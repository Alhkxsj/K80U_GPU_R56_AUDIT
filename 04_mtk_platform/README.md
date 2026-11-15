# 04_mtk_platform — MT6991 原厂 GPU 平台适配层

> **状态：TASK 03 已交付**（2026-11-15）。本目录现为审计结论目录，不再是规划占位。

## 目的

回答一个核心问题：**能否最大程度保留 MT6991 原厂平台管理体系，只重建它与 R56p0 Kbase/CSF 之间的连接层？**

结论：**可以**。保留 10 个模块、适配 2 项、重写 0 项。详见 `06_platform_retention_matrix.md`。

## 交付物

| 文件 | 对应任务 | 内容 |
| --- | --- | --- |
| `01_module_dependency_audit.md` | 03-A | 15 个 `.ko` 的依赖方向、加载顺序、5 个必答问题 |
| `02_gpufreq_gpueb_architecture.md` | 03-B | GPUFreq→IPI→GPUEB 调用链、12 条 IPI 通道、52 项 OPP |
| `03_ged_integration_audit.md` | 03-C | GED 双向交互、devfreq governor 真实语义 |
| `04_mgm_pma_memory_audit.md` | 03-D | MGM ops 7→7 槽位替换、PMA 逐字节兼容、PBHA/SVP |
| `05_dts_hardware_resource_audit.md` | 03-E | dtbo 拆包、GPU 节点全属性、6 路中断、缺失属性分析 |
| `06_platform_retention_matrix.md` | 03-F + §四 | 保留/适配/重写矩阵、最小化路线、**六项 Stage 2 复核** |
| `MANIFEST.md` | — | 基准核对、SHA256、可执行复核命令、来源完整性 |

## 证据基础（与规划期假设不同，已修正）

规划期假设"MTK 平台层有源码"。实测：`01_original_baseline/mtk_kernel_modules/` 下**只有 r49p1 Kbase（581 文件）**，没有 `drivers/`。MTK 平台层的归档形态是 `kernel_ref_mt6991/vendor_dlkm/` 的 **15 个 `.ko`**。

因此方法改为三条互证的证据链：

1. **ELF 静态解析**：`.symtab` / `__ksymtab` / `__versions` / `.rela.*`（15 个模块均 `not stripped`）
2. **源码对读**：r49p1 Kbase 本体（调用方侧）
3. **DTB 反解析**：`mt6991.dtb` 实为 Android DT-Table 封装，拆包后 2,194 节点

## 原规划的子目录去向

规划中的 `vendor_patches/` `power_clock/` `dts/` `firmware_load/` `conflicts/` 五个子目录**未创建**，其内容已并入上表六份报告：

| 原规划 | 现落点 |
| --- | --- |
| `vendor_patches/` | `01` §2–§6（模块级）+ `06` §2.3（45 处结构体字段） |
| `power_clock/` | `02` 全篇 |
| `dts/` | `05` 全篇 |
| `firmware_load/` | `02` §3.1（`mali_csffw.bin` 加载未变）+ `04` §3.4（SVP 路径） |
| `conflicts/` | `06` §3（六项 Stage 2 复核，含 2 项推翻）+ §4 风险登记 |

理由：TASK 03 规定"只允许写入 `04_mtk_platform/`"，并建议 7 个产物。扁平化便于交叉引用，避免同一结论分散在多层目录。

## 与相邻目录的边界

- **换 SoC 也成立** → `03_kbase_csf/`；**只有 MT6991 成立** → 本目录
- **方案取舍**（选哪条路线、排期、人力）→ `06_porting_design/`，不在本目录下结论
- 本目录**不含**任何补丁、`.dts` 改动、Makefile/Kconfig 变更

## 遗留风险

1. **MTK 平台层无源码**：`MiCode/MTK_kernel_modules @ fe0fa7ff` 的 `drivers/gpu/mediatek/**`（211 文件）未归档，导致 6 项 UNKNOWN 无法闭环。
2. **固件与用户态 DDK 缺失**：`mali_csffw.bin`、`libGLES_mali.so` 全仓 0 命中，固件行为类问题无法静态解决。
3. **BSP 与出货固件可能不同点**：出厂 `.ko` 的 `vermagic` 为 `6.6.118-android15-8-g57e634f35c1b-4k`，与开源树 `f089d58c` 不同（见 `01_original_baseline/gpu_source_inventory.md` §0 第 10 条）。
