# 源码完整性与来源核验（Stage 1-A）

> 项目：K80U_GPU_R56_AUDIT — Redmi K80 至尊版（25060RK16C）/ MT6991 / Immortalis-G925 MC12 / Android 16 / Linux 6.6
> 核验日期：2026-11-15
> 核验性质：**只读**。本轮未下载任何新源码、未修改任何文件、未编译、未部署、未连接设备。
> 结论强度标记：`[实证]` 有命令输出可复现；`[推断]` 由多项实证推出；`[UNKNOWN]` 当前证据不足。

---

## 0. 结论摘要

| # | 结论 | 强度 |
| --- | --- | --- |
| 1 | **出厂 GPU 驱动源码已完整取得**：`mali-r49p1` 的 `MALI_RELEASE_NAME` 为 `r49p1-03bet0`，与出厂 `mali_kbase_mt6991_r49.ko` 内的 `K:r49p1-03bet0(GPL)` 逐字符一致 | `[实证]` |
| 2 | 主内核树 `bsp-dali-v-oss` 是**完整 Linux 6.6 源码树**（6.6.56，82,279 个文件），但**不含任何 GPU 驱动**（kbase/csf/ged/gpueb/gpufreq 命中数均为 0） | `[实证]` |
| 3 | GPU 驱动被**完全拆分**到两个外部模块仓库，主树与模块仓库存在明确的版本对应关系 | `[实证]` |
| 4 | 存在**两套 r49p1**：`03bet0`（随设备出货）与 `00dev0`（开发版，未出货）。二者 UAPI 头完全相同、驱动主体不同 | `[实证]` |
| 5 | 内核树为 `android15-6.6` 世代（`KMI_GENERATION=8`），与出品 `.ko` 的 vermagic `android15-8` 吻合；但**目标 Android 16 对应的开源树不存在** | `[实证]` + `[UNKNOWN]` |
| 6 | 内核子版本 6.6.56 相对出厂构建 6.6.118 **落后 62 个 patch**，开源树不是出厂内核的精确同点快照 | `[实证]` |
| 7 | 所有仓库**无 Git LFS 对象、无子模块**，不存在"LFS 文件缺失 / 子模块未初始化"问题 | `[实证]` |
| 8 | `kernel_devicetree` 仓库**不覆盖 dali/MT6991**（70 个分支无一匹配），本轮未拉取 | `[实证]` |
| 9 | 用户态 DDK（`libGLES_mali.so` 等）与 CSF 固件（`mali_csffw.bin`）**在任何已获取仓库中均不存在** | `[实证]` |
| 10 | `MTK_kernel_modules` 本地为 tarball 形态（非 git），无法用 git 校验，仅有 URL + SHA256 作为来源凭据 | `[实证]`，校验强度受限 |

---

## 1. 仓库清单总表

| # | 仓库 | 分支 | commit | 本地路径 | 形态 | 清单文件数 | 本地体积 | 完整性 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R1 | `MiCode/Xiaomi_Kernel_OpenSource` | `bsp-dali-v-oss` | `f089d58cab670dc0d75db1203fa63850e57a940d` | `01_original_baseline/kernel_src_dali` | git（shallow+blobless） | 82,279 | 2.9 MB | 树完整，blob 按需 |
| R2 | `MiCode/MTK_kernel_modules` | `bsp-dali-v-oss` | `fe0fa7ff68a2de0dec7ce1a04f5db6f07fd4a3b9` | `01_original_baseline/mtk_kernel_modules` | **tarball 解出**（非 git） | 18,094（仓库）<br>581（已解出） | 8.3 MB | 仓库级未全量落地 |
| R3 | `MiCode/MTK_kernel_device_modules` | `bsp-dali-v-oss` | `e45c3199537fbba9aae5fb06c31fc8dbd3c1dcee` | `01_original_baseline/kernel_dev_modules_dali` | git（shallow+blobless） | 11,619 | 672 KB | 树完整，blob 按需 |
| R4 | `MiCode/kernel_devicetree` | — | — | **未拉取** | — | — | — | 无 dali 分支 |
| R5 | `xiaomi-mt6991-devs/android_device_xiaomi_dali-kernel` | `lineage-23.2` | `057642643c9ff9ecd75d2442ca6be9766ece90d1` | `01_original_baseline/kernel_ref_mt6991` | **tarball 子集** | 1,585（仓库）<br>21（已落盘） | 4.5 MB | 子集，清单完整 |
| R6 | Arm Mali R56p0 DDK | —（无分支概念） | `r56p0-18eac0` | `02_r56_source/mali_r56p0` | **官方 tar.gz 原件** | 454 | 6.5 MB | 完整且哈希校验通过 |

