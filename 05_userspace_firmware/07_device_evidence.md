# 07 — 真机证据登记（Stage 4 补充核验）

> **本文件的定位**：Stage 4 首轮（`efd8547`）的六份报告建立在"仓库内零用户态实体"的前提上，因此大量结论止步于**源码契约层**。本文件登记 2026-11-15 20:56 收到的三份真机采集结果，把"契约层"与"实体层"接上，并**逐条标出哪些原结论被证实、哪些被推翻、哪些仍不成立**。
>
> **⚠️ 来源归属前置（2026-11-15 21:40 补记，必须与正文同读）**
>
> 采集发生时，设备运行的是**第三方 GKI 内核**（KernelSU 补丁，内核源码提交 `f9aa2fec23c3…`，基于 Google GKI `android15-6.6` / sublevel 143），**不是原厂 boot**。因此本文件的三类证据来源不同：
>
> | 类别 | 内容 | 来源 | 标签 |
> | --- | --- | --- | --- |
> | **A** | `/vendor` 下 GPU 用户态库、`mali_csffw.bin`、配置 | **厂商分区**（本次安装只写 `boot`，未改 `vendor`） | `[D·A]` |
> | **B** | `uname`、`lsmod`、`/sys/module`、`/dev/mali0`、服务与属性 | **第三方内核运行时** | `[D·B]` |
> | **C** | Kbase / MGM / PMA / GED / GPUFreq / GPUEB 等 `.ko` 文件 | **厂商模块**，装载于第三方内核之上 | `[D·C]` |
>
> **本文正文中凡写"真机实测"者，均须按上表读作对应的 A/B/C 类**；不得把 B 类读成"原厂内核实测"。完整审计见 [`08_kernel_provenance_audit.md`](08_kernel_provenance_audit.md)。
>
> **证据分级**（本阶段统一口径）：
>
> | 级别 | 含义 | 可反驳性 |
> | --- | --- | --- |
> | **[D]** | **设备实测**：采集输出中可直接读到的值（路径、大小、哈希、ELF 动态段、getprop、`lsmod`）。细分 `[D·A]` 厂商分区文件 / `[D·B]` 第三方内核运行时 / `[D·C]` 厂商模块装载状态 | 不可反驳，只能被"采集脚本写错"推翻 |
> | **[E1]** | 源码 / 二进制直接证据：仓库内文件的行号级内容 | 可被版本误认推翻 |
> | **[E2]** | 交叉推导：由两条以上 [D]/[E1] 推出，中间有一步推理 | 可被新证据推翻 |
> | **[E3]** | 惯例推断：基于 AOSP/Android 通用实现 | 最弱，仅作方向 |
> | **[U]** | UNKNOWN：无证据，或证据不足以定值 | — |
> | **[B]** | **构建记录**：公开可核验的 CI 运行页 / 产物清单 / 构建模板源码（**不等于设备实测**） | 只能被"看错行"推翻 |
> | **[P]** | **用户声明**：任务书或对话给出、本次无法独立复核的参数 | 可被构建记录推翻 |
>
> **三态标注法**（贯穿全部八份文件）：每条结论必须落在这三档之一——
> `已实测`（[D]，含 A/B/C 归属）/ `静态分析`（[E1]/[E2]）/ `尚未验证`（[E3]/[U]）。
> 禁止把"静态分析"写成"已实测"，把"报告已提交"写成"证据已闭环"，把"第三方内核上的实测"写成"原厂环境实测"。

---

## 0. 本次补充核验做了什么、不做什么

| 项 | 内容 |
| --- | --- |
| 做 | 解析三份真机采集输出；把可公开元数据（路径/大小/SHA256/Build ID/动态段/服务状态）整合进 `01`–`06`；复核首轮的五处过度推断；修正根 `README.md` |
| 不做 | 不重新执行 Stage 4；不开始 Stage 5；不编译；不替换任何固件或系统库；不上传任何 `.so` / `.bin` / `.ko` 实体；不要求用户重跑已有采集项目 |
| 唯一例外 | 若存在**可被 8 字节读数直接闭合**的 P0 缺口，提出最小只读命令并等待用户确认（见 §10）。**该例外已于 2026-11-15 23:20 执行完毕**：用户运行 `tools/collect_stage4_p0.sh` 并回传纯文本，未上传任何二进制 |

---

## 1. 输入登记（三份基线采集 + 一份 P0 补采）

### 1.0 三份基线采集（2026-11-15 20:56 收到）

| 文件 | 字节 | 行数 | SHA256（本次收到的副本） | 采集时间（文件内） |
| --- | ---: | ---: | --- | --- |
| `stage4_inventory.txt` | 85,684 | 1,732 | `d897ed47…1729a6` | `Sun Nov 15 19:54:06 CST 2026` |
| `stage4_file_metadata.txt` | 6,055 | 120 | `c8a856b5…e5f59dc` | 与上同批 |
| `stage4_elf_analysis.txt` | 79,123 | 1,244 | `9f95078f…8b3b3e33` | `Sun Nov 15 20:02:40 CST 2026` |

> 三份文件**均在设备侧生成**（`OUTPUT: /sdcard/GPU_AUDIT_STAGE4/…`），经本地副本转交，**未进入本仓库**。本仓库只登记其**哈希与解析结论**，不登记其正文。

### 1.1 P0 补采（2026-11-15 23:20 收到，**闭合 U4-01**）

| 文件 | 采集时间 | 生成方式 | 内容 |
| --- | --- | --- | --- |
| `stage4_p0_20261115_232021.txt` | `Sun Nov 15 23:20:21 CST 2026` | 设备端执行 `05_userspace_firmware/tools/collect_stage4_p0.sh`（POSIX sh，只读，无 adb） | 固件前 16 字节 + DDK 版本串 |

| 项 | 值 |
| --- | --- |
| 设备 / 代号 | `25060RK16C` / `dali` |
| Android / 内核 | 17 (SDK 37) / `6.6.143-android15-8-gf9aa2fec23c3-4k` |
| SELinux / UID | `u:r:ksu:s0` / 0 |
| 工具可用性 | `od` YES · `xxd` YES · `strings` YES · `readelf` YES · **`hexdump` NO** |
| 输出位置 | `/data/local/tmp/gpu_audit_p0/stage4_p0_20261115_232021.txt`（设备本地） |
| 回传形态 | **纯文本**；未复制、未 pull 任何 `.bin` / `.so` |

> 该文件的作用只有一个：**把 U4-01 从推理变为读数**。它在 §1.1 是登记项，在 §4.5 是证据正文。

### 1.2 三份基线采集各自的能力边界

