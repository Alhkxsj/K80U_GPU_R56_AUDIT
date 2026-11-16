# R49-derived compatibility DDK 改造预研框架

> **本文件做什么**：为"**R56 Kbase + R49-derived compatibility DDK**"这条备用路线建立**预研框架**——把"要改什么、改得动吗、改不动的是什么"逐项拆开，每项标注证据等级。
>
> **本文件不做**：**不修改任何源码**（R49 与 R56 都不改）、不编译、不生成可刷入产物、不替换设备上的 `.so` / `.ko` / 固件。本文是**设计文档**，不是实施记录。
>
> **命名纪律**：本路线的产物**不得**称为"原生完整 R56 DDK"。若最终无法实现全部 R56 特性，必须标注为"**兼容移植方案**"（compatibility port）。任何情况下不得通过修改版本字符串、伪造 ABI 版本、绕过校验来宣称兼容（`AGENTS.md` §0.6 禁止项 ⑬–⑮）。
>
> **标注约定**：
>
> | 标签 | 含义 |
> | --- | --- |
> | **CONFIRMED** | 有直接证据（源码行号 / 字节实测 / 设备实测） |
> | **LIKELY** | 证据支持，但尚未验证（可被一次实测推翻） |
> | **UNKNOWN** | 缺少证据，且已知缺口位置 |
> | **BLOCKED** | 缺少必要资产，无法推进 |
>
> 相关文档：[`DDK_DUAL_TRACK_ASSESSMENT.md`](DDK_DUAL_TRACK_ASSESSMENT.md)（路线取舍）、[`STAGE4_REMAINING_AUDIT.md`](STAGE4_REMAINING_AUDIT.md)（证据台账）、[`STAGE5_PREREQUISITES.md`](STAGE5_PREREQUISITES.md)（准入）。

---

## 0. 一页概览

| 维度 | 结论 | 标签 |
| --- | --- | --- |
| R49 DDK **编译产物** | 设备上**有**（`libGLES_mali.so` 53,105,232 B / `r49p1-03bet0`） | **CONFIRMED** |
| R49 DDK **源码** | 设备上**没有**；仓库也没有 → 必须外部取得 | **BLOCKED** |
| R49 kbase 对 G925 MC12 的硬件支持 | **完整**（`tKRx` features 与 R56 完全相同） | **CONFIRMED** |
| UAPI 结构体差异 | 51 个共同结构体，实质差异 **0** | **CONFIRMED** |
| UK 1.30 → 1.39 能力差 | 7 项新 cap 全部拿不到；原样运行 = 1.30 语义 | **CONFIRMED**（机制）/ **UNKNOWN**（改造后能达到什么） |
| CSF 固件 | **不能由 DDK 改造解决**，必须单独取得 header 0.4 / G925 MC12 | **BLOCKED** |
| 改造可行性（整体） | **方案存在，但"能否保留全部 R56 特性"未验证** | **UNKNOWN** |

> **一句话**：这条路线**不是**"换个 DDK 版本试试"，而是"以出厂代码为基线自维护一条兼容分支"。它的成败几乎完全取决于**能否拿到 R49 DDK 源码**这一件事。

---

## 1. R49 原厂 DDK 资产清单

### 1.1 设备上实际存在什么

| 对象 | 路径 | 字节 | 身份 | 标签 |
| --- | --- | ---: | --- | --- |
| GLES/EGL 驱动（**DDK 主体**） | `/vendor/lib64/egl/mt6991/libGLES_mali.so` | **53,105,232** | Build ID `700e6d4112a6a8a5`；note API 35；内含 `r49p1-03bet0` | **CONFIRMED** [D·A] |
| Vulkan 厂商模块（**薄壳**） | `/vendor/lib64/hw/mt6991/vulkan.mali.so` | 133,416 | 仅导出 `mali_vk_vendor_stub`；NEEDED `libGLES_mali.so` | **CONFIRMED** [D·A] |
| Mali 平台 HAL | `/vendor/lib64/mt6991/arm.mali.platform-V2-ndk.so` | 85,344 | AIDL `arm.mali.platform` | **CONFIRMED** [D·A] |
| EGL 属性注入 | `/vendor/lib64/mt6991/libarm_egl_properties_sysprop.so` | 35,704 | `ro.vendor.arm.egl.configs.*` | **CONFIRMED** [D·A] |
| gralloc 属性注入 | `/vendor/lib64/mt6991/libarm_gralloc_properties_sysprop.so` | 35,672 | `ro.vendor.arm.gralloc.*` | **CONFIRMED** [D·A] |
| Mali 配置属性 | `/vendor/lib64/mt6991/libarm_mali_config_sysprops.so` | 52,056 | — | **CONFIRMED** [D·A] |
| MTK GPU 数据面 | `/vendor/lib64/libgpud.so` | 395,856 | 80+ 个 `gpudVk*` / `gpudMisc*` 符号 | **CONFIRMED** [D·A] |
| MTK GED 用户态 | `/vendor/lib64/libged.so` | 未单列 | `libGLES_mali.so` / mapper / HWC 均 NEEDED 它 | **CONFIRMED** [D·A] |
| 4 个 gralloc 私有库 | `libgralloc_extra` / `libgralloc_metadata` / `libgralloctypes_mtk` + allocator AIDL | — | `libGLES_mali.so` 硬依赖 | **CONFIRMED** [D·A] |

