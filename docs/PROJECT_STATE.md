# PROJECT_STATE — 项目长期状态

> **这是每个新 Agent 会话的首要恢复入口。**
> 本文件描述**当前有效状态**；历史快照与已被推翻的结论见各目录 `README.md` / `MANIFEST.md` 的历史段与 `docs/DECISION_LOG.md`。
> 任何与本文件冲突的对话记忆或 commit 标题，以本文件 + 仓库实测为准；若发现本文件与实测不符，**先修本文件**。

| 项 | 值 |
| --- | --- |
| 最后更新 | 2026-11-16 07:30（GMT+8） |
| 更新提交 | `stage4: correct DDK route to R49-derived and re-audit remaining items`（本轮） |
| 提交前基准 HEAD | `bbaeaf2416c49b451fdada707bfd9d95bdd758aa`（`stage4: finalize stage 4 with full-state ledger and DDK dual-track assessment`） |
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
| **Stage 4** | 用户态与固件 ABI | ✅ **已交付**（9 份 + `06/` 五份收尾/纠偏台账） | ⚠️ **收尾完成，未闭环**：27 项 = CLOSED 5 / PARTIAL 8 / BLOCKED 1 / OPEN 13；**P0 3 项** |
| Stage 5 | 方案设计与可行性结论 | ⏳ 未开始 | — |

**"报告已交付"与"证据已闭环"是两种状态，不可互相替代。**

---

## 3. Stage 4 当前状态

### 3.1 计数（与 `05_userspace_firmware/06_abi_compatibility_matrix.md` §7 及 `05/MANIFEST.md` §6.1 一致）

| 项 | 数量 |
| --- | --- |
| 总数 | **27** |
| ✅ CLOSED | **5**（U4-01 / U4-03 / U4-05 / U4-08 / U4-09） |
| ⚠️ PARTIAL | **8**（U4-04 / U4-06 / U4-07 / **U4-10** / **U4-14** / **U4-15** / U4-24 / U4-25） |
| ⛔ BLOCKED | **1**（**U4-12**） |
| ○ OPEN | **13** |
| ? UNKNOWN | **0** |
| **P0** | **3**（U4-04 / U4-10 / U4-12） |

> **本轮变化（2026-11-16 TASK-STAGE4-REMAINDER）**：五态判定规则统一为"**有子项闭 + 有子项开 = PARTIAL**"（`D-033`），据此 **U4-14 与 U4-15 由 OPEN 转 PARTIAL**（二者的子项 a 本轮闭合：删除清单独立复现 / 新增 props 与缓冲增量定量）。计数 **5/6/1/15 → 5/8/1/13**。总数 27、**P0 仍 3**。
>
> 上一轮（TASK-STAGE4-FINAL）的变化：改用五态；PARTIAL 5 → 6（U4-10 由 OPEN 转入）；U4-12 单列 BLOCKED；U4-04 拆 a/b/c，b 闭合。

### 3.2 P0 明细

| ID | 内容 | 当前证据 | 闭合方式 |
| --- | --- | --- | --- |
| ~~U4-01~~ | ~~原厂 CSF 固件 header 实际字节~~ | ✅ **已闭合 [D·A]**：`6e 3a f1 c3 03 00 00 00` → `offset 4 = 0x03` / `offset 5 = 0x00` → **0.3** | 2026-11-15 23:20 `od` 读数（`05/07` §4.5、`05/02` §3.0.5） |
| **U4-04** | 原厂 DDK 的 UK ABI / padding 是否清零 / props 是否严格校验 | **三子项**：**a ✅** 版本代次 `r49p1-03bet0` → UK 1.30 **[D·A]**；**b ✅** 结构体布局无实质差异（51 个共同结构体、实质差异 0）**[E1]**；**c ⚠️ 收窄**：15 个 R56 强制项中 **3 已证满足 / 4 结构上不用 / 8 待证**，剩余致命位 = `CS_QUEUE_REGISTER`（`D-031`） | 需 DDK 源码或反汇编看 `CS_QUEUE_REGISTER` 等 4 处的栈初始化 |
| **U4-10** | GPU 初始化失败后是否 bootloop | ⚠️ **PARTIAL**：**静态已排除启动阻断**——CSF 固件在首次 `open()` 加载、probe 不涉及，失败只让 `open` 返回错误，可重试；R49/R56 同构 **[E1]** | 故障注入（需可回滚环境，本轮禁止） |
| **U4-12** | R56p0 固件是否匹配 G925 MC12 | ⛔ **BLOCKED**：R56 交付包 23 条目中 `firmware`/`.bin`/`ddk`/`csffw`/`libGLES`/`vulkan` 命中 **0** → 属商业授权件 **[E1]**。验收判据已扩至 6 条（含 GLB ≥ 1.1.0、entry 布局） | 取得固件后按 `06/STAGE4_REMAINING_AUDIT.md` §3.3 六项判据验收 |

