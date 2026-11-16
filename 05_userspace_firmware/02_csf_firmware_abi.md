# 02 — CSF 固件 ABI 分析

> **本文件回答**：原厂 CSF 固件能否直接用于 R56p0？
>
> **答案**：**不能。在固件加载的第一个检查点就被拒绝**，且不存在兼容分支。
>
> 证据等级：**[D·A]** 厂商分区静态实测 · **[E1]** 源码直接证据（两版加载器逐行对照） · **[E2]** 交叉推导 · **[U]** UNKNOWN
>
> **✅ 2026-11-15 23:20 实测确认（本文件最终状态）**：P0 补采（`stage4_p0_20261115_232021.txt`）已读到固件前 8 字节 —— **`6e 3a f1 c3 03 00 00 00`**，magic 校验通过，`offset 4 = 0x03`、`offset 5 = 0x00`。**header = 0.3，[D·A] 厂商分区静态实测**，U4-01 闭合。本文 §3 的阻断判定由"推理成立"升级为"实测成立"，详见 §3.0.5。
>
> **⚠️ 留痕（不得删除）**：首轮曾把"0.3"当**结论**写（**证据越级**，无字节支撑）；第二轮撤为"UNKNOWN + E2 推理"；本轮才由读数闭合。这条三段式迁移是本文最重要的一条记录（§9 文末）。

---

## 0. 结论先行

| 层次 | 检查项 | 两版源码要求 | 判定 |
| --- | --- | --- | --- |
| **容器层** | 固件文件名 | 都是 `mali_csffw.bin` | 相同 **[E1]** |
| **容器层** | 文件 magic | 同一常量 `0xC3F13A6E` | 相同 **[E1]** |
| **容器层** | **源码要求 header minor** | **r49p1 = 3；r56p0 = 4，严格 `!=`** | **硬阻断（条件成立时）[E1]** |
| **容器层** | **原厂固件实际 header minor** | — | **`0x03` → 0.3 [D·A]**（`od -An -tx1 -N 8`，见 §3.0.5） |
| **容器层** | header 长度 / 字段偏移 | 0x14，逐字节相同 | 相同 **[E1]** |
| **容器层** | 文件大小 | 真机 307,200 B（300 KiB 整） | **与版本无关**，见 §3.0.3 **[D]** |
| **编码层** | entry type/size 位域 | `type=h&0xFF`、`size=(h>>8)&0xFF` | 相同 **[E1]** |
| **编码层** | entry 类型集合 | r56p0 多 `PAGE_FAULT_CNT`（可选） | 向后兼容 **[E1]** |
| **协议层** | GLB 全局接口字段 | 97 个共有字段偏移**全部相同** | 相同 **[E1]** |
| **协议层** | 接口版本门槛 | 都要求 ≥ 1.0.0 / ≥ 1.1.0 | 相同 **[E1]** |
| **协议层** | 新增字段处置 | 有 `iface->version >= (1,1,0)` 守卫，旧固件置 0 | 正确降级 **[E1]** |

> 阻断逻辑本身是确定的：**固件 offset 4 的值 = 3 ≠ 4**，r56p0 在第一个检查点拒绝，无分支、无 fallback。**该值现已由读数确认（[D·A]），不再是推理。**
>
> 因此本文件的最终判定是：**组合 B（R56p0 Kbase + 原厂固件）被实测否决**——不是"极可能不可用"，而是"读到的字节与 r56p0 期望值不同"。`02` §3.0.5 给出原始 16 字节与字段解码。

---

## 1. 固件加载完整流程（两版逐行对照）

### 1.1 调用链

```
kbase_platform_device_probe()
└─ kbase_device_init()
   └─ kbase_csf_early_init()                     device/backend/mali_kbase_device_csf.c:188
      └─ kbase_csf_firmware_early_init()         csf/mali_kbase_csf_firmware.c:2537 (r56p0) / :25xx (r49p1)
         └─ kbase_csf_firmware_load_file()       csf/mali_kbase_csf_firmware.c:2660 (r56p0)
            ├─ [1] 确定 fw_name
            ├─ [2] request_firmware()
            ├─ [3] vmalloc + memcpy（保留副本）
            ├─ [4] size >= 0x14 ？
            ├─ [5] magic ？
            ├─ [6] header version ？   ← 失败点
            ├─ [7] entry_end_offset 边界
            └─ [8] 逐 entry 解析（while 循环）
```

### 1.2 关键代码（r56p0，`csf/mali_kbase_csf_firmware.c`）