### 1.2 设备上**没有**什么（这是本路线的核心约束）

| 对象 | 状态 | 标签 |
| --- | --- | --- |
| R49 **DDK 源码**（`libGLES_mali.so` 的 C/C++ 源码） | **不存在于设备，也不在仓库**。仓库 `01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/` 只有 **kbase 内核驱动源码**（`drivers/gpu/arm/midgard/`） | **BLOCKED** |
| DDK 的符号表 | 设备采集时 `.dynsym` 被关键字筛选，**未取全** | **UNKNOWN** |
| DDK 的 `.text` | 未取（53 MB，`D-004` 禁止入库） | **UNKNOWN** |
| R49 DDK 的构建脚本 / 编译选项 | 无 | **BLOCKED** |

> **必须纠正的一句话**：任务书里"以手机提取的原厂 R49 DDK **源码**和二进制作为基线"——**"源码"这一半不成立**。手机只能提供二进制。源码必须来自 Arm / MTK 授权交付（见 §1.3）。

### 1.3 源码可能的合法来源（未验证，仅供规划）

| 来源 | 可能性 | 标签 |
| --- | --- | --- |
| SoC 厂商（MTK）BSP / 授权包附带当期内核+DDK 源码 | 中——整机厂需要基于它集成，通常随 BSP 提供 | **LIKELY**（[E3] 惯例，未验证） |
| Arm 直接授权（与 R56 DDK 同一渠道，只是版本更旧） | 中——同一授权体系，旧版本反而更容易获批 | **LIKELY**（[E3]） |
| 公开渠道（GitHub / 论坛） | **禁止使用**（来源不明二进制/源码，违反 `D-004` 精神） | — |

> 这条"可能性"判断是本路线**唯一**相对于 DDK-A 的优势所在：**不是"R49 更兼容"，而是"R49 更可能拿得到源码"**。

---

## 2. R49 与 R56 Kbase 的 UAPI 差异

**总判定：CONFIRMED —— 51 个共同结构体、实质差异 0。**

| 文件 | 共同结构体 | 字段有差异 | 仅 R49 有 | 仅 R56 有 |
| --- | ---: | ---: | ---: | ---: |
| `mali_kbase_ioctl.h` | 28 | 1 | 6 | 0 |
| `csf/mali_kbase_csf_ioctl.h` | 23 | 1 | 0 | 2 |
| **合计** | **51** | **2** | **6** | **2** |

| 差异 | 性质 | 对改造的影响 | 标签 |
| --- | --- | --- | --- |
| `kbase_ioctl_mem_sync`：`__u64 handle` → `__u64 gpu_va` | **纯重命名**，偏移/大小不变 | 无 | **CONFIRMED** |
| `kbase_ioctl_cs_queue_group_create`：112 B → 120 B、nr 58 → 63 | R56 **保留** `_1_35`（nr 58 / 112 B）并逐字段迁移 | 原样运行**不受影响**；若要改用 120 B 新版需改造 | **CONFIRMED** |

**ioctl 集合差异**（独立复现，`STAGE4_REMAINING_AUDIT` §2 N-3）：R49 **54** → R56 **50**（删 6、增 2）。

| 变更 | 项 | 对 R49 DDK 的影响 | 标签 |
| --- | --- | --- | --- |
| 删 | `HWCNT_READER_SETUP`(8) / `DISJOINT_QUERY`(12) / `HWCNT_SET`(32) / `CINSTR_GWT_DUMP`(35) | 若被调用 → `-ENOTTY`；均为旧/调试面 | **LIKELY** 无生产影响 |
| 删 | `SET_LIMITED_CORE_COUNT`(**55**) | 在 **CSF** 硬件上本来就是 no-op（`limited_core_mask` 只被 JM 后端读） | **CONFIRMED**（no-op）/ **UNKNOWN**（DDK 是否调用、是否把 `-ENOTTY` 当致命） |
| 删 | `INTERNAL_FENCE_WAIT`(**80**) | MTK 私有；R49 kbase 在 OEM 构建里**已启用**（strings 证据）→ 存在"DDK 真的会调"的可能 | **LIKELY**（存在性 CONFIRMED）/ **UNKNOWN**（调用面） |
| 增 | `CS_QUEUE_GROUP_CREATE_1_35`(58/112) | R49 原编码改名保留，**语义一致** | **CONFIRMED** |
| 增 | `CS_TILER_HEAP_SIZE`(62) | 新查询接口；R49 DDK 不会调用 | **CONFIRMED**（不会调用）/ 改造可选用 |

---

## 3. UK ABI 1.30 与 1.39 的能力差异

### 3.1 机制

`kbase_caps_table[]`（`02_r56_source/.../mali_kbase_core_linux.c:145-163`）逐项给出 `required_major/minor`，判定为 `api_version >= required`。**DDK 声称 1.30，就只拿到 ≤1.30 的能力。**

### 3.2 逐项能力表（以 `api_version = 1.30` 为输入）

