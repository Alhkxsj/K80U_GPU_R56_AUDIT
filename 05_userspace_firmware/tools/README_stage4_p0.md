# Stage 4 P0 补充采集 — 手机端执行说明

> 本文件配套 `collect_stage4_p0.sh`。目标：用**手机自身**采集两个 P0 缺口，不需要电脑、不需要 Termux、不需要 adb。
>
> **脚本只读**：不复制、不 pull、不改任何设备文件、不生成二进制副本。
>
> **当前状态（已更新）**：脚本已在 Linux 的 `dash` 与 `bash` 下通过语法检查，并对 0.3 / 0.4 / magic 不符 / 文件缺失四条分支做过伪造文件演练。
>
> **✅ 已在真机运行一次（2026-11-15 23:20，`25060RK16C` / Android 17 / `6.6.143-android15-8-gf9aa2fec23c3-4k`）**，输出 `stage4_p0_20261115_232021.txt`，结果：
>
> | 项 | 实测 | 判定 |
> | --- | --- | --- |
> | 固件前 8 字节 | `6e 3a f1 c3 03 00 00 00` | magic OK、**header 0.3** → U4-01 闭合 |
> | `UK version N.N` | `NOT_FOUND` | 该模式不存在（不等于"无 UK 版本"） |
> | DDK release | `r49p1-03bet0` ×3 | 与 kbase 同串 → 原厂配套 |
> | `Mali-*` | G71 / G725 / G77 / G720 / G31 | **受 `-m 5` 截断 + 模式不匹配 `Immortalis-*`，不能据此判断 G925 支持** |
> | Build ID | `NOT_FOUND`（设备端） | 离线 `readelf` 已取 `700e6d4112a6a8a5`，属工具差异 |
>
> 完整解码见 `../07_device_evidence.md` §4.5 / §5.4。**下文保留原始执行说明，供其它设备复现。**

---

## 1. 采什么

| 项 | 目标 | 读取量 | 判定依据 |
| --- | --- | --- | --- |
| **[U4-01]** | `/vendor/firmware/mali_csffw.bin` 前 8 字节 | **8 字节**（另可选读 offset 8–15 交叉校验） | 源码：`data[4]=minor`、`data[5]=major`；magic `0xC3F13A6E` → 小端 `6e 3a f1 c3` |
| **[U4-04]** | `/vendor/lib64/egl/mt6991/libGLES_mali.so` 版本串 | 仅 `grep -m` 前几条匹配 | 搜 `UK version x.y`、`r49p1-…`、`Mali-…`、Build ID（若有 `readelf`） |

**字段定义出处**（不是预期值，是代码）：

- `mali-r49p1/.../csf/mali_kbase_csf_firmware.c:107-109`、`:2770-2774`
- `mali_r56p0/.../csf/mali_kbase_csf_firmware.c:84-86`、`:2695-2699`
- 头部总长 `FIRMWARE_HEADER_LENGTH = 0x14`（20 字节），两版相同

---

## 2. 脚本在仓库里的路径

```
05_userspace_firmware/tools/collect_stage4_p0.sh
```

GitHub 直达（公开仓库）：

```
https://github.com/JiangXue5/K80U_GPU_R56_AUDIT/blob/main/05_userspace_firmware/tools/collect_stage4_p0.sh
```

---

## 3. 把脚本放到手机（三种方式，任选其一）

### 方式 A — 在 aShell You 里直接下载（推荐）

打开 aShell You，执行（先 `su`）：

```sh
su
cd /data/local/tmp
curl -fsSL -o c.sh https://raw.githubusercontent.com/JiangXue5/K80U_GPU_R56_AUDIT/main/05_userspace_firmware/tools/collect_stage4_p0.sh
```

若 `raw.githubusercontent.com` 连不上，换镜像：

```sh
curl -fsSL -o c.sh https://gh-proxy.com/https://raw.githubusercontent.com/JiangXue5/K80U_GPU_R56_AUDIT/main/05_userspace_firmware/tools/collect_stage4_p0.sh
```

若 `curl` 不存在，把上面的 `curl -fsSL -o c.sh` 换成 `wget -O c.sh`（URL 不变）。

下载后确认文件非空、行数合理：

```sh
wc -l c.sh      # 预期 280 行左右
head -3 c.sh    # 预期看到 #!/system/bin/sh
```

### 方式 B — 用浏览器「原始文件」另存

GitHub 页面点 **Raw** → 浏览器菜单「下载」→ 文件落到 `Download/` → 然后：

```sh
su
cp /sdcard/Download/collect_stage4_p0.sh /data/local/tmp/c.sh
```

> 注意：浏览器可能给文件加 `.txt` 后缀，`cp` 时按实际文件名改。

### 方式 C — 手动粘贴（前两种都失败时）

```sh
su
cat > /data/local/tmp/c.sh
```

然后把脚本全文粘贴进去，按 `Ctrl-D`（aShell You 的输入栏旁通常有 EOF/换行提交键）。**这种方式容易漏行，不推荐**。

---

## 4. 执行

一行版：

```sh
su -c 'sh /data/local/tmp/c.sh'
```

或分步：

```sh
su
sh /data/local/tmp/c.sh
```

**必须是 root。** 虽然 `/vendor/firmware/mali_csffw.bin` 通常是 `644 root:root`（`shell` 用户可读），但部分 HyperOS 版本对 `/vendor` 有额外 SELinux 限制；`su` 下最稳。

脚本不会等待任何输入，全程 5–20 秒（`libGLES_mali.so` 有 53 MB，`grep -m 3` 命中即停）。

---

## 5. 输出在哪

