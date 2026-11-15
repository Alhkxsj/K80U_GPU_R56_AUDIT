# GPU 内核模块身份核验 —— 手机端执行指南（U4-24）

> **这份文件解决什么**：`U4-24` 需要设备侧 GPU `.ko` 的**真实路径 / 文件大小 / SHA256 / vermagic**。已有三份 Stage 4 采集只有 `lsmod` 输出（模块名、内存尺寸、refcount、use-by），**不含**上述四项——所以必须补一次只读采集。
>
> **你会跑什么**：`collect_gpu_module_identity.sh`，纯只读，输出一份 `.txt`。
>
> **不会发生什么**：不复制、不压缩、不导出、不上传任何 `.ko`；不改系统属性、不改内核参数、不装卸模块、不动分区。

---

## 0. 前置条件

| 项 | 要求 |
| --- | --- |
| 设备 | 已 root（`su` 可用），已装 aShell You 或任意能拿到 root shell 的 App |
| 网络 | 仅方式 A 需要（下载脚本本身，约 13 KB） |
| 时间 | 约 10–40 秒；`sha256sum` 要算 15 个模块（合计约 4 MB），不慢 |
| 磁盘 | 输出文本约 40–80 KB，写在 `/data/local/tmp` |

> 若 `su` 不可用，脚本仍能跑，但 `/vendor_dlkm` 可能不可读，`FILE_SHA256` 会大量出现 `NOT_READABLE`。这种情况**结果无效**，不要发回来。

---

## 1. 方式 A：一条命令下载并执行（推荐）

在 aShell You 里先 `su`，再执行：

```sh
su
curl -fsSL -o /data/local/tmp/c.sh \
  https://gh-proxy.com/https://raw.githubusercontent.com/JiangXue5/K80U_GPU_R56_AUDIT/main/05_userspace_firmware/tools/collect_gpu_module_identity.sh
sh /data/local/tmp/c.sh
```

如果 `gh-proxy.com` 不通，把前缀换成任意一个可用镜像：

```sh
# 任选其一
https://ghfast.top/https://raw.githubusercontent.com/...
https://raw.gitmirror.com/JiangXue5/K80U_GPU_R56_AUDIT/main/...
https://cdn.jsdelivr.net/gh/JiangXue5/K80U_GPU_R56_AUDIT@main/...
```

**成功标志**：屏幕最后出现

```
CANDIDATES:     25
LOADED:         13
FILE_FOUND:     ...
HASHED:         ...
END: ...
OUTPUT_WRITTEN: /data/local/tmp/gpu_audit_mod/stage4_mod_XXXXXXXX_XXXXXX.txt
```

---

## 2. 方式 B：不联网，手工建文件

1. 在电脑或手机上打开仓库文件页：
   `https://github.com/JiangXue5/K80U_GPU_R56_AUDIT/blob/main/05_userspace_firmware/tools/collect_gpu_module_identity.sh`
2. 点 **Raw**，全选复制。
3. aShell You → 切到 `/data/local/tmp` → 新建文件 `c.sh` → 粘贴 → 保存。
4. 执行：

```sh
su
sh /data/local/tmp/c.sh
```

> 注意：aShell You 的编辑器可能把换行转成 CRLF。若执行时报 `: not found`，先跑
> `tr -d '\r' < /data/local/tmp/c.sh > /data/local/tmp/c2.sh && sh /data/local/tmp/c2.sh`。

---

## 3. 取回结果

```sh
su
cat /data/local/tmp/gpu_audit_mod/stage4_mod_*.txt
```

或者先 `ls` 确认文件名再 `cat` 具体那一个。**直接整份贴回即可**，不需要挑选。

> 输出里不含路径之外的个人信息：没有 IMEI、没有序列号、没有账号、没有 IP。
> `SELINUX:` 行会显示 `context=u:r:su:s0` 之类，属正常。

---

## 4. 怎么读这份输出（判读表）

### 4.1 最关键的三行

每个模块段落里，先看这三行：

