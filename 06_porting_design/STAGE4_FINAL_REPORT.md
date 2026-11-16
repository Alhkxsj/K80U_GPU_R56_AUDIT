# Stage 4 最终报告（TASK-STAGE4-FINAL）

> ⚠️ **本文件是 `TASK-STAGE4-FINAL`（提交 `bbaeaf2`）的时点快照，不是最新台账。**
>
> **最新状态以 [`STAGE4_REMAINING_AUDIT.md`](STAGE4_REMAINING_AUDIT.md) 为准**（`TASK-STAGE4-REMAINDER`，2026-11-16）。两者差异如下，**本节不删除原文**：
>
> | 项 | 本文件（快照） | 最新（`STAGE4_REMAINING_AUDIT.md`） | 原因 |
> | --- | --- | --- | --- |
> | 五态计数 | 5 / 6 / 1 / 15 | **8 / 12 / 1 / 6**（`D-034`，两轮真机采集后；中间态 5/8/1/13 为 `D-033`） | 规则统一 + 采集回传：U4-20/26/27 闭合，U4-11/17/21/23 转 PARTIAL |
> | U4-04c 的未知面 | "15 处强制，任一处失败 → GPU 完全不可用" | **3 已证 / 4 结构上不用 / 8 待证**，剩余致命位 = `CS_QUEUE_REGISTER` 等 4 条 | R49 kbase **内联校验** padding **9 处**（`D-031`） |
> | GPU 属性 | "83/83 不变"、"568 → 592" | **83 共同 + 3 新增（86/87/88）**；序列化缓冲 **749 → 781 B** | `D-032` |
> | ioctl 总数 | "55 个" | **54（R49）→ 50（R56）** | 独立复现 |
> | DDK 路线 | DDK-B = R46，不可推荐 | **DDK-B = R56 Kbase + R49-derived compatibility DDK**（R46 退出） | `D-030` |
>
> | 固件阻断机制 | "kbase 只认 header 0.4" | **锁死：`!=` 严格相等，0.3 → header 校验阶段 `-EINVAL`，早于 entry 解析**；`entry_end_offset` 实测 = 1000 | `06/STAGE4_REMAINING_AUDIT.md` §3.3、`firmware_header.md` §5 |
> | Vulkan 薄壳 | "133,416 B 薄壳，分析成本低" | **是桩不是实现**：已定义函数只有 `mali_vk_vendor_stub`（**24 B**）→ 反汇编目标应改为 `libGLES_mali.so` | `D-034` |
>
> **结论面（验收 **B — 有条件可行，存在明确阻断项**）不变。**

> **本文件做什么**：把 `05_userspace_firmware/01`–`09` 与 `04_mtk_platform` 的全部结论收敛为**一份可验收的状态台账**——27 个 U4 项的最终状态、证据边界、风险分级、以及"哪些能静态解决、哪些必须商业资产或实机"。
>
> **本文件不做**：不改驱动源码、不改 Kconfig/Kbuild、不改 workflow、不编译、不刷机。全部改动为纯文档。
>
> **与相邻文档的分工**：DDK 版本选择见 [`DDK_DUAL_TRACK_ASSESSMENT.md`](DDK_DUAL_TRACK_ASSESSMENT.md)；进入下一阶段的门槛见 [`STAGE5_PREREQUISITES.md`](STAGE5_PREREQUISITES.md)；逐项推理过程仍在 `05/`。
>
> 证据等级沿用 `05/08` §0.1：**[D·A]/[D·B]/[D·C]** 设备实测三分 · **[B]** 可核验构建记录 · **[P]** 用户声明 · **[E1]** 源码/二进制直接证据 · **[E2]** 交叉推导 · **[E3]** 惯例推断 · **[U]** UNKNOWN

---

## 0. 一句话结论

> **Stage 4 可以收尾，但不能宣称"证据闭环"。** 27 项中 5 项 CLOSED、6 项 PARTIAL、1 项 BLOCKED（U4-12，商业资产不在手）、15 项 OPEN；P0 仍有 3 项。**本轮把 U4-04 从一个"未知量"拆成了三个可判定子项，其中结构体布局子项已闭合**（51 个共同结构体、实质差异仅 1 处且被 R56 的兼容变体覆盖），剩余唯一未知收窄为"R49 DDK 是否遵守它自己的 `must be zero` 契约"。验收结论 **B：有条件可行，存在明确阻断项**。

