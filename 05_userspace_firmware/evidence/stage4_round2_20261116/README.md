# 第二轮真机采集证据（2026-11-16 13:13）

> 对应任务：`TASK-STAGE4-REMAINDER` 的第三项（最小真机只读采集）**执行后的判读**。
> 原始报告：`stage4_remainder_20261116_131307.txt`，**56,138 B / 770 行**，`SELFCHECK: 数据行数 = 668`。
> 采集脚本：`05_userspace_firmware/tools/collect_stage4_remainder.sh` **v1.1**（本轮执行）→ 已修至 **v1.2**。
> 执行环境：Redmi K80 至尊版（`25060RK16C` / `dali`），Root（`u:r:ksu:s0`），aShell You，**无电脑参与**。

---

## 1. 本目录只放文本

| 文件 | 内容 | 大小 |
| --- | --- | ---: |
| `README.md` | 本文件：采集结果评估、脚本缺陷、边界声明 | — |
| `firmware_header.md` | 固件 header 逐字段解析、entry 首项解码、截断检查、R56 0.4 硬校验 | — |
| `key_readings.md` | 十二组关键读数与台账影响、四条不采用数据的理由 | — |

**未入库**：原始 `stage4_remainder_*.txt`（56 KB）、`F_*_versions.txt`（135 KB / 63 KB）。
本目录**不含任何 `.ko` / `.so` / `.bin` / 固件字节**，只有解析后的文本结论。

---

## 2. 这一轮成功了：v1.1 的输出通道修复有效

| 指标 | 第一轮（v1.0） | 第二轮（v1.1） | 阈值 |
| --- | ---: | ---: | --- |
| 报告大小 | ~3 KB | **56,138 B** | — |
| 总行数 | ~60 | **770** | — |
| **`SELFCHECK: 数据行数`** | 缺失（v1.0 无此项） | **668** | **> 300 才算成功** |
| 文件内容 ≡ 终端输出 | ❌ | ✅（本机验证 `diff` 0 行） | — |

第一轮的缺陷是**脚本单通道设计错误**（43 处原始命令管道只写 stdout、不落盘），已在 v1.1 修复并验证。第二轮的每一段都有实质内容，不再只有标题。

**各段数据行数**（A–K + Z）：

```
A 环境与指纹              35      G OEM MTK 扩展            47
B 固件 header/尾部        22      H dmesg 线索              76
C mount/overlay           93      I debugfs                  8
D 内核 build-id           25      J ELF 元数据             194
E GPU 产品识别            55      K 属性面/holders         139
F __versions（独立文件）  47      Z 结束                    15
```

---

## 3. 但 v1.1 有三处**判读**缺陷（数据取到了，标签贴错了）

这三处不影响 `key_readings.md` 的任何结论，但**不能再被引用**。已在 v1.2 全部修正。

| # | 缺陷 | 表现 | 根因 | v1.2 修法 |
| ---: | --- | --- | --- | --- |
| 1 | **`/proc/modules` 列错位** | 输出 `taint=0x0000000000000000`，看起来像"所有模块无 taint" | 用 `$6` 当 taint，实际第 6 列是**加载地址**（`kptr_restrict` 下为 0）。列序是 `name size refs deps state address` | 改打印 `deps`（第 4 列，即"被谁依赖"）；taint 改读 `/proc/sys/kernel/tainted` |
| 2 | **note 偏移错 4 字节** | `build-id: 474e5500c5eac1f0...`，`474e5500` 是 ASCII `"GNU\0"` | 固定 `-j 12 -N 20`，但 note 布局是 `namesz(4) descsz(4) type(4) name(对齐) desc`，desc 实际在 `12+align4(namesz)=16` | 先读 `namesz/descsz` 算偏移，并打印 `note hdr` 自证 |
| 3 | **符号统计正则顺序反了** | `GLOBAL DEFAULT FUNC: 0`，看起来像"库不导出函数" | readelf 列序是 `FUNC GLOBAL DEFAULT`，脚本写成 `GLOBAL.*DEFAULT.*FUNC`，永不匹配；叠加 `\|\| echo 0` 还多打一个 `0` | 改为 `FUNC.*GLOBAL.*DEFAULT`；新增 `defined (Ndx!=UND)` 计数与已定义符号样本 |

另有二处小问题一并修掉：