### 3.3 来源审计新增项（**不是 P0**）

| ID | 内容 | 优先级 | 现有证据 |
| --- | --- | --- | --- |
| U4-24 | 设备侧 GPU `.ko` 的**路径 / 文件大小 / SHA256 / vermagic / srcversion**（a）／**`__ksymtab` CRC 与 kCFI 常量**（b） | **P1** | **a ✅ 已闭合**（18 个文件，`05/07` §3.5）；**b 开放**，范围收窄至 kbase（`05/08` §3.7.6） |
| **U4-14** | DDK 是否使用 R56 已删除的 ioctl | **P1** | ⚠️ **PARTIAL（本轮）**：子项 a ✅ 删除清单**独立复现**（生产 ioctl **54 → 50**，删 6 增 2）；**ioctl 55 在 CSF 硬件上本就是 no-op**（`limited_core_mask` 只被 JM 后端读）；**ioctl 80 在 OEM 构建里已启用**（`strings` 命中 `Internal fence wait`）。子项 b（DDK 是否调用）仍 OPEN |
| U4-15 | DDK 对 props 新增 ID 的处理 | **P1** | ⚠️ **PARTIAL（本轮）**：子项 a ✅ **83 共同 + 3 新增**（`RAW_BASE_PRESENT`/`RAW_NEURAL_PRESENT`/`NUM_ACTIVE_GRANULARITY`），序列化缓冲 **749 → 781 B（+32）**，线上格式为 TLV（`D-032`）；子项 b（DDK 是否 `size=0` 探测）仍 OPEN |
| U4-25 | 第三方内核与原厂 boot 的运行时差异范围（含 `check_version` 是否也被绕过） | **P1** | **25a ✅ 闭合**：vermagic 串不符是 `CONFIG_MODVERSIONS` 的原生语义（`same_magic` 忽略 release 串），**不存在也不需要**绕过 **[E1]**；**25b 开放**：真正的开关是 `bypass-kernel` 改 `bad_version`，默认关闭、2026-08-29→10-30 门控恒失效，且该补丁在 CRC 匹配时无行为差异 → **运行态不可观测**；25c 未测 |
| U4-26 | 设备当前 boot 是否即所链接 CI run 的产物 | P2 | **判据已更换**：`uname -v` 的日期是 `os_patch_level` 派生**常量**（`${YM}-05 04:20:00 UTC`），零信息量 **[E1]**；四项参数一致但不足以定论；缺内核 `build-id` |
| U4-27 | `/vendor` 当前视图是否被 KSU/NoMount overlay 覆盖 | P2 | 未采 mount 表 |