参考件（非本阶段核验范围，仅列出）：

| # | 来源 | 标识 | 本地路径 | 覆盖度 |
| --- | --- | --- | --- | --- |
| R7 | `zenithblue-oss/panvk-kbase-android` | `main` @ `cf70e02b918e1864cbcd746a7fefa57b96c673ce` | `00_reference/third_party/panvk-kbase-android` | 33 文件 / 450.5 KB，约 0.042% |

---

## 2. 逐仓库核验

### R1 — Xiaomi_Kernel_OpenSource @ bsp-dali-v-oss

**实际路径**：`/workspace/K80U_GPU_R56_AUDIT/01_original_baseline/kernel_src_dali`

| 项 | 值 | 证据 |
| --- | --- | --- |
| 分支 | `bsp-dali-v-oss` | `git rev-parse --abbrev-ref HEAD` |
| commit | `f089d58cab670dc0d75db1203fa63850e57a940d` | `git rev-parse HEAD` |
| 提交日期 / 说明 | 2025-09-19 / `dali open source` | `git log -1` |
| 克隆方式 | `--depth 1 --filter=blob:none --no-checkout` | `git rev-parse --is-shallow-repository` → `true` |
| 文件总数 | **82,279** | `git ls-tree -r --name-only HEAD \| wc -l` |
| 目录数 | 5,346 个对象（含 1 commit + 全部 tree） | `git count-objects -v` → `in-pack: 5346` |

**是否为完整 Linux 内核源码树**：是。顶层 25 个目录 `Documentation LICENSES android arch block certs crypto drivers fs include init io_uring ipc kernel lib mm net rust samples scripts security sound tools usr virt`，含 `Makefile`、`Kconfig`、`Kbuild`、`rust/`、`android/abi_gki_aarch64*`，是标准 Android GKI 形态。`[实证]`

**是否混入预编译文件**：否。全树 `.ko/.img/.lz4/.dtb/.dtbo` 文件数 = **0**。`[实证]`

**版本**：见 §4。

### R2 — MTK_kernel_modules @ bsp-dali-v-oss

**实际路径**：`/workspace/K80U_GPU_R56_AUDIT/01_original_baseline/mtk_kernel_modules`

**形态说明（重要）**：本仓库未以 git 克隆，而是以 `codeload` tarball 获取后**仅解出 `mali-r49p1` 子树**。因此：

- commit 来源为 tarball URL：`https://codeload.github.com/MiCode/MTK_kernel_modules/tar.gz/fe0fa7ff68a2de0dec7ce1a04f5db6f07fd4a3b9` → `fe0fa7ff68a2de0dec7ce1a04f5db6f07fd4a3b9` `[实证]`
- 原件未被 git 校验，仅有 SHA256：`788b3310217cf87403d7c46fed1bcc2126b4e66232528e7053a2ada8e5d569d9`，60,893,300 B `[实证]`
- 仓库清单完整（18,094 条目），但**实体仅落盘 581 个文件**（r49p1 子树）→ 该仓库**不能称为"已完整拉取"** `[实证]`

**目录构成**：`gpu/` 10,859、`connectivity/` 4,420、`mtkcam/` 2,306、`met_drv_v3/` 194、`met_drv_v2/` 130 等。

### R3 — MTK_kernel_device_modules @ bsp-dali-v-oss

**实际路径**：`/workspace/K80U_GPU_R56_AUDIT/01_original_baseline/kernel_dev_modules_dali`

| 项 | 值 | 证据 |
| --- | --- | --- |
| 分支 | `bsp-dali-v-oss` | `git rev-parse --abbrev-ref HEAD` |
| commit | `e45c3199537fbba9aae5fb06c31fc8dbd3c1dcee` | `git rev-parse HEAD` |
| 文件总数 | 11,619 | `git ls-tree -r --name-only HEAD \| wc -l` |
| 对象数 | 1,540 | `git count-objects -v` |

**性质**：不是完整内核树，是**设备模块树**。`drivers/` 10,348、`sound/` 572、`arch/` 307、`include/` 231、`kernel/` 63；`mm/`、`net/`、`fs/` 等核心子系统缺失（`drivers/mm` = 0）。`[实证]`

**含 dali 设备树**：`arch/arm64/boot/dts/mediatek/dali.dts`、`dali-mt6991-common.dtsi`、`xiaomi_dali_mt6991_{fingerprint,touch,mitee}.dtsi`、`kernel/configs/dali.config`、`dali_stability.config`。`[实证]`

### R4 — kernel_devicetree

**未拉取，理由充分**：该仓库共 **70 个分支**，全为机型代号（`alioth-r-oss`、`bixi-v-oss`、`dagu-s-oss` …），**无 `dali`，无 `6991`**；`master` 分支顶层仅有 1 个 `README.md`，判定为"按机型分支存放"的容器仓库。`[实证]`

