# Stage 4 真机只读采集方案（合并版）

> **本文件做什么**：把 Stage 4 台账里**仍然 OPEN / PARTIAL 且可只读查证**的项目合并成**一次采集**，给出可直接在 aShell You 里执行的最小方案、判读标准与本方案的**能力边界**。
>
> **本文件不做**：不要求任何人现在就执行；不包含任何写操作、模块装卸、故障注入、刷机、替换。
>
> **配套脚本**：[`../05_userspace_firmware/tools/collect_stage4_remainder.sh`](../05_userspace_firmware/tools/collect_stage4_remainder.sh)（464 行，POSIX `sh`，无 adb 依赖）
>
> **不重复采集**：`stage4_inventory.txt` / `stage4_file_metadata.txt` / `stage4_elf_analysis.txt` / `stage4_p0_20261115_232021.txt` / `stage4_mod_20261116_000412.txt` 五份**已在库**，本方案**不再采其中任何一项**。

---

## 0. 一页概览

| 项 | 值 |
| --- | --- |
| 执行次数 | **1 次**（脚本内部分 11 段） |
| 预计耗时 | 1–3 分钟（`readelf -x __versions` 对大文件稍慢） |
| 需要权限 | **root**（`su`）；只读 |
| 输出目录 | **`/sdcard/GPU_AUDIT_STAGE4/`**（不可写时回退 `/data/local/tmp/GPU_AUDIT_STAGE4/`） |
| 产出 | 1 个主日志 + 2 个 `__versions` dump（纯文本） |
| 覆盖的 U4 项 | U4-02 / U4-04（部分）/ U4-06 / U4-11 / U4-12（辅证）/ U4-13 / U4-14 / U4-15（部分）/ U4-17（部分）/ U4-20 / U4-21 / U4-23（部分）/ U4-24b / U4-25b / U4-26 / U4-27 |
| 不覆盖 | U4-10 / U4-22（需故障注入）、U4-12 实体（需商业件）、U4-04c 的 padding 字节（见 §6） |

**一条命令（aShell You，已 root）**：

```sh
su -c 'mkdir -p /sdcard/GPU_AUDIT_STAGE4 && cp /sdcard/Download/collect_stage4_remainder.sh /sdcard/GPU_AUDIT_STAGE4/ && sh /sdcard/GPU_AUDIT_STAGE4/collect_stage4_remainder.sh'
```

> 若脚本放在别处，把 `/sdcard/Download/collect_stage4_remainder.sh` 换成实际路径即可。脚本自身会 `mkdir -p` 输出目录，`cp` 只是为了让"脚本与输出同目录"，便于回传。

---

## 1. 本批要解的具体缺口

| # | 缺口 | 卡住哪项 | 现状 |
| ---: | --- | --- | --- |
| 1 | 固件 `offset 0x10` 的 `entry_end_offset` | U4-11（U4-01 的唯一遗留） | 从未读到；只读到 0x00–0x0F |
| 2 | 固件尾部 32 字节 | U4-11 / U4-13 | 未采 |
| 3 | `/vendor` 是否被 overlay | U4-27 | 未采 mount 表 → 全部 `[D·A]` 结论都挂着一个"视图可能被改写"的问号 |
| 4 | 内核 `build-id` | U4-26 | 缺；`uname -v` 零信息量 |
| 5 | `gpuinfo` sysfs | U4-12 辅证 / U4-04a | 未采；这是唯一能直接读出"G925-Immortalis + 12 核 + product ID"的节点 |
| 6 | 设备 `__versions` 的 CRC | U4-24b | 未采；决定 Stage 3 二进制常量能否沿用 |
| 7 | 设备 kbase 是否编入 `CONFIG_MALI_MTK_FENCE_DEBUG` | U4-14 | 只知道**仓库基线**有，设备构建未验 |
| 8 | 固件启动行 / GLB 线索 | U4-02 / U4-11 | 无 dmesg |
| 9 | mali debugfs 有没有版本类节点 | U4-02 | 未枚举 |
| 10 | `vulkan.mali.so` / `libgpud*` / `libged` 的 ELF 元数据 | U4-17 / U4-23 / U4-22 辅证 | 只有部分（`vulkan.mali.so` 有 Build ID 与 NEEDED，`libgpud_sys.so` 完全没有） |
| 11 | EGL 搜索路径、SF 后端、`/dev/mali0` 占用者 | U4-06 / U4-20 / U4-21 | 未采 |

