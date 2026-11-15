# Stage 4 剩余项目逐项核验（TASK-STAGE4-REMAINDER）

> **本文件做什么**：对 `STAGE4_FINAL_REPORT.md` 的 27 项台账**逐项回原始证据重算**，不复制上一轮统计；并把本轮查出的五处数值/机制更正登记下来。
>
> **本文件不做**：不改驱动源码、不改 Kconfig/Kbuild、不改 workflow、不编译、不刷机、不部署。全部改动为纯文档。
>
> **与相邻文档的分工**：DDK 路线见 [`DDK_DUAL_TRACK_ASSESSMENT.md`](DDK_DUAL_TRACK_ASSESSMENT.md)；R49 改造预研见 [`R49_DDK_ADAPTATION_PLAN.md`](R49_DDK_ADAPTATION_PLAN.md)；真机采集方案见 [`STAGE4_DEVICE_COLLECTION_PLAN.md`](STAGE4_DEVICE_COLLECTION_PLAN.md)。
>
> 证据等级沿用 `05/08` §0.1：**[D·A]/[D·B]/[D·C]** 设备实测三分 · **[B]** 可核验构建记录 · **[P]** 用户声明 · **[E1]** 源码/二进制直接证据 · **[E2]** 交叉推导 · **[E3]** 惯例推断 · **[U]** UNKNOWN

---

## 0. 一句话结论

> **逐项重算后，27 项的五态由 5 / 6 / 1 / 15 变为 5 / 8 / 1 / 13**（变化原因见 §4，规则见 `D-033`）。**P0 仍是 3 项**。本轮真正的收获不是"多数了几项"，而是把 **U4-04c 这个 P0 生死项从"完全未知"收窄到 3 处具体检查**——因为 R49 kbase **本来就在内联校验**其中最关键的三类结构体（MEM_JIT_INIT / CSG create 全 padding / READ_USER_PAGE），这一点此前被"R49 没有 `mali_kbase_ioctl_helpers.h`"误读为"R49 不校验 padding"。
>
> 同时更正三处数值口径：**GPU 属性 ID 是 83 共同 + 3 新增（不是 83/83 不变）**；**序列化后的 props 缓冲区 749 → 781 字节（不是 568 → 592，后者是 `gpu_props_user_data` 的 `sizeof` 人工推算，且不是线上格式）**；**ioctl 集合是 54 → 50（删 6 增 2），不是"55 个"**。

---

## 1. 复核方法与边界

| 项 | 内容 |
| --- | --- |
| 起点 | `HEAD = bbaeaf2`（与任务书基线一致，工作区干净，无新提交） |
| 方法 | 对每一项回**源码逐字段/逐枚举**重算；对上一轮的数字用脚本重新生成，不复用报告措辞 |
| 新增采集 | **0**。本轮未使用任何设备命令，未下载任何二进制 |
| 工具 | `git` / `grep` / `sed` / Python3（结构体与枚举解析脚本，脚本本身不入库） |
| 不可越界 | 不改 `01_original_baseline/`、`02_r56_source/`；不编译；不刷机；不进入 Stage 5 |

> 本轮用过的一次性脚本共 4 个（ioctl 集合比对、props 缓冲区字节数、padding 钩子三分类、结构体字段尺寸），全部只读源码、输出为文本。**结论可由任何人用同样命令复现**，不依赖脚本留存。

---

## 2. 五项新发现（本轮实质增量）

### N-1 · R49 kbase **内联校验** padding —— 纠正"D-027 前提之一"

`D-027` 写："R49 kbase **没有** `mali_kbase_ioctl_helpers.h`（该机制 R50+ 才引入）→ 旧环境**不校验** padding → DDK 没有外部压力保证清零。"

**前半句对，后半句错。** 集中式 helper 头确实是 R50+ 才引入（R49 目录内 `ls | grep ioctl` 只返回 `include/uapi/.../mali_kbase_ioctl.h`，无 `mali_kbase_ioctl_helpers.h`），但**校验代码本身在 R49 里就以展开形式存在**：

| # | R49 位置 | 对象 | 行为 |
| ---: | --- | --- | --- |
| 1 | `mali_kbase_core_linux.c:1160-1166` | `MEM_JIT_INIT` 的 `padding[]` | 逐字节判零，非零 `-EINVAL`；注释原文 *"Ensure all padding bytes are 0 for potential future extension"* |
| 2 | `mali_kbase_core_linux.c:1518-1521` | `CSG_CREATE_1_6` 的 `in.padding[]` | 逐字节判零，非零 `-EINVAL` |
| 3 | `mali_kbase_core_linux.c:1550-1553` | `CSG_CREATE_1_18` 的 `in.padding[]` | 同上 |
| 4 | `csf/mali_kbase_csf.c:1367-1370` | **现版 CSG_CREATE（112 B / nr 58）的 `in.padding[9]`（offset 40–111）** | 逐字节判零，非零 `-EINVAL` |
| 5 | `mali_kbase_core_linux.c:1568-1571` | 现版 CSG_CREATE 的 `in.reserved`（offset 30） | 非零 → `dev_warn` + `-EINVAL` |
| 6 | `mali_kbase_core_linux.c:1714-1716` | `READ_USER_PAGE` 的 `in.padding` | 非零 `-EINVAL` |
| 7 | `csf/mali_kbase_csf_kcpu.c:3059-3063` | KCPU 命令的 `command.padding[]` | 非零 → `dev_dbg` + 拒绝 |
| 8 | `mali_kbase_kinstr_jm.c:756-758` | `KINSTR_JM_FD` 的 `in.padding` | 非零 `-EINVAL` |
| 9 | `mali_kbase_softjobs.c:894-897` | `base_jit_alloc_info` 的 `info->padding`（`kbasep_jit_alloc_validate`） | 非零 `-EINVAL` |