> 结论：dali/MT6991 的设备树**不在**此仓库，而在 R3 的 `arch/arm64/boot/dts/mediatek/`。

### R5 — android_device_xiaomi_dali-kernel（原厂预编译件）

**实际路径**：`/workspace/K80U_GPU_R56_AUDIT/01_original_baseline/kernel_ref_mt6991`

**性质判定：这是预编译发布仓，不是源码仓。** 依据：

| 类型 | 数量 | 体积 |
| --- | --- | --- |
| `.h` | 942 | 6.06 MB |
| `.ko` | **635** | **106.54 MB** |
| `.lz4`（内核镜像） | 1 | 16.50 MB |
| `.dtb` | 1 | 0.51 MB |
| `.img`（dtbo） | 1 | 8.00 MB |
| `.c` | **0** | 0 |
| 合计 | 1,585 | 137.6 MB |

`[实证]`。**本仓库 0 个 C 文件，任何将其内容称为"源码"的表述都是错的。**

本地仅落盘 21 个文件（15 个 `.ko` + 4 个 `modules.load.*` + 1 个 `.dtb` + `README.md`），完整清单见 `01_original_baseline/_inventory/kernel_repo_tree_0576426.json`。

顶层分区构成（全量清单口径）：`vendor_dlkm` 284 / 53.56 MB、`vendor_ramdisk` 273 / 42.55 MB、`system_dlkm` 78 / 10.43 MB、`kernel-headers` 942 / 6.06 MB、根文件 7 / 24.51 MB（含 `Image.lz4`、`dtbo.img`）、`dtb` 1。

### R6 — Arm Mali R56p0 DDK

**实际路径**：`/workspace/K80U_GPU_R56_AUDIT/02_r56_source/mali_r56p0`

| 项 | 值 |
| --- | --- |
| 原件 | `AX504X08X-SW-99002-r56p0-18eac0.tar.gz` |
| 大小 | 1,147,252 B |
| MD5 | `62b168823691eb61ec29654cbf35e719` = Arm CDN 清单登记值，**逐字节一致** |
| 条目 | 454 |
| 形态 | 官方 tar.gz 解包，未打补丁 |

**不含固件**：包内无 `mali_csffw.bin` 等二进制固件，仅有 `mali_kbase_csf_firmware*.c` 等**加载器源码**。`[实证]`

---

## 3. 完整性专项：LFS / 子模块 / partial clone

### 3.1 Git LFS

| 仓库 | `.gitattributes` | `filter=lfs` 规则数 | 已解出目录的 LFS 指针扫描 |
| --- | --- | --- | --- |
| R1 | 存在 | **0** | — |
| R3 | 存在 | **0** | — |
| R2 | 未纳入版本控制（tarball） | — | `grep -rl "git-lfs.github.com/spec"` → 无命中 |
| R5 | 未纳入版本控制（tarball 子集） | — | 同上，无命中 |

R1 的 `.gitattributes` 全文仅 5 行，全是 `diff=` 属性（`*.[ch] diff=cpp`、`*.dts diff=dts`、`*.rs diff=rust`），**无 LFS 过滤**。`[实证]`

> 结论：**不存在 LFS 文件缺失**。系统虽有 `git-lfs`（`/usr/bin/git-lfs`），但本项目未用到。

### 3.2 子模块

| 仓库 | `.gitmodules` | gitlink（mode 160000）条目 |
| --- | --- | --- |
| R1 | **不存在** | **0** |
| R3 | **不存在** | **0** |

`[实证]`（`git ls-tree -r HEAD | awk '$1=="160000"'`）

> 结论：**不存在子模块未初始化**。

### 3.3 partial clone 的影响（必须知情）

R1/R3 使用 `--filter=blob:none --no-checkout`，含义是：

- **有**：完整 commit + 完整 tree（全部目录结构、全部文件路径、每个文件的大小与 blob SHA）
- **无**：文件内容（blob），工作区为空

验证按需拉取可用（本轮实测 3 次，均成功且大小与 tree 登记一致）：

| 文件 | tree 登记大小 | `git cat-file -s` |
| --- | --- | --- |
| `Makefile`（R1） | — | 通过，读出 6.6.56 |
| `kernel/configs/dali.config`（R3） | 3,169 | 3,169 |
| `.../mali-r49p1/.../mali_kbase_core_linux.c`（R3） | 201,222 | 201,222 |

`[实证]`。**风险提示**：若后续断网或代理失效，blob 将无法按需获取。因此"树清单完整"≠"内容已全部落地"，两者需分开表述。

