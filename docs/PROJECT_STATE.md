# PROJECT_STATE — 项目长期状态

> **这是每个新 Agent 会话的首要恢复入口。**
> 本文件描述**当前有效状态**；历史快照与已被推翻的结论见各目录 `README.md` / `MANIFEST.md` 的历史段与 `docs/DECISION_LOG.md`。
> 任何与本文件冲突的对话记忆或 commit 标题，以本文件 + 仓库实测为准；若发现本文件与实测不符，**先修本文件**。

| 项 | 值 |
| --- | --- |
| 最后更新 | 2026-11-16 01:10（GMT+8） |
| 更新提交 | `stage4: close remaining audit items with source-level verification` |
| 提交前基准 HEAD | `50644e1`（`stage4: close U4-24a with device module identity`） |
| 分支 | `main` |
| 精确 SHA 查询 | `git log -1 --format='%H %s'` |

---

## 1. 项目基本信息

| 字段 | 值 | 证据 |
| --- | --- | --- |
| 设备 | Redmi K80 至尊版 | — |
| 机型代码 / 代号 | `25060RK16C` / `dali` | **[D·A]** 设备采集 §1 |
| SoC | MediaTek **MT6991** | **[D·A]** |
| GPU | Arm **Immortalis-G925 MC12**（5th Gen / CSF） | **[D·A]**（`compatible = arm,mali-valhall`） |
| Android | **17 / SDK 37**，HyperOS `OS4.0.3.0.XONCNXM` | **[D·A]** `ro.build.*` |
| **运行内核**（第三方） | **Linux 6.6.143-android15-8-gf9aa2fec23c3-4k**，SukiSU-Ultra 构建 | **[D·B]** `uname -a` + `u:r:ksu:s0` |
| **原厂内核（推定）** | **Linux 6.6.118-android15-8-g54a15cf3acba-4k** | **[E2]**：18 个厂商 `.ko` 的 vermagic（`05/07` §3.5） |
| **仓库基线内核** | **Linux 6.6.118-android15-8-g57e634f35c1b-4k**（OS3.0.305.0） | **[E1]** |
| 内核源码提交 | `f9aa2fec23c3f4a06a935f69dc04cb85b261e7f3`（GKI `android15-6.6`） | **[B]** CI 运行页 + **[D·B]** |
| 原厂基线 | `mali-r49p1-03bet0`（CSF UK ABI **1.30**） | `01_original_baseline/` |
| 目标驱动 | `mali-r56p0-18eac0`（CSF UK ABI **1.39**） | `02_r56_source/` |
| 仓库 | `github.com/JiangXue5/K80U_GPU_R56_AUDIT` | — |

> `android15` 是 **GKI 分支名**，不是 Android 版本。设备 Android 为 17。

---

## 2. 阶段状态

| 阶段 | 内容 | 报告 | 证据 |
| --- | --- | --- | --- |
| Stage 0 | 目录骨架与审计说明 | ✅ 完成 | ✅ |
| Stage 1 | 参考资料与双基线采集 | ✅ 完成 | ✅ 两条基线实体在手 |
| Stage 2 | kbase / CSF 差异审计 | ✅ 完成（7 份，45 条差异 / 13 P0） | ✅ |
| Stage 3 | MTK 平台层审计 | ✅ 完成（7 份，保留 10 / 适配 2 / 重写 0） | ✅ |
| Stage 3-REA | 二进制逆向补充 | ✅ 完成（8 份，12 个 `.ko` / 5,440 函数） | ⚠️ 数值基线需按 §5.4 重导 |
| **Stage 4** | 用户态与固件 ABI | ✅ **已交付**（9 份，`01`–`09`） | ⚠️ **收尾完成，未闭环**（U4-01、U4-24a、U4-25a 闭合；3 项 P0 开放） |
| Stage 5 | 方案设计与可行性结论 | ⏳ 未开始 | — |

