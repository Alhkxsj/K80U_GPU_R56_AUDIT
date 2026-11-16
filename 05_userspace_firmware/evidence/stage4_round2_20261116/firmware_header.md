# CSF 固件 header 实测解析（2026-11-16 第二轮采集）

> 对象：`/vendor/firmware/mali_csffw.bin`，**307,200 字节**（300 KiB 整）。
> 来源：`stage4_remainder_20261116_131307.txt` §B（脚本 v1.1，`SELFCHECK` = 668）。
> 解析依据：`01_original_baseline/.../mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware.c`。
> 证据等级：**[D·A]**（设备上直读字节）+ **[E1]**（源码字段定义）。

---

## 1. 原始字节（前 24 字节，即 `0x00`–`0x17`）

```
6e 3a f1 c3 03 00 00 00 00 00 0a 03 00 00 00 00
e8 03 00 00 00 20 00 00
```

| 偏移 | 字节 | 字段 | 值 | 判定 | 源码依据 |
| --- | --- | --- | --- | --- | --- |
| `0x00` | `6e 3a f1 c3` | `magic` | `0xC3F13A6E` | ✅ 与 `FIRMWARE_HEADER_MAGIC` 完全一致 | `:108` |
| `0x04` | `03` | `version_minor` | **3** | ✅ | `:2768` `data[4]` |
| `0x05` | `00` | `version_major` | **0** | ✅ | `:2769` `data[5]` |
| `0x06`–`0x07` | `00 00` | 保留 | 0 | — | — |
| `0x08` | `00 00 0a 03` | `version_hash` | `0x030A0000` | 仅打印/ktrace，**不是 GLB 版本** | `:2783` |
| `0x0C` | `00 00 00 00` | 保留 | 0 | — | — |
| `0x10` | `e8 03 00 00` | **`entry_end_offset`** | **1000**（`0x3E8`） | ✅ 首次取得 | `:2785` |
| `0x14` | `00 20 00 00` | 首个 entry 的 `header` | `0x00002000` | 见 §3 | `:2794` `entry_offset = 0x14` |

> **`entry_end_offset` 此前在 `02` / `07` 里标的是"未采集"**（当时只读到 offset `0x0F`）。本轮补齐，**= 1000**。

---

## 2. 截断检查：必然通过

源码（`mali_kbase_csf_firmware.c:2787`）：

```c
memcpy(&entry_end_offset, &mcu_fw->data[0x10], sizeof(entry_end_offset));

if (entry_end_offset > mcu_fw->size) {
    dev_err(kbdev->dev, "Firmware image is truncated\n");
    ret = -EINVAL;
    goto err_out;
}
```

代入实测值：

| 量 | 值 |
| --- | --- |
| `entry_end_offset` | **1000** |
| `mcu_fw->size`（文件长度） | **307 200** |
| 判定 | `1000 ≤ 307 200` → **不触发 "Firmware image is truncated"** |

**结论 [E1]+[D·A]**：这个固件在 R49 kbase 上**不会因截断被拒**。而且设备确实在渲染（§5 的 GLES 版本串），说明整条 `while (entry_offset < entry_end_offset)` 遍历与 `load_firmware_entry` 全部成功。

---

## 3. 首个 entry 解码：结构自洽

`entry_offset` 从 `FIRMWARE_HEADER_LENGTH = 0x14 = 20` 开始（`:110`），所以 `0x14` 处就是第一个 entry 的 header。

```c
static unsigned int entry_type(u32 header) { return header & 0xFF; }
static unsigned int entry_size(u32 header) { return (header >> 8) & 0xFF; }
```
（`:177`–`:180`）

`header = 0x00002000` 拆解：

| 项 | 计算 | 结果 |
| --- | --- | --- |
| `entry_type` | `0x2000 & 0xFF` | **`0x00` = `CSF_FIRMWARE_ENTRY_TYPE_INTERFACE`** |
| `entry_size` | `(0x2000 >> 8) & 0xFF` | **`0x20` = 32 字节** |
| `entry_update` | `(0x2000 >> 30) & 1` | `0` |
| `entry_optional` | `(0x2000 >> 31) & 1` | `0` |

