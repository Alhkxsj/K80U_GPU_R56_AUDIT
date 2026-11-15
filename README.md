# K80U_GPU_R56_AUDIT

> **Redmi K80 至尊版（25060RK16C）· Arm Mali 5th Gen GPU 驱动 R56p0 移植可行性审计**

本仓库是一个**只读式技术审计工程**，用于评估将 Arm Mali 第五代（5th Gen / CSF 架构）GPU 驱动 **R56p0** 移植到本机 Android 16 / Linux 6.6 / MT6991 平台的可行性。仓库本身不是驱动工程，不承载可直接编译的生产代码。

---

## 1. 审计标的

| 项目 | 取值 |
| --- | --- |
| 设备型号 | Redmi K80 至尊版 |
| 机型代码 | 25060RK16C |
| SoC 平台 | MediaTek **MT6991** |
| GPU | Arm **Immortalis-G925 MC12**（5th Gen，CSF 固件驱动架构） |
| 操作系统 | **Android 16** |
| 内核 | **Linux 6.6**（GKI 形态） |
| 目标驱动 | Arm Mali GPU DDK **R56p0**（kbase 内核驱动 + CSF firmware + 用户态 blobs） |

> 审计结论必须同时落在三条链路上：**内核驱动（kbase）**、**固件（CSF firmware）**、**用户态（GLES/Vulkan/gralloc/composer）**。任何单点替换都不构成"移植完成"。

---

## 2. 当前状态（截至 2026-11-15 19:45）

| 阶段 | 内容 | 状态 | 产物 / 证据 |
| --- | --- | --- | --- |
| Stage 0 | 目录骨架与审计说明 | ✅ 完成 | 本文件、各目录 `README.md` / `MANIFEST.md` |
| Stage 1 | 参考资料与基线采集 | ✅ 完成 | `01_original_baseline/`（r49p1 源码 581 文件）、`02_r56_source/`（R56p0 454 文件） |
| Stage 2 | R56p0 落盘 + kbase/CSF 差异审计 | ✅ 完成 | `03_kbase_csf/` 7 份产物，45 条差异（13 P0） |
| Stage 3 | MTK 平台层差异比对 | ✅ 完成 | `04_mtk_platform/` 7 份产物（保留 10 / 适配 2 / 重写 0）+ REA 二进制补充审计 8 份 |
| Stage 4 | 用户态与固件 ABI 核对 | 🔄 **进行中** | `05_userspace_firmware/` 6 份报告已交付；**固件与用户态 blob 未采集，21 项 UNKNOWN 待补** |
| Stage 5 | 方案设计与可行性结论 | ⏳ 未开始 | `06_porting_design/`、`final_report/` 仅目录骨架 |

> **Stage 4 的实质进展与硬边界**
>
> 已完成：UAPI 契约逐字段比对（ioctl 28/28 逐字相同、结构体 30/30 兼容、属性 ID 83/83 不变）、CSF 固件加载链路两版逐行对照、能力阈值表解析、四组合八维矩阵。
>
> 已确认的硬结论：**原厂 CSF 固件 header 为 0.3，R56p0 要求 0.4 且用 `!=` 严格校验 → 组合 B（只换内核）确定不可行**。
>
> 已修正的预期：**原厂用户态 DDK 在契约层可保留**（此前假设必须同步替换）。最小替换范围收敛为 **Kbase + CSF 固件两件套**。
>
> 未完成的原因：仓库内无 `mali_csffw.bin`、无 `libGLES_mali.so`、无 Vulkan ICD、无 gralloc/HWC/VINTF。已提供只读采集脚本 `05_userspace_firmware/tools/collect_device.sh`（不落地二进制），待设备证据补齐后闭合 4 项 P0 UNKNOWN。详见 [`05_userspace_firmware/06_abi_compatibility_matrix.md`](05_userspace_firmware/06_abi_compatibility_matrix.md) §7。

**两条基线均已实体在手**——此前"R56p0 未获取、Stage 2 阻塞"的判断已失效：

| 基线 | 落盘位置 | 规模 | 来源与校验 |
| --- | --- | --- | --- |
| 出厂 `r49p1-03bet0`（UK ABI **1.30**） | `01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/` | 581 文件 / 8.3 MB | `MiCode/MTK_kernel_modules @ bsp-dali-v-oss`（commit `fe0fa7ff`）；"路径—版本串—模块名—模块清单"四环闭合判定即出厂源码，见 [`source_integrity.md`](01_original_baseline/source_integrity.md) §5.1 |
| 官方 `r56p0-18eac0`（UK ABI **1.39**） | `02_r56_source/mali_r56p0/driver/product/kernel/` | 454 文件 / 5.58 MB | 用户登录 Arm 下载原包；MD5 `62b168823691eb61ec29654cbf35e719` 与 Arm 清单一致，未 patch、未格式化、未编译 |

