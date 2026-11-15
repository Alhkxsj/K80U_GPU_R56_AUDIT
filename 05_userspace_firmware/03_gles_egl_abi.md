# 03 — GLES / EGL 用户态 ABI 审计

> **本文件回答**：原厂 `libGLES_mali.so` / `libEGL_mali.so` 能否与 R56p0 Kbase 配合？
>
> **答案**：**从 UAPI 契约看，可以**——这是本阶段最反直觉、也是证据最充分的结论。但"契约兼容"不等于"实测可用"，关键 gap 见 §12。
>
> **前置声明**：仓库内**没有** `libGLES_mali.so` / `libEGL_mali.so`。因此本文件分析的是**内核侧向用户态提供的契约**（[E1] 源码），而非 blob 本身的实现（[U]）。这不是缺陷——契约是唯一有法律效力的接口，blob 必须遵守它。
>
> 证据等级：**[E1]** 源码直接证据 · **[E2]** 交叉推导 · **[U]** UNKNOWN

---

## 0. 结论摘要

| 检查面 | 结果 | 证据 |
| --- | --- | --- |
| ioctl 编号 | 28 个共有，**定义逐字相同**；r56p0 删 5 个、**零新增** | §4 |
| ioctl 结构体 | 30 个共有，**仅 1 个字段改名**（布局不变） | §5 |
| 内存标志位 | CSF 视图 **24/24 一致** | §7 |
| `gpu_props` 属性 ID | 83 个**值全部不变**，新增 3 个**追加在末尾** | §8 |
| 版本协商 | `min(内核, 用户)`，**1.30 用户态会得到 1.30 语义** | §2 |
| 能力门槛 | 1.31/1.32/1.35 的新能力在 1.30 下**全部不生效** | §3 |
| padding 校验 | r56p0 新增，但**Arm 主动替旧用户态清零** | §9 |
| MTK UAPI 扩展 | 存在 3 组，**均为尾部追加**，不破坏标准值 | §10 |

> **总体判断**：这是一次**减法 + 尾部追加**式演进，不是重排。原厂 1.30 用户态在 r56p0 上会走"旧版本路径"，而这些路径的代码与接口在 r56p0 中被完整保留。

---

## 1. DDK 版本确认

### 1.1 直接证据缺失

| 目标 | 状态 |
| --- | --- |
| `libGLES_mali.so` 自身版本串 | **[U]** U4-04（无文件） |
| ELF Build ID / SONAME | **[U]** 无文件 |
| 依赖库列表 | **[U]** 无文件 |

### 1.2 但"它必须宣称的版本"是可确定的

用户态 DDK 与内核协商的版本号，**由内核头文件中的常量定义**——DDK 若违反，握手就会失败。因此原厂 DDK **必然**宣称：

```c
/* r49p1 csf/mali_kbase_csf_ioctl.h:121-122 */
#define BASE_UK_VERSION_MAJOR 1
#define BASE_UK_VERSION_MINOR 30
```

| 项 | 原厂（r49p1 生态） | r56p0 |
| --- | --- | --- |
| 宣称的 UK ABI | **1.30** | 1.39 |
| 依据 | r49p1 UAPI 头常量 | r56p0 UAPI 头常量 `:148-149` |

> 这不是推断，是**逻辑必然**：DDK 编译时用的是 r49p1 的头，`BASE_UK_VERSION_MINOR` 在编译期被固化为 30。

---

## 2. UK ABI 协商机制

### 2.1 协商代码（r56p0 `mali_kbase_core_linux.c:357-390`）

```c
static int kbase_api_handshake(struct kbase_file *kfile,
                               struct kbase_ioctl_version_check *version)
{
    int err = 0;

    switch (version->major) {
    case BASE_UK_VERSION_MAJOR:                                   /* == 1 */
        /* set minor to be the lowest common */
        version->minor = min_t(int, BASE_UK_VERSION_MINOR, (int)version->minor);
        break;
    default:
        /* We return our actual version regardless if it
         * matches the version returned by userspace -
         * userspace can bail if it can't handle this version */
        version->major = BASE_UK_VERSION_MAJOR;
        version->minor = BASE_UK_VERSION_MINOR;
        break;
    }

    err = kbase_file_set_api_version(kfile, version->major, version->minor);
    ...
    if (!mali_kbase_supports_system_monitor(kbase_file_get_api_version(kfile)))
        err = kbase_file_create_kctx(kfile, BASE_CONTEXT_SYSTEM_MONITOR_SUBMIT_DISABLED);
    return err;
}
```

### 2.2 逐步推演：原厂 1.30 用户态会发生什么

| 步骤 | 用户态 | 内核（r56p0） |
| --- | --- | --- |
| 1 | 发 `VERSION_CHECK{major=1, minor=30}` | `major==1` → 命中 `case` |
| 2 | — | `minor = min(39, 30) = **30**` |
| 3 | — | `kbase_file_set_api_version(kfile, 1, 30)` |
| 4 | — | `mali_kbase_supports_system_monitor(1.30)` → 表项是 `{1,0}` → **true** |
| 5 | — | 因 true，**不**提前建 kctx（走正常路径） |
| 6 | 收到 `{1, 30}` | 与自身期望一致 → 继续初始化 |

