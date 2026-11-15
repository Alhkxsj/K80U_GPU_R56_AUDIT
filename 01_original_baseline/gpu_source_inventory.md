# K80U 原厂 GPU 驱动源码定位（TASK 01-B）

> 项目：K80U_GPU_R56_AUDIT — Redmi K80 至尊版（25060RK16C）/ MT6991 / Immortalis-G925 MC12
> 执行日期：2026-11-15
> 性质：**只读分析**。未修改任何源码文件，未编译，未刷机，未连接设备。
> 本轮新增操作仅一种：对 blobless 克隆按需拉取 blob 到 `/tmp` 临时目录（`git archive`，不触碰工作区、不改 index）。详见 §10。

---

## 0. 结论摘要

| # | 结论 | 强度 |
| --- | --- | --- |
| 1 | **原厂 GPU 驱动源码 100% 定位完毕：15 个出厂 `.ko` 全部找到对应 `.c` 源码**，无一遗留 | `[实证]` |
| 2 | **r49p1 源码原生支持 G925**：`mali_kbase_core_linux.c:3633-3639` 有 `GPU_ID_PRODUCT_TKRX` + `nr_cores>=10` + RT → `"Mali-G925-Immortalis"` 的显式分支 | `[实证]` |
| 3 | 出厂驱动实际走 **CSF 后端**（`MALI_USE_CSF=1`）：出厂 `.ko` 内 `kbase_csf_*` 符号 461 处 vs `kbase_jd_/kbase_job_` 仅 5 处 | `[实证]` |
| 4 | `mtk_gpu_qos.ko` 的源码是 **`drivers/gpu/mediatek/gpu_bm/gpu_bm.c`**——目录名 `gpu_bm`、模块名 `mtk_gpu_qos`，二者不同名导致此前漏检 | `[实证]`，**修正 01-A 的 M5** |
| 5 | `mtk_gpu_power_throttling.ko` 的源码是 **`drivers/misc/mediatek/power_throttling/mtk_gpu_power_throttling.c`**，此前检索范围止于 `drivers/gpu/` 导致漏检 | `[实证]`，**修正 01-A 的 M6** |
| 6 | MTK 平台适配源码共 **8 个模块 / 211 文件**（ged 54、gpufreq 88+5、gpueb 28、gpu_bm 3、pdma 3、iommu 2、hal 2、mt-plat 1，另构建入口 2） | `[实证]` |
| 7 | GPU 设备树节点在 **`mt6991.dts:7874`**，`compatible = "mediatek,mali", "arm,mali-valhall"`，基址 `0x48000000`，6 路中断，最高频 1.508 GHz | `[实证]` |
| 8 | **CSF 固件 `mali_csffw.bin` 与用户态 DDK 仍然缺失**——所有已获取仓库中 0 命中，这是本轮唯一真实硬缺口 | `[实证]` |
| 9 | `gpu_mali` 下并存 r47p0（613 文件）与 r49p1（559 文件），**仅 r49p1 与目标相关** | `[实证]` |
| 10 | 出厂内核构建 hash 为 `g57e634f35c1b`，与开源树 `f089d58c` **不同**，再次印证开源树非出厂同点快照 | `[实证]` |

---

## 1. 检索方法与命中矩阵

### 1.1 检索面

| 层 | 数据源 | 可检索内容 | 规模 |
| --- | --- | --- | --- |
| 路径层 | R1 / R3 的 `git ls-tree -r` | 全部文件路径 | 82,279 + 11,619 条 |
| 内容层 | R2 已落盘 r49p1 | 全文 grep | 581 文件 / 205,411 行 C/H |
| 内容层 | R3 GPU 子树（按需拉 blob 至 /tmp） | 全文 grep | 1,362 文件 / 20 MB |
| 内容层 | R3 power_throttling / dts / defconfig | 全文 grep | 36 文件 |
| 二进制层 | R5 的 15 个 `.ko` + `mt6991.dtb` | `strings` / modinfo 段 | 15 文件 / 3.8 MB |
| 清单层 | R2 tarball 原件 | `tar -tzf` 18,094 条 | 60.9 MB |

### 1.2 关键词命中矩阵

| 关键词 | R1 主内核树 | R3 设备模块树 | R2 modules | R5 二进制 |
| --- | ---: | ---: | ---: | ---: |
| `mali_kbase` | **0** | **736** | 现于 r49p1 | 1 个模块 |
| `kbase` | **0** | 736 | 581 文件内 | `kbase_csf_*` 461 处 |
| `CSF` / `csf` | **0** | 228 | csf/ 70 文件 | 461 处 |
| `GED` / `ged` | 19（**全为子串误命中**） | 54 | — | `ged.ko` |
| `GPUEB` / `gpueb` | **0** | 29 | — | `mtk_gpueb.ko` |
| `GPUFreq` / `gpufreq` | **0** | 98 | — | 2 个模块 |
| `gpu_mfg` | **0** | **0** | **0** | 0 |
| `IOMMU` / `iommu` | 194（多为 `drivers/iommu/` 通用框架） | 45 | — | `mtk_gpu_iommu_mt6991.ko` |

> **`ged` 的 19 条命中已逐条核验**：`drm_managed.c`、`khugepaged.c`、`evged.c`、`tagged-pointers.rst`、`voltagedomains*.c`、`ia_css_pipe_stagedesc.h` 等，**无一条**是 GED 调度器。R1 对 GPU 子系统的真实命中数为 **0**。`[实证]`
>
> **`gpu_mfg` 全库 0 命中**：该命名（Samsung/Exynos 常用）在本标的任一仓库中不存在，检索该词无意义。