```
VERMAGIC_CHECK:            6.6.143-android15-8-gf9aa2fec23c3-4k SMP preempt ...
VERMAGIC_MATCHES_UNAME_R:  YES / NO
FILE_SHA256:               <64 位十六进制>
```

| 实测 | 含义 | 对 U4-24 的作用 |
| --- | --- | --- |
| `YES`（且串含 `6.6.143-...-gf9aa2fec23c3-4k`） | 设备模块正是为本机内核构建的 | **坐实"设备 `.ko` 是另一次构建"**，`[E2]` 升 `[D·C]` |
| `NO`，串含 `6.6.118-...-g57e634f35c1b` | 设备上放的是仓库那批 | **D-007 被推翻**，须重写 `08` §3 与 `07` §3.4 |
| `NO`，串是第三种（如 `6.6.143-...-g<别的哈希>`） | 内核与模块来自不同构建 | 比"另一次构建"更强的结论：**设备本身是混装** |
| `NOT_FOUND` | 该 `.ko` 被 strip 掉 `.modinfo`，或读到的是压缩容器 | 记 `UNKNOWN`，改用 `readelf -p .modinfo` 兜底 |

### 4.2 其它行

| 字段 | 怎么用 | 陷阱 |
| --- | --- | --- |
| `LSMOD_SIZE_BYTES` | 运行时内存占用（`core_layout.size`） | **不是文件大小**，绝不可与仓库 `.ko` 字节数直接相减 |
| `FILE_SIZE_BYTES` | 真实的磁盘文件大小 | 这个才能与仓库比对 |
| `SYSFS_VERSION` | `MODULE_VERSION()` 的展开值，如 `r49p1-03bet0 (UK version 1.30)` | 只有声明过 `MODULE_VERSION` 的模块才有；空 = 该模块没声明 |
| `SYSFS_SRCVERSION` / `MODINFO srcversion` | 源码级构建指纹 | 仓库 15 个里**只有 4 个 mali 模块有**，另外 11 个没有 → **不可跨模块比较** |
| `SYSFS_BUILDID_HEX` | 内核导出的 ELF note（末尾 20 字节即 Build ID） | 与 `ELF_BUILD_ID` 应一致；不一致说明 sysfs 与磁盘文件**不是同一份** |
| `SEC __versions size=0x…` | 该模块导入的受版本校验符号表大小 | 每条 12 字节；用它可估"重导工作量" |
| `FILE_COMPRESSED_CANDIDATES` | 只找到 `.ko.gz/.zst/.xz` | 压缩容器哈希 ≠ 解压后哈希，**不能**与仓库比对 |
| `BUILTIN_HINT` | 该模块被编进内核（`=y`）而非独立 `.ko` | 此时没有文件可核，只能记 `[U]` |

### 4.3 一个必须注意的坑

`FILE_FOUND` 可能小于 `LOADED`。这**不代表脚本坏了**，常见原因：

1. 模块在 `vendor_boot` / `init_boot` 的 ramdisk 里（没有独立 `.ko` 路径）；
2. 模块名与实际文件名不同（如 `mali_kbase_mt6991_r49` vs 目录里的 `mali_kbase.ko`）；
3. 路径不在脚本列的 7 个搜索根里 → 看 §5「目录扫描」段，那里是 `find` 全扫结果。

**遇到 (3) 时请把「目录扫描」整段发回来**，我据此补搜索根。

---

## 5. 兜底：脚本完全跑不起来时，逐条手打

这些命令只输出文本，同样不复制任何文件。