---

## 1. 状态快照

### 1.1 五态分布（27 项）

> ⚠️ **下表是本轮的时点值**；最新为 **8 / 12 / 1 / 6**（`D-034`，两轮真机采集后；U4-20/26/27 闭合、U4-11/17/21/23 转 PARTIAL，见 `STAGE4_REMAINING_AUDIT.md` §4）。两表**同时保留**，不覆盖。

| 状态 | 数量 | 明细 |
| --- | ---: | --- |
| ✅ **CLOSED** | **5** | U4-01 / U4-03 / U4-05 / U4-08 / U4-09 |
| ⚠️ **PARTIAL** | **6** | U4-04 / U4-06 / U4-07 / **U4-10** / U4-24 / U4-25 |
| ⛔ **BLOCKED** | **1** | **U4-12**（R56 固件属商业交付件，交付包内 0 条目） |
| ○ **OPEN** | **15** | U4-02 / U4-11 / U4-13 / U4-14 / U4-15 / U4-16 / U4-17 / U4-18 / U4-19 / U4-20 / U4-21 / U4-22 / U4-23 / U4-26 / U4-27 |
| ? **UNKNOWN** | **0** | 所有项都已能归入上述四态；无"连问题都定义不清"的项 |

> **本轮计数变化**：PARTIAL 5 → 6（U4-10 由 OPEN 转入，理由见 §4.3）；BLOCKED 0 → 1（U4-12 单列，此前混在 OPEN 里）。**总数与 P0 数量不变。**

### 1.2 优先级分布

| 优先级 | 数量 | 项 |
| --- | ---: | --- |
| **P0** | **3** | U4-04（PARTIAL）/ U4-10（PARTIAL）/ U4-12（BLOCKED） |
| P1 | 8 | U4-02 / U4-11 / U4-14 / U4-15 / U4-17 / U4-22 / U4-24 / U4-25 |
| P2 | 8 | U4-06 / U4-07 / U4-16 / U4-19 / U4-20 / U4-21 / U4-26 / U4-27 |
| P3 | 3 | U4-13 / U4-18 / U4-23 |
| （不计） | 5 | U4-01 / U4-03 / U4-05 / U4-08 / U4-09 —— 已闭合，不再分级 |

> 校验：3 + 8 + 8 + 3 + 5 = **27** ✓

### 1.3 P0 逐项状态

| ID | 内容 | 状态 | 已取得 | 缺什么 | 解除条件 |
| --- | --- | --- | --- | --- | --- |
| **U4-04** | R49 DDK 的 padding / props 行为 | **PARTIAL** | ①版本代次 `r49p1-03bet0` → UK 1.30 [D·A]；②**结构体布局差异已闭合**（§4.1）[E1]；③padding 强制校验 15 处、props 两阶段协商 [E1] | **R49 DDK 是否对 15 个结构体的 padding 清零** | 一条 `strace -f -e trace=ioctl` 抓 `eglInitialize`，或对 `libGLES_mali.so` 反编译 |
| **U4-10** | GPU 初始化失败是否 bootloop | **PARTIAL** | **静态路径已定：不会 bootloop**（§4.3）[E1]；R49 与 R56 的固件加载时机**同构** | 真实故障下的**系统可用性**（非启动阻断） | 需故障注入（要求可回滚环境，本轮禁止） |
| **U4-12** | R56p0 固件是否匹配 G925 MC12 | **BLOCKED** | 交付包 23 条目内 `firmware`/`.bin`/`ddk` 命中 0 [E1]；验收判据已预写 | **固件实体本身** | 取得 Arm 商业交付件（见 `STAGE5_PREREQUISITES.md` §3） |

---

## 2. 已具备的设备证据