---

## 2. A 类：ARM Kbase 核心驱动源码

### 2.1 定位

| 项 | 值 |
| --- | --- |
| 仓库 | `MiCode/MTK_kernel_modules` @ `fe0fa7ff68a2de0dec7ce1a04f5db6f07fd4a3b9` |
| 本地路径 | `01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/` |
| 文件数 | **581**（midgard 546 + `drivers/base/arm` 19 + `hwtracing` 13 + 上层 3） |
| 代码量 | **205,411 行** C/H（499 个 `.c/.h`） |
| 版本串 | `MALI_RELEASE_NAME = "r49p1-03bet0"`（`Makefile:526`） |
| 文件类型 | C 源码 / H 头文件 / Makefile+Kbuild（无二进制、无 LFS、无子模块） |

### 2.2 内部分层

> 口径：文件数为**递归**计数（含 Makefile/Kbuild），行数为该目录下 `.c/.h` 总行数。

| 目录 | 文件 | C/H 行数 | 组件定位 |
| --- | ---: | ---: | --- |
| `midgard/`（顶层） | 129 | 55,279 | kbase 核心：设备/上下文/内存/JS/IOCTL 入口 |
| `csf/` | 70 | 43,113 | **CSF 固件接口、队列组、门铃、同步对象** |
| `backend/` | 46 | 20,149 | 后端公共层（PM/GPU props/devfreq） |
| `platform/` | 110 | 18,025 | **MTK 平台适配层（含 mt6991 专属 3 文件）** |
| `hwcnt/` | 23 | 11,442 | 硬件计数器 |
| `tl/` | 12 | 10,513 | Timeline stream（Perfetto 数据源） |
| `mmu/` | 17 | 9,499 | MMU 页表、TLB、故障处理 |
| `hw_access/` | 15 | 8,179 | GPU 寄存器间接访问 |
| `include/` | 29 | 7,036 | UAPI 与内部公共头 |
| `tests/` | 31 | 5,420 | KUTF 单元测试 |
| `debug/` | 19 | 4,149 | debugfs / 白盒诊断 |
| `ipa/` | 13 | 3,817 | IPA 功耗控制 |
| `device/` | 9 | 2,611 | 设备初始化 |
| `jm/` | 3 | 2,259 | JM 后端（**出厂未编译**，见 §2.4） |
| `arbiter/` | 6 | 1,868 | **MTK 专有** GPU 仲裁层，r56p0 已无此目录 |
| `context/` | 6 | 1,082 | 上下文管理 |
| `thirdparty/` | 3 | 526 | 第三方（CRC/列表） |
| `gpu/` | 5 | 444 | GPU ID / 属性抽象 |
| **合计（midgard）** | **546** | **205,411**（仅 `.c/.h`，共 499 个） | 另加 `drivers/base/arm/` 19 + `hwtracing/` 13 + 上层 3 = **581** |

### 2.3 关键符号

| 结构体 / 函数 | 位置 | 作用 |
| --- | --- | --- |
| `struct kbase_device` | `mali_kbase_defs.h:1187` | 全局设备对象，承载 PM/MMU/CSF/平台回调 |
| `struct kbase_context` | `mali_kbase_defs.h:2087` | 每进程 GPU 上下文 |
| `kbase_driver_init()` | `mali_kbase_core_linux.c:6764` | 模块入口（`module_init`） |
| `kbase_platform_driver` | `mali_kbase_core_linux.c:6762` | `module_platform_driver` 绑定 |
| `kbase_csf_queue_register()` | `csf/mali_kbase_csf.c:604` | CS 队列注册（UK IOCTL 落点） |
| `kbase_csf_queue_group_*` | `csf/mali_kbase_csf.c` | 队列组生命周期 |
| `kbase_csf_firmware_*()` | `csf/mali_kbase_csf_firmware.c` | 固件加载/启动/重载/核心转储 |
| `kbase_csf_firmware_reload()` | `csf/mali_kbase_csf_firmware.c:2258` | 固件重载（r56p0 变更重点） |
| `kbase_arbif_init()` | `arbiter/mali_kbase_arbif.c:237` | MTK 仲裁接口注册 |

### 2.4 后端判定：CSF 而非 JM（关键）

源码树同时含 `jm/`（3 文件）与 `csf/`（65 文件），但**编译期只能二选一**：

```make
# Makefile:545-550
ifeq ($(CONFIG_MALI_CSF_SUPPORT),y)
    MALI_USE_CSF = 1
else
    MALI_USE_CSF ?= 0
endif
```

出厂二进制的判定证据：

| 指标 | 出厂 `mali_kbase_mt6991_r49.ko` |
| --- | --- |
| `kbase_csf_*` 符号/路径字符串 | **461** |
| `kbase_jd_*` / `kbase_job_*` | **5** |
| 编译路径包含 `csf/…` | 是（`mali_kbase_csf_csg.c`、`_event.c`、`_sync.c`、`ipa_control/…` 等） |
| 固件名 `mali_csffw.bin` | **存在**（`csf/mali_kbase_csf_firmware.c:84` 的 `default_fw_name`） |
| CSF 保留内存节点名 | `mediatek,me_CSFFWLOG_reserved` |
| Timeline 事件 | `KBASE_TL_KBASE_CSFFW_FW_ENABLING/DISABLING/RELOADING/…` 全套 |

> **判定：出厂驱动是 CSF-only 构建。** 源码里的 `jm/` 目录属"随包携带但未参与链接"，不得据其存在推断为 JM 驱动。`[实证]`

