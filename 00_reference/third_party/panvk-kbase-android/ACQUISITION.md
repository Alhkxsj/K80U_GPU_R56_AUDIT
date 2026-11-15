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

| 设备 | 代号 | SoC | GPU | panArch | 前端 |
| --- | --- | --- | --- | --- | --- |
| 2506BPN68G | klimt | MT6991 | Mali-G925-Immortalis MC12 | 13 | CSF |
| 2602BPC18G | dash | MT6991 | Mali-G925-Immortalis MC11 | 13 | CSF |
| SM-X736B | gts11 | MT6991 | Mali-G925-Immortalis MC12 | 13 | CSF |
| V2413 / V2419A | k6991v1_64 | MT6991 | Mali-G925-Immortalis MC12 | 13 | CSF |

解读边界：

- 只能说明 **PanVK 已覆盖 MT6991 + G925 + CSF 这一组合**；
- **不能**说明这些机型的 kbase 版本、DTS、电源时序与 K80 至尊版一致；
- `kbase` 字段在上表条目中均为 `null`，即该库未记录这些机型的 kbase 版本。

## 未获取

- Mesa 主体源码（`src/`、`apps/`、`tests/`、`snapshots/` 等）——需要时按具体路径单独取。
- 完整文件索引（tree 响应被截断）。
