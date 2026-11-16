# Stage 4 剩余项目逐项核验（TASK-STAGE4-REMAINDER）

> **本文件做什么**：对 `STAGE4_FINAL_REPORT.md` 的 27 项台账**逐项回原始证据重算**，不复制上一轮统计；并把查出的数值/机制更正登记下来。**第 3 版（2026-11-16 下午）并入了第三轮真机采集的回传结果**（§2 N-8～N-10），五态由 8/12/1/6 更新为 **8/13/1/5**；同时改写 U4-26 的结论（设备内核为第三方重编）。
>
> **本文件不做**：不改驱动源码、不改 Kconfig/Kbuild、不改 workflow、不编译、不刷机、不部署。全部改动为纯文档。
>
> **与相邻文档的分工**：DDK 路线见 [`DDK_DUAL_TRACK_ASSESSMENT.md`](DDK_DUAL_TRACK_ASSESSMENT.md)；R49 改造预研见 [`R49_DDK_ADAPTATION_PLAN.md`](R49_DDK_ADAPTATION_PLAN.md)；真机采集方案见 [`STAGE4_DEVICE_COLLECTION_PLAN.md`](STAGE4_DEVICE_COLLECTION_PLAN.md)。
>
> 证据等级沿用 `05/08` §0.1：**[D·A]/[D·B]/[D·C]** 设备实测三分 · **[B]** 可核验构建记录 · **[P]** 用户声明 · **[E1]** 源码/二进制直接证据 · **[E2]** 交叉推导 · **[E3]** 惯例推断 · **[U]** UNKNOWN

---

## 0. 一句话结论

> **五态：27 项 = CLOSED 8 / PARTIAL 13 / BLOCKED 1 / OPEN 5**（`D-035`；三轮趋势见 §4.2.1）。**P0 仍是 3 项，一项未动**。
>
> **三轮真机采集的真实效果**：未闭合项 **22 → 19 → 19**，但其中"什么都没查到"的 OPEN 从 **13 → 6 → 5**（性质从"不知道"变为"知道差什么"）。闭合的三项（U4-20 / U4-26 / U4-27）全在 P2。**P0 / P1 无一闭合**——这不是采集不够，而是 P0/P1 缺的是**行为**（padding 字节、故障表现、商业固件）与**调用面**（`strace`），只读采集拿不到。
>
> **第三轮没有新增状态，只做了一处表述更正**：`05/MANIFEST` §1 早已登记"设备运行时内核 = 第三方 GKI 构建（KernelSU 补丁）"，但 U4-26 一直写成"设备侧已闭合、与 CI 产物比对未做"。既然内核来源早有记录，该项的答案**本应是"否"**。第三轮独立复现了构建者、KSU 域与 taint 位解码，把这句话写直：**设备 boot 不是 CI 产物**（`D-036`）。`/vendor`、`/vendor_dlkm` 仍为原厂只读 `erofs`（U4-27），**被审计的固件与 `kbase.ko` 本体未被替换**，故设备读数仍有效。
>
> **最重要的单点结论不变**：R56p0 要求 CSF 固件 header **0.4** 且用 `!=` **严格相等**比较（`csf_firmware.c:86`/`:2698`），设备固件实测 **0.3** → **R56 Kbase 加载原厂固件时在 header 校验阶段就 `-EINVAL`，早于 entry 解析**。所以**固件约束不可能靠 DDK 改造消除**，U4-12 是独立阻断项。这条从"任务书的判断"升级为 **[E1]+[D·A] 双侧证据**（§2 N-7 推论 2，第三轮逐字节复现）。
>
> **另外三处数值口径更正**：GPU 属性 ID 是 **83 共同 + 3 新增**（不是 83/83 不变）；序列化 props 缓冲区 **749 → 781 B**（不是 568 → 592，后者是 `sizeof` 人工推算）；ioctl 集合 **54 → 50**（删 6 增 2，不是"55 个"）。

---

## 1. 复核方法与边界

| 项 | 内容 |
| --- | --- |
| 起点 | 第一版 `HEAD = bbaeaf2`（与任务书基线一致）；**第 2 版基线 `faae673`**；**第 3 版基线 `f4f4c85`**（含第一/二轮采集修复提交） |
| 方法 | 对每一项回**源码逐字段/逐枚举**重算；对上一轮的数字用脚本重新生成，不复用报告措辞 |
| 新增采集 | **第一版：0**（纯源码复核）。**第 2 版并入第二轮**（脚本 v1.1）。**第 3 版并入第三轮**（脚本 v1.2，2026-11-16 14:12，`SELFCHECK=632`）：用户在本机执行并回传 zip，全程只读；**本审计侧只做判读，未接触设备、未执行任何设备命令** |
| 工具 | `git` / `grep` / `sed` / Python3（结构体与枚举解析脚本，脚本本身不入库） |
| 不可越界 | 不改 `01_original_baseline/`、`02_r56_source/`；不编译；不刷机；不进入 Stage 5 |

> **第一版**用过一次性脚本 4 个（ioctl 集合比对、props 缓冲区字节数、padding 钩子三分类、结构体字段尺寸），全部只读源码、输出为文本。
> **第二、三轮**另加 3 个：`__versions` 记录解析（hexdump → symbol/CRC）、符号方向统计、逐段行数对比。前两个的复现命令已固化在 [`evidence/stage4_round3_20261116/symbols/README.md`](../05_userspace_firmware/evidence/stage4_round3_20261116/symbols/README.md) §3，**任何人可用同样命令得到同样结果**。

---

## 2. 十项新发现（N-1～N-5 源码复核 ／ N-6～N-10 三轮真机采集）

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
| ~~这是**仓库基线** kbase，设备构建**未直接验证**~~ | ✅ **2026-11-16 已在设备构建上复核**：`/vendor_dlkm/lib/modules/mali_kbase_mt6991_r49.ko`（2,328,064 B）上 `Internal fence wait` = **1**、`Internal fence timeouts` = **4**、`ged_mali_event_notify_fence_timeout_event` = **2** → 该结论对**设备构建**同样成立，等级升为 **[D·A]** |
| 原推理链 | [E1]（同源码、不同构建）→ 现在有 [D·A] 直接背书 | 同 release 串 `r49p1-03bet0`，`mali_*` 三个模块中只有 kbase 有实质差异（`+17,640 B`） |
| 复核命令 | `strings /vendor_dlkm/lib/modules/mali_kbase_mt6991_r49.ko \| grep -c "Internal fence wait"`，见 `STAGE4_DEVICE_COLLECTION_PLAN.md` §5 G 段 | 已执行，输出见 `§9.2` |

> **为什么这条重要**：它把 U4-14 的"80 是否可能被调用"变成"80 在 OEM 上确实存在，所以 DDK **有理由**调用它；若 R56 上没有，DDK 会拿到 `-ENOTTY`"。