### 2.5 G925 支持判定（本任务最重要的一条）

`drivers/gpu/arm/midgard/mali_kbase_core_linux.c` 第 3633–3640 行：

```c
if (product_model == GPU_ID_PRODUCT_TKRX) {
    const bool rt_supported = gpu_props->gpu_features.ray_intersection;
    const u8 nr_cores = gpu_props->num_cores;

    if ((nr_cores >= 10) && rt_supported)
        product_name = "Mali-G925-Immortalis";
    else
        product_name = (nr_cores >= 6) ? "Mali-G725" : "Mali-G625";
```

配套定义在 `include/uapi/gpu/arm/midgard/gpu/mali_kbase_gpu_id.h:174-175`：

```c
#define GPU_ID_PRODUCT_TKRX  GPU_ID_MODEL_MAKE(13, 0)
#define GPU_ID_PRODUCT_LKRX  GPU_ID_MODEL_MAKE(13, 1)
```

**推导链**：K80U 为 Immortalis-G925 **MC12**（12 核）→ `product_model == TKRX` 成立 → `nr_cores=12 >= 10` 成立 → 该机必须支持光线追踪（G925 硬件特性）→ 走第一分支 → 产品名 `Mali-G925-Immortalis`。

> 结论：**r49p1 在源码层面原生、显式地支持 G925**，型号识别不依赖任何补丁或外部表。产品名由运行时读 GPU 寄存器得出，设备树不写死型号。`[实证]`（代码逻辑）+ `[推断]`（12 核与 RT 为公开规格，未在真机验证）

### 2.6 A 类字段汇总

| 字段 | 内容 |
| --- | --- |
| 仓库名称 | `MiCode/MTK_kernel_modules` @ `fe0fa7ff` |
| 文件完整路径 | `gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/`（499 文件）+ `…/drivers/base/arm/`（19）+ `…/drivers/hwtracing/`（13） |
| 文件类型 | `.c` / `.h` / `Makefile` / `Kbuild` — **纯源码，无预编译件** |
| 所属组件 | ARM Mali Kbase DDK r49p1（CSF 后端） |
| 关键函数/结构体 | `kbase_device`、`kbase_context`、`kbase_csf_queue_register`、`kbase_csf_firmware_*` |
| 是否属于 MT6991 | 主体平台无关；MT6991 专属见 `platform/mt6991/` 3 文件 |
| 能否确认 G925 | **能**（`core_linux.c:3633-3639`） |
| 依赖关系 | 依赖 MGM、PMA、GED、GPUFreq、GPUEB、GPU_HAL、PDMA（见 §5） |

---

## 3. B 类：MTK GPU 平台适配源码

### 3.1 总览（R3 `kernel_dev_modules_dali` @ `e45c3199`）

| 模块 | 目录 | 文件 | C/H 行数 | 产物 `.ko` | MT6991 专属文件 |
| --- | --- | ---: | ---: | --- | --- |
| GED 调度器 | `drivers/gpu/mediatek/ged/` | 54 | 26,273 | `ged.ko` | 平台共用 |
| GPUFreq v2 | `…/gpufreq/v2/` | 24 | — | `mtk_gpufreq_wrapper.ko`<br>`mtk_gpufreq_mt6991.ko` | `gpufreq_mt6991.c`<br>`gpufreq_reg_mt6991.h`<br>`gpufreq_history_mt6991.c` |
| GPUFreq v2-legacy | `…/gpufreq/v2_legacy/` | 48 | — | —（`CONFIG_MTK_GPU_LEGACY` 未启用） | 否 |
| GPUFreq v1（子目录） | `…/gpufreq/v1/` | 14 | — | —（`CONFIG_MTK_GPUFREQ_V2=y` 时不编译） | 否 |
| GPUFreq 顶层 | `…/gpufreq/Makefile`、`mtk_gpufreq.h` | 2 | — | — | 否 |
| GPUFreq v1（独立目录） | `…/gpufreq_v1/` | 5 | 158 | — | 否 |
| GPUEB 协处理器 | `…/gpueb/` | 28 | 5,000 | `mtk_gpueb.ko` | 平台共用 |
| GPU BM / QoS | `…/gpu_bm/` | 3 | 580 | **`mtk_gpu_qos.ko`** | 平台共用 |
| GPU PDMA | `…/gpu_pdma/` | 3 | 808 | `mtk_gpu_pdma_mt6991.ko` | `gpu_pdma_mt6991.c` |
| GPU IOMMU | `…/gpu_iommu/` | 2 | 50 | `mtk_gpu_iommu_mt6991.ko` | `gpu_iommu_mt6991.c` |
| GPU HAL | `…/hal/` | 2 | 777 | `mtk_gpu_hal.ko` | 平台共用 |
| 平台头 | `…/mt-plat/` | 1 | 119 | — | `mtk_gpu_utility.h` |
| 构建入口 | `…/Makefile`、`Kconfig` | 2 | — | — | — |
| **GPU 功耗限流** | `drivers/misc/mediatek/power_throttling/` | 23 | — | **`mtk_gpu_power_throttling.ko`** | `mtk_gpu_power_throttling.c/.h` |

### 3.2 逐模块详表

#### B-1 GED（Graphics Engine Driver，GPU 调度枢纽）

