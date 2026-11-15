# ACQUISITION — PanVK Kbase Android（第三方参考）

## 定位

> **第三方开源实现，非权威来源。** 仅用于理解用户态如何与厂商 `mali_kbase` 通信（ABI、能力探测、CSF 交互），**不得**作为 R56p0 接口规范的依据，也不得据此推断 K80 至尊版的适配结论。

## 来源

| 字段 | 值 |
| --- | --- |
| 仓库 | `zenithblue-oss/panvk-kbase-android` |
| 地址 | https://github.com/zenithblue-oss/panvk-kbase-android |
| 分支 | `main` |
| commit | `cf70e02b918e1864cbcd746a7fefa57b96c673ce` |
| commit 日期 | 2026-10-31T07:58:25Z |
| commit 摘要 | `docs/releases: asset names, checksums and screenshots match the final …` |
| 最新发布 | `panvk-kbase-v26.3.1`（2026-10-31） |
| 仓库规模 | 约 1.07 GB（GitHub API `size` 字段，含历史） |
| 下载日期 | 2026-11-15 |
| 下载方式 | GitHub REST `contents` API（`Accept: application/vnd.github.raw`），只读、未 clone |

## 为什么只取子集

- 沙箱到 GitHub 的吞吐约 **25 KB/s**，git 协议不可用，全量需 11 小时以上。
- `git/trees?recursive=1` 响应约 8.4 MB，被网关截断，无法拿到完整文件索引。
- 结论：按"与 ABI/架构相关"取文档子集，其余留存于上游仓库，需要时按路径补取。

## 已落盘文件

| 文件 | 大小 | 取用理由 |
| --- | --- | --- |
| `README.md` | 16,611 | 驱动定位、支持的 Mali 版本范围（v6–v14） |
| `CHANGELOG.md` | 40,682 | 版本演进、兼容性变更史 |
| `NOTICE.md` / `sources.lock` | 5,546 / 2,211 | 许可与上游锁版本 |
| `docs/KBASE-PROFILES.md` | 701 | kbase 配置档位 |
| `docs/KBASE-SPARSE-FEASIBILITY.md` | 15,462 | kbase 稀疏内存 ABI |
| `docs/MALI-GPU-ARCHITECTURES.md` | 24,702 | 架构代际对照（G925 属 v13） |
| `docs/MALI-VULKAN-NATIVE-FEATURES.md` | 98,561 | 各代特性矩阵，用于界定 G925 能力边界 |
| `docs/ARCHITECTURE.md` | 1,263 | 驱动分层 |
| `docs/RUNTIME-FEATURES.md` | 4,002 | 运行时能力开关 |
| `docs/MESA-MATRIX.md` | 1,489 | Mesa 版本对应关系 |
| `docs/BCN-COMPAT.md` / `BCN-INTEGRATION.md` | 3,285 / 1,277 | BCN 兼容与集成 |
| `docs/PORTABILITY.md` | 703 | 可移植性说明 |
| `docs/RELEASE.md` / `SIGNING.md` | 4,512 / 3,029 | 发布与签名 |
| `compatibility/devices.json` | 54,078 | 设备兼容库（77 条） |

## devices.json 中与本次标的相关的条目（**旁证，非适配证据**）

> **更正（2026-11-15 13:20）**：本文件早期版本称"`kbase` 字段在上表条目中均为 `null`"，
> 该说法**错误**。实际字段为 `kbaseUapi`，且 6/7 条有明确值 `"1.30"`。已在下方重写。

MT6991 + G925 共 7 条，字段完整度远高于初判：

| 设备 | 代号 | GPU | gpuId | panArch | kbaseUapi | androidLoader | androidWsi |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2506BPN68G | klimt | G925 MC12 | `0xd8300015` | 13 | **1.30** | pass | pass |
| 2602BPC18G | dash | G925 MC11 | `0xd8300015` | 13 | **1.30** | pass | pass |
| SM-X736B | gts11 | G925 MC12 | `0xd8300015` | 13 | **1.30** | pass | pass |
| SM-X736N | gts11 | G925 MC12 | `0xd8300015` | 13 | **1.30** | untested | untested |
| SM-X930 | gts11uwifi | G925 MC12 | `0xd8300015` | 13 | **1.30** | pass | pass |
| V2413 | k6991v1_64 | G925 MC12 | `0xd8300015` | 13 | **1.30** | pass | pass |
| V2419A | k6991v1_64 | G925 MC12 | `0xd8300015` | 13 | `not logged` | untested | untested |

字段含义（据 README `tests/kbase-probe/` 说明）：

- `kbaseUapi`：`/dev/mali0` 上握手的 UK ABI 版本。
- `androidLoader` / `androidWsi`：PanVK 作为 Vulkan 驱动被 loader 加载、swapchain 建立的实际测试结果。
- `glibc` / `winlator` / `gamehub`：跨层兼容，**MT6991 各条目全部为 `untested`**。

### 由此可确认的三条事实

1. **MT6991 平台出厂 kbase 的 UK ABI 统一为 1.30** —— 小米 `klimt`、vivo `V2413`、三星 `gts11`
   三家厂商、7 台设备、内核 6.6.89 ~ 6.6.127，取值全部一致。
   这与我们基线 `mali_kbase_mt6991_r49.ko` 读出的 `UK version 1.30` **独立互证**。