| cap | required | 1.30 下是否可用 | 标签 |
| --- | ---: | :---: | --- |
| `SYSTEM_MONITOR` | 1.0 | ✅ | **CONFIRMED** |
| `JIT_PRESSURE_LIMIT` | 1.0 | ✅ | **CONFIRMED** |
| `QUERY_MEM_DONT_NEED` | 1.22 | ✅ | **CONFIRMED** |
| `QUERY_MEM_GROW_ON_GPF` | 1.0 | ✅ | **CONFIRMED** |
| `QUERY_MEM_PROTECTED` | 1.0 | ✅ | **CONFIRMED** |
| `QUERY_MEM_IMPORT_SYNC_ON_MAP_UNMAP` | 1.26 | ✅ | **CONFIRMED** |
| `QUERY_MEM_KERNEL_SYNC` | 1.26 | ✅ | **CONFIRMED** |
| `QUERY_MEM_SAME_VA` | 1.28 | ✅ | **CONFIRMED** |
| `REJECT_ALLOC_MEM_DONT_NEED` | 1.31 | ❌ **不可用** | **CONFIRMED** |
| `REJECT_ALLOC_MEM_PROTECTED_IN_UNPROTECTED_ALLOCS` | 1.31 | ❌ | **CONFIRMED** |
| `REJECT_ALLOC_MEM_UNUSED_BIT_20` | 1.31 | ❌ | **CONFIRMED** |
| `REJECT_ALLOC_MEM_UNUSED_BIT_27` | 1.31 | ❌ | **CONFIRMED** |
| `REJECT_ALLOC_MEM_UNUSED_BIT_5` | 1.32 | ❌ | **CONFIRMED** |
| `REJECT_ALLOC_MEM_UNUSED_BIT_7` | 1.32 | ❌ | **CONFIRMED** |
| `CSG_CS_USER_PAGE_ALLOCATION` | 1.35 | ❌（走"CSG 自己分配 user page"旧路径） | **CONFIRMED** |

> 另有 3 个 cap 在 R56 中即 `U16_MAX`（`REJECT_ALLOC_MEM_UNUSED_BIT_8/19/29`），**任何版本都不可用**，与本路线无关。**CONFIRMED**

### 3.3 改造的含义（本路线最需要小心的地方）

| 做法 | 结果 | 标签 |
| --- | --- | --- |
| 只改 DDK 声称的 minor（1.30 → 1.39） | kbase 会按 1.39 给能力，但 DDK 里没有对应实现 → 可能调用不存在的路径、可能传错结构体 → **属于"伪造 ABI"，本项目禁止** | — |
| 改 minor **并**实现 1.31–1.39 的语义 | 这才是"保留 R56 特性" | **UNKNOWN**（工作量与可行性都未评估，需源码） |
| 保持 1.30 不动 | 行为与"组合 C"完全相同，**R56 新特性全失** | **CONFIRMED** |

---

## 4. CSF 队列与 CSG 兼容

| 检查项 | 结论 | 标签 |
| --- | --- | --- |
| CSG create 的 size 落点 | R49 发 nr 58 / 112 B → 命中 R56 `_1_35` | **CONFIRMED** |
| `_1_35` 的迁移是否完整 | 逐字段拷贝；`neural_max` / `fragment_endpoint_task_limit` / `reserved` 强制置 0 | **CONFIRMED**（`mali_kbase_core_linux.c:1446-1472`） |
| CSG create 的 padding 是否被 R56 拒绝 | R56 检查 `in.padding[62]`（offset 50–111）；R49 kbase 检查 `padding[9]`（offset 40–111，**超集**）→ 设备可用 ⇒ offset 40–111 全 0 ⇒ R56 检查必过 | **CONFIRMED**（[E1]+[D·B] 推理） |
| `CS_QUEUE_REGISTER` 的 padding | R49 kbase **不校验**；R56 强制 → **未知** | **UNKNOWN**（渲染主路径上的剩余致命位） |
| `CS_QUEUE_REGISTER_EX` / `CS_TILER_HEAP_INIT(_1_13)` / `MEM_ALLOC_EX` 的 padding | 同上（R49 不校验） | **UNKNOWN** |
| KCPU 命令 padding | R49 **校验**（`csf/mali_kbase_csf_kcpu.c:3059`）→ DDK 必须清零 | **CONFIRMED** |
| CSG 生命周期（create / terminate / 队列注册顺序） | 协议未变；`CS_QUEUE_GROUP_TERMINATE` 仍在 R56 | **LIKELY** |
| 队列优先级 / `cs_min` / `cs_max` 语义 | 结构体字段未变 | **CONFIRMED**（结构层面）/ **LIKELY**（行为层面） |
| 1.35 的 `CSG_CS_USER_PAGE_ALLOCATION` 旧路径 | 1.30 DDK 走"CSG 自己分配 user page"，kbase 侧保留该分支 | **CONFIRMED**（机制）/ **UNKNOWN**（实测） |

---

## 5. GPU properties 兼容