### 2.1 Stage 0（历史记录，已完成）

硬约束全部遵守：只建目录与说明文档、未修改源码、未编译、未接触设备、未引入第三方二进制。

### 2.2 Stage 1（历史记录 · 结论已被后续进展推翻）

2026-11-15 上午的采集结论如下，原文保留在 [`SOURCE_ACQUISITION.md`](SOURCE_ACQUISITION.md) 作为留痕，**不代表当前状态**：

| 目标 | 当时结果 | 现状 |
| --- | --- | --- |
| Arm R56p0 内核驱动源码 | ❌ 未获取（需 Arm 账号 + EULA） | ✅ **已获取**，454 文件，MD5 校验通过 |
| 出厂 r49p1 内核源码 | ❌ 仅有 `.ko` 二进制 | ✅ **已获取**，581 文件，四环闭合 |
| MT6991 内核参考仓库 | ⚠️ 部分获取（仓库只含预编译产物） | ⚠️ 维持：该仓库确无内核源码；主内核树另由 `MiCode/Xiaomi_Kernel_OpenSource @ f089d58c` 补齐（82,279 文件，但**不含任何 GPU 驱动**） |
| PanVK 第三方参考 | ⚠️ 部分获取 | ⚠️ 维持：仅文档与兼容矩阵，未取主体源码 |

> 采集期的阻塞细节（Arm 站 403、登录跳转、清单令牌等）作为审计留痕保存于 [`02_r56_source/SOURCING_STATUS.md`](02_r56_source/SOURCING_STATUS.md) §3。

### 2.3 Stage 2（当前成果，2026-11-15）

R56p0 源码落盘并完成五域差异审计，产物见 [`03_kbase_csf/`](03_kbase_csf/)：

| 产物 | 内容 |
| --- | --- |
| `01_uapi_abi_diff.md` | UAPI / UK ABI：14 条实质差异 + 1 条文档形态变更（`KB-030`）；ABI 1.30→1.39，`base_mem_handle` 删除、`CSG_CREATE` 58→63 / 112→120、`gpu_props_user_data` 568→592 |
| `02_csf_architecture_diff.md` | CSF 核心：9 条；CSF-only 化、`fw_io` 抽象、reset 路径重构 |
| `03_memory_mmu_diff.md` | 内存 / MMU：8 条；MGM 签名破坏（P0）、PMA 的 SVP 安全区消失 |
| `04_pm_interface_diff.md` | 电源：7 条；12 个回调成员一致，但 devfreq 静默退回 `simple_ondemand` |
| `05_g925_hardware_support.md` | G925：7 条；`kbase_regmap_v12_init` 两版逐字节相同（38 行，均在第 1106 行） |
| `06_blocking_issues.md` | 汇总：45 条实质差异（13 P0 / 11 P1 / 5 P2 / 16 P3），回答五个终局问题 + U1–U10 |
| `MANIFEST.md` | 登记、SHA256、可执行复核命令 |

核心结论：**不存在"保留 MTK 平台层、只换 Arm 通用核心"的干净切面**——约 1,200 处 MTK 注入中有近 900 处位于 Arm 核心文件内部（见 `06` Q5）。

---

## 3. 目录职责

| 目录 | 职责 | 写入性质 |
| --- | --- | --- |
| `00_reference/` | 上游规范与参考资料登记册（Arm DDK 文档、MTK BSP 文档、AOSP/GKI 要求） | 登记为主，仅存链接与摘要 |
| `01_original_baseline/` | 原厂基线快照：出厂 kbase 版本、配置、DTS、固件与模块元数据 | **只读**，禁止改动 |
| `02_r56_source/` | R56p0 上游源码树（Arm 官方 DDK 交付物） | **只读**，保持原样，禁打补丁 |
| `03_kbase_csf/` | kbase / CSF 内核驱动的结构分析、调用链、ABI 清单、差异笔记 | 分析产物 |
| `04_mtk_platform/` | MTK 平台适配层：私有 patch、电源时钟 OPP、mfgcfg、DTS 集成 | 分析产物 + 差异比对 |
| `05_userspace_firmware/` | 用户态组件与固件：GLES/Vulkan blobs、gralloc、composer、CSF bin、加载路径 | 清单与 ABI 分析 |
| `06_porting_design/` | 移植方案设计、兼容矩阵、风险登记册、回滚方案、验证计划 | 设计产物 |
| `final_report/` | 最终审计报告与结论、证据索引 | 交付物 |

