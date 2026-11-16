# 第三轮真机采集证据（2026-11-16 14:12）

> 对应任务：`TASK-STAGE4-REMAINDER` 第三项（最小真机只读采集）**第三次执行后的判读**。
> 原始报告：`stage4_remainder_20261116_141236.txt`，**58,428 B / 735 行**，`SELFCHECK: 数据行数 = 632`。
> 采集脚本：`05_userspace_firmware/tools/collect_stage4_remainder.sh` **v1.2**（`SCRIPT_VERSION` 自报 `stage4-remainder v1.2`，md5 `aae2228187e44c228f86a34fb90ec5e4`）。
> 执行环境：Redmi K80 至尊版（`25060RK16C` / `dali`），`UID 0` / `SELINUX_CTX u:r:ksu:s0`，输出目录 `/sdcard/GPU_AUDIT_STAGE4`。

---

## 1. 本目录只放文本

| 文件 | 内容 |
| --- | --- |
| `README.md` | 本文件：本轮执行结果、v1.2 修复验证、三项新发现、台账影响 |
| `key_readings.md` | 十三组关键读数与判读，含**不采用**的数据 |
| `symbols/ged_versions.tsv` | ged.ko `__versions` 全量 **241** 条（symbol / crc32 / crc_hex） |
| `symbols/kbase_versions.tsv` | kbase `__versions` 全量 **513** 条 |
| `symbols/kbase_mtk_side.tsv` | kbase 中 MTK 侧 **84** 条（49 `ged_` / 16 `gpufreq_` / 4 `gpueb_` / 15 `mtk_`），带分类 |
| `symbols/README.md` | 解析方法与复现命令 |

**未入库**：原始 `stage4_remainder_*.txt`（58 KB）、`F_*_versions.txt`（135 KB / 63 KB）。
本目录**不含任何 `.ko` / `.so` / `.bin` / 固件字节**，只有解析后的文本结论与派生表。

---

## 2. v1.2 四处判读修复全部验证有效

v1.2 改的是"数据取到了但标签贴错"，因此**每一项都能在输出里看到修复前后的差别**：

| # | v1.1 缺陷 | v1.2 输出中的证据 | 结论 |
| ---: | --- | --- | :---: |
| 1 | `stat -c` 对符号链接取到链接自身长度 | J 段 `/vendor/lib64/hw/vulkan.mali.so` 打印 `symlink -> mt6991/vulkan.mali.so（以下按目标文件读取）`，`size : 133416`，与目标文件 sha256 相同 | ✅ |
| 2 | build-id 固定 `-j 12`，读到 `"GNU\0"` | D-4 打印 `note hdr : namesz=4 descsz=20 desc_off=16`，随后 `build-id : c5eac1f08ba2434defdeb72d2f4185c4a2217bb3`（20 B，与小节头自洽） | ✅ |
| 3 | `/proc/modules` 第 6 列当成 taint | E-3 表头改为 `refs / deps / state`，附说明"第 6 列是加载地址，不是 taint"；taint 单列 `tainted（全局）= 4609` | ✅ |
| 4 | 符号正则 `GLOBAL.*DEFAULT.*FUNC` 顺序反了，恒为 0 | J 段 vulkan：`GLOBAL DEFAULT FUNC: 3`、`defined (Ndx!=UND) : 1`；libgpud：`407` / `335`；libgpud_sys：`482` / `372`；libged：`179` / `100` | ✅ |

> 第 4 项尤其关键：上一轮四个库的导出符号全部报 0，本轮拿到真实值，`libgpud` / `libgpud_sys` 的对照才第一次成立。

---

## 3. 行数从 770 降到 735 —— 是合并与裁剪，不是丢数据

`SELFCHECK` 由 668 降到 632（−36）。逐段对比如下，**每一段都在、没有空段**：

| 段 | 第二轮行数 | 第三轮行数 | 差 | 原因 |
| --- | ---: | ---: | ---: | --- |
| A 环境与指纹 | 35 | 35 | 0 | — |
| B 固件 | 22 | 22 | 0 | — |
| C mount/overlay | 93 | 93 | 0 | — |
| D build-id | 25 | 26 | **+1** | 新增 `note hdr` 一行 |
| E GPU 识别 | 55 | 43 | **−12** | v1.1 的"taint 二次过滤"整段删除（该列本就是加载地址），模块表 `head -20`→`-24` 且不再打两遍 |
| F `__versions` | 47 | 47 | 0 | — |
| G OEM 扩展 | 47 | 47 | 0 | — |
| H dmesg | 76 | 76 | 0 | — |
| I debugfs | 8 | 8 | 0 | — |
| J ELF 元数据 | 194 | 171 | **−23** | 符号样本 20→15 行 × 4 个库 = −20；另有注释行调整 |
| K 属性/后端/holders | 139 | 137 | **−2** | holders 25→23（进程退出），非脚本行为 |
| Z 结束 | 15 | 16 | **+1** | SELFCHECK 提示改为两行 |
| **合计** | **770** | **735** | **−35** | — |