| 字段 | 内容 |
| --- | --- |
| 仓库 | `MiCode/MTK_kernel_device_modules` @ `e45c3199` |
| 完整路径 | `drivers/gpu/mediatek/ged/`（`src/` 26 个 `.c`，`include/` 27 个 `.h`，`Makefile`） |
| 文件类型 | C 源码 + 头文件 |
| 关键函数/结构体 | `ged_init()`（`src/ged_main.c:979`，`module_init`）；`g_ged_pdrv`（`platform_driver`）；导出 `ged_notification`、`ged_vsync_notifier_fp`、`ged_set_target_fps`、`ged_dvfs_set_gpu_core_mask_fp`、`ged_get_segment_id` |
| 是否 MT6991 | 平台共用（同一份代码服务 MT6877/MT6893/MT6991 等） |
| 能否确认 G925 | 否（经 kbase 回调间接服务于任意 GPU） |
| 依赖 | `mtk_gpufreq_wrapper`、`mtk_gpu_hal`、`mtk_gpu_qos`、`mtk_gpueb`、`mediatek-drm`、`thermal_interface`、`sspm_v3`、`system_heap` |

#### B-2 GPUFreq（DVFS）

| 字段 | 内容 |
| --- | --- |
| 完整路径 | `drivers/gpu/mediatek/gpufreq/v2/gpufreq_mt6991.c`（MT6991 平台实现）<br>`…/v2/gpufreq_v2.c`（框架）<br>`…/v2/gpufreq_history_mt6991.c`（频点历史）<br>`…/v2/include/gpufreq_reg_mt6991.h`（寄存器映射）<br>`…/v2/gpuppm.c`（PPU 功耗模型） |
| 产物拆分 | `mtk_gpufreq_wrapper.ko` ← `gpufreq_v2.o + gpufreq_history.o + gpufreq_debug.o`<br>`mtk_gpufreq_mt6991.ko` ← `gpufreq_history_mt6991.o + gpuppm.o + gpufreq_mt6991.o` |
| 关键函数/结构体 | `gpufreq_power_ctrl_enable`、`gpufreq_get_dvfs_state`、`gpufreq_get_shader_present`、`gpufreq_active_sleep_ctrl_enable`、`gpufreq_get_cur_oppidx`（被 QoS 引用） |
| 是否 MT6991 | **是**（`gpufreq_mt6991.c:223` 有 `MT6991_B0` ECO 分支） |
| 依赖 | `mtk_gpueb`、`mtk_gpu_hal`、`mtk_pbm`、`device-apc-common`、`mtk_ghpm_swwa`、`mtk_tinysys_ipi` |

#### B-3 GPUEB（GPU 微控制器协处理器）

| 字段 | 内容 |
| --- | --- |
| 完整路径 | `drivers/gpu/mediatek/gpueb/gpueb.c`、`gpueb_ipi.c`、`ghpm*.c`、`include/gpueb_ipi.h` |
| 关键函数/结构体 | `__gpueb_init()`（`gpueb.c:304`）；`g_gpueb_of_match[]`；`gpueb_ipi_send()`、`get_gpueb_ipidev()` |
| 是否 MT6991 | 平台共用 |
| 依赖 | `mtk_tinysys_ipi`、`mtk-mbox` |

#### B-4 GPU BM / QoS（**本轮关键修正**）

| 字段 | 内容 |
| --- | --- |
| 完整路径 | `drivers/gpu/mediatek/gpu_bm/gpu_bm.c`（580 行）、`gpu_bm.h`、`Makefile` |
| 文件类型 | C 源码 |
| **模块名映射** | `Makefile`：`obj-$(CONFIG_MTK_GPU_SUPPORT) += mtk_gpu_qos.o`<br>`mtk_gpu_qos-y := gpu_bm.o` |
| 关键函数/结构体 | `MTKGPUQoS_setup()`、`MTKGPUQoS_mode()`、`MTKGPUQoS_mode_ratio()`、`MTKGPUQoS_is_inited()`、`MTKGPUQoS_getBW()`；`g_GPU_BM_lock`、`gpu_bm_inited`、`gpu_opp_high` |
| 是否 MT6991 | 平台共用（读 dts `gpu_qos` 节点 + `qos-opp-high` 属性） |
| 依赖 | `mtk_gpu_hal`、`mtk_gpufreq_wrapper`、**`mtk_qos`**（后者源码在 `drivers/misc/mediatek/qos/`） |

**三重独立证据锁定该映射**：

1. `Makefile` 显式 `mtk_gpu_qos-y := gpu_bm.o`
2. `.ko` 的 `MODULE_DESCRIPTION("MediaTek GPU QOS")` 与 `gpu_bm.c:534` **逐字符一致**
3. `.ko` 内字符串 `"@%s: Failed to find gpu_qos node"`、`"qos-opp-high: %d"` 对应 `gpu_bm.c:458,477` 的 `pr_info` 格式串

> **01-A 报告 §7.1 的 M5「`mtk_gpu_qos.ko` 对应源码缺失」判定错误，此处撤销。** 漏检原因：只按 `*qos*` 文件名检索，未建立"目录名 → 模块名"映射。

#### B-5 GPU PDMA

| 字段 | 内容 |
| --- | --- |
| 完整路径 | `drivers/gpu/mediatek/gpu_pdma/gpu_pdma_mt6991.c`（含 `pdma_of_match[]`、`gpu_pdma_init`、`pdma_lock_reclaim`） |
| 是否 MT6991 | **是**（文件名与 `CONFIG_MTK_GPU_MT6991_SUPPORT` 绑定） |
| 依赖 | `ged`、`mtk_gpueb`、`mtk_gpufreq_wrapper` |

#### B-6 GPU IOMMU