---

## 2. 明确**不**采的东西（已完成，勿重跑）

| 已完成的采集 | 覆盖内容 |
| --- | --- |
| `stage4_inventory.txt`（85,684 B） | 系统版本、模块清单、目录枚举、VINTF、DT、getprop 子集、`/dev` 节点 |
| `stage4_file_metadata.txt`（6,055 B） | 22 个关键对象的 size/perm/SHA256 |
| `stage4_elf_analysis.txt`（79,123 B） | 9 个 ELF 的头/动态段/Build ID/部分符号；固件的 `strings` |
| `stage4_p0_20261115_232021.txt` | 固件前 16 字节、DDK release 串 |
| `stage4_mod_20261116_000412.txt` | 18 个 `.ko` 的路径/大小/SHA256/vermagic/srcversion/节大小 |

> 本方案的 B 段（固件头）**只读 `0x10` 起的 24 字节与尾部 32 字节**，**不重复**读 `0x00–0x0F`（已有）。

---

## 3. 前置条件与风险

| 项 | 说明 |
| --- | --- |
| Root | 必需（读 `/vendor/firmware`、`/vendor_dlkm`、`/sys/kernel/notes`、`dmesg`） |
| 只读 | 全部为 `od` / `cat` / `strings` / `readelf` / `stat` / `sha256sum` / `ls` / `grep` / `dmesg` / `dumpsys` |
| 不装卸模块 | 全程无 `insmod` / `rmmod` / `modprobe` |
| 不改分区 | 全程无 `mount -o remount`、无 `setprop`、无写 `/vendor` `/system` |
| 无故障注入 | 不触发 GPU 异常、不断电、不重启 |
| 唯一"写" | 在 `/sdcard/`（或 `/data/local/tmp/`）**新增文本文件** |
| 工具缺失 | 脚本对每个工具做 `need` 检查，缺失输出 `NOT_AVAILABLE` 并继续，**不中断** |
| 可能受限项 | `dmesg` 可能被 `dmesg_restrict` 挡住；`/sys/kernel/debug` 可能未挂载；`/vendor_dlkm` 在某些机型是 `/vendor/lib/modules` |
| 失败即降级 | 上述任一受限只影响对应项目，其余照常产出 |

---

## 4. 执行步骤

### 4.1 把脚本放到手机

任选一种：

| 方式 | 操作 |
| --- | --- |
| A（推荐） | 把 `collect_stage4_remainder.sh` 复制到 `/sdcard/Download/` |
| B | 直接把内容粘贴进 aShell You 新建的脚本文件 |

### 4.2 执行（aShell You）

```sh
su -c 'sh /sdcard/Download/collect_stage4_remainder.sh'
```

若提示 `Permission denied`，先确认：

```sh
su -c 'id'
# 期望输出 uid=0(root)，且 id -Z 形如 u:r:su:s0 或 u:r:ksu:s0
```

### 4.3 查看产物

```sh
ls -l /sdcard/GPU_AUDIT_STAGE4/
```

期望看到：

```
stage4_remainder_<时间戳>.txt          ← 主日志
F_ged_versions.txt                     ← ged 的 __versions 十六进制
F_mali_kbase_mt6991_r49_versions.txt   ← kbase 的 __versions 十六进制
```

### 4.4 回传

| 回传什么 | 怎么回传 |
| --- | --- |
| 主日志 | **纯文本**，通常 < 100 KB |
| 两个 `__versions` dump | 可只回传 `sha256sum` 与**前 40 行**；若需要精确比对再回传全文（每份约 60–140 KB 文本） |
| **不要**回传 | 任何 `.so` / `.ko` / `.bin` / 分区镜像 |