| 项 | R49 | R56 | 标签 |
| --- | ---: | ---: | --- |
| `KBASE_GPUPROP_*` ID 数 | 83 | **86** | **CONFIRMED** |
| 新增 ID | — | `RAW_BASE_PRESENT`(86, u64)、`RAW_NEURAL_PRESENT`(87, u64)、`NUM_ACTIVE_GRANULARITY`(88, u32) | **CONFIRMED** |
| 删除 ID | — | **0** | **CONFIRMED** |
| 序列化缓冲区 `prop_buffer_size` | **749 B** | **781 B**（+32） | **CONFIRMED**（由 `gpu_property_mapping[]` + uapi 字段类型逐条求和） |
| 线上格式 | TLV：`u32 id` + `u8 type_size` + 值，无头部无计数 | 同 | **CONFIRMED**（`mali_kbase_gpuprops.c:809-880`） |
| 唯一硬门槛 | `get_props->flags != 0` → `-EINVAL`；`size == 0` → 返回所需长度；`size < prop_buffer_size` → `-EINVAL` | 同 | **CONFIRMED**（`mali_kbase_core_linux.c:870-891`） |
| R49 DDK 是否做 `size=0` 两步探测 | — | — | **UNKNOWN** |

**改造结论**：

1. 若 R49 DDK **做** `size=0` 探测 → **零改造**，781 B 缓冲区照拿，未知 ID 跳过。**LIKELY**（这是 Arm DDK 的常见写法，但未验证）
2. 若 R49 DDK **写死 749**（或写死 `sizeof(gpu_props_user_data)` 的 568） → 必须改造为两步协商，否则 `-EINVAL`，GPU 直接不可用。**UNKNOWN**
3. **不得**用"缓冲区变大 32 B 无所谓"来淡化——`size < prop_buffer_size` 是**严格比较**。

> 判据成本：`strace -f -e trace=ioctl` 看 `GET_GPUPROPS` 是否**连续两次**出现（第一次应返回长度）。见 `STAGE4_DEVICE_COLLECTION_PLAN.md` §6。

---

## 6. 内存分配、JIT、dma-buf、MGM、PMA

| 子系统 | R49↔R56 接口差异 | 改造需求 | 标签 |
| --- | --- | --- | --- |
| `MEM_ALLOC` / `MEM_IMPORT` / `MEM_FREE` / `MEM_COMMIT` | 结构体一致（51 个共同结构体之列） | 无接口改造 | **CONFIRMED** |
| `MEM_ALLOC_EX`（`in.extra[]`） | 结构体一致；R56 **强制** `extra[]` 全 0，R49 不查 | 需确认 DDK 是否清零 | **UNKNOWN** |
| `MEM_JIT_INIT` | 结构体一致；R49 **校验** padding、R56 也校验 | **零改造**（已证清零） | **CONFIRMED** |
| `MEM_SYNC` | 仅字段重命名；R56 由 kbase **替 DDK 清零** padding | 零改造 | **CONFIRMED** |
| `MEM_PROFILE_ADD` | 结构体一致；R56 强制 padding=0，R49 不查 | 调试面，非致命 | **UNKNOWN** |
| dma-buf / `dma_heap` / `ion` | 走 Linux 用户态接口，不经 kbase ABI | 无 | **CONFIRMED**（结构层） |
| MGM（Memory Group Manager） | MTK 侧内核模块 `mali_mgm_mt6991_r49.ko`，与 kbase 通过导出符号交互；**DDK 不直接调用** | 无 | **CONFIRMED**（依赖方向见 `04/01`） |
| PMA（Protected Memory Allocator） | `mali_prot_alloc_mt6991_r49.ko`，同上 | 无 | **CONFIRMED** |
| tiler heap | `CS_TILER_HEAP_INIT(_1_13)` + R56 新增 `CS_TILER_HEAP_SIZE`(62) | padding 待证；新增查询可选 | **UNKNOWN** / 可选改造 |

---

## 7. MTK GED / GPUD / GPUFreq 私有接口

| 面 | 关系 | 与 DDK 版本的关系 | 标签 |
| --- | --- | --- | --- |
| `libged.so` → `/dev/ged` → `ged.ko` | `libGLES_mali.so` **NEEDED** `libged.so`（硬依赖） | `ged.ko` **不反向依赖** kbase（0 命中）→ GED 侧不随 kbase 换代而断 | **CONFIRMED**（`04/03` §69） |
| `libgpud.so` | `libGLES_mali.so` NEEDED；80+ 个 `gpudVk*`/`gpudMisc*` 符号 | 同上，与 kbase 无直接绑定 | **CONFIRMED**（NEEDED 面）/ **UNKNOWN**（调用语义） |
| `libgpud_sys.so` | 被 `/system/lib64/libvulkan.so` NEEDED（MTK 定制） | 与 DDK 版本无关 | **CONFIRMED**（NEEDED 面） |
| GPUFreq / GPUEB | `mtk_gpufreq_wrapper` / `mtk_gpueb` **引用** kbase（正向），kbase 也被它们引用 | 若 kbase 换 R56，**连接层需重建**（`04/06`：保留 10 / 适配 2） | **CONFIRMED**（依赖方向）/ **UNKNOWN**（适配细节） |
| MET（`met_gpu_*`） | 本机**未装载** | 不构成风险面 | **CONFIRMED**（[D·B]） |

### 7.1 接口面已量化：84 条 MTK 侧符号（2026-11-16 实测）

对设备构建做 `readelf -x __versions` 全量解析后，R49 kbase 的 **513** 条 import 里有 **84 条**指向 MTK 平台模块。这份清单是 DDK-B 路线**唯一已经落到符号级**的约束——改造后的 DDK 或 R56 kbase 必须让这 84 条全部解析成功。