```c
:2660  if (request_firmware(&firmware, fw_name, kbdev->dev) != 0) {
:2661      dev_err(kbdev->dev, "Failed to load firmware image '%s'\n", fw_name);
:2662      ret = -ENOENT;
       } else { ... vmalloc + memcpy ... release_firmware(firmware); }

:2683  if (mcu_fw->size < FIRMWARE_HEADER_LENGTH) {           /* 0x14 */
:2684      dev_err(kbdev->dev, "Firmware too small\n");  return -EINVAL;

:2689  if (memcmp(mcu_fw->data, &magic, sizeof(magic)) != 0) {
:2690      dev_err(kbdev->dev, "Incorrect firmware magic\n");  return -EINVAL;

:2694  version_minor = mcu_fw->data[4];
:2695  version_major = mcu_fw->data[5];
```

### 1.3 两版代码一致性

`diff` 结果：**从 `request_firmware` 到 entry 循环，两版逐字相同**（仅行号不同）。

| 行为 | r49p1 | r56p0 |
| --- | --- | --- |
| `request_firmware` 调用 | `:2735` | `:2660` |
| size 检查 | `:2759` | `:2683` |
| magic 检查 | `:2765` | `:2689` |
| header version 检查 | `:2773-2774` | `:2698-2699` |
| `entry_end_offset` 读取 | `data[0x10]` | `data[0x10]` |
| entry 循环起点 | `FIRMWARE_HEADER_LENGTH`(0x14) | 同 |

> **这意味着：加载器的"读取逻辑"没有演进，唯一变化的是它期望的版本号常量。**

---

## 2. 固件头结构（从解析代码反推的字段偏移）

从两版完全相同的解析代码反推——**这是"内核怎么读"，不是"固件里写了什么"**：

| 偏移 | 长度 | 字段 | 读取代码 |
| ---: | ---: | --- | --- |
| 0x00 | 4 | `magic` | `memcmp(mcu_fw->data, &magic, 4)` |
| 0x04 | 1 | `version_minor` | `mcu_fw->data[4]` |
| 0x05 | 1 | `version_major` | `mcu_fw->data[5]` |
| 0x06 | 2 | *（未读取，推测保留）* | — |
| 0x08 | 4 | `version_hash` | `memcpy(&version_hash, &data[8], 4)` |
| 0x0C | 4 | *（未读取）* | — |
| 0x10 | 4 | `entry_end_offset` | `memcpy(&entry_end_offset, &data[0x10], 4)` |
| 0x14 | — | entry 区起点 | `entry_offset = FIRMWARE_HEADER_LENGTH` |

**固件头总长 `FIRMWARE_HEADER_LENGTH = 0x14 = 20 字节`**，两版相同。

---

## 3. 🔴 阻断点：header 版本严格相等

### 3.0 三层证据：源码要求 / 启动一致性 / 字节实测

首轮把三者混为一谈；第二轮拆开但 L3 仍缺；**第三轮 L3 已补齐**。现状如下：

| 层 | 命题 | 状态 | 支撑 |
| --- | --- | --- | --- |
| **L1 源码要求** | r49p1 要求 `(major, minor) == (0, 3)`；r56p0 要求 `(0, 4)`；校验用 `!=`，无 fallback | **确定 [E1]** | §3.1–§3.2 常量与代码 |
| **L2 启动一致性** | 设备当前加载的 `/vendor/firmware/mali_csffw.bin`，其 offset 4 必然等于 `3` | **已被 L3 取代**（原为 [E2] 推理） | §3.0.1（保留，作为方法学示例） |
| **L3 字节实测** | offset 4 = `0x03`、offset 5 = `0x00` | **✅ 已实测 [D·A]** | `od -An -tx1 -N 8`，见 §3.0.5 |

> **三层的关系**：L2 是"在没有读数时，能推到的最强程度"；L3 一次读数便把 L2 的结论升格为事实。**L2 保留在文中的价值只有一个**——它示范了"八环推理仍不能替代一次 `od`"，这是本项目证据纪律的原始案例。日后遇到"推理极强所以不必实测"的诱惑，回看这一节。

> **为什么 L2 不能说成 L3**：L2 的前提是"设备当前 GPU 工作正常"。这条前提本身是 [D]（`/dev/mali0` 存在、`init.svc.vendor.gpu=running`、HWC/gralloc 服务在跑），但它推出的是**"加载成功的固件必然满足 0.3"**，不是**"我读到了 0x03"**。二者在逻辑上等价于同一结论，在证据法上不等价——一旦 L2 的某个前提失真（例如存在我们未看到的固件覆盖路径），L3 会立刻暴露问题，而 L2 不会。

#### 3.0.1 L2 的完整推理链（**已归档**：L3 已证实其结论，本节仅作方法学示例）