> 优先级分布（27 = 3 P0 + 8 P1 + 8 P2 + 3 P3 + 5 已闭合不计级）：P1 = U4-02 / U4-11 / U4-14 / U4-15 / U4-17 / U4-22 / U4-24 / U4-25；P2 = U4-06 / U4-07 / U4-16 / U4-19 / U4-20 / U4-21 / U4-26 / U4-27；P3 = U4-13 / U4-18 / U4-23。

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
| **R49 与 R56 的 UAPI 结构体：51 个共同定义、实质差异 0** | **[E1]** | `mem_sync` 仅字段重命名；CSG 的 112→120 扩展由 `_1_35` 兼容变体 + 逐字段迁移吸收（`05/09` §11.1） |
| **R56 为 1.0–1.39 全段保留语义路径**：握手 `min()` 无下限；`caps` 表按 `api_version >= required` 降级 | **[E1]** | 这是 R49 DDK（1.30）能工作的**机制性**原因，不是巧合（`06/DDK_DUAL_TRACK_ASSESSMENT.md` §1） |
| **CSF 固件在首次 `open()` 加载，不在 probe** | **[E1]** | 固件缺失 → `open` 失败，**不阻断启动**、可重试；R49/R56 同构（`05/09` §11.3） |
| **R56 删除 6 个 ioctl**，含 MTK 私有 `INTERNAL_FENCE_WAIT`（80） | **[E1]** | 80 仅用于 internal fence 超时上报与（可选）自愈 reset，**不在渲染主路径**（`05/09` §11.2） |
| **R49 kbase 内联校验 padding（9 处）** | **[E1]** | 含 `MEM_JIT_INIT`、现版 CSG create 的 `padding[9]`（offset 40–111）、`READ_USER_PAGE`、KCPU 命令；集中式 helper 头是 R50+ 才有的，但**校验本身在 R49 就存在**（`D-031`） |
| **R56 的 CSG create padding 检查是 R49 所查范围的子集** | **[E1]+[D·B] → [E2]** | R56 查 offset 50–111，R49 查 40–111；设备可渲染 ⇒ R49 DDK 填了全 0 ⇒ **R56 这一关必过** |
| **R49 已完整支持 `tKRx`（G925）** | **[E1]** | `base_hw_features_tKRx[]` 与 R56 **逐项相同**；`base_hw_issues_tKRx_r0p0[]` 差 3 项（−`TURSEHW_2716`，+`KRAKEHW_2348`、`MAGNIHW_2257`），且全在 kbase 侧 |
| **ioctl 集合 54（R49）→ 50（R56）** | **[E1]** | 删 6 增 2（`CS_QUEUE_GROUP_CREATE_1_35` 是原编码改名、`CS_TILER_HEAP_SIZE` 是真新增）；此前写"55 个"不准确 |
| **ioctl 55 在 CSF 硬件上是 no-op** | **[E1]** | `kctx->limited_core_mask` 的唯一消费者是 `backend/gpu/mali_kbase_jm_hw.c`（JM 后端）；`csf/` 内零引用 |
| **GPU props：83 共同 + 3 新增；缓冲 749 → 781 B** | **[E1]** | 线上格式是 TLV（`u32 id` + `u8 type_size` + 值），不是结构体直拷；"568/592"是 `sizeof` 人工推算（`D-032`） |
| **OEM 构建启用了 `CONFIG_MALI_MTK_FENCE_DEBUG`** | **[E1]** | 仓库基线 `mali_kbase_mt6991_r49.ko` 内含 `Internal fence wait timeouts…` 与 `ged_mali_event_notify_fence_timeout_event`；设备构建未直接验证（可由 `strings` 一条命令复核） |

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
13. **设备上只有 R49 DDK 的编译产物，没有源码**。`libGLES_mali.so`（53,105,232 B）与 `vulkan.mali.so`（133,416 B）都是二进制；仓库 `01_original_baseline/` 里的 `mali-r49p1` **只是 kbase 内核驱动源码**（`drivers/gpu/arm/midgard/`）。任何"从手机提取 DDK 源码"的表述都不成立（`D-030`）。
14. **R49 kbase 已经完整支持 `tKRx`（= G925）**：`base_hw_features_tKRx[]` 与 R56 **逐项相同**。所以"R56 才支持 G925"是错的；只有早于 2024-05 的版本（如 R46）才没有。`gpuinfo` sysfs 会打印 `Mali-G925-Immortalis 12 cores r0p0 0x…`，是一条可直接复核的只读命令。
15. **R49 kbase 的 import 面已量化**（2026-11-16 实测）：513 条符号 + CRC32，其中 **84 条**指向 MTK 平台模块（`ged_*` 49 / `gpufreq_*` 16 / `gpueb_*`+`wait_gpueb` 4 / `mtk_*` 15）。`ged.ko` **不** import 任何 kbase 符号，`module_layout` CRC 两模块同为 `0x4e276f37`。见 `05/evidence/stage4_round1_20261116/`。
16. **`CONFIG_MALI_MTK_FENCE_DEBUG` 在设备构建上确证为开**：`/vendor_dlkm/lib/modules/mali_kbase_mt6991_r49.ko` 上 `Internal fence wait`=1、`Internal fence timeouts`=4、`ged_mali_event_notify_fence_timeout_event`=2。**ioctl 80 在 OEM 栈上确实可达**（`D-025` / `D-031` 的 [E1] 推理升为 [D·A]）。