| 字段 | 内容 |
| --- | --- |
| 完整路径 | `drivers/gpu/mediatek/gpu_iommu/gpu_iommu_mt6991.c`（50 行，极薄封装） |
| 关键结构体 | `match_table[]`（`of_device_id`，compatible `mediatek,gpu-iommu`） |
| 是否 MT6991 | **是** |
| 依赖 | 无（modinfo `depends=` 为空）；实际通过 dts 的 `iommus = <&gpu_smmu 0x01/0x02>` 绑定 |

#### B-7 GPU HAL

| 字段 | 内容 |
| --- | --- |
| 完整路径 | `drivers/gpu/mediatek/hal/mtk_gpu_utility.c`（777 行） |
| 关键函数 | `mtk_get_gpu_memory_usage()`、`mtk_get_gpu_memory_pool()`、`mtk_get_gpu_loading()` |
| 依赖 | 无（被 ged / kbase / pdma 等反向依赖） |

#### B-8 GPU 功耗限流（**本轮关键修正**）

| 字段 | 内容 |
| --- | --- |
| 完整路径 | `drivers/misc/mediatek/power_throttling/mtk_gpu_power_throttling.c`（217 行）、`.h` |
| 关键结构体/函数 | `struct gpu_pt_priv`、`gpu_pt_info[]`、`mtk_gpu_power_throttling_probe()`、`gpu_power_throttling_of_match[]`；回调 `gpu_pt_low_battery_cb`、`gpu_pt_over_current_cb`、`gpu_pt_battery_percent_cb` |
| 构建条件 | `Kconfig:99` `config MTK_GPU_POWER_THROTTLING`（tristate）<br>`Makefile`：`obj-$(CONFIG_MTK_GPU_POWER_THROTTLING) += mtk_gpu_power_throttling.o`<br>`mgk_64_k66_defconfig`：`CONFIG_MTK_GPU_POWER_THROTTLING=m` |
| 是否 MT6991 | 平台共用 |
| 依赖 | `mtk_low_battery_throttling`、`mtk_battery_oc_throttling`、`mtk_bp_thl`、`mtk_gpufreq_wrapper` |

> **01-A 报告 §7.1 的 M6「`mtk_gpu_power_throttling.ko` 对应源码缺失」判定错误，此处撤销。** 漏检原因：检索范围限定在 `drivers/gpu/mediatek/**`，而该文件在 `drivers/misc/mediatek/power_throttling/`。

### 3.3 15 个出厂 `.ko` 的源码归属（闭环表）

| # | 模块 | 大小 | 源码仓库 | 源码完整路径 | 构建目标 | 状态 |
| ---: | --- | ---: | --- | --- | --- | :--: |
| 1 | `mali_kbase_mt6991_r49.ko` | 2256.3 KB | R2 | `gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/` | `obj-m` via `mt6991/Makefile` | ✅ |
| 2 | `mali_mgm_mt6991_r49.ko` | 54.4 KB | R2 | `…/mali-r49p1/drivers/base/arm/memory_group_manager/` | 同上 | ✅ |
| 3 | `mali_prot_alloc_mt6991_r49.ko` | 20.6 KB | R2 | `…/mali-r49p1/drivers/base/arm/protected_memory_allocator/` | 同上 | ✅ |
| 4 | `ged.ko` | 1067.7 KB | R3 | `drivers/gpu/mediatek/ged/` | `obj-$(CONFIG_MTK_GPU_SUPPORT) += ged.o` | ✅ |
| 5 | `mtk_gpueb.ko` | 125.5 KB | R3 | `drivers/gpu/mediatek/gpueb/` | 隐式（目录级 `obj-y`） | ✅ |
| 6 | `mtk_gpufreq_wrapper.ko` | 148.2 KB | R3 | `drivers/gpu/mediatek/gpufreq/v2/gpufreq_v2.c` 等 3 文件 | `mtk_gpufreq_wrapper-y := gpufreq_v2.o gpufreq_history.o gpufreq_debug.o` | ✅ |
| 7 | `mtk_gpufreq_mt6991.ko` | 115.6 KB | R3 | `drivers/gpu/mediatek/gpufreq/v2/gpufreq_mt6991.c` 等 3 文件 | `mtk_gpufreq_mt6991-y := …` | ✅ |
| 8 | `mtk_gpu_iommu_mt6991.ko` | 12.5 KB | R3 | `drivers/gpu/mediatek/gpu_iommu/gpu_iommu_mt6991.c` | `mtk_gpu_iommu_mt6991-y := gpu_iommu_mt6991.o` | ✅ |
| 9 | `mtk_gpu_pdma_mt6991.ko` | 39.6 KB | R3 | `drivers/gpu/mediatek/gpu_pdma/gpu_pdma_mt6991.c` | `mtk_gpu_pdma_mt6991-y := gpu_pdma_mt6991.o` | ✅ |
| 10 | `mtk_gpu_hal.ko` | 57.6 KB | R3 | `drivers/gpu/mediatek/hal/mtk_gpu_utility.c` | `mtk_gpu_hal-y := mtk_gpu_utility.o` | ✅ |
| 11 | `mtk_gpu_qos.ko` | 32.6 KB | R3 | **`drivers/gpu/mediatek/gpu_bm/gpu_bm.c`** | `mtk_gpu_qos-y := gpu_bm.o` | ✅ **新** |
| 12 | `mtk_gpu_power_throttling.ko` | 37.4 KB | R3 | **`drivers/misc/mediatek/power_throttling/mtk_gpu_power_throttling.c`** | `obj-$(CONFIG_MTK_GPU_POWER_THROTTLING) += …` | ✅ **新** |
| 13 | `met_gpu_api.ko` | 14.0 KB | R2 | `met_drv_v3/default/met_api/met_gpu_api/met_gpu_api.c` | `obj-m += met_gpu_api.o` | ✅ **新** |
| 14 | `met_gpu_adv_api.ko` | 11.9 KB | R2 | `met_drv_v3/default/met_api/met_gpu_adv_api/met_gpu_adv_api.c` | `obj-m += met_gpu_adv_api.o` | ✅ **新** |
| 15 | `met_gpueb_api.ko` | 13.8 KB | R2 | `met_drv_v3/default/met_api/met_gpueb_api/met_gpueb_api.c` | `obj-m += met_gpueb_api.o` | ✅ **新** |