**为什么这条重要**：R56 的 `check_padding_KBASE_IOCTL_CS_QUEUE_GROUP_CREATE_1_35` 校验的是 `in.padding[62]`（offset 50–111），它是 R49 `in.padding[9]`（offset 40–111）的**真子集**。既然 OEM 设备上 GPU **确实在渲染**（[D·B]：`init.svc.vendor.hwcomposer=running`、SurfaceFlinger 在册），那么 R49 DDK 发出的 CSG create 必然 `padding[9]` 全零 —— 否则 R49 kbase 会直接 `-EINVAL`，一个 CSG 都建不起来，GPU 完全不可用。

> **推理链**：`[E1]` R49 校验 `padding[9]` ⊕ `[D·B]` 设备可渲染 ⇒ `[E2]` R49 DDK 在 CSG create 上填的 offset 40–111 **全为 0** ⇒ R56 的 `_1_35` 检查（50–111）**必然通过**。
>
> **边界**：只覆盖 CSG create 这一条路径，**不覆盖**其余强制项（见 §3.3）。

### N-2 · GPU 属性：83 共同 + **3 新增**；序列化缓冲区 749 → **781** 字节

| 项 | R49 | R56 | 差 |
| --- | ---: | ---: | ---: |
| `KBASE_GPUPROP_*` ID 数（排除 4 个 `VALUE_SIZE_*`） | **83** | **86** | **+3** |
| 其中 R56 新增 | — | `RAW_BASE_PRESENT` = 86（`__u64`）<br>`RAW_NEURAL_PRESENT` = 87（`__u64`）<br>`NUM_ACTIVE_GRANULARITY` = 88（`__u32`） | — |
| 被删除的 ID | — | — | **0** |
| `gpu_property_mapping[]` 条目数 | 83 | 86 | +3 |
| **序列化缓冲区 `prop_buffer_size`**（`Σ(4 + sizeof(value))`） | **749** | **781** | **+32** |
| `sizeof(struct gpu_props_user_data)`（人工推算，未经编译） | 568 | 592 | +24 |

**更正两处旧表述**：

1. `05/06_abi_compatibility_matrix.md:61/169` 与 `PROJECT_STATE` §3.4 的"**属性 ID 83/83 不变**"——实为 **83 共同 + 3 新增**。方向不变（无删除、旧 ID 语义未改），但"不变"这个词是错的。
2. `05/09` §5.4 的"先问一次 `size=0`，就能拿到 **592**"——592 是 `sizeof(gpu_props_user_data)` 的**人工推算值**（`03/MANIFEST` U8 已自认"未经编译验证"），**不是**内核返回的长度。内核返回的是 `prop_buffer_size`，R56 为 **781**。`05/README.md:69` 已正确指出"结构体不是 ABI"，但 `09` §5.4 的措辞没有跟上。

**机制**（`[E1]`，`mali_kbase_gpuprops.c:809-880`）：缓冲区是 **TLV 流**——每条 `u32 id` + `u8 type_size` + 值，无头部、无计数。因此 ①旧 DDK 遇到不认识的 ID **跳过即可**，新增属性天然向前兼容；②唯一硬门槛是 `get_props->size < prop_buffer_size` → `-EINVAL`（`09` §5.4）。**R56 的 781 > R49 的 749，所以"写死旧长度"这种实现会在 R56 上失败**——这条风险从"定性"变成"定量 +32 B"。

### N-3 · ioctl 集合：54 → 50（删 6、增 2），且 **ioctl 55 在 CSF 上是 no-op**

用 `_IOWR|_IOW|_IOR|_IO(KBASE_IOCTL_TYPE, nr, …)` 全量正则提取（排除 `KBASE_IOCTL_TEST_TYPE` 的 5 个测试项）：

| 侧 | 生产 ioctl 数 |
| --- | ---: |
| R49 | **54** |
| R56 | **50** |
| 差 | 54 − 6 + 2 = 50 ✓ |

**删除 6 个**（独立复现，与 `05/09` §11.2 一致）：

| ioctl | nr | 性质 |
| --- | ---: | --- |
| `HWCNT_READER_SETUP` | 8 | 旧 HWCNT 读取 |
| `DISJOINT_QUERY` | 12 | 已废弃 |
| `HWCNT_SET` | 32 | 旧 HWCNT 写入（`struct kbase_ioctl_hwcnt_values`） |
| `CINSTR_GWT_DUMP` | 35 | 调试 |
| `SET_LIMITED_CORE_COUNT` | **55** | 生产相关（见下） |
| `INTERNAL_FENCE_WAIT` | **80** | **MTK 私有** |

**新增 2 个**：`CS_QUEUE_GROUP_CREATE_1_35`（nr 58 / 112 B，**不是新能力**，是 R49 `CS_QUEUE_GROUP_CREATE` 的原编码改名保留）、`CS_TILER_HEAP_SIZE`（nr 62，真新增：按 `heap_ptr` 查 `size`/`peak_size`）。