```sh
su

# 1) 内核与模块清单
uname -r
grep -E '^(mali_|ged |mtk_gpu|mtk_gpufreq|mtk_ghpm)' /proc/modules

# 2) 模块目录在哪
ls -d /vendor_dlkm/lib/modules /vendor/lib/modules /vendor/lib64/modules 2>/dev/null
ls /vendor_dlkm/lib/modules/ 2>/dev/null | head -40

# 3) 单个模块的 vermagic（换 $M 为实际名）
M=mali_kbase_mt6991_r49
strings -a /vendor_dlkm/lib/modules/$M.ko | grep -E '^(vermagic|srcversion|version|name)='
sha256sum /vendor_dlkm/lib/modules/$M.ko
wc -c < /vendor_dlkm/lib/modules/$M.ko

# 4) 如果上面路径不存在，用 find 定位
find /vendor_dlkm /vendor/lib -name "$M.ko" 2>/dev/null

# 5) Build ID（sysfs 与磁盘各一份，应一致）
od -An -tx1 /sys/module/$M/notes/.note.gnu.build-id
readelf -n /vendor_dlkm/lib/modules/$M.ko | grep 'Build ID'
```

**最少要回传的**：`uname -r` + 至少 3 个模块（`mali_kbase_mt6991_r49`、`ged`、`mtk_gpufreq_wrapper`）的 `vermagic` 与 `sha256sum`。

---

## 6. 失败排查

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `Permission denied`（大量） | 没 `su`，或 SELinux 拒绝 | 确认提示符是 `#`；再试 `su -c 'sh /data/local/tmp/c.sh'` |
| `curl: not found` | 系统无 curl | 用方式 B；或用 `wget -O /data/local/tmp/c.sh <url>` |
| 所有 `FILE_PATH: NOT_FOUND` | 模块目录名与预期不同 | 跑 §5 第 2、4 条，把结果发回 |
| `sha256sum: NOT_AVAILABLE` | 极少数 ROM 无此工具 | 不影响 vermagic 判定；`sha256sum` 可由 `toybox sha256sum` 替代 |
| `readelf: NOT_AVAILABLE` | 无 llvm 工具 | 不影响核心判据；Build ID 缺一条 |
| 输出被截断 | aShell You 显示上限 | 先 `wc -l` 看行数，再用 `head -n 200` / `tail -n +200` 分段贴 |
| 脚本报 `syntax error` | 文件被 CRLF 化 | 见 §2 末尾的 `tr -d '\r'` |

---

## 7. 这次采集的验证边界（如实声明）

| 已做 | 未做 |
| --- | --- |
| `sh -n`（dash）与 `bash -n` 双通过 | **未在任何 Android 设备上运行过** |
| 用伪造 `/proc/modules` + 伪 sysfs + 伪 `.ko` 演练 5 条分支：<br>vermagic 与 `uname -r` 一致 → `YES`<br>vermagic 不一致 → `NO`<br>只有 `.ko.gz` → `FILE_COMPRESSED_CANDIDATES`<br>文件缺失 → `NOT_FOUND` + `BUILTIN_HINT`<br>无 `/vendor` → 全 `NOT_FOUND`，退出码仍为 0 | 未验证 Android `toybox strings` 对 2.3 MB `.ko` 的行为是否与 GNU `strings` 一致（预期一致，`-a` 已显式要求全文扫描） |
| 缺工具时输出 `NOT_AVAILABLE` 且不中断（宿主上 `modinfo`/`xxd` 实测走通该分支） | 未验证 SELinux 对 `/sys/module/*/notes/` 的读取策略（若拒绝会显示 `NOT_READABLE`，属预期降级） |
| 无 `/vendor` 环境下退出码 0、stderr 为空 | — |

---

## 8. 采完之后我怎么处理

1. 设备 `vermagic` 与仓库 `6.6.118-…-g57e634f35c1b` 比对 → 决定 `U4-24` 是否闭合；
2. `FILE_SHA256` 与仓库 15 个模块哈希逐项比对 → 有无任何一个是同一二进制；
3. `srcversion` 比对（仅 4 个 mali 模块可比）→ 判定是否同源码上下文；
4. 依 `08_kernel_provenance_audit.md` §3.6 的判定矩阵，给出**kCFI 类型哈希 / `__versions` CRC 是否需要重导**的结论；
5. 同步 `07` / `08` / `MANIFEST` / `PROJECT_STATE`，新增或修订决策条目。

> **在输出回传之前，`U4-24` 保持 `UNKNOWN`。** 本仓库不会因为"脚本写好了"就把该项记为闭合。