---

### N-6 · 真机实测：SKU 确证 + import 面量化（2026-11-16）

| # | 事实 | 证据 | 等级 |
| --- | --- | --- | --- |
| 1 | GPU 为 **Mali-G925-Immortalis 12 cores r0p1 0x0D080300** | `/sys/class/misc/mali0/device/gpuinfo` 与 `/sys/devices/platform/soc/48000000.mali/gpuinfo` 两路一致 | **[D·A]** |
| 2 | R49 kbase import **513** 条、ged import **241** 条；其中 **84 条是 MTK 侧符号** | `readelf -x __versions` 全量解析，见 `05/evidence/stage4_round1_20261116/` | **[D·A]** |
| 3 | `ged.ko` **不** import 任何 `kbase` 符号 | 241 条里搜 `kbase` 为空 | **[D·A]**（Stage 3 "零反向依赖"定理的实测复核） |
| 4 | `module_layout` CRC 两模块相同 = `0x4e276f37` | 同上 | **[D·A]** |

**意义**：

- 第 2 条给 `R49_DDK_ADAPTATION_PLAN.md` §7 一份**可逐条核对的 84 项接口面**（`ged_*` / `gpufreq_*` / `gpueb_*` / `mtk_*` / `wait_gpueb`），不再是"大致依赖 GED/GPUFreq"的模糊表述。这是 DDK-B 路线**唯一已经量化到符号级**的约束。
- 第 3 条意味着：换 kbase **不会**打破 ged 的链接，只会在 kbase 侧因缺符号而失败——失败面是**单向**的，便于定位。
- 第 1 条只确证**硬件 SKU**，**不**确证固件匹配；U4-12 仍是 BLOCKED，不得据此上调。

> **边界**：以上 CRC 数值只对**本机这次构建**有效，**不得**复制到其它设备或其它构建（`AGENTS.md` 禁止表述 ⑤）。

---

### N-7 · 第二轮真机采集：8 项闭合/推进，3 项 P0 未动

> 来源：`stage4_remainder_20261116_131307.txt`（56,138 B / 770 行，`SELFCHECK` = **668**；脚本 v1.1）。用户在本机 aShell You 执行并回传，**全程只读**。
> 逐条读数与判读见 [`05_userspace_firmware/evidence/stage4_round2_20261116/`](../05_userspace_firmware/evidence/stage4_round2_20261116/README.md)。

| # | 事实 | 证据 | 等级 |
| ---: | --- | --- | :---: |
| 1 | 固件 header 全字段：magic `0xC3F13A6E`、**0.3**、`version_hash 0x030A0000`、**`entry_end_offset = 1000`**；`0x14` 处首 entry `0x2000` → type=INTERFACE、size=32，三项对齐/长度校验全过 | §B-1 + R49 源码 `:108`/`:110`/`:177`/`:2794` | **[D·A]**+**[E1]** |
| 2 | 尾部 32 B 全 `00`；尾部 4 KiB 可打印串 **0** 条 | §B-2 / §B-3 | **[D·A]** |
| 3 | 内核 `build-id = 0c637c57d1ad6f81f4de95c6dbbc92a8f9153408`（20 B 完整） | §D-1 `/sys/kernel/notes` | **[D·A]** |
| 4 | kbase `version = r49p1-03bet0`、**`UK version 1.30`**、`srcversion CAC308B0D61305ACE6017E3` | §D-4 | **[D·A]** |
| 5 | **`GLES: ARM, Mali-G925-Immortalis MC12, OpenGL ES 3.2 v1.r49p1-03bet0.4505ac17...`** | §K-3 `dumpsys SurfaceFlinger` | **[D·A]** |
| 6 | **`padding is only supported for UMM`**、**`Invalid reserved field not 0 in queue group create`** 两条串在设备 ko 里 | §G-5 | **[D·A]** |
| 7 | `kbasep_ioctl_set_limited_core_count` 串存在 | §G-4 | **[D·A]** |
| 8 | **`vulkan.mali.so` 是桩**：已定义函数只有 `mali_vk_vendor_stub`（**24 B**），`DT_NEEDED` 首项 `libGLES_mali.so`，`RUNPATH $ORIGIN/../egl` | §J | **[D·A]** |
| 9 | **`------------RE GLES (Ganesh)------------`** | §K-3 | **[D·A]** |
| 10 | **`/vendor` / `/vendor_dlkm` 均为 `erofs ro`，`mountinfo` 无 overlay 条目** | §C-1 / §C-3 | **[D·A]** |
| 11 | `dmesg` 97,430 行中 `Loading Mali firmware` **0 条**；`/sys/kernel/debug` **未挂载** | §H-2 / §I | **[D·A]**（阴性） |
| 12 | 25 个进程持有 `/dev/mali0`（含 SF、camerahalserver、systemui、微信） | §K-4 | **[D·A]** |

**三条推论**

1. **第 5 条把"原厂三方配套"从 [E1] 推到 [D·A] 双侧实测**：用户态 DDK 自报 `v1.r49p1-03bet0...`，内核 kbase 自报 `r49p1-03bet0`，**逐字符相同**。换任一侧都破坏配套——这正是 DDK-B（R56 Kbase + R49-derived DDK）必须同时解决固件的原因。
2. **第 1 条把 U4-12 的阻断机制定死了**：R56p0 要求 header **0.4** 且用 `!=` **严格相等**（`:86`/`:2698`），设备固件是 **0.3** → **在 header 校验阶段就 `-EINVAL`**，早于 entry 解析。所以"DDK 改造能绕过固件约束"这个想法**在源码层面不成立**，与任务书的判断一致。因固件在首次 `open()` 加载（非 probe），失败表现为 `open` 返回错误、**不 bootloop**。
3. **第 11 条是阴性结果，但它关掉了一条路线**：U4-02（运行时 GLB 版本）靠 `dmesg` 或 `debugfs` 都不可行——前者日志已被环形缓冲滚掉（最早一行在 72,700 s 后），后者 debugfs 根本没挂。

**同时发现脚本 v1.1 三处判读缺陷**（数据取到了、标签贴错了，已修 v1.2，`D-034`）：

| 缺陷 | 表现 | 为什么不影响本文结论 |
| --- | --- | --- |
| `/proc/modules` 列错位 | 输出 `taint=0x000...` | 第 6 列实为**加载地址**（`kptr_restrict` 清零），非 taint；本文**从未**引用该列做结论 |
| note 偏移错 4 字节 | `build-id: 474e5500c5ea...` | `474e5500` 是 ASCII `"GNU\0"`；U4-26 用的是**内核** build-id（第 3 条），不受影响 |
| 符号统计正则反序 | `GLOBAL DEFAULT FUNC: 0` | readelf 列序是 `FUNC GLOBAL DEFAULT`；样本行已给出实际符号（第 8 条即据此判定） |