**关于 ioctl 55 的新裁定**（`[E1]`）：`kctx->limited_core_mask` 的**唯一消费者**是 `backend/gpu/mali_kbase_jm_hw.c`（Job Manager 后端：`:140`、`:1275-1283`）。G925 是 **CSF** 硬件，不走 JM 后端；`csf/` 目录内对该字段**零引用**。因此在 G925 上调用 ioctl 55 **只改一个没人读的变量**，等于 no-op。

> 由此 `R-B3` 的风险描述应改写：55 的丢失**不是"性能降级"**，而是"原本就是空操作，现在连空操作都不给你"。真正需要确认的是 **DDK 是否把 `-ENOTTY` 当致命错误**。

### N-4 · tKRx 硬件支持：R49 **已完整具备**，features 完全相同，issues 差 3 项

`03_kbase_csf/05_g925_hardware_support.md` 讨论过 R56 的 `tKRx`；本轮确认 **R49 也有，且是同一套**：

| 项 | R49 | R56 | 判定 |
| --- | --- | --- | --- |
| `GPU_ID_PRODUCT_TKRX` 定义 | `gpu/mali_kbase_gpu_id.h:174` | 同 | **相同** |
| `base_hw_features_tKRx[]` | 9 项（FLUSH_REDUCTION / PROTECTED_DEBUG_MODE / L2_CONFIG / CLEAN_ONLY_SAFE / L2_SLICE_HASH / GPU_SLEEP / CORE_FEATURES / PBHA_HWU / LARGE_PAGE_ALLOC） | 同 9 项，仅前缀 `BASE_`→`KBASE_` | **完全相同** |
| `base_hw_issues_tKRx_r0p0[]` | 8 项 | 9 项 | **差 3** |
| 产品名映射 | `"Mali-G725"`；`nr_cores≥10 && RT` → `"Mali-G925-Immortalis"` | 同逻辑 | **相同** |
| `gpuinfo` sysfs | `DEVICE_ATTR_RO(gpuinfo)`，输出 `"%s %d cores r%dp%d 0x%08X"` | 同 | **相同** |

**issues 表的具体差**（`[E1]`，逐项比对）：

| 变更 | 项 |
| --- | --- |
| R56 **移除** | `TURSEHW_2716` |
| R56 **新增** | `KRAKEHW_2348`、`MAGNIHW_2257` |

> **意义**：①"G925 需要 R56 才支持"是**错的**——R49 就支持，因为 R49 就是这台手机的出厂驱动；②R49→R56 在硬件规避上只差 3 项，且**全部落在 kbase 侧**（DDK 不承担 workaround），所以"换 R56 kbase"本身就能拿到这 3 项，与 DDK 用哪一代**无关**；③这也是 `D-028` 用"G925 发布晚于 R46"否决 R46 的逻辑**不能平移到 R49** 的原因——R49 是同期、同机、同 SKU 的配套件。

### N-5 · OEM 构建**启用了** `CONFIG_MALI_MTK_FENCE_DEBUG`（ioctl 80 在 OEM 栈上是活的）

```
$ strings -a 01_original_baseline/kernel_ref_mt6991/vendor_dlkm/mali_kbase_mt6991_r49.ko \
    | grep -i "internal fence"
ctx:%d_%d cpu queue:%llx Internal fence wait timeouts(%llu ms)! flags=0x%x pid=%u
ctx:%d_%d cpu queue:%llx Internal fence timeouts(%llu ms)! Trigger GPU reset
ctx:%d_%d cpu queue:%llx Internal fence timeouts(%llu ms)! Other threads are already resetting the GPU
ctx:%d_%d cpu queue:%llx Internal fence timeouts(%llu ms)! Trigger cross queue sync recovery
$ strings -a … | grep -c ged_mali_event_notify_fence_timeout_event
2
```

这些串只出现在 `#if IS_ENABLED(CONFIG_MALI_MTK_FENCE_DEBUG)` 的 `kbasep_ioctl_internal_fence_wait()` 内（`mali_kbase_core_linux.c:1830-1880`）。**串在 ⇒ 代码在 ⇒ 该 ioctl 在 OEM 栈上是可达的**。

| 边界 | 说明 |
| --- | --- |
| 这是**仓库基线** kbase（OS3.0.305.0，`g57e634f35c1b`） | 设备 kbase 是 OS4.0.3.0（`g54a15cf3acba`），**未直接验证**；device `.ko` 未入库（`D-004`） |
| 但它把"OEM 是否启用该 MTK 扩展"从 [U] 推到 **[E1]（同源码、不同构建）** | 同 release 串 `r49p1-03bet0`，`mali_*` 三个模块中只有 kbase 有实质差异（`+17,640 B`） |
| **可一条只读命令在设备上复核** | `strings /vendor_dlkm/lib/modules/mali_kbase_mt6991_r49.ko \| grep -c "Internal fence wait"`，见 `STAGE4_DEVICE_COLLECTION_PLAN.md` §5 G 段 |

> **为什么这条重要**：它把 U4-14 的"80 是否可能被调用"变成"80 在 OEM 上确实存在，所以 DDK **有理由**调用它；若 R56 上没有，DDK 会拿到 `-ENOTTY`"。

---

## 3. P0 三项的逐项重核

### 3.1 U4-04（padding / props 行为）—— 仍然 **PARTIAL**，但子项 c 的未知面缩小到 3 条

子项拆分（`D-026`）与最新状态：