---

## 5. 分段说明与判读标准

### A 段 · 环境与指纹

**采**：时间、UID、SELinux 域、机型、指纹、SDK、`uname -r/-v/-a`、工具可用性表。

**判读**：`uname -r` 应为 `6.6.143-android15-8-gf9aa2fec23c3-4k`（第三方）。若已回滚原厂，则记为 **[D·B-原厂]**，**不删除**旧记录（`D-005`）。

### B 段 · 固件头与尾（U4-11 / U4-13）

**采**：
- `offset 0x00–0x17`（24 字节）
- `offset 0x10` 的 `entry_end_offset`（DEC + HEX 两种）
- 文件末尾 32 字节
- 末 4096 字节的可打印串（最多 40 行）

**判读**：

| 字段 | 期望 | 说明 |
| --- | --- | --- |
| `0x04` | `03` | **已知 0.3**，此处仅作一致性复核 |
| `0x05` | `00` | major |
| `0x08–0x0B` | `00 00 0a 03` | `version_hash = 0x030A0000`；**不是 GLB 版本**，禁止解码 |
| `0x10–0x13` | 应是一个 `< 307200` 的 4 字节整数 | `entry_end_offset`；**这是本轮最想要的一个数** |

> **注意**：`entry_end_offset` **不是** GLB 版本，也**不是** U4-12 的答案。它只说明"固件 header 之后 entry 表有多长"。U4-11 的"GLB 尾部版本"若在尾部字符串里出现（例如形如 `v1.1.0`），才算命中；没有就仍是 OPEN。

### C 段 · mount / overlay（U4-27）

**采**：`/proc/self/mountinfo` 中 `vendor|overlay|magisk|ksu|susfs|apatch|worker` 相关行；`mount` 的 overlay/vendor 行；`/data/adb/*` 目录存在性。

**判读**：

| 观察 | 结论 |
| --- | --- |
| 无 ` - overlay ` 类型行、`/vendor` 来自 `/dev/block/...` | `/vendor` 视图**未被 overlay 覆盖** → 全部 `[D·A]` 结论可维持 |
| 出现 `overlay` 且 lowerdir 指向 `/vendor` | `/vendor` 被覆盖 → **全部 `[D·A]` 结论需重估**（这是本项目最严重的一类后果） |
| 出现 KSU/NoMount 的 bind mount | 同上，需逐条核对被 bind 的路径 |

> `/data/adb/modules` 存在**不等于**正在覆盖 `/vendor`。判定**只看 mount 表**。

### D 段 · 内核 build-id（U4-26）

**采**：`/sys/kernel/notes` 原始字节 + `readelf -n`；`/proc/version`；模块自身 `/sys/module/mali_kbase_mt6991_r49/notes/.note.gnu.build-id`。

**判读**：

| 观察 | 结论 |
| --- | --- |
| `/sys/kernel/notes` 含 `GNU\0` 且后随 20 字节 | 得到内核 build-id 的 SHA1 → 可与 CI 产物的 `Image` 比对 |
| `readelf -n` 无输出但 `od` 有字节 | 属正常（`notes` 不是标准 ELF），以 `od` 为准 |
| 完全读不到 | U4-26 仍 OPEN，退回"四项参数吻合"的 [E2] |

> **模块 build-id ≠ 内核 build-id**。前者只能证明"装载的就是盘上这份 `.ko`"。

### E 段 · GPU 产品识别（U4-12 辅证 / U4-04a）

**采**：`gpuinfo` sysfs（三个候选路径 + `find` 兜底）；`/proc/modules` 中 GPU 链路的 taint 列。

**判读**（`[E1]`：`mali_kbase_core_linux.c` 的 `gpuinfo_show()` 输出格式为 `"%s %d cores r%dp%d 0x%08X"`）：