| 组 | 条数 | 代表符号 | 归属模块 |
| --- | ---: | --- | --- |
| `ged_mali_event_*` | 7 | `ged_mali_event_init`、`ged_mali_event_notify_fence_timeout_event`、`ged_mali_event_update_device_lost_nolock` | `ged.ko` |
| `ged_dvfs_*` | 20 | `ged_dvfs_cal_gpu_utilization_ex_fp`、`ged_dvfs_gpu_freq_commit_fp`、`ged_dvfs_write_sysram_last_commit_*` | `ged.ko` |
| 其它 `ged_*`（APO / KPI / idle 统计 / 白盒） | 22 | `ged_gpu_apo_notify`、`ged_kpi_get_target_fps`、`ged_get_predict_active_time`、`ged_set_whitebox_power_state_store` | `ged.ko` |
| `gpufreq_*` | 16 | `gpufreq_bringup`、`gpufreq_commit`、`gpufreq_set_limit`、`gpufreq_get_shader_present` | `mtk_gpufreq_wrapper.ko` |
| `gpueb_*` / `wait_gpueb` | 4 | `gpueb_get_mbox1_irq`、`gpueb_clr_mbox1_irq`、`gpueb_dump_status`、`wait_gpueb` | `mtk_gpueb.ko` |
| `mtk_*`（SWPM / PMU / LTR / 带宽 / 计时） | 15 | `mtk_swpm_gpu_pm_start_fp`、`mtk_ltr_gpu_pmu_start_fp`、`mtk_bandwidth_resource_init`、`mtk_get_system_timer_fp` | 多个 |
| **合计** | **84** | | |

> 逐条清单（含 CRC32）见 [`05_userspace_firmware/evidence/stage4_round1_20261116/mtk_side_symbols.md`](../05_userspace_firmware/evidence/stage4_round1_20261116/mtk_side_symbols.md)。

**三条推论（都可直接用于 Stage 5 的工作量估算）**：

1. **`_fp` 后缀占比高**（`ged_dvfs_*` / `mtk_*_fp`）：说明这些是**运行时解析的函数指针**，不是编译期强绑定。改造时可用同一套 `mtk_*_fp` 结构体，**不需要重编 MTK 模块**——这对 DDK-B 是实质利好。
2. **`ged.ko` 不 import 任何 kbase 符号**（241 条里 0 命中）：换 kbase 时 `ged` 无需重编，失败面**单向**。
3. **`module_layout` CRC 两模块同为 `0x4e276f37`**：说明两者针对同一内核配置构建。R56 kbase 若用不同内核头文件构建，**这一条就会先炸**（`disagrees about version of symbol module_layout`），是最廉价的失败信号。

标签：**[D·A]**（设备构建直接读出），不是推理。

---

> **本路线的结构性优势**：这些 MTK 私有对接**存在于 R49 DDK 源码内部**（`libGLES_mali` 就是调用方）。若拿到源码，这部分**不需要重写**；而 DDK-A（R56）必须把它们重新接一遍。这是 §3.3 中"改造是增量"的技术依据。标签 **LIKELY**（推理，未验证）。

---

## 8. G925 MC12 产品识别

**总判定：CONFIRMED —— R49 已完整支持，且就是在这台机器上跑的。**

| 检查项 | R49 | R56 | 标签 |
| --- | --- | --- | --- |
| `GPU_ID_PRODUCT_TKRX` 定义 | `gpu/mali_kbase_gpu_id.h:174` | 同 | **CONFIRMED** |
| `base_hw_features_tKRx[]` | 9 项 | 同 9 项（仅前缀 `BASE_`→`KBASE_`） | **CONFIRMED**（逐项相同） |
| `base_hw_issues_tKRx_r0p0[]` | 8 项 | 9 项 | **CONFIRMED**（差 3 项，见下） |
| 产品名映射 | `TKRX` → `"Mali-G725"`；`nr_cores ≥ 10 && RT` → `"Mali-G925-Immortalis"` | 同逻辑 | **CONFIRMED** |
| `gpuinfo` sysfs | `DEVICE_ATTR_RO(gpuinfo)`，输出 `"%s %d cores r%dp%d 0x%08X"` | 同 | **CONFIRMED** |
| MC12（12 核）| 设备为 12 核（[D·A] 规格 + DT） | — | **CONFIRMED** |

**issues 表的具体差**（R49 → R56）：

| 变更 | 项 |
| --- | --- |
| 移除 | `TURSEHW_2716` |
| 新增 | `KRAKEHW_2348`、`MAGNIHW_2257` |

> **重要**：这 3 项**全部在 kbase 侧**（`mali_kbase_hwconfig_issues.h` 是内核表），**DDK 不承担 workaround**。因此"换 R56 kbase"本身就能拿到全部 3 项，**与 DDK 用哪一代无关**。这也意味着：**R49 改造路线的硬件风险为零**（前提是 kbase 用 R56）。

---

## 9. R56 CSF 固件适配

**总判定：BLOCKED —— DDK 改造无法解决。**