| 文件 | 能回答 | 不能回答 |
| --- | --- | --- |
| `inventory` | 系统版本、模块清单、目录枚举、VINTF 清单名、DT 节点、getprop、`/dev` 节点 | 任何文件内容；任何字节级取值 |
| `file_metadata` | 22 个关键对象的**大小 / 权限 / SHA256** | 文件内部结构 |
| `elf_analysis` | 9 个 ELF 的**头 / 动态段 / Build ID / 部分符号**；固件的**可打印字符串** | 固件头字节（offset 0–19）；完整符号表；`.text` 反汇编 |

**关键限制（只适用于 §1.0 的三份基线，**不适用于 §1.1 的 P0 补采**）**：`strings` 输出的是可打印字符串，**不含二进制头字段**。固件的 `version_minor`/`version_major` 位于 offset 4 / 5，是原始字节，**不可能出现在任何一份 `strings` 结果里**。

> 这条限制曾决定 §4 的结论（"只能推理，不能读数"）。**P0 补采改用 `od -An -tx1 -N 8` 直接读字节，因此不受此限制**——§4.5 给出读数。这里保留该段，是因为它解释了"为什么第一轮不补采就一定拿不到"，是工具选型决定证据边界的一个标准案例。

---

## 2. 设备基线（[D] 实测）

| 项 | 实测值 | 来源 |
| --- | --- | --- |
| 机型代码 | `25060RK16C` | 采集 §1 第 1 行 |
| 代号 | `dali` | 采集 §1 第 2 行 |
| SoC | `mt6991`（第 3、4 行同值，对应 platform 与 hardware 两个字段） | 采集 §1 第 3–4 行 |
| **Android 版本** | **17** | 采集 §1 第 5 行 |
| **SDK** | **37** | 采集 §1 第 6 行 |
| 构建指纹 | `Redmi/dali/dali:17/CP2A.260605.016/OS4.0.3.0.XONCNXM:user/release-keys` | 采集 §1 第 7 行 |
| 系统版本名 | HyperOS `OS4.0.3.0.XONCNXM` | 同上 |
| 内核（**第三方 GKI**） | `6.6.143-android15-8-gf9aa2fec23c3-4k`，`#1 SMP PREEMPT Mon Oct 5 04:20:00 UTC 2026 aarch64` | `uname -a` |
| 内核来源判定 | **第三方构建**：SELinux 域 `u:r:ksu:s0`（KernelSU 补丁内核） | 采集文件 `id` 输出 |
| 内核基线 | Google GKI `android15-6.6`，源码提交 `f9aa2fec23c3…`，sublevel 143，patch `2026-10` | `[B]` 构建运行页 + `[D·B]` `uname` 双向吻合 |
| GPU 节点 | `/soc/mali@48000000`，`compatible = mediatek,mali` + `arm,mali-valhall` | `uevent` |
| 设备节点 | `/dev/mali0`，`crw-rw-rw- system graphics 10:282` | `ls -l /dev` |

> 说明：`inventory` 的 §1 只打印取值、不打印键名。上表的键名是按 Android 标准属性顺序对应，取值本身是原文照录；若需键名级确认，`getprop` 的完整输出可直接复核。
>
> **四处必须纠正的旧表述**：
> 1. 根 `README.md` 的 **"Android 16"已过时**——真机为 **Android 17 / SDK 37**。
> 2. 内核串里的 `android15` 是 **GKI 分支名**（`android15-8`），**不是** Android 版本；`6.6.143` 才是内核版本。旧文写作"Linux 6.6（GKI 形态）"方向正确但不够精确。
> 3. `compatible` 为 `arm,mali-valhall`（Valhall 家族字符串），与 Immortalis-G925 属同一 `regmap` 世代，和 `03_kbase_csf/05` 的 `kbase_regmap_v12_init` 判定一致 **[E2]**。
> 4. **内核不是原厂的**。`uname` 串与原厂 boot 完全相同（两者都基于同一 GKI 提交 `f9aa2fec`），**因此 `uname` 无法区分**；决定性判据是 `u:r:ksu:s0`——该 SELinux 域只在 KernelSU 补丁内核上存在。凡本文写"内核侧"者，一律指**第三方内核**。

---

## 3. 运行观测：模块与版本（[D·B] + [D·C]）

> **本节是本文件来源混淆最严重的地方，先立规则**：
>
> - **模块文件**属 **C 类**（厂商 `/vendor_dlkm` 提供）；
> - **装载这件事**属 **B 类**（发生在第三方内核上）；
> - 因此"已装载"只能写成"**厂商模块在第三方内核上装载成功**"，不能写成"原厂内核已装载原厂模块"。
>
> 第三节的结论全部受此限定；由于 `ged.ko` 等模块**未反向依赖 kbase**（TASK 03 定理），装载成功反映的是 **GKI KMI 兼容**，不是"原厂内核行为"。

### 3.1 版本串——首轮最重要的补强

```
/sys/module/mali_kbase_mt6991_r49/version  →  r49p1-03bet0 (UK version 1.30)
```

源码依据（r49p1）：

```c
/* mali_kbase_core_linux.c:6800 */
MODULE_VERSION(MALI_RELEASE_NAME " (UK version " __stringify(BASE_UK_VERSION_MAJOR) "."
               __stringify(BASE_UK_VERSION_MINOR) ")");
```

| 判定 | 内容 | 等级 |
| --- | --- | --- |
| 运行中的 kbase 版本 | `r49p1-03bet0` | **[D·C]** |
| 运行中的 kbase UK ABI | **1.30（major 1 / minor 30）** | **[D·C]** |
| 与仓库基线**源码标签**一致 | 与 `01_original_baseline` 的 `MALI_RELEASE_NAME` 逐字符一致 | **[D·C]**+[E1] |
| 与仓库基线**二进制**一致 | **否**——vermagic `6.6.118-…` ≠ 运行内核 `6.6.143-…`，见 §3.4 | **[E1]**+[E2] |

> 这是 Stage 4 首轮**拿不到、只能推测**的东西：首轮说"原厂 DDK 必然宣称 1.30"是源码推理 **[E1]**，而现在有设备侧字符串直接确认**内核**就是 1.30。
>
> **⚠️ 注意区分（本轮已补齐另一侧）**：本节确认的是**内核宣称值**，不是 DDK 宣称值。DDK 侧已在 §5.4 由 P0 补采闭合——`libGLES_mali.so` 内含同一 release 串 `r49p1-03bet0`。**两侧同串**，这才是"原厂配套"的完整证据。
>
> **但版本串只能证明"源码标签相同"，不能证明"构建相同"**。`MODULE_VERSION` 是编译期宏展开，同一个 tag 换一个内核 sublevel 重编，串不变、二进制全变。§3.4 给出反证。

