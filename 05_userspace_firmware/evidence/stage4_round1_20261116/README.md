# Stage 4 第一轮真机采集证据（2026-11-16 09:01 / 09:02）

## 这批东西是什么

用户于 2026-11-16 09:01 与 09:02 在 Redmi K80 至尊版上执行 `05_userspace_firmware/tools/collect_stage4_remainder.sh` **v1.0**，回传 `GPU_AUDIT_STAGE4.zip`。

**必须记住的前提：v1.0 有输出缺陷。** `say()` 会同时写终端与文件，但脚本里 43 处原始命令管道（`od` / `readelf` / `grep` / `dumpsys`）只写 stdout、不进文件。结果是：

| 类型 | v1.0 是否落盘 |
| --- | --- |
| `say` 拼接的行（含计数、路径、sha256、gpuinfo 值） | ✅ 有 |
| 原始命令的输出（十六进制字节、mount 行、dmesg 行、符号表） | ❌ **丢失** |
| `__versions` 转储（`> 文件` 重定向） | ✅ 有（独立文件） |

因此本目录只收录**确实拿到**的部分；缺口清单见 `06_porting_design/STAGE4_DEVICE_COLLECTION_PLAN.md` §9。v1.1 已修复该缺陷（所有输出统一经 `tee` 落盘，文件内容 ≡ 终端内容）。

## 文件清单

| 文件 | 内容 | 来源 |
| --- | --- | --- |
| `kbase_imports.tsv` | `mali_kbase_mt6991_r49.ko` 的 **513** 条 import 符号 + CRC32 | `F_mali_kbase_mt6991_r49_versions.txt` 解析 |
| `ged_imports.tsv` | `ged.ko` 的 **241** 条 import 符号 + CRC32 | `F_ged_versions.txt` 解析 |
| `mtk_side_symbols.md` | 上表中筛出的 **84** 条 MTK 侧符号（`ged_*` / `gpufreq_*` / `gpueb_*` / `mtk_*` / `wait_gpueb`） | 同上 |

原始转储（`F_*.txt`，63 KB / 135 KB）**未入库**，只登记 SHA256：

```
F_ged_versions.txt                 63660 B  934556f5ad33ffdc42f50dd3b4d59e91196ddc53c548f9496b28f754fd0ec771
F_mali_kbase_mt6991_r49_versions.txt 135468 B  b8f118d283d04cfb992d917a57c46ff61b807054eeebdec52cee3ac71624d9a9
```

对应模块本体（不入库，仅登记）：

```
/vendor_dlkm/lib/modules/ged.ko                     1093352 B  e4ff2a35e3019a97aa587e7453a62b5bed595b6d9b76a29ab245cf0e515c50b8
/vendor_dlkm/lib/modules/mali_kbase_mt6991_r49.ko   2328064 B  ad0e0ff25a2918a2e0820257d415b69db60cf6cd72753114c7dcc42fc85b1fa8
```

## 解析方法（可复现）

`readelf -x __versions` 的输出是每行 16 字节的十六进制。`__versions` 每条记录 **64 字节**：

```
offset 0..3   u32 crc          （小端）
offset 4..7   u32 pad
offset 8..63  char name[56]    （NUL 截断）
```

把十六进制按行号拼成字节流后每 64 字节切一条即可。校验点：`kbase_imports.tsv` 首条应为 `0xd5977bfb  mutex_lock`。

## 三条可直接引用的事实

1. **`module_layout` 的 CRC 在两个模块上相同**：`0x4e276f37`。说明两者针对同一内核构建、同一结构体布局约束编译。
2. **`ged.ko` 不 import 任何 `kbase` 符号**（在 241 条里搜 `kbase` 为空）。这与 Stage 3 的"MTK 平台层对 kbase 零反向依赖"定理**逐条吻合**——换 kbase 不会打破 ged 的链接，只会因 kbase 缺失而少一个消费者。
3. **R49 kbase 依赖 84 条 MTK 侧符号**，覆盖 GED 事件通道（`ged_mali_event_*`）、DVFS（`ged_dvfs_*`、`gpufreq_*`）、GPUEB 邮箱（`gpueb_*`、`wait_gpueb`）、SWPM/PMU（`mtk_swpm_*`、`mtk_ltr_gpu_pmu_*`）、EMI 带宽（`mtk_bandwidth_resource_init`）。这 84 条就是 R56 kbase / R49-derived DDK 必须对齐的**接口面**。

## 边界

- 本目录**不含**任何 `.ko` / `.so` / `.bin` / 固件字节，只有符号名与 CRC 数值（公开可见的 ABI 元数据）。
- CRC 数值**只对这台设备的这次构建**有效。**不得**把这里的 CRC 复制到其它设备或其它构建的结论里（`AGENTS.md` 禁止表述 ⑤）。
- `kCFI` 类型哈希（`__kcfi_typeid_*` 节）**本轮没有采集**，U4-24b 的这一半仍开放。
