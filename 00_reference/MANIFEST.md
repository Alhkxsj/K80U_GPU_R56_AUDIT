# MANIFEST — 00_reference

> 登记本目录下所有留存文件。Stage 0 阶段为空表，随资料采集逐条追加。

## 文件清单

| 文件 | 类别 | 来源 | 版本 / 标识 | 采集日期 | 采集方式 | SHA256 |
| --- | --- | --- | --- | --- | --- | --- |
| `third_party/panvk-kbase-android/`（17 个文件，约 272 KB） | 第三方源码参考 | `zenithblue-oss/panvk-kbase-android` @ `cf70e02` | `main` / `panvk-kbase-v26.3.1` | 2026-11-15 | GitHub REST contents API（只读） | 明细见 `ACQUISITION.md` |
| `third_party/panvk-kbase-android/docs/MALI-VULKAN-NATIVE-FEATURES.md` | 特性矩阵 | 同上 | 98,561 B | 2026-11-15 | 同上 | `0ffbae0c48dea71d` |
| `third_party/panvk-kbase-android/docs/MALI-GPU-ARCHITECTURES.md` | 架构对照 | 同上 | 24,702 B | 2026-11-15 | 同上 | `a499e41dbfea552b` |
| `third_party/panvk-kbase-android/docs/KBASE-SPARSE-FEASIBILITY.md` | ABI 参考 | 同上 | 15,462 B | 2026-11-15 | 同上 | `b091960cc5b7d436` |
| `third_party/panvk-kbase-android/docs/KBASE-PROFILES.md` | 配置档位 | 同上 | 701 B | 2026-11-15 | 同上 | `36570c8121851a2f` |
| `third_party/panvk-kbase-android/compatibility/devices.json` | 兼容库 | 同上 | 77 条设备记录 | 2026-11-15 | 同上 | `f0ecdcf2404772c1` |

## 登记规则

1. 一文件一行，新增文件必须先登记后提交。
2. 版本列优先填写文件内提取的版本串，而非文件名推断。
3. 外部资料以链接形式存档时，"文件"列填标题，"采集方式"列填 URL 与访问日期。
4. 采集日期格式 `YYYY-MM-DD`。
5. 非权威线索类资料，在版本列前加 `[非权威]` 标记。