| # | 证据 | 等级 | 用途 |
| ---: | --- | --- | --- |
| 1 | 设备标识：`25060RK16C` / `dali` / `CP2A.260605.016` / `OS4.0.3.0.XONCNXM` / SDK 37 | [D·A] | 全项目锚点 |
| 2 | 运行内核 `6.6.143-android15-8-gf9aa2fec23c3-4k`；`u:r:ksu:s0` | [D·B] | 第三方环境界定 |
| 3 | **18 个 GPU 相关 `.ko`** 的路径 / 字节数 / SHA256 / vermagic / srcversion / sysfs Build ID | [D·A] | U4-24a；模块台账 |
| 4 | 18 个模块 vermagic 全为 `6.6.118-android15-8-g54a15cf3acba-4k` | [D·A] | 推出原厂内核版本 |
| 5 | `/proc/modules` 597 项全量、taint 列（GPU 模块仅 `(O)`，无 `F`） | [D·A] | 排除强制装载 |
| 6 | 原厂固件前 16 字节 `6e 3a f1 c3 03 00 00 00 …` → header **0.3** | [D·A] | U4-01 闭合 |
| 7 | `libGLES_mali.so` 53,105,232 B、内含 `r49p1-03bet0`、API 35、NEEDED `libged`/`libgpud`/4 个 gralloc 私有库 | [D·A] | U4-04a |
| 8 | `vulkan.mali.so` 133,416 B 薄壳、仅导出 `mali_vk_vendor_stub` | [D·A] | U4-05 闭合 |
| 9 | HWC / mapper 的 NEEDED 面（不链 DDK、链 `libged`） | [D·A] | U4-08 闭合 |
| 10 | `__versions` / `.text` 节大小 18 个模块逐一 | [D·A] | U4-24a；重导范围收窄 |
| 11 | `lsmod` size 与文件大小对照（证伪"`ged` 差 409 KB"） | [D·A] | 口径更正 |
| 12 | `uname -v` = `Mon Oct 5 04:20:00 UTC 2026` | [D·B] | 证明它是补丁月常量 |

## 3. 仍缺失的设备证据

| # | 缺什么 | 挡住哪项 | 最小补采方案（只读） | 是否需授权 |
| ---: | --- | --- | --- | --- |
| 1 | DDK 的 ioctl 入参字节 | U4-04c、U4-14 | `strace -f -e trace=ioctl -o /data/local/tmp/gpu.log` 后跑一次 `eglInitialize` | 需 root（已有） |
| 2 | 设备 `ged.ko` 的 `__versions` 内容 | U4-24b | `readelf -x __versions /vendor_dlkm/lib/modules/ged.ko`（约 96 KB 文本） | 否 |
| 3 | 内核 `build-id` | U4-26 | `cat /sys/kernel/notes`（十六进制）或 `readelf -n /proc/…` 等文本手段 | 否 |
| 4 | mount 表 | U4-27 | `cat /proc/self/mountinfo \| grep -Ei "vendor\|overlay"` | 否 |
| 5 | 故障注入 | U4-10 剩余 | **不在只读范围内**，本轮禁止 | 需可回滚环境 |
| 6 | R56 固件 / DDK 实体 | U4-12 | **不可通过设备采集取得** | 商业授权 |

> 第 2–4 项都是**一条命令、纯文本、零风险**。第 1 项需要一次 `strace`（不改任何文件，但会临时占用 `/data/local/tmp`）。第 5、6 项不是"采集"能解决的。

---

## 4. 本轮五项实质推进

### 4.1 U4-04b 闭合：结构体布局差异 = 1 处实质 + 1 处重命名

**方法**：对两代 `include/uapi/gpu/arm/midgard/` 下的 `mali_kbase_ioctl.h` 与 `csf/mali_kbase_csf_ioctl.h` 做**全量结构体解析比对**（去注释后逐字段比较，非抽样）。

| 文件 | 共同结构体 | 字段有差异 | 仅 R49 有 | 仅 R56 有 |
| --- | ---: | ---: | --- | --- |
| `mali_kbase_ioctl.h` | 28 | **1** | 6 个（见下） | 0 |
| `csf/mali_kbase_csf_ioctl.h` | 23 | **1** | 0 | 2 |
| **合计** | **51** | **2** | 6 | 2 |

**两处差异的实际性质**：