| 情况 | 路径 |
| --- | --- |
| 默认（root 可写） | `/data/local/tmp/gpu_audit_p0/stage4_p0_YYYYmmdd_HHMMSS.txt` |
| `/data/local/tmp` 不可写 | `/sdcard/Download/gpu_audit_p0/stage4_p0_*.txt` |
| 都不可写 | 只打到屏幕，末尾提示 `Not saved to a file` |

脚本结尾会打印 `Saved to: <路径>`。

取回文本（在 aShell You 里显示，然后长按复制）：

```sh
cat /data/local/tmp/gpu_audit_p0/stage4_p0_*.txt
```

---

## 6. 怎么把结果交回

**最省事**：把 `cat` 出来的全文粘贴给我（约 40–60 行）。

**最小集**：只贴这 6 行也够判读——

```
KERNEL:
SELINUX_CTX:
HEADER_HEX:
FIRMWARE_HEADER:
DDK_UK_VERSION:
DDK_RELEASE:
```

---

## 7. 结果怎么读（先自己看一眼，防止误读）

### U4-01

| `HEADER_HEX` | `FIRMWARE_HEADER` | 含义 |
| --- | --- | --- |
| `6e 3a f1 c3 03 00 …` | `0.3` | 与原厂 r49p1 一致 → `02` §3 的硬阻断从"推理"升为**实测** |
| `6e 3a f1 c3 04 00 …` | `0.4` | **推翻**首轮核心结论 → `02`/`06` 必须重写 |
| `6e 3a f1 c3 0x ..` 其它 | `0x..` | 两版都不是 → 需重新核对厂商定制 |
| 前 4 字节不是 `6e 3a f1 c3` | `UNRELIABLE` | 文件不是裸 CSF 固件（可能加密/打包），**不能**据此判版本 |
| 无输出 | `UNKNOWN` | 读失败，看 `REASON` |

### U4-04

| 输出 | 含义 |
| --- | --- |
| `UK version 1.30` | DDK 自称 1.30 → `03` §1.5 的"必然宣称 1.30"由 [E1] 推理变为实体证据 |
| `UK version 1.31+` | 需重算 `min()` 协商落点（结论方向不变，前提要改） |
| `NOT_FOUND` | **只是"本方法没搜到"**，**不等于** DDK 不兼容、也不等于没有版本信息（可能被压缩/加密/拆分） |

> 特别注意：`/sys/module/mali_kbase_mt6991_r49/version` 是**内核模块**版本，不是 DDK 版本；内核 UK ABI 1.30 **不等于** DDK 宣称 1.30。字符串命中**也不证明** DDK 运行时会走 1.30 分支。

---

## 8. 失败排查

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `FILE_NOT_READABLE` + `permission denied` | 非 root 或 SELinux 拦截 | 确认 `id -u` 为 0；再试 `su -c` |
| `READ_FAILED` / `no usable tool` | `od`/`xxd`/`hexdump` 全无 | 极少见；改用第 9 节兜底命令 |
| `STATUS: PARTIAL_READ` | 文件短于 6 字节 | 文件异常，需人工确认 |
| `Not saved to a file` | 两个目录都不可写 | 直接复制屏幕文本 |
| 输出的 `KERNEL_NOTE` 写着 third-party GKI | 正常 | 这是**环境标记**，说明本次是第三方内核下采集，不是原厂 boot |

---

## 9. 兜底：不落脚本，直接两条命令

如果脚本怎么都传不上去，这两条也能闭合（结果贴给我即可）：

```sh
su -c 'od -An -tx1 -N 8 /vendor/firmware/mali_csffw.bin'
su -c 'grep -a -o -m 3 -E "UK version [0-9]+\.[0-9]+" /vendor/lib64/egl/mt6991/libGLES_mali.so'
```

第二条若为空，再补一条：

```sh
su -c 'grep -a -o -m 3 -E "r[0-9]{2}p[0-9]-[0-9a-z]+" /vendor/lib64/egl/mt6991/libGLES_mali.so'
```

---

## 10. 脚本明确不做的事

- 不 `pull`、不 `cp`、不 `tar` 任何 `.so` / `.bin` / `.ko`
- 不修改、不挂载、不 remount 任何分区
- 不读 `dmesg`（需额外权限且输出量大）
- 不做 `strace`（不属于本轮范围）
- 不判断"兼容/不兼容"——只报观测值

---

## 11. 采完之后（**已执行完毕**）

**实际执行结果**：命中"`03` → 0.3"分支。Agent 据此完成了：

1. ✅ 更新 `02_csf_firmware_abi.md` §3.0 / §3.0.5（U4-01 实测判据）；
2. ✅ 更新 `03_gles_egl_abi.md` §1.5（U4-04 的实体证据）；
3. ✅ 更新 `06_abi_compatibility_matrix.md` §7（闭合状态与计数：27/4/3/4 → 27/5/3/3）；
4. ✅ 同步 `docs/PROJECT_STATE.md`、`docs/DECISION_LOG.md`（D-016 / D-017）与 `MANIFEST.md`（v1.4）；
5. ✅ 未触发"`0.4` → 结论反转"分支，故 `02`/`06` 核心结论保持。

> **历史留痕**：本文件在脚本就绪时曾声明"在输出回传之前，U4-01 / U4-04 一律保持 UNKNOWN"。该约束已随回传解除。
>
> **仍然适用的禁止表述**：
> - 不得由 `version_hash = 0x030A0000` 推出 "GLB 3.10.0"（格式无关，见 `02` §3.0.5）；
> - 不得写"DDK 实测宣称 UK 1.30"（库内无该字面量，1.30 由 release 映射）。
