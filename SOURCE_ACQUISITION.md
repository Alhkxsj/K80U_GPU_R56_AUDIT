# 源码资料采集报告 — Stage 1

> 采集日期：2026-11-15 · 采集方式：只读下载/只读 API · **未修改、未合并、未编译任何源码**

> ## ⚠️ 本文是 2026-11-15 上午的采集快照，不是当前状态
>
> 文中"R56p0 未获取""`02`/`03` 阻塞"等结论**已于当日晚间解除**，请勿据此判断仓库现状：
>
> | 本文的结论 | 现状 |
> | --- | --- |
> | F-01：Arm R56p0 内核驱动源码未获取 | ✅ **已获取**，454 文件 / 5.58 MB，MD5 校验通过 → `02_r56_source/mali_r56p0/` |
> | 出厂 r49p1 仅 `.ko`、无源码 | ✅ **已获取源码**，581 文件 → `01_original_baseline/mtk_kernel_modules/…/mali-r49p1/` |
> | `02`/`03` 源码级工作无法开展 | ✅ `03_kbase_csf` 五域差异审计已完成（45 条，13 P0） |
>
> 现行状态见 [`README.md`](README.md) §2 与 [`02_r56_source/SOURCING_STATUS.md`](02_r56_source/SOURCING_STATUS.md)。本文原样保留，作为"阻塞—解除"过程的审计留痕。

## 0. 结论速览（采集时点）

| 来源 | 目标 | 结果 | 落盘位置 |
| --- | --- | --- | --- |
| Arm 官方 | Mali 5th Gen R56p0 内核驱动源码 | ❌ **未获取**（需 Arm 账号登录 + 接受 EULA）→ **当晚已获取，见文首** | `02_r56_source/mali_r56p0/`（当时为空壳，仅 `.gitkeep`） |
| GitHub | MT6991 / K80 至尊版内核参考仓库 | ⚠️ **部分获取**（仓库本身只含预编译产物，非内核源码；按 GPU 相关性取 21 个文件） | `01_original_baseline/kernel_ref_mt6991/` |
| GitHub | PanVK Kbase Android 第三方参考 | ⚠️ **部分获取**（仓库 1.07 GB，带宽 25 KB/s，取文档与兼容矩阵 17 个文件） | `00_reference/third_party/panvk-kbase-android/` |

**最重要的一条基线事实**（本次采集直接证实）：

> 设备出厂 GPU 内核驱动是 **`mali_kbase_mt6991_r49.ko`，版本 `r49p1-03bet0(GPL)`**。
> 也就是说，本次移植的跨度是 **r49p1 → r56p0**，跨 7 个主版本。

---

## 1. 源码目录结构（实际落盘）

```
K80U_GPU_R56_AUDIT/
├── 00_reference/
│   └── third_party/
│       └── panvk-kbase-android/          # PanVK（第三方参考，非权威）
│           ├── README.md  CHANGELOG.md  NOTICE.md  sources.lock
│           ├── ACQUISITION.md            # 采集说明（本次新增）
│           ├── compatibility/devices.json
│           └── docs/  (13 份 .md)
├── 01_original_baseline/
│   ├── _inventory/
│   │   └── kernel_repo_tree_0576426.json # 原仓库完整文件清单（1585 条）
│   └── kernel_ref_mt6991/                # MT6991 参考仓库（部分）
│       ├── README.md
│       ├── modules.load.{vendor,vendor_ramdisk,system,recovery}
│       ├── dtb/mt6991.dtb
│       └── vendor_dlkm/  (15 个 GPU 相关 .ko)
└── 02_r56_source/
    ├── _arm_listing/
    │   └── arm_5thgen_package_listing_20261115.json   # Arm 包清单（证据）
    ├── SOURCING_STATUS.md                # 获取失败详情与补齐路径
    └── mali_r56p0/                       # 【空】R56p0 源码未获取
```

> `03_kbase_csf` / `04_mtk_platform` / `05_userspace_firmware` / `06_porting_design` 本次**未新增内容**：源码级分析的前置材料（R56p0 源码）尚缺，不宜提前生产结论。

---

## 2. 各源码版本信息

### 2.1 Arm Mali 5th Gen R56p0 内核驱动（❌ 当时未获取 → 当晚已获取）

| 字段 | 值 |
| --- | --- |
| 包名 | `AX504X08X-SW-99002-r56p0-18eac0.tar.gz` |
| 发布日期 | 2026-06-30 |
| 大小 | 1,147,252 字节（约 1.1 MiB） |
| MD5 | `62b168823691eb61ec29654cbf35e719` |
| 页面 | https://developer.arm.com/downloads/-/mali-drivers/5th-gen-gpu-architecture-kernel |
| 状态 | 点击下载跳转 `user-login`，**匿名不可下载** |