| 结构体 | 差异 | 是否影响 ABI |
| --- | --- | :---: |
| `kbase_ioctl_mem_sync` | 首字段 `__u64 handle` → `__u64 gpu_va`，**纯重命名**，类型/偏移/大小完全相同 | **否** |
| `kbase_ioctl_cs_queue_group_create` | R49 长度 112 B；R56 现版长度 **120 B 且 ioctl 号 58→63** | **否**（见下） |

**为什么 CSG 的改动不影响 R49 DDK**——这是本轮最关键的一条机制证据：

```
R49 : _IOWR(KBASE_IOCTL_TYPE, 58, union ..._create)             → nr=58, size=112
R56 : _IOWR(KBASE_IOCTL_TYPE, 58, union ..._create_1_35)        → nr=58, size=112  ← 同一编码
      _IOWR(KBASE_IOCTL_TYPE, 58, union ..._create_1_18)        → nr=58, size=40
      _IOWR(KBASE_IOCTL_TYPE, 63, union ..._create)             → nr=63, size=120
```

`switch (cmd)` 按**完整请求号（含 size）**分派，所以 R49 DDK 发出的 `(58, 112)` 精确命中 R56 的 `_1_35` 分支。而 `_1_35` 的处理函数是**逐字段迁移**：

```c
/* mali_kbase_core_linux.c:1446-1472 */
union kbase_ioctl_cs_queue_group_create new_create = { .in = {
    .tiler_mask = create->in.tiler_mask, ... .csi_handlers = create->in.csi_handlers,
    .dvs_buf = create->in.dvs_buf,
    .neural_mask = create->in.neural_mask,          /* R49 的 padding[0..7]，须为 0 */
    .comp_pri_threshold = create->in.comp_pri_threshold,   /* R49 的 padding[8] */
    .comp_pri_ratio = create->in.comp_pri_ratio,           /* R49 的 padding[9] */
} };
/* neural_max / fragment_endpoint_task_limit / reserved 一律取 0 */
```

由此得到三条结论：

1. **R56 是"设计上"向下兼容的**：刻意保留 112 字节的 `_1_35`，不是巧合。
2. **R49 的 `reserved`（offset 30）不被读**——它在新结构里对应 `neural_max`，但迁移代码**不拷贝该字段**，强制为 0。故"`reserved` 垃圾值被误解释"这一风险**不存在**。
3. R49 的 `padding[9]`（offset 40–111，72 B）被切分为 `neural_mask(8) + comp_pri(2) + padding(62)`。只要 R49 DDK 按自身 UAPI 契约清零，R56 读到的就是 0。

> **U4-04b 判定：CLOSED [E1]**（双向逐字段比对）。"CSG 结构体变化"这一 Stage 2 差异项，在 **R49 DDK → R56 kbase** 方向上不构成不兼容。

### 4.2 U4-04c 仍开放，但风险从"单点致命"降为"中"

| 支撑"风险可控"的证据 | 等级 |
| --- | --- |
| R49 UAPI 明文写 `@in.padding: Currently unused, must be zero`，15 个结构体同此 | [E1] |
| R56 为全部旧版本保留逐字段迁移路径（不止 CSG，见下） | [E1] |
| `MEM_SYNC` 等 5 个 ioctl 由 **kbase 主动替用户态清零**（`mali_kbase_ioctl_helpers.h:152-167` 注释明示"on behalf of user space"） | [E1] |
| 55 个 ioctl 中 R49 与 R56 结构体字段差异仅 2 处（§4.1） | [E1] |

| 仍缺的证据 | 为什么不能推断 |
| --- | --- |
| R49 DDK **实际是否**清零 | UAPI 契约只规定"应该"，不证明"确实"。R49 kbase **没有** `mali_kbase_ioctl_helpers.h`（该机制 R50+ 才引入）→ 旧环境**不校验**，DDK 没有外部压力保证清零 |

> **表述边界**：可以说"结构上已被 R56 兼容设计覆盖"；**不能**说"R49 DDK 一定清零"。后者仍需一条 `strace`（`STAGE5_PREREQUISITES.md` §2 第 1 项）。

### 4.3 U4-10 定性：**不会 bootloop**，但会丢可用性

**源码路径**（R56，[E1]）：

