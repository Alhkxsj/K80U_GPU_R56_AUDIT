# K80U_GPU_R56_AUDIT

> **Redmi K80 至尊版（25060RK16C）· Arm Mali 5th Gen GPU 驱动 R56p0 移植可行性审计**

本仓库是一个**只读式技术审计工程**，用于评估将 Arm Mali 第五代（5th Gen / CSF 架构）GPU 驱动 **R56p0** 移植到本机 **Android 17 / 原厂 Linux 6.6.118 / MT6991** 平台的可行性。（运行时内核是第三方的 `6.6.143`，详见下表）仓库本身不是驱动工程，不承载可直接编译的生产代码。

---

## 0. 新会话从这里开始

> 本项目跨多轮 Agent 会话推进，**对话记忆不是可靠来源**。任何 Agent（或新读者）投入工作前，按下表顺序读取，即可恢复全部必要上下文。

| 顺序 | 文件 | 作用 | 何时必读 |
| ---: | --- | --- | --- |
| 1 | [`AGENTS.md`](AGENTS.md) | **强制执行规范**：上下文恢复、Git 检查、证据等级、九类禁止表述、仓库红线、交付格式 | **每次任务开始** |
| 2 | [`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md) | **项目当前状态**：阶段进度、Stage 4 的 27 项 UNKNOWN（闭合 5 / 部分闭合 5）、P0 明细、设备事实、技术债、任务队列、Stage 5 准入判定 | **每次任务开始** |
| 3 | [`docs/DECISION_LOG.md`](docs/DECISION_LOG.md) | **已形成的决策**：D-001 … D-015，含状态与再审议条件 | 涉及判断"能不能做/能不能改"时 |
| 4 | 本文件 §1–§7 | 审计标的、阶段路线图、关键问题闭环情况 | 需要全景时 |
| 5 | 目标目录的 `README.md` + `MANIFEST.md` | 该目录职责、文件清单、证据登记、修订记录 | 进入某目录前 |

**三条最容易犯的错**（已发生过的实例）：

1. 把**源码推断**写成**设备实测**（首轮"固件 header 实测 0.3"）；
2. 把**第三方 GKI 运行时**写成**原厂环境实测**（设备运行 KernelSU 补丁内核）；
3. 把**契约层兼容**写成**运行兼容**（原厂用户态目前只到 UAPI 契约层）。

> 以上三条对应的证据拆分与禁止清单，见 [`AGENTS.md`](AGENTS.md) §0.6；对应的实际案例，见 [`05_userspace_firmware/08_kernel_provenance_audit.md`](05_userspace_firmware/08_kernel_provenance_audit.md)。

---

## 1. 审计标的

| 项目 | 取值 | 来源 |
| --- | --- | --- |
| 设备型号 | Redmi K80 至尊版 | — |
| 机型代码 | 25060RK16C（代号 `dali`） | `ro.product.model` **[D]** |
| SoC 平台 | MediaTek **MT6991** | `ro.board.platform` **[D]** |
| GPU | Arm **Immortalis-G925 MC12**（5th Gen，CSF 固件驱动架构） | `compatible = arm,mali-valhall` **[D]** |
| 操作系统 | **Android 17（SDK 37）** · HyperOS `OS4.0.3.0.XONCNXM` | `ro.build.version.release/sdk`、`ro.build.fingerprint` **[D]** |
| **原厂内核（推定）** | **Linux 6.6.118-android15-8-g54a15cf3acba-4k**（由 18 个厂商 `.ko` 的 vermagic 反推；`android15` 是分支名，非 Android 版本） | `[E2]`，见 [`07`](05_userspace_firmware/07_device_evidence.md) §3.5 |
| **运行时内核**（第三方） | **Linux 6.6.143-android15-8-gf9aa2fec23c3-4k**（KernelSU + SUSFS 补丁；源码提交 `f9aa2fec23c3…`，基于 Google GKI `android15-6.6`） | `uname -a` **[D]** + `u:r:ksu:s0` **[D]** + 构建运行页 **[B]** |
| 目标驱动 | Arm Mali GPU DDK **R56p0**（kbase 内核驱动 + CSF firmware + 用户态 blobs） | `02_r56_source/` |

> **本表三处已按真机更正（2026-11-15）**：原写 "Android 16"、"Linux 6.6（GKI 形态）"、"机型代码 25060RK16C"（正确但缺代号）。Android 版本差异不是文字问题——它直接影响 `README` §7 第 5 项（KMI/vermagic）与 HyperOS 版本前提。
>
> **第四处更正（2026-11-15 21:40）**：设备运行的是**第三方 GKI 内核**，不是原厂 boot。`/vendor` 与 `/vendor_dlkm` 仍是厂商分区内容（安装包只写 `boot`）。因此本仓库所有"设备实测"必须按 **A 类（厂商文件）/ B 类（第三方内核运行时）/ C 类（厂商模块）** 分开读，见 [`05_userspace_firmware/08_kernel_provenance_audit.md`](05_userspace_firmware/08_kernel_provenance_audit.md)。
>
> 审计结论必须同时落在三条链路上：**内核驱动（kbase）**、**固件（CSF firmware）**、**用户态（GLES/Vulkan/gralloc/composer）**。任何单点替换都不构成"移植完成"。

---

## 2. 当前状态（截至 2026-11-15 22:50）

| 阶段 | 内容 | 状态 | 产物 / 证据 |
| --- | --- | --- | --- |
| Stage 0 | 目录骨架与审计说明 | ✅ 完成 | 本文件、各目录 `README.md` / `MANIFEST.md` |
| Stage 1 | 参考资料与基线采集 | ✅ 完成 | `01_original_baseline/`（r49p1 源码 581 文件）、`02_r56_source/`（R56p0 454 文件） |
| Stage 2 | R56p0 落盘 + kbase/CSF 差异审计 | ✅ 完成 | `03_kbase_csf/` 7 份产物，45 条差异（13 P0） |
| Stage 3 | MTK 平台层差异比对 | ✅ 完成 | `04_mtk_platform/` 7 份产物（保留 10 / 适配 2 / 重写 0） |
| Stage 3-REA | 二进制逆向补充审计（REA + Ghidra） | ✅ 完成 | `04_mtk_platform/REA_SUPPLEMENT.md` 等 8 份；12 个 `.ko` / 5,440 函数 |
| Stage 4 | 用户态与固件 ABI 核对 | 🔄 **报告已交付，收尾核验完成，证据未闭环** | `05_userspace_firmware/` 9 份（`01`–`09`）；**27 项 UNKNOWN，闭合 5 / 部分闭合 5** |
| Stage 5 | 方案设计与可行性结论 | ⏳ 未开始 | `06_porting_design/`、`final_report/` 仅目录骨架 |

> **Stage 4 的两种状态必须分开读**
>
> | 维度 | 状态 | 说明 |
> | --- | --- | --- |
> | **报告交付** | ✅ 完成 | 首轮 6 份（`efd8547`）+ 真机证据整合（`04-fix`，第 7 份）+ 来源审计（`stage4: audit … provenance`，第 8 份） |
> | **来源归属** | ✅ 完成 | A/B/C 三分：厂商文件 / 第三方内核运行时 / 厂商模块（`05/08`） |
> | **证据闭环** | ⚠️ **部分闭环** | 27 项 UNKNOWN / 闭合 **5** 项 / 部分闭合 3 项；**P0 由 4 项降为 3 项**（U4-01 已闭合） |
>
> **已完成（证据支持）**
> - UAPI 契约逐字段比对：ioctl 28/28 逐字相同、结构体 30/30 兼容、属性 ID 83/83 不变、能力表为 ≤1.30 保留旧语义
> - 真机基线实测：kbase `r49p1-03bet0 (UK version 1.30)`、**DDK `r49p1-03bet0`**、`/dev/mali0` 在、GPU 服务在跑（**运行于第三方 GKI 内核之上**）
> - **固件 header 实测 `0.3`**：前 16 字节 `6e 3a f1 c3 03 00 00 00 …`，magic 校验通过（**U4-01 闭合**）
> - 用户态构成实测：`libGLES_mali.so` 53,105,232 B / API 35 / NEEDED `libged`+`libgpud`；Vulkan 为 133,416 B 薄壳
> - 图形栈依赖实测：HWC/mapper 不链接 DDK，但 NEEDED `libged`；composer 3.3
>
> **硬结论（注意证据等级）**
> - **源码判据**：r56p0 的 CSF 加载器只接受 header `0.4`，用 `!=` 严格校验、无 fallback **[E1]**
> - **实测判据**：原厂固件 header = **`0.3`**（`offset 4 = 0x03`）**[D·A]** → **组合 B（只换内核）被实测否决**，不再是"逻辑成立、证据待确认"
> - **原厂三方配套**：固件 0.3 + kbase `r49p1-03bet0` + DDK `r49p1-03bet0`，代次是**整体**属性 **[D·A]+[D·C]**
> - **原厂用户态在契约层可保留**（UAPI 全兼容 + `min()` 夹取），但必须**整套**保留，实现层行为未验证
> - **来源判据**：设备 `.ko` 与仓库基线 `.ko` 不是同一构建——两者同为 `6.6.118` 分支，但提交不同（`g54a15cf3acba` vs `g57e634f35c1b`，分属 OS4.0.3.0 与 OS3.0.305.0）；**14/15 个模块的字节数与关键节大小完全相同，只有 kbase 实质不同** → 二进制级常量**按模块分层**：kbase 必须重导，其余可抽样验证后沿用 **[D·A]+[E1]**
> - **环境判据（2026-11-16 更正）**：`CONFIG_MODVERSIONS` 下内核**原生忽略** vermagic 的 release 串（`same_magic()`，v6.6 `version.c:88-96`），所以"串不符仍装载"**不是**异常、**不需要**补丁；它只证明被 import 的符号 CRC 一致，**不能**推出与 R56 兼容。真正会掩盖 CRC 错误的是构建开关 `allow_version_mismatch`（默认关闭）。见 [`09`](05_userspace_firmware/09_stage4_closure.md) §2–§3
>
> **仍未闭环的原因**：缺运行时证据（dmesg / strace / 故障注入）与两份商业资产（R56 固件、R56 DDK）。剩余 P0 为 U4-04（padding / props 行为）、U4-10、U4-12；**U4-04 的风险已上调为组合 C 的单点致命项**（padding 强制校验 15 处，覆盖 CS 主链路），**U4-12 属阻断**（交付包内 0 个固件）。收尾核验见 [`09`](05_userspace_firmware/09_stage4_closure.md)。详见 [`05_userspace_firmware/06_abi_compatibility_matrix.md`](05_userspace_firmware/06_abi_compatibility_matrix.md) §7、[`05_userspace_firmware/07_device_evidence.md`](05_userspace_firmware/07_device_evidence.md) §10 与 [`05_userspace_firmware/08_kernel_provenance_audit.md`](05_userspace_firmware/08_kernel_provenance_audit.md) §6。

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
| `docs/` | **长期上下文管理**：`PROJECT_STATE.md`（项目状态）、`DECISION_LOG.md`（决策日志）；与根 `AGENTS.md`（执行规范）共同构成 Agent 恢复入口 | 治理产物 |

**边界原则**：原始证据（`01`、`02`）与分析结论（`03`–`06`）物理隔离，任何结论必须能回溯到 `01`/`02`/`00` 中的具体文件或版本号。治理层（`AGENTS.md`、`docs/`）不承载技术结论，只承载**流程**与**状态**；技术结论永远在 `03`–`06`。

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
| Stage 4 | 用户态与固件 ABI 核对 | `05` | 🔄 **报告已交付 / 来源已归属 / 收尾核验完成**（27 项 UNKNOWN，闭合 5、部分闭合 5；P0 3 项，其中 U4-12 为阻断） |
| Stage 5 | 方案设计与可行性结论 | `06` `final_report` | ⏳ 未开始（前置条件：U4-04 行为面 / U4-12 / U4-24；**可设计、不可定论**） |

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
| 3 | CSF firmware 的 `fw version` 与 kbase `kernel ABI` 匹配窗口 | ✅ **实测判定** | 两版加载器逐行对照：`FIRMWARE_HEADER_VERSION_MINOR` **3 → 4**，`!=` 严格相等、无兼容分支（`05/02` §3.1）。**原厂固件 header 实测 `0.3`**（`6e 3a f1 c3 03 00 00 00`，[D·A]，`05/02` §3.0.5）→ r56p0 必拒 |
| 4 | 用户态 blobs 是否与 R56p0 kbase 的 ioctl / uk ABI 对齐 | ⚠️ **契约层已闭环，实现层未验证** | ioctl 28/28 逐字相同、结构体 30/30 兼容、属性 ID 83/83 不变、`min()` 夹取保证有效版本 ≤1.30（`05/03`）。真机已确认 `libGLES_mali.so` 存在（53 MB / API 35）及其对 `libged`/`libgpud` 的硬依赖；**DDK 自称版本与行为仍为 UNKNOWN**（U4-04） |
| 5 | Android 17 / GKI 6.6.x 的 `vermagic` / `MODULE_SIG` / KMI 是否允许替换 GPU 模块 | ⚠️ **分层：装载可行已证，替换未证** | ①**装载**：厂商 15 个 GPU 相关模块（含 `ged`）已在**重编的** `6.6.143` GKI 内核上装载（`lsmod` + `/dev/mali0` + 服务 pid）**[D·B]**+**[D·C]**；②**为何能装载（2026-11-16 更正）**：不是靠补丁——`CONFIG_MODVERSIONS` 下 `same_magic()` 只比较第一个空格之后的 flags 段（`SMP preempt mod_unload modversions aarch64`），两侧**逐字符相同**，故合法装载 **[E1]**；③**代次**：仓库基线 15 个 `.ko` 为 `6.6.118-…-g57e634f35c1b`（OS3.0.305.0），14/15 个与设备结构完全一致、kbase 实质不同 **[D·A]**+**[E1]**；④**替换**：r56p0 kbase 需匹配 MTK 模块导出的 89 个符号及其 CRC，未验证 **[U]**（U4-24b/U4-25b） |
| 6 | G925 MC12 的配置项（core mask、DVFS 频点、电源域）在 R56p0 中的支持形态 | ✅ 已闭环（MTK 侧） | 寄存器映射与产品识别逻辑两版一致（`03_kbase_csf/05`）；DVFS/电源域由 MTK 平台层负责且**对 kbase 零反向依赖**（`04/01` §4），保留即可 |

> **更新后的闭环状态（2026-11-16 模块身份审计后）**：
> - 第 3 项：**已闭环**。固件 header 实测 `6e 3a f1 c3 03 00 00 00` → `0.3`，r56p0 期望 `0.4`，`!=` 严格无 fallback → **组合 B 实测否决** **[D·A]**+**[E1]**。
> - 第 4 项：契约层充分闭环；真机补齐了实体构成；DDK release 串 `r49p1-03bet0` 已取，padding / props 行为仍为 [U]。
> - 第 5 项：**本轮（收尾核验）再次改写**。上一版写"装载成功含补丁因素——因为该内核绕过了 vermagic 校验"，该判断**已撤回**：那是 6.6 的原生语义，不是补丁。改为"合法装载，证明符号 CRC 一致，但不证明与 R56 兼容"。详见 [`08`](05_userspace_firmware/08_kernel_provenance_audit.md) §3.7.4 与 [`09`](05_userspace_firmware/09_stage4_closure.md) §2。
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
| 2026-11-15 | **Stage 4 P0 补采工具** | `stage4: add minimal P0 device evidence collector`：新增 `05_userspace_firmware/tools/collect_stage4_p0.sh`（POSIX sh、只读、无 adb、工具自检、失败报因）与执行指南。**仅为采集准备，未改任何结论** |
| 2026-11-15 | **Stage 4 P0 补采整合** | **U4-01 闭合 / U4-04 推进**（`stage4: close U4-01 with firmware header bytes, advance U4-04`）：用户以 aShell You 在手机端执行脚本并回传纯文本。①**固件 header 实测 `0.3`**：`6e 3a f1 c3 03 00 00 00`，magic OK、`offset 4 = 0x03`、`offset 5 = 0x00` → U4-01 由 [U] 升为 **[D·A]**，组合 B 由"推理否决"升为"**实测否决**"；②**DDK 内含 `r49p1-03bet0`**，与 kbase `MODULE_VERSION` **同串** → 原厂"固件+kbase+DDK"三方配套（新决策 D-017）；③`UK version N.N` 字面量 `NOT_FOUND`，1.30 由 release 映射而非库内自报；④记录两条**禁止表述**：`version_hash = 0x030A0000` ≠ GLB 3.10.0、"DDK 实测宣称 1.30"；⑤计数 **27/4/3/4 → 27/5/3/3**；新增 D-016，D-008 转为生效。**未上传任何二进制** |
| 2026-11-15 | **U4-24 采集工具 + 口径更正** | **设备 GPU 模块身份核验准备**（`stage4: add GPU module identity audit`）：①新增只读采集脚本 `05/tools/collect_gpu_module_identity.sh`（手机端，无 adb）与执行指南 `README_gpu_module_identity.md`——现有三份采集只有 `lsmod`，**没有**路径 / 文件大小 / SHA256 / vermagic，故 U4-24 无法离线闭合；②`05/08` 新增 **§3.6**：判定矩阵、模块集合映射、**kCFI（类型型 oracle）vs `__versions` CRC（数值型 oracle）的重导策略**、U4-24 拆 a/b；③**更正三处口径**：`lsmod` 的 size 是 `core_layout.size`（内存、页对齐）而非文件大小（上一行"`ged` 1,093,352 B vs 684,032 B"不可相减）；设备多出 **`mtk_ghpm`** 而仓库无此文件（集合不对称）；`met_*`「未装载」受筛选口径限制；④**计数不变 27/5/3/3，U4-24 仍未闭合**；新增 D-018 / D-019 |
| 2026-11-15 | **治理（本项目基础设施）** | **建立长期上下文管理**（`docs: establish persistent agent context protocol`）：新增根 [`AGENTS.md`](AGENTS.md)（全局执行协议：上下文恢复 / Git 检查 / 历史核对 / 证据等级 / 九类禁止表述 / 红线 / 自检清单）、[`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md)（阶段状态、Stage 4 的 27/4/3/4 计数与 P0 明细、设备事实、技术债、任务队列、Stage 5 准入）、[`docs/DECISION_LOG.md`](docs/DECISION_LOG.md)（D-001…D-015）；本文件新增 §0 恢复入口与 `docs/` 目录职责。**目的：让项目状态不再依赖某一次 Agent 对话的记忆。** 同轮修正 5 处 `Android 16` 过时表述（`00_reference/README.md`、`final_report/README.md`、`06_porting_design/README.md` 直接更正为 17；`SOURCE_ACQUISITION.md`、`03_kbase_csf/06_blocking_issues.md` 保留原文并加更正注），另 `03_kbase_csf/01_uapi_abi_diff.md` 一处补"其发布时的"限定；`00_reference/third_party/` 外部文档原文不改（D-014） |
| 2026-11-16 | **U4-24 实测整合（a 闭合 / b 开放）** | `stage4: close U4-24a with device module identity`：用户执行模块身份脚本并回传纯文本。①**18 个 `.ko` 身份全取**：路径 / 大小 / SHA256 / vermagic / `srcversion` / sysfs Build ID；vermagic 全部 `6.6.118-android15-8-**g54a15cf3acba**-4k`；②**推翻一条项目级事实**——`6.6.143` 是**第三方运行内核**，原厂内核应为 `6.6.118-g54a15cf3acba`（三层版本，新决策 D-020）；③**14/15 个模块与仓库基线（OS3.0.305.0 / `g57e634f35c1b`）字节数及 `.text`/`__versions` 节大小完全相同**，`mali_mgm`/`mali_prot_alloc` 的 `srcversion` 逐字符相同，**仅 kbase 实质不同**（+17,640 B）→ **REA 重导范围收窄至 kbase**（D-022）；④**发现运行内核绕过 vermagic 校验**（15 个串不符仍装载）→ "装载成功"不构成 ABI 证据（D-021）；⑤**"`ged` 差 409 KB"连方向都错**：两侧文件同为 1,093,352 B；⑥设备 GPU 相关文件 **18 个**（仓库 15 个，缺 `mtk_ghpm` / `mtk_cg_peak_power_throttling` / `mtk_smmu_qos`）；⑦修脚本 v1.1 的 `ged$` 正则缺陷。**计数 27/5/3/3 → 27/5/4/3**。**注**：上文 2026-11-15 两条中的"vermagic 118 vs 143"与"684,032 B"表述已被本轮推翻，保留原文以留痕（D-012）|
| 2026-11-16 | **Stage 4 收尾核验** | `stage4: close remaining audit items with source-level verification`：新增 [`05/09_stage4_closure.md`](05_userspace_firmware/09_stage4_closure.md)。**四处更正**：①**撤回"运行内核绕过 `same_magic()`"**——`CONFIG_MODVERSIONS` 下 release 串本就不参与比较（v6.6 `version.c:88-96`），装载合法、无需补丁；②**找出真正的绕过开关** `bypass-kernel`（改 `bad_version` 为 `return 1`，默认关闭；2026-08-29→10-30 门控 `== 'true'` 对布尔输入恒失效），U4-25 拆 a/b/c；③**`uname -v` 的日期不是构建时间**（由 `os_patch_level` 派生为 `${YM}-05 04:20:00 UTC`，实测串逐字段吻合）；④**padding 强制校验实为 15 处**（原文"两处"只读了前 20 个定义），覆盖 `CS_QUEUE_REGISTER`/`CS_QUEUE_GROUP_CREATE*` → R-C2 由"tiler 失效"上调为"GPU 不可用"。另核：R56 交付包 23 条目 **0 个固件**（U4-12 属商业阻断）、`/proc/modules` taint 无 `F`（未强制装载）。**计数 27/5/4/3 → 27/5/5/3**；D-021 改写，新增 D-023/D-024/D-025 |