---

### N-8 · 第三轮真机采集：独立复现"第三方内核"既有记录，并把 U4-26 的答案**显式化**

> 来源：`stage4_remainder_20261116_141236.txt`（58,428 B / 735 行，`SELFCHECK` = **632**；脚本 **v1.2**）。逐条读数见 [`05_userspace_firmware/evidence/stage4_round3_20261116/`](../05_userspace_firmware/evidence/stage4_round3_20261116/README.md)。

**先澄清一件事，避免把旧闻当新闻**：`05_userspace_firmware/MANIFEST.md` §1 的"三层内核版本"表（`D-020`）**早有记录**——

| 层 | 登记值 | 证据等级 |
| --- | --- | --- |
| 设备运行时内核 | **第三方 GKI 构建**（KernelSU 补丁；GKI `android15-6.6`，`6.6.143-android15-8-gf9aa2fec23c3-4k`，`chandr1000@SukiSU-Ultra-v41181`） | **[D·B]**+**[B]** |
| 原厂内核（推定） | `6.6.118-android15-8-g54a15cf3acba-4k`（由 18 个厂商 `.ko` vermagic 反推） | **[E2]** |
| 仓库基线内核 | `6.6.118-android15-8-g57e634f35c1b-4k`（OS3.0.305.0） | **[E1]** |

所以"设备内核是第三方的"**不是本轮新发现**。本轮做的是**独立复现 + 补齐三项此前没有直接读数的证据**：

| 证据 | 读数 | 此前状态 | 等级 |
| --- | --- | --- | :---: |
| 内核构建者/主机 | `chandr1000@SukiSU-Ultra-v41181` | 已登记于 `05/MANIFEST` §1（[D·B]） | **[D·A]**（本轮 `/proc/version` 直读） |
| SELinux 域 | `u:r:ksu:s0` | 已登记（root 环境） | **[D·A]** |
| root 痕迹 | `/data/adb/ksu` `EXISTS`、`/data/adb/modules` `EXISTS`；`/data/adb/susfs`、`/sbin/.magisk` **`ABSENT`** | 未明确排除 SUSFS / Magisk | **[D·A]**（新增判别） |
| 全局 taint | `4609` = `0x1201` = bit0 **P** + bit9 **W** + bit12 **O**（**无** bit13） | 此前只有"无 `F`（forced）" | **[D·A]**（新增位解码） |

**真正需要更正的是台账表述，不是事实**：U4-26 此前记为"✅ 已闭合（设备侧）——内核 build-id 已取；与 CI 产物的一元比对未做"。既然 §1 早已写明运行时内核是第三方构建，那么"设备 boot 是否即 CI 产物"的答案**本应是"否"**，而不是"设备侧已取、待比对"。第三轮把这句话写直：**答案 = 否**（`D-036`）。状态仍为 CLOSED——问句答完了。

**四条推论（写法不变，但适用范围要说清）**：

1. 本轮回传的全部 `[D·A]`/`[D·B]` 证据来自 **root + 第三方内核**环境，**不能直接代表未 root 零售机**的可观测面。
2. `/vendor`、`/vendor_dlkm` 仍是原厂 `erofs ro`，`mountinfo` 无 overlay 条目（U4-27）→ **固件文件与 `kbase.ko` 本体未被替换**，第 1、5 节的读数依然有效。
3. 内核虽被重编，`kbase.ko`（原厂 `vendor_dlkm` 文件）能加载并 `state=Live`、`refs=91`，且 dmesg 全程 `disagrees about version of symbol` = **0**（§H-4）→ 该内核导出符号的 `modversions` CRC 与 `kbase.ko` 的 `__versions` 期望**一致**，否则模块根本装不上。这把 H-4 的"0 条"从"无信息的阴性"升级为**加载成功的弱旁证**。
4. `tainted ≠ 0` **不是**本项目造成的（本轮无任何写入/装载），是 OEM 私有+树外模块的固有结果；`bit12 = O` 与 OEM `kbase`/`ged` 的存在吻合。

### N-9 · `/proc/modules` 的 `deps` 是**反向依赖**（谁在用我），读反会得出相反结论

第三轮 E 段 `ged` 行的 `deps` 含 `mali_kbase_mt6991_r49`：

```
ged  size=684032  refs=5  deps=mtk_mbraink_v6991,...,mali_kbase_mt6991_r49,...  state=Live
```

若按"本模块依赖谁"读，会得出"`ged` 依赖 `kbase`"，并据此推翻上一轮"`ged.ko` 零 import `kbase` 符号"的结论。

**`__versions` 的真值给出相反答案**（第三轮把符号表全量解析，见 `symbols/`）：

| 方向 | 条数 | 明细 |
| --- | ---: | --- |
| `ged.ko` 的 241 条导入中，含 `kbase` 的 | **0** | — |
| `kbase.ko` 的 513 条导入中，MTK 侧符号 | **84** | 49 `ged_*` / 16 `gpufreq_*` / 4 `gpueb_*` / 15 `mtk_*` |

即 **`kbase` 是消费者，`ged` 是被消费者**。`deps` 列列的是"谁在用我"，四条自洽验证：

| 行 | `deps` 含 | 按"谁在用我"解释 | 成立 |
| --- | --- | --- | :---: |
| `ged` | `mali_kbase_mt6991_r49` | kbase 使用 ged | ✅ 与 49 条 `ged_*` 导入一致 |
| `mtk_gpu_pdma_mt6991` | `mali_kbase_mt6991_r49` | kbase 使用 pdma | ✅ |
| `mtk_gpufreq_wrapper` | 含 `mali_kbase_mt6991_r49` | kbase 使用 wrapper（16 条 `gpufreq_*`） | ✅ |
| `mali_kbase_mt6991_r49` | `-`（空） | 无模块使用 kbase 符号 | ✅ 与 ged 零 `kbase_*` 导入一致 |

**结论**：`kbase` 是**叶子消费者**——它向 MTK 侧要 84 个符号，MTK 侧一个都不向它要。这条直接把 U4-22 的子项 a（依赖面）定量闭合。

### N-10 · HWUI 走 Vulkan 与 SF RenderEngine 走 GLES 是两条独立路径

同一份报告里两条看似矛盾的读数：

| 读数 | 位置 | 含义 |
| --- | --- | --- |
| `ro.hwui.use_vulkan = true` | §K-1b | **App 层 HWUI** 优先 Vulkan |
| `------------RE GLES (Ganesh)------------` | §K-3 | **SurfaceFlinger 的 RenderEngine** 用 GLES(Ganesh) |