### 3.2 MTK 平台层模块：15 个 `.ko` 的实际装载情况

`01_original_baseline/kernel_ref_mt6991/vendor_dlkm/` 共 15 个 `.ko`，真机 `lsmod` 对照：

| 模块 | 真机状态 | 备注 |
| --- | :---: | --- |
| `mali_kbase_mt6991_r49` | ✅ 已装载 | refcount 77 |
| `mali_mgm_mt6991_r49` | ✅ | |
| `mali_prot_alloc_mt6991_r49` | ✅ | PMA |
| `ged` | ✅ | 设备侧 `lsmod` 报 **684,032 B** 运行时内存（**不是文件大小**，仓库文件为 **1,093,352 B**；口径差异见 `08` §3.6.2）；被 5 个模块引用 |
| `mtk_gpufreq_mt6991` | ✅ | |
| `mtk_gpufreq_wrapper` | ✅ | 被 9 个模块引用（含 kbase） |
| `mtk_gpueb` | ✅ | 被 10 个模块引用（含 kbase） |
| `mtk_gpu_hal` | ✅ | 被 8 个模块引用（含 kbase） |
| `mtk_gpu_pdma_mt6991` | ✅ | 被 1 个模块引用（kbase） |
| `mtk_gpu_qos` | ✅ | 被 1 个模块引用（ged） |
| `mtk_gpu_iommu_mt6991` | ✅ | refcount 0 |
| `mtk_gpu_power_throttling` | ✅ | refcount 0 |
| `met_gpu_api` | ❌ **未装载** | MET 追踪，本机未启用 |
| `met_gpu_adv_api` | ❌ **未装载** | 同上 |
| `met_gpueb_api` | ❌ **未装载** | 同上 |

**新增结论（TASK 03 未能观察到）**：三个 `met_*` 模块**在本机根本不装载**。因此 `04_mtk_platform/06_platform_retention_matrix.md` 中与 MET 相关的适配项，在本机型上**不构成风险面**；反之，任何"必须同步升级 MET"的担心可以撤回 **[D]**。

> **两条口径补正（2026-11-15 U4-24 准备轮）**：
>
> 1. **"未装载"的观测口径**：上表依据的是 `lsmod | grep -iE "mali|gpu|ged|gpueb|gpufreq"` 的**过滤输出**。`met_gpu_*` 含 `gpu`，会被该模式命中；未出现即"未装载"。严格说是"在该筛选口径下未见"，全量 `/proc/modules` 采集可把它升级为"确认"（见 `08` §2.4 注 2）。
> 2. **集合不对称**：设备除上表 12 个已装载模块外，还有 **`mtk_ghpm`**（被 `mtk_gpufreq_wrapper` 引用），而仓库 `vendor_dlkm/` **没有这个文件**。故"仓库 15 个 = 设备 15 个"不成立，详见 `08` §3.6.3。

### 3.3 引用方向：设备侧交叉印证 TASK 03 的"89 处正向引用"

`lsmod` 的 used-by 列显示 `mali_kbase_mt6991_r49` 出现在以下模块的依赖列表中：`ged`、`mtk_gpufreq_wrapper`、`mtk_gpueb`、`mtk_gpu_hal`、`mtk_gpu_pdma_mt6991`。

> 这与 TASK 03 用 `__versions`/`.rela` 推出的 **kbase → MTK 正向引用 89 处（ged 53 / gpufreq_wrapper 16 / gpu_hal 13 / gpueb 6 / pdma 1）** 在**模块集合层面**完全吻合 **[D]**+[E1]。
>
> 注意：`lsmod` 只能证明"谁引用谁"这一层，**不能**给出符号粒度，也不能反驳"MTK 对 kbase 零反向依赖"定理（该定理的依据是 `__ksymtab` 与 `UND` 符号，仍以 `04_mtk_platform/01` 为准）。

### 3.4 设备 `.ko` 与仓库 `.ko` **不是同一份二进制**（本轮新增）

| 判据 | 仓库基线 15 个 `.ko` | 设备运行内核 / 模块 | 结论 |
| --- | --- | --- | --- |
| vermagic（**决定性**） | `6.6.118-android15-8-g57e634f35c1b-4k SMP preempt mod_unload modversions aarch64` | 内核 `6.6.143-android15-8-gf9aa2fec23c3-4k` | **不相等 → 基线 `.ko` 无法装载到当前内核** |
| `ged` 尺寸（**辅助，口径不同**） | 文件 **1,093,352 B** | `lsmod` 运行时 **684,032 B**（`core_layout.size`，167 页） | 方向一致（设备侧更小），但**两者不可相减**，见 `08` §3.6.2 |
| `modversions` | 开启（vermagic 含 `modversions`） | 开启 | `.ko` 与内核版本串必须逐字符相等 |
| 构建时间 | — | `Mon Oct 5 04:20:00 UTC 2026` | **不可作判据**：GKI 可复现构建常固定 `KBUILD_BUILD_TIMESTAMP` |

**推论（三条，逐条可反驳）**：

1. 设备上的 GPU `.ko` 是**另一次构建**（`6.6.143` 世代），不是仓库归档的 `6.6.118` 批次。
2. 两者共享的只有**源码标签** `r49p1-03bet0` 与 **UK ABI 1.30**。
3. Stage 3 / 03-REA 的**二进制级数字**（kCFI 类型哈希、`__versions` CRC、模块体积）来自 `6.6.118` 批次，**不能直接套用到设备构建**；源码级结论（表项数、成员顺序、符号计数、依赖方向）不受影响。

> 反向可反驳条件：若设备 `.ko` 的 `modinfo vermagic` 实测为 `6.6.118-…`，则本条推翻（但那意味着 `modversions` 校验被绕过，与 Android init 的加载方式不符）。该实测属 U4-24。

---

## 4. CSF 固件实体：大小、哈希、**头字节（已取得）**

### 4.1 实测元数据（[D]）

| 项 | 值 |
| --- | --- |
| 路径 | `/vendor/firmware/mali_csffw.bin` |
| 大小 | **307,200 B**（= 300 KiB 整） |
| 权限 | `-rw-r--r-- root:root 644` |
| SHA256 | `334fb67648f2ec43f57b24a8972e97b7d54919783d398a88327d7c136fa7de4a` |
| 唯一性 | `/vendor/firmware/` 下**仅此一个** `mali_csffw*`；`/vendor/firmware_mnt`、`/vendor/etc/firmware` **不存在** |
| **前 16 字节**（2026-11-15 23:20 补采） | **`6e 3a f1 c3 03 00 00 00 00 00 0a 03 00 00 00 00`** |
| **header 版本** | **`0.3`**（`offset 4 = 0x03` = minor，`offset 5 = 0x00` = major） |