```
① kbase 版本 = r49p1-03bet0，UK 1.30            [D] /sys/module/.../version
② r49p1 源码要求 header (0,3)，用 != 强校验       [E1] §3.1
③ 加载器无 fallback、无白名单、无版本放宽分支     [E1] §3.2
④ /vendor/firmware/ 下只有唯一 mali_csffw.bin    [D] 07 §4.1
⑤ /vendor/firmware_mnt、/vendor/etc/firmware 不存在[D]
⑥ DT /soc/mali@48000000 无 firmware-name 属性     [D] 07 §7.4
⑦ 因此 request_firmware("mali_csffw.bin") 只能取到④那个文件
⑧ 设备 GPU 子系统正在工作                        [D] /dev/mali0 (10:282)、服务在跑
──────────────────────────────────────────────
∴ ④ 的 offset 4 == 3（否则 ②③ 会让 probe 失败，与 ⑧ 矛盾）
```

每一环都有独立出处；**唯一未被直接观测的环节是"⑧ 是否由这个固件驱动"**——若存在我们未发现的第二份固件（例如 vendor_boot 内的 ramdisk 副本、或 `fw_name=` 模块参数覆盖），链条会断。TASK 03 已确认 DT 无覆盖，但 **insmod 参数未采集**（`/vendor_dlkm` 的 `modules.load` 内容未读）。

> 这就是 L2 停在 [E2] 的真正原因：不是"不够像"，而是**有一个未采集的旁路**（模块参数）无法排除。
>
> **事后记**：L3 读数证明该旁路确实没有改变结论（读到的就是那一份文件的 `0x03`）。但这恰好说明 [E2] 的定性是对的——推理链条再完整，也不能因为"结果碰巧正确"而提前宣布闭合。若当时按 L2 写"实测确认"，本篇就会在第二轮的更正里变成反例。

#### 3.0.2 L3 为什么三份采集覆盖不到

| 采集项 | 内容 | 为何取不到 header |
| --- | --- | --- |
| `file_metadata` | `ls -l` + `sha256sum` | 只有大小与摘要，**无字节** |
| `elf_analysis` §3 | `strings mali_csffw.bin \| grep …` | `version_minor` 是 offset 4 的单字节 `0x03`/`0x04`，**非可打印字符**，`strings` 永不输出 |
| `inventory` | 路径枚举 | 更不涉及内容 |

> 结论：**不是采集做得不够细，而是工具选型在原理上不可能覆盖二进制头字段**。要闭合必须换工具（`od`/`hexdump`），见 §3.0.4。

#### 3.0.3 为什么"307,200 B"不能反推版本

- 300 KiB 是**整 KiB 对齐**的容器大小；
- 加载器只解析到 `entry_end_offset`（offset 0x10），**尾部填充不参与任何校验**；
- 因此大小既不含版本信息，也不随 0.3→0.4 的 entry 增删而线性变化（对齐会吸收差异）。

> 任何"大小 → 版本"的推断都是无效的。首轮未犯此错，此处补记以防后续误用。

#### 3.0.4 闭合方式（**已执行**，2026-11-15 23:20）

原计划命令（`adb shell` 版）：

```bash
adb shell "od -An -tx1 -N 8 /vendor/firmware/mali_csffw.bin"
```

**实际执行方式**：本机无电脑，改用手机端 aShell You 直接运行 `05_userspace_firmware/tools/collect_stage4_p0.sh`（POSIX sh、只读、不 pull）。核心读数逻辑等价于上面的 `od`。

原定四分支与**实际命中**：

| 实际输出 | 判定 | 后续动作 | 状态 |
| --- | --- | --- | --- |
| `6e 3a f1 c3 **03** 00 …` | 0.3 → L2 升级为 [D·A] | 本文 §3 判定改为"实测确认"，`06` 组合 B 否决维持 | **✅ 命中本条** |
| `6e 3a f1 c3 **04** 00 …` | 0.4 → 首轮核心结论被推翻 | 重写本文 §3、`06` §1–§2 | 未触发 |
| magic 不符 / 读失败 | 采集或路径异常 | 回到 §3.0.1 复查 ④⑤⑥ | 未触发（magic OK） |
| 文件缺失 | 该方法未命中 | 仅记"未拿到"，不得反推 | 未触发 |

#### 3.0.5 实测记录（原始字节，[D·A]）

**采集文件**：`stage4_p0_20261115_232021.txt`（设备本地 `/data/local/tmp/gpu_audit_p0/` 生成，纯文本回传；**未上传任何二进制**）