```c
/* mali_kbase_core_linux.c:790-802 —— 注意注释 */
/* Device-wide firmware load is moved here from probing to comply with
 * Android GKI vendor guideline. */
static int kbase_open(...)
{
    ret = kbase_device_firmware_init_once(kbdev);   /* ← 固件在这里加载 */
    if (ret) goto out;                              /* ← 只让 open 失败 */
    ...
}
```

| 判定 | 结论 | 依据 |
| --- | --- | --- |
| probe 阶段是否加载固件 | **否** | 注释明示为符合 GKI vendor guideline 而下移到 open |
| 固件失败是否导致 probe 失败 | **否** | probe 不涉及固件 |
| 固件失败是否导致内核 panic | **否** | `kbase_csf_firmware_load_init` 全部走 `goto err_out` + `-EINVAL` |
| 是否 bootloop | **否** | 无重启路径；`/dev/mali0` 仍在 |
| 失败后能否重试 | **能** | `if (!kbdev->csf.firmware_inited)` 未置位 → 下次 open 重新尝试 |
| R49 与 R56 行为是否同构 | **是** | R49 `device/backend/mali_kbase_device_csf.c:463-474` 同样的 deferred 注释与结构 |

**真正的后果不是"起不来"，而是"起来了但没有 GPU"**：

| 层 | 后果 |
| --- | --- |
| 内核 | 正常启动，`/dev/mali0` 存在，`open()` 返回 `-EINVAL`/`-ENOENT` |
| DDK | `eglInitialize` 失败 → `EGL_NOT_INITIALIZED` |
| MTK 平台层 | **不受阻**：`ged.ko` 的 240 个 `UND` 中匹配 `kbase` 命中 **0**（`04/03` §69）→ GED 不等待 kbase |
| SurfaceFlinger / HWC | HWC 不链 DDK（[D·A]），可继续工作；但 GPU 合成不可用 → 退化为 client 合成 |
| 应用 | 无法创建 GL 上下文；`ro.vendor.mtk.gpu.sw3d=0`（无 CPU 3D 回退）→ 图形应用不可用 |

> **U4-10 状态：OPEN → PARTIAL。** "启动阻断"这一 P0 关切已被源码排除；剩下的是"可用性丧失的严重程度与是否可自愈"，那需要故障注入。

### 4.4 U4-14 精确化：R56 实际删除了 6 个 ioctl，其中 1 个是 MTK 私有

用请求号 + 结构体双重比对，R56 相对 R49 **删除**了下列 6 个：

| ioctl | 号 | 性质 | 对 MTK 移植的意义 |
| --- | ---: | --- | --- |
| `kbase_ioctl_hwcnt_reader_setup` / `_hwcnt_values` | 8 | 旧 HWCNT 读取接口，R49 版本注释已标 "Remove"（1.19） | 无语义损失（新 `KINSTR_PRFCNT` 取代） |
| `kbase_ioctl_disjoint_query` | — | 已废弃 | 无 |
| `kbase_ioctl_set_limited_core_count` | 55 | R56 版本注释标 **"Remove legacy IOCTLs … at 1.34"** | **需确认 DDK 是否调用**；若调用 → 返回 `-ENOTTY`，通常是降级而非崩溃 |
| `kbase_ioctl_internal_fence_wait` | **80** | **MTK 私有扩展**（`#ifdef CONFIG_MALI_MTK_FENCE_DEBUG`），R49 有实现（`mali_kbase_core_linux.c:2264`），R56 **完全没有** | **真实能力丢失**，详见下 |
| `kbase_ioctl_cinstr_gwt_dump` | — | 调试用（`CONFIG_MALI_CINSTR_GWT`） | 无生产影响 |

**ioctl 80 的实际用途**（读 R49 实现，`mali_kbase_core_linux.c:1830-1880`）：

```c
/* 仅在 internal fence 等待超时时被 DDK 调用，用于： */
if (t == 2000 || t == 3000) { logbuffer/printk 打印超时; }
if (flags & BASE_INTERNAL_FENCE_WAIT_DUMP_FLAG) { mtk_common_debug(...) 系列转储; }
#if IS_ENABLED(CONFIG_MALI_MTK_FENCE_TIMEOUT_RESET)
if (t == 3000) { kbase_prepare_to_reset_gpu(...); }   /* ← 超时自动 reset GPU */
#endif
```