---

## 5. 已知技术债与派生影响

### 5.1 固件判据（**已闭合**）

源码判据（[E1]）与实测判据（[D·A]）现已一致：r49p1 要 0.3、r56p0 要 0.4、**原厂实测 0.3**。组合 B 的否决有字节支撑，不再需要"推理支持"这类限定语。

> 遗留的相邻缺口：`U4-11`（GLB 运行时版本）与 `U4-12`（R56p0 固件是否匹配 G925）仍未闭合，二者与 header 版本是**不同问题**。

### 5.2 用户态契约 ≠ 实现

`03_gles_egl_abi.md` 的全部"兼容"结论都在 UAPI 契约层。`min()` 是**夹取**（取较小值），不是"校验"。DDK 版本代次已知（`r49p1-03bet0` → 1.30），但 **padding 清零 / props 协商行为仍未知**（U4-04 剩余子项）。

> **2026-11-16 风险上调（D-025）**：padding **不是**"Arm 全替你清零"的软门槛。全量重算：48 个 `check_padding_*` 中 **28 空 / 5 清零 / 15 强制**，强制集包含 `CS_QUEUE_REGISTER`、`CS_QUEUE_REGISTER_EX`、`CS_QUEUE_GROUP_CREATE_1_6|_1_18|_1_35`、`CS_QUEUE_GROUP_TERMINATE`、`CS_TILER_HEAP_INIT(_1_13)`。**若 1.30 DDK 不清零，GPU 不是降级而是完全不可用**。这是组合 C 的单点致命项。**注意**：判定成本**不低**——`strace` 只能确认调用与请求号，**不能读出 padding 字节**；定性需 R49 DDK 源码或反汇编（`06/STAGE4_DEVICE_COLLECTION_PLAN.md` §6）。2026-11-16 复核后未知面已收窄至 4 条（`D-031`）。
>
> **2026-11-16 二次修正（D-026，风险下调）**：上面这条"单点致命"的前提是"DDK 与 R56 的结构体布局不一致"。实测**不成立**——51 个共同结构体实质差异 0，且 R56 对旧版本做了逐字段迁移（`05/09` §11.1）。加上 R49 的 UAPI 明文写 `padding: must be zero`，风险应改为 **"设计上已被覆盖，仅剩实现规范性问题"**，等级由 **P0 致命**下调为 **中**。**但 U4-04c 仍不闭合**——R49 kbase 本身不校验 padding（没有 `mali_kbase_ioctl_helpers.h`），所以"R49 上能跑"不能反推"清零"。
>
> **2026-11-16 三次修正（D-031，未知面收窄）**：上一段的最后一句**有一半是错的**。R49 **确实没有** `mali_kbase_ioctl_helpers.h`，但**校验代码以展开形式存在 9 处**——包括 `MEM_JIT_INIT`、**现版 CSG create 的 `padding[9]`（offset 40–111，是 R56 所查 50–111 的超集）**、`READ_USER_PAGE`、KCPU 命令等。因此 15 个强制项中 **3 项已被设备行为证明满足、4 项结构上不用**，**剩余致命位只有 `CS_QUEUE_REGISTER`（以及可能被选用的 `_EX` / `CS_TILER_HEAP_INIT(_1_13)` / `MEM_ALLOC_EX`）**。风险等级不变（中），但 U4-04c **仍不闭合**。

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
| 16 | ~~**DDK-B：R56 Kbase + R46 DDK**（第一版写的"降级路线"）~~ | **已被用户最新路线决策取代**（`D-030`） | 第一版三条理由中，①"不解除固件阻断"**对 R49 同样成立**；②"G925 时间线矛盾"与 ③"CSG size 落点未知"是 **R46 特有**，**不适用于 R49**（R49 的 `tKRx` features 与 R56 逐项相同、CSG 落点已知为 nr 58/112 B）。保留此行仅为留痕 |
| 17 | "R46 与 R56 版本接近所以兼容" | **禁止表述** | 跨代组合从未在任何平台验证；`_1_35` 的存在恰恰证明"接近"需要专门写迁移代码。**R46 已退出备选路线**，此条降为一般性禁止表述 |
| 18 | **"R49 kbase 不校验 padding"** | **证伪**（`D-031`） | R49 有 9 处内联校验（含 CSG create 的 `padding[9]` 全量）。集中式 helper 头是 R50+ 才有，**但校验本身早就在** |
| 19 | "属性 ID 83/83 不变" | **证伪**（`D-032`） | **83 共同 + 3 新增**（86/87/88），无删除；序列化缓冲 **749 → 781 B** |
| 20 | "props 缓冲区 568 → 592" | **口径错误**（`D-032`） | 那是 `sizeof(gpu_props_user_data)` 的人工推算（未经编译）；线上格式是 TLV，长度 749 → 781 |
| 21 | **"R49 DDK 源码可以从手机提取"** | **不成立**（`D-030`） | 手机只有编译产物（`libGLES_mali.so`）；源码只能来自 Arm/MTK 授权交付。仓库 `01_original_baseline/` 只有 **kbase 内核驱动源码** |
| 22 | "R56 才支持 G925 / 旧版本都没有 `tKRx`" | **禁止**（`D-030`） | R49 **已完整支持 `tKRx`**（features 完全相同）；只有 R46 这类早于 G925 发布的版本才没有 |