| 项 | 值 |
| --- | --- |
| 采集时间 | 2026-11-15 23:20:21 CST |
| 设备 | `25060RK16C` / `dali`，Android 17 (SDK 37) |
| 运行内核 | `6.6.143-android15-8-gf9aa2fec23c3-4k`（第三方 GKI，`u:r:ksu:s0`，UID 0） |
| 工具可用性 | `od` **YES** · `xxd` YES · `strings` YES · `readelf` YES · `hexdump` **NO** |
| 路径 / 大小 / 权限 | `/vendor/firmware/mali_csffw.bin` · 307,200 B · `644 root:root` |
| **前 16 字节** | **`6e 3a f1 c3 03 00 00 00 00 00 0a 03 00 00 00 00`** |
| magic 校验 | **OK**（`6e 3a f1 c3` = `0xC3F13A6E` 小端） |

**逐字段解码**（字段定义见 §2，来自两版逐字相同的解析代码 [E1]）：

| 偏移 | 字节 | 字段 | 值 | 判定 |
| ---: | --- | --- | --- | --- |
| 0x00–0x03 | `6e 3a f1 c3` | `magic` | `0xC3F13A6E` | ✅ 与 `FIRMWARE_MAGIC` 一致 |
| **0x04** | **`03`** | **`version_minor`** | **3** | ✅ 等于 r49p1 要求；**≠ r56p0 要求的 4** |
| **0x05** | **`00`** | **`version_major`** | **0** | ✅ 两版都要求 0 |
| 0x06–0x07 | `00 00` | *（源码未读取，保留）* | — | 不参与校验 |
| 0x08–0x0B | `00 00 0a 03` | `version_hash` | `0x030A0000` | 仅用于打印 / ktrace，见下方纪律 |
| 0x0C–0x0F | `00 00 00 00` | *（源码未读取）* | — | — |
| 0x10–0x13 | **`e8 03 00 00`** | **`entry_end_offset`** | **1000**（`0x3E8`） | ✅ `1000 ≤ 307 200` → **截断检查必过**（2026-11-16 补采） |

**2026-11-16 补采：`entry_end_offset` 与首个 entry**（`stage4_remainder_20261116_131307.txt` §B-1）

前 24 字节完整读出：

```
6e 3a f1 c3 03 00 00 00 00 00 0a 03 00 00 00 00
e8 03 00 00 00 20 00 00
```

- `0x10` = `e8 03 00 00` → **`entry_end_offset = 1000`**。源码 `:2787` 的截断检查是 `if (entry_end_offset > mcu_fw->size)`，而文件 307 200 字节 → **必然通过**（[E1]+[D·A]）。
- `0x14` = `00 20 00 00` → 首个 entry 的 `header = 0x00002000`。按 `entry_type = header & 0xFF`、`entry_size = (header >> 8) & 0xFF`（`:177-180`）拆解：**type = 0（`INTERFACE`）、size = 32 字节**。`load_firmware_entry` 的三项校验（4 字节对齐、`size ≥ 4`、`size ≥ 0x14+4`）全部通过。
- 尾部 32 字节全 `00`；尾部 4 KiB 可打印串 **0 条** → 固件尾部**不携带版本信息**。

> 一个随机损坏的 header 几乎不可能同时给出「type=0 + size=32」且三项长度校验全过，所以这是一条**强自洽证据**：entry 表在 `0x14` 处正常起步。
> 完整解析见 [`evidence/stage4_round2_20261116/firmware_header.md`](evidence/stage4_round2_20261116/firmware_header.md)。

**结论（三条，逐条给等级）**：

1. **原厂固件 header = `(major 0, minor 3)` = `0.3`** —— **[D·A]**，厂商分区静态文件实测。
2. **r56p0 加载器必拒**：`version_minor(3) != FIRMWARE_HEADER_VERSION_MINOR(4)` → `dev_err("Firmware header version 0.3 not understood")` → `-EINVAL` → `goto err_out`。校验逻辑 **[E1]** + 实际值 **[D·A]**，**组合 B 由此从"推理否决"变为"实测否决"**。
3. **r49p1 加载器必过**：`(0,3) == (0,3)`，与设备当前 kbase（`r49p1-03bet0`）自洽。这解释了"设备 GPU 正常工作"这一现象——不是运气，是配套。