| 子项 | 内容 | 状态 | 依据 |
| --- | --- | --- | --- |
| **a** | DDK 版本代次 | ✅ **CLOSED** | `r49p1-03bet0`（[D·A]）→ 映射 UK 1.30 |
| **b** | R49↔R56 结构体布局 | ✅ **CLOSED** | 51 个共同结构体、实质差异 0（`05/09` §11.1） |
| **c1** | DDK 是否对 R56 强制的 15 个结构体清零 padding | ⚠️ **3 已证 / 4 结构上不用 / 8 待证** | 见下表 |
| **c2** | DDK 是否做 `size=0` 的 props 两步协商 | **OPEN**，且新增定量风险（+32 B） | §2 N-2 |

**c1 的 15 项逐项裁定**（R56 强制集来自 `05/09` §5.2，R49 侧来自 §2 N-1）：

| # | R56 强制项 | R49 是否校验 | 裁定 |
| ---: | --- | :---: | --- |
| 1 | `MEM_JIT_INIT` | ✅ `core_linux:1160` | **已证清零**（否则 JIT 不可用 → 设备不可能正常） |
| 2 | `CS_QUEUE_GROUP_CREATE_1_35` | ✅ `csf.c:1367`（超集） | **已证清零** |
| 3 | `READ_USER_PAGE` | ✅ `core_linux:1714` | **已证清零** |
| 4 | `CS_QUEUE_GROUP_CREATE_1_6` | ✅ `core_linux:1518` | 结构上不用（1.30 DDK 用 nr 58 / 112 B 的那支） |
| 5 | `CS_QUEUE_GROUP_CREATE_1_18` | ✅ `core_linux:1550` | 同上 |
| 6 | `CS_QUEUE_GROUP_CREATE`（120 B / nr 63） | ❌ | 结构上不用（R56 新增编码） |
| 7 | **`CS_QUEUE_REGISTER`** | ❌ | **待证（渲染主路径，致命）** |
| 8 | **`CS_QUEUE_REGISTER_EX`** | ❌ | **待证（若 DDK 用 EX 变体）** |
| 9 | **`CS_TILER_HEAP_INIT`** | ❌ | **待证（3D 路径）** |
| 10 | **`CS_TILER_HEAP_INIT_1_13`** | ❌ | **待证（若 DDK 用 1_13 变体）** |
| 11 | `MEM_ALLOC_EX`（`in.extra[]`） | ❌ | **待证（若 DDK 用 EX 变体）** |
| 12 | `CS_QUEUE_GROUP_TERMINATE` | ❌ | 待证（非致命） |
| 13 | `GET_DDK_VERSION` | ❌ | 待证（非致命；R56 只在 `padding != 0` 时拒绝） |
| 14 | `MEM_PROFILE_ADD` | ❌ | 待证（调试面） |
| 15 | `GET_CPU_GPU_TIMEINFO` | ❌ | 待证（时间查询面） |

> **U4-04c 的净结论**：**"任意一处失败 → GPU 完全不可用"这个最坏情形，其入口已从 15 个减到 4 个**（表中 7/8/9/10），其中 8 与 10 只在 DDK 选用了新版变体时才成立。**仍然不能闭合**——`CS_QUEUE_REGISTER` 的 `padding[3]`（offset 13–15）没有任何 R49 侧压力，DDK 完全可能留脏值。
>
> **也不能反向推断**：本节的"已证"依赖"设备可渲染"，而"设备可渲染"是 OEM 栈（R49 kbase + R49 DDK）的事实，**不是** R56 kbase 上的事实。R56 的检查范围与 R49 **不完全重合**（例如 R56 额外检查 offset 50–111 的 62 字节，R49 检查 40–111 的 72 字节 —— 后者是前者的超集，所以这条**是**覆盖的；但 `CS_QUEUE_REGISTER` 这类 R49 完全不查的项**不覆盖**）。

### 3.2 U4-10（GPU 失败是否 bootloop）—— **PARTIAL**，无新增证据

静态结论不变：固件在**首次 `open()`** 加载（`mali_kbase_core_linux.c:790-802`），probe 不涉及 → **不阻断启动、可重试**（[E1]）。本轮未新增任何故障注入证据，也未重算。

剩余问题（真实故障下可用性丧失面）**只能靠故障注入**，本轮禁止。

一条本轮补充的**旁证**（不改变状态）：R56 删掉了 ioctl 80，而 80 携带 `CONFIG_MALI_MTK_FENCE_TIMEOUT_RESET` 下的"internal fence 超时 → `kbase_prepare_to_reset_gpu()`"这一 MTK 自愈入口。R56 自身仍有 19+ 处 `kbase_prepare_to_reset_gpu()` 调用，所以"reset 能力"不丢，丢的是"**由 internal fence 超时触发**"这个 MTK 特有入口。

### 3.3 U4-12（R56 CSF 固件）—— **BLOCKED**，理由已精确，但需再拆一层

**本轮重核 `02_r56_source/_arm_listing/arm_5thgen_package_listing_20261115.json`（23 条目）**：

| 关键词 | 命中 |
| --- | ---: |
| `firmware` / `.bin` / `csffw` / `ddk` / `libGLES` / `vulkan` | **0** |

**R56p0 交付包的实际结构**（`02_r56_source/mali_r56p0/` 全量枚举）：