### 4.2 为什么"大小 + 哈希"不能推出 header 版本

| 假想判据 | 为什么无效 |
| --- | --- |
| 按大小推断（300 KiB 整） | 加载器只读到 `entry_end_offset`（offset 0x10），**尾部填充不参与解析**。整 KiB 对齐是打包惯例，与版本无关 **[E2]** |
| 按哈希比对 Arm 发布包 | R56p0 的 `mali_csffw.bin` **未随内核源码包交付**，仓库内无对照哈希 **[D]** |
| 按 strings 推断 | `strings` 只输出可打印字节；`version_minor` 是 offset 4 的**单字节 0x03/0x04**，非可打印串，**不可能出现** **[E1]** |

### 4.3 strings 提供了什么（有价值，但不是版本）

固件内可打印串含完整 CSF 时间线枚举与启动状态机：

```
CSFFW_TL_ITER_vb421b363699b1165c0a40c789b8a54f822bece74     ← 唯一构建标识（v + 40 hex）
CSFFW_TL_FW_NORMAL_MODE / _PROTECTED_MODE / _SLEEPING
CSFFW_CSI_STOPPED / _SUSPENDING / _BLOCKED_PROTM_PEND / _FAULT
CSFFW_TL_CSG_ENABLED / _DISABLED / _PROTM_SUSPENDING
BOOT WARM / BOOT WARM AFTER PMODE
MCU_GPU_IRQ_MASK / GPU_FEATURES_LO / MCU_GPU_FAULTADDRESS_LO
Firmware hang detected at PC 0x%08x        （"CSFFW Oops!" 路径）
```

| 可读出 | 不可读出 |
| --- | --- |
| 固件是**完整的 CSF 调度器**（含 CSG/CS/ITER 状态机、保护模式、warm boot、hang 检测） | header 版本（0.3 / 0.4） |
| 存在**构建标识** `b421b363…`，可作未来比对锚点 | GLB 接口运行时版本（需运行后读共享内存） |
| 具备 `PROTECTED_MODE`，与 DRM/SVP 路径的存在性自洽 | core mask / 是否匹配 G925 MC12（U4-12） |

> 该构建标识 `vb421b363…` 是本次唯一新增的**可追踪锚点**：若日后取得 Arm R56p0 固件，可直接比对它是同一分支的不同 commit，还是完全不同的代码线。

### 4.4 结论：U4-01 **已闭合（[D·A]）**

- **字节已实测**：`6e 3a f1 c3 03 00 00 00` → magic OK、`minor = 0x03`、`major = 0x00` → **header 0.3**。
- 该值**同时推翻**"仍需保留 UNKNOWN"的旧状态，并**坐实** r49p1 判据、**否决** r56p0 判据。
- 旧推理链（`02` §3.0.1 的八环）已归档为方法学示例，不再作为证据来源。

### 4.5 实测记录与解码（[D·A]）

**原始输出片段**（来自 `stage4_p0_20261115_232021.txt`）：

```
--- [U4-01] CSF firmware header (first 8 bytes) ---
PATH: /vendor/firmware/mali_csffw.bin
SIZE:   307200 bytes
PERM:   644 root:root
HEADER_HEX: 6e 3a f1 c3 03 00 00 00
MAGIC:      OK (0xC3F13A6E little-endian)
OFFSET4_MINOR: 0x03
OFFSET5_MAJOR: 0x00
FIRMWARE_HEADER: 0.3
SOURCE_CHECK:   matches r49p1 requirement (0.3); r56p0 requires 0.4
EXTRA_8_15:  00 00 0a 03 00 00 00 00
```

**字段解码**（字段定义见 `02` §2，来自两版逐字相同的解析代码 [E1]）：

| 偏移 | 字节 | 字段 | 值 | 判定 |
| ---: | --- | --- | --- | --- |
| 0x00–0x03 | `6e 3a f1 c3` | `magic` | `0xC3F13A6E` | ✅ 一致 |
| 0x04 | `03` | `version_minor` | 3 | ✅ **= r49p1 要求；≠ r56p0 要求（4）** |
| 0x05 | `00` | `version_major` | 0 | ✅ 两版都要求 0 |
| 0x06–0x07 | `00 00` | 保留（源码未读取） | — | 不参与校验 |
| 0x08–0x0B | `00 00 0a 03` | `version_hash` | `0x030A0000` | 仅打印 / ktrace，见下 |
| 0x0C–0x0F | `00 00 00 00` | 保留（源码未读取） | — | — |
| 0x10–0x13 | **未采集** | `entry_end_offset` | — | 本轮只读到 0x0F |

**三条判定**：

1. **header = `0.3`**，[D·A]。与 `02` §3.1 的 `FIRMWARE_HEADER_VERSION_MINOR(r49p1) = 3` 精确相等。
2. **r56p0 必拒**：`3 != 4` → `-EINVAL`。组合 B 的否决由 [E2] 升为 **[E1]+[D·A]**。
3. **原厂配套自洽**：固件 0.3 + kbase `r49p1-03bet0` + DDK `r49p1-03bet0`（见 §5.4），三者同代。

> **⚠️ `version_hash` 防误用（必须写入本节）**
>
> `0x030A0000` 若按 `GLB_VERSION` 寄存器格式（`major<<24 | minor<<16 | patch`）解码，恰为 **3.10.0**。**这是数值外观的巧合，不是证据**：
>
> - 源码中 `version_hash` 只出现在两处——`dev_notice("Loading Mali firmware 0x%x", version_hash)` 与 ktrace `CSF_FIRMWARE_BOOT` 的 `(hash<<32)|(major<<8)|minor`；
> - 它**不参与校验**，**不是从 GLB 共享内存读出的**；
> - 真正决定 GLB 语义的是运行时 `iface->version`，与 header offset 8 无关。
>
> 因此 **U4-11 不因本次采集闭合**。任何"0x030A0000 → GLB 3.10.0"的写法，与首轮"E2 当实测"同属越级，禁止。
>
> （附注：`%x` 无零填充，dmesg 中将显示 `0x30a0000`。）

---

## 5. 用户态实体清单（[D] 实测）

### 5.1 图形相关对象全表