**关键**：内核不会"假装自己是 1.39"。它把 `kfile->api_version` **固定为 1.30**，后续所有能力判断都以 1.30 为基准。

### 2.3 反例：如果用户态宣称 1.39

`minor = min(39, 39) = 39` → 拿到 1.39 语义。**同一份内核可服务两代 DDK**，靠的就是这个 `min()`。

### 2.4 major 不匹配时的行为

若用户态宣称 `major=2`：走 `default` 分支，内核**强制回填** `{1, 39}`。用户态可以选择"发现不匹配就退出"——注释明确写了 *"userspace can bail if it can't handle this version"*。

> 这是**协商而非拒绝**的设计：内核从不主动拒绝版本，只负责告知真实版本。是否继续由用户态决定。

---

## 3. 能力阈值表（兼容窗口的物理实现）

### 3.1 完整表（r56p0 `mali_kbase_core_linux.c:148-166`）

```c
static const struct mali_kbase_capability_def kbase_caps_table[MALI_KBASE_NUM_CAPS] = {
    { 1, 0 },  /* SYSTEM_MONITOR */
    { 1, 0 },  /* JIT_PRESSURE_LIMIT */
    { 1, 22 }, /* QUERY_MEM_DONT_NEED */
    { 1, 0 },  /* QUERY_MEM_GROW_ON_GPF */
    { 1, 0 },  /* QUERY_MEM_PROTECTED */
    { 1, 26 }, /* QUERY_MEM_IMPORT_SYNC_ON_MAP_UNMAP */
    { 1, 26 }, /* QUERY_MEM_KERNEL_SYNC */
    { 1, 28 }, /* QUERY_MEM_SAME_VA */
    { 1, 31 }, /* REJECT_ALLOC_MEM_DONT_NEED */
    { 1, 31 }, /* REJECT_ALLOC_MEM_PROTECTED_IN_UNPROTECTED_ALLOCS */
    { U16_MAX, U16_MAX }, /* REJECT_ALLOC_MEM_UNUSED_BIT_8   —— 永不启用 */
    { U16_MAX, U16_MAX }, /* REJECT_ALLOC_MEM_UNUSED_BIT_19  —— 永不启用 */
    { 1, 31 }, /* REJECT_ALLOC_MEM_UNUSED_BIT_20 */
    { 1, 31 }, /* REJECT_ALLOC_MEM_UNUSED_BIT_27 */
    { 1, 32 }, /* REJECT_ALLOC_MEM_UNUSED_BIT_5  */
    { 1, 32 }, /* REJECT_ALLOC_MEM_UNUSED_BIT_7  */
    { U16_MAX, U16_MAX }, /* REJECT_ALLOC_MEM_UNUSED_BIT_29 —— 永不启用 */
    { 1, 35 }  /* CSG_CS_USER_PAGE_ALLOCATION */
};
```

### 3.2 对原厂 1.30 用户态的实际效果

| 能力 | 门槛 | 1.30 下 | 实际效果 |
| --- | --- | --- | --- |
| `SYSTEM_MONITOR` | 1.0 | ✔ 生效 | 正常 |
| `JIT_PRESSURE_LIMIT` | 1.0 | ✔ | 正常 |
| `QUERY_MEM_DONT_NEED` | 1.22 | ✔ | 正常（1.30 > 1.22） |
| `QUERY_MEM_IMPORT_SYNC_ON_MAP_UNMAP` | 1.26 | ✔ | 正常 |
| `QUERY_MEM_KERNEL_SYNC` | 1.26 | ✔ | 正常 |
| `QUERY_MEM_SAME_VA` | 1.28 | ✔ | 正常 |
| `REJECT_ALLOC_MEM_DONT_NEED` | 1.31 | ✘ | **不启用**——传 DONT_NEED 仍被接受 |
| `REJECT_ALLOC_MEM_PROTECTED_IN_UNPROTECTED_ALLOCS` | 1.31 | ✘ | **不启用**——旧宽松行为保留 |
| `REJECT_ALLOC_MEM_UNUSED_BIT_20/27` | 1.31 | ✘ | **不启用**——传这些位不报错 |
| `REJECT_ALLOC_MEM_UNUSED_BIT_5/7` | 1.32 | ✘ | **不启用** |
| `CSG_CS_USER_PAGE_ALLOCATION` | **1.35** | ✘ | **走旧路径**：CS_USER 页在 **CS bind 时**分配，而非 CSG 创建时 |

> **这张表是本次审计最重要的发现之一**。它证明 r56p0 **内置了 r49p1 时代的完整行为**——不是"勉强兼容"，而是"显式保留旧语义"。
>
> 特别是 `CSG_CS_USER_PAGE_ALLOCATION`（1.35）：这是一个**内存分配时机**的结构性改动。r56p0 为旧用户态保留了"CS bind 时分配"的旧路径。如果 r56p0 强行用新语义，原厂用户态会拿不到 CS_USER 页 → CS 无法启动。