| 观察 | 结论 |
| --- | --- |
| `Mali-G925-Immortalis 12 cores r0p0 0x…` | **CONFIRMED**：`GPU_ID_PRODUCT_TKRX` + 12 核 + RT 支持 → 与"Immortalis-G925 MC12"一致 |
| `Mali-G725 12 cores …` | TKRX 但 `nr_cores < 10` 或 RT 未报 → 需核对为何未识别为 Immortalis |
| `Mali-G625` 或核数 ≠ 12 | **与预期不符**，U4-12 的产品匹配性判断要重做 |
| taint 列含 `F` | 曾走强制装载（与 `D-021` 的判定相关） |

> 最后一个字段 `0x%08X` 是 **product_id 原始值**，可与 R56 kbase 的 `GPU_ID_PRODUCT_TKRX` 掩码比对 —— 这是 U4-12 验收判据第 3 条（core mask）的**唯一现成数据源**。

### F 段 · `__versions`（U4-24b）

**采**：`ged.ko` 与 `mali_kbase_mt6991_r49.ko` 的 `readelf -x __versions`，各自写入独立文件，并记录文件 size / sha256 / dump size / dump sha256。

**为什么是这两个、而不是 18 个**：

| 模块 | 作用 |
| --- | --- |
| `ged.ko` | **抽样**。设备与仓库的 `ged.ko` **文件字节数完全相同（1,093,352）**、`.text` 与 `__versions` 节大小相同 → 若其 CRC 也对得上，则"其余 13 个结构一致模块可沿用"这一推断成立（`D-022` 的可反驳条件） |
| `mali_kbase_mt6991_r49.ko` | **必须单独**。`+17,640 B`、`.text` `+6,788 B`、`__versions` `514 → 513` 条、`srcversion` 不同 → 它就是"必须重导"的那一个 |

**判读**：

| 观察 | 结论 |
| --- | --- |
| `ged` 的 CRC 与仓库基线**逐条相同** | 14 个模块可沿用（`D-022` 成立） |
| `ged` 的 CRC **有若干条不同** | `D-022` 被推翻 → 退回"逐模块重导" |
| 两份 dump 的 sha256 与仓库侧同名 dump 相同 | 更直接的证据（表示整节一致） |

> **边界**：`__versions` 记录的是"**本模块期望的内核导出符号 CRC**"，由**内核构建**决定。因此它证明的是"内核导出面一致"，**不是**"kbase 自身的常量一致"。kbase 的 513 条必须自己看。
>
> **不建议**只回传 `sha256sum` 就宣称闭合——必须先有一份"参照 dump"（仓库基线同名模块）才能比对，本方案不预设该参照已存在。

### G 段 · OEM kbase 是否编入 MTK 扩展（U4-14）

**采**：对 `/vendor_dlkm/lib/modules/mali_kbase_mt6991_r49.ko` 做 `strings`，统计三组关键串的命中数：
- `Internal fence wait` → `CONFIG_MALI_MTK_FENCE_DEBUG`
- `Internal fence timeouts` → `FENCE_TIMEOUT_RESET` / 跨队列恢复路径
- `ged_mali_event_notify_fence_timeout_event` → MBRAIN 通道
- 另：`Invalid reserved field not 0` → R49 内联 padding 校验的日志面

**判读**：

| 观察 | 结论 |
| --- | --- |
| `Internal fence wait` 命中 > 0 | **ioctl 80 在设备构建上可达** → 若 R49 DDK 调用它，R56 上会从"成功"变成 `-ENOTTY`，这是**真实行为差异** |
| 命中 = 0 | ioctl 80 在 OEM 上**也不可达** → DDK 必然已容忍 `-ENOIOCTLCMD` → **U4-14 的 80 项风险基本消除** |
| `Invalid reserved field not 0` 命中 > 0 | 佐证 R49 内联 padding 校验（`STAGE4_REMAINING_AUDIT` §2 N-1）编进了设备构建 |