> **⚠️ 一条必须写下来的防误用纪律：`version_hash` 不是 GLB 接口版本。**
>
> `0x030A0000` 若按 `GLB_VERSION` 寄存器编码（`major<<24 | minor<<16 | patch`，`mali_kbase_csf_registers.h:310/317/324`）解码，恰好得到 **3.10.0**。**但这只是数值外观的巧合，源码没有建立任何关联**：
>
> - `version_hash` 的唯一用途是 `dev_notice("Loading Mali firmware 0x%x", version_hash)`（r56p0 `:2708` / r49p1 `:2783`）与 ktrace `CSF_FIRMWARE_BOOT` 的拼接值 `(hash<<32)|(major<<8)|minor`（`:2815`）；
> - 它**不参与任何校验**，也**不来自 GLB 共享内存**；
> - 真正决定 GLB 语义的是运行时从共享内存读出的 `iface->version`，与这个 header 字段无关。
>
> 因此 **U4-11（原厂固件 GLB 尾部实际版本号）不因本次采集而闭合**。任何"由 0x030A0000 推出 GLB 3.10.0"的写法都属于把无关格式当同一格式，与首轮"把 E2 当实测"是同一类错误。
>
> （另注：`%x` 无零填充，dmesg 里会显示为 `0x30a0000`，不是 `0x030a0000`。）

### 3.1 常量差异

| 常量 | r49p1（`:108-109`） | r56p0（`:85-86`） |
| --- | --- | --- |
| `FIRMWARE_HEADER_VERSION_MAJOR` | `0ul` | `0ul` |
| `FIRMWARE_HEADER_VERSION_MINOR` | **`3ul`** | **`4ul`** |
| `FIRMWARE_HEADER_LENGTH` | `0x14ul` | `0x14ul` |

### 3.2 检查方式

```c
/* r56p0 :2698-2703，r49p1 :2773-2778 —— 两版逐字相同 */
if (version_major != FIRMWARE_HEADER_VERSION_MAJOR ||
    version_minor != FIRMWARE_HEADER_VERSION_MINOR) {
    dev_err(kbdev->dev, "Firmware header version %d.%d not understood\n",
            version_major, version_minor);
    ret = -EINVAL;
    goto err_out;
}
```

**判定依据**：

1. 使用 `!=` 而非 `>=` / `>` —— **不接受任何非精确匹配**
2. 无 `#ifdef`、无白名单、无 fallback 分支
3. `goto err_out` 直接销毁已分配资源并返回 `-EINVAL`

### 3.3 后果推演

**前提已实测**（原厂固件 header = `0.3` [D·A]，r56p0 期望 `0.4` [E1]）：

```
version_major(0) != 0  → false
version_minor(3) != 4  → true
→ ret = -EINVAL, goto err_out
```

内核日志将出现（**推演，未实测**）：

```
mali_kbase ...: Firmware header version 0.3 not understood
mali_kbase ...: Failed to load firmware image 'mali_csffw.bin'
```

> **措辞纪律（三段式留痕）**：
> 首轮 → 写成"内核日志必然出现 `0.3`"（把条件结论写成事实，**错误**）；
> 第二轮 → 改为"若 L2 成立则必然发生"的条件句（**正确但未实测**）；
> 第三轮（本轮）→ 前提已由 `0x03` 读数坐实，**条件句已具备转为事实句的资格**。
>
> 但日志文本本身仍是**推演**：本轮采集只读固件字节，**没有采集 dmesg**。因此准确表述是"按代码路径必然打印该行，且该行内容现已与实测字节一致"，而不是"我看到了这行日志"。U4-10（失败后的系统表现）同样保持 UNKNOWN。

### 3.4 关键判断：是否"格式不兼容"

**不是。** 格式层完全兼容（见 §4）。差异只在版本号常量。这在工程上意味着：

> 0.3 → 0.4 的升级是**语义升级**（新增 entry 类型），但 Arm 选择了"版本号严格匹配 + optional entry 机制"的组合：
> - **新固件 → 旧内核**：靠 optional bit 前向兼容（未知类型跳过）
> - **旧固件 → 新内核**：**不兼容，直接拒绝**

这是一种"只向前不向后"的策略。它保证了新内核不会误解读旧固件的语义，代价是新旧固件不能混搭。

---

## 4. entry 编解码（格式层）

### 4.1 位域定义（两版逐字相同）

```c
/* r49p1 :173-187 / r56p0 :122-136 */
static unsigned int entry_type(u32 header)   { return header & 0xFF; }
static unsigned int entry_size(u32 header)   { return (header >> 8) & 0xFF; }
static bool         entry_update(u32 header) { return (header >> 30) & 0x1; }
static bool         entry_optional(u32 hdr)  { return (header >> 31) & 0x1; }
```

| 位 | 宽度 | 含义 |
| --- | ---: | --- |
| `[7:0]` | 8 | entry 类型 |
| `[15:8]` | 8 | entry 大小（**以 4 字节为单位？否——是字节数**，且须 4 字节对齐） |
| `[29:16]` | 14 | 保留 |
| `[30]` | 1 | `updatable`（配合 `FIRMWARE_CONFIG_UPDATE`） |
| `[31]` | 1 | `optional`（未知类型可跳过） |