同页另有版本序列可供后续比对：r49p0～r49p5、r50p0、r51p0、r52p0、r53p0、r54p0/p2/p3、r56p0（共 23 个包）。完整清单已存 `_arm_listing/`。

### 2.2 出厂 GPU 内核驱动（✅ 已获取，基线核心证据）

| 字段 | 值 |
| --- | --- |
| 文件 | `vendor_dlkm/mali_kbase_mt6991_r49.ko`（2,310,424 B） |
| DDK 版本串 | **`r49p1-03bet0(GPL)`** |
| 模块名 | `mali_kbase_mt6991_r49` |
| `srcversion` | `9E8156B93E2E5E961FF9A20` |
| `license` | GPL |
| `vermagic` | `6.6.118-android15-8-g57e634f35c1b-4k SMP preempt mod_unload modversions aarch64` |
| 设备匹配 | `alias=of:N*T*Carm,mali-valhall`、`alias=of:N*T*Carm,mali-valhallC*` |
| 依赖模块 | `mtk_gpufreq_wrapper,aee_aed,ged,irq-dbg,mtk_gpu_hal,mrdump,mtk_gpueb,emi,mtk_sec_heap,tmem_ffa,mtk_slbc,mtk_gpu_pdma_mt6991` |
| 源码构建路径 | `../vendor/mediatek/kernel_modules/gpu/mt6991/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/...` |
| GPU 型号串 | 含 `Mali-G925-Immortalis`（该驱动已识别 G925） |

三条值得注意的推论（**推断，非事实**）：

1. MTK 把 kbase 放在 `mali_avalon/mali-r49p1/` 下，但源码路径仍叫 `midgard/` —— 命名沿革，判断 CSF 能力要看代码不看目录名。
2. ~~`vermagic` 写的是 `android15-8`，而目标系统是 Android 16 —— 需核实机型实际 KMI 分支，不能直接按字面推断。~~
   → **已澄清（2026-11-15 治理轮更正）**：`android15` 是 **GKI 分支名**，不是 Android 版本。设备 Android 为 **17 / SDK 37**，其 KMI 分支确为 `android15-8`（`uname -a` = `6.6.143-android15-8-gf9aa2fec23c3-4k`），两者不矛盾 **[D·B]**。原文保留以留痕（见 `docs/DECISION_LOG.md` D-012）。
   → **2026-11-16 再补一条**：上面引用的 `uname -a` 是**第三方运行内核**（SukiSU-Ultra）。本机厂商模块的 vermagic 为 `6.6.118-android15-8-g54a15cf3acba-4k`，据此推定**原厂 boot 内核为 `6.6.118`**（[E2]）。因此"目标系统内核"这一说法本身要分三层，见 `05/08` §3.7.2。
3. `arm,mali-valhall` 作为 `compatible` 用于 CSF 设备，说明 MTK 的 DTS 命名并未随架构换代而改变。

### 2.3 MT6991 内核参考仓库（⚠️ 部分获取）

| 字段 | 值 |
| --- | --- |
| 仓库 | `xiaomi-mt6991-devs/android_device_xiaomi_dali-kernel` |
| 地址 | https://github.com/xiaomi-mt6991-devs/android_device_xiaomi_dali-kernel |
| 分支 | `lineage-23.2`（默认分支） |
| commit | `057642643c9ff9ecd75d2442ca6be9766ece90d1` |
| commit 日期 | 2026-09-28 |
| commit 说明 | `Initial commit: add Redmi K80 Ultra (dali) prebuilt kernel` |
| 仓库规模 | 1,585 个文件 / 137.6 MB |
| 实际获取 | 21 个文件 / 4.66 MB（GPU 相关全量 + 加载清单 + dtb） |
| 性质 | **预编译产物仓库，不是内核源码** |

仓库内容构成：`vendor_dlkm`(53.6 MB)、`vendor_ramdisk`(42.6 MB)、`system_dlkm`(10.4 MB)、`Image.lz4`(16.5 MB)、`dtbo.img`(8 MB)、`kernel-headers`(6 MB, 942 个 uapi 头)、`dtb/mt6991.dtb`。README 声明产物抽取自 **OS3.0.305.0.WONCNXM** 固件，布局参照 `dash-kernel` 参考树。

### 2.4 PanVK Kbase Android（⚠️ 部分获取）

| 字段 | 值 |
| --- | --- |
| 仓库 | `zenithblue-oss/panvk-kbase-android` |
| 地址 | https://github.com/zenithblue-oss/panvk-kbase-android |
| 分支 | `main` |
| commit | `cf70e02b918e1864cbcd746a7fefa57b96c673ce` |
| commit 日期 | 2026-10-31 |
| 最新发布 | `panvk-kbase-v26.3.1`（2026-10-31） |
| 仓库规模 | 约 1.07 GB（含历史） |
| 实际获取 | 17 个文件 / 约 272 KB |
| 定位 | 第三方开源实现，**非权威**，仅作 ABI 与行为参考 |