### 3.3 与 `REJECT_ALLOC_MEM_UNUSED_BIT_*` 的关系

这组能力的存在，回答了 §7 的"消失位"问题：r56p0 **不是静默忽略**未用位，而是**按版本选择性拒绝**。

- 1.39 用户态：传 bit20 → `-EINVAL`（严格）
- 1.30 用户态：传 bit20 → 接受（宽容）

这是**向后兼容的精确实现**——新用户态被约束，旧用户态被豁免。

---

## 4. ioctl 面比对

### 4.1 总数与差异

| 项 | 数量 |
| --- | ---: |
| r49p1 定义 | 33 |
| r56p0 定义 | 28 |
| **共有且定义逐字相同** | **28** |
| 仅 r49p1 | 5 |
| **仅 r56p0** | **0** |

> **r56p0 的 ioctl 面是 r49p1 的严格子集。**

### 4.2 被删除的 5 个

| ioctl | 编号 | 用途 | 影响评估 |
| --- | --- | --- | --- |
| `KBASE_IOCTL_DISJOINT_QUERY` | 12 | JM 时代的 disjoint 查询 | JM 专用，CSF 设备不用 |
| `KBASE_IOCTL_HWCNT_SET` | 32 | 旧 hwcnt 配置 | 被 `KINSTR_PRFCNT_SETUP` 取代 |
| `KBASE_IOCTL_CINSTR_GWT_START` | 33 | GPU Writer Trace 开始 | 被 kinstr_prfcnt 取代 |
| `KBASE_IOCTL_CINSTR_GWT_STOP` | 34 | GWT 停止 | 同上 |
| `KBASE_IOCTL_CINSTR_GWT_DUMP` | 35 | GWT 导出 | 同上 |

**风险评估**：

| 场景 | 后果 |
| --- | --- |
| 原厂 DDK 在正常渲染路径用这些 | **极不可能**——它们全是 profiling/debug 工具接口 |
| 原厂 DDK 在 `dumpsys`/`perfetto` GPU 计数路径用 | **可能**——则性能计数功能失效（`-ENOTTY`），不影响渲染 |
| 原厂 DDK 在启动时无条件调用 | 若未检查返回值会误判；但 `-ENOTTY` 是干净失败 |

> 注意 `KBASE_IOCTL_SET_LIMITED_CORE_COUNT` 与 `KBASE_IOCTL_INTERNAL_FENCE_WAIT` 也属"仅 r49p1"，但前者是 **MTK 定制**（见 §10.1），后者是 **MTK debug 配置**。

### 4.3 编号未重排的证据

28 个共有 ioctl 的 `_IOW/_IOWR(type, nr, struct)` 三元组**逐字相同**。这意味着 **编号空间没有被打乱**——r49p1 的 28 个 ioctl 在 r56p0 上仍落在同一个号上。

> 如果发生过重排，哪怕是 1 个号偏移，都会导致"调 A 却执行 B"的灾难。这里没有。

---

## 5. ioctl 结构体比对

### 5.1 总体

| 项 | 数量 |
| --- | ---: |
| r49p1 `kbase_ioctl_*` 结构/联合 | 35 |
| r56p0 | 30 |
| 共有 | 30 |
| **共有中字段完全相同的** | **29** |
| 共有中字段有差异的 | **1** |

### 5.2 唯一的结构体差异

```c
/* r49p1 mali_kbase_ioctl.h —— struct kbase_ioctl_mem_sync */
struct kbase_ioctl_mem_sync {
    __u64 handle;          /* ← 名字 */
    __u64 user_addr;
    __u64 size;
    __u8  type;
    __u8  padding[7];
};

/* r56p0 同结构 */
struct kbase_ioctl_mem_sync {
    __u64 gpu_va;          /* ← 改名 */
    __u64 user_addr;
    __u64 size;
    __u8  type;
    __u8  padding[7];
};
```

**只是改名**。字段类型、顺序、大小、偏移全部不变 → **ABI 等价**。

> 语义上也一致：在 `SAME_VA` 分配下，`handle` 本身就是 GPU VA。改名是为了澄清语义，不是行为变更。

### 5.3 CSF 专有结构体

`csf/mali_kbase_csf_ioctl.h` 中 13 个结构体：**字段全部相同，零差异**。

包括最关键的：
- `kbase_ioctl_cs_queue_register`（CS 队列注册）
- `kbase_ioctl_cs_queue_bind`（CS 绑定）
- `kbase_ioctl_cs_queue_kick`（CS 提交）
- `kbase_ioctl_cs_get_glb_iface`（读 GLB 接口信息）
- `kbase_ioctl_cs_tiler_heap_init`（tiler heap）

> **这些是 CSF 渲染的主干接口**。它们逐字段相同，是"原厂用户态可用"判断的核心支撑。

---

## 6. 版本化结构体：同号不同 size

### 6.1 机制

r56p0 的 `mali_kbase_csf_ioctl.h` 对同一个 ioctl 号保留了**多个版本的结构体**：