**"报告已交付"与"证据已闭环"是两种状态，不可互相替代。**

---

## 3. Stage 4 当前状态

### 3.1 计数（与 `05_userspace_firmware/06_abi_compatibility_matrix.md` §7 及 `MANIFEST.md` §6.1 一致）

| 项 | 数量 |
| --- | --- |
| UNKNOWN 总数 | **27** |
| 已闭合 | **5**（U4-01 / U4-03 / U4-05 / U4-08 / U4-09） |
| 部分闭合 | **5**（U4-04 / U4-06 / U4-07 / U4-24 / **U4-25**） |
| **P0** | **3**（U4-04 / U4-10 / U4-12） |

> **本轮变化（2026-11-16 收尾核验）**：部分闭合 4 → 5（U4-25 的 a 子项闭合）；**P0 数量不变，但 U4-04 风险等级上调**（padding 强制校验 15 处，覆盖 CS 主链路，见 §5.4）。**U4-12 性质变更**：不是"没找到固件"，而是"交付包内 0 个固件条目，属商业交付件"——它是**阻断**。

### 3.2 P0 明细

| ID | 内容 | 当前证据 | 闭合方式 |
| --- | --- | --- | --- |
| ~~U4-01~~ | ~~原厂 CSF 固件 header 实际字节~~ | ✅ **已闭合 [D·A]**：`6e 3a f1 c3 03 00 00 00` → `offset 4 = 0x03` / `offset 5 = 0x00` → **0.3** | 2026-11-15 23:20 `od` 读数（`05/07` §4.5、`05/02` §3.0.5） |
| **U4-04** | 原厂 DDK **自身**宣称的 UK ABI / padding 是否清零 / props 是否严格校验 | **版本代次已取**：`libGLES_mali.so` 内含 `r49p1-03bet0` **[D·A]**，与 kbase 模块串同代 → UK 1.30（映射）；**padding 门槛已定量**：48 个钩子中 **15 个强制**（含 `CS_QUEUE_REGISTER`、`CS_QUEUE_GROUP_CREATE*`）**[E1]**；**props 机制已明**：`size==0` 协商 + `size < prop_buffer_size` 才 `-EINVAL` **[E1]**；DDK 是否清零/是否协商仍 [U] | 一条 `strace -e ioctl` 或一次反编译（需 `.so` 内部证据） |
| **U4-10** | GPU 初始化失败后是否 bootloop | 本机 `ro.vendor.mtk.gpu.sw3d=0`（无 CPU 3D 回退）是**风险信号**，非实证 | 故障注入（需可回滚环境，高风险） |
| **U4-12** | R56p0 固件是否匹配 G925 MC12 | **阻断**：R56 交付包 23 个条目中 `firmware`/`.bin`/`ddk` 命中 **0** → 属商业授权件，不在源码包内 **[E1]** | 取得 R56 固件后按 `09` §6.2 的四项判据验收 |

### 3.3 来源审计新增项（**不是 P0**）

| ID | 内容 | 优先级 | 现有证据 |
| --- | --- | --- | --- |
| U4-24 | 设备侧 GPU `.ko` 的**路径 / 文件大小 / SHA256 / vermagic / srcversion**（a）／**`__ksymtab` CRC 与 kCFI 常量**（b） | **P1** | **a ✅ 已闭合**（18 个文件，`05/07` §3.5）；**b 开放**，范围收窄至 kbase（`05/08` §3.7.6） |
| U4-25 | 第三方内核与原厂 boot 的运行时差异范围（含 `check_version` 是否也被绕过） | **P1** | **25a ✅ 闭合**：vermagic 串不符是 `CONFIG_MODVERSIONS` 的原生语义（`same_magic` 忽略 release 串），**不存在也不需要**绕过 **[E1]**；**25b 开放**：真正的开关是 `bypass-kernel` 改 `bad_version`，默认关闭、2026-08-29→10-30 门控恒失效，且该补丁在 CRC 匹配时无行为差异 → **运行态不可观测**；25c 未测 |
| U4-26 | 设备当前 boot 是否即所链接 CI run 的产物 | P2 | **判据已更换**：`uname -v` 的日期是 `os_patch_level` 派生**常量**（`${YM}-05 04:20:00 UTC`），零信息量 **[E1]**；四项参数一致但不足以定论；缺内核 `build-id` |
| U4-27 | `/vendor` 当前视图是否被 KSU/NoMount overlay 覆盖 | P2 | 未采 mount 表 |