`compatibility/devices.json` 共 77 条设备记录，其中 **7 条为 MT6991 + Mali-G925-Immortalis（MC11/MC12）+ CSF 前端**，例如 `2506BPN68G(klimt)`、`2602BPC18G(dash)`、`V2413/V2419A(k6991v1_64)`。这些是**同 SoC/同 GPU 的其他机型**，只能作为"该平台被 PanVK 覆盖"的旁证，**不能当作 K80 至尊版的适配证据**。

---

## 3. 重要文件清单

### 3.1 基线（`01_original_baseline/kernel_ref_mt6991/`）

| 文件 | 大小 | SHA256(前16) | 为什么重要 |
| --- | --- | --- | --- |
| `vendor_dlkm/mali_kbase_mt6991_r49.ko` | 2,310,424 | `c5ebca1c2a8be8e8` | **基线 kbase 本体**，r49p1-03bet0，未 strip，可做符号级分析 |
| `vendor_dlkm/mali_mgm_mt6991_r49.ko` | 55,696 | `22d3f50867d0bf1c` | MTK 内存/分组管理配套模块 |
| `vendor_dlkm/mali_prot_alloc_mt6991_r49.ko` | 21,080 | `4dc0f482a5d6631d` | 受保护内存分配 |
| `vendor_dlkm/mtk_gpufreq_mt6991.ko` | 118,368 | `939e68b8a5d58376` | DVFS/OPP 平台实现 |
| `vendor_dlkm/mtk_gpufreq_wrapper.ko` | 151,736 | `86e52c00daae6d11` | kbase 的 DVFS 对接层（被 kbase 依赖） |
| `vendor_dlkm/mtk_gpu_hal.ko` | 58,968 | `a2a3e56a50c3477c` | 平台 GPU HAL（被 kbase 依赖） |
| `vendor_dlkm/mtk_gpueb.ko` | 128,560 | `29a61def07bf31f6` | GPU EB（EMI 带宽）控制 |
| `vendor_dlkm/mtk_gpu_pdma_mt6991.ko` | 40,512 | `91d66e2e81b4d452` | GPU PDMA |
| `vendor_dlkm/mtk_gpu_iommu_mt6991.ko` | 12,840 | `5f79e6e44c4ba836` | GPU IOMMU 绑定 |
| `vendor_dlkm/mtk_gpu_power_throttling.ko` | 38,288 | `4a226ec226a1e9a4` | 功耗墙/限频 |
| `vendor_dlkm/mtk_gpu_qos.ko` | 33,376 | `2830bec88492e519` | QoS |
| `vendor_dlkm/ged.ko` | 1,093,352 | `f53e8c6833e82d8f` | MTK 调度框架（被 kbase 依赖） |
| `vendor_dlkm/met_{gpu,gpueb,gpu_adv}_api.ko` | 12–14 KB | — | MET 性能接口 |
| `modules.load.vendor` | 4,339 | `ef29ab691cb13b01` | **模块加载顺序**（见下） |
| `dtb/mt6991.dtb` | 532,322 | `223984cc1daf6f91` | 设备树：`gpufreq@48500000`、`gpu-fdvfs@13f800`、`arm,mali-valhall` |

**GPU 模块加载顺序**（`modules.load.vendor` 行号）：
`mtk_gpu_power_throttling`(38) → `mtk_gpueb`(43) → `mtk_gpu_hal`(45) → `mtk_gpufreq_wrapper`(46) → `mtk_gpufreq_mt6991`(47) → `mtk_gpu_iommu_mt6991`(48) → `ged`(49) → `mtk_gpu_pdma_mt6991`(50) → `mali_prot_alloc`(51) → `mali_mgm`(52) → `mali_kbase`(53) → `mtk_gpu_qos`(87)

> 这个顺序就是"平台先就绪、kbase 后插入"的硬约束，任何移植方案都必须保住它。

### 3.2 PanVK（`00_reference/third_party/panvk-kbase-android/`）

| 文件 | 大小 | 用途 |
| --- | --- | --- |
| `docs/KBASE-PROFILES.md` | 701 | kbase 配置档位说明 |
| `docs/KBASE-SPARSE-FEASIBILITY.md` | 15,462 | kbase 稀疏内存可行性（ABI 相关） |
| `docs/MALI-GPU-ARCHITECTURES.md` | 24,702 | Mali v6–v14 架构对照（G925 = v13） |
| `docs/MALI-VULKAN-NATIVE-FEATURES.md` | 98,561 | 各架构特性矩阵，定位 G925 能力边界 |
| `docs/BCN-COMPAT.md` / `BCN-INTEGRATION.md` | 3.3K / 1.3K | BCN 集成 |
| `docs/ARCHITECTURE.md` / `RUNTIME-FEATURES.md` / `MESA-MATRIX.md` | — | 运行时与 Mesa 版本矩阵 |
| `compatibility/devices.json` | 54,078 | 设备兼容库（含 7 条 MT6991/G925） |
| `CHANGELOG.md` | 40,682 | 版本演进与兼容性变更 |
| `sources.lock` | 2,211 | Mesa 上游锁定版本 |