| 定义 | ioctl 号 | 结构体 | 对应 API 版本 |
| --- | ---: | --- | --- |
| `KBASE_IOCTL_CS_QUEUE_GROUP_CREATE_1_6` | 42 | `union ..._1_6` | 1.6 |
| `KBASE_IOCTL_CS_QUEUE_GROUP_CREATE_1_18` | **58** | `union ..._1_18` | 1.18 |
| `KBASE_IOCTL_CS_QUEUE_GROUP_CREATE_1_35` | **58** | `union ..._1_35` | 1.35 |
| `KBASE_IOCTL_CS_QUEUE_GROUP_CREATE` | **58** | `union ...`（当前） | 最新 |

### 6.2 为什么"同号"却能区分

`_IOWR(type, nr, datatype)` 展开为：

```
dir<<30 | sizeof(datatype)<<16 | type<<8 | nr
```

**`size` 字段被编码进 ioctl 值**。因此：

- `_1_18`：size = `sizeof(union _1_18)` = **40**
- `_1_35`：size = `sizeof(union _1_35)` = **112**

两者 `nr` 都是 58，但**完整 ioctl 值不同** → `switch` 里是两个不同的 `case`。

### 6.3 内核分派（r56p0 `mali_kbase_core_linux.c:1827-1845`）

```c
case KBASE_IOCTL_CS_QUEUE_GROUP_CREATE_1_6:
    KBASE_HANDLE_IOCTL_INOUT(KBASE_IOCTL_CS_QUEUE_GROUP_CREATE_1_6, ...);
case KBASE_IOCTL_CS_QUEUE_GROUP_CREATE_1_18:
    KBASE_HANDLE_IOCTL_INOUT(KBASE_IOCTL_CS_QUEUE_GROUP_CREATE_1_18, ...);
case KBASE_IOCTL_CS_QUEUE_GROUP_CREATE_1_35:
    KBASE_HANDLE_IOCTL_INOUT(KBASE_IOCTL_CS_QUEUE_GROUP_CREATE_1_35, ...);
case KBASE_IOCTL_CS_QUEUE_GROUP_CREATE:
    KBASE_HANDLE_IOCTL_INOUT(KBASE_IOCTL_CS_QUEUE_GROUP_CREATE, ...);
```

### 6.4 原厂 1.30 用户态走哪条

`1.18 ≤ 1.30 < 1.35` → 用户态用 `_1_18` 结构（40 字节）→ 命中 `case _1_18`。

**而 r49p1 与 r56p0 的 `union _1_18` 逐字相同**（已 diff 验证）：

```c
union kbase_ioctl_cs_queue_group_create_1_18 {
    struct {
        __u64 tiler_mask;      __u64 fragment_mask;  __u64 compute_mask;
        __u8  cs_min;          __u8  priority;
        __u8  tiler_max;       __u8  fragment_max;   __u8 compute_max;
        __u8  csi_handlers;    __u8  padding[2];
        __u64 dvs_buf;
    } in;
    struct { __u8 group_handle; __u8 padding[3]; __u32 group_uid; } out;
};
```

### 6.5 `_1_35` 如何扩展而不破坏 `_1_18`

```c
union kbase_ioctl_cs_queue_group_create_1_35 {
    struct {
        __u64 tiler_mask; __u64 fragment_mask; __u64 compute_mask;
        __u8  cs_min; __u8 priority; __u8 tiler_max;
        __u8  fragment_max; __u8 compute_max; __u8 csi_handlers;
        __u8  neural_max;              /* ← 新增，复用 padding[0] */
        __u8  cs_fault_report_enable;  /* ← 新增，复用 padding[1] */
        __u64 dvs_buf;                 /* 偏移仍是 32 —— 未被挤动 */
        __u64 neural_mask;             /* ← 尾部新增 */
        __u8  comp_pri_threshold; __u8 comp_pri_ratio;
        __u8  padding[62];
    } in;
    ...
};
```

**关键**：新增的两个 1 字节字段**精确填进原来的 `padding[2]`**，所以 `dvs_buf` 偏移保持在 32。这是教科书级的兼容扩展。

> `neural_max` / `neural_mask` 说明 r56p0 为 Immortalis 的神经加速器（NX）预留了 CSG 配置位——与 §6.3 的 `GLB_PRFCNT_NEURAL_EN` 呼应。

---

## 7. 内存标志位

### 7.1 比较口径的重要性

**首次比较（错误口径）**：扫描整个 UAPI 目录（含 JM 头）→ 得出"5 个位消失"。

**正确口径**：只比较 CSF 视图（`mali_base_common_kernel.h` + `csf/*` 头）→ **24 位一致，2 位改名**。