判读：U4-20 的问句是"**SF RenderEngine 后端**"，答案是 GLES(Ganesh)，**不受 `ro.hwui.use_vulkan` 影响**。不要把后者读成"系统整体走 Vulkan"，也不要用它推翻 U4-20。

同时 `vulkan.mali.so` 仍是 133,416 B 的桩（`defined = 1`，只有 24 B 的 `mali_vk_vendor_stub`，`DT_NEEDED` 首项 `libGLES_mali.so`）→ 即使 HWUI 走 Vulkan，最终仍落到 `libGLES_mali.so`。**REA 目标库不变**。

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

### 3.3 U4-12（R56 CSF 固件）—— **BLOCKED**，阻断机制已锁定为一行 `!=` 比较

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
| 1 | header 版本 | `offset 4 = 0x04`、`offset 5 = 0x00` | `csf/mali_kbase_csf_firmware.c:85-86, 2698-2701`，`!=` 严格、无 fallback。**2026-11-16 实测：原厂固件 `offset4 = 0x03` → 判据 1 直接不满足** |
| 2 | magic | `offset 0-3 = 6e 3a f1 c3`（`0xC3F13A6E` 小端） | 同上 |
| 3 | GPU 型号 / core mask | 与 G925 **MC12**（12 核）一致；产品 ID 应为 `TKRX` | `mali_kbase_hw.c:272`、`mali_kbase_gpu_id.h:174`；`gpuinfo` 输出可比对 |
| 4 | **GLB 接口版本 ≥ 1.1.0** | 运行时 `iface->version >= kbase_csf_interface_version(1,1,0)` | `csf/mali_kbase_csf.c:657`、`csf/mali_kbase_csf_scheduler.c:1794`（R49 同阈值，故**不是新增门槛**） |
| 5 | **interface entry 布局** | `entry_end_offset`（header offset 0x10）与 R56 的 entry 表一致 | `csf/mali_kbase_csf_firmware.c` 的 entry 解析器。**实测原厂 `entry_end_offset = 1000`，首 entry 为 INTERFACE/32 B（自洽）**，可作 R56 固件的对照基线 |
| 6 | 与 DDK 的配套性 | 同一 release（`r56p0-18eac0`）交付 | — |

> **禁止**：改 R49 固件 8 字节 header 冒充 0.4。header 只是入口校验，entry 表（GLB 版本、region 布局）随 release 变化；改了只会把"早失败"变成"晚崩溃"。
>
> **注意第 4 项**：GLB ≥ 1.1.0 是 R49/R56 **共同**要求，因此它不构成"R56 更严"的证据；不要把它写成新增门槛。

**2026-11-16 实测后的最终定性**（`firmware_header.md` §5）：

| 量 | 值 | 结论 |
| --- | --- | --- |
| 原厂固件 header | **0.3**（`offset 0x04 = 03`、`0x05 = 00`） | 判据 1 **不满足** |
| R56p0 要求 | **0.4**，`!=` **严格相等** | — |
| 失败点 | `mali_kbase_csf_firmware.c:2698` 的 header 校验 | **早于** entry 解析、早于 `parse_capabilities` |
| 表现 | `dev_err("Firmware header version 0.3 not understood")` → `-EINVAL` | 因固件在**首次 `open()`** 加载（非 probe），**不 bootloop**，`open` 返回错误 |

⇒ **U4-12 的阻断是"一行 `!=` 比较"，而不是"参数不匹配"。** 这意味着：
- 不可能通过调参、改配置、改 DDK 绕过；
- 唯一出路是取得 header 0.4 的 R56 固件（商业件），或自行构建固件（需 R56 DDK 的固件工程，属商业件）；
- 改 header 字节只能把"早失败"变成"晚崩溃"，**已在禁止清单里**。

---

## 4. 五态重算（含计数规则变更）

### 4.1 新计数规则（`D-033`）

> **PARTIAL 的判定**：一个 U4 项若**已被拆成可独立判定的子项**，且**至少一个子项 CLOSED、至少一个子项未闭合**，则整项记 **PARTIAL**；否则按 OPEN / CLOSED / BLOCKED 记。

上一轮用这条规则时只套用在 U4-04 / U4-24 / U4-25 上，U4-14 与 U4-15 虽同样"子项 a 已闭、子项 b 未闭"，却仍记 OPEN。该轮统一规则（不是重新定性，只是把同一标准用全）。

**2026-11-16 第三轮（真机采集回传后）规则不变，只是把同一标准套到新证据上**：U4-20 / U4-26 / U4-27 的**全部**判定条件均已满足 → CLOSED；U4-11 / U4-17 / U4-21 / U4-23 是"主问题已答、细节未答" → PARTIAL。判据逐条写在 §5 的"已有证据 / 缺失证据"两列，不靠印象。

**2026-11-16 第四轮（第三轮真机采集，脚本 v1.2）**：套用同一规则处理两个新事实——
- **U4-22** 首次具备"可独立判定的子项"：a 依赖面（`kbase` 84 条 MTK 侧导入 + `HWC`/`mapper` 的 `NEEDED libged`）已定量闭合，b 失效表现未观察 → **OPEN → PARTIAL**。
- **U4-26** 的问句已有确定答案（**否**，内核为第三方重编）→ 维持 CLOSED，但**结论反转**，不算状态变化。

### 4.2 结果

| 状态 | 第二轮 | 第三轮 | **本轮（第四轮）** | 变化 |
| --- | ---: | ---: | ---: | --- |
| ✅ CLOSED | 5 | 8 | **8** | 不变（U4-26 结论改写，状态不变） |
| ⚠️ PARTIAL | 8 | 12 | **13** | **+1**：U4-22 |
| ⛔ BLOCKED | 1 | 1 | **1** | 不变（U4-12） |
| ○ OPEN | 13 | 6 | **5** | **−1**：U4-22 移出 |
| ? UNKNOWN | 0 | 0 | **0** | 不变 |
| **合计** | **27** | **27** | **27** | ✓ |

明细：

| 状态 | 项 |
| --- | --- |
| CLOSED（8） | U4-01、U4-03、U4-05、U4-08、U4-09、U4-20、**U4-26**（结论改写为"否"）、U4-27 |
| PARTIAL（13） | U4-04、U4-06、U4-07、U4-10、U4-11、U4-14、U4-15、U4-17、U4-21、**U4-22**、U4-23、U4-24、U4-25 |
| BLOCKED（1） | U4-12 |
| OPEN（5） | U4-02、U4-13、U4-16、U4-18、U4-19 |

### 4.2.1 四轮趋势

| 轮次 | CLOSED | PARTIAL | BLOCKED | OPEN | P0 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 第一轮（`STAGE4_FINAL_REPORT`） | 5 | 6 | 1 | 15 | 3 |
| 第二轮（`D-033` 五态统一） | 5 | 8 | 1 | 13 | 3 |
| 第三轮（`D-034`） | 8 | 12 | 1 | 6 | 3 |
| **第四轮（本轮，`D-035`）** | **8** | **13** | **1** | **5** | **3** |