判读：**−36 数据行的每一行都有归属**。若哪天某段整段消失（例如 I 段从 8 行变 0 行），那才是真丢数据。

---

## 4. 三项发现（N-8 为复现与表述更正，N-9 / N-10 为新增判读）

### N-8 · 独立复现"第三方内核"既有记录，并把 U4-26 的答案写直

**先说明这不是新事实。** `05_userspace_firmware/MANIFEST.md` §1 的"三层内核版本"表（`D-020`）**早已登记**：

| 层 | 登记值 |
| --- | --- |
| 设备运行时内核 | **第三方 GKI 构建**（KernelSU 补丁；`6.6.143-android15-8-gf9aa2fec23c3-4k`，`chandr1000@SukiSU-Ultra-v41181`） |
| 原厂内核（推定） | `6.6.118-android15-8-g54a15cf3acba-4k`（由 18 个厂商 `.ko` vermagic 反推） |
| 仓库基线内核 | `6.6.118-android15-8-g57e634f35c1b-4k` |

本轮做的是**独立复现 + 补齐读数**。D-3 段 `/proc/version` 原文：

```
Linux version 6.6.143-android15-8-gf9aa2fec23c3-4k
  (chandr1000@SukiSU-Ultra-v41181)
  (Android (11368308, +pgo, +bolt, +lto, +mlgo, based on r510928) clang version 18.0.0 ...)
  #1 SMP PREEMPT Mon Oct 5 04:20:00 UTC 2026
```

| 证据 | 读数 | 此前状态 | 等级 |
| --- | --- | --- | :---: |
| 构建者/主机 | `chandr1000@SukiSU-Ultra-v41181` | 已登记于 `05/MANIFEST` §1 | **[D·A]** 本轮直读 |
| SELinux 域 | `u:r:ksu:s0` | 已登记（root） | **[D·A]** |
| root 痕迹 | `/data/adb/ksu`、`/data/adb/modules` `EXISTS`；`/data/adb/susfs`、`/sbin/.magisk` **`ABSENT`** | 未排除 SUSFS / Magisk | **[D·A]** 新增判别 |
| 全局 taint | `4609` = `0x1201` = bit0 **P** + bit9 **W** + bit12 **O**（**无** bit13） | 此前只有"无 `F`" | **[D·A]** 新增位解码 |

**需要更正的只是台账表述**：U4-26 原写"已闭合（设备侧）——build-id 已取；与 CI 产物比对未做"。既然内核来源早有登记，答案本应是"否"，而不是"待比对"。本轮把答案写直：**否**。状态仍 CLOSED（问句已答），见 `D-036`。

**四条推论（引用设备数据时必须带上）**：

1. 本轮回传的全部 `[D·A]` / `[D·B]` 证据，来自 **root + 第三方内核**环境，**不能直接代表未 root 零售机**的可观测面。
2. `/vendor`、`/vendor_dlkm` 仍是原厂 `erofs` 只读分区（U4-27，`mountinfo` 无 overlay 条目）→ **`kbase.ko` 与固件文件本体未被替换**，这部分证据仍然有效。
3. 内核被重编，但 `kbase.ko`（原厂 `vendor_dlkm` 文件）能加载并 `state=Live`、`refs=91`，且 dmesg 全程无 `disagrees about version of symbol`（H-4 `COUNT: 0`）→ 该内核导出符号的 **modversions CRC 与 `kbase.ko` 的 `__versions` 期望一致**，否则模块装不上。这条把 H-4 的"0 条"从"无信息的阴性"升级为"加载成功的弱旁证"。
4. `tainted` 非 0 **不是**本项目动作造成的（本轮无任何写入/装载），而是 OEM 私有+树外模块的固有结果；`bit12 = O` 与 OEM `kbase`/`ged` 的存在吻合，**不要**读成"unsigned module"（本机无 bit13）。

### N-9 · `/proc/modules` 的 `deps` 列方向搞反会得出相反结论

v1.2 输出里 `ged` 行的 `deps` 含 `mali_kbase_mt6991_r49`：

```
ged   size=684032  refs=5  deps=mtk_mbraink_v6991,...,mali_kbase_mt6991_r49,...  state=Live
```

