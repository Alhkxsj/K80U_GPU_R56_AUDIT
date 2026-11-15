# K80U_GPU_R56_AUDIT

> **Redmi K80 至尊版（25060RK16C）· Arm Mali 5th Gen GPU 驱动 R56p0 移植可行性审计**

本仓库是一个**只读式技术审计工程**，用于评估将 Arm Mali 第五代（5th Gen / CSF 架构）GPU 驱动 **R56p0** 移植到本机 **Android 17 / Linux 6.6.143 / MT6991** 平台的可行性。仓库本身不是驱动工程，不承载可直接编译的生产代码。

---

## 1. 审计标的

| 项目 | 取值 | 来源 |
| --- | --- | --- |
| 设备型号 | Redmi K80 至尊版 | — |
| 机型代码 | 25060RK16C（代号 `dali`） | `ro.product.model` **[D]** |
| SoC 平台 | MediaTek **MT6991** | `ro.board.platform` **[D]** |
| GPU | Arm **Immortalis-G925 MC12**（5th Gen，CSF 固件驱动架构） | `compatible = arm,mali-valhall` **[D]** |
| 操作系统 | **Android 17（SDK 37）** · HyperOS `OS4.0.3.0.XONCNXM` | `ro.build.version.release/sdk`、`ro.build.fingerprint` **[D]** |
| 内核 | **Linux 6.6.143-android15-8-gf9aa2fec23c3-4k**（GKI 形态；`android15` 是分支名，非 Android 版本） | `uname -a` **[D]** |
| **运行时内核** | **第三方 GKI 构建**（KernelSU + SUSFS 补丁；内核源码提交 `f9aa2fec23c3…`，基于 Google GKI `android15-6.6`） | `u:r:ksu:s0` **[D]** + 构建运行页 **[B]** |
| 目标驱动 | Arm Mali GPU DDK **R56p0**（kbase 内核驱动 + CSF firmware + 用户态 blobs） | `02_r56_source/` |

> **本表三处已按真机更正（2026-11-15）**：原写 "Android 16"、"Linux 6.6（GKI 形态）"、"机型代码 25060RK16C"（正确但缺代号）。Android 版本差异不是文字问题——它直接影响 `README` §7 第 5 项（KMI/vermagic）与 HyperOS 版本前提。
>
> **第四处更正（2026-11-15 21:40）**：设备运行的是**第三方 GKI 内核**，不是原厂 boot。`/vendor` 与 `/vendor_dlkm` 仍是厂商分区内容（安装包只写 `boot`）。因此本仓库所有"设备实测"必须按 **A 类（厂商文件）/ B 类（第三方内核运行时）/ C 类（厂商模块）** 分开读，见 [`05_userspace_firmware/08_kernel_provenance_audit.md`](05_userspace_firmware/08_kernel_provenance_audit.md)。
>
> 审计结论必须同时落在三条链路上：**内核驱动（kbase）**、**固件（CSF firmware）**、**用户态（GLES/Vulkan/gralloc/composer）**。任何单点替换都不构成"移植完成"。

---

## 2. 当前状态（截至 2026-11-15 21:00）

| 阶段 | 内容 | 状态 | 产物 / 证据 |
| --- | --- | --- | --- |
| Stage 0 | 目录骨架与审计说明 | ✅ 完成 | 本文件、各目录 `README.md` / `MANIFEST.md` |
| Stage 1 | 参考资料与基线采集 | ✅ 完成 | `01_original_baseline/`（r49p1 源码 581 文件）、`02_r56_source/`（R56p0 454 文件） |
| Stage 2 | R56p0 落盘 + kbase/CSF 差异审计 | ✅ 完成 | `03_kbase_csf/` 7 份产物，45 条差异（13 P0） |
| Stage 3 | MTK 平台层差异比对 | ✅ 完成 | `04_mtk_platform/` 7 份产物（保留 10 / 适配 2 / 重写 0） |
| Stage 3-REA | 二进制逆向补充审计（REA + Ghidra） | ✅ 完成 | `04_mtk_platform/REA_SUPPLEMENT.md` 等 8 份；12 个 `.ko` / 5,440 函数 |
| Stage 4 | 用户态与固件 ABI 核对 | 🔄 **报告已交付，证据未闭环** | `05_userspace_firmware/` 8 份（`01`–`08`）；**27 项 UNKNOWN，闭合 4 项** |
| Stage 5 | 方案设计与可行性结论 | ⏳ 未开始 | `06_porting_design/`、`final_report/` 仅目录骨架 |

