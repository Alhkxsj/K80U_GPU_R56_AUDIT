# `__versions` 符号表（第三轮派生）

> 来源：真机 `readelf -x __versions` 的 hexdump（`F_ged_versions.txt` / `F_mali_kbase_mt6991_r49_versions.txt`），由审计侧**离线**解析成结构化文本。
> 本目录**只有文本**，不含任何 `.ko` 字节。

---

## 1. 为什么不能直接 `grep`

`readelf -x` 每行只给 16 字节，右边 ASCII 列会在第 16 字节处硬折行。符号名跨行时被拆成两段，例如：

```
0x00007fc0 a5f8ac9e 00000000 6b737472 6e647570 ........kstrndup
```

若符号是 `kbase_ioctl_...` 这类长名，`grep kbase` 可能一条都搜不到（假阴性）。**必须先把 hex 列还原成连续字节流，再按记录切分。**

## 2. 记录结构

`__versions` 每条记录 **64 字节**：

| 偏移 | 长度 | 内容 |
| ---: | ---: | --- |
| 0x00 | 4 | `crc`（小端 u32，内核 `modversions` CRC） |
| 0x04 | 4 | 保留（全 0） |
| 0x08 | 56 | 符号名（NUL 结尾，定长 56） |

## 3. 复现命令

```bash
# 1) 设备侧取 hexdump（只读）
readelf -x __versions /vendor_dlkm/lib/modules/mali_kbase_mt6991_r49.ko > F_kbase.txt

# 2) 审计侧解析（Python 3，无第三方依赖）
python3 - <<'PY'
import re, struct
data = bytearray()
for line in open('F_kbase.txt', errors='replace'):
    m = re.match(r'\s+0x([0-9a-fA-F]+)\s+((?:[0-9a-fA-F]{8}\s+){4})', line)
    if m:
        for g in m.group(2).split():
            data += bytes.fromhex(g)          # 注意：不要做字节反转
for i in range(0, len(data) - 63, 64):
    crc = struct.unpack('<I', data[i:i+4])[0]
    name = data[i+8:i+64].split(b'\x00')[0].decode('utf-8', 'replace')
    if name:
        print(f"{name}\t{crc}\t0x{crc:08x}")
PY
```

> 踩过的坑：把 4 组 u32 当小端字再反转，会得到 `etumol_x` 这种倒序名。`readelf -x` 打印的是**内存字节顺序**，直接拼即可。

## 4. 校验点

| 校验 | 期望 | 实测 |
| --- | --- | :---: |
| `ged.ko` 记录数 | 241 | ✅ |
| `kbase` 记录数 | 513 | ✅ |
| 两模块 `module_layout` CRC | 相同 | ✅ `0x4e276f37` |
| `kbase` 中 MTK 侧符号 | 84 | ✅ 49+16+4+15 |
| `ged.ko` 中 `kbase` 符号 | 0 | ✅ |

## 5. 文件说明

| 文件 | 行数（不含表头） | 列 |
| --- | ---: | --- |
| `ged_versions.tsv` | 241 | `symbol` / `crc32`(十进制) / `crc_hex` |
| `kbase_versions.tsv` | 513 | 同上 |
| `kbase_mtk_side.tsv` | 84 | `symbol` / `crc_hex` / `category`（`ged_` / `gpufreq_` / `gpueb_` / `mtk_`） |

`kbase_mtk_side.tsv` 是 `kbase_versions.tsv` 的**子集**，不是新增符号；分类规则：

- `ged_` — 以 `ged_` 开头（49 条）
- `gpufreq_` — 以 `gpufreq` 开头（16 条）
- `gpueb_` — 以 `gpueb_` / `wait_gpueb` 开头（4 条）
- `mtk_` — 以 `mtk_` 开头（15 条）

## 6. 这些表的用途

1. **U4-24b**：设备构建的 `__ksymtab` 期望 CRC 基线，用于将来比对另一版 `kbase.ko` 是否可装载。
2. **U4-22**：`kbase` 对 MTK 侧的 84 条符号级硬依赖清单。
3. **U4-25**：若换内核/换模块，`disagrees about version of symbol` 报错可直接定位到具体符号与 CRC。
4. **REA 对照**：反汇编 `libGLES_mali.so` 时，这些名字可用来识别调用点（`kbase` 侧对应导出名）。