> **15/15 全部有源码归属。** 01-A 报告中「10/15」的统计作废，M5、M6、U6 三项 UNKNOWN 全部关闭。

---

## 4. C 类：GPU 固件与设备树

### 4.1 设备树（源码级）

| 字段 | 内容 |
| --- | --- |
| 仓库 | `MiCode/MTK_kernel_device_modules` @ `e45c3199` |
| 完整路径 | `arch/arm64/boot/dts/mediatek/mt6991.dts` |
| 节点行号 | `mali: mali@48000000` @ **7874** |
| 文件类型 | DTS 源码（文本） |

**节点全文要点**（`mt6991.dts:7874-7910`）：

```dts
mali: mali@48000000 {
    compatible = "mediatek,mali", "arm,mali-valhall";
    reg = <0 0x48000000 0 0x480000>;          /* 基址 + 4.5 MB */
    l2-hash-values = <0xb 0xe 0x0>;
    physical-memory-group-manager = <&mgm>;
    interrupts = <GIC_SPI 606 …>, <605 …>, <604 …>, <607 …>, <608 …>, <612 …>;
    interrupt-names = "JOB", "MMU", "GPU", "EVENT", "PWR", "GPUEB_MBOX1";
    protected-memory-allocator = <&gpu_protected_memory_allocator>;
    operating-points-v2 = <&gpu_mali_opp>;
    #cooling-cells = <2>;
    system-coherency = <0>;
    ged-supply = <&ged>;
    sleep-mode-enable = <1>;
    firmware-idle-hysteresis-time-us = <0>;
    default-glb-pwroff-timeout-us = <10>;
    autosuspend-delay-ms = <10>;
    adaptive-power-policy = <2>;
    pbha { propagate-bits = /bits/ 8 <0xf>; };
};
```

| 字段 | 内容 |
| --- | --- |
| 所属组件 | GPU 顶层设备节点 |
| 关键属性 | `compatible`（绑定 kbase）、`interrupt-names`（6 路）、`default-glb-pwroff-timeout-us`（**CSF 专属**：全局掉电超时）、`firmware-idle-hysteresis-time-us`（**CSF 专属**：固件空闲迟滞） |
| 是否 MT6991 | **是**（SoC 级 dts，非板级） |
| 能否确认 G925 | **间接确认**：`arm,mali-valhall` + 6 路 CSF 中断 + 固件属性，与 G925（5th Gen CSF-only）一致；但 dts **不写型号与核数**，型号由运行时 GPU 寄存器读出 |
| 依赖 | `&mgm`、`&gpu_protected_memory_allocator`、`&ged`、`&gpu_mali_opp`、`&gpu_smmu` |

**配套节点**：

| 节点 | 行号 | compatible | 作用 |
| --- | ---: | --- | --- |
| `mgm` | 3160 | `arm,physical-memory-group-manager` | 内存组管理（对应 `mali_mgm_*.ko`） |
| `gpu_protected_memory_allocator` | 3164 | `arm,protected-memory-allocator`（`pma-version=2`, `gpr-id=6`, 保留 2 MB） | 受保护内存（对应 `mali_prot_alloc_*.ko`） |
| `ged` | 3191 | `mediatek,ged` | GED 调度器 |
| `gpufreq_wrapper` | 3196 | `mediatek,gpufreq_wrapper`（`gpufreq-version=2`, `dual-buck=1`, `gpueb-support=1`） | DVFS 框架 |
| `gpupdma@48540000` | 3203 | `mediatek,gpupdma` | PDMA |
| `gpu_smmu: iommu@48600000` | 10895 | `arm,smmu-v3`, `mtk,smmu-v700`, `mediatek,mt6991-gpu-smmu` | GPU 专用 SMMU（2 个 SID：1=normal, 2=protected） |
| `gpu_mali_opp` | 7912 起 | `operating-points-v2` | 频压表，最高 **1,508 MHz @ 850 mV** |

> **`mtk_gpu_qos` 在 dts 中无独立节点**——`gpu_bm.c:458` 的 `"Failed to find gpu_qos node"` 说明它**尝试查找** `gpu_qos` 节点但 dali 平台未提供，走的是默认兜底路径。这是一条实证：QoS 功能在此机型上依赖 dts 缺省值而非显式配置。`[实证]`

### 4.2 GPU 固件

| 项 | 状态 | 证据 |
| --- | --- | --- |
| `mali_csffw.bin` | **不存在于任何已获取仓库** | R5 全量 1,585 条清单 `csffw`/`csf_fw`/`firmware` 命中 0；R6 Arm 包内亦无 |
| 固件加载器源码 | 存在 | `csf/mali_kbase_csf_firmware.c`（`default_fw_name = "mali_csffw.bin"`） |
| 固件在设备上的实际位置 | `[UNKNOWN]` | 推测在 `/vendor/firmware/` 或 `vendor_dlkm` 分区，需真机确认 |