**净效果**：未闭合项 **22 → 19 → 19**（第四轮只是把 U4-22 从 OPEN 移入 PARTIAL，总数不变），但"什么都没查到"的 OPEN 从 13 降到 **5**——未知面的**性质**变了：从"不知道"变成"知道差什么"。**P0 仍然 3 项，一项都没动**——因为 P0 的三项（U4-04 / U4-10 / U4-12）都需要**反汇编、故障注入、商业件**，不在只读采集的能力范围内。这是四轮下来最重要的一句话。

### 4.3 优先级分布（未变）

| 优先级 | 总数 | 未闭合 | 已闭合 |
| --- | ---: | ---: | ---: |
| **P0** | 3 | **3**（U4-04 / U4-10 / U4-12） | 0 |
| P1 | 8 | 8（U4-02 / U4-11 / U4-14 / U4-15 / U4-17 / U4-22 / U4-24 / U4-25） | 0 |
| P2 | 8 | **5**（U4-06 / U4-07 / U4-16 / U4-19 / U4-21） | **3**（U4-20 / U4-26 / U4-27） |
| P3 | 3 | 3（U4-13 / U4-18 / U4-23） | 0 |
| **合计** | **22** | **19** | **8** |

校验：19 + 8 = 27 ✓；未闭合 19 = PARTIAL 13 + BLOCKED 1 + OPEN 5 ✓。

> 本轮闭合的三项全部在 P2，**P0 / P1 无一闭合**。这不是采集做得不够，而是 P0 / P1 的缺口性质决定的：
> P0 要的是**行为**（padding 字节、故障表现、商业固件），P1 要的是**调用面**（strace）与**商业件**。
> 只读采集能拿到的是**静态事实**，静态事实恰好已经把 P2 清完。

---

## 5. 全量逐项核验表

> 列含义：**只读** = 能否只用手机只读命令闭合；**真机** = 是否必须真机；**REA** = 是否必须二进制逆向；**商业件** = 是否必须取得 Arm/MTK 授权交付物。