```
driver/product/kernel/
├── drivers/gpu/arm/midgard/     ← kbase 源码（唯一内容）
├── include/uapi/gpu/arm/midgard/ ← uapi 头
├── Documentation/               ← ABI(testing) / devicetree / csf_sync_state_dump / ioctl-categories
└── config/                      ← BUILD.bazel / cflags.bzl / fragment
```

> **结论**：包内**只有内核驱动源码**，没有 `mali_csffw.bin`，没有用户态 DDK，也没有 DDK 源码。缺的是**两类**商业件，不是一个。

**R56 固件验收标准**（在 `05/09` §6.2 四项之上，本轮补两条源码级判据）：

| # | 检查 | 通过条件 | 依据 |
| ---: | --- | --- | --- |
| 1 | header 版本 | `offset 4 = 0x04`、`offset 5 = 0x00` | `csf/mali_kbase_csf_firmware.c:85-86, 2698-2701`，`!=` 严格、无 fallback |
| 2 | magic | `offset 0-3 = 6e 3a f1 c3`（`0xC3F13A6E` 小端） | 同上 |
| 3 | GPU 型号 / core mask | 与 G925 **MC12**（12 核）一致；产品 ID 应为 `TKRX` | `mali_kbase_hw.c:272`、`mali_kbase_gpu_id.h:174`；`gpuinfo` 输出可比对 |
| 4 | **GLB 接口版本 ≥ 1.1.0** | 运行时 `iface->version >= kbase_csf_interface_version(1,1,0)` | `csf/mali_kbase_csf.c:657`、`csf/mali_kbase_csf_scheduler.c:1794`（R49 同阈值，故**不是新增门槛**） |
| 5 | **interface entry 布局** | `entry_end_offset`（header offset 0x10）与 R56 的 entry 表一致 | `csf/mali_kbase_csf_firmware.c` 的 entry 解析器 |
| 6 | 与 DDK 的配套性 | 同一 release（`r56p0-18eac0`）交付 | — |

> **禁止**：改 R49 固件 8 字节 header 冒充 0.4。header 只是入口校验，entry 表（GLB 版本、region 布局）随 release 变化；改了只会把"早失败"变成"晚崩溃"。
>
> **注意第 4 项**：GLB ≥ 1.1.0 是 R49/R56 **共同**要求，因此它不构成"R56 更严"的证据；不要把它写成新增门槛。

---

## 4. 五态重算（含计数规则变更）

### 4.1 新计数规则（`D-033`）

> **PARTIAL 的判定**：一个 U4 项若**已被拆成可独立判定的子项**，且**至少一个子项 CLOSED、至少一个子项未闭合**，则整项记 **PARTIAL**；否则按 OPEN / CLOSED / BLOCKED 记。

上一轮用这条规则时只套用在 U4-04 / U4-24 / U4-25 上，U4-14 与 U4-15 虽同样"子项 a 已闭、子项 b 未闭"，却仍记 OPEN。本轮统一规则（不是重新定性，只是把同一标准用全）。

### 4.2 结果

| 状态 | 上一轮 | 本轮 | 变化 |
| --- | ---: | ---: | --- |
| ✅ CLOSED | 5 | **5** | 不变（U4-01/03/05/08/09） |
| ⚠️ PARTIAL | 6 | **8** | **+2**：U4-14、U4-15 |
| ⛔ BLOCKED | 1 | **1** | 不变（U4-12） |
| ○ OPEN | 15 | **13** | **−2** |
| ? UNKNOWN | 0 | **0** | 不变 |
| **合计** | **27** | **27** | ✓ |

明细：

| 状态 | 项 |
| --- | --- |
| CLOSED（5） | U4-01、U4-03、U4-05、U4-08、U4-09 |
| PARTIAL（8） | U4-04、U4-06、U4-07、U4-10、**U4-14**、**U4-15**、U4-24、U4-25 |
| BLOCKED（1） | U4-12 |
| OPEN（13） | U4-02、U4-11、U4-13、U4-16、U4-17、U4-18、U4-19、U4-20、U4-21、U4-22、U4-23、U4-26、U4-27 |

### 4.3 优先级分布（未变）

| 优先级 | 数量 | 项 |
| --- | ---: | --- |
| **P0** | **3** | U4-04（PARTIAL）/ U4-10（PARTIAL）/ U4-12（BLOCKED） |
| P1 | 8 | U4-02 / U4-11 / U4-14 / U4-15 / U4-17 / U4-22 / U4-24 / U4-25 |
| P2 | 8 | U4-06 / U4-07 / U4-16 / U4-19 / U4-20 / U4-21 / U4-26 / U4-27 |
| P3 | 3 | U4-13 / U4-18 / U4-23 |
| （不计） | 5 | 已闭合 |

校验：3 + 8 + 8 + 3 + 5 = 27 ✓

---

## 5. 全量逐项核验表

> 列含义：**只读** = 能否只用手机只读命令闭合；**真机** = 是否必须真机；**REA** = 是否必须二进制逆向；**商业件** = 是否必须取得 Arm/MTK 授权交付物。