> 其它 P1：U4-02 / U4-11 / U4-14 / U4-15 / U4-17 / U4-22。P2：U4-06 / U4-07 / U4-16 / U4-19 / U4-20 / U4-21 / U4-26 / U4-27。P3：U4-13 / U4-18 / U4-23。

### 3.4 Stage 4 已确立的结论（按等级）

| 结论 | 等级 | 边界 |
| --- | --- | --- |
| UAPI 契约：ioctl 28/28 逐字相同、结构体 30/30 兼容、属性 ID 83/83 不变、能力表为 ≤1.30 保留旧语义 | **[E1]** | 仅"契约层"；不含实现行为 |
| r56p0 CSF 加载器只接受 header `0.4`，`!=` 严格、无 fallback | **[E1]** | 源码确定 |
| **原厂固件 header = `0.3`** | **[D·A]** | 已实测（16 字节 dump），U4-01 闭合 |
| 组合 B（r56p0 Kbase + 原厂固件）**不可行** | **[E1] + [D·A]** | **实测否决**：要 0.4，实际 0.3 |
| 原厂用户态**契约层**可保留（组合 C 候选），但须**整套**保留；DDK 版本代次 `r49p1-03bet0` | **[E1]** + **[D·A]** | 实现层行为未验证（U4-04 剩余子项） |
| 原厂三方**配套**：固件 0.3 + kbase `r49p1-03bet0` + DDK `r49p1-03bet0` | **[D·A]** + **[D·C]** | 三条独立证据同代 |
| Vulkan **存在**，是 133,416 B 薄壳（`vulkan.mali.so` 仅导出 `mali_vk_vendor_stub`，NEEDED `libGLES_mali.so`） | **[D·A]** | 兼容性随 GLES |
| HWC / mapper **不链接** Mali DDK，但 NEEDED `libged` | **[D·A]** | 故障性质为**降级**，因 `ged.ko` 不反向依赖 kbase |
| `libGLES_mali.so` 53,105,232 B / API 35 / 硬依赖 `libged`、`libgpud`、4 个 gralloc 私有库 | **[D·A]** | — |
| 设备 `.ko` 与仓库基线 `.ko` **不是同一构建**（同 sublevel、不同提交） | **[D·A]** + **[E1]** | 见 §5.4 |
| **14/15 个模块与仓库基线字节数及 `.text`/`__versions` 节大小完全相同**，`mali_mgm`/`mali_prot_alloc` 的 `srcversion` 逐字符相同；**仅 kbase 实质不同**（+17,640 B） | **[D·A]** | REA 重导范围可收窄至 kbase |
| ~~**运行内核绕过 vermagic 校验**~~ → **2026-11-16 撤回**：`CONFIG_MODVERSIONS` 下 `same_magic()` **原生忽略 release 串**，两侧 flags 段逐字符相同 → **合法装载，无需补丁** **[E1]** | **[E1]** + **[D·C]** | "装载成功"仍不构成"与 R56 兼容"的证据，但**可以**作为"被 import 符号 CRC 一致"的证据（前提：`check_version()` 未被 `allow_version_mismatch` 打开，U4-25b）；taint 仅 `(O)`、无 `F` → 未走强制装载 |
| **模块集合本身不对称**：设备 13 个 GPU 链路模块含 `mtk_ghpm`，仓库 15 个文件里没有它；仓库 3 个 `met_*` 设备未装载 | **[D·B]** + **[E1]** | "仓库 15 = 设备 15"不成立；`mtk_ghpm` 是否需纳入 Stage 5 需在设计中回答 |
| `lsmod` 的 `size` 是 `core_layout.size`（内存、页对齐），**不是文件大小**；两侧 `ged.ko` 文件同为 1,093,352 B | **[D·A]** | 历史"`ged` 差 409 KB"**结论方向亦错**，已作废（`05/08` §3.2、§3.6.2） |