> 这是**本方案里性价比最高的一段**：一条 `strings | grep -c`，就能把 U4-14 最大的不确定性砍掉一半。

### H 段 · dmesg（U4-02 / U4-11 / U4-25b）

**采**：`mali|csf|gpu` 相关行（前 60）；`Loading Mali firmware`；`Version check failed`；`disagrees about version of symbol` 的**计数**；`firmware git_sha`。

**判读**：

| 观察 | 结论 |
| --- | --- |
| `disagrees about version of symbol` 计数 = 0 | 所有已装载模块的 CRC 一致 → **U4-25b 的补丁问题对本项目无影响**（`STAGE4_FINAL_REPORT` §4.5） |
| 计数 > 0 | 该内核打过 `bad_version → return 1` 补丁 → "装载成功"不能作 CRC 证据 |
| 有 `Loading Mali firmware 0x…` | 只给 `version_hash`（已知 `0x30a0000`），**不是 GLB 版本** |
| 有 `firmware git_sha: …` | 多一个可比对的固件构建锚点（与 `05/07` §4.3 的 `vb421b363…` 对照） |

> **不要**从 dmesg 里"没有 GLB 版本"推出"GLB 版本未知是因为采集不够"——源码里 kbase **根本不打印** `iface->version`（已核）。

### I 段 · debugfs 枚举（U4-02）

**采**：`/sys/kernel/debug/mali0` 的一级、二级条目名（**只列名，不自动读内容**，避免副作用）。

**判读**：R49 与 R56 的 kbase 都**没有**直接暴露 GLB 版本的 debugfs 节点（源码已核）。若枚举中出现 `fw_*` 版本类文件，再单独 `cat`。若 debugfs 未挂载 → U4-02 只能走 H 段或离线固件解析。

### J 段 · ELF 元数据（U4-17 / U4-23 / U4-22 辅证）

**采**：`vulkan.mali.so` / `libgpud.so` / `libgpud_sys.so` / `libged.so` 的 size、sha256、`DT_NEEDED`/`SONAME`、导出 FUNC 计数与样本、`vulkan.mali.so` 的 `vk_icd|api_version|e[0-9]` 字符串。

**判读**：

| 观察 | 结论 |
| --- | --- |
| `libgpud.so` 与 `libgpud_sys.so` 的导出 FUNC 符号集高度重合 | 同 API 的 vendor / system 两份拷贝 → U4-23 可闭合 |
| 两者差集很大 | 不同实现 → U4-23 需分别分析 |
| `vulkan.mali.so` 出现 `vk_icd` 类符号 | 佐证"薄壳 + 主体在 GLES 库"的判定 |
| 出现硬编码 `api_version` 常量 | 只能作线索；**确定值仍需反汇编** |

### K 段 · 属性面与后端（U4-06 / U4-20 / U4-21）

**采**：`getprop` 的图形相关子集；`/linkerconfig/ld.config.txt` 中的 egl/mali 行；`dumpsys SurfaceFlinger` 的后端线索（有界 20 行）；`/dev/mali0` 的权限；打开 `/dev/mali0` 的进程。

**判读**：

| 观察 | 结论 |
| --- | --- |
| `ld.config.txt` 含 `egl/mt6991` 的搜索路径 | U4-06 的"机制"部分闭合 |
| `dumpsys` 显示 `RenderEngine` 类型 | U4-20 闭合（GLES / SkiaGL / Vulkan） |
| 有非 SurfaceFlinger 进程持 `/dev/mali0` | U4-21 的"服务硬依赖"有直接证据 |

---

## 6. `strace` 的能力边界（**必读，防止误用**）

> 本节回应一个反复出现的误解：**"跑一次 `strace -e ioctl` 就能看出 padding 是不是 0"——这是错的。**

### 6.1 `strace` 能看到什么

对**未注册**的 ioctl，`strace` 打印的是**请求号的解码形式 + 参数指针**，例如：