| 对象 | 路径 | 字节 | SHA256（前 8） | 判定要点 |
| --- | --- | ---: | --- | --- |
| GLES 驱动 | `/vendor/lib64/egl/mt6991/libGLES_mali.so` | **53,105,232** | `d84ae538` | SONAME `libGLES_mali.so`；Build ID `700e6d4112a6a8a5`；note **API level 35**；`FLAGS: SYMBOLIC BIND_NOW` |
| Vulkan 厂商模块 | `/vendor/lib64/hw/mt6991/vulkan.mali.so` | **133,416** | `336acc0f` | SONAME `vulkan.mali.so`；**仅导出 1 个符号 `mali_vk_vendor_stub`**；NEEDED **`libGLES_mali.so`** |
| mapper HAL | `/vendor/lib64/hw/mt6991/mapper.mediatek.so` | 187,640 | `eaa9b03c` | SONAME `mapper.mediatek.so`；导出 `GrallocMapperV5*` + `arm::mapper::common::*` + `ANDROID_HAL_MAPPER_VERSION` |
| HWC | `/vendor/lib64/hw/hwcomposer.mtk_common.so` | 2,086,232 | `1b911b83` | SONAME `hwcomposer.mtk_common.so`；**NEEDED 中无任何 Mali 库** |
| gralloc（default） | `/vendor/lib64/hw/gralloc.default.so` | 52,344 | `c2588383` | 仅 NEEDED `liblog/libcutils/libc++/libc/libm/libdl`——**无分配后端**，是 passthrough 占位 |
| Mali 平台 HAL | `/vendor/lib64/mt6991/arm.mali.platform-V2-ndk.so` | 85,344 | `74c7d175` | AIDL `arm.mali.platform`（压缩率/EGL 格式协商） |
| EGL 属性注入 | `/vendor/lib64/mt6991/libarm_egl_properties_sysprop.so` | 35,704 | `f30bc153` | 对应 `ro.vendor.arm.egl.configs.*` 一整族属性 |
| gralloc 属性注入 | `/vendor/lib64/mt6991/libarm_gralloc_properties_sysprop.so` | 35,672 | `325567a1` | 对应 `ro.vendor.arm.gralloc.*` |
| Mali 配置属性 | `/vendor/lib64/mt6991/libarm_mali_config_sysprops.so` | 52,056 | `f6d92135` | |
| GPU 数据面 | `/vendor/lib64/libgpud.so` | 395,856 | `de46f6ee` | MTK 性能/抓帧数据生产者的 vendor 副本 |
| GPU 数据面（system） | `/system_ext/lib64/libgpud_sys.so` | 未采集 | — | 被 `/system/lib64/libvulkan.so` NEEDED |
| GPU 辅助 | `/vendor/lib64/libgpu_aux.so` | 151,760 | `a03447df` | |
| 系统 EGL | `/system/lib64/libEGL.so` | 287,664 | `bca71cbf` | note **API level 37**；NEEDED 含 `libnativebridge_lazy`/`libnativeloader_lazy`/`libvndksupport` |
| 系统 GLESv2 | `/system/lib64/libGLESv2.so` | 117,312 | `cac82021` | API 37；NEEDED `libEGL.so` |
| 系统 Vulkan loader | `/system/lib64/libvulkan.so` | 308,040 | `d69f6469` | API 37；**NEEDED `libgpud_sys.so`（MTK 定制）** |
| MEOW 拦截层 | `/vendor/lib64/egl/libGLES_meow.so` 等 5 个 | 未采集 | — | 小米图形拦截/追踪层 |

### 5.2 依赖关系（[D]，来自 `DT_NEEDED`）

```
libGLES_mali.so
├─ libged.so            ← MTK GED 用户态（→ /dev/ged → 内核 ged.ko）
├─ libgpud.so           ← MTK GPU 数据面（80+ 个 gpudVk*/gpudMisc* UND 符号）
├─ libgralloc_extra.so / libgralloc_metadata.so / libgralloctypes_mtk.so
├─ android.hardware.graphics.allocator-V2-ndk.so   ← 分配走 AIDL allocator HAL（gralloc-v2 服务）
├─ android.hardware.graphics.mapper@4.0.so
├─ libdmabufheap.so / libion.so
├─ arm.mali.platform-V2-ndk.so
└─ libc++/libc/libm/libdl/libz/libbase/liblog/libcutils/libhardware/libnativewindow/libutils/libbinder_ndk

vulkan.mali.so  →  libGLES_mali.so（唯一非 libc 依赖）
libvulkan.so    →  libgpud_sys.so（MTK 定制，非 AOSP 原样）
mapper.mediatek.so → libged.so / libgpud.so / libdrm.so / mapper@4.0 / libdmabufheap / libsync
hwcomposer.mtk_common.so → libged.so / libdpframework.so / libdrm.so / libpq_sec.so / mapper@2.0,2.1,4.0
                          （**无 libGLES_mali.so**）
```

**三条硬结论（[D]）**：

1. **Vulkan 不是独立实现**：`vulkan.mali.so` 仅 133 KB、SONAME 为自身、唯一导出 `mali_vk_vendor_stub`，且 NEEDED 直指 `libGLES_mali.so` → 它是**薄壳**，Vulkan 主体在 GLES 库内。
2. **HWC 不链接 Mali DDK**：这是首轮只能靠 [E3] 惯例推断的结论，现在是 [D] 事实。
3. **MTK 用户态库是 GLES 的硬依赖**：`libged` + `libgpud` + 4 个 gralloc 私有库。**"原厂用户态可整体保留"必须限定为"整套保留"**，不能只留 `libGLES_mali.so`。

### 5.3 仍然没有的东西（版本串已补，其余仍缺）

| 缺口 | 状态 | 影响 |
| --- | --- | --- |
| `libGLES_mali.so` release 串（`r[0-9]{2}p[0-9]-…`） | **✅ 已取**：`r49p1-03bet0`（见 §5.4） | U4-04 的"版本代次"子项闭合 |
| `libGLES_mali.so` 的 `UK version N.N` 字面量 | **未命中**（该正则全文无匹配） | 只说明"该模式不存在"，**不等于**"无 UK 版本"；由 release 串映射 |
| `libGLES_mali.so` 完整符号表 / `.text` | **无**（符号输出被采集脚本按关键字筛选） | U4-04 padding 子项 / U4-14 仍开放 |
| `libgpud_sys.so` 的元数据 | **无**（未列入 metadata 目标） | 只知被 NEEDED，不知其导出 |
| `libEGL_mali.so` | 全域未见（`egl/` 目录完整枚举 6 项，无此项） | 见 §6 |

### 5.4 DDK release 串实测（[D·A]，第二个关键补采）

**原始输出片段**：

```
--- [U4-04] Userspace DDK version strings ---
PATH: /vendor/lib64/egl/mt6991/libGLES_mali.so
SIZE:   53105232 bytes
DDK_UK_VERSION: NOT_FOUND
DDK_RELEASE:    r49p1-03bet0 r49p1-03bet0 r49p1-03bet0
DDK_GPU_MODEL:  Mali-G71 Mali-G725 Mali-G77 Mali-G720 Mali-G31
DDK_BUILD_ID:   NOT_FOUND
```