| 事实 | 值 | 标签 |
| --- | --- | --- |
| 原厂固件 header | **0.3**（`offset 4 = 0x03`） | **CONFIRMED** [D·A] |
| R56 kbase 要求 | **0.4**，`!=` 严格、无 fallback | **CONFIRMED** [E1] |
| R49 kbase 要求 | **0.3** | **CONFIRMED** [E1] |
| 固件由谁加载 | **kbase**，在首次 `open()`（不在 probe） | **CONFIRMED** |
| DDK 能否影响 header 校验 | **不能**（校验在 kbase 的 `kbase_csf_firmware_load_init`） | **CONFIRMED** |
| 改 R49 固件 header 冒充 0.4 | **禁止**，且无效（entry 表随 release 变） | **CONFIRMED** |
| 失败发生点 | **header 校验**（`csf_firmware.c:2698`），**早于 entry 解析**（`:2794`）与 `parse_capabilities` | **CONFIRMED** [E1] |
| 原厂固件完整性 | `entry_end_offset = 1000`（≤ 307,200 → 截断检查必过）；首 entry = INTERFACE / 32 B（三项长度校验全过）；尾部 4 KiB 无版本串 | **CONFIRMED** [D·A]+[E1]（2026-11-16） |

**R56 固件验收判据**（6 条，见 `STAGE4_REMAINING_AUDIT.md` §3.3）：header 0.4 / magic / G925 MC12 core mask / GLB ≥ 1.1.0 / entry 布局与 R56 一致 / 同 release 交付。

> **顺序问题（必须写进设计）**：没有 0.4 固件，R56 kbase 连 `open()` 都过不去，**DDK 改造得再完美也无处可跑**。因此固件是**前置**，不是**并行项**。
>
> **2026-11-16 实测后的一条补充**：两侧的版本校验**代码形状完全一致**（都是 `if (version_major != MAJOR || version_minor != MINOR)`），只是常量 `3ul` vs `4ul`。这说明不存在"某种宽松模式"可被利用——**它就是硬编码相等比较**。
> 完整证据链：[`05_userspace_firmware/evidence/stage4_round2_20261116/firmware_header.md`](../05_userspace_firmware/evidence/stage4_round2_20261116/firmware_header.md) §5。

---

## 10. GLES / EGL / Vulkan 用户态接口

| 项 | 现状 | 改造含义 | 标签 |
| --- | --- | --- | --- |
| EGL 前端 | 系统 `libEGL.so`（API 37）承担；厂商只提供 GLES 驱动，由 loader `dlopen` 后取 `egl*` 入口 | 与 DDK 版本无关 | **CONFIRMED**（`05/07` §6） |
| `libEGL_mali.so` | **不存在且不必存在** | — | **CONFIRMED** |
| GLES 驱动 | `libGLES_mali.so` 单文件 53 MB，内含 EGL+GLES | 改造=重编这一个库 | **CONFIRMED** |
| Vulkan | `vulkan.mali.so` **是桩不是薄壳**：133,416 B，dynsym 仅 3 项，**唯一已定义函数 `mali_vk_vendor_stub` 只有 24 字节**，`DT_NEEDED` 首项 `libGLES_mali.so`，`RUNPATH $ORIGIN/../egl` | **Vulkan 随 GLES 走**，不需要单独改造；反汇编目标应是 `libGLES_mali.so` | **CONFIRMED**（2026-11-16 [D·A]） |
| Vulkan `api_version` | VINTF 声明 `vulkan.version-1_3` | 薄壳内的 `api_version` 来源未查 | **UNKNOWN**（U4-17） |
| MTK 私有 gralloc / allocator | `libGLES_mali.so` 硬依赖 4 个库 + allocator AIDL | 必须**整套**保留，不能只留 `libGLES_mali.so` | **CONFIRMED** |
| MEOW 拦截层 | `/vendor/lib64/egl/libGLES_meow.so` 等 5 个 | 小米图形拦截/追踪层，与 DDK 加载顺序相关 | **UNKNOWN** |

> **推论**：改造 `libGLES_mali.so` = 同时改动 GLES 与 Vulkan 的实现（因为 Vulkan 主体在里面）。这既是"改一处、两处受益"，也是"改坏了两个都坏"。

---

## 11. R56 新特性逐项保留矩阵

> 口径：**"原样运行"= R49 DDK 不改，跑在 R56 kbase 上（= 组合 C）；"改造后"= 有源码并实现对应语义。**
> 所有"改造后"列均为 **UNKNOWN**（无源码，未评估工作量）；此处只列**该项需要什么**。