```
ioctl(5, _IOC(_IOC_READ|_IOC_WRITE, 0x80, 0x3a, 0x70), 0x7ffd12345678) = 0
                                │          │     │
                                │          │     └── size = 0x70 = 112  ← 可读！
                                │          └── nr = 0x3a = 58
                                └── type = 0x80 = KBASE_IOCTL_TYPE
```

| 可获得 | 不可获得 |
| --- | --- |
| **调用了哪些 ioctl**（type / nr） | **缓冲区内容**（含 padding 字节） |
| **结构体大小**（`_IOC_SIZE` 字段）→ 可判定 CSG create 走的是 40 / 112 / 120 哪一支 | **字段值**（`buffer_size`、`size`、`flags` 等） |
| **调用次数与顺序** → 可推断"是否两次 GET_GPUPROPS（两步协商）" | 返回值之外的语义 |
| 返回码（`= 0` / `= -1 ENOTTY`） | — |

### 6.2 因此 `strace` 能解 / 不能解

| 项 | 能否由 `strace` 解 | 说明 |
| --- | --- | --- |
| U4-14（是否调用 8/12/32/35/55/80） | ✅ **能**（看 nr 是否出现） | 但"未出现"只代表**该次负载没走那条路径**，不代表永不调用 |
| U4-04c2（是否两步协商 props） | ⚠️ **弱证据**（看是否连续两次 GET_GPUPROPS） | 单次调用 ≠ 写死长度；需结合返回码 |
| CSG create 的 size 落点 | ✅ **能**（`_IOC_SIZE`） | 直接验证"R49 DDK 用 112 B" |
| **U4-04c1（padding 字节是否为 0）** | ❌ **不能** | `strace` 不解私有结构体，**看不到 16 字节里的第 13–15 字节** |
| 分配走 dma-heap 还是 ion（U4-07） | ✅ 能（`-e trace=openat` 看 `/dev/dma_heap/*` vs `/dev/ion`） | — |

### 6.3 如果想真的看到 padding 字节，只有三条路（**本轮都不做**）

| 路径 | 需要什么 | 风险 / 局限 |
| --- | --- | --- |
| **① 离线反汇编**（推荐） | 把 `libGLES_mali.so` 取到 PC 上做 REA | 53 MB 二进制，**不得入库**（`D-004`）；需用户自行在本地完成 |
| ② `LD_PRELOAD` 拦截 `ioctl` 的 shim | 需要一个 aarch64 编译环境 + 一个自己写的小 `.so` | **需要编译**（超出本任务授权）；且只影响被注入的那个进程；注入失败会让目标进程起不来 |
| ③ 内核侧加打印 | 改 kbase 源码 | **绝对禁止**（`D-002`/`D-003`） |

> **本方案的选择**：**不引入 strace，也不引入任何 preload**。理由是：①`strace` 解不了最关键的那一项；②preload 需要编译；③而"G 段一条 `strings | grep -c`"就能把 U4-14 最大的不确定性砍半 —— **性价比高得多**。
>
> 若用户后续希望做 strace，应作为**独立的一次任务**授权，并明确"只用于 ioctl 编号与 size，不用于 padding"。

---

## 7. 结果如何转成台账更新（本批跑完后的处理规则）

| 段 | 可能的产出 | 台账动作 |
| --- | --- | --- |
| B | `entry_end_offset` 有值 | U4-11 仍 **OPEN**（只补了一个字段）；若尾部出现形如 `v1.1.0` 的 GLB 串，则 **CLOSED** |
| C | 无 overlay | U4-27 **CLOSED**；若**有** overlay → 全仓 `[D·A]` 结论降级，需开新任务重估 |
| D | 有 build-id | U4-26 转 **PARTIAL**（设备侧已取，仍缺 CI 产物比对） |
| E | `Mali-G925-Immortalis 12 cores` | 写进 U4-12 的"辅证"栏；**不闭合**（固件仍缺） |
| F | 两份 dump | U4-24b **CLOSED 或推翻 `D-022`**，二选一，不许"大致一致" |
| G | `Internal fence wait` 计数 | 影响 U4-14 的 80 项定性与 `R-B3` 的措辞 |
| H | `disagrees` 计数 = 0 | U4-25b 记"对本项目无影响"（**不闭合**，因为它是条件性结论） |
| I | 有/无 `fw_*` 节点 | 影响 U4-02 的下一步方法选择 |
| J | 两组 dynsym | U4-23 **CLOSED** 或转 PARTIAL |
| K | ld.config / SF 后端 | U4-06 / U4-20 / U4-21 各自转 CLOSED 或 PARTIAL |