**解读（逐项，含每项的方法学边界）**：

| 项 | 结果 | 能说明 | **不能**说明 |
| --- | --- | --- | --- |
| `DDK_RELEASE` | `r49p1-03bet0` ×3 | **DDK 与内核同 release 串**（`/sys/module/mali_kbase_mt6991_r49/version` 亦为 `r49p1-03bet0`）→ 原厂配套 | 不能说明 DDK 的运行时行为（ioctl/padding） |
| `DDK_UK_VERSION` | `NOT_FOUND` | 全文**无** `UK version N.N` 该字面模式 | **不能**说"DDK 没有 UK 版本"；`MODULE_VERSION` 那种写法只在内核模块里 |
| `DDK_GPU_MODEL` | G71 / G725 / G77 / G720 / G31 | 该 `.so` 是**多型号共用**的 DDK 包 | **不能**据此判断是否支持 G925：① `grep -m 5` 只取前 5 条；② 模式 `Mali-[A-Za-z0-9]+` **结构上不匹配** `Immortalis-G925` |
| `DDK_BUILD_ID` | `NOT_FOUND` | 设备端 `readelf -n \| grep 'Build ID'` 未命中 | **不能**说"无 Build ID"：首轮离线 `readelf` 已取得 `700e6d4112a6a8a5`，属设备端工具差异 |

**由此得到的结论（等级分明）**：

1. **用户态 DDK 是 `r49p1-03bet0`** —— **[D·A]**（厂商分区静态文件内的可打印串）。这是"原厂整套配套"的第三块拼图（固件 0.3 / kbase r49p1 / DDK r49p1）。
2. **DDK 的 UK ABI 为 1.30** —— **[D·A]+[E1]**：由 `r49p1-03bet0` 这个 release 串，经 `MODULE_VERSION` 展开规则反推（`BASE_UK_VERSION_MAJOR/MINOR` 在同 release 内固定），而**不是**"库内自报 `UK version 1.30`"。二者证据强度不同，必须分开表述。
3. **padding / props 行为仍未验证** —— **[U]**（U4-04 的两个子项保持开放，需 `strace` 或反编译）。

> **方法学教训（两条，值得记入规范）**：
>
> - **`-m N` 会截断，截断后的结果不能用于"不存在"的断言**。`grep -m 5` 只回答"前 5 个匹配是什么"，不回答"还有没有别的"。
> - **正则模式本身就是盲区**。用 `Mali-*` 找 Immortalis-G925 永远找不到——不是设备没有，是模式不匹配。这与"用 `strings` 找单字节 header"是同一类错误：**工具选型先于结论**。

**与 U4-04 原始定义的对应**（该 ID 内含三个子问题，本次只闭合第一个）：

| 子问题 | 状态 | 依据 |
| --- | --- | --- |
| DDK 自称的 UK ABI 是多少 | **已推进**：`r49p1-03bet0` → 1.30 | [D·A]+[E1] |
| `MEM_JIT_INIT` 的 padding 是否清零 | **开放** | 需反编译 / `strace` |
| `gpu_props` 是否严格校验字节数 | **开放** | 需反编译 / `strace` |

---

## 6. EGL 加载路径：不能因"缺 `libEGL_mali.so`"判定异常

### 6.1 实测事实（[D]）

| 事实 | 值 |
| --- | --- |
| `ro.hardware.egl` | **`mali`** |
| `ro.hardware.vulkan` | **`mali`** |
| `ro.hardware.gralloc` | `common` |
| `ro.hardware.hwcomposer` | `mtk_common` |
| `/vendor/lib64/egl/` 内容 | `libGLES_meow.so`、`libMEOW_data/gift/qt/trace.so`、**`mt6991/libGLES_mali.so`**（共 6 项，含 1 个子目录） |
| `libEGL_mali.so` | **不存在**（`/vendor/lib64/egl`、`/vendor/lib64`、`/system/lib64` 均未见） |
| 系统 EGL/GLES | `libEGL.so` 287,664 B、`libGLESv2.so` 117,312 B，**均为 API 37 AOSP 构建** |
| 运行状态 | `init.svc.vendor.hwcomposer=running`、SurfaceFlinger 服务在册、`ro.vendor.composer_version=3.3` |

### 6.2 为什么缺 `libEGL_mali.so` 不是故障

| 论证 | 内容 |
| --- | --- |
| 反证法 | 设备**正在运行**（HWC pid 1708、SurfaceFlinger 进程在 binder 服务表内）。若 EGL 真的加载失败，系统不可能进入此状态。因此"加载路径是通的"是 [D] 事实 |
| 结构解释 | 自 Android 8 起，供应商**不再提供 `libEGL_*.so`**；EGL 前端由系统 `libEGL.so` 承担，供应商只提供 GLES 驱动库，由 loader `dlopen` 后取 `egl*` 入口 |
| 目录布局 | `egl/**mt6991**/libGLES_mali.so` 的 SoC 子目录布局，说明加载路径由**厂商 linker 配置**注入（而非默认 `egl/` 平铺），这与"多 GPU 变体共用 vendor 分区"的打包方式一致 |
| 反例排除 | 若 `libEGL_mali.so` 真的是必需项且缺失，`libEGL.so` 会在 `eglGetDisplay` 阶段直接失败——与实测运行状态矛盾 |

### 6.3 仍未确定的部分（[U]）

| 项 | 为什么不能定论 |
| --- | --- |
| `mt6991` 子目录是如何被加入搜索路径的 | 需读 `/linkerconfig/ld.config.txt` 或 `ro.egl.additional_libraries`（后者**未出现在 getprop 采集结果中**，但该结果本身是筛选输出，不能据此断定未设置） |
| `libGLES_meow.so` 的注入方式 | 需 `ro.egl.additional_libraries` 或 `LD_PRELOAD`/`debug.egl.*` 佐证 |
| `libGLES_mali.so` 是否导出 `egl*` 入口 | 符号输出被关键字筛选，未见 `eglGetDisplay` **不能**证明未导出 |

> **因此本文件的措辞是**：EGL **实际可用**（[D]），加载**机制细节 UNKNOWN**（[U]）。首轮 01 §3.2 把 `libEGL_mali.so` 列为"期望路径"的写法，已按本节修正为"不存在且不必存在"。

---

## 7. 图形栈服务与声明（[D]）

### 7.1 运行中的服务