> 这是**唯一真实硬缺口**：没有 CSF 固件，任何内核侧移植都无法让 GPU 跑起来。`[实证]`

---

## 5. D 类：预编译二进制

### 5.1 出厂 GPU 模块（15 个，全部为 `.ko`）

| 项 | 值 |
| --- | --- |
| 来源 | `xiaomi-mt6991-devs/android_device_xiaomi_dali-kernel` @ `0576426` |
| 本地路径 | `01_original_baseline/kernel_ref_mt6991/vendor_dlkm/` |
| 文件类型 | **ELF aarch64 可重定位目标（`.ko`）**，非源码 |
| 统一 vermagic | `6.6.118-android15-8-g57e634f35c1b-4k SMP preempt mod_unload modversions aarch64` |
| 是否 MT6991 | **是**（点名 `_mt6991_` 的 5 个 + 其余为 MT6991 构建产物） |
| 能否确认 G925 | 否（二进制不含 GPU 型号；型号在运行时由寄存器读出） |

> **vermagic 里的 `g57e634f35c1b` 是本轮新证据**：这是出厂内核的构建 git hash 前缀，与开源树 `f089d58c` 完全不同。说明出厂内核来自一个**未开源**的 commit。`[实证]`

### 5.2 依赖关系（modinfo 段实测）

```
[底座层]
  mtk_gpu_hal          depends=(空)
  mtk_gpu_iommu_mt6991 depends=(空)
  mtk_gpueb            depends=mtk_tinysys_ipi, mtk-mbox
        │
[框架层]
  mtk_gpufreq_wrapper  depends=mtk_gpueb, mtk_gpu_hal, mtk_pbm,
                                device-apc-common, mtk_ghpm_swwa, mtk_tinysys_ipi
        │
[功能层]
  mtk_gpufreq_mt6991   depends=mtk_gpufreq_wrapper, mtk_gpueb, mrdump
  mtk_gpu_qos          depends=mtk_gpu_hal, mtk_gpufreq_wrapper, mtk_qos
  mtk_gpu_pdma_mt6991  depends=ged, mtk_gpueb, mtk_gpufreq_wrapper   ← 注意：反向依赖 ged
  mtk_gpu_power_throttling depends=mtk_low_battery_throttling, mtk_battery_oc_throttling,
                                mtk_bp_thl, mtk_gpufreq_wrapper
        │
[调度层]
  ged                  depends=mtk_gpufreq_wrapper, mtk_gpu_hal, mtk_gpu_qos,
                                mtk_gpueb, thermal_interface, mediatek-drm,
                                sspm_v3, system_heap, mtk_tinysys_ipi
        │
[驱动层]
  mali_kbase_mt6991_r49 depends=mtk_gpufreq_wrapper, ged, mtk_gpu_hal, mtk_gpueb,
                                mtk_gpu_pdma_mt6991, aee_aed, irq-dbg, mrdump,
                                emi, mtk_sec_heap, tmem_ffa, mtk_slbc
  mali_prot_alloc_mt6991_r49 depends=mtk_gpueb, mtk_gpufreq_wrapper, mtk_sec_heap, tmem_ffa
  mali_mgm_mt6991_r49  depends=emi, system_heap, mtk_slbc
        │
[跟踪层]
  met_gpu_api          depends=met, mtk_gpu_hal
  met_gpu_adv_api      depends=met, mtk_gpu_hal
  met_gpueb_api        depends=met, mtk_gpueb
```

**两个必须注意的依赖异常**：

1. **`ged` ↔ `mtk_gpu_pdma_mt6991` 循环依赖**：`ged` 不依赖 pdma，但 `pdma` 依赖 `ged`；而 `mali_kbase` 同时依赖两者。实际加载顺序由 `modules.dep`（depmod 生成）决定，`modules.load.vendor` 的书写顺序**不等于** insmod 顺序。
2. **`mtk_gpu_qos` 位置矛盾**：`ged.ko` 声明依赖 `mtk_gpu_qos`，但 `modules.load.vendor` 里 ged 在第 49 行、qos 在第 87 行。若按文件顺序裸 `insmod`，ged 必然失败。→ 佐证 Android 使用 `modprobe` 而非顺序 `insmod`。`[推断]`

### 5.3 用户态库

| 项 | 状态 |
| --- | --- |
| `libGLES_mali.so` | **不存在于任何已获取仓库**（R5 全量清单 0 命中） |
| Vulkan 用户态（`libvk*`） | **不存在** |
| 实际位置 | `[UNKNOWN]`，推测在 `/vendor/lib64/egl/`，需真机提取 |

---

## 6. 类型归属总判定

| 类型 | 命中 | 数量 | 结论 |
| --- | --- | --- | --- |
| **A. ARM Kbase 核心驱动源码** | R2 `mali-r49p1/drivers/gpu/arm/midgard/` | 499 文件 / 205,411 行 | ✅ 完整，纯源码 |
| **B. MTK GPU 平台适配源码** | R3 `drivers/gpu/mediatek/`（除 gpu_mali）+ `drivers/misc/mediatek/power_throttling/` | 188 + 23 文件 | ✅ 完整，纯源码 |
| **C. GPU 固件与设备树** | 设备树 ✅ / 内核配置 ✅ / **固件 ❌** | dts 11 + config 3 / 固件 0 | ⚠️ 固件缺失 |
| **D. 预编译二进制** | R5 `vendor_dlkm/*.ko` 15 个 + `dtb/mt6991.dtb` | 15 + 1 | ✅ 已识别，**全部标注为二进制** |