---

## 7. 下一步任务队列（按优先级）

| # | 任务 | 目标 | 风险 |
| ---: | --- | --- | --- |
| 1 | ~~建立并验证长期上下文规范~~ | 让状态可从仓库恢复 | ✅ 完成（`0c1d1dd`） |
| 2 | ~~闭合 U4-01 + 推进 U4-04~~ | 组合 B 判定升为实测；组合 C 前提落地 | ✅ **完成（`65006de` 工具 + 用户执行 + 本轮整合）** |
| 3 | ~~评估 U4-24 设备侧模块身份采集是否必要~~ | 决定 Stage 3 常量是否必须重导 | ✅ 完成（`b1da0b9`） |
| 4 | ~~执行 U4-24a 并整合~~ | 设备 `.ko` 身份落地 | ✅ **完成（`b1da0b9` 工具 + 用户执行 + 本轮整合）** |
| 4b | **U4-24b 单样本比对**：设备端 `readelf -x __versions` 取 `ged.ko`（抽样）+ `mali_kbase_mt6991_r49.ko`（必取） | 判定 14 个模块的 CRC 能否整体沿用；kbase 必须单独重导 | 无（只读，纯文本） |
| 4c | **U4-14 的调用面**：需 `strace` 看 ioctl 请求号（**不是**看 padding） | 确认 R49 DDK 是否调用 R56 已删的 8/12/32/35/55/80 | 低（root，只读；另见下条"更低成本替代"） |
| 4d | ~~U4-04c 定性：一条 `strace` 看 padding 字节~~ | ❌ **方法作废**：`strace` 只解出 `_IOC(type,nr,size)`，**看不到结构体内容**（`06/STAGE4_DEVICE_COLLECTION_PLAN.md` §6） | — |
| 4e | **U4-14 的最低成本替代（优先做）**：设备端 `strings mali_kbase_mt6991_r49.ko \| grep -c "Internal fence wait"` | 直接判定 ioctl 80 在**设备构建**上是否可达 → 若不可达，DDK 必然已容忍 `-ENOIOCTLCMD` | 无（一条命令） |
| 5 | ~~处理 U4-25 / U4-26 / U4-27~~ | 界定第三方内核差异面与 vendor 视图真实性 | ✅ 复核完成：25a 闭合、25b 判据明确；26 判据更换；27 仍缺 mount 表 |
| 6 | **执行合并后的只读采集**（待用户授权）：`05_userspace_firmware/tools/collect_stage4_remainder.sh` | 一次覆盖 U4-02/06/11/14/17/20/21/23/24b/25b/26/27 | 低（root，只读，输出到 `/sdcard/GPU_AUDIT_STAGE4/`） |
| 7 | U4-12：取得 R56 固件（商业交付件） | 按 `06/STAGE4_REMAINING_AUDIT.md` §3.3 **六项**判据验收 | **阻断**（资产不在手） |
| 8 | U4-04c 残留（`CS_QUEUE_REGISTER` 等 4 处） | 需 R49 DDK **源码**（优先）或离线反汇编 `libGLES_mali.so`（次选） | 中（源码/资产） |
| 9 | **Stage 4 证据充分后**，再决定是否进入 Stage 5 | 设计 vs 定论分离 | — |