| ID | 内容 | 优先级 | 状态 | 已有证据 | 缺失证据 | 最低成本核验方法 | 只读 | 真机 | REA | 商业件 |
| --- | --- | :---: | :---: | --- | --- | --- | :---: | :---: | :---: | :---: |
| U4-01 | 固件 header 实测值 | ~~P0~~ | ✅ CLOSED | `6e 3a f1 c3 03 00 00 00` → **0.3** [D·A] | — | 已闭合 | — | — | — | — |
| U4-02 | 原厂固件**运行时** GLB 版本 | P1 | ○ OPEN | kbase 只在 `iface->version` 生效、**不打印**；`dev_notice("Loading Mali firmware 0x%x")` 只给 `version_hash`（≠ GLB）。**2026-11-16 实测**：dmesg 97,430 行中 `Loading Mali firmware` = **0 条**（开机 72,700 s 前，已被环形缓冲滚掉）；`/sys/kernel/debug` 未挂载（§2 N-7）→ **两条低成本路径均已排除** | `iface->version` 的运行时值 | ①GLB 寄存器 MMIO 读（需内核侧手段）；②重载 mali 模块后再抓 dmesg（属状态变更，须单独授权）；③离线解析固件 shared-interface 初值（需 REA） | ❌ | ✅ | ⚠️ | ❌ |
| U4-03 | DTB `firmware-name` 覆盖 | — | ✅ CLOSED | DT 双向无该属性 | — | 已闭合 | — | — | — | — |
| **U4-04** | DDK padding / props 行为 | **P0** | ⚠️ PARTIAL | a ✅、b ✅、**c1 缩至 4 条致命项**（§3.1）、c2 机制明 [E1]；**2026-11-16 二进制确证**：`Invalid reserved field not 0 in queue group create` 与 `padding is only supported for UMM` 两条串在**设备 ko** 里（N-7）→ R49 侧校验代码确实存在且在运行时全部通过 | c1 的 4 项致命位（首为 `CS_QUEUE_REGISTER`）、c2 的 DDK 协商行为 | 反汇编 R49 DDK 的 ioctl 打包点，或取得 R49 DDK 源码 | ⚠️ | ✅ | ✅ | ❌ |
| U4-05 | 是否有 Vulkan | — | ✅ CLOSED | `vulkan.mali.so` 133,416 B 薄壳 | — | 已闭合 | — | — | — | — |
| U4-06 | EGL 加载机制细节 | P2 | ⚠️ PARTIAL | 可用性 [D·A]；`ro.hardware.egl=mali`；`mt6991/` 子目录布局；**`/linkerconfig/ld.config.txt` 中 `namespace.sphal` 与 `namespace.default` 均含 `+= /vendor/${LIB}/egl`**；`ro.vendor.arm.egl.configs.*` 全表（N-7） | `/vendor/lib64/egl/` 目录清单、`ro.egl.additional_libraries` | `ls -l /vendor/lib64/egl/`；`getprop ro.egl.additional_libraries` | ✅ | ✅ | ❌ | ❌ |
| U4-07 | 分配走 dma-buf heap 还是 ion | P2 | ⚠️ PARTIAL | 两库都在 NEEDED 里 | 实际路径 | `strace -f -e trace=openat` 看 `/dev/dma_heap/*` vs `/dev/ion` | ⚠️ | ✅ | ❌ | ❌ |
| U4-08 | HWC 是否依赖 DDK | — | ✅ CLOSED | NEEDED 面无 Mali 库 | — | 已闭合 | — | — | — | — |
| U4-09 | VINTF / init | — | ✅ CLOSED | 三份 manifest 齐备 | — | 已闭合 | — | — | — | — |
| **U4-10** | 失败是否 bootloop | **P0** | ⚠️ PARTIAL | 静态：**不阻断启动**、可重试 [E1] | 真实故障的可用性丧失面 | 故障注入（需可回滚环境） | ❌ | ✅ | ❌ | ❌ |
| U4-11 | 固件 GLB 尾部版本 / `entry_end_offset` | P1 | ⚠️ PARTIAL | **`entry_end_offset = 1000` 已取**（`0x10`，`1000 ≤ 307200` → 截断检查必过 [E1]+[D·A]）；尾部 32 B 全 `00`、尾部 4 KiB 可打印串 **0 条** → **尾部不携带任何版本**（`evidence/stage4_round2_20261116/firmware_header.md`） | 固件 GLB 的**实际运行版本**（与 U4-02 同源，已非只读可解） | 随 U4-02 | ❌ | ✅ | ⚠️ | ❌ |
| **U4-12** | R56 固件是否匹配 G925 MC12 | **P0** | ⛔ BLOCKED | 交付包 23 条目 0 命中；验收判据 6 条已写定（§3.3）；**2026-11-16 新增硬证据**：R56p0 要求 header **0.4** 且 `!=` **严格相等**（`csf_firmware.c:86`、`:2698`），设备固件实测 **0.3** → **在 header 校验阶段即 `-EINVAL`**，早于 entry 解析。故此项**不可能被 DDK 改造消除**（`firmware_header.md` §5） | **固件实体**（header 0.4 + G925 MC12 配套） | 不可由设备/源码取得；不得改 header 字节冒充 | ❌ | ❌ | ❌ | ✅ |
| U4-13 | NX 相关 GLB 字段 | P3 | ○ OPEN | 原厂固件已证实**完整可解析**（magic/0.3/entry 首项 INTERFACE-32B 自洽，N-7）；缺的是 R56 侧字段语义 | R56 期望的 NX/GLB 配置项清单 | 需 R56 固件或 Arm 文档；原厂固件侧可离线解析但不知"R56 要什么" | ❌ | ❌ | ⚠️ | ✅ |
| **U4-14** | DDK 是否用被删的 6 个 ioctl | P1 | ⚠️ **PARTIAL** | 删除清单独立复现（54→50）；**55 在 CSF 上是 no-op**（唯一消费者是 JM 后端）；**80 在 OEM 上存在**（N-3/N-5）；实测 `CONFIG_MALI_MTK_FENCE_DEBUG` **为开**（`Internal fence wait`=1）；**2026-11-16 新增**：`kbasep_ioctl_set_limited_core_count` 串在设备 ko 里（N-7）→ 55 的**处理函数被编入** | DDK **是否真的调用**（编入 ≠ 调用） | `strace -f -e trace=ioctl` 看 `_IOC(_,0x80,nr,size)` 是否出现 8/12/32/35/55/80 | ✅ | ✅ | ❌ | ❌ |
| U4-15 | DDK 对新增 props 的处理 | P1 | ⚠️ **PARTIAL** | **3 个新 ID**、**+32 B**、TLV 机制、唯一硬门槛（§2 N-2） | DDK 是否 `size=0` 探测 | `strace` 看 GET_GPUPROPS 调用次数 | ✅ | ✅ | ❌ | ❌ |
| U4-16 | DDK 是否依赖 HWCNT 做 DVFS | P2 | ○ OPEN | — | trace | `strace` 看 `KINSTR_PRFCNT_SETUP` | ✅ | ✅ | ❌ | ❌ |
| U4-17 | Vulkan 薄壳 `api_version` / 加载机制 | P1 | ⚠️ PARTIAL | **加载机制已定性**：`vulkan.mali.so` 133,416 B，dynsym 仅 3 项，已定义函数**只有** `mali_vk_vendor_stub`（**24 字节**），`DT_NEEDED` 首项 `libGLES_mali.so`，`RUNPATH $ORIGIN/../egl`，`vkAcquireImageANDROID` 为 `UND` → **它是桩，真实现在 `libGLES_mali.so`**（N-7） | `api_version` 的来源（`vk_icd` 字段 / VINTF 声明） | `strings vulkan.mali.so \| grep -i icd`；`cat /vendor/etc/vintf/manifest.xml` 看 vulkan 段 | ✅ | ✅ | ❌ | ❌ |
| U4-18 | Vulkan 与 GLES 是否同批构建 | P3 | ○ OPEN | 两 Build ID 已取（`700e6d41…`） | 判据本身 | 需 Arm 构建记录 | ❌ | ❌ | ❌ | ✅ |
| U4-19 | Vulkan 是否用 GLES 不用的 ioctl | P2 | ○ OPEN | — | trace | 跑 Vulkan 用例 + `strace` | ✅ | ✅ | ❌ | ❌ |
| U4-20 | SF RenderEngine 后端 | P2 | ✅ CLOSED | **`dumpsys SurfaceFlinger` 直接输出 `------------RE GLES (Ganesh)------------`**，紧接 `GLES: ARM, Mali-G925-Immortalis MC12, OpenGL ES 3.2 v1.r49p1-03bet0.4505ac17...`（N-7）→ 后端 = **GLES(Ganesh)**，不是 Skia Graphite / Vulkan | — | 已闭合 | — | — | — | — |
| U4-21 | 是否有服务硬依赖 `/dev/mali0` | P2 | ⚠️ PARTIAL | **持有进程数：第二轮 25 → 第三轮 23**（`surfaceflinger`、`mediaserver`、`camerahalserver`、`systemui`、`com.miui.home`、微信、输入法、GMS 等；差异为进程生命周期，非系统变化）；节点 `crw-rw-rw- u:object_r:gpu_device:s0 10,282` | "硬依赖"的**等级**（持有 fd ≠ 不可降级） | 需在 GPU 不可用条件下观察（故障注入），或逐进程看 fallback 分支 | ❌ | ✅ | ⚠️ | ❌ |
| U4-22 | `libged` 失效的降级程度 | P1 | ⚠️ **PARTIAL** | **a 依赖面已定量闭合**（N-9）：`kbase.ko` 的 513 条导入中有 **84 条** MTK 侧符号（49 `ged_*`、16 `gpufreq_*`、4 `gpueb_*`、15 `mtk_*`），`deps` 四行自洽证明 `kbase` 是叶子消费者；`HWC`/`mapper` 的 `NEEDED libged`；`libged.so` `defined=100` | **b 真实失效表现**（缺 `ged`/`libged` 时 GPU 是降级还是完全不可用） | 需故障注入（卸载/屏蔽 ged 或替换 libged），或代码级追 fallback 分支 | ❌ | ✅ | ⚠️ | ❌ |
| U4-23 | `libgpud` 与 `libgpud_sys` 符号关系 | P3 | ⚠️ PARTIAL | 两者 `DT_NEEDED` **全表已取**（16 / 17 项）；**第三轮补全导出面**：`libgpud` `defined=335`、`libgpud_sys` `defined=372`（+37），`GLOBAL DEFAULT FUNC` 407 / 482，样本显示 `gpudVk*`/`gpudGl*`/`gpudEgl*` 同名共存 → **`_sys` 是超集/扩展版**；`libged.so` `defined=100` | **逐符号全量 diff**（当前只有计数 + 15 条样本，未导出完整符号集） | `readelf --dyn-syms -W <so> \| awk '$7!="UND"{print $8}' \| sort > a.txt`，两者 `comm -23/-13` | ✅ | ✅ | ❌ | ❌ |
| **U4-24** | 设备 `.ko` 身份 / CRC | P1 | ⚠️ PARTIAL | a ✅ 18 个全取；**b 已全量**：`kbase` **513** 条 / `ged` **241** 条 import 符号 + CRC32 已结构化落盘（`evidence/stage4_round3_20261116/symbols/`），`module_layout`=`0x4e276f37` 两模块相同；两模块 `.ko` 的 `sha256` 与 `__versions` dump `sha256` 均已取（第三轮） | **kCFI 类型哈希**（`__kcfi_typeid_*` 未采） | `readelf -x __cfi_*` / 补采 `__kcfi_typeid_*` | ✅ | ✅ | ❌ | ❌ |
| **U4-25** | 第三方内核差异面 | P1 | ⚠️ PARTIAL | a ✅；b 运行态不可观测（只在 CRC 不匹配时有意义） | c：导出符号集/CFI/调度 | `dmesg \| grep disagrees`；导出符号表需镜像 | ⚠️ | ✅ | ⚠️ | ❌ |
| U4-26 | 设备 boot 是否即 CI 产物 | P2 | ✅ CLOSED（**答案：否**） | 内核 `build-id = 0c637c57d1ad6f81f4de95c6dbbc92a8f9153408`（两轮逐字节一致）；**但 `/proc/version` 显示构建者 `chandr1000@SukiSU-Ultra-v41181`**，配合 `u:r:ksu:s0`、`/data/adb/ksu`、`tainted=0x1201`（P+W+O）→ **内核为第三方重编，非原厂 CI 产物**；`/vendor`/`/vendor_dlkm` 仍原厂 erofs（N-8、`D-036`） | — | 问句已答（**否**）。若要知"该第三方内核与原厂内核的差异面"，属另一问题，转 U4-25 | — | — | — | ⚠️ |
| U4-27 | `/vendor` 是否被 overlay | P2 | ✅ CLOSED | **`/vendor` = `erofs /dev/block/dm-13 ro`；`/vendor_dlkm` = `erofs dm-18 ro`；`mountinfo` 中两者均无 overlay 条目**。overlay 仅覆盖 `/product`、`/system`、`/system_ext` 的**子路径**，`lowerdir` 指向 `mi_ext`/`mi_product`（`firmware_header.md` §7） | — | 已闭合 | — | — | — | — |