### 3.4 shallow clone 的影响

`--depth 1` 意味着**只有 1 个 commit 的历史**，无法做跨版本 `git log -S`、`git blame` 追溯。

> `[UNKNOWN]`：若后续需要"某行代码是哪个版本引入的"，当前浅克隆无法回答，需 `--unshallow` 或改用 GitHub API 对比。

---

## 4. 内核版本确认

### 4.1 主内核树

```
Makefile:
VERSION = 6
PATCHLEVEL = 6
SUBLEVEL = 56
```

→ **Linux 6.6.56**，符合"Linux 6.6"目标。`[实证]`

### 4.2 GKI 世代

```
build.config.common:
BRANCH=android15-6.6
KMI_GENERATION=8
```

→ 这是 **android15-6.6** 分支、KMI 第 8 代。`[实证]`

### 4.3 与出厂模块的一致性

| 维度 | 开源树 | 出厂 `mali_kbase_mt6991_r49.ko` | 判定 |
| --- | --- | --- | --- |
| 主版本 | 6.6 | 6.6 | 一致 |
| 子版本 | **6.6.56** | **6.6.118** | **差 62 个 patch** |
| GKI 分支 | android15-6.6 | `vermagic=6.6.118-android15-8` | 一致 |
| KMI 代 | 8 | `-android15-8` | 一致 |
| 页大小 | — | `-4k` | — |

`[实证]`（`strings ... | grep '^vermagic='`）

**解读**：分支与 KMI 完全对齐，说明开源树与出厂构建**同属 android15-6.6 分支**；但子版本落后 62 个 patch，说明小米开源的是**该分支的较早快照**（2025-09-19），不是出厂内核的精确同点。

> 对审计的影响：模块 ABI 层面（`modversions`）无法用这棵树精确复现出厂内核的符号 CRC。若后续要做"模块能否加载"的判定，必须用目标机实际内核的 `Module.symvers`，而非本树。`[推断]`

### 4.4 Android 16 目标

用户设定的目标是 **Android 16**，但：

- `Xiaomi_Kernel_OpenSource` 共 100 个分支，含 dali 的只有 `bsp-dali-v-oss` 一个，`BRANCH=android15-6.6` `[实证]`
- 全库不存在 `android16` 分支或 MT6991 的 16 世代分支 `[实证]`

> `[UNKNOWN]`：Android 16 对应的小米 MT6991 内核树是否已开源，当前无法确认。**这是一个需要你在决策层拍板的缺口**——要么目标机实际仍在 android15-6.6 内核上跑 Android 16 用户态（GKI 允许，需核实），要么该树尚未发布。

---

## 5. 跨仓库版本对应关系

### 5.1 证据链 A：出厂 `.ko` ← R2 的 r49p1

| 环节 | 证据 |
| --- | --- |
| ① 出厂模块版本串 | `mali_kbase_mt6991_r49.ko` → `K:r49p1-03bet0(GPL)` |
| ② 出厂模块编译路径 | `../vendor/mediatek/kernel_modules/gpu/mt6991/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/...` |
| ③ R2 中该路径的对应物 | `gpu/mt6991/Makefile`：`obj-m += mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/`；`gpu/mt6991/mali_avalon` 为符号链接 → `gpu/gpu_mali/mali_avalon` |
| ④ 该子树源码版本串 | `Makefile:526` → `MALI_RELEASE_NAME ?= '"r49p1-03bet0"'` |

**四环闭合**：路径、版本串、模块名三者互相印证，判定 **R2 的 `mali-r49p1` 即出厂驱动的确切源码**。`[实证]`

### 5.2 证据链 B：UAPI 版本 1.30 的三方一致

| 来源 | 值 | 位置 |
| --- | --- | --- |
| 源码定义 | 1.30 | `mali_kbase_csf_ioctl.h:121-122`：`BASE_UK_VERSION_MAJOR 1` / `BASE_UK_VERSION_MINOR 30` |
| 出厂二进制 | 1.30 | `.ko` 内 `UK version 1.30` |
| 第三方实测 | 1.30 | PanVK `devices.json`，7 台 MT6991 设备中 6 台 `kbaseUapi=1.30` |

`[实证]`。三方独立来源一致，可作确定事实使用。

### 5.3 证据链 C：R5 的 15 个 `.ko` ↔ 源码归属