| 判定 | 内容 |
| --- | --- |
| 是否渲染主路径 | **否**，只在超时/异常时调用 |
| 丢失后果 | ①失去 MTK 的 internal-fence 超时日志与自动转储；②失去 `FENCE_TIMEOUT_RESET` 的**超时自愈**能力 |
| 是否影响 U4-10 | **是**——这是"GPU reset 后能否恢复"链条上的一环：R56 自身有完整 reset 机制（19+ 处 `kbase_prepare_to_reset_gpu` 调用），但**"由 internal fence 超时触发"这一 MTK 特有入口会消失** |
| 处置 | Stage 5A 的 MTK 适配矩阵必须显式登记；**不得**用空实现假装保留（`AGENTS.md` 禁止项） |

> **U4-14 仍 OPEN**，但问题已从"哪 5 个 ioctl 没了"变为"**已知这 6 个，待确认 R49 DDK 是否调用其中 2 个生产项（55 / 80）**"。这一项可以由同一条 `strace` 一并回答。

### 4.5 U4-25b 的判定边界再确认

| 层 | 机制 | 能否从运行态观测 |
| --- | --- | --- |
| vermagic（release 串） | `CONFIG_MODVERSIONS` 下 `same_magic()` **忽略**第一个空格前的内容 | **不需要**——本来就不比较（U4-25a 已闭合） |
| 符号 CRC | `check_version()` 逐符号比对 `__versions` | **能**，但只在**不匹配时**才有输出 |
| `bad_version → return 1` 补丁 | 把不匹配从"失败"改为"放行" | **不能**——CRC 匹配时补丁与原生**行为完全一致**，无日志、无 taint |

**推论**：只要 18 个模块**没有** CRC 不匹配（即装载无 `disagrees about version of symbol`），那么"补丁是否打过"**对本项目结论没有任何影响**——两种情况的结果都是"CRC 一致"。

> 这条把 U4-25b 从"必须回答"降级为"**只在出现 CRC 不匹配时才有意义**"。副作用：`STAGE5_PREREQUISITES.md` 中对验证内核的要求可以放宽为"**装载后 `dmesg` 无 `disagrees about version of symbol`**"，而不必查构建输入。

---

## 5. 全量 27 项状态表