### 7.1 Stage 5 准入判定

| 层面 | 判定 | 依据 |
| --- | --- | --- |
| 开始 Stage 5A 的**设计** | **可以**（需用户明确授权） | 5A 硬前置 0 项；2 项可带条件进入（`06/STAGE5_PREREQUISITES.md` §2） |
| 给出**可行性定论** | **仍不可以** | U4-04c 未闭合、U4-12 BLOCKED |
| 开始 **Stage 5B（实施）** | **不可以** | 4 项硬前置 P-1～P-4 全未满足（`06/STAGE5_PREREQUISITES.md` §1） |

> **Stage 5 当前不允许自动启动。** 必须由用户显式授权；且 **Stage 5A 通过 ≠ 允许实施**（`D-011`）。
>
> **与上一版相比的变化**：U4-01 闭合使"设计层"的条件从"可双分支展开"变为"单分支"——固件必须换，没有"也许 0.4 能用"的余地。
>
> **本版（TASK-STAGE4-REMAINDER）修改的一条约束**：
>
> 2. **DDK 路线已定为"首选 + 备用"两档**：DDK-A = 完整 R56（**首选**）；DDK-B = **R56 Kbase + R49-derived compatibility DDK**（**备用**，且**必须标注为兼容移植方案**）。**R46 已退出备选**（`D-030`）；两条路线**都必须单独解决** header 0.4 / G925 MC12 的 R56 固件。
>
> **以下两条沿用上一版**：
>
> 1. **验证环境的判据再放宽**：不必查构建输入——只要装载后 `dmesg` 无 `disagrees about version of symbol`，则"补丁是否打过"对本项目结论**无影响**（`06/STAGE4_FINAL_REPORT.md` §4.5）。
> 3. **9 条未验证假设禁止带入下一阶段**（`06/STAGE5_PREREQUISITES.md` §5）。

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
| 2026-11-16 | **Stage 4 全量收尾 + DDK 双路线评估**（`stage4: finalize stage 4 with full-state ledger and DDK dual-track assessment`）：新增 `06/STAGE4_FINAL_REPORT.md`（27 项五态台账 + 风险登记 + 验收结论 **B**）、`06/DDK_DUAL_TRACK_ASSESSMENT.md`（DDK-A/DDK-B 11 行决策矩阵，推荐 DDK-A、否决 DDK-B）、`06/STAGE5_PREREQUISITES.md`（4 项硬前置 / 2 项带条件 / 9 条禁带假设）；`05/09` 追加 §11。**三条新证据**：①**UAPI 结构体 51 个共同定义、实质差异 0** → U4-04b **闭合**；②**R56 删 6 个 ioctl**（含 MTK 私有 80）→ U4-14 精确化；③**固件在首次 `open()` 加载、不在 probe**（R49/R56 同构）→ **U4-10 转 PARTIAL**。**计数 27/5/5/3 → 27/5/6/1/15**（五态）；新增 D-026 / D-027 / D-028 / D-029 |
| 2026-11-16 | **Stage 4 剩余取证与路线纠偏**（`stage4: correct DDK route to R49-derived and re-audit remaining items`）：新增 `06/STAGE4_REMAINING_AUDIT.md`（27 项逐项重核 + 7 条更正留痕）、`06/R49_DDK_ADAPTATION_PLAN.md`（**17 节**预研框架 §0–§17，逐项 CONFIRMED/LIKELY/UNKNOWN/BLOCKED）、`06/STAGE4_DEVICE_COLLECTION_PLAN.md`（11 段合并只读采集方案）、`05/tools/collect_stage4_remainder.sh`（464 行，`NOT_AVAILABLE` 容错）。`06/DDK_DUAL_TRACK_ASSESSMENT.md` **重写第 2 版**：DDK-B 由 **R46** 更正为 **R49-derived compatibility DDK**（R46 移入 §4 留痕）。**五条实质发现**：①**R49 kbase 内联校验 padding（9 处）**，含现版 CSG create 的 `padding[9]`（40–111，是 R56 检查范围的超集）→ U4-04c 未知面 **15 → 4**；②props 实为 **83 共同 + 3 新增**、序列化缓冲 **749 → 781 B**；③ioctl 集合 **54 → 50**，且 **ioctl 55 在 CSF 上是 no-op**；④**R49 已完整支持 `tKRx`**（features 与 R56 逐项相同，issues 差 3 项且全在 kbase 侧）；⑤OEM 构建**已启用** `CONFIG_MALI_MTK_FENCE_DEBUG`（`strings` 证据）。**计数 5/6/1/15 → 5/8/1/13**（U4-14、U4-15 转 PARTIAL，`D-033`）；新增 **D-030～D-033**，D-028 路线部分被取代 |
| 2026-11-16 | **第一轮真机采集回传 + 脚本修复**（`stage4: fix collector output channel and ingest round-1 device evidence`）：用户执行 `collect_stage4_remainder.sh` **v1.0** 并回传 `GPU_AUDIT_STAGE4.zip`。①**发现脚本输出缺陷**：`say()` 落盘但 43 处原始命令管道只写 stdout → 回传文件只有计数层；**v1.1** 改为 `main 2>&1 | tee -a` 单通道，本机 `diff` 验证 0 行差，新增 `SELFCHECK`。②**新增证据目录** `05/evidence/stage4_round1_20261116/`：kbase **513** 条 / ged **241** 条 import 符号 + CRC32，其中 **84** 条为 MTK 侧符号 → DDK-B 的接口面首次量化到符号级。③**三条实测结论**：GPU = `Mali-G925-Immortalis 12 cores r0p1 0x0D080300`；`CONFIG_MALI_MTK_FENCE_DEBUG` 在**设备构建**上确证为开（`Internal fence wait`=1）→ U4-14 可行性子项由 [E1] 升 [D·A]；`ged.ko` 零 import kbase 符号（Stage 3 定理实测复核）。④**计数不变 27/5/8/1/13**；U4-24b 仅闭 CRC 一半（kCFI 未采）。需重跑 v1.1 补 B/D/H/J/K/C 六段 |