### 4.2 entry 类型集合对比

| 类型 | r49p1 | r56p0 | 说明 |
| --- | :---: | :---: | --- |
| `INTERFACE` | ✔ | ✔ | 共享接口内存布局 |
| `CONFIGURATION` | ✔ | ✔ | 配置项 |
| `TRACE_BUFFER` | ✔ | ✔ | trace buffer |
| `TIMELINE_METADATA` | ✔ | ✔ | 时间线元数据 |
| `BUILD_INFO_METADATA` | ✔ | ✔ | 构建信息 |
| `CORE_DUMP` | ✔ | ✔ | core dump 区 |
| `FUNC_CALL_LIST` | ✔ | ✔ | 函数调用列表 |
| **`PAGE_FAULT_CNT`** | ✘ | **✔** | **r56p0 新增** |

> 这就是 0.3 → 0.4 的**唯一实质变化**：新增页错误计数器 entry（配合 `init_page_fault_cnt_firmware_memory()`）。

### 4.3 未知类型处置（前向兼容机制）

```c
/* r56p0 :2745-2750 */
default:
    if (!optional) {
        dev_err(kbdev->dev, "Unsupported non-optional entry type %u in firmware\n", type);
        return -EINVAL;
    }
```

**这是关键的前向兼容设计**：新固件里旧内核不认识的 entry，只要标 `optional`(bit31) 就会被跳过。

**但方向反了**：旧固件（0.3）里**没有**新类型，不会触发 default；真正的阻断在更早的版本号检查。

### 4.4 `PAGE_FAULT_CNT` 是否必需

```c
/* r56p0 :171-175 */
static void init_page_fault_cnt_firmware_memory(struct kbase_device *kbdev)
{
    if (!kbdev->csf.page_fault_cnt_ptr_address)
        return;                    /* ← 优雅返回，非错误 */
```

**不是必需项**。缺失时功能降级（无页错误计数），不影响加载。

> 推论（**E2**）：如果绕过版本号检查，0.3 固件在格式上**能被 r56p0 解析**，只是失去页错误计数。但绕过版本号需要修改固件字节，属于任务书禁止行为，且无法保证 GLB 协议语义正确。

---

## 5. 固件接口版本（GLB）

### 5.1 版本编码

```c
/* 两版函数体相同，仅行号不同：r49p1 firmware.h:900 / r56p0 firmware.h:829 */
static inline u32 kbase_csf_interface_version(u32 major, u32 minor, u32 patch)
{
    return ((major << GLB_VERSION_MAJOR_SHIFT) |
            (minor << GLB_VERSION_MINOR_SHIFT) |
            (patch << GLB_VERSION_PATCH_SHIFT));
}
```

版本号**不从文件读**，而是**运行时从固件写入的 GLB 寄存器/共享内存读取**：

```c
/* r56p0 :1389-1393 */
iface->version = get_firmware_version(kbdev);
if (!iface->version) {
    dev_err(kbdev->dev, "Version check failed. Firmware may have failed to boot.");
    return -EINVAL;
}
```

### 5.2 门槛对比（全部调用点）

| 文件:行 | r49p1 | 文件:行 | r56p0 |
| --- | --- | --- | --- |
| `csf/mali_kbase_csf.c:627` | `< (1,1,0)` 拒绝 | `csf/mali_kbase_csf.c:657` | `< (1,1,0)` 拒绝 |
| `csf/mali_kbase_csf_firmware.c:1346` | `>= (1,1,0)` 取 instr_features | `:1419` | `>= (1,1,0)` 取 instr_features |
| `csf/mali_kbase_csf_firmware_no_mali.c:234` | `>= (1,1,0)` | `:214` | `>= (1,1,0)` |
| `csf/mali_kbase_csf_scheduler.c:1869` | `< (1,1,0)` 拒绝 | `:1794` | `< (1,1,0)` 拒绝 |
| `csf/mali_kbase_csf_scheduler.c:2818` | `>= (1,0,0)` | `:2860` | `>= (1,0,0)` |
| — | — | **`:1424`** | **`>= (1,1,0)` 取 prfcnt_features（新增）** |

**结论**：接口版本门槛**完全没有提高**。r56p0 只多了一处对 `prfcnt_features` 的守卫读取。

### 5.3 新增字段的降级处置（正确做法）

```c
/* r56p0 :1424-1427 */
if (iface->version >= kbase_csf_interface_version(1, 1, 0))
    iface->prfcnt_features = shared_info[GLB_PRFCNT_FEATURES / 4];
else
    iface->prfcnt_features = 0;          /* 旧固件：置 0，不误读 */
```