| ID | 内容 | 优先级 | 状态 | 已有证据 | 缺失证据 | 最低成本核验方法 | 只读 | 真机 | REA | 商业件 |
| --- | --- | :---: | :---: | --- | --- | --- | :---: | :---: | :---: | :---: |
| U4-01 | 固件 header 实测值 | ~~P0~~ | ✅ CLOSED | `6e 3a f1 c3 03 00 00 00` → **0.3** [D·A] | — | 已闭合 | — | — | — | — |
| U4-02 | 原厂固件**运行时** GLB 版本 | P1 | ○ OPEN | kbase 只在 `iface->version` 生效，**未打印**；`dev_notice("Loading Mali firmware 0x%x")` 只给 `version_hash`（≠ GLB） | `iface->version` 的运行时值 | ①`dmesg \| grep -i "mali\|csf"` 看是否有版本行；②`ls /sys/kernel/debug/mali0/` 找 `fw_*`；③离线读固件 shared-interface 初值（需 REA/解析） | ⚠️ | ✅ | ⚠️ | ❌ |
| U4-03 | DTB `firmware-name` 覆盖 | — | ✅ CLOSED | DT 双向无该属性 | — | 已闭合 | — | — | — | — |
| **U4-04** | DDK padding / props 行为 | **P0** | ⚠️ PARTIAL | a ✅、b ✅、**c1 缩至 4 条致命项**（§3.1）、c2 机制明 [E1] | c1 的 8 项（4 项致命）、c2 的 DDK 协商行为 | `strace` 看 GET_GPUPROPS 是否两次调用 + CSG/QUEUE 的 size；padding 字节需 REA 或 preload shim | ⚠️ | ✅ | ✅ | ❌ |
| U4-05 | 是否有 Vulkan | — | ✅ CLOSED | `vulkan.mali.so` 133,416 B 薄壳 | — | 已闭合 | — | — | — | — |
| U4-06 | EGL 加载机制细节 | P2 | ⚠️ PARTIAL | 可用性 [D·A]；`ro.hardware.egl=mali`；`mt6991/` 子目录布局 | `ld.config.txt` 的搜索路径、`ro.egl.additional_libraries` | `cat /linkerconfig/ld.config.txt \| grep -A3 egl`；`getprop \| grep egl` | ✅ | ✅ | ❌ | ❌ |
| U4-07 | 分配走 dma-buf heap 还是 ion | P2 | ⚠️ PARTIAL | 两库都在 NEEDED 里 | 实际路径 | `strace -f -e trace=openat` 看 `/dev/dma_heap/*` vs `/dev/ion` | ⚠️ | ✅ | ❌ | ❌ |
| U4-08 | HWC 是否依赖 DDK | — | ✅ CLOSED | NEEDED 面无 Mali 库 | — | 已闭合 | — | — | — | — |
| U4-09 | VINTF / init | — | ✅ CLOSED | 三份 manifest 齐备 | — | 已闭合 | — | — | — | — |
| **U4-10** | 失败是否 bootloop | **P0** | ⚠️ PARTIAL | 静态：**不阻断启动**、可重试 [E1] | 真实故障的可用性丧失面 | 故障注入（需可回滚环境） | ❌ | ✅ | ❌ | ❌ |
| U4-11 | 固件 GLB 尾部版本 / `entry_end_offset` | P1 | ○ OPEN | 前 16 B 已知；`0x030A0000` 是 `version_hash`，**不是** GLB 版本（禁止解码） | `offset 0x10` 起 4 字节、尾部 32 B | `od -An -tx1 -N 24 /vendor/firmware/mali_csffw.bin`；`od -j $((SIZE-32))` | ✅ | ✅ | ❌ | ❌ |
| **U4-12** | R56 固件是否匹配 G925 MC12 | **P0** | ⛔ BLOCKED | 交付包 23 条目 0 命中；验收判据 6 条已写定（§3.3） | **固件实体** | 不可由设备/源码取得 | ❌ | ❌ | ❌ | ✅ |
| U4-13 | NX 相关 GLB 字段 | P3 | ○ OPEN | — | 固件实体 | 随 U4-12 | ❌ | ❌ | ⚠️ | ✅ |
| **U4-14** | DDK 是否用被删的 6 个 ioctl | P1 | ⚠️ **PARTIAL** | 删除清单独立复现（54→50）；**55 在 CSF 上是 no-op**；**80 在 OEM 上存在**（§2 N-3/N-5） | DDK 实际调用面 | `strace -f -e trace=ioctl` 看 `_IOC(_,0x80,nr,size)` 是否出现 8/12/32/35/55/80 | ✅ | ✅ | ❌ | ❌ |
| U4-15 | DDK 对新增 props 的处理 | P1 | ⚠️ **PARTIAL** | **3 个新 ID**、**+32 B**、TLV 机制、唯一硬门槛（§2 N-2） | DDK 是否 `size=0` 探测 | `strace` 看 GET_GPUPROPS 调用次数 | ✅ | ✅ | ❌ | ❌ |
| U4-16 | DDK 是否依赖 HWCNT 做 DVFS | P2 | ○ OPEN | — | trace | `strace` 看 `KINSTR_PRFCNT_SETUP` | ✅ | ✅ | ❌ | ❌ |
| U4-17 | Vulkan 薄壳 `api_version` / 加载机制 | P1 | ○ OPEN | 薄壳存在；VINTF 1.3 | 壳内 `api_version` 来源 | `strings vulkan.mali.so \| grep -i vk_icd`；`getprop \| grep vulkan`；完整需反汇编 | ⚠️ | ✅ | ⚠️ | ❌ |
| U4-18 | Vulkan 与 GLES 是否同批构建 | P3 | ○ OPEN | 两 Build ID 已取（`700e6d41…`） | 判据本身 | 需 Arm 构建记录 | ❌ | ❌ | ❌ | ✅ |
| U4-19 | Vulkan 是否用 GLES 不用的 ioctl | P2 | ○ OPEN | — | trace | 跑 Vulkan 用例 + `strace` | ✅ | ✅ | ❌ | ❌ |
| U4-20 | SF RenderEngine 后端 | P2 | ○ OPEN | `ro.hwui.use_vulkan=true` [D·A] | 实际后端 | `dumpsys SurfaceFlinger \| grep -iE "gles\|skiagl\|renderengine"` | ✅ | ✅ | ❌ | ❌ |
| U4-21 | 是否有服务硬依赖 `/dev/mali0` | P2 | ○ OPEN | — | 服务面 | `dumpsys -l` + `ls -l /proc/*/fd 2>/dev/null \| grep mali` | ✅ | ✅ | ❌ | ❌ |
| U4-22 | `libged` 失效的降级程度 | P1 | ○ OPEN | HWC/mapper NEEDED `libged`；`ged.ko` 不反向依赖 kbase | 真实失效表现 | 需故障注入或代码级追踪 | ❌ | ✅ | ⚠️ | ❌ |
| U4-23 | `libgpud` 与 `libgpud_sys` 符号关系 | P3 | ○ OPEN | 两者分别被 GLES / `libvulkan.so` NEEDED | 符号表对照 | `readelf --dyn-syms` 两者并比对（设备端可做） | ✅ | ✅ | ❌ | ❌ |
| **U4-24** | 设备 `.ko` 身份 / CRC | P1 | ⚠️ PARTIAL | a ✅ 18 个全取 | b：CRC 数值 | `readelf -x __versions` （ged 抽样 + kbase 全量） | ✅ | ✅ | ❌ | ❌ |
| **U4-25** | 第三方内核差异面 | P1 | ⚠️ PARTIAL | a ✅；b 运行态不可观测（只在 CRC 不匹配时有意义） | c：导出符号集/CFI/调度 | `dmesg \| grep disagrees`；导出符号表需镜像 | ⚠️ | ✅ | ⚠️ | ❌ |
| U4-26 | 设备 boot 是否即 CI 产物 | P2 | ○ OPEN | 四项参数吻合 [B]+[D·B]；`uname -v` 零信息量 | 内核 `build-id` | `cat /sys/kernel/notes \| od -An -tx1` | ✅ | ✅ | ❌ | ⚠️（需 CI 产物） |
| U4-27 | `/vendor` 是否被 overlay | P2 | ○ OPEN | 安装包只写 `boot`（[B]），不证明视图原样 | mount 表 | `cat /proc/self/mountinfo \| grep -Ei "vendor\|overlay\|magisk\|KSU"` | ✅ | ✅ | ❌ | ❌ |