| 位 | r49p1（CSF 视图） | r56p0（CSF 视图） | 判定 |
| ---: | --- | --- | --- |
| 0–4 | `PROT_CPU_RD/WR`、`PROT_GPU_RD/WR/EX` | 同 | 一致 |
| **5** | `BASEP_MEM_PERMANENT_KERNEL_MAPPING` | `BASE_MEM_UNUSED_BIT_5` | 改名（kernel-only） |
| 6 | `GPU_VA_SAME_4GB_PAGE` | 同 | 一致 |
| **7** | `BASEP_MEM_NO_USER_FREE` | `BASE_MEM_UNUSED_BIT_7` | 改名（kernel-only） |
| 8 | `BASE_MEM_FIXED` | 同 | 一致 |
| 9–18 | `GROW_ON_GPF` … `IMPORT_SHARED` | 同 | 一致 |
| 19 | `BASE_MEM_CSF_EVENT` | 同 | 一致 |
| 20 | `BASE_MEM_UNUSED_BIT_20` | 同 | **一致（两版都是"未用"）** |
| 21 | `UNCACHED_GPU` | 同 | 一致 |
| 26 | `IMPORT_SYNC_ON_MAP_UNMAP` | 同 | 一致 |
| 27 | `BASE_MEM_UNUSED_BIT_27` | 同 | **一致** |
| 28 | `KERNEL_SYNC` | 同 | 一致 |
| 29 | `BASE_MEM_FIXABLE` | 同 | 一致 |

### 7.2 bit20 / bit27 的真相

r49p1 自己在 CSF 头里就写明了：

```c
/* r49p1 csf/mali_base_csf_kernel.h:52 */
/* Unused bit for CSF, only used in JM for BASE_MEM_FLAG_MAP_FIXED */
```

r56p0 的 `csf/mali_kbase_csf_mem_flags.h:46`：

```c
/* Unused bit for CSF, only used in JM for BASE_MEM_TILER_ALIGN_TOP */
#define BASE_MEM_UNUSED_BIT_20 ((base_mem_alloc_flags)1 << 20)
```

**两版都认为 bit20/27 在 CSF 下未用**。因为 r56p0 删掉了 JM 头，这两个位的"JM 用途"定义也随之消失，看起来像"新出现"，实际是**比较口径造成的错觉**。

### 7.3 `BASEP_MEM_FLAGS_KERNEL_ONLY` 的语义陷阱

| 版本 | 定义 | 实际含义 |
| --- | --- | --- |
| r49p1 | `BASEP_MEM_FLAGS_KERNEL_ONLY = (PERMANENT_KERNEL_MAPPING \| NO_USER_FREE)` | **bit5 \| bit7** |
| r56p0 | `BASE_MEM_FLAGS_KERNEL_ONLY = ~(((1) << (64 - 4)) - 1)` | **高 4 位 bit60–63** |

**同名不同义**。r56p0 的 `BASEP_MEM_FLAGS_NR_BITS = 4` 指的是"从 bit63 向下数的 4 位"，不是 bit5/7。

> 这是极易误读的点：若按名字以为 r56p0 也保护 bit5/7，就会误判"用户态传 bit5 会被拒"。实际不会（见 §3.3，是否拒绝由能力表按版本决定）。

---

## 8. `gpu_props` 接口

### 8.1 真正的 ABI 是"ID + value 流"，不是结构体

这是本次审计推翻 Stage 2 结论的关键。

内核**不 memcpy 结构体**，而是按 `gpu_property_mapping[]` 表逐项序列化：

```c
/* r56p0 mali_kbase_gpuprops.c:845-899 */
for (i = 0; i < count; i++) {
    u32 type = gpu_property_mapping[i].type;
    const size_t offset = gpu_property_mapping[i].offset;
    ...
    if (likely(offset < sizeof(struct gpu_props_user_data)))
        field = ((const u8 *)&props) + offset;
    else
        field = &dummy_backwards_compat_value;      /* ← 越界保护 */

    WRITE_U32((type << 2) | type_size);             /* ID 低 2 位 = 值大小 */
    switch (type_size) { case 1: WRITE_U8(...); case 8: WRITE_U64(...); }
}
```

**格式**：`<u32 ID|size><value>` 重复 N 次。**自描述**：每项自带大小，读者可跳过不认识的项。

### 8.2 属性 ID 对比

| 项 | r49p1 | r56p0 |
| --- | ---: | ---: |
| 属性项总数 | 83 | 86 |
| 共有 | 83 | 83 |
| **共有项 ID 值变化** | **0** | **0** |
| 新增 | — | `RAW_BASE_PRESENT`=86、`RAW_NEURAL_PRESENT`=87、`NUM_ACTIVE_GRANULARITY`=88 |

**新增 ID 全部大于 r49p1 的最大值（85），即严格追加，无插入。**

### 8.3 结构体大小确实变了，但不构成越界

编译器实测（`gcc -fsyntax-only` 提取结构体并 `sizeof`）：

| 字段 | r49p1 | r56p0 | 变化 |
| --- | ---: | ---: | ---: |
| `sizeof(gpu_props_user_data)` | **568** | **592** | **+24** |
| `offsetof(l2_props)` | 56 | **63** | +7 |
| `offsetof(tiler_props)` | 60 | 68 | +8 |
| `offsetof(thread_props)` | 68 | 76 | +8 |
| `offsetof(raw_props)` | 96 | 104 | +8 |
| `offsetof(coherency_info)` | 296 | 320 | +24 |

**+24 字节是事实，Stage 2 的数字没错**。但"导致用户态缓冲区越界"的推论**不成立**，原因见 §8.4。