对比 r49p1 同位置（`instr_features`）使用了完全相同的模式：

```c
/* r49p1 :1346-1349 */
if (iface->version >= kbase_csf_interface_version(1, 1, 0))
    iface->instr_features = shared_info[GLB_INSTR_FEATURES / 4];
else
    iface->instr_features = 0;
```

> **这是本次审计中看到的、最规范的向后兼容写法**：新增字段一律带版本守卫 + 置零降级，绝不误读旧固件的未定义区域。

---

## 6. GLB 全局接口字段对比

### 6.1 总体

| 项 | r49p1 | r56p0 |
| --- | ---: | ---: |
| GLB_* 宏总数 | 104 | 110 |
| 共有 | 97 | 97 |
| **共有字段偏移不同** | **0** | **0** |

**97 个共有字段，偏移全部相同**——全局接口布局高度稳定。

### 6.2 仅 r49p1 有（7 项）

| 名称 | 值 | 性质 |
| --- | --- | --- |
| `GLB_PRFCNT_STATUS` | `0x0014` | 旧字段；两版**均无 .c 消费者**（死定义） |
| `GLB_REQ_INACTIVE_COMPUTE_SHIFT` | 20 | JM 时代的 INACTIVE 位定义 |
| `GLB_REQ_INACTIVE_FRAGMENT_SHIFT` | 21 | 同上 |
| `GLB_REQ_INACTIVE_TILER_SHIFT` | 22 | 同上 |
| `GLB_ACK_IRQ_MASK_INACTIVE_{COMPUTE,FRAGMENT,TILER}_SHIFT` | 20/21/22 | 同上 |

### 6.3 仅 r56p0 有（13 项）

| 名称 | 值 | 性质 |
| --- | --- | --- |
| `GLB_REQ_STATE_{ACTIVE,HALT,SLEEP,SUSPEND}` | 0/1/2/3 | **枚举值**，非偏移（状态机可读性提升） |
| `GLB_ACK_STATE_{ACTIVE,HALT,SLEEP,SUSPEND}` | 0/1/2/3 | 同上 |
| `GLB_FATAL_INFO_LO` | `0x0020` | 新增：致命错误信息 |
| `GLB_FATAL_INFO_HI` | `0x0024` | 新增 |
| `GLB_PRFCNT_FEATURES` | `0x0020` | 新增（与 FATAL_INFO_LO **同址**） |
| `GLB_PRFCNT_NEURAL_EN` | `0x0060` | 新增：神经加速计数使能 |
| `GLB_REQ_NX_PWR_MODE_ENABLE_SHIFT` | 17 | 新增：NX 电源模式位 |

> **注意 `0x0020` 的一址两用**：`GLB_FATAL_INFO_LO` 与 `GLB_PRFCNT_FEATURES` 都指向 `0x0020`。这不是冲突，而是**同一字的不同解释**（错误上下文中是 fatal info，性能计数上下文中是 features）。这种复用是该接口的既有风格。

---

## 7. 失败路径与系统行为

### 7.1 内核态传导

```
固件版本检查失败 (-EINVAL)
└─ kbase_csf_firmware_load_file() 返回 -EINVAL
   └─ kbase_csf_firmware_early_init() 返回 err      :2537
      └─ kbase_csf_early_init() 返回 err            device/backend/mali_kbase_device_csf.c:188-190
         └─ kbase_device_init() 失败
            └─ kbase_platform_device_probe() 返回 err
               → 设备不注册 → /dev/mali0 不存在
```

代码依据：

```c
/* mali_kbase_device_csf.c:186-192 */
static int kbase_csf_early_init(struct kbase_device *kbdev)
{
    int err = kbase_csf_firmware_early_init(kbdev);
    if (err)
        return err;
    ...
}
```

### 7.2 用户态可见表现（**E2 推导，需实机确认**）

| 层次 | 预期现象 |
| --- | --- |
| 内核日志 | `Firmware header version 0.3 not understood` + probe 失败（**条件式，非实测**） |
| 设备节点 | `/dev/mali0` **不存在** |
| EGL 初始化 | `eglGetDisplay`/`eglInitialize` 失败（无设备可开） |
| SurfaceFlinger | 无 GPU 后端 → 回退软件渲染（SwiftShader）或启动失败 |
| 系统表现 | 动画卡顿、部分应用黑屏或崩溃 |

> 这段是**推导**，不是实测。具体表现取决于 Android 图形栈的降级策略，列入 U4-10。

### 7.3 是否有恢复路径

**没有运行时恢复**。固件版本检查发生在 probe 早期，失败即终止设备注册。唯一"恢复"是换回匹配的固件或内核。