**统计**：只读可闭合 **13** 项（U4-06/07*/11/14/15/16/17*/19/20/21/23/24/26/27）；需 REA **3** 项（U4-04、U4-17、U4-22/U4-25 各为 ⚠️）；需商业件 **4** 项（U4-12/13/18 + U4-04c 的 DDK 二进制分析若要"确定"才需）；必须故障注入 **2** 项（U4-10、U4-22）。

> `*` = 只读只能闭合"主问题"，细节仍需反汇编或 trace。

---

## 6. 分档：谁能靠手机解决，谁不能

### 6.1 只靠手机只读采集即可闭合（无需 REA、无需商业件）

| 项 | 采集内容 | 成本 |
| --- | --- | --- |
| U4-27 | `mountinfo` | 一条命令 |
| U4-11 | 固件 `offset 0x10` + 尾部 32 B | 两条 `od` |
| U4-26 | `/sys/kernel/notes` 的 build-id | 一条命令 |
| U4-24b | `readelf -x __versions`（ged + kbase） | 两条命令，产出 ~200 KB 文本 |
| U4-06 | `ld.config.txt` + `ro.egl.*` | 两条命令 |
| U4-23 | 两库 `--dyn-syms` 对照 | 两条命令 |
| U4-20 / U4-21 | `dumpsys` 定向 grep | 两条命令 |
| U4-17（部分） | `vulkan.mali.so` 的 `--dyn-syms` / `-d` / `strings` | 两条命令 |
| U4-02（部分） | `dmesg` 中固件启动行 + `debugfs/mali0` 枚举 | 两条命令 |

### 6.2 必须 REA（离线反汇编）才能"确定"

| 项 | 对象 | 说明 |
| --- | --- | --- |
| U4-04c1 残部 | `libGLES_mali.so`（53 MB） | 只看 `CS_QUEUE_REGISTER` / `CS_TILER_HEAP_INIT` / `MEM_ALLOC_EX` 的栈初始化是否 `{0}`；**不需全量分析**，定位到 ioctl 打包点即可 |
| U4-04c2 | 同上 | 看 `GET_GPUPROPS` 是否先发 `size=0` |
| U4-17 | `vulkan.mali.so`（133 KB） | 薄壳的 `api_version` 常量与 ICD 加载顺序 |

### 6.3 必须商业交付件

| 项 | 缺什么 |
| --- | --- |
| U4-12 / U4-13 | R56p0 `mali_csffw.bin`（header 0.4、G925 MC12） |
| U4-18 | Arm 构建记录（两库是否同批） |
| （若选完整 R56 路线）用户态 DDK | R56p0 GLES/EGL/Vulkan |
| （若选 R49 改造路线）**R49 DDK 源码** | 设备上只有编译产物，**没有源码** —— 见 `R49_DDK_ADAPTATION_PLAN.md` §1 |

