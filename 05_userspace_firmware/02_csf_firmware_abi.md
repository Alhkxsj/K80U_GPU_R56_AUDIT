# 02 — CSF 固件 ABI 分析

> **本文件回答**：原厂 CSF 固件能否直接用于 R56p0？
>
> **答案**：**不能。在固件加载的第一个检查点就被拒绝**，且不存在兼容分支。
>
> 证据等级：**[E1]** 源码直接证据（两版加载器逐行对照）

---

## 0. 结论先行

| 层次 | 检查项 | 两版关系 | 判定 |
| --- | --- | --- | --- |
| **容器层** | 固件文件名 | 都是 `mali_csffw.bin` | 相同 |
| **容器层** | 文件 magic | 同一常量 | 相同 |
| **容器层** | **header 版本** | **0.3 vs 0.4，严格 `!=`** | **🔴 硬阻断** |
| **容器层** | header 长度 / 字段偏移 | 0x14，逐字节相同 | 相同 |
| **编码层** | entry type/size 位域 | `type=h&0xFF`、`size=(h>>8)&0xFF` | 相同 |
| **编码层** | entry 类型集合 | r56p0 多 `PAGE_FAULT_CNT`（可选） | 向后兼容 |
| **协议层** | GLB 全局接口字段 | 97 个共有字段偏移**全部相同** | 相同 |
| **协议层** | 接口版本门槛 | 都要求 ≥ 1.0.0 / ≥ 1.1.0 | 相同 |
| **协议层** | 新增字段处置 | 有 `iface->version >= (1,1,0)` 守卫，旧固件置 0 | 正确降级 |

> 一行的差异（header minor 3 vs 4）足以否决整个组合。这不是"可能有问题"，是**确定性失败**。

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

## 2. 固件头结构（实测字段偏移）

从两版完全相同的解析代码反推：

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

原厂固件 header = `0.3`；r56p0 期望 `0.4`：

```
version_major(0) != 0  → false
version_minor(3) != 4  → true
→ ret = -EINVAL, goto err_out
```

内核日志必然出现：

```
mali_kbase ...: Firmware header version 0.3 not understood
mali_kbase ...: Failed to load firmware image 'mali_csffw.bin'
```

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
| 内核日志 | `Firmware header version 0.3 not understood` + probe 失败 |
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
| 原厂固件能否被 r56p0 加载？ | **不能**，header 0.3 ≠ 0.4，`-EINVAL` | **[E1]** |
| 是否存在兼容分支？ | **无**，`!=` + 无 fallback | **[E1]** |
| 格式层是否兼容？ | **兼容**，entry 编解码逐字相同 | **[E1]** |
| 0.4 改了什么？ | 新增 `PAGE_FAULT_CNT` entry（可选） | **[E1]** |
| GLB 协议层是否兼容？ | 97/97 字段偏移相同，门槛相同 | **[E1]** |
| 运行时 GLB 版本是否足够？ | **UNKNOWN**（无固件实体，无法读 GLB 寄存器） | **[U]** |

### 一句可操作的结论

> **固件必须与 Kbase 同代**。`R56p0 Kbase` 只能配 `0.4` 头版本的固件，即 Arm R56p0 发布包内自带的 `mali_csffw.bin`。原厂 0.3 固件无法使用，也无法"修改版本号绕过"——那属于篡改固件且不保证协议语义。

---

## 9. UNKNOWN（本文件负责部分）

| ID | 内容 | 缺失证据 | 影响 |
| --- | --- | --- | --- |
| U4-10 | 固件加载失败后 Android 图形栈的实际降级行为 | 实机 | 决定"是否变砖"还是"仅无 GPU 加速" |
| U4-11 | 原厂固件 GLB 尾部的实际版本号（major.minor.patch） | 固件实体 / 实机 dmesg | 影响 §5 门槛判定的实际触发情况 |
| U4-12 | R56p0 官方固件的 core mask / 型号字段是否匹配 G925 MC12 | R56p0 固件实体 | 决定固件能否驱动该 SKU |
| U4-13 | `GLB_PRFCNT_NEURAL_EN`、`GLB_REQ_NX_PWR_MODE_ENABLE` 是否被 MTK 平台层使用 | 运行时 | 仅影响 NX 相关特性 |