---

## 4. 下载失败 / 无法确认的内容

| # | 项 | 状态 | 原因 | 影响 |
| --- | --- | --- | --- | --- |
| F-01 | **Mali R56p0 内核驱动源码** | ❌ 未获取 → ✅ **当晚已获取** | 点击下载重定向至 `developer.arm.com/user-login?returnUrl=...`，需 Arm 账号登录并接受 EULA；后由用户登录下载 | **当时阻塞**：`02`/`03` 的源码级工作无法开展；**现已解除**，见 `02_r56_source/SOURCING_STATUS.md` |
| F-02 | MTK 内核源码（GPU 驱动源码树） | ❌ 不存在于该仓库 | 该仓库只含预编译 `Image.lz4`、`.ko`、`.dtb`、uapi 头，无 `vendor/mediatek/kernel_modules/...` 源码 | `04_mtk_platform` 只能做**二进制级**分析（符号/字符串/依赖）。**补充**：GPU 驱动源码实际在另一仓库 `MiCode/MTK_kernel_modules`，已落盘 581 文件（见 `01_original_baseline/source_integrity.md` §R2） |
| F-03 | `Image.lz4`（16.5 MB） | ⏸ 未下载 | 单文件过大，25 KB/s 下约 11 分钟且价值低于 `mali.ko` | 低：kbase 版本已从 `.ko` 拿到，镜像仅作交叉验证 |
| F-04 | `dtbo.img`（8 MB）、`kernel-headers`（942 文件 / 6 MB） | ⏸ 未下载 | 同上，优先保 GPU 相关 | 低：uapi 头对 GPU 审计非关键 |
| F-05 | 仓库其余 1564 个文件（132.9 MB） | ⏸ 未下载 | 全量约需 90 分钟（25 KB/s）；已保存完整清单 `_inventory/kernel_repo_tree_0576426.json` | 低：非 GPU 模块 |
| F-06 | PanVK 完整仓库（1.07 GB） | ⏸ 未下载 | 带宽 25 KB/s，全量需 11 小时以上；`recursive` tree API 响应 8.4 MB 亦被网关截断 | 中：仅缺失 Mesa 主体源码，文档与兼容矩阵已覆盖 ABI 参考需求 |

### 网络通道说明（复现用）

- `github.com` 的 git 协议：**不可用**（连接超时 / TLS 中断）。
- `codeload.github.com` 的 tar.gz：可用但**约 10 MB 处被截断**，且不支持 Range 续传。
- `api.github.com` 的 blob / contents 接口：**稳定可用**，单文件按原始大小校验通过；速率约 25 KB/s。
- `developer.arm.com`：页面可读，下载接口需登录态。

---

## 5. 补齐 R56p0 的三条路径

| 方案 | 做法 | 代价 | 风险 |
| --- | --- | --- | --- |
| **A（推荐）** | 你登录 Arm 账号下载 `AX504X08X-SW-99002-r56p0-18eac0.tar.gz`（1.1 MB），放到任意本地路径后告知我 | 你操作 1 分钟 | 无 |
| B | 我在浏览器里走登录流程，你完成账号密码/MFA 输入 | 需你实时配合 | 凭据不应经我手，不推荐 |
| C | 从第三方镜像/他人 vendor 树取同版本 kbase | 我可自动完成 | **合规与真伪风险**：无法证明与 Arm 官方包一致，且易混入其他机型改动，违背"不把其他 GPU 型号代码当作 G925 适配代码"的原则 |

> 建议走 A。包只有 1.1 MB，你下载后我可在 1 分钟内完成落盘、MD5 校验、目录测绘。

---

## 6. 采集边界声明

本次操作严格遵守：

- ✅ 只做了 `GET` 类只读请求与文件落盘
- ✅ 所有落盘文件均按 API 返回的字节大小逐一校验
- ✅ 保存了 Arm 包清单 JSON 与仓库完整 tree JSON 作为可回溯证据
- ❌ 未修改任何源码（无 R56p0 源码可改）
- ❌ 未合并任何分支、未打任何补丁
- ❌ 未执行 `make` / `meson` / 任何构建
- ❌ 未连接、未读写任何设备
- ❌ 未把其他机型（`klimt` / `dash` / `gts11` 等）的配置当作 K80 至尊版的适配依据