### 6.4 必须真机故障注入（本轮禁止）

| 项 | 说明 |
| --- | --- |
| U4-10 | GPU 初始化失败的可用性丧失面 |
| U4-22 | `libged` 真实失效时 mapper/HWC 的表现 |

---

## 7. 本轮更正清单（对被推翻表述的留痕）

| # | 旧表述 | 出处 | 现表述 | 依据 |
| ---: | --- | --- | --- | --- |
| 1 | "R49 kbase 不校验 padding，所以 DDK 没有外部压力" | `D-027`、`05/09` §11.4 | R49 **确实**校验 padding（至少 9 处内联），只是没有集中式 helper 头 | §2 N-1 |
| 2 | "padding 15 处强制，任一处失败 GPU 完全不可用" | `D-025`、`PROJECT_STATE` §5.2 | 15 处仍是 15 处（脚本复核 `28+5+15=48` ✓），但**其中 3 处已被设备行为证明满足、4 处结构上不用** → 致命入口实际为 4 条 | §3.1 |
| 3 | "属性 ID 83/83 不变" | `05/06` §2、`PROJECT_STATE` §3.4 | **83 共同 + 3 新增**（86/87/88），无删除 | §2 N-2 |
| 4 | "`size=0` 能拿到 592" | `05/09` §5.4 | 592 是 `sizeof(gpu_props_user_data)` 的人工推算；内核返回的 `prop_buffer_size` 是 **781** | §2 N-2 |
| 5 | "55 个 ioctl" | `STAGE4_FINAL_REPORT` §4.2、`05/09` §11.1 | **54（R49）→ 50（R56）**，删 6 增 2 | §2 N-3 |
| 6 | "R56 才支持 G925 / R46 没有 tKRx" | `D-028`、`06/DDK_DUAL_TRACK_ASSESSMENT` §3.3 | R49 **已完整支持 tKRx**（features 完全相同、issues 差 3 项）。R46 的结论**不受影响**，但**不能平移给 R49** | §2 N-4 |
| 7 | "ioctl 55 丢失 → 性能降级" | `STAGE4_FINAL_REPORT` §4.4 | 在 CSF 硬件上 55 **本来就是 no-op**（`limited_core_mask` 只被 JM 后端读取）；风险只是"`-ENOTTY` 是否被 DDK 当致命" | §2 N-3 |

> 第 1、6 条**推翻的是本项目自己的推理**，不是外部事实。原文留痕于 `D-027` / `D-028` 的"后续修正"栏，本表不删除历史。
>
> **本表自身的两处修订（同一轮内）**：①第 1 条的处数在提交前由 **8 处复核为 9 处**——补入 `mali_kbase_softjobs.c:894-897` 的 `base_jit_alloc_info.info->padding`（`kbasep_jit_alloc_validate`）；②原稿把两处路径记错（`csf/mali_kbase_csf_csg.c` 应为 `csf/mali_kbase_csf.c`；`backend/gpu/mali_kbase_kinstr_jm.c` 应为 `mali_kbase_kinstr_jm.c`），已逐行复核更正。**结论方向不变**，仅处数由 8 变 9。

---

## 8. 引用

| 引用 | 位置 | 内容 |
| --- | --- | --- |
| R-1 | `01_original_baseline/…/mali-r49p1/…/mali_kbase_core_linux.c:1160-1166, 1518-1521, 1550-1553, 1568-1571, 1714-1716, 1830-1880` | R49 内联 padding 校验与 ioctl 80 实现 |
| R-2 | `01_original_baseline/…/csf/mali_kbase_csf.c:1367-1370` | R49 对 112 B CSG 的 `padding[9]` 全量校验 |
| R-3 | `01_original_baseline/…/csf/mali_kbase_csf_kcpu.c:3059-3063` | KCPU 命令 padding 校验 |
| R-4 | `01_original_baseline/…/backend/gpu/mali_kbase_jm_hw.c:140, 1275-1283` | `limited_core_mask` 唯一消费者（JM 后端） |
| R-5 | `01_original_baseline/…/mali_base_hwconfig_features.h:154`、`mali_base_hwconfig_issues.h:596-614` | R49 的 `tKRx` features / issues |
| R-6 | `02_r56_source/…/mali_kbase_hwconfig_{features,issues}.h:152 / 634-651` | R56 的同名表 |
| R-7 | `02_r56_source/…/mali_kbase_core_linux.c:2583-2594`、`01…/mali_kbase_core_linux.c:3633-3645` | 两代相同的 G925 识别逻辑 |
| R-8 | `02_r56_source/…/mali_kbase_gpuprops.c:583-880` | props 的 TLV 序列化、`prop_buffer_size` 计算 |
| R-9 | `02_r56_source/…/include/uapi/…/mali_gpu_props.h:78, 111-112` | R56 新增的 3 个字段类型 |
| R-10 | `02_r56_source/…/mali_kbase_ioctl_helpers.h` | 48 个钩子、`28+5+15` 三分类（脚本复核） |
| R-11 | `02_r56_source/…/csf/mali_kbase_csf.c:657` | GLB ≥ 1.1.0 的硬要求 |
| R-12 | `01_original_baseline/kernel_ref_mt6991/vendor_dlkm/mali_kbase_mt6991_r49.ko`（`strings`） | OEM 构建启用 `CONFIG_MALI_MTK_FENCE_DEBUG` |

*本文件不含任何源码或配置改动。*