---

## 4. 重要设备事实（防止新 Agent 重复踩坑）

1. **用户已完成三份 Stage 4 设备采集**（`stage4_inventory.txt` / `stage4_file_metadata.txt` / `stage4_elf_analysis.txt`），解析结论已固化在 `05_userspace_firmware/07_device_evidence.md`。**不得要求重新采集这三份文件。**
2. **设备当前运行的是第三方 GKI 内核**，不是原厂 boot。`[D·B]` 结论**不能**写成"原厂环境实测"。
3. `/vendor` 与 `/vendor_dlkm` 下的 GPU 文件与模块属**厂商分区内容**，安装包只写 `boot`（`block=boot` / `do.modules=0` / `do.systemless=0`）**[B]**；但这只说明"该包不改 vendor"，**不证明**设备 vendor 与出厂逐字节一致（U4-27）。
4. **设备 GPU 模块与仓库基线 `.ko` 不是同一构建，但差异面极小**：设备 vermagic `6.6.118-…-g54a15cf3acba`（OS4.0.3.0）vs 仓库 `6.6.118-…-g57e634f35c1b`（OS3.0.305.0），**同 sublevel、不同提交**。14/15 个模块的文件字节数与 `.text`/`__versions` 节大小**逐字节相同**，`mali_mgm`/`mali_prot_alloc` 的 `srcversion` 也相同；**只有 kbase 实质不同**（2,328,064 vs 2,310,424 B）。两侧 `ged.ko` 文件**同为 1,093,352 B**。
5. 厂商 15 个 GPU 相关模块**已在第三方 GKI 上实际运行**。**"能装载"不能推出"与 R56 兼容"**；但 2026-11-16 复核后要**撤回**"该内核绕过了 `same_magic()`"这一说法：`CONFIG_MODVERSIONS` 下 `same_magic()` 只比较第一个空格之后的 flags 段（`SMP preempt mod_unload modversions aarch64`），两侧**逐字符相同**，故装载合法、无需任何补丁（`05/08` §3.7.4、`05/09` §2）。装载成功**可以**说明"被 import 的符号 CRC 一致"，前提是该内核的 `check_version()` 未被 `allow_version_mismatch=true` 构建打开过（**U4-25b 未定**）。
6. 用户当前第三方内核**已稳定使用约一周**——这是**用户提供的背景 [P]**，不是独立实验报告，不可作为稳定性证据引用。
7. 固件的**大小 / SHA256 / strings** 与 **前 16 字节** 均已取得：`6e 3a f1 c3 03 00 00 00 00 00 0a 03 00 00 00 00` → **header 0.3**。**但 `entry_end_offset`（offset 0x10）仍未读到**，GLB 尾部版本（U4-11）仍未知。
8. **DDK 与 kbase 同 release 串 `r49p1-03bet0`**。这是"原厂配套"的直接证据，也意味着**不能把 DDK 当成独立变量**——任何"只换内核"的组合都会同时打破内核与 DDK 的版本对应关系。
9. **DDK 不自报 `UK version N.N`**。1.30 是由 release 串映射得出，不是库内字面量。凡表述"DDK 宣称 1.30"必须补"由 release 映射"。
10. **两次补采都只回传纯文本**（`/data/local/tmp/gpu_audit_p0/` 与 `/data/local/tmp/gpu_audit_mod/` 下的 `.txt`），未上传、未复制任何 `.so` / `.bin` / `.ko`。
11. **设备侧 GPU 相关 `.ko` 是 18 个文件、15 个已装载**（13 个 GPU 链路 + `mtk_cg_peak_power_throttling` + `mtk_smmu_qos`）；仓库基线只有 15 个文件，**缺这后两个以及 `mtk_ghpm`**。"仓库 15 = 设备 15"是错的。
12. **`met_*` 三个模块文件存在但未装载**（全量 `/proc/modules` 597 个中确无）——已从"筛选口径下未见"升级为"确认"。