**边界原则**：原始证据（`01`、`02`）与分析结论（`03`–`06`）物理隔离，任何结论必须能回溯到 `01`/`02`/`00` 中的具体文件或版本号。

---

## 4. 审计原则

1. **基线不可变**：`01_original_baseline/` 与 `02_r56_source/` 一旦落盘即冻结，后续所有改动只能以 patch/diff 形式出现在 `03`–`06`，永不回写原树。
2. **证据可追溯**：每条结论附 `文件路径:行号` 或 `版本号 / commit / 校验和`。
3. **版本三对齐**：kbase 版本、CSF firmware 版本、用户态 blobs 版本构成一个 ABI 三元组，必须整体对齐，禁止混搭。
4. **差异最小化**：优先"以 MTK 基线为底、按需回移 R56p0 变更"，而非"以上游 R56p0 为底、重做 MTK 适配"。该取向将在 `06_porting_design/` 中做正式论证。
5. **可回滚**：任何设计必须给出回到出厂状态的路径（备份分区/模块版本）。
6. **合规**：不提交签名私钥、不开源厂商 blobs、不绕过设备完整性校验机制。

---

## 5. 阶段路线图

| 阶段 | 内容 | 产出目录 | 状态 |
| --- | --- | --- | --- |
| Stage 0 | 目录骨架与审计说明 | 全仓库 | ✅ 完成 |
| Stage 1 | 参考资料与基线采集（版本、配置、ABI 快照） | `00` `01` | ✅ 完成（两条基线均在手） |
| Stage 2 | R56p0 源码落盘、结构测绘与 kbase/CSF 差异审计 | `02` `03` | ✅ 完成 |
| Stage 3 | MTK 平台层差异比对 | `04` | ✅ 完成（+ REA 二进制补充审计） |
| Stage 4 | 用户态与固件 ABI 核对 | `05` | 🔄 **进行中**（契约层完成，blob 待采集） |
| Stage 5 | 方案设计与可行性结论 | `06` `final_report` | ⏳ 未开始 |

---

## 6. 留档规范

- **命名**：`<分类>_<对象>_<版本|日期>.<ext>`，例：`kbase_version_MT6991_20261115.txt`、`diff_mtk_vs_r56p0_kbase_20261115.patch`。
- **清单**：每个目录必须同时存在 `README.md`（职责说明）与 `MANIFEST.md`（文件清单：名称 / 来源 / 版本或校验和 / 采集日期 / 采集方式）。
- **禁止提交**：构建产物（`*.o`、`*.ko`、`*.so` 的编译输出）、日志、临时脚本输出、密钥与证书、超过 50 MB 的单个二进制。
- **大文件**：确实需要归档的固件/镜像，只登记路径、大小与 SHA256，实体另行存放并在 `MANIFEST.md` 注明。
- **提交粒度**：一个阶段一个提交，提交信息格式 `stage<N>: <动作> <对象>`。

---

## 7. 关键问题的闭环情况

| # | 问题 | 状态 | 依据 |
| --- | --- | --- | --- |
| 1 | 出厂 kbase 的 `BASE_KERNEL_VERSION` / `MALI_RELEASE_NAME` | ✅ 已确认 | `r49p1-03bet0`，源码 `Makefile:526` 与出厂 `.ko` 的 `K:r49p1-03bet0(GPL)` 逐字符一致；跨至 `r56p0-18eac0`，UK ABI 1.30→1.39（9 个 minor） |
| 2 | MTK 私有改动是否可枚举、可分离 | ⚠️ 可枚举，**不可分离** | 约 1,200 处注入 / 39 个 `CONFIG_MALI_MTK_*` / 约 70 个专属文件；其中近 900 处在 Arm 核心文件内部（`03_kbase_csf/06` Q5） |
| 3 | CSF firmware 的 `fw version` 与 kbase `kernel ABI` 匹配窗口 | ✅ **已判定（不兼容）** | 两版加载器逐行对照：`FIRMWARE_HEADER_VERSION_MINOR` **0.3 → 0.4**，且用 `!=` 严格相等校验、无兼容分支 → 原厂固件被 R56p0 拒绝（`05/02` §3）。固件实体仍缺，运行时 GLB 版本为 UNKNOWN |
| 4 | 用户态 blobs 是否与 R56p0 kbase 的 ioctl / uk ABI 对齐 | ⚠️ **契约层已闭环，实现层未验证** | ioctl 28/28 逐字相同、结构体 30/30 兼容、属性 ID 83/83 不变、能力表为 1.30 保留旧语义（`05/03`）。`libGLES_mali.so` 未取得，故"DDK 是否遵守契约"仍为 UNKNOWN（U4-04） |
| 5 | Android 16 / GKI 6.6 的 `vermagic` / `MODULE_SIG` / KMI 是否允许替换 GPU 模块 | ❓ 未验证 | 已知出厂 vermagic 为 `g57e634f35c1b`，与开源树 `f089d58c` 不同；模块签名在 TASK 03-REA 中确认为 `signature: absent`，但 KMI 符号 CRC 绑定仍需实机验证 |
| 6 | G925 MC12 的配置项（core mask、DVFS 频点、电源域）在 R56p0 中的支持形态 | ✅ 已闭环（MTK 侧） | 寄存器映射与产品识别逻辑两版一致（`03_kbase_csf/05`）；DVFS/电源域由 MTK 平台层负责且**对 kbase 零反向依赖**（`04/01` §4），保留即可 |