**统计（2026-11-16 第三轮后，按"还差什么手段"分档）**

| 档 | 项数 | 项 | 说明 |
| --- | ---: | --- | --- |
| ✅ 已闭合 | **8** | U4-01/03/05/08/09/20/26/27 | 判据全部满足 |
| 🔧 一条只读命令即可 | **3** | U4-06、U4-23、U4-24 | 目录清单 / 符号对照 / kCFI 哈希；**不必跑全量脚本** |
| 📡 需 `strace`（只读、真机） | **5** | U4-07、U4-14、U4-15、U4-16、U4-19 | 看调用面与调用次数 |
| 🧩 需 REA / 反汇编 | **3** | U4-04、U4-17、U4-25 | U4-17 的目标已从 `vulkan.mali.so` 改为 `libGLES_mali.so`（N-7） |
| 💼 需商业件 | **3** | U4-12、U4-13、U4-18 | R56 固件 / Arm 构建记录 |
| 💥 需故障注入 | **3** | U4-10、U4-21、U4-22 | 须可回滚环境 |
| 📟 需运行时寄存器 / 内核手段 | **2** | U4-02、U4-11 | GLB 版本，同源 |

校验：8 + 3 + 5 + 3 + 3 + 3 + 2 = 27 ✓

> **与第二轮的差别**：上一版这里有 13 项标"只读可闭合"，其中 **9 项本轮真的闭合了或推进了**；剩下 4 项（U4-06/07/16/19）经实测发现只读不够——U4-07/16/19 需要 `strace` 看调用，U4-06 缺一个目录清单。上一版把 `strace` 也算进"只读"，本轮把它单列，因为 `strace` 需要额外工具与权限，且**看不到 ioctl 结构体内容**（`D-031`）。

---

## 6. 分档：谁能靠手机解决，谁不能

### 6.1 已由真机只读采集**闭合**（3 项）

| 项 | 判据 | 读数 |
| --- | --- | --- |
| **U4-20** | SurfaceFlinger 的 RenderEngine 后端 | `------------RE GLES (Ganesh)------------` |
| **U4-26** | 设备 boot 是否即 CI 产物 | **否**：内核构建者 `chandr1000@SukiSU-Ultra-v41181`、`u:r:ksu:s0`、`/data/adb/ksu` 存在、`tainted=0x1201`；`/vendor` 仍原厂 erofs |
| **U4-27** | `/vendor` / `/vendor_dlkm` 是否被 overlay | 两者均 `erofs ro`，`mountinfo` 无 overlay 条目 |

> 三项都在 P2。**没有一项在 P0 / P1** —— 这是四轮下来最需要如实说明的一点。
> **U4-26 是"闭合于否定答案"**：问句答完了，答案对项目不利——设备不是纯净环境，Stage 5 任何真机实验都必须写明这一点。

### 6.1b 已推进但**未闭合**（5 项）

| 项 | 拿到了什么 | 还缺什么 | 缺的那部分靠什么 |
| --- | --- | --- | --- |
| **U4-11** | `entry_end_offset = 1000`；尾部 32 B 全零、尾部 4 KiB 无串 | 固件 GLB 的**实际运行版本** | GLB 寄存器 MMIO 读 / 重载模块后抓 dmesg（需授权） |
| **U4-17** | 桩的定性（`mali_vk_vendor_stub` 24 B）、`DT_NEEDED`、`RUNPATH` | `api_version` 的来源 | `strings \| grep icd` + VINTF manifest（**一条只读命令**） |
| **U4-21** | 23 个进程持有 `/dev/mali0`，含 SF 与相机 HAL | "硬依赖"的**等级** | 故障注入，或逐进程看 fallback 分支 |
| **U4-22** | **依赖面定量**：`kbase` 84 条 MTK 侧导入（49 `ged_*`），`HWC`/`mapper` `NEEDED libged` | **失效表现**（降级还是全废） | 故障注入（屏蔽 ged / 替换 libged） |
| **U4-23** | 两库 `DT_NEEDED` 全表、`defined` 335 / 372（+37）、同名 `gpudVk*`/`gpudGl*` 样本 | **逐符号全量 diff** | 一条 `readelf` + `comm`（见 §6.1c） |

### 6.1c 还差**一条只读命令**（3 项，不必重跑全量脚本）

| 项 | 命令 |
| --- | --- |
| **U4-06** | `ls -l /vendor/lib64/egl/`；`getprop ro.egl.additional_libraries` |
| **U4-23** | `readelf --dyn-syms -W <so> \| awk '$7!="UND"'`（两库各一次） |
| **U4-24** | `readelf -x __cfi* <ko>` 或 `readelf -x __kcfi_typeid_* <ko>`（kCFI 类型哈希） |