---

## 5. 已知技术债与派生影响

### 5.1 固件判据（**已闭合**）

源码判据（[E1]）与实测判据（[D·A]）现已一致：r49p1 要 0.3、r56p0 要 0.4、**原厂实测 0.3**。组合 B 的否决有字节支撑，不再需要"推理支持"这类限定语。

> 遗留的相邻缺口：`U4-11`（GLB 运行时版本）与 `U4-12`（R56p0 固件是否匹配 G925）仍未闭合，二者与 header 版本是**不同问题**。

### 5.2 用户态契约 ≠ 实现

`03_gles_egl_abi.md` 的全部"兼容"结论都在 UAPI 契约层。`min()` 是**夹取**（取较小值），不是"校验"。DDK 版本代次已知（`r49p1-03bet0` → 1.30），但 **padding 清零 / props 协商行为仍未知**（U4-04 剩余子项）。

> **2026-11-16 风险上调（D-025）**：padding **不是**"Arm 全替你清零"的软门槛。全量重算：48 个 `check_padding_*` 中 **28 空 / 5 清零 / 15 强制**，强制集包含 `CS_QUEUE_REGISTER`、`CS_QUEUE_REGISTER_EX`、`CS_QUEUE_GROUP_CREATE_1_6|_1_18|_1_35`、`CS_QUEUE_GROUP_TERMINATE`、`CS_TILER_HEAP_INIT(_1_13)`。**若 1.30 DDK 不清零，GPU 不是降级而是完全不可用**。这是组合 C 的单点致命项，判定成本却最低（一条 `strace -e ioctl`）。

> **props 反而不再是最硬的门槛**：`kbase_api_get_gpuprops` 先以 `size==0` 返回所需长度，只有 `size < prop_buffer_size` 才 `-EINVAL`。DDK 只要做过一次 size=0 探测就不受影响（`05/09` §5.4）。

### 5.3 最小替换范围

**Kbase + CSF 固件两件套**；用户态**整套保留**；平台层按 Stage 3 保留 10 / 适配 2。影响半径包含 mapper / HWC 的 `libged` 事件面（降级，非崩溃）。

### 5.4 Stage 3 二进制常量的代次错配（**重要**）

`04_mtk_platform/REA_SUPPLEMENT.md` 的 **kCFI 类型哈希**与 **`__versions` CRC** 取自仓库基线 `.ko`（`6.6.118-…g57e634f35c1b`，OS3.0.305.0），而设备模块来自 `6.6.118-…g54a15cf3acba`（OS4.0.3.0）。**这些数值不能直接假定适用于设备**，但实测把重导范围压小了很多：

| 模块 | 证据 | 处理 |
| --- | --- | --- |
| **kbase** | `.text` 差 6,788 B；`__versions` 514→513 条；`srcversion` 不同 | **必须重导** |
| 其余 14 个 | `.text` 与 `__versions` 节大小逐字节相同；`mali_mgm`/`mali_prot_alloc` 的 `srcversion` 相同 | 抽样验证后可沿用（`05/08` §3.7.6） |

**源码级结论（依赖方向、调用链、ops 表结构）不受影响。**