> **更新后的闭环状态**：第 3 项已从"未验证"升级为"已判定不兼容"——这是本阶段最重要的结论，它直接把"只换内核"的路径排除。第 4 项在契约层已充分闭环，剩余风险转移到"DDK 是否遵守契约"，属可实测范畴。第 5 项仍需实机验证，是 Stage 4 收尾的最后一个硬门槛。

---

## 8. 变更记录

| 日期 | 阶段 | 变更 |
| --- | --- | --- |
| 2026-11-15 | Stage 0 | 初始化目录骨架与 8 份审计说明文件，建立留档规范 |
| 2026-11-15 | Stage 1（历史） | 源码资料采集：确认基线 kbase 为 `r49p1-03bet0`；落盘 MT6991 参考仓库 GPU 子集（21 文件）与 PanVK 文档子集（17 文件）；Arm R56p0 源码因登录门槛未获取，出具 `SOURCE_ACQUISITION.md`。**该结论当晚被推翻，见下两行** |
| 2026-11-15 | Stage 1（补） | 出厂 `r49p1` 源码取得：`MiCode/MTK_kernel_modules @ bsp-dali-v-oss`（`fe0fa7ff`），落盘 581 文件 / 8.3 MB，四环闭合判定为出厂源码；主内核树 `MiCode/Xiaomi_Kernel_OpenSource @ f089d58c` 落盘（82,279 文件，不含 GPU 驱动） |
| 2026-11-15 | Stage 2 | R56p0 原包落盘（`AX504X08X-SW-99002-r56p0-18eac0.tar.gz`，454 文件 / 5.58 MB，MD5 `62b1688…` 校验通过）+ `03_kbase_csf` 五域差异审计完成（45 条：13 P0 / 11 P1 / 5 P2 / 16 P3） |
| 2026-11-15 | docs | 修正 `README.md`、`02_r56_source/SOURCING_STATUS.md`、`02_r56_source/STRUCTURE_MAP.md`、`SOURCE_ACQUISITION.md` 中"R56p0 未获取""r49p1 未获取"的过时表述；历史记录与当前状态分列，原文留痕不删除 |
| 2026-11-15 | Stage 3 | `04_mtk_platform/` 完成：7 份报告。结论 **保留 10 / 适配 2 / 重写 0**；建立"MTK 平台层对 kbase 零反向依赖"定理；发现 MGM ops 第 7 槽位静默错配；纠正任务书前提（`mtk_kernel_modules/drivers/` 不存在，平台层实为 15 个 `.ko`） |
| 2026-11-15 | Stage 3-REA | 引入 REA + Ghidra 12.2 对 12 个 `.ko` / 5,440 函数反编译，出 `REA_SUPPLEMENT.md`。修正 4 项量化前提（`gpufreq_fp` 实为 416B/52 项而非 72B/9 项等），新增 kCFI 类型哈希风险 |
| 2026-11-15 | Stage 4 | `05_userspace_firmware/` 6 份报告 + 只读采集脚本。**核心结论：固件 header 0.3≠0.4 硬不兼容（组合 B 否决）；原厂用户态契约层可保留（组合 C 候选）**；最小替换范围收敛为 Kbase + 固件两件套。blob 未采集，21 项 UNKNOWN（4 项 P0） |