**这是一条强的自洽检查**：一个随机/损坏的 header 几乎不可能同时给出「type=0（INTERFACE）+ size=32（4 字节对齐、≥ 最小长度）」。而 `load_firmware_entry` 会强制校验：

```c
if ((offset % sizeof(*entry)) || (size % sizeof(*entry)))  // 0x14 % 4 == 0, 32 % 4 == 0 ✓
if (size < sizeof(*entry))                                 // 32 >= 4 ✓
if (size < INTERFACE_ENTRY_NAME_OFFSET + sizeof(*entry))   // 32 >= 0x14+4=24 ✓
```

**三项全过**。⇒ 固件 entry 表在 `0x14` 处正常起步，不是垃圾数据。

### 3.1 INTERFACE entry 的字段布局（供后续补采对照）

`load_firmware_entry` 先 `entry++; size -= 4;`（去掉 header），随后 `parse_memory_setup_entry` 按下列下标读（`:728`–`:732`）：

| 相对 `entry`（= `0x18`） | 字段 |
| --- | --- |
| `+0x00` | `flags` |
| `+0x04` | `virtual_start` |
| `+0x08` | `virtual_end` |
| `+0x0C` | `data_start` |
| `+0x10` | `data_end` |
| `+0x14` | `name[]`（`INTERFACE_ENTRY_NAME_OFFSET = 0x14`，`:128`） |

即绝对偏移 `0x18`–`0x2B` 是 5 个 u32，`0x2C` 起是名字。**本轮只读到 `0x17`，这一段未采**。

> 补采一条命令即可（只读，约 48 字节）：
> ```sh
> od -An -tx1 -j 20 -N 48 /vendor/firmware/mali_csffw.bin
> ```
> 拿到后可验证 `data_end >= data_start`、`virtual_end >= virtual_start`（否则源码报 "Firmware corrupt"），并读出 interface 名字。

---

## 4. 尾部：零填充，无版本串

| 项 | 读数 | 判读 |
| --- | --- | --- |
| 最后 32 字节（`307168`–`307199`） | 全 `00` | 零填充 |
| 尾部 4096 字节内可打印串（`strings -n 4`） | **0 条** | 无版本串、无签名块、无 git sha |

⇒ **固件尾部不携带任何版本信息**。这条同时否掉了「靠读固件尾部拿到 GLB 实际版本」的路线（U4-11 的另一半）。

注意：`entry_end_offset = 1000` 而文件有 307 200 字节，说明 **entry 表只占头部 1 KB，其余 306 KB 是各 entry 指向的代码/数据段**，尾部零填充属于打包对齐惯例，不代表内容缺失。

---

## 5. 与 R56 的硬冲突：header 0.3 vs 0.4，严格相等比较

| | `version_major` | `version_minor` | 校验方式 |
| --- | :---: | :---: | --- |
| **R49p1**（设备在用） | `0` | **`3`** | `!=` **严格相等** |
| **R56p0** | `0` | **`4`** | `!=` **严格相等** |
| **设备固件实测** | `0` | **`3`** | — |

R56p0 源码（`02_r56_source/mali_r56p0/.../csf/mali_kbase_csf_firmware.c:86`）：

```c
#define FIRMWARE_HEADER_VERSION_MINOR (4ul)
```

校验（`:2698`）：

```c
if (version_major != FIRMWARE_HEADER_VERSION_MAJOR ||
    version_minor != FIRMWARE_HEADER_VERSION_MINOR) {
    dev_err(kbdev->dev, "Firmware header version %d.%d not understood\n", ...);
    ret = -EINVAL;
    goto err_out;
}
```

R49p1 的同名校验（`:2771`）**结构完全相同**，只是常量是 `3ul`。

### 5.1 由此得到的确定结论

**R56 Kbase + 本机原厂固件（header 0.3）→ 在 header 校验阶段直接 `-EINVAL`，报 `Firmware header version 0.3 not understood`。**