r56p0 用显式 `unused` 数组（`unused0[2]`、`unused1[4]`、`unused2[7]`、`unused4[2]`、`unused5`、`unused6[4]`）+ 3 个真字段（`num_active_granularity`、`base_present`、`neural_present`）重构了布局。显式 padding 的目的是**锁死偏移**，避免编译器在不同配置下产生差异。

### 8.4 为什么不会越界：两阶段 size 协商

```c
/* r56p0 mali_kbase_core_linux.c:869-891；r49p1 同位置逻辑逐字相同 */
static int kbase_api_get_gpuprops(struct kbase_file *kfile,
                                  struct kbase_ioctl_get_gpuprops *get_props)
{
    struct kbase_gpu_props *kprops = &kfile->kbdev->gpu_props;
    int err;

    if (get_props->flags != 0) { ... return -EINVAL; }

    if (get_props->size == 0)
        return (int)kprops->prop_buffer_size;        /* ① 查询：返回所需大小 */

    if (get_props->size < kprops->prop_buffer_size)
        return -EINVAL;                              /* ② 太小：干净拒绝 */

    err = copy_to_user(u64_to_user_ptr(get_props->buffer),
                       kprops->prop_buffer, kprops->prop_buffer_size);   /* ③ 只写这么多 */
    ...
}
```

**三重保护**：

1. `size == 0` → 返回所需大小（协议规定的第一步）
2. `size < 需要` → `-EINVAL`，**不写任何字节**
3. `copy_to_user` 的长度是 `prop_buffer_size`，**不是** `sizeof(struct)`

**因此**：

| 用户态行为 | 结果 |
| --- | --- |
| 遵循两阶段协议 | 正常拿到 86 项（或它认识的 83 项） |
| 硬编码旧 size（568）但实际需要 600+ | `-EINVAL`，**干净失败，无内存破坏** |
| 硬编码超大 size | 正常，只写 `prop_buffer_size` 字节 |

> **Stage 3-REA 的推翻结论（P0 → P2）在此得到更强支撑**：不仅"有守卫"，而且**结构体根本不以整体形式跨边界**。

### 8.5 新增 3 项对旧用户态的影响

`prop_buffer_size` 增量为：

| 新增项 | 大小 | 序列化开销 |
| --- | ---: | ---: |
| `NUM_ACTIVE_GRANULARITY`（u32） | 4 | 4 + 4 = 8 |
| `RAW_BASE_PRESENT`（u64） | 8 | 4 + 8 = 12 |
| `RAW_NEURAL_PRESENT`（u64） | 8 | 4 + 8 = 12 |
| **合计** | — | **+32 字节** |

旧用户态若严格校验"收到的字节数 == 预期的常量"，会因多 32 字节而报错；若按自描述格式逐项读取并忽略未知 ID，则完全正常。**哪种行为属于 UNKNOWN（U4-04）**。

---

## 9. padding 校验：r56p0 的新增门槛？

### 9.1 机制差异

| 项 | r49p1 | r56p0 |
| --- | --- | --- |
| 分派宏位置 | `mali_kbase_core_linux.c:1785` | `mali_kbase_ioctl_helpers.h:75` |
| `check_padding_##cmd()` | **无** | **有** |

r56p0 新增了逐 ioctl 的 padding 校验钩子。

### 9.2 但绝大多数校验是空操作

```c
/* r56p0 mali_kbase_ioctl_helpers.h:99-215 */
static inline int check_padding_KBASE_IOCTL_VERSION_CHECK(...) { return 0; }
static inline int check_padding_KBASE_IOCTL_SET_FLAGS(...)     { return 0; }
static inline int check_padding_KBASE_IOCTL_GET_GPUPROPS(...)  { return 0; }
static inline int check_padding_KBASE_IOCTL_MEM_ALLOC(...)     { return 0; }
...
```

**只有两个真正检查**：

```c
static inline int check_padding_KBASE_IOCTL_GET_DDK_VERSION(struct kbase_ioctl_get_ddk_version *p)
{ return p->padding; }

static inline int check_padding_KBASE_IOCTL_MEM_JIT_INIT(struct kbase_ioctl_mem_jit_init *p)
{ for (i = 0; i < ARRAY_SIZE(p->padding); i++) if (p->padding[i]) return -1; return 0; }
```

### 9.3 最关键的是：Arm 主动替旧用户态清零

```c
/* r56p0 mali_kbase_ioctl_helpers.h:152-167 */
static inline int check_padding_KBASE_IOCTL_MEM_SYNC(struct kbase_ioctl_mem_sync *p)
{
    size_t i;

    /*
     * Checking p->padding is deferred till the support window for
     * backward-compatibility ends. GPUCORE-42000 will add the checking.
     *
     * To avoid the situation with old version of base which might not set
     * padding bytes as 0, padding bytes are set as zero here on behalf on
     * user space.
     */
    for (i = 0; i < ARRAY_SIZE(p->padding); i++)
        p->padding[i] = 0;          /* ← 替用户态清零 */

    return 0;
}
```