**若把 `deps` 读成"本模块依赖谁"**，就会得出"`ged` 依赖 `kbase`"，进而推翻上一轮"`ged.ko` 零 import `kbase` 符号"的结论。

**实测 `__versions` 的答案是反的**：`ged.ko` 的 241 条 import 里，含 `kbase` 的 **0 条**；反之 `kbase` 的 513 条里有 **84 条**是 MTK 侧符号（49 `ged_*`、16 `gpufreq_*`、4 `gpueb_*`、15 `mtk_*`）。即 **`kbase` 是消费者，`ged` 是被消费者**。

`deps` 列列的是**反向依赖（谁在用我）**，四条自洽验证：

| 行 | `deps` 列含 | 按"谁在用我"解释 | 是否成立 |
| --- | --- | --- | :---: |
| `ged` | `mali_kbase_mt6991_r49` | kbase 使用 ged | ✅ 与 49 条 `ged_*` 导入一致 |
| `mtk_gpu_pdma_mt6991` | `mali_kbase_mt6991_r49` | kbase 使用 pdma | ✅ |
| `mtk_gpufreq_wrapper` | `mali_kbase_mt6991_r49` | kbase 使用 wrapper（16 条 `gpufreq_*`） | ✅ |
| `mali_kbase_mt6991_r49` | `-`（空） | 没有模块使用 kbase 的符号 | ✅ 与 ged 零 `kbase_*` 导入一致 |

结论：**kbase 是叶子消费者**，它向 MTK 侧要 84 个符号，而 MTK 侧不向它要任何一个。这对 U4-22（`libged` 失效的降级程度）是**依赖面定量**：`kbase.ko` 对 `ged`/`gpufreq`/`gpueb` 存在**符号级硬依赖**，缺一个都装不上。

### N-10 · HWUI 走 Vulkan 与 SF RenderEngine 走 GLES 是两条独立路径

同一份报告里两条看似矛盾的读数，实际不矛盾：

| 读数 | 位置 | 含义 |
| --- | --- | --- |
| `ro.hwui.use_vulkan = true` | K-1b | **App 层 HWUI** 配置为优先 Vulkan |
| `------------RE GLES (Ganesh)------------` | K-3 | **SurfaceFlinger 的 RenderEngine** 用 GLES(Ganesh) |

判读：`U4-20` 的问句是"**SF RenderEngine 后端**"，答案是 GLES(Ganesh)，**不受 `ro.hwui.use_vulkan` 影响**。不要把后者读成"系统整体走 Vulkan"，也不要用它去推翻 U4-20。

同时 `vulkan.mali.so` 仍是 133,416 B 的桩（`defined = 1`，只有 24 B 的 `mali_vk_vendor_stub`，`DT_NEEDED` 首项 `libGLES_mali.so`）→ 即使 HWUI 走 Vulkan，最终仍落到 `libGLES_mali.so`。**REA 的目标库不变：`libGLES_mali.so`（约 53 MB），不是 `vulkan.mali.so`。**

---

## 5. 台账影响

| ID | 本轮前 | 本轮后 | 依据 |
| --- | :---: | :---: | --- |
| **U4-22** | ○ OPEN | ⚠️ **PARTIAL** | 子项 a（依赖面）已定量闭合：`kbase` 84 条 MTK 侧导入 + `HWC`/`mapper` 的 `NEEDED libged`；子项 b（真实失效表现）仍未观察 → 按 `D-033` 记 PARTIAL |
| **U4-26** | ✅ CLOSED | ✅ **CLOSED（结论改写）** | 问题"设备 boot 是否即 CI 产物"已答：**否**——内核为 SukiSU 重编（N-8），`vendor` 分区仍原厂 erofs。答案由"是"改为"否"，见 `D-036` |

其余 25 项**状态不变**。五态：**8 / 13 / 1 / 5**（CLOSED / PARTIAL / BLOCKED / OPEN），合计 27 ✓。

**P0 仍是 3 项（U4-04 / U4-10 / U4-12），一项未动。** 第三轮拿到的全部是静态事实，P0 要的是 padding 字节、故障表现、商业固件——只读采集触及不到。

---

## 6. 边界声明

- 本轮**未执行**采集脚本本身以外的任何设备命令；判读全部在审计侧离线完成。
- **未修改**任何驱动源码；**未编译**；**未刷机**；**未替换**任何 `.ko` / 固件 / GLES / Vulkan 库；**未做故障注入**；**未进入 Stage 5A/5B**。
- 报告中的 `tainted`、`SukiSU` 等环境事实是**读出来的**，不是本项目造成的状态变更。
- 任何以本轮数据为依据的 Stage 5 设计，必须先声明"设备为 root + 第三方内核"这一前提。