> **U4-24 已拆为两个子项，不做笼统表述**（`05/08` §3.6.5）：
>
> | 子项 | 内容 | 能否只读文本闭合 |
> | --- | --- | :---: |
> | **a** | 模块身份：路径 / 文件大小 / SHA256 / vermagic / srcversion | ✅ **已闭合**（2026-11-16 00:04） |
> | **b** | 数值：设备 `__ksymtab` CRC、kCFI 期望常量 | ❌ 不能（需反汇编或 `.ko` 副本，后者须用户授权） |
>
> 依赖分类（同节）：`__versions` CRC = **数值型 oracle，必须从设备构建取**；kCFI 哈希 = **类型型 oracle，设备值用于验证"原型一致"，不是用来抄**；结构体大小/偏移 = 建议核对（成本低）；函数数/符号数/依赖方向 = **不受影响**。
>
> **收窄后的最小动作**：设备端 `readelf -x __versions /vendor_dlkm/lib/modules/ged.ko`（约 96 KB 纯文本）。`__versions` 记录的是"本模块期望的内核导出符号 CRC"，由**内核**决定——一个样本全等即可外推到同一内核的其余模块。kbase 因条数不同需单独处理。

---

## 6. 已否决 / 已撤回的方案与结论

| # | 对象 | 状态 | 原因 |
| ---: | --- | --- | --- |
| 1 | 组合 B：只换 Kbase，保留原厂固件 | **否决（实测）** | header 要 `0.4`，原厂实测 `0.3`，`!=` 严格 |
| 2 | "gralloc / mapper / HWC 免疫" | **撤回** | 不链接 DDK，但 NEEDED `libged` → 两跳耦合 |
| 3 | "固件 header 已实测 0.3" | **曾降级，现已恢复并坐实** | 第二轮因无字节降为 [U]；第三轮 `od` 读到 `03`，正式升为 [D·A] |
| 4 | "原厂用户态必须同步替换" | **推翻** | 契约层兼容（28/28、30/30、83/83、能力表） |
| 5 | "R56p0 未获取 / Stage 2 阻塞" | **失效** | 双基线实体在手 |
| 6 | "组合 A = 出厂状态验证通过" | **修正** | 观测环境是第三方内核 |
| 7 | 用第三方 PanVK 文档作 R56 兼容证据 | **禁止** | 非原厂证据 |
| 8 | "模块装载成功 = 模块同源" | **禁止** | vermagic 与 SHA256 均不同（§4 第 4 条） |
| 9 | "DDK 实测宣称 UK 1.30" | **禁止表述** | DDK 只自报 release 串；1.30 是映射结果，非库内字面量 |
| 10 | "由 `version_hash` 0x030A0000 推出 GLB 3.10.0" | **禁止** | `version_hash` 与 GLB 版本格式无关，属巧合解码 |
| 11 | "设备内核 = 6.6.143" | **证伪** | 6.6.143 是**第三方运行内核**；原厂应为 `6.6.118-g54a15cf3acba`（§1） |
| 12 | "模块装载成功 = ABI 兼容" | **禁止** | 装载只证明被 import 的符号 CRC 一致（且前提是 `check_version()` 未被 `allow_version_mismatch` 打开），**不能**推出与 R56 兼容（§4 第 5 条、`05/09` §3） |
| 14 | ~~"该内核绕过 `same_magic()`"~~ | **证伪并撤回** | `CONFIG_MODVERSIONS` 下 release 串本就不参与比较（`05/09` §2） |
| 15 | "`uname -v` 的时间 = 构建时间" | **禁止** | 该串由 `os_patch_level` 派生（`${YM}-05 04:20:00 UTC`），只编码补丁月（`05/09` §4、D-024） |
| 13 | "`ged` 差 409 KB，已排除同一二进制" | **证伪并作废** | 两侧文件同为 1,093,352 B；684,032 是 `lsmod` 内存值 |

---

## 7. 下一步任务队列（按优先级）