| 服务 | pid | 含义 |
| --- | ---: | --- |
| `vendor.hwcomposer` | 1708 | composer 3.3 HAL |
| `vendor.gralloc-v2` | 1706 | **AIDL allocator，实际分配者** |
| `vendor.gpuserv-default` | 1982 | MTK GPU 服务（`IGpuService`） |
| `gpu`（framework） | 1812 | `android.graphicsenv.IGpuService` |
| `vendor.mediatek.hardware.mmagent-default` | 2213 | 显示/多媒体代理 |

### 7.2 VINTF 与特性声明

| 声明 | 值 | 意义 |
| --- | --- | --- |
| `android.hardware.vulkan.version-1_3` | 存在 | **Vulkan 1.3 能力已被系统承认** |
| `android.hardware.vulkan.level-1` | 存在 | |
| `android.hardware.vulkan.compute-0` | 存在 | |
| `android.software.vulkan.deqp.level-2024-03-01` | 存在 | CTS/VTS 合规等级 |
| `android.hardware.opengles.aep` | 存在 | GLES AEP |
| manifest | `manifest_hwcomposer.xml`(395 B)、`mapper.mediatek.xml`(311 B)、`manifest_mtkgpuserv.xml`(208 B) | 三者齐备 |

### 7.3 与"GPU 是否可缺席"相关的属性

| 属性 | 值 | 读法 |
| --- | --- | --- |
| `ro.vendor.mtk.gpu.sw3d` | **`0`** | **软件 3D 关闭**——无 CPU 光栅化回退 |
| `ro.vendor.mtk.gpu.service` | `1` | GPU 服务启用 |
| `ro.hwui.use_vulkan` | `true` | HWUI 走 Vulkan |
| `persist.sys.enable_systemui_mali` | `true` | 系统 UI 显式绑定 Mali |
| `persist.miui.gpu.partition.enable` | `true` | MIUI 侧 GPU 分区特性 |
| `graphics.gpu.profiler.support` | `true` | 抓帧/性能工具链 |

> 这张表**只是风险信号，不是 bootloop 结论**。`sw3d=0` 说明本机没有配置 CPU 3D 回退；但"SurfaceFlinger 在无 GL 时是否仍能起 client 合成"是另一回事，二者不能互相替代。U4-10 保持 UNKNOWN。

### 7.4 DT 侧（[D]）

`/sys/firmware/devicetree/base/` 可见：`soc/mali@48000000`（含 `gpu-frame-base-optimize`）、`soc/gpueb@4b000000`（`gpueb_mem_size`、`gpueb-mem-table`）、`gpufreq-wrapper`（`gpufreq-version`、`gpufreq-bringup`、`gpueb-support`）、`reserved-memory/mblock-17-me_GPUmputab_PMA` 与 `mblock-52-me_GPUEB_SHARED`。

| 结论 | 等级 |
| --- | --- |
| PMA 页表区由 DT 预留，PMA 路径真实存在（呼应首轮"PMA 可保留"） | **[D]** |
| `mall@48000000` 节点**未见** `firmware-name` → 走默认 `mali_csffw.bin` | **[D]**（与 TASK 03 dtbo 解析一致，U4-03 闭合） |
| `gpufreq-wrapper` 同时具备 `gpueb-support` 与 `gpufreq-version` 属性 → 频率策略仍由 MTK 层承担 | **[D]** |

---

## 8. 三份采集文件的净收益

| 首轮结论 | 本次判定 | 依据 |
| --- | --- | --- |
| "仓库内零用户态实体" | ✅ 仍成立（仓库层面） | 仓库仍未提交任何 `.so`/`.bin` |
| "Vulkan ICD 是否存在 UNKNOWN" | ✅ **升级为"存在"** | `ro.hardware.vulkan=mali` + `vulkan.mali.so` 实体 + VINTF 1.3 声明 |
| "gralloc/mapper/HWC 免疫" | ⚠️ **撤回** | HWC 不链接 Mali DDK（[D] 证实），但 NEEDED `libged`；`ged.ko` 不反向依赖 kbase → 失效表现为降级而非崩溃 |
| "原厂固件 header = 0.3" | ✅ **P0 补采后已实测确认**（三份基线本身只能到 E2 推理，见 `02` §3.0） | §4.5：`6e 3a f1 c3 03 00 00 00` |
| "原厂用户态契约层可保留" | ✅ **不变**，且新增实现层约束 | 整套依赖 MTK 用户态库，不能拆 |
| "bootloop UNKNOWN" | ✅ 保持 UNKNOWN | 无 HyperOS 4.0.3.0 实机故障证据 |
| "EGL 路径 UNKNOWN" | ⚠️ 拆成"可用 [D] / 机制 [U]" | 见 §6 |
| （隐含）"设备 = 原厂环境" | ⚠️ **不成立**：内核为第三方 GKI（`u:r:ksu:s0`） | §2 / §3 / `08` §1 |
| "15 个 `.ko` 已装载" | ⚠️ **限定**：装载的是设备侧 `6.6.143` 构建，非仓库 `6.6.118` 基线 | §3.4 |
| （新增）"DDK 版本代次未知" | ✅ **已取**：`r49p1-03bet0`，与 kbase 同串 | §5.4 |

---

## 9. 方法学限制（读本文件前必须知道）

1. **目录清单是被筛选的**。`inventory` 的 `/vendor/lib64`、`/system/lib64` 等段落明显为模式匹配输出（含大量 camera/audio 库，但不含全部库）。因此"某文件不在清单里"**只能弱推断其不存在**；本文件中所有"不存在"判断都已在正文注明其强度。`egl/` 子目录的 6 项枚举看起来是完整 `ls`。
2. **符号输出是被筛选的**。`elf_analysis` §2 只覆盖 `gpud*`/`ged_*`/`Egl*`/`vk*`/mali 平台类符号，**不是完整 `.dynsym`**。因此"未见 `eglGetDisplay`"不能推出"未导出"。
3. **无 dmesg / logcat**。因此所有"运行时行为"结论（GLB 版本、DDK 协商值、失败表现）仍无从验证。
4. **无文件内容**。`mali_platform.config`(86 B)、`gralloc/gpu.xml`(1,166 B)、`gpuserv-default.rc`(366 B)、三个 VINTF manifest（208–395 B）都只有大小与哈希，**内容未采集**。
5. **同一份采集不可重复演绎**。本次所有 [D] 结论都指向上表的三个文件；任何超出其内容的推断都已标 [E2]/[E3]/[U]。
6. **SUSFS 可隐藏路径**。内核启用 SUSFS 后，`ls` / `stat` 结果可被策略过滤，使"清单里没有"这一推断比第 1 条更弱。凡本文的"不存在"判断，均只作**弱推断**。
7. **未采 mount 表**。无法判断 `/vendor` 当前视图是否被 KernelSU / NoMount 元模块 overlay 覆盖（U4-27）。因此 A 类结论的边界是"**分区未被安装包修改**"，不是"**视图必为分区原样**"。
8. **观测内核非原厂**。所有运行时结论仅代表"厂商模块 + 第三方 GKI 内核"这一组合，不外推到原厂 boot（详见 `08_kernel_provenance_audit.md`）。