> **这段注释是本次审计中最重要的文本证据之一**。它明确表明：
> 1. Arm **知道**旧版用户态可能不清零 padding
> 2. Arm 选择**替它清零**而不是拒绝
> 3. 严格检查被**推迟到兼容窗口结束后**（`GPUCORE-42000`）
>
> 这直接排除了"padding 校验构成兼容门槛"的假设。

### 9.4 对有真实检查的两个 ioctl 的评估

| ioctl | 检查内容 | 风险 |
| --- | --- | --- |
| `GET_DDK_VERSION` | `p->padding` 必须为 0 | 用户态若不清零 → `-EINVAL`。但该 ioctl 仅用于查询版本，失败可降级 |
| `MEM_JIT_INIT` | `p->padding[]` 必须全 0 | JIT 内存初始化失败 → tiler heap 不可用 → **可能影响渲染** |

**风险等级**：`MEM_JIT_INIT` 是唯一需要关注的。但原厂 DDK 是否清零 padding 属于 **[U] U4-04**。

---

## 10. MTK 在 UAPI 层做了什么

### 10.1 三组条件编译扩展

全部位于 r49p1 的 UAPI 头，受 `CONFIG_MALI_MTK_*` 控制。**r56p0 完全没有这些**。

| 配置 | 扩展内容 | 位置 |
| --- | --- | --- |
| `CONFIG_MALI_MTK_FENCE_DEBUG` | `kbase_ioctl_internal_fence_wait`（**新增 ioctl**） | `mali_kbase_ioctl.h` |
| `CONFIG_MALI_MTK_DEBUG_DUMP` | `enum mtk_base_csf_notification_dump_cmd`；`base_csf_notification.payload.dump` | `csf/mali_base_csf_kernel.h:578-593,618-622` |
| `CONFIG_MALI_MTK_HWCNT_HINT` | `BASE_NOTIFICATION_HWCNT`；`BASE_CSF_NOTIFICATION_HWCNT` | 同文件 `:530,572` |

### 10.2 关键：插入位置都在尾部

```c
/* enum base_csf_notification_type —— r49p1 */
enum base_csf_notification_type {
    BASE_CSF_NOTIFICATION_EVENT = 0,
    BASE_CSF_NOTIFICATION_GPU_QUEUE_GROUP_ERROR,     /* 1 */
    BASE_CSF_NOTIFICATION_CPU_QUEUE_DUMP,            /* 2 */
#if IS_ENABLED(CONFIG_MALI_MTK_HWCNT_HINT)
    BASE_CSF_NOTIFICATION_HWCNT,                     /* 3 —— 追加 */
#endif
    BASE_CSF_NOTIFICATION_COUNT                      /* 3 或 4 */
};
```

**0/1/2 三个值不变**。r56p0 的标准版是 `EVENT=0, ERROR=1, DUMP=2, COUNT=3`，与 MTK 版的 0/1/2 **完全对齐**。

`struct base_csf_notification` 的 union：

```c
union {
    struct { __u8 handle; __u8 padding[7]; struct base_gpu_queue_group_error error; } csg_error;
#if IS_ENABLED(CONFIG_MALI_MTK_DEBUG_DUMP)
    struct { __u8 cmd; } dump;      /* 1 字节，远小于 align[56] */
#endif
    __u8 align[56];                 /* ← 强制 union 大小 */
} payload;
```

`align[56]` 锁死了 union 大小 → 加 `dump` **不改变** `sizeof(base_csf_notification)`。

### 10.3 影响评估

| MTK 扩展 | 在 r56p0 上的表现 |
| --- | --- |
| `internal_fence_wait` ioctl | `-ENOTTY`（不存在）。仅 MTK 的 fence 调试流程受影响 |
| `HWCNT` 通知 | r56p0 永不发出 type=3 通知 → 用户态收不到。功能静默缺失 |
| `CPU_QUEUE_DUMP` 的 `cmd` 字段 | r56p0 的 `payload` 是 union，`cmd` 位置可能是垃圾 → 但 type=2 时 r56p0 也发 DUMP 通知，只是不含 cmd 语义 |

> **这三项全属诊断类**，不影响 GLES 渲染主路径。但若原厂 DDK 依赖 `HWCNT` 通知做 DVFS 联动，会有性能影响（**E3** 推断）。

---

## 11. 内存管理接口

### 11.1 主干 ioctl（全部逐字相同）

| ioctl | 作用 | 结构体差异 |
| --- | --- | --- |
| `MEM_ALLOC` | 分配 GPU 内存 | 无 |
| `MEM_ALLOC_EX` | 扩展分配（带 `extent`） | 无 |
| `MEM_IMPORT` | 导入 dma-buf | 无 |
| `MEM_FREE` | 释放 | 无 |
| `MEM_ALIAS` | 创建别名（多 VA 指向同一 PA） | 无 |
| `MEM_QUERY` | 查询属性 | 无 |
| `MEM_COMMIT` | 提交/回退 | 无 |
| `MEM_SYNC` | 缓存同步 | **仅字段改名** |
| `MEM_FLAGS_CHANGE` | 修改标志 | 无 |
| `MEM_JIT_INIT` | JIT 池初始化 | 无（但 padding 检查见 §9.4） |
| `MEM_FIND_CPU_OFFSET` | PA → CPU offset | 无 |
| `MEM_FIND_GPU_START_AND_OFFSET` | PA → GPU VA | 无 |