| # | R56 新特性 | 载体 | 原样运行 | 改造需要什么 | 标签 |
| ---: | --- | --- | :---: | --- | --- |
| 1 | `REJECT_ALLOC_MEM_DONT_NEED`（1.31） | cap + `MEM_ALLOC` flags 校验 | ❌ 失 | 声称 ≥1.31 并在分配路径处理"拒绝 DONT_NEED"语义 | **UNKNOWN** |
| 2 | `REJECT_ALLOC_MEM_PROTECTED_IN_UNPROTECTED_ALLOCS`（1.31） | 同上 | ❌ 失 | 同上（保护内存分配约束） | **UNKNOWN** |
| 3 | `REJECT_ALLOC_MEM_UNUSED_BIT_20/27`（1.31） | flags 位校验 | ❌ 失 | 位定义对齐 | **UNKNOWN** |
| 4 | `REJECT_ALLOC_MEM_UNUSED_BIT_5/7`（1.32） | flags 位校验 | ❌ 失 | 位定义对齐 | **UNKNOWN** |
| 5 | `CSG_CS_USER_PAGE_ALLOCATION`（1.35） | CSG 创建时分配 CS_USER IO page | ❌ 失（走旧路径，功能上可能仍正确） | 改为在 CSG 创建时分配 | **UNKNOWN** |
| 6 | CSG 扩展字段：`neural_mask` / `comp_pri_threshold` / `comp_pri_ratio`（1.35+） | 112 B → 120 B 结构体 | ❌ 失（R49 结构体里这些字节是 padding） | 改用 120 B 结构体并填真值 | **UNKNOWN** |
| 7 | `fragment_endpoint_task_limit` / `neural_max`（1.38+） | 同上 | ❌ 失 | 同上 | **UNKNOWN** |
| 8 | `CS_TILER_HEAP_SIZE`（nr 62） | 新 ioctl：查 heap `size`/`peak_size` | ❌ 失（DDK 不会调用） | 实现调用 + 用于堆增长启发 | **UNKNOWN** |
| 9 | props `RAW_BASE_PRESENT` / `RAW_NEURAL_PRESENT` / `NUM_ACTIVE_GRANULARITY`（86/87/88） | GET_GPUPROPS 流 | ⚠️ 跳过（不影响功能） | 按 ID 解析并使用 | **UNKNOWN** |
| 10 | 硬件 workaround（`KRAKEHW_2348` / `MAGNIHW_2257`） | **kbase 侧** | ✅ **自动获得**（与 DDK 无关） | 无 | **CONFIRMED** |
| 11 | 其余 1.31–1.39 的 DDK 侧优化 | 未知（需 R56 DDK 对照） | ❌ 未知 | 需与 R56 DDK 行为逐项对齐 | **BLOCKED**（无 R56 DDK 作参照） |

> **净结论**：**原样运行时，R56 新特性保留度为 0**（第 10 项除外，它在 kbase 侧）。
> **这一点必须在任何对外表述中写清楚**：R49-derived 路线的**默认结果**是"能在 R56 kbase 上跑，但没有任何 R56 新特性"。宣称"保留 R56 特性"必须**先有源码、再逐项实现、再逐项验收**。

---

## 12. 必须改造的源码位置（拿到 R49 DDK 源码后的定位清单）

> **前提**：本节所有"文件"都是 **R49 DDK 源码**（不在库，需外部取得）。**行号无法给出**（无源码）。这里给的是"按功能定位"的清单 + **kbase 侧对照锚点**（可用于确认改动点是否落在正确位置）。

| # | 改造点 | 怎么定位（在 DDK 源码中） | kbase 侧对照锚点 | 优先级 |
| ---: | --- | --- | --- | --- |
| 1 | UK 版本握手指令 | 搜 `version_check` / `BASE_UK_VERSION_MINOR` / `ioctl` + `0x80` + nr 0 | `mali_kbase_core_linux.c:357-378` | **P0** |
| 2 | CSG 创建结构体 | 搜 `cs_queue_group_create` / `tiler_mask` / `fragment_mask` | `mali_kbase_core_linux.c:1446-1472` | **P0** |
| 3 | GPU props 协商 | 搜 `get_gpuprops` / `gpu_props_user_data` / `prop_buffer` | `mali_kbase_core_linux.c:870-891` | **P0** |
| 4 | `CS_QUEUE_REGISTER` 栈初始化 | 搜 `cs_queue_register` / `buffer_gpu_addr` | `mali_kbase_ioctl_helpers.h`（`CS_QUEUE_REGISTER` 分支） | **P0** |
| 5 | `CS_TILER_HEAP_INIT` 栈初始化 | 搜 `tiler_heap_init` / `chunk_size` | 同上 | **P1** |
| 6 | `MEM_ALLOC_EX` 的 `extra[]` | 搜 `mem_alloc_ex` | 同上 | **P1** |
| 7 | ioctl 55 调用点 | 搜 `limited_core_count` / 立即数 `55` | R49 `mali_kbase_core_linux.c:1803-1824` | **P1** |
| 8 | ioctl 80 调用点 | 搜 `internal_fence_wait` / 立即数 `80` / `2000` `3000` `4000` `5000` | R49 `mali_kbase_core_linux.c:1830-1880` | **P1** |
| 9 | caps 查询与分支 | 搜 `kbase_caps` / `SYSTEM_MONITOR` / `CSG_CS_USER_PAGE_ALLOCATION` | `mali_kbase_core_linux.c:145-163` | P2 |
| 10 | tiler heap 增长策略 | 搜 `tiler_heap` / `grow` / `target_in_flight` | `kbase_csf_tiler_heap*` | P2 |

> **成本提示**：第 1–6 项是"能不能跑"的门槛；第 7–8 项是"跑起来会不会崩"的门槛；第 9–10 项是"能不能拿到新特性"的门槛。**不要在第 9–10 项上先投入**。

---

## 13. 可能需要重写的模块（而非改造）

| 模块 | 为什么可能需要重写 | 标签 |
| --- | --- | --- |
| `libGLES_mali.so` 的 **CSF 后端**（CSG/CS 调度、tiler heap 管理） | 若要从 1.30 语义升到 1.35+，调度与堆管理的数据结构要跟着扩展（120 B 结构体、`neural_*`、`comp_pri_*`） | **UNKNOWN** |
| **GPU props 解析层** | 从"写死长度"改为"两步协商 + 按 ID 解析"是结构性改动 | **LIKELY** |
| **Vulkan 薄壳** | 只有 133 KB 且仅一个导出符号；若 `api_version` 被写死为 1.3 之外的值，需重编 | **UNKNOWN**（U4-17） |
| MTK 私有对接层（GED/GPUD） | **不需要重写**（R49 已有），只需随主库重编 | **LIKELY** |