---

## 10. 最小化只读补充采集（**已于 2026-11-15 23:20 执行**）

**结论：需要，且只需一次。** 理由是存在两个**能被几十字节直接闭合**的 P0 缺口，而基线采集在原理上无法覆盖。**本次已由用户执行并回传，结果见 §4.5 / §5.4。** 本节保留原始命令与判读表，作为**可复现记录**。

### 10.1 缺口一：固件 header 实际版本（U4-01，P0）—— **✅ 已闭合**

- 为什么必须采：`version_minor` 是 offset 4 的**单字节**，`strings` 原理上取不到；而它是"组合 B 是否确定不可行"的唯一实测依据。
- 命令（文件权限 644，通常 `shell` 用户即可读；若被 SELinux 拒绝，前置 `su -c`）：

```bash
adb shell "od -An -tx1 -N 8 /vendor/firmware/mali_csffw.bin"
# 若 od 不可用：
adb shell "dd if=/vendor/firmware/mali_csffw.bin bs=1 count=8 2>/dev/null | hexdump -C"
```

- 读法（`02` §2 已证字段布局）：`6e 3a f1 c3` 是 magic `0xC3F13A6E` 的小端字节；**第 5 个字节 = minor，第 6 个字节 = major**。
  - `6e 3a f1 c3 03 00 …` → **0.3**，`02` §3 的硬阻断判定由"推理"升级为"实测"； ← **本次命中**
  - `6e 3a f1 c3 04 00 …` → **0.4**，则首轮最核心的结论被推翻，必须重写 `02`/`06`。
- **实际结果**：`6e 3a f1 c3 03 00 00 00` → **0.3**，见 §4.5。

### 10.2 缺口二：DDK 自称的 UK ABI 版本（U4-04，P0）—— **✅ 版本代次已取，行为子项仍开放**

- 为什么必须采：`03` 的整套论证是"1.30 DDK 在 r56p0 上走旧语义"，但**DDK 是否真的宣称 1.30** 从未被观测。设备上直接 `grep` 二进制即可，**不需要 pull 53 MB**。
- 命令：

```bash
adb shell "grep -a -o -m 3 -E 'UK version [0-9]+\.[0-9]+' /vendor/lib64/egl/mt6991/libGLES_mali.so"
adb shell "grep -a -o -m 3 -E 'r[0-9]{2}p[0-9]-[0-9a-z]+' /vendor/lib64/egl/mt6991/libGLES_mali.so"
```

- 读法：若出现 `UK version 1.30` 与 `r49p1-…`，则"原厂 DDK 与内核同代"由 [E1] 推理变为 [D]；若出现 `1.31+`，则需重算 `min()` 协商的实际落点（结论方向不变，但"1.30 语义"的前提要改）。
- **实际结果**：第一条 **NOT_FOUND**（该字面模式不存在）；第二条 **`r49p1-03bet0`**。→ 由 release 串映射为 1.30。见 §5.4。
  - 这条"部分命中"本身就是重要信息：它说明 **DDK 不自报 UK 版本，只自报 release**。因此后续任何"DDK 宣称 N.N"的表述都必须写成"由 release 映射"，不能写成"库内读到"。

### 10.3 缺口三（P1）：模块构建代次（U4-24）—— **工具已就绪，待执行**

- 为什么需要：§3.4 已证明设备 `.ko` 与仓库基线 `.ko` **不是同一构建**。若 Stage 5 要用二进制级常量（`__versions` CRC、kCFI 哈希），必须以设备构建为准。
- 为什么不能用上面那种"手写一行 `strings`"的做法：模块路径**不是猜出来的**（`/vendor/lib64/modules` 只是常见位置之一），已有采集也没记录过路径。因此改为一次受控采集：

```sh
# 手机端（aShell You，已 root），只读，无 adb
su
sh /data/local/tmp/c.sh
```

脚本：`tools/collect_gpu_module_identity.sh`；步骤与判读表：`tools/README_gpu_module_identity.md`。

采集内容（每个模块独立成段）：实际路径 / realpath / 文件大小 / SHA256 / 权限 / `.modinfo` 的 `name, vermagic, srcversion, version, depends, retpoline, intree` / `VERMAGIC_MATCHES_UNAME_R` / sysfs `version, srcversion, taint, initstate, coresize, inuse, holders` / sysfs Build ID / ELF 头与 Build ID / `__versions`、`__ksymtab`、`.text`、`.modinfo` 节大小。

- 读法：vermagic 应为 `6.6.143-android15-8-gf9aa2fec23c3-4k …`；若如此，§3.4 的推论由 `[E2]` 升为 `[D·C]`。完整判定矩阵（含"若是第三种串"这一支）见 `08` §3.6.4。
- **子项拆分**：U4-24a = 身份（本脚本可闭合）；U4-24b = 数值（设备构建的 `__ksymtab` CRC / kCFI 期望常量，需反汇编或 `.ko` 副本，**本阶段不做**）。见 `08` §3.6.5。

### 10.4 明确不要求的采集

| 不做 | 原因 |
| --- | --- |
| `pull` 任何 `.so` / `.bin` / `.ko` | 合规红线；且上述缺口用设备内 `od`/`grep` 即可闭合 |
| `strace` / `dmesg` / `logcat` | 需 root 或重启，超出"最小只读"；待 P0 闭合后再议（U4-14/U4-16/U4-02） |
| 重跑整份 `collect_device.sh` | 三份文件已覆盖其绝大部分输出 |

> **状态（2026-11-15 23:50 更新）**：
>
> | ID | 旧状态 | 新状态 |
> | --- | --- | --- |
> | **U4-01** | UNKNOWN（有 E2 级推理） | **✅ 已闭合 [D·A]**：header `0.3` |
> | **U4-04** | UNKNOWN（有 E1 级推理） | **⚠️ 部分闭合**：版本代次 `r49p1-03bet0` [D·A]；padding / props 行为仍 [U] |
> | **U4-24** | UNKNOWN（无采集手段） | **⚠️ 工具已就绪，仍未闭合**：`tools/collect_gpu_module_identity.sh` + 指南已提交，**未在真机运行**；子项 b（CRC / kCFI 数值）本阶段不做 |
>
> §10.3 的采集工具已交付，但**在用户回传输出之前，U4-24 一律记 UNKNOWN**。