> **Stage 4 的两种状态必须分开读**
>
> | 维度 | 状态 | 说明 |
> | --- | --- | --- |
> | **报告交付** | ✅ 完成 | 首轮 6 份（`efd8547`）+ 真机证据整合（`04-fix`，第 7 份）+ 来源审计（`stage4: audit … provenance`，第 8 份） |
> | **来源归属** | ✅ 完成 | A/B/C 三分：厂商文件 / 第三方内核运行时 / 厂商模块（`05/08`） |
> | **证据闭环** | ⚠️ **未完成** | 27 项 UNKNOWN / 闭合 4 项 / 部分闭合 3 项；**P0 仍有 4 项** |
>
> **已完成（证据支持）**
> - UAPI 契约逐字段比对：ioctl 28/28 逐字相同、结构体 30/30 兼容、属性 ID 83/83 不变、能力表为 ≤1.30 保留旧语义
> - 真机基线实测：kbase `r49p1-03bet0 (UK version 1.30)`、`/dev/mali0` 在、GPU 服务在跑（**运行于第三方 GKI 内核之上**）
> - 用户态构成实测：`libGLES_mali.so` 53,105,232 B / API 35 / NEEDED `libged`+`libgpud`；Vulkan 为 133,416 B 薄壳
> - 图形栈依赖实测：HWC/mapper 不链接 DDK，但 NEEDED `libged`；composer 3.3
>
> **硬结论（注意证据等级）**
> - **源码判据**：r56p0 的 CSF 加载器只接受 header `0.4`，用 `!=` 严格校验、无 fallback → **组合 B（只换内核）不可行** **[E1]**
> - **实测判据**：原厂固件 header 实际值 **仍为 UNKNOWN**（三份采集未覆盖 offset 4/5），仅有 E2 级启动一致性推理指向 `0.3` → 组合 B 的否决**逻辑成立、证据待确认**
> - **原厂用户态在契约层可保留**（UAPI 全兼容 + `min()` 夹取），但必须**整套**保留，实现层未验证
> - **来源判据**：设备 `.ko` 与仓库基线 `.ko` 不是同一构建（vermagic `6.6.118-…` vs 运行内核 `6.6.143-…`）→ Stage 3 的二进制级常量需以设备构建重导 **[E1]+[E2]**
>
> **未闭环的原因**：缺运行时证据（dmesg / strace / 故障注入），以及两个可用 8 字节与 2 条 `grep` 闭合的 P0 项。详见 [`05_userspace_firmware/06_abi_compatibility_matrix.md`](05_userspace_firmware/06_abi_compatibility_matrix.md) §7、[`05_userspace_firmware/07_device_evidence.md`](05_userspace_firmware/07_device_evidence.md) §10 与 [`05_userspace_firmware/08_kernel_provenance_audit.md`](05_userspace_firmware/08_kernel_provenance_audit.md) §6。

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
| Stage 3 | MTK 平台层差异比对 | `04` | ✅ 完成（+ Stage 3-REA 二进制补充审计） |
| Stage 4 | 用户态与固件 ABI 核对 | `05` | 🔄 **报告已交付 / 来源已归属 / 证据未闭环**（27 项 UNKNOWN，闭合 4 项） |
| Stage 5 | 方案设计与可行性结论 | `06` `final_report` | ⏳ 未开始（前置条件：U4-01/U4-04 闭合 + U4-24 基线重导；**可设计、不可定论**） |

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
| 3 | CSF firmware 的 `fw version` 与 kbase `kernel ABI` 匹配窗口 | ⚠️ **源码判据已判定 / 实测判据未闭合** | 两版加载器逐行对照：`FIRMWARE_HEADER_VERSION_MINOR` **3 → 4**，`!=` 严格相等、无兼容分支（`05/02` §3.1）。**原厂固件实际 header 值仍为 UNKNOWN**（字节未采，U4-01），仅有 E2 级启动一致性推理指向 0.3（`05/02` §3.0） |
| 4 | 用户态 blobs 是否与 R56p0 kbase 的 ioctl / uk ABI 对齐 | ⚠️ **契约层已闭环，实现层未验证** | ioctl 28/28 逐字相同、结构体 30/30 兼容、属性 ID 83/83 不变、`min()` 夹取保证有效版本 ≤1.30（`05/03`）。真机已确认 `libGLES_mali.so` 存在（53 MB / API 35）及其对 `libged`/`libgpud` 的硬依赖；**DDK 自称版本与行为仍为 UNKNOWN**（U4-04） |
| 5 | Android 17 / GKI 6.6.143 的 `vermagic` / `MODULE_SIG` / KMI 是否允许替换 GPU 模块 | ⚠️ **分层：装载可行已证，替换未证** | ①**装载**：厂商 12 个 GPU 模块已在**重编的** `6.6.143` GKI 内核上成功装载（`lsmod` + `/dev/mali0` + 服务 pid）→ GKI KMI（`android15-8`）未被破坏 **[D·B]**+**[D·C]**；②**代次**：仓库基线 15 个 `.ko` 的 vermagic 为 `6.6.118-…-g57e634f35c1b`，**与运行内核不相等**，不能直接用于该设备 **[E1]**+**[E2]**；③**替换**：r56p0 kbase 需匹配 MTK 模块导出的 89 个符号及其 CRC，未验证 **[U]**（U4-24/U4-25） |
| 6 | G925 MC12 的配置项（core mask、DVFS 频点、电源域）在 R56p0 中的支持形态 | ✅ 已闭环（MTK 侧） | 寄存器映射与产品识别逻辑两版一致（`03_kbase_csf/05`）；DVFS/电源域由 MTK 平台层负责且**对 kbase 零反向依赖**（`04/01` §4），保留即可 |