| # | 任务 | 目标 | 风险 |
| ---: | --- | --- | --- |
| 1 | ~~建立并验证长期上下文规范~~ | 让状态可从仓库恢复 | ✅ 完成（`0c1d1dd`） |
| 2 | ~~闭合 U4-01 + 推进 U4-04~~ | 组合 B 判定升为实测；组合 C 前提落地 | ✅ **完成（`65006de` 工具 + 用户执行 + 本轮整合）** |
| 3 | ~~评估 U4-24 设备侧模块身份采集是否必要~~ | 决定 Stage 3 常量是否必须重导 | ✅ 完成（`b1da0b9`） |
| 4 | ~~执行 U4-24a 并整合~~ | 设备 `.ko` 身份落地 | ✅ **完成（`b1da0b9` 工具 + 用户执行 + 本轮整合）** |
| 4b | **U4-24b 单样本比对**：设备端 `readelf -x __versions /vendor_dlkm/lib/modules/ged.ko` 回传 | 判定 14 个模块的 CRC 能否整体沿用 | 无（只读，~96 KB 文本） |
| 5 | ~~处理 U4-25 / U4-26 / U4-27~~ | 界定第三方内核差异面与 vendor 视图真实性 | ✅ **本轮完成复核**：25a 闭合、25b 判据明确；26 判据更换；27 仍缺 mount 表 |
| 6 | **U4-04 的 padding 子项（现为最贵风险）**：`strace -f -e trace=ioctl -o /data/local/tmp/gpu.log` 抓一次 `eglInitialize` | 看 `MEM_JIT_INIT` / `CS_QUEUE_REGISTER` 的 padding 字节是否清零 | 低（需 root，只读） |
| 7 | U4-12：取得 R56 固件（商业交付件） | 按 `05/09` §6.2 四项判据验收 | **阻断**（资产不在手） |
| 8 | **Stage 4 证据充分后**，再决定是否进入 Stage 5 | 设计 vs 定论分离 | — |

### 7.1 Stage 5 准入判定

| 层面 | 判定 |
| --- | --- |
| 开始 Stage 5 的**设计** | **可以在用户明确授权后开始**（固件分支已唯一：0.3，无需双分支展开） |
| 给出**可行性定论** | **仍不可以**（U4-04 行为子项、U4-12 未闭合） |
| 开始**实施**（编译/刷机/替换） | **不可以**（U4-24b 未闭合 + U4-04 padding 未定性 + 无可回滚环境声明 + 验证内核须能证明 `bad_version:` 仍为 `return 0`） |

> **Stage 5 当前不允许自动启动。** 必须由用户在 U4-04 行为面 / U4-12 / U4-24b 推进后显式授权。
>
> **与上一版相比的变化**：U4-01 闭合使"设计层"的条件从"可双分支展开"变为"单分支"——固件必须换，没有"也许 0.4 能用"的余地。
>
> **本版（收尾核验）修正的两条约束**：
>
> 1. **U4-24b 的范围**：从"15 个模块的 CRC 全重导"降为"kbase 必须重导 + 其余 14 个抽样验证"（不变）。
> 2. **验证环境约束改写**：原写"必须换到未打补丁的内核"——**撤回**，那种内核不存在（`same_magic` 本来就忽略 release 串）。改为：验证内核须能证明 `kernel/module/version.c` 的 `bad_version:` 仍为 `return 0`，即未以 `allow_version_mismatch=true` 构建。

---

## 8. 变更记录