| 出厂模块 | 大小 | 源码归属 | 状态 |
| --- | --- | --- | --- |
| `mali_kbase_mt6991_r49.ko` | 2256.3 KB | R2 `mali-r49p1/drivers/gpu/arm/midgard` | ✅ 有源码 |
| `mali_mgm_mt6991_r49.ko` | 54.4 KB | R2 `mali-r49p1/drivers/base/arm/memory_group_manager` | ✅ 有源码 |
| `mali_prot_alloc_mt6991_r49.ko` | 20.6 KB | R2 `mali-r49p1/drivers/base/arm/protected_memory_allocator` | ✅ 有源码 |
| `ged.ko` | 1067.7 KB | R3 `drivers/gpu/mediatek/ged` | ✅ 有源码 |
| `mtk_gpueb.ko` | 125.5 KB | R3 `drivers/gpu/mediatek/gpueb` | ✅ 有源码 |
| `mtk_gpufreq_wrapper.ko` | 148.2 KB | R3 `drivers/gpu/mediatek/gpufreq` | ✅ 有源码 |
| `mtk_gpufreq_mt6991.ko` | 115.6 KB | R3 `drivers/gpu/mediatek/gpufreq` | ✅ 有源码 |
| `mtk_gpu_iommu_mt6991.ko` | 12.5 KB | R3 `drivers/gpu/mediatek/gpu_iommu/gpu_iommu_mt6991.c` | ✅ 有源码 |
| `mtk_gpu_pdma_mt6991.ko` | 39.6 KB | R3 `drivers/gpu/mediatek/gpu_pdma/gpu_pdma_mt6991.c` | ✅ 有源码 |
| `mtk_gpu_hal.ko` | 57.6 KB | R3 `drivers/gpu/mediatek/hal` | ✅ 有源码 |
| `mtk_gpu_qos.ko` | 32.6 KB | `[UNKNOWN]` — R3 中未找到显式 `gpu_qos` 目录 | ❓ |
| `mtk_gpu_power_throttling.ko` | 37.4 KB | 部分：R3 `drivers/misc/mediatek/cg_ppt/*peak_power_throttling*.c`，命名不完全对应 | ⚠️ `[UNKNOWN]` |
| `met_gpu_api.ko` | 14.0 KB | R2 `met_drv_v3` / `met_drv_v2` | ⚠️ 目录存在，未逐文件核对 |
| `met_gpu_adv_api.ko` | 11.9 KB | 同上 | ⚠️ 同上 |
| `met_gpueb_api.ko` | 13.8 KB | 同上 | ⚠️ 同上 |

**加载顺序**（`modules.load.vendor` 第 38–53、87 行）：`power_throttling → gpueb → gpu_hal → gpufreq_wrapper → gpufreq_mt6991 → gpu_iommu → ged → gpu_pdma → mali_prot_alloc → mali_mgm → mali_kbase`，`mtk_gpu_qos` 在第 87 行之后单独加载。`[实证]`

> **10/15** 个模块有明确源码归属，1 个缺失（`mtk_gpu_qos.ko`），1 个半缺（`power_throttling`），3 个 `met_*` 待细核。**这是本阶段唯一实质性的源码缺口。**

缺口的直接证据来自 `R3:drivers/gpu/mediatek/Makefile` 的构建目标列表——**只有 7 个**：

```make
obj-y += ged/      obj-y += hal/       obj-y += gpufreq/   obj-y += gpu_bm/
obj-y += gpu_iommu/  obj-y += gpueb/   obj-y += gpu_pdma/
```

`gpu_qos` 与 `power_throttling` **均不在其中**，且全库检索 `drivers/gpu/mediatek/**qos*` 无命中（仅 `drivers/gpu/drm/mediatek/mediatek_v2/mtk_disp_pmqos.c`，属**显示**模块）。`[实证]`

### 5.4 证据链 D：两套 r49p1 的辨别

| 维度 | R2（kernel_modules） | R3（device_modules） | 判定 |
| --- | --- | --- | --- |
| 版本串 | `r49p1-03bet0` | **`r49p1-00dev0`** | R2 对齐出厂 |
| 路径数 | 664 | 559（**严格子集**，`comm -23` 结果为空） | R3 缺 `drivers/base/arm/*`、`hwtracing` |
| `Makefile` | 729 行 | 499 行 | R2 含 MTK 定制块 |
| `core_linux.c` | 208,790 B | 201,222 B | 差 7,568 B |
| UAPI 头 | `88e5868e511aa561…` | `88e5868e511aa561…` | **完全相同** |

`core_linux.c` 的 216 行差异（+202 / −14）内容抽样：

```c
+#if defined(CONFIG_MALI_MTK_GPU_BM_JM)
+#include <gpu_bm.h>
+#if IS_ENABLED(CONFIG_MTK_TINYSYS_SSPM_SUPPORT)
+#include <sspm_reservedmem_define.h>
```

→ 差异为 **MTK 私有功能注入**（GPU 带宽监控 GPU_BM、SSPM 共享内存、GPU_QOS），非上游演进。`[实证]`