---

## 8. 结论

| 问题 | 答案 | 依据等级 |
| --- | --- | --- |
| 两版源码要求的 header 版本？ | r49p1 = `0.3`；r56p0 = `0.4` | **[E1]** |
| **原厂固件实际 header 版本？** | **`0.3`**（`offset 4 = 0x03`、`offset 5 = 0x00`） | **[D·A]** 实测，见 §3.0.5 |
| 原厂固件能否被 r56p0 加载？ | **不能**：`version_minor(3) != 4` → `-EINVAL` | **[E1]** 校验逻辑 + **[D·A]** 实际值 |
| 是否存在兼容分支？ | **无**，`!=` + 无 fallback | **[E1]** |
| 格式层是否兼容？ | **兼容**，entry 编解码逐字相同 | **[E1]** |
| 0.4 改了什么？ | 新增 `PAGE_FAULT_CNT` entry（可选） | **[E1]** |
| GLB 协议层是否兼容？ | 97/97 字段偏移相同，门槛相同 | **[E1]** |
| 运行时 GLB 版本是否足够？ | **UNKNOWN**（无 dmesg、无 GLB 寄存器读；`version_hash` 不能替代，见 §3.0.5 纪律） | **[U]** |
| 固件实体是否已取得？ | **元数据 + 头 16 字节已取得**：307,200 B / SHA256 `334fb676…`；实体未入库 | **[D·A]** |

### 一句可操作的结论

> **固件必须与 Kbase 同代**。`R56p0 Kbase` 只能配 header 为 `0.4` 的固件（Arm R56p0 发布包内的 `mali_csffw.bin`）。
>
> 原厂固件是 `0.3`——**这已由 16 字节读数确认**（`6e 3a f1 c3 03 00 00 00`）。所以正确的表述不再是"极可能不可用"，而是"**读到的字节与 r56p0 期望值不同，加载必然被拒**"。
>
> 至于"改版本号绕过"——那属于篡改固件，且不保证 GLB 协议语义正确，本审计明确排除。

---

## 9. UNKNOWN（本文件负责部分）

| ID | 内容 | 缺失证据 | 影响 |
| --- | --- | --- | --- |
| ~~U4-01~~ | ~~原厂固件 offset 4/5 的实际值~~ | **✅ 已闭合 2026-11-15 23:20**：`03` / `00` → 0.3 | 已升为 **[D·A]**，见 §3.0.5 |
| U4-10 | 固件加载失败后 Android 图形栈的实际降级行为 | 实机故障注入 + dmesg | 决定"是否变砖"还是"仅无 GPU 加速" |
| U4-11 | 原厂固件 GLB 尾部的实际版本号（major.minor.patch） | 运行时读 `GLB_VERSION` 寄存器，或采集 dmesg 中固件自报 | 影响 §5 门槛判定的实际触发情况。**注意：header 的 `version_hash` 不能替代此项**。<br>**2026-11-16 进展**：`entry_end_offset` 子项已闭合（= 1000，§3）；尾部零填充已证实**不携带版本**，故本条只剩"运行时 GLB 版本"一个缺口，且 `dmesg`/`debugfs` 两条路均已排除（`06/STAGE4_REMAINING_AUDIT.md` §2 N-7） |
| U4-12 | R56p0 官方固件的 core mask / 型号字段是否匹配 G925 MC12 | R56p0 固件实体 | 决定固件能否驱动该 SKU |
| U4-13 | `GLB_PRFCNT_NEURAL_EN`、`GLB_REQ_NX_PWR_MODE_ENABLE` 是否被 MTK 平台层使用 | 运行时 | 仅影响 NX 相关特性 |

> **U4-01 的状态迁移（本文件最重要的一条记录，三段式，均已留痕）**：
>
> | 轮次 | 表述 | 性质 |
> | --- | --- | --- |
> | 首轮 | "已确认 0.3" | **错误**：无字节支撑，属证据越级 |
> | 第二轮 | "UNKNOWN + E2 级推理指向 0.3" | 正确：承认推理不等于读数 |
> | **第三轮（本文件现状）** | **"0.3，[D·A] 实测"** | **闭合**：`od` 读到 `03` |
>
> **教训**：三轮之间结论**从未改变**（都是 0.3），改变的只是证据等级。这说明"结论正确"不能反证"证据充分"——本项目后续所有"方向性结论"都必须继续按此标准区分。
>
> 另记：固件内的构建标识 `vb421b363699b1165c0a40c789b8a54f822bece74` 是本次新增的**唯一可追踪锚点**，可用于日后与 Arm R56p0 固件比对是否同一代码线（非版本号）。