> **严格区分声明**：本报告中，凡 `.ko` 一律标注为「预编译二进制模块」，凡 `.so` 一律标注为「用户态预编译库」。**不存在**任何将二进制称为源码的表述。R5 仓库 `.c` 文件数为 **0**，是全量 1,585 条清单的实测结果。`[实证]`

---

## 7. 与 TASK 01-A 的差异清单

| 项 | 01-A 结论 | 01-B 实测 | 处置 |
| --- | --- | --- | --- |
| M5 `mtk_gpu_qos.ko` 源码 | 缺失 | **存在**：`drivers/gpu/mediatek/gpu_bm/gpu_bm.c` | 撤销 M5 |
| M6 `mtk_gpu_power_throttling.ko` 源码 | 半缺失/UNKNOWN（M6 + U4） | **存在**：`drivers/misc/mediatek/power_throttling/mtk_gpu_power_throttling.c` | 撤销 M6、U4 |
| U6 三个 `met_*` 源码 | 待细核 | **全部确认**：`met_drv_v3/default/met_api/*/` | 撤销 U6 |
| §5.3 源码归属 | 10/15 | **15/15** | 更新统计 |
| §5.4 两套 r49p1 差异原因 | R3 缺 `drivers/base/arm/*`、`hwtracing` | **错**：两侧 `drivers/base` 均 19、`hwtracing` 均 13；R3 实际缺的是 6 个其他 SoC 平台目录（18 文件）+ 4 个 `mtk_platform_common` 工具文件 | **修正** |
| §5.4 文件数 | R2 664 / R3 559 | R2 **581** 实体 / R3 **559**；664 是含目录的 tree 条目数 | **修正口径** |
| 后端判定 | "JM+CSF 双后端" | 源码双后端，**出厂构建为 CSF-only** | **补充** |

---

## 8. 缺口与 UNKNOWN

| # | 项 | 性质 | 影响 |
| --- | --- | --- | --- |
| G1 | `mali_csffw.bin` CSF 固件 | **硬缺失** | 无固件则 GPU 无法启动，移植方案必须解决 |
| G2 | 用户态 DDK（`libGLES_mali.so` 等） | **硬缺失** | 决定能否沿用现网闭源 blobs |
| G3 | Android 16 内核树 | 不存在（沿用 01-A 结论） | 需真机核实实际内核 |
| U1 | `mtk_gpu_qos` 的 `mtk_qos` 底层源码是否与出厂一致 | `drivers/misc/mediatek/qos/` 存在，但未逐版本核对 | 影响 QoS 行为复现 |
| U2 | 出厂内核 commit `57e634f35c1b` 是否已开源 | 开源树为 `f089d58c`，不匹配 | 无法精确复现符号 CRC |
| U3 | `gpu/mt6991/Makefile` 同时列 r48p0/r49p1 两组 `obj-m` 如何择一 | 仍存疑 | 但出厂 `.ko` 版本串为 r49p1，且 `mali_avalon/Makefile` 按 `CONFIG_MTK_GPU_VERSION` 第 3 词单一选择，实际应只编 r49p1 |
| U4 | 12 核 + RT 为真机实测属性 | 公开规格推断 | 需 `dmesg | grep -i "Mali-G925"` 验证 |

---

## 9. 对下一阶段的影响

1. **`03_kbase_csf` 可无阻碍开工**：r49p1 CSF 后端 65 文件 41,750 行 + r56p0 对侧源码齐备，可做逐文件 diff。
2. **`04_mtk_platform` 材料 100% 齐备**：8 个模块源码 + 设备树 + 15 个 `.ko` + 依赖图，无需再补源码。
3. **`05_userspace_firmware` 的唯一阻塞点是 G1/G2**：必须拿到 `mali_csffw.bin` 与用户态 blobs，否则整条链断在最后一步。
4. **两条可直接执行的验证命令**（需真机，本阶段未执行）：
   ```bash
   adb shell 'dmesg | grep -iE "mali|g925|kbase"'      # 验证 G925 识别
   adb shell 'uname -r; getprop ro.build.version.release'  # 验证内核与 Android 版本
   adb shell 'find / -name "mali_csffw.bin" 2>/dev/null'   # 定位固件
   ```

---

## 10. 本轮操作合规声明

| 操作 | 是否执行 | 说明 |
| --- | --- | --- |
| 修改源码文件 | **否** | 所有文件仅读取 |
| 编译 | **否** | 无 `make`、无 `gcc`、无 `clang` |
| 刷机 / 连接设备 | **否** | 全程未接触真机 |
| 下载新仓库 | **否** | 仅复用 01-A 已获取的 4 个仓库 + 1 个 tarball |
| 按需拉取 blob | **是** | `git archive HEAD <path> \| tar -x -C /tmp/…`，共 3 次（`drivers/gpu/mediatek` 1,362 文件、dts 12 文件、`power_throttling` 23 文件、`defconfig` 1 文件）。**不写工作区、不改 index、不改 remote** |
| 写入项目目录 | 仅 2 个产出 | 本报告 + `_inventory/gpu_path_inventory.md` |

---

## 附录：完整路径清单

- **A 类全量**：581 条，见 `_inventory/gpu_path_inventory.md` §A
- **B 类全量**：188 条（已剔除 gpu_mali 副本），见 §B
- **B2 功耗限流**：23 条，见 §B2
- **R3 gpu_mali 副本**：1,174 条（r47p0 613 + r49p1 559），见 §A′ 统计表
- **C/D 类**：dts 11 + config 3 + `.ko` 15 + dtb 1，见 §C/§D

清单文件：`01_original_baseline/_inventory/gpu_path_inventory.md`