> 判定：R2 的 `03bet0` 是"上游基线 + MTK 私有补丁"的出货形态；R3 的 `00dev0` 是未经 MTK 补丁的开发基线，**不得用于代表出厂驱动**。`[推断]`

---

## 6. 重复、过期与无关代码

### 6.1 重复

| 重复项 | 范围 | 处置建议 |
| --- | --- | --- |
| r49p1 双份 | R2 664 文件 + R3 559 文件 | **以 R2 为准**，R3 版本仅作 diff 参照 |
| `gpu/mt6991/Makefile` 同时列 `r48p0` 与 `r49p1` 两组 `obj-m` | R2 | 见 U3：属 R5P0 旧构建路径，与 `gpu_mali/` 路径互斥 |
| DDK 版本选择变量 | `CONFIG_MTK_GPU_VERSION` | 由 `drivers/gpu/mediatek/Makefile` 与 `mali_avalon/Makefile` 反推，格式应为 4 段 `<mali> <avalon> <r49p1> <mt6991>`（第 1 词→`gpu_mali/`，第 3 词→版本目录，第 4 词→平台）。`[推断]`，实际取值 `[UNKNOWN]` |
| 设备树双份 | R3 `arch/arm64/boot/dts/mediatek/` 与 R5 的 `dtb/mt6991.dtb`（二进制） | 前者为源，后者为编译产物，非重复 |

### 6.2 过期（与目标无关的旧版本）

R2 `gpu/gpu_mali/mali_avalon/` 下并存 6 个 DDK 版本：

| 版本 | 文件数 | 与 MT6991 关系 |
| --- | --- | --- |
| `mali-r44p0` | 552 | 无关（旧世代） |
| `mali-r44p1` | 572 | 无关 |
| `mali-r46p0` | 706 | 无关 |
| `mali-r47p0` | 714 | 无关（R3 亦有） |
| `mali-r48p0` | 624 | 无关（但出现在 mt6991/Makefile 中，见上） |
| **`mali-r49p1`** | **664** | **✅ 出厂版本** |

`[实证]`。avalon 合计 3,834 文件，**仅 664 个与本次标的相关（17.3%）**。

### 6.3 与 MT6991 无关的代码（占比很高，需明确剔除）

| 仓库 | 总量 | 与 MT6991 相关 | 无关主体 |
| --- | --- | --- | --- |
| R2 `gpu/` | 10,859 | 664 + 少量平台胶水 | `gpu_rgx` 3,789（**PowerVR，完全不同厂商**）、`mali_valhall` 2,582（G7x/G5x，非 Avalon）、`mali_bifrost` 613、avalon 旧版本 3,170 |
| R2 全库 | 18,094 | — | `connectivity` 4,420、`mtkcam` 2,306、`met_drv_*` 324 等均与 GPU 无关 |
| R3 | 11,619 | `drivers/gpu/mediatek` 1,362 + dali dts | 其余 10,257 为其他平台/子系统 |
| R1 | 82,279 | **0** | 全树无 GPU 驱动 |

`[实证]`。

**特别提示（易误判项）**：

- `drivers/gpu/drm/arm/` 存在，但内容是 `malidp_*`（**显示控制器**），不是 Mali GPU 驱动。`[实证]`
- `drivers/gpu/drm/panfrost/` 存在 24 个文件，是**上游社区**的 Arm Valhall(JM) 开源驱动，与 MTK 无关、与 CSF 无关。`[实证]`
- `drivers/gpu/drm/mediatek/` 是 **MTK 显示驱动**，不是 GPU。`[实证]`
- `panthor`（上游 CSF 驱动）**不存在**（6.6 树中尚无）。`[实证]`

---

## 7. 缺失与 UNKNOWN 清单

### 7.1 明确缺失（已确认不存在）

| # | 缺失项 | 证据 |
| --- | --- | --- |
| M1 | **用户态 DDK**（`libGLES_mali.so`、`libmali.so`、Vulkan 用户态） | R5 全量 1,585 条清单中 `libGLES`/`libmali`/`libvk`/`vulkan` 命中 **0** |
| M2 | **CSF 固件**（`mali_csffw.bin`） | R5 中 `csffw`/`csf_fw`/`firmware` 命中 **0**；R6 包内亦无 |
| M3 | Android 16 世代内核树 | 100 个分支中无 `android16` |
| M4 | `kernel_devicetree` 的 dali 覆盖 | 70 分支无一匹配 |
| M5 | `mtk_gpu_qos.ko` 对应源码 | R3 `drivers/gpu/mediatek/Makefile` 的 7 个 `obj-y` 目标中无 `qos`；全库 `drivers/gpu/mediatek/**qos*` 命中 0 |
| M6 | `mtk_gpu_power_throttling.ko` 对应源码 | 同上，Makefile 无该目标；只有 `drivers/misc/mediatek/cg_ppt/` 的 CPU 峰值功耗限流，命名与用途均不对应 |