### 11.2 `MEM_ALLOC` 的 `extension` 字段

两版都有 `union kbase_ioctl_mem_alloc { struct { ...; __u8 extension; } in; ... }`。

`extension` 非零时启用 `MEM_ALLOC_EX` 语义。**两版一致**。

### 11.3 保护内存（DRM / SVP）路径

`BASE_MEM_PROTECTED`（bit16）两版一致。PMA 的 ops 结构在 TASK 03 已证**逐字节相同**（`04_mgm_pma_memory_audit.md` §3）。

结合本文件：

- `MEM_ALLOC` 带 `PROTECTED` → 内核转交 PMA `pma_alloc_page`
- r56p0 的 PMA 接口与 r49p1 相同（TASK 03 [E1]）
- 因此**保护内存路径在用户态 ABI 层无变化**

> 这修正了 Stage 2 的"PMA 缺失导致 DRM 视频无法播放"——PMA 本身完全兼容，问题只在于 MTK 的 `mali_prot_alloc_mt6991_r49.ko` 是否被保留（TASK 03 判定：保留）。

---

## 12. 结论与剩余 gap

### 12.1 逐项回答任务书四-C 的 8 个问题

| # | 问题 | 答案 | 等级 |
| ---: | --- | --- | --- |
| 1 | 用户态 DDK 版本 | **无法确认具体版本串**（无 blob），但**必然宣称 UK ABI 1.30** | [E1]/[U] |
| 2 | ELF Build ID / SONAME / 依赖 | **UNKNOWN**（无 blob） | [U] |
| 3 | UK ABI 识别与协商逻辑 | `handshake` 取 `min()`，major 不匹配则回填内核版本 | [E1] |
| 4 | GPU 属性查询 ioctl | `GET_GPU_PROPS`，两阶段 size 协商，83 ID 不变 + 3 新增 | [E1] |
| 5 | 内存分配/导入/释放接口 | 12 个主干 ioctl 全部逐字相同；`MEM_SYNC` 仅字段改名 | [E1] |
| 6 | r49p1 vs R56p0 UAPI 对照 | 见 §4/§5/§7/§8 | [E1] |
| 7 | `gpu_props_user_data` / 句柄 / CSG 创建变化 | 结构体 +24 但**不越界**；句柄语义不变；CSG 有 `_1_6/_1_18/_1_35` 三代，1.30 走 `_1_18` | [E1] |
| 8 | 不兼容时的错误处理 | **无兼容性拒绝**——见 §2.4、§9.3；唯一硬失败点是固件（见 `02_csf_firmware_abi.md`） | [E1] |

### 12.2 核心判断

> **原厂 1.30 用户态与 r56p0 的 UAPI 契约兼容。**
>
> 支撑：
> 1. ioctl 面是严格子集，28/28 定义逐字相同
> 2. 结构体 30/30 兼容（1 个仅改名）
> 3. 内存标志 CSF 视图 24/24 一致
> 4. 属性 ID 83/83 不变，新增严格追加
> 5. 能力表**显式保留 1.30 时代的全部旧行为**
> 6. padding 校验被 Arm 主动放宽
>
> 这个结论**比 TASK 03 的预期更乐观**——TASK 03 认为用户态必须替换，实测契约层面不需要。

### 12.3 但这不等于"能用"

契约兼容是**必要条件**，不是充分条件。以下 gap 仍会阻断：

| Gap | 说明 | 归属 |
| --- | --- | --- |
| **固件不兼容** | header 0.3 ≠ 0.4，**硬阻断** | `02_csf_firmware_abi.md` §3 |
| 用户态是否用被删的 5 个 ioctl | 若用则 `-ENOTTY` | [U] U4-04 |
| 用户态是否清零 padding | `MEM_JIT_INIT` 会拒 | [U] U4-04 |
| 用户态是否严格校验 props 字节数 | 会因 +32 报错 | [U] U4-04 |
| MTK 扩展是否被依赖 | `internal_fence_wait`/`HWCNT` 失效 | [E3] |
| CSF 协议语义 | 需固件实体才能验 | [U] |

**结论**：`R56p0 Kbase + R56p0 固件 + 原厂用户态`（组合 C）在契约层是**可行候选**，但必须实机验证。详见 `06_abi_compatibility_matrix.md`。

### 12.4 UNKNOWN（本文件负责部分）

| ID | 内容 | 补齐方式 |
| --- | --- | --- |
| U4-04 | 原厂 DDK 的 UK ABI 实际宣称值、是否清 padding、是否严格校验 props | 采集 `libGLES_mali.so` + `strace` 实机 |
| U4-14 | 原厂 DDK 是否调用被删的 5 个 ioctl | `strace -e ioctl` 实机 |
| U4-15 | 原厂 DDK 对 `gpu_props` 新 ID 的处理（跳过 or 报错） | 实机 + 反编译 |
| U4-16 | 原厂 DDK 是否依赖 `HWCNT` 通知做 DVFS | 反编译 + 实机 perfetto |