| 日期 | 变更 |
| --- | --- |
| 2026-11-15 | 建立。基线 HEAD `b09cbb8`；记录阶段状态、Stage 4 的 27/4/3/4 计数、P0 明细、设备事实、技术债、已否决方案、任务队列 |
| 2026-11-15 | **P0 补采工具就绪**（`stage4: add minimal P0 device evidence collector`）：新增 `05_userspace_firmware/tools/collect_stage4_p0.sh`（手机端只读采集，无 adb）与 `README_stage4_p0.md`（aShell You 执行指南）。**U4-01 / U4-04 状态未变（仍 UNKNOWN）**，待用户执行并回传 |
| 2026-11-15 | 同轮修正 5 处 `Android 16` 过时表述（`00_reference`、`final_report`、`06_porting_design` 直接更正；`SOURCE_ACQUISITION`、`03_kbase_csf/06` 留痕加注），另 `03_kbase_csf/01` 补"其发布时的"限定。`00_reference/third_party/` 外部文档原文不改（D-014）。**技术结论未变** |
| 2026-11-15 | **U4-01 闭合 + U4-04 推进**（`stage4: close U4-01 with firmware header bytes, advance U4-04`）：用户执行 P0 补采并回传 `stage4_p0_20261115_232021.txt`。固件 header 实测 `6e 3a f1 c3 03 00 00 00` → **0.3**（[D·A]）；DDK 内含 `r49p1-03bet0`，与 kbase 同串。**计数 27/4/3/4 → 27/5/3/3**；组合 B 升为"实测否决"。新增 D-016 / D-017，D-008 由条件性生效转为生效 |
| 2026-11-15 | **U4-24 采集工具就绪 + 三处口径更正**（`stage4: add GPU module identity audit`）：新增 `05/tools/collect_gpu_module_identity.sh`（396 行）与 `README_gpu_module_identity.md`（199 行）；`05/08` 新增 §3.6（判定矩阵 / 模块集合映射 / kCFI-CRC 重导依赖分类 / 子项 a-b 拆分）。更正：①`lsmod` size 非文件大小 ②设备多 `mtk_ghpm`（仓库无）③`met_*` 未装载受筛选口径限制。**计数不变 27/5/3/3，U4-24 仍未闭合**；新增 D-018 / D-019 |
| 2026-11-16 | **U4-24 实测整合，a 闭合 / b 开放**（`stage4: close U4-24a with device module identity`）：用户回传 `stage4_mod_20261116_000412.txt`。①**18 个 `.ko` 身份全取**，vermagic 全部 `6.6.118-android15-8-g54a15cf3acba-4k`；②**确立三层内核版本**（运行 6.6.143 第三方／原厂推定 6.6.118-g54a15cf3acba／仓库基线 6.6.118-g57e634f35c1b），**推翻"设备内核 = 6.6.143"**；③**14/15 模块结构完全一致，仅 kbase 实质不同** → REA 重导范围收窄；④**~~发现内核绕过 vermagic 校验~~（已于下一轮撤回）**；⑤"`ged` 差 409 KB"作废（两侧同为 1,093,352 B）；⑥设备 GPU 文件 18 个（仓库缺 3 个）。**计数 27/5/3/3 → 27/5/4/3**；新增 D-020 / D-021 / D-022，D-007 依据改写 |
| 2026-11-16 | **Stage 4 收尾核验**（`stage4: close remaining audit items with source-level verification`）：新增 `05/09_stage4_closure.md`。**四处更正**：①**"内核绕过 `same_magic()`"撤回**——`CONFIG_MODVERSIONS` 下 release 串本就不比（v6.6 `version.c:88-96`），装载合法；②**真正的绕过开关**是 `bypass-kernel` 改 `bad_version`（默认关闭；2026-08-29→10-30 门控 `== 'true'` 恒失效），U4-25 拆 a/b/c；③**`uname -v` 的日期是补丁月常量**（`${YM}-05 04:20:00 UTC`），不能作构建时间；④**padding 强制校验实为 15 处**（原写"两处"，只读了前 20 个定义），R-C2 由"tiler 失效"上调为"GPU 不可用"。另核：R56 交付包 23 条目**0 个固件**（U4-12 属商业阻断）；`/proc/modules` taint 无 `F`。**计数 27/5/4/3 → 27/5/5/3**（U4-25 转部分闭合）；D-021 改写，新增 D-023 / D-024 / D-025 |