### 7.2 已识别但未落盘（非缺失，属策略性跳过）

| # | 内容 | 数量 | 说明 |
| --- | --- | --- | --- |
| P1 | R5 的 `vendor_ramdisk/` | 273 文件 / 42.55 MB | 仅清单，未下实体 |
| P2 | R5 的 `system_dlkm/` | 78 文件 / 10.43 MB | 仅清单 |
| P3 | R5 的 `kernel-headers/` | 942 文件 / 6.06 MB | 仅清单 |
| P4 | R5 的其余 620 个 `.ko` | 约 100 MB | 仅清单 |
| P5 | R2 除 r49p1 外的 17,513 个文件 | — | 仅清单 |
| P6 | R1 的全部 blob | 82,279 个 | 按需拉取 |
| P7 | R7 PanVK 源码主体 | 约 1.04 GB | 仅取 33 个文档/补丁文件 |

### 7.3 UNKNOWN（证据不足，不作判断）

| # | 事项 | 为何无法判定 |
| --- | --- | --- |
| U1 | 目标机当前内核是否真为 6.6.118 | 需真机 `uname -r`；本阶段未接触设备 |
| U2 | 目标机是否为 Android 16 且运行于 android15-6.6 GKI | GKI 允许跨版本用户态，需真机 `getprop` 核实 |
| U3 | `gpu/mt6991/Makefile` 中 r48p0/r49p1 双 `obj-m` 实际编译哪一套 | **部分收窄**：`drivers/gpu/mediatek/Makefile` 显示两条互斥路径——`CONFIG_MTK_GPU_R5P0=y` 时走 `mt6991/`（该文件同列 r48p0/r49p1，仍存疑）；否则走 `gpu_mali/`，由 `mali_avalon/Makefile` 按 `CONFIG_MTK_GPU_VERSION` 的**第 3 个词**选择单一版本。出厂 `.ko` 版本串为 `r49p1`，故应为后者。最终取值仍取决于构建期配置，`CONFIG_MTK_GPU_VERSION` 的实际值仓库内未见 |
| U4 | `mtk_gpu_power_throttling.ko` 与 `cg_ppt` 的精确对应 | 命名不一致，未见 Makefile 显式映射 |
| U5 | R2 tarball 与 GitHub 分支是否逐字节等价 | 无 git 元数据，仅 SHA256 可查 |
| U6 | 3 个 `met_*` 模块的源码对应 | 目录存在但未逐文件核对 Makefile 目标名 |

> **后续观测（2026-11-16 追加；本目录正文冻结，只增不改）**
>
> | # | 原状态 | 现状态 | 依据 |
> | --- | --- | --- | --- |
> | **U1** | 目标机内核是否真为 6.6.118 | **✅ 已闭合**：**是**，具体为 `6.6.118-android15-8-g54a15cf3acba-4k` | 设备 18 个厂商 `.ko` 的 `vermagic` 全部为该串（`05/07` §3.5、`05/08` §3.7.2）。注意：这是**原厂 boot 的推断值** [E2]；运行时内核已被替换为第三方 `6.6.143-…-gf9aa2fec23c3` |
> | **U2** | 目标机是否 Android 16 且运行 android15-6.6 | **✅ 已闭合**：Android **17 / SDK 37**；GKI 分支 `android15-8`（`android15` 是分支名，非 Android 版本） | 真机 `getprop`（`05/07` §2） |
>
> **另注（2026-11-16）**：本轮修正了 §2、§3 表格中两处 `` `git ls-tree … | wc -l` `` 的管道符转义（原写法会让 GFM 表格断行）。**只改格式，不改任何数值与结论。**
>
> **同时需要更正本目录的一个隐含前提**：`01_original_baseline/` 的 `.ko` 取自社区镜像声明的 `OS3.0.305.0.WONCNXM`，其 vermagic 为 `6.6.118-android15-8-**g57e634f35c1b**`；而本机（`OS4.0.3.0`）模块为 `6.6.118-android15-8-**g54a15cf3acba**`。**同 sublevel、不同提交**——所以"6.6.118"这个判断成立，但"基线 `.ko` = 本机 `.ko`"不成立。

---

## 8. 对下一阶段的影响