> **注意**：以上全部是"如果拿到源码"的讨论。**没有源码，"重写"不成立**。

---

## 14. 无法通过 R49 改造实现的功能

| # | 功能 | 为什么不能 | 标签 |
| ---: | --- | --- | --- |
| 1 | **CSF 固件 header 0.4** | 由 kbase 校验，DDK 无权干预 | **CONFIRMED** |
| 2 | **G925 MC12 的固件内容**（core mask / GLB entry 布局） | 同上 | **CONFIRMED** |
| 3 | 无源码时的**任何行为改变** | 二进制不可维护 | **CONFIRMED**（条件性） |
| 4 | **MTK internal fence 超时自愈**（ioctl 80 + `CONFIG_MALI_MTK_FENCE_TIMEOUT_RESET`） | R56 kbase 没有该 ioctl；DDK 最多能"不发"，不能"恢复该能力"。若要保留，需在 **kbase 的 MTK 适配层**另建通道（不是 DDK 能解决的） | **CONFIRMED**（机制）/ **UNKNOWN**（是否有替代路径） |
| 5 | **"原生完整 R56 DDK"的任何等价物** | 没有 R56 源码作参照，无法证明行为等价 | **BLOCKED** |

---

## 15. 需要商业 R56 DDK 或厂商资料才能解决的问题

| # | 问题 | 需要什么 | 若拿不到 | 标签 |
| ---: | --- | --- | --- | --- |
| 1 | R56 新特性的**行为基线**（改到什么程度算"保留"） | R56 DDK 或 Arm 的特性说明 | 无法定义"保留"的验收标准，只能按 caps 表形式化判定 | **BLOCKED** |
| 2 | R56 固件（header 0.4 / G925 MC12） | Arm 商业交付 | 整条路线不可运行 | **BLOCKED** |
| 3 | 1.31–1.39 各版本 DDK 侧语义变更清单 | Arm release notes（商业件） | 只能从 kbase 的 caps 表反推"存在哪些门"，不知道"门后是什么" | **BLOCKED** |
| 4 | R49 DDK **源码** | MTK BSP / Arm 授权 | 路线退化为"原样运行"（组合 C） | **BLOCKED** |
| 5 | MTK 侧对 R56 的适配参考（若有） | 联发科授权包 | 需自研连接层（`04/06`：保留 10 / 适配 2） | **LIKELY**（可自研替代） |

---

## 16. 本路线当前证据评分

| 结论 | 等级 | 可被什么推翻 |
| --- | --- | --- |
| R49 DDK 在本机能驱动 G925 MC12 | **[D·A] + [D·B]** | 采集错误 |
| R49 与 R56 的 UAPI 结构体实质差异为 0 | **[E1]** | 读错结构体 |
| R49 kbase 已具备 `tKRx` 完整支持 | **[E1]** | 读错表 |
| R56 的 caps 表使 1.30 DDK 拿不到 1.31+ 能力 | **[E1]** | 读错判定逻辑 |
| CSG create 的 padding 已被设备行为证明为 0 | **[E1] + [D·B]** → **[E2]** | R49 kbase 的校验代码与实际构建不一致 |
| R49 DDK 源码不在设备/仓库 | **[E1]** | 目录枚举遗漏 |
| "R49 源码比 R56 DDK 更容易取得" | **[E3]** | 任何实证 |
| "改造后能保留 R56 特性" | **[U]** | 需源码 + 实施 + 验收 |

---

## 17. 引用

| 引用 | 位置 |
| --- | --- |
| 51 个共同结构体、2 处差异 | `05/09` §11.1；`STAGE4_REMAINING_AUDIT` §2 |
| ioctl 集合 54 → 50 | `STAGE4_REMAINING_AUDIT` §2 N-3 |
| caps 表与 `>=` 语义 | `02_r56_source/.../mali_kbase_core_linux.c:145-196` |
| `_1_35` 逐字段迁移 | `02_r56_source/.../mali_kbase_core_linux.c:1446-1472` |
| R49 内联 padding 校验 | `STAGE4_REMAINING_AUDIT` §2 N-1（含 9 处行号） |
| props 749 → 781 | `STAGE4_REMAINING_AUDIT` §2 N-2 |
| TLV 序列化 | `02_r56_source/.../mali_kbase_gpuprops.c:583-880` |
| R49 `tKRx` features / issues | `01_original_baseline/.../mali_base_hwconfig_features.h:154`、`mali_base_hwconfig_issues.h:596-614` |
| 固件 header 0.4 严格比对 | `02_r56_source/.../csf/mali_kbase_csf_firmware.c:85-86, 2698-2701` |
| 固件在 `open()` 加载 | `02_r56_source/.../mali_kbase_core_linux.c:790-802` |
| R49 DDK 编译产物身份 | `05/07` §5.1、§5.4 |
| MTK 依赖方向（保留 10 / 适配 2） | `04/06` §1；`04/03` §69 |

*本文件不含任何源码或配置改动；未编译、未刷机、未部署。*