2. **PanVK 在 G925 (panArch 13) + UK 1.30 + CSF 上确实跑通过**：5 台设备的
   `androidLoader` 与 `androidWsi` 均为 `pass`。这**修正**了仅凭
   `docs/MALI-GPU-ARCHITECTURES.md` 中"`patches/csf-v13/` … no profile, no device"
   得出的"纯纸面支持"判断 —— 后者的含义是"无独立 profile 文件"，而非"未在设备上运行"。
3. **但验证深度有限**：仅覆盖 Vulkan loader 与 WSI，游戏/翻译层全部 `untested`。
   因此这是"通道打通"级证据，**不是**"可日常使用"级证据。

### 解读边界

- 只能说明 **PanVK 作为用户态驱动可在 MT6991 + G925 + UK 1.30 上加载并呈现**；
- **不能**说明这些机型的 DTS、电源时序、OPP 表与 K80 至尊版一致；
- **不能**据此推断 Arm 官方 R56p0 内核驱动的可移植性 —— 两者不是同一条技术路线。

### 对本次审计的战略含义（需在 `06_porting_design` 中正式评估）

`kbaseUapi = 1.30` 在 7 台设备上的一致性，加上 PanVK 在 1.30 上的实际跑通，
意味着存在一条**不改内核**的路线：

| 路线 | 内核 | 用户态 | 已验证程度 |
| --- | --- | --- | --- |
| 主线：R56p0 移植 | r49p1 → r56p0（UK 1.30 → 1.39） | 同步升级 Arm 闭源 blobs | 未验证 |
| **Plan B：仅换用户态** | **保持 r49p1 不动** | **PanVK (Mesa 26.3)** | **loader/WSI 已 pass，游戏未测** |

Plan B 若成立，则"移植 R56p0"这件事可能**本身就不是达成目标的最短路径**。
这是本次审计必须正面回答的战略问题，但**不属于 `02` 的结论范围**，仅在此登记线索。

## 未获取

- Mesa 主体源码（`src/`、`apps/`、`tests/`、`snapshots/` 等）——需要时按具体路径单独取。
- 完整文件索引（tree 响应被截断）。

## 补充获取：kbase 对接补丁层（2026-11-15 13:20）

仓库是 **pinned 上游 Mesa 的 patch 层**，不含 `src/`。它对 kbase 的全部认知浓缩在 12 个 patch 中，
已按路径单独取回（192 KB），保持原目录结构落于 `patches/` 与 `profiles/`：

| 文件 | 大小 | 与 kbase 的关系 |
| --- | --- | --- |
| `patches/csf/007-gpu-queue-kbase.patch` | 84,693 | **CSF 队列提交路径**（最大，直接对应 kbase CSF ioctl） |
| `patches/kbase-common/004-physical-device-kbase.patch` | 32,508 | 设备创建、能力探测 |
| `patches/kbase-common/006-device-queue-wsi-kbase.patch` | 21,947 | 队列与 WSI |
| `patches/kbase-common/003-pan-kmod-backend-hooks.patch` | 11,610 | 后端钩子 |
| 其余 8 个 patch | 共 39,860 | meson 选项、BO munmap、CSIF 初始化、FD 属性、扩展开关 |
| `profiles/*.json` | 1,641 | v10 / v11 / v12 三份 profile（**无 v13**） |

### 交叉验证：PanVK 不依赖 r56p0 的 ABI 破坏项

R56p0 在 UK 1.39 **移除**了两个 ioctl。对 PanVK 补丁层做全量检索：

| ioctl | PanVK 引用次数 |
| --- | --- |
| `KBASE_IOCTL_SET_LIMITED_CORE_COUNT` | **0** |
| `KBASE_IOCTL_DISJOINT_QUERY` | **0** |

`[限定]` 该结论只说明补丁层未直接引用这两个符号；Mesa 的 `pan_kmod` 若以数字常量或封装函数调用，
此处检索不到。要完全排除，需在真机上跑 `strace -e ioctl` 抓实际调用序列。

**含义**：若选择 Plan B（保留 UK 1.30 内核 + PanVK 用户态），R56p0 的这条 ABI 破坏**不构成障碍**。
反过来，若坚持主线（升级到 UK 1.39），则需另行确认**闭源 blobs**是否调用了这两个 ioctl —— 这与 PanVK 无关。

### PanVK 对本审计的定位（结论）

| 用途 | 是否成立 |
| --- | --- |
| 独立印证 MT6991 出厂 kbase = UK 1.30 | ✅ 7 台设备互证 |
| 提示"不改内核、只换用户态"的 Plan B 路线 | ✅ 5 台 G925 设备 loader/WSI pass |
| 交叉验证 R56p0 的 ABI 破坏项是否影响该路线 | ✅ 引用次数为 0 |
| 作为 G925 适配证据、或 R56p0 可移植性依据 | ❌ **不成立**，且违背审计红线第 5 条 |
| 作为主力方案（日常使用级） | ❌ 仅验证到 loader/WSI，游戏与翻译层全部 `untested` |