> **一条纪律**：任何一段的产出**不得跨段外推**。例如"`gpuinfo` 显示 12 核"**不能**推出"R56 固件也匹配 12 核"——那只证明**当前固件**驱动的是 12 核。

---

## 8. 安全声明

本次采集：

- **只读**：无 `mount -o remount`、无 `setprop`、无写 `/vendor` `/system` `/vendor_dlkm`；
- **不装卸模块**：无 `insmod`/`rmmod`/`modprobe`；
- **不替换**任何 `.so` / `.ko` / 固件；
- **不刷机、不重启、不做故障注入**；
- **不导出二进制**：不 `cp`/`tar`/`pull` 任何 `.so`/`.ko`/`.bin`；
- 唯一写入：`/sdcard/GPU_AUDIT_STAGE4/`（或回退 `/data/local/tmp/GPU_AUDIT_STAGE4/`）下的**文本文件**。

> 本方案**不要求现在就执行**。是否执行、何时执行，由用户决定。

---

## 9. 第一轮执行结果评估（2026-11-16 09:01 / 09:02）

> **结论先行**：脚本 v1.0 有**输出缺陷**，回传的数据只到"计数与路径"这一层，**字节级与行级内容全部缺失**。已修 v1.1，需重跑一次补齐。**这不是执行者的问题**，是脚本自身的单通道设计错误。

### 9.1 缺陷根因

`v1.0` 里 `say()` 会同时写终端与结果文件，但脚本有 **43 处**原始命令管道（`od` / `readelf` / `grep` / `dumpsys` / `find`）只写 stdout，**不进文件**。所以终端滚得很快、看起来"全采到了"，存下来的 `.txt` 却几乎只有标题。

| 类别 | v1.0 落盘 | 例 |
| --- | --- | --- |
| `say` 拼接行 | ✅ | `SIZE: 307200 bytes`、`COUNT: 1`、`VALUE: Mali-G925-...` |
| 原始命令输出 | ❌ | 固件前 24 字节、`entry_end_offset`、mount 行、dmesg 行、ELF 符号 |
| `__versions` 转储 | ✅ | 因为用了 `> 独立文件` 重定向 |

**v1.1 的修法**：主体整体放进 `main()` 子 shell，`main 2>&1 | tee -a "$MAIN"`，所有输出走同一条管道；无 `tee` 时用内置 `tee_a` 回退。已在本机验证 **文件内容与终端输出 `diff` 为 0 行**，并新增 `SELFCHECK: 数据行数` 便于自检（< 60 即说明多数命令没产出）。

### 9.2 第一轮确实拿到的（可用）