| ID | 内容 | 优先级 | 状态 | 证据边界（能证明什么 / 不能证明什么） |
| --- | --- | :---: | :---: | --- |
| ~~U4-01~~ | 原厂固件 header 实际值 | ~~P0~~ | ✅ CLOSED | 能：`0.3`（字节实测）。不能：GLB 运行时版本（→ U4-02/11） |
| U4-02 | 原厂固件运行时 GLB 版本 | P1 | ○ OPEN | 需 dmesg 中固件启动打印 |
| ~~U4-03~~ | DTB `firmware-name` 覆盖 | — | ✅ CLOSED | DT 双向确认无此属性 |
| **U4-04** | DDK 的 padding / props 行为 | **P0** | ⚠️ PARTIAL | **a 版本代次 ✅**、**b 结构体布局 ✅（本轮）**、**c DDK 实现 ❌** |
| ~~U4-05~~ | 是否存在 Vulkan | — | ✅ CLOSED | 薄壳存在，133,416 B |
| U4-06 | EGL 加载机制 | P2 | ⚠️ PARTIAL | 可用性已证；具体 `eglGetDisplay` 分支未追 |
| U4-07 | 分配走 dma-buf heap 还是 ion | P2 | ⚠️ PARTIAL | 两库都在；实际路径未定 |
| ~~U4-08~~ | HWC 是否依赖 DDK | — | ✅ CLOSED | 不依赖（NEEDED 面） |
| ~~U4-09~~ | VINTF / init | — | ✅ CLOSED | — |
| **U4-10** | GPU 失败后是否 bootloop | **P0** | ⚠️ **PARTIAL（本轮）** | 能：**不阻断启动**、固件失败可重试、reset 机制完整 [E1]。不能：真实故障下可用性 |
| U4-11 | 原厂固件 GLB 尾部版本 | P1 | ○ OPEN | 需读 offset 0x10 之后 |
| **U4-12** | R56p0 固件是否匹配 G925 MC12 | **P0** | ⛔ **BLOCKED** | 能：交付包内 0 固件。不能：任何匹配性结论（无实体） |
| U4-13 | NX 相关 GLB 字段 | P3 | ○ OPEN | 需固件实体 |
| **U4-14** | DDK 是否用被删的 ioctl | P1 | ○ OPEN（**已精确化**） | 能：R56 删除 6 个，含 MTK 私有 80 [E1]。不能：DDK 是否调用 55 / 80 |
| U4-15 | DDK 对 props 新 ID 的处理 | P1 | ○ OPEN | 需 DDK 二进制；机制侧已明（两阶段协商） |
| U4-16 | DDK 是否依赖 HWCNT 做 DVFS | P2 | ○ OPEN | 需 trace |
| U4-17 | 薄壳 `api_version` / 加载机制 | P1 | ○ OPEN | 需 `vulkan.mali.so` 反汇编 |
| U4-18 | Vulkan 与 GLES 是否同批构建 | P3 | ○ OPEN | 两 Build ID 已取，判据不足 |
| U4-19 | Vulkan 是否用 GLES 不用的 ioctl | P2 | ○ OPEN | 需 trace |
| U4-20 | SF RenderEngine 后端选择 | P2 | ○ OPEN | 需 dumpsys |
| U4-21 | 是否有服务硬依赖 `/dev/mali0` | P2 | ○ OPEN | 需 `dumpsys` / init 分析 |
| U4-22 | `libged` 事件面失效的降级程度 | P1 | ○ OPEN | 需真实失效场景 |
| U4-23 | `libgpud` 与 `libgpud_sys` 同名符号 | P3 | ○ OPEN | 需符号表比对（可静态做） |
| **U4-24** | 设备 `.ko` 身份 / CRC | P1 | ⚠️ PARTIAL | **a ✅ 18 个全取**；**b ❌ 需 `readelf -x __versions`** |
| **U4-25** | 第三方内核差异面 | P1 | ⚠️ PARTIAL | **25a ✅（撤回原结论）**；**25b 本应无影响（§4.5）**；25c 未测 |
| U4-26 | 设备 boot 是否即 CI 产物 | P2 | ○ OPEN | `uname -v` 零信息量；缺 `build-id` |
| U4-27 | `/vendor` 是否被 overlay | P2 | ○ OPEN | 缺 mount 表 |

---

## 6. 风险登记（P0 / P1）

| ID | 风险 | 等级 | 触发条件 | 后果 | 缓解 | 当前状态 |
| --- | --- | :---: | --- | --- | --- | --- |
| **R-A1** | R49 DDK 未清零 padding | **P0** | DDK 手写赋值而非 `{0}` 初始化 | `CS_QUEUE_REGISTER` / `CSG_CREATE` → `-EINVAL` → **GPU 完全不可用** | 一条 `strace` 定性；若为真则组合 C 判死 | **未验证**（结构侧已兼容，见 §4.1） |
| **R-A2** | R56 固件不存在 / 不配 G925 MC12 | **P0** | 商业件不可得或 SKU 不符 | 整条路线无固件可加载 → `-EINVAL` | 取得交付件后按 4 项判据验收 | **BLOCKED** |
| **R-A3** | 真实故障下可用性丧失面 | **P0** | GPU 初始化失败 | 显示降级、应用不可渲染（**非** bootloop） | 设计 fail-safe 与 sw3d 回退评估 | **PARTIAL**（启动面已排除） |
| R-B1 | 设备 `.ko` CRC 与仓库基线不同 | P1 | kbase 已确认不同（+17,640 B） | Stage 3 的 REA 数值基线需重导 | 已收窄至 kbase；抽样验证其余 14 个 | **PARTIAL** |
| R-B2 | `mtk_ghpm` 等 3 个模块仓库缺失 | P1 | 设备 18 / 仓库 15 | 移植后可能缺平台模块 | Stage 5A 的组件清单必须补 | OPEN |
| R-B3 | ioctl 55 / 80 被 DDK 使用 | P1 | DDK 调用了 R56 已删的接口 | 55：降级；80：失去超时自愈 | `strace` 确认；必要时在 MTK 适配层补 | OPEN |
| R-B4 | 平台层双写 core mask | P1 | GED 每 100 ms 改写 + kbase 自身调频 | 频率/核数抖动 | `04/03` §157 已识别 | OPEN（设计阶段处理） |