### 6.1d 只读采集**读不出来**的（2 项，阴性结果已确证）

| 项 | 为什么读不出来 |
| --- | --- |
| **U4-02** | `dmesg` 97,430 行里 `Loading Mali firmware` = **0 条**（开机 72,700 s 前，已滚出环形缓冲）；`/sys/kernel/debug` **未挂载**。**两条低成本路径都已排除**，不是"没采到" |
| **U4-15** | 需要 `strace` 数 `GET_GPUPROPS` 的调用次数；这是行为观测，不是静态读取 |

### 6.2 必须 REA（离线反汇编）才能"确定"

| 项 | 对象 | 说明 | 成本变化 |
| --- | --- | --- | --- |
| **U4-04c1 残部** | `libGLES_mali.so`（53 MB） | 只看 `CS_QUEUE_REGISTER` / `CS_TILER_HEAP_INIT` / `MEM_ALLOC_EX` 的栈结构体是否 `{0}` 初始化。**不需全量分析**，定位到 ioctl 打包点即可 | 未变 |
| **U4-04c2** | 同上 | 看 `GET_GPUPROPS` 是否先发 `size=0` | 未变 |
| **U4-17 余部** | **`libGLES_mali.so`**（不再是 `vulkan.mali.so`） | 原计划分析 133 KB "薄壳"，本轮证实它只有 24 字节的桩函数 → **分析对象改为 53 MB 的 `libGLES_mali.so`** | ⬆️ **成本上升**（体量大两个数量级），但 U4-17 的主问题（加载机制）已答 |
| **U4-25c** | 内核镜像导出符号表 | 需镜像 | 未变 |

> **一条要写下来的教训**：上一版把"Vulkan 薄壳只有 133 KB，分析成本低"当作 U4-17 的优势。实测表明这 133 KB 里几乎没有实现代码——**文件小 ≠ 好分析，可能只是因为它什么都没做**。这条同样适用于任何"轻量封装层"的判断。

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
| U4-21 | `/dev/mali0` 持有者的"硬依赖"等级（持有 fd ≠ 不可降级） |
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
| 8 | "所有 GPU 链路模块 `taint=0`，无强制装载" | 采集脚本 v1.1 的 E-3 段输出 | **该列不是 taint**，是 `/proc/modules` 第 6 列的**加载地址**（`kptr_restrict` 下为 0）。taint 须读 `/proc/sys/kernel/tainted`。**此结论作废**，不得引用 | `D-034`、`evidence/stage4_round2_20261116/README.md` §3 |
| 9 | "kbase 模块 `build-id = 474e5500c5eac1f0...`" | 采集脚本 v1.1 的 D-4 段输出 | 错在 `-j 12`：note 布局是 `namesz/descsz/type/name(对齐)/desc`，desc 起点应为 `16`。`474e5500` 是 ASCII `"GNU\0"`。**真实 build-id 未取到**，不得引用 | 同上 |
| 10 | "`libgpud.so` 不导出任何函数（GLOBAL DEFAULT FUNC: 0）" | 采集脚本 v1.1 的 J 段输出 | **假 0**：readelf 列序是 `FUNC GLOBAL DEFAULT`，脚本写成 `GLOBAL.*DEFAULT.*FUNC` 永不匹配。**导出符号其实没采到**（样本全是 `UND`），U4-23 因此仍是 PARTIAL | 同上 |
| 11 | "设备 boot 即 CI 产物"（表述含糊：只写"设备侧已闭合、比对未做"） | `STAGE4_FINAL_REPORT` §7、`PROJECT_STATE` §3.2、本表第三版 §6.1 | **答案写直：否**。`05/MANIFEST` §1 **早已登记**运行时内核为"第三方 GKI 构建（KernelSU 补丁）"，本轮补充 `/proc/version` 构建者 `chandr1000@SukiSU-Ultra-v41181`、`u:r:ksu:s0`、`/data/adb/ksu`、`tainted=0x1201` 四项 **[D·A]** 直读。**事实不是新的，表述是新的**；用户态 `/vendor`、`/vendor_dlkm` 仍原厂 erofs（U4-27），设备读数的有效性不受影响 | §2 N-8、`D-036` |
| 12 | "`ged.ko` 不反向依赖 kbase"（读作 `ged` 与 `kbase` 互不依赖） | 本表第三版 §5 的 U4-22 行 | 方向要拆开说：**`ged` 不 import 任何 `kbase` 符号（0 条）**；但 **`kbase` import 84 条 MTK 侧符号（含 49 条 `ged_*`）** → 依赖是**单向**的，`kbase` 是叶子消费者。`/proc/modules` 的 `deps` 列是**反向依赖（谁在用我）**，不能按"我依赖谁"读 | §2 N-9、`evidence/stage4_round3_20261116/symbols/` |

> 第 1、6 条**推翻的是本项目自己的推理**，不是外部事实。原文留痕于 `D-027` / `D-028` 的"后续修正"栏，本表不删除历史。
>
> **第 8～10 条是采集脚本的判读缺陷，不是设备问题**：数据都取到了，只是标签贴错。三项均已在脚本 **v1.2** 修正并本机验证（`note` 偏移、`FUNC` 正则、`stat -L`）。**不影响本表第 1～7 条的任何结论**。
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
| R-13 | `01_original_baseline/…/csf/mali_kbase_csf_firmware.c:108-110, 128, 177-180, 2765-2800` | 固件 header 常量（magic / 0.0.3 / len 0x14）、`entry_type`/`entry_size`、截断检查、entry 遍历 |
| R-14 | `02_r56_source/…/csf/mali_kbase_csf_firmware.c:86, 2698-2703` | **R56 要求 header 0.4，且 `!=` 严格相等** → 0.3 固件必被拒 |
| R-15 | `05_userspace_firmware/evidence/stage4_round2_20261116/`（`README.md` / `firmware_header.md` / `key_readings.md`） | 第二轮真机采集的判读与证据 |
| R-16 | `05_userspace_firmware/evidence/stage4_round3_20261116/`（`README.md` / `key_readings.md`） | 第三轮真机采集的判读：v1.2 修复验证、环境定性、deps 方向、双渲染路径 |
| R-17 | `05_userspace_firmware/evidence/stage4_round3_20261116/symbols/`（`ged_versions.tsv` 241 / `kbase_versions.tsv` 513 / `kbase_mtk_side.tsv` 84 / `README.md`） | `__versions` 全量符号表与解析方法（含字节序陷阱） |
| R-18 | `05_userspace_firmware/tools/collect_stage4_remainder.sh`（v1.2，`md5 aae2228…`，523 行） | 第三轮实际执行的采集脚本；头部注释含 v1.1→v1.2 四处判读修正 |

*本文件不含任何源码或配置改动。*