| # | 问题 | 修法 |
| ---: | --- | --- |
| 4 | `vulkan.mali.so` 的 `size: 21` 是符号链接自身长度 | `fsize` 改用 `stat -Lc %s`，并打印 `symlink ->` 目标 |
| 5 | `E-3` 小节标题叫"taint 列"，与实际内容不符 | 改为"模块表：refs / deps / state" |

**修正验证**（本机，2026-11-16）：

```
构造 note: namesz=4 descsz=20 name="GNU\0" desc=0c637c...3408
  v1.2 : 0c637c57d1ad6f81f4de95c6dbbc92a8f9153408   ← 正确
  v1.1 : 474e55000c637c57d1ad6f81f4de95c6dbbc92a8   ← 把 "GNU\0" 算进去了

/bin/ls 的 dynsym:
  FUNC (v1.2) : 114      FUNC (v1.1) : 0      ← 确认 v1.1 是假 0
  defined (Ndx!=UND) : 7
```

`sh -n` / `bash -n` 通过；空环境端到端冒烟 `EXIT=0`，`diff` 终端与文件 0 行差。

---

## 4. 影响：不需要重跑全量

三处缺陷中，只有 #3 造成了一项实质缺口：**U4-23 需要 `libgpud` 与 `libgpud_sys` 的导出符号对照，本轮没拿到**（样本里全是 UND）。

补采一条命令即可（只读，两行输出）：

```sh
readelf --dyn-syms -W /vendor/lib64/libgpud.so | awk '$1 ~ /^[0-9]+:/ && $7 != "UND"'; echo "--- sys ---"; readelf --dyn-syms -W /system_ext/lib64/libgpud_sys.so | awk '$1 ~ /^[0-9]+:/ && $7 != "UND"'
```

**其余项都不需要重跑**：#1 的 taint 本来就不参与任何结论；#2 的模块 build-id 对 U4-26 无影响（该判据用的是**内核** build-id，已从 `/sys/kernel/notes` 完整取得 20 字节）。

---

## 5. 这一轮闭合/推进了什么（详见 `key_readings.md` 与台账）

| 项 | 变化 | 依据 |
| --- | --- | --- |
| **U4-20** SF RenderEngine 后端 | OPEN → **CLOSED** | `RE GLES (Ganesh)` |
| **U4-26** 设备 boot 是否即 CI 产物 | OPEN → **CLOSED**（设备侧） | 内核 build-id `0c637c57...` |
| **U4-27** `/vendor` 是否被 overlay | OPEN → **CLOSED** | `/vendor` = erofs 只读，无 overlay |
| **U4-11** 固件 `entry_end_offset` | OPEN → **PARTIAL** | `entry_end_offset = 1000` 首次取得 |
| **U4-17** Vulkan 薄壳 | OPEN → **PARTIAL** | 确认为桩，真实现在 `libGLES_mali.so` |
| **U4-21** 服务硬依赖 `/dev/mali0` | OPEN → **PARTIAL** | 25 个进程持有 |
| **U4-23** `libgpud` 符号关系 | OPEN → **PARTIAL** | NEEDED 全表已取，符号面待补 |
| U4-04c padding | PARTIAL（证据加强） | `Invalid reserved field not 0` 串 |
| U4-14 ioctl 55 | PARTIAL（证据加强） | `kbasep_ioctl_set_limited_core_count` 串 |

**计数：5 / 8 / 1 / 13 → 8 / 12 / 1 / 6**（CLOSED / PARTIAL / BLOCKED / OPEN，共 27）；**P0 仍 3**。

---

## 6. 边界声明

- 本轮全部操作**只读**：未复制、未导出、未压缩任何 `.so` / `.ko` / `.bin`。
- **未**装载/卸载/替换模块或固件；**未**写任何分区；**未**重启；**未**做故障注入。
- 采集脚本**未**在仓库外分发；执行由用户在本机完成，本轮只做判读。
- 证据边界：以上 CRC、SHA256、版本串**只对本机这次构建有效**，**不得**复制到其它设备或其它构建（`AGENTS.md` 禁止表述 ⑤）。

---

## 7. 引用

- `05_userspace_firmware/tools/collect_stage4_remainder.sh`（v1.2）
- `06_porting_design/STAGE4_DEVICE_COLLECTION_PLAN.md` §10（第二轮结果评估）
- `06_porting_design/STAGE4_REMAINING_AUDIT.md` §2 N-7、§4、§5
- `docs/DECISION_LOG.md` `D-034`