1. **`03_kbase_csf` 可以正式开工**。r49p1（`03bet0`）与 r56p0 两侧源码齐备，可做源码级 diff，无需再依赖二进制反推。
2. **建议以 R2 的 r49p1 为基线，R3 的 r49p1 仅作对照**，理由见 §5.4。
3. **`04_mtk_platform` 的材料基本齐备**：ged/gpueb/gpufreq/pdma/iommu 源码 + `dali.dts` + 出厂 15 个 `.ko`，但 `qos` 与 `power_throttling` 两个模块的源码归属需要补齐。
4. **两个待你决策的缺口**：
   - **Android 16 内核树不存在**（U2）——这会影响"移植后能否在 Android 16 上加载"的判定，建议先核实目标机实际内核。
   - **内核子版本差 62 个 patch**（§4.3）——若后续要做模块加载可行性验证，必须取真机 `Module.symvers`。
5. **用户态与固件是硬缺口**（M1/M2），这决定 `05_userspace_firmware` 能否成立。若走"内核升级 + 用户态沿用"路线，必须先确认现网 blobs 能否与 UK 1.39 握手。

---

## 附录：核验命令索引

```bash
# 仓库形态与元数据
git -C <repo> rev-parse --abbrev-ref HEAD; git -C <repo> rev-parse HEAD
git -C <repo> rev-parse --is-shallow-repository; git -C <repo> count-objects -v

# 文件清单（不取 blob）
git -C <repo> ls-tree -r --name-only HEAD | wc -l

# LFS / 子模块
git -C <repo> cat-file -e HEAD:.gitattributes && git -C <repo> show HEAD:.gitattributes
git -C <repo> cat-file -e HEAD:.gitmodules
git -C <repo> ls-tree -r HEAD | awk '$1=="160000"'

# 版本
git -C <repo> show HEAD:Makefile | sed -n '2,6p'
git -C <repo> show HEAD:build.config.common | grep -E "BRANCH|KMI"

# 出厂模块证据
strings -a mali_kbase_mt6991_r49.ko | grep -E '^vermagic=|r49p1-03bet0|kernel_modules/gpu/mt6991'

# 两套 r49p1 差异
comm -23 /tmp/dev_r49.txt /tmp/mod_r49.txt   # 仅 dev 有 → 为空，证子集
diff -u /tmp/core_dev.c /tmp/core_mod.c
```

---

## 勘误（2026-11-15，由 TASK 01-B 触发）

本文件以下判定在 TASK 01-B 全局检索后被证伪，**以 `gpu_source_inventory.md` 为准**：

| 原判定 | 位置 | 实测 | 漏检原因 |
| --- | --- | --- | --- |
| M5：`mtk_gpu_qos.ko` 对应源码缺失 | §7.1 | 源码为 `drivers/gpu/mediatek/gpu_bm/gpu_bm.c`；`Makefile` 内 `mtk_gpu_qos-y := gpu_bm.o` | 只按 `*qos*` 文件名检索，未建立「目录名 ≠ 模块名」映射 |
| M6 / U4：`mtk_gpu_power_throttling.ko` 源码缺失或对应不明 | §7.1 / §7.3 | 源码为 `drivers/misc/mediatek/power_throttling/mtk_gpu_power_throttling.c`（217 行） | 检索范围止于 `drivers/gpu/mediatek/**`，未外扩至 `drivers/misc/` |
| U6：3 个 `met_*` 模块源码待细核 | §7.3 | 全部确认于 `met_drv_v3/default/met_api/{met_gpu_api,met_gpu_adv_api,met_gpueb_api}/` | 未展开 tarball 内 `met_drv_v3` 子目录 |
| §5.3 统计「10/15 有源码」 | §5.3 | **15/15** | 上述三项叠加 |
| §5.4「R3 缺 `drivers/base/arm/*`、`hwtracing`」 | §5.4 | **错误**。两侧 `drivers/base` 均 19 文件、`hwtracing` 均 13 文件；R3 实际缺 22 项 = 6 个其他 SoC 平台目录（18 文件）+ 4 个 `mtk_platform_common` 工具文件（`mtk_platform_upf_counter.c/.h`、`mtk_platform_whitebox_directly_hard_reset.c/.h`） | `comm` 输入混用了「含目录的 tree 条目」与「纯文件清单」两种口径 |
| §5.4 文件数「R2 664 / R3 559」 | §5.4 | R2 **581** 实体文件 / R3 **559**；664 是含目录的 tree 条目数 | 口径未标注 |

补充结论（01-B 新增，不影响原判定）：

- 源码树虽含 `jm/`，但出厂 `.ko` 为 **CSF-only** 构建（`kbase_csf_*` 461 处 vs `kbase_jd_/kbase_job_` 5 处）。
- 出厂内核构建 hash 为 `g57e634f35c1b`（取自 15 个 `.ko` 的 vermagic），与开源树 `f089d58c` 不同。