三个要点：

1. 这发生在 **entry 解析之前**。哪怕 entry 表 100% 兼容、哪怕 DDK 完美适配，都越不过去。
2. 因为 `mali_csffw.bin` 是在**首次 `open("/dev/mali0")` 时加载**（不在 probe），失败表现为 `open()` 返回错误 → 用户态拿不到设备节点。**不会 bootloop**（这与 U4-10 的静态结论一致）。
3. 因此 **U4-12（R56 匹配固件）是独立阻断项，不能被 DDK 改造消除**——这正是任务书强调的那条约束，现在有 [E1]（两侧源码）+ [D·A]（设备字节）的完整证据链。

> **不得**通过修改固件 header 的 `03` → `04` 来"解决"。那只是骗过版本比较：0.3 固件里没有 R56 需要的 entry 类型与 capability 表，后续 `parse_capabilities` / `load_firmware_entry` 会以更难诊断的方式失败（`Shared interface region not found` 之类）。**这也是任务书明令禁止的做法。**

---

## 6. 本文件**不能**证明的事

| 问题 | 为什么不能 |
| --- | --- |
| 固件是否**匹配 G925 MC12** | header 里没有产品 ID 字段。产品绑定在 **DDK 侧**（`tKRx` 的 `features`）与 **capability 表**里，不在固件 header |
| 固件 GLB 的**实际运行版本** | 尾部无版本串（§4）；`dmesg` 里 `Loading Mali firmware` 已被环形缓冲滚掉（97 430 行，最早一行在 72 700 秒之后） |
| 固件是否**支持 R56 新特性** | 需要 R56 的 capability ID 全集与固件 `CSF_FIRMWARE_ENTRY_TYPE_CONFIGURATION` 表逐项对照；本轮只解了 1 个 entry |
| 固件是否**未被篡改** | 只有 SHA256 可做完整性锚点，但没有官方值可比对。**不过** §7 的 mount 证据表明 `/vendor` 是只读 erofs、无 overlay |

---

## 7. 顺带确证：`/vendor` 未被 overlay

本轮 `mountinfo` 完整读出（`stage4_remainder_20261116_131307.txt` §C-1/C-3）：

| 挂载点 | 设备 | 类型 | 选项 | 是否 overlay |
| --- | --- | --- | --- | --- |
| `/vendor` | `/dev/block/dm-13` | `erofs` | `ro,seclabel,...` | **否** |
| `/vendor_dlkm` | `/dev/block/dm-18` | `erofs` | `ro,seclabel,...` | **否** |
| `/odm` | `/dev/block/dm-17` | `erofs` | `ro,...` | 否 |
| `/product` | `/dev/block/dm-14` | `erofs` | `ro,...` | 否（但 `/product/*` 子路径有 overlay） |
| `/system` | `/dev/block/dm-11` | `erofs` | `ro,...` | 否（子路径有 overlay） |

overlay 只出现在 `/product/{app,lib,lib64,etc,...}`、`/system/{app,priv-app,framework,...}`、`/system_ext/etc/permissions` 这些**子路径**，`lowerdir` 全部指向 `mi_ext` / `mi_product`（小米自己的分区），**不是** KSU/Magisk 的模块目录。

⇒ **`/vendor/firmware/mali_csffw.bin` 与 `/vendor_dlkm/lib/modules/*.ko` 读到的都是原厂只读镜像内容**，本轮所有字节级证据不受 root 方案污染。这是 U4-27 的闭合判据。

---

## 8. 引用

- `05_userspace_firmware/02_csf_firmware_abi.md` §2（header 字段表）、§3.0.5（`version_hash` 纪律）
- `05_userspace_firmware/07_device_evidence.md` §4（设备读数）
- `06_porting_design/STAGE4_REMAINING_AUDIT.md` §2 N-7、§5（U4-11 / U4-13）
- `01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware.c`
- `02_r56_source/mali_r56p0/driver/product/kernel/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware.c`