| 项 | 内容 | 对台账的作用 |
| --- | --- | --- |
| **E** | `Mali-G925-Immortalis 12 cores r0p1 0x0D080300`（两条路径一致） | **硬件 SKU 确认为 G925 MC12**；`0x0D080300` 的 product id 段对应 `tKRx` |
| **G** | `Internal fence wait` = **1**、`Internal fence timeouts` = **4**、`ged_mali_event_notify_fence_timeout_event` = **2** | **U4-14 的"可行性"子项闭合**：`CONFIG_MALI_MTK_FENCE_DEBUG` 在本机 OEM 构建里**是开的**，ioctl 80 在 OEM 栈上可达（此前只有 [E3] 推测） |
| **F** | kbase **513** 条、ged **241** 条 import 符号 + CRC32 | **U4-24b 的 CRC 一半闭合**；证据见 `05/evidence/stage4_round1_20261116/` |
| **H-4** | `disagrees about version of symbol` 计数 **0** | 运行态**没有**版本冲突记录，与"装载成功"自洽（仍不能反推 R56 兼容） |
| **H** | dmesg 共 103,115 / 103,905 行（两次运行） | 说明 dmesg 可读、未被 restrict |
| **C** | overlay 行 18、vendor 行 29；`/data/adb/ksu` 与 `/data/adb/modules` 存在 | 有 KSU 环境，但**是否覆盖 `/vendor` 仍需看具体 mount 行**——行本身没落盘 |
| **I** | `/sys/kernel/debug/mali0` 不存在 | debugfs 未挂载或路径不同；**U4-02/U4-15 的这条路走不通**，需换 `/proc/mali0` 或无则放弃 |
| **J** | `vulkan.mali.so` 133,416 B / `libgpud.so` 395,856 B / `libgpud_sys.so` 396,752 B / `libged.so` 101,944 B（SHA256 全取） | 四库实体与哈希确认；**DT_NEEDED 与符号集缺失** |
| **K-4** | **30 个**进程持有 `/dev/mali0`（含 `surfaceflinger`、`camerahalserver`、`com.miui.home` 等） | U4-21 从"是否有硬依赖"变成"依赖面很宽"，但**仍需 K-1/K-2/K-3 才能定性** |

### 9.3 第一轮缺失、必须重跑的（v1.1 已覆盖）

| 段 | 缺什么 | 影响的台账项 |
| --- | --- | --- |
| **B** | 固件前 24 字节、`byte[0x04]`、`u32[0x10] entry_end_offset`、尾部 32 字节 | **U4-11 / U4-13**（此前只有 header 0.3 的 8 字节，`entry_end_offset` 从未取到） |
| **D** | `/sys/kernel/notes` 的 build-id 字节、kbase `.note.gnu.build-id` | **U4-26** |
| **H-1/2/3/5** | 实际 dmesg 行（固件加载、GLB、git_sha） | **U4-02** |
| **J** | `DT_NEEDED` 列表、`GLOBAL DEFAULT` 符号集 | **U4-17 / U4-23** |
| **K-1/2/3** | 属性值、`ld.config.txt` 的 EGL 路径、SF 后端行 | **U4-06 / U4-20** |
| **C-1** | mount 具体行 | **U4-27** |

### 9.4 重跑方式

```sh
curl -fsSL https://raw.githubusercontent.com/JiangXue5/K80U_GPU_R56_AUDIT/main/05_userspace_firmware/tools/collect_stage4_remainder.sh -o /data/local/tmp/c.sh && sh /data/local/tmp/c.sh
```

跑完只回传**最新那一份** `stage4_remainder_*.txt`（新的会更大，因为这次带数据）。判断标准：文件末尾 `SELFCHECK: 数据行数` 应 **> 300**；若仍 < 60，说明脚本没更新成功。

---

## 10. 引用

| 引用 | 位置 |
| --- | --- |
| 脚本本体 | `05_userspace_firmware/tools/collect_stage4_remainder.sh` |
| 固件 header 字段定义 | `05_userspace_firmware/02_csf_firmware_abi.md` §2 |
| `gpuinfo` 输出格式 | `01_original_baseline/…/mali-r49p1/…/mali_kbase_core_linux.c:3652`（`DEVICE_ATTR_RO(gpuinfo)`）、`02_r56_source/…/mali_kbase_core_linux.c:2671` |
| `__versions` 语义 | `D-019`、`D-022`、`05/08` §3.6.5 |
| `disagrees about version of symbol` 判据 | `06/STAGE4_FINAL_REPORT.md` §4.5 |
| MTK 扩展串所在源码 | `01_original_baseline/…/mali_kbase_core_linux.c:1830-1880` |
| 已完成的五份采集 | `05/07` §1 |

*本文件与配套脚本不含任何写系统分区的操作；未编译、未刷机、未部署。*