---

## 7. 证据引用索引

| 引用 | 位置 | 内容 |
| --- | --- | --- |
| E-1 | `05/09` §2 | `same_magic()` 在 `CONFIG_MODVERSIONS` 下忽略 release 串 |
| E-2 | `05/09` §3 | `bypass-kernel` 开关与门控 bug 时间窗 |
| E-3 | `05/09` §5 | padding 48 钩子分类：28 空 / 5 清零 / 15 强制 |
| E-4 | `05/09` §6 | R56 交付包 23 条目、0 固件 |
| E-5 | **本文件 §4.1** | 51 个共同结构体、2 处差异、`_1_35` 兼容机制 |
| E-6 | **本文件 §4.3** | `kbase_open` 延迟固件加载；R49/R56 同构 |
| E-7 | **本文件 §4.4** | R56 删除 6 个 ioctl，含 MTK 私有 80 |
| E-8 | `02_r56_source/.../csf/mali_kbase_csf_firmware.c:85-87, 2698` | `MAJOR 0 / MINOR 4`、`!=` 严格 |
| E-9 | `02_r56_source/.../mali_kbase_core_linux.c:137-196` | caps 表与 `api_version >= required` 语义 |
| E-10 | `02_r56_source/.../mali_kbase_core_linux.c:357-385` | 握手 `min()` 夹取，无下限检查 |
| E-11 | `04/03` §69 | `ged.ko` 对 kbase 0 反向依赖 |
| E-12 | `04/06` §1 | 平台保留矩阵（保留 10 / 适配 2） |

---

## 8. 最终闭环结论

### 8.1 三条判定

| 判定对象 | 结论 |
| --- | --- |
| Stage 4 报告是否交付 | ✅ 已交付（`05/01`–`09` + 本文件 + 两份配套） |
| Stage 4 证据是否闭环 | ❌ **未闭环**：P0 三项分别为 PARTIAL / PARTIAL / BLOCKED |
| 是否允许宣布"Stage 4 通过" | ❌ **不允许**。按 `AGENTS.md` §1.3，存在未闭合 P0 时不得声明阶段结论成立 |

### 8.2 验收结论：**B — 有条件可行，存在明确阻断项**

| 维度 | 判定 | 理由 |
| --- | --- | --- |
| 组合 A/B 裁定 | **不变**（B 已被实测否决） | 固件 0.3 vs 要求 0.4，`!=` 严格 |
| 最小替换范围 = kbase + 固件 | **不变** | 平台层保留 10 / 适配 2；用户态契约层可整套保留 |
| 用户态契约层可保留 | **不变，且本轮加强** | 51/51 结构体布局兼容，实质差异 0（§4.1） |
| 是否可进入 Stage 5A（设计） | **可以**（需用户明确授权） | 设计所需证据已足；本轮清除的四处机制错误不会带进设计 |
| 是否可进入 Stage 5B（实施） | **不可以** | U4-04c 未定性、U4-12 BLOCKED、U4-24b 未闭、无回滚环境声明 |

### 8.3 推翻本结论需要什么

| 若出现 | 则 |
| --- | --- |
| R49 DDK 实测清零全部 padding | R-A1 关闭 → 组合 C 的致命项消失，P0 由 3 降为 2（仍受固件阻断） |
| R56 固件交付件到手且 SKU 匹配 | U4-12 解除 → 组合 D 可评估 |
| 发现 R56 存在"读旧版固件"的 fallback | 组合 B 复活，需重跑全部固件判据 |
| 发现设备 vendor 被 overlay 改写 | 全部 [D·A] 证据需重估（U4-27 的后果） |

---

*本文件不含任何源码或配置改动；`git diff` 仅涉及 `.md`。*