> **更新后的闭环状态（2026-11-15 补充核验后）**：
> - 第 3 项：**源码判据**已判定"r56p0 只接受 0.4"，但**原厂固件实际值仍未实测**。因此该行状态是"**判据成立、证据待补**"，而不是"已闭环"。这是本轮从"✅"降为"⚠️"的唯一一处——因为首轮把"源码要求"当成了"固件实测"。
> - 第 4 项：契约层充分闭环，且真机补齐了实体构成；剩余风险是"DDK 是否遵守契约"，属可实测范畴（2 条 `grep` 即可推进）。
> - 第 5 项：**拆成"装载 / 代次 / 替换"三层**。装载层已由第三方内核的实机运行给出正面证据（KMI 未破坏）；代次层已判定仓库 `.ko` 与设备内核不同代，不能直接复用；替换层（r56p0 kbase 能否匹配 MTK 导出的 89 个符号）仍未验证。**这三层不可互相替代**。

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
| 2026-11-15 | **Stage 4 补充** | **真机证据整合与独立复核**（`04-fix`）：解析三份设备采集（inventory / file_metadata / elf_analysis），新增 `05_userspace_firmware/07_device_evidence.md`。①**固件 header 由"实测 0.3"降级为"E2 推理 + U4-01 UNKNOWN"**——三份采集在原理上取不到 offset 4/5；②Vulkan 存在性由 UNKNOWN 升级为**已闭合**（`vulkan.mali.so` 薄壳 + `ro.hardware.vulkan=mali` + VINTF 1.3）；③**撤回"gralloc/mapper/HWC 免疫"**——HWC/mapper 虽不链接 DDK，但 NEEDED `libged`（事件面）；因 `ged.ko` 不反向依赖 kbase，失效性质为**降级**而非崩溃；④`min()` 语义由"校验"更正为"**夹取**"；⑤README 基线更正为 **Android 17 / SDK 37 / kernel 6.6.143-android15**；⑥新增 U4-22/U4-23；⑦确认 `met_*` 三个模块本机不装载。UNKNOWN 由 21 项调整为 23 项（闭合 4 项 + 部分闭合 3 项） |
| 2026-11-15 | **Stage 4 来源审计** | **第三方 GKI 环境下的证据来源审计**（`stage4: audit … provenance`）：①确认设备运行**第三方 GKI 内核**（KernelSU 补丁，源码提交 `f9aa2fec`，基于 GKI `android15-6.6`），非原厂 boot；②建立 **A/B/C 三类**证据归属（厂商分区文件 / 第三方内核运行时 / 厂商内核模块）并重标 07/01/06；③核验安装范围：`block=boot` + `do.modules=0` + `do.systemless=0`，**只写 boot**，产物无 `.ko`/固件/`.so`；④判定设备 `.ko` 与仓库基线 `.ko` **不是同一构建**（vermagic 118 vs 143、`ged` 1,093,352 B vs 684,032 B），Stage 3 的 kCFI/CRC 常量须以设备构建重导；⑤定性第三方补丁影响（调度/调频/温控为间接，**不可能**改 GPU 驱动源码）；⑥新增 `08_kernel_provenance_audit.md` 与 U4-24…U4-27，UNKNOWN 23→27 项 |
