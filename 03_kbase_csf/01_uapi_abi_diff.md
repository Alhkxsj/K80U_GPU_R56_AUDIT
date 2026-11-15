# Kbase UAPI / UK ABI 差异审计：r49p1-03bet0 → r56p0-18eac0

> 审计标的：Redmi K80 至尊版（25060RK16C）/ MT6991 / Immortalis-G925 MC12
> 审计方式：纯静态比对，不改源码、不编译、不部署
> 审计日期：2026-11-15
> 本文件所有行号均为**实测行号**，可直接 `sed -n 'Np'` 复核
> 依据：`02_r56_source/mali_r56p0/driver/product/kernel/` @ **r56p0-18eac0**（`drivers/gpu/arm/midgard/Kbuild:75`）
> 对照：`01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/` @ **r49p1-03bet0**（`drivers/gpu/arm/midgard/Makefile:526`）
> 版本标识：UK ABI **1.30 → 1.39**（`include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_ioctl.h:122` → `:149`）

---

## 0. 路径基准与核验

| 项 | 值 |
| --- | --- |
| 出厂基线根 | `01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/` |
| UAPI 子路径（r49p1） | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/` |
| R56p0 根 | `02_r56_source/mali_r56p0/driver/product/kernel/` |
| UAPI 子路径（r56p0） | `include/uapi/gpu/arm/midgard/` |

**路径结构已变更**，这是 r56p0 的其中一项重构：

- r49p1 的 UAPI 头位于 `drivers/gpu/arm/midgard/include/uapi/` **内部**
- r56p0 的 UAPI 头被提升到内核树顶层 `include/uapi/`，与 `drivers/gpu/arm/midgard/` 平级

这符合上游 Linux 的 out-of-tree → in-tree 化惯例（`Documentation/ABI/testing/sysfs-device-mali` 的出现佐证了这点，见本文件 KB-030）。

### 0.1 UK ABI 版本（实证）

| | r49p1 | r56p0 |
| --- | --- | --- |
| 文件 | `include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_ioctl.h` | 同左 |
| MAJOR | **1**（行 121） | **1**（行 148） |
| MINOR | **30**（行 122） | **39**（行 148-149） |

> 源码原文
> r49p1:122 `#define BASE_UK_VERSION_MINOR 30`
> r56p0:149 `#define BASE_UK_VERSION_MINOR 39`

**跨 9 个 minor 版本**（1.31–1.39），不是"几个小版本"。MAJOR 未变，意味着协商机制不拒绝对方，只在 minor 上取最小值。

---

## 1. 版本协商机制（两个版本完全相同）

`kbase_api_handshake()` 的两版实现**逐字符一致**，仅行号不同：

| | 文件 | 行号 |
| --- | --- | --- |
| r49p1 | `drivers/gpu/arm/midgard/mali_kbase_core_linux.c` | 461–494 |
| r56p0 | 同左 | 357–390 |

```c
switch (version->major) {
case BASE_UK_VERSION_MAJOR:
    /* set minor to be the lowest common */
    version->minor = min_t(int, BASE_UK_VERSION_MINOR, (int)version->minor);
    break;
default:
    version->major = BASE_UK_VERSION_MAJOR;
    version->minor = BASE_UK_VERSION_MINOR;
    break;
}
```

**行为推论（实证级）**：

- 1.30 用户态 ↔ 1.39 内核 → 协商结果 **1.30**，内核需按 1.30 语义服务
- 1.39 用户态 ↔ 1.30 内核 → 协商结果 **1.30**，用户态需自行降级
- 协商本身**不会失败**，不会拒绝连接

⚠️ 但协商成功 ≠ 功能兼容。内核保存的 `api_version` 只用于少数分支判断，**不会自动转换已变更的结构体布局**。这是本审计中多处 P0/P1 的根源：协商通过，数据错位。

---

## 2. ioctl 命令表全量比对

### 2.1 统计

| | r49p1 | r56p0 |
| --- | ---: | ---: |
| ioctl 定义总数 | **58** | **52** |
| 仅 r49p1 有（被删） | — | 8 |
| 仅 r56p0 有（新增） | 2 | — |
| 共有但编号变化 | — | 1 |

> 统计口径：`#define KBASE_IOCTL_* _IOWR/_IOW/_IOR/_IO(KBASE_IOCTL_TYPE, nr, ...)`，已处理 `\` 续行。`_IO()` 双参数形式（GWT_START/STOP）单独纳入。

### 2.2 被删除的 8 条

| 编号 | 名称 | r49p1 位置 | 类型 | ABI | MTK | 严重度 |
| ---: | --- | --- | :--: | :--: | :--: | :--: |
| 80 | `KBASE_IOCTL_INTERNAL_FENCE_WAIT` | `mali_kbase_ioctl.h:662` | 删除 | **破坏** | **是** | **P0** |
| 55 | `KBASE_IOCTL_SET_LIMITED_CORE_COUNT` | `mali_kbase_ioctl.h:592` | 删除 | **破坏** | 间接 | **P1** |
| 33 | `KBASE_IOCTL_CINSTR_GWT_START` | `mali_kbase_ioctl.h:493` | 删除 | 破坏 | 否 | P1 |
| 34 | `KBASE_IOCTL_CINSTR_GWT_STOP` | `mali_kbase_ioctl.h:495` | 删除 | 破坏 | 否 | P1 |
| 35 | `KBASE_IOCTL_CINSTR_GWT_DUMP` | `mali_kbase_ioctl.h:528` | 删除 | 破坏 | 否 | P1 |
| 32 | `KBASE_IOCTL_HWCNT_SET` | `mali_kbase_ioctl.h:180` | 删除 | 破坏 | 是 | P2 |
| 8 | `KBASE_IOCTL_HWCNT_READER_SETUP` | `mali_kbase_ioctl.h:165` | 删除 | 破坏 | 是 | P2 |
| 12 | `KBASE_IOCTL_DISJOINT_QUERY` | `mali_kbase_ioctl.h:190` | 删除 | 破坏 | 否 | P3 |

### 2.3 新增的 2 条

| 编号 | 名称 | r56p0 位置 | 说明 |
| ---: | --- | --- | --- |
| 58 | `KBASE_IOCTL_CS_QUEUE_GROUP_CREATE_1_35` | `csf/mali_kbase_csf_ioctl.h:430` | 兼容槽位，与 `_1_18` 共用 58，靠 `_IOC_SIZE` 区分 |
| 62 | `KBASE_IOCTL_CS_TILER_HEAP_SIZE` | `csf/mali_kbase_csf_ioctl.h:727` | 查询 tiler heap 尺寸，全新接口 |

> **编号 58 并非"重复定义冲突"**。`_IOWR(type, nr, size)` 的 `size` 参与 command 编码，因此 `_1_18`（32 B）与 `_1_35`（112 B）产生不同的 command 值，可在 switch 中并存。这是 ARM 的版本分派惯例。同理 48 号（`cs_tiler_heap_init` / `_1_13`）。

---

## KB-001 — UK ABI 版本 1.30 → 1.39

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-001 |
| **r49p1** | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_ioctl.h:121-122` |
| **r56p0** | `include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_ioctl.h:148-149` |
| **代码差异** | `BASE_UK_VERSION_MINOR 30` → `39`；MAJOR 均为 1 |
| **差异类型** | 修改 |
| **影响 ABI** | 是（协商结果变化，但机制不变） |
| **影响 MTK** | 否（MTK 平台层不读此宏） |
| **严重程度** | **P2** |
| **证据等级** | **实证** |

**说明**：跨 9 个 minor。因协商取 `min()`，1.30 用户态连 1.39 内核会得到 1.30 的承诺。风险不在协商本身，而在于内核是否真的对所有 1.30 语义做了分支兼容——下文 KB-004 证明至少有一处没做到。

---

## KB-002 — `base_mem_handle` 结构体被彻底删除，全部改为裸 `gpu_va`

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-002 |
| **r49p1** | `include/uapi/gpu/arm/midgard/mali_base_common_kernel.h:27-31` |
| **r56p0** | 该结构体**不存在**（全 UAPI 目录 grep `base_mem_handle` 零命中） |
| **差异类型** | 重构（类型删除 + 语义替换） |
| **影响 ABI** | **是**（字段名与语义变更，大小不变） |
| **影响 MTK** | **是** |
| **严重程度** | **P0** |
| **证据等级** | **实证** |

**r49p1 原文**（`mali_base_common_kernel.h:27-31`）：

```c
struct base_mem_handle {
	struct {
		__u64 handle;
	} basep;
};
```

**r56p0 对应位置**：无此类型。所有原使用点改为裸 `__u64 gpu_va`。

**受影响的结构体（全部实测）**：

| 结构体 | r49p1 定义 | r56p0 定义 | 大小 |
| --- | --- | --- | --- |
| `basep_syncset` | `mali_base_mem_priv.h:49-55`，`struct base_mem_handle mem_handle` | `:53-59`，`__u64 gpu_va` | 32 → 32 |
| `base_mem_aliasing_info` | `mali_base_kernel.h:186-190`，`struct base_mem_handle handle` | `:192`，`__u64 gpu_va` | 24 → 24 |
| `kbase_ioctl_mem_sync` | `mali_kbase_ioctl.h:248-254`，`__u64 handle` | `:199`，`__u64 gpu_va` | 32 → 32 |

**为什么是 P0 而不是"改名而已"**：

`handle` 与 `gpu_va` 是**两种不同的寻址语义**：

- `handle`：内核分配的 opaque 标识符，由 `kbase_ioctl_mem_alloc` 返回，用户态回传时内核在 `kctx->regions` 中查找
- `gpu_va`：GPU 虚拟地址，用户态可直接构造（如 aliasing 时指向已有 VA 区间）

两者虽同为 `__u64`、大小一致，**结构体 sizeof 不变**，因此 `copy_from_user` 不会报错、`_IOC_SIZE` 校验通过、handshake 也不拦。但内核把它当 VA 用而用户态按 handle 填，或反之，会产生**静默的地址解析错误**——映射到错误的物理页，或返回 `-EINVAL` 而用户态无从判断原因。

这类差异不会在 dmesg 里留下明显痕迹，是本次审计中最难定位的一类。**必须在移植时同步替换用户态**，不能靠"大小一样"蒙混。

---

## KB-003 — `CS_QUEUE_GROUP_CREATE` 编号 58 → 63，结构体 112 → 120 字节

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-003 |
| **r49p1** | `csf/mali_kbase_csf_ioctl.h:367`（union 定义）、`:396`（ioctl 编号 58） |
| **r56p0** | `csf/mali_kbase_csf_ioctl.h:767`（主版 union）、`:795`（主版编号 63）、`:342`（`_1_18` union）、`:367`（`_1_18` 编号 58）、`:404`（`_1_35` union）、`:430`（`_1_35` 编号 58） |
| **差异类型** | 重构 + 新增（结构体扩容 + 编号迁移 + 保留旧槽位） |
| **影响 ABI** | **是** |
| **影响 MTK** | **是**（MTK 的 CSG 调度依赖此接口） |
| **严重程度** | **P0** |
| **证据等级** | **实证** |

### 结构差异

r49p1（58 号，`in` 部分 112 B）：

```c
struct {
    __u64 tiler_mask; __u64 fragment_mask; __u64 compute_mask;   // 24
    __u8 cs_min; __u8 priority; __u8 tiler_max;
    __u8 fragment_max; __u8 compute_max; __u8 csi_handlers;
    __u8 reserved;                                               // ← 后被复用
    __u8 cs_fault_report_enable;                                 // 32
    __u64 dvs_buf;                                               // 40
    __u64 padding[9];                                            // 40..112
} in;
```

r56p0 主版（63 号，`in` 部分 120 B）：

```c
struct {
    __u64 tiler_mask; __u64 fragment_mask; __u64 compute_mask;   // 24
    __u8 cs_min; __u8 priority; __u8 tiler_max;
    __u8 fragment_max; __u8 compute_max; __u8 csi_handlers;
    __u8 neural_max;              // ← 复用了 r49p1 的 reserved 字节
    __u8 cs_fault_report_enable;
    __u64 dvs_buf;                                               // 40
    __u64 neural_mask;                                           // 48  ← 新
    __u8 comp_pri_threshold; __u8 comp_pri_ratio;                // 50  ← 新
    __u8 padding[58];                                            // 52..110
    __u32 fragment_endpoint_task_limit;                          // 110 ← 新
    __u64 reserved;                                              // 112 ← 新
} in;                                                            // 120
```

| 字段 | r49p1 | r56p0 主版 | 性质 |
| --- | --- | --- | --- |
| `reserved`（偏移 30） | 1 B，必须为 0 | → `neural_max` | **复用** |
| `neural_mask`（偏移 40） | 在 `padding[9]` 内 | 新增 8 B | 新增 |
| `comp_pri_threshold` / `comp_pri_ratio`（48-49） | 在 padding 内 | 新增 2 B | 新增 |
| `fragment_endpoint_task_limit`（110） | 不存在 | 新增 4 B | 新增 |
| `reserved`（112） | 不存在 | 新增 8 B | 新增 |
| **合计** | **112 B** | **120 B** | **+8** |

### 兼容路径

r56p0 保留两个 58 号槽位，靠 `_IOC_SIZE` 区分：

| 宏 | 编号 | size | 推测对应用户态 |
| --- | ---: | ---: | --- |
| `..._CREATE_1_6` | 42 | — | UK ≤ 1.6 |
| `..._CREATE_1_18` | 58 | 32 B | UK ≤ 1.18 |
| `..._CREATE_1_35` | 58 | **112 B** | UK 1.19–1.35 |
| `..._CREATE`（主版） | **63** | 120 B | UK ≥ 1.36 |

**r49p1（1.30）用户态发出 58/112 B，其 command 值与 r56p0 的 `_1_35` 完全一致**，会进入 `kbasep_cs_queue_group_create_1_35()`（`mali_kbase_core_linux.c:1446-1474`）。

前 40 字节布局两版**完全一致**（含 `cs_fault_report_enable` 均在偏移 31），差异只在 40 字节之后——而 r49p1 那一段是 `padding[9]` 且要求填 0。因此**老用户态进来的新字段全为 0**，等价于"关闭 neural、comp_pri=0"。

→ 结论：**该路径在数据层面大致兼容**，但见 KB-004。

---

## KB-004 — 1.35 兼容路径遗漏 `cs_fault_report_enable`，导致 CS_FAULT 上报静默失效

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-004 |
| **r49p1** | `csf/mali_kbase_csf.c:1305`（`group->cs_fault_report_enable = create->in.cs_fault_report_enable;`） |
| **r56p0** | `mali_kbase_core_linux.c:1446-1474`（`kbasep_cs_queue_group_create_1_35` 的字段搬运表） |
| **差异类型** | 修改（兼容层字段丢失） |
| **影响 ABI** | 是（行为级，非布局级） |
| **影响 MTK** | **是**（MTK whitebox 故障处理依赖 CS_FAULT） |
| **严重程度** | **P1** |
| **证据等级** | **实证** |

**r56p0 原文**（`mali_kbase_core_linux.c:1448-1466`，节选）：

```c
union kbase_ioctl_cs_queue_group_create
    new_create = { .in = {
                   .tiler_mask = create->in.tiler_mask,
                   .fragment_mask = create->in.fragment_mask,
                   .compute_mask = create->in.compute_mask,
                   .cs_min = create->in.cs_min,
                   .priority = create->in.priority,
                   .tiler_max = create->in.tiler_max,
                   .fragment_max = create->in.fragment_max,
                   .compute_max = create->in.compute_max,
                   .csi_handlers = create->in.csi_handlers,
                   .dvs_buf = create->in.dvs_buf,
                   .neural_mask = create->in.neural_mask,
                   .comp_pri_threshold = create->in.comp_pri_threshold,
                   .comp_pri_ratio = create->in.comp_pri_ratio,
               } };
```

**注意缺失的两项**：`cs_fault_report_enable` 与 `neural_max`。

由于是 designated initializer（`{ .in = {...} }`），未列出的成员**自动初始化为 0**。

**下游仍然使用该字段**（实证，r56p0 内部）：

- `csf/mali_kbase_csf.c:1324` — `group->cs_fault_report_enable = create->in.cs_fault_report_enable;`
- `csf/mali_kbase_csf.c:2808` — `if (group->cs_fault_report_enable && queue->clear_faults)`

**后果**：r49p1 用户态若置 `cs_fault_report_enable = 1`（Mali DDK 在某些容错配置下会这么做），经 1.35 路径进入 r56p0 内核后该标志恒为 0 → `kbase_csf.c:2808` 的 CS_FAULT 上报分支永假 → **故障不再上报给用户态**。

**为什么是 P1 而非 P0**：不崩溃、不报错、驱动正常工作，只是容错能力下降。但 MTK 的 `mtk_platform_whitebox_fault_worker.c` / `mtk_platform_qinspect_recovery.c` 依赖 fault 事件做恢复决策，功能缺失会让这些机制失效。**这是"能用但纠错能力退化"的典型形态**。

> ⚠️ 争议点：也可能 ARM 有意废弃该字段（`_1_35` 之后的用户态改走 63 号新版，那里有完整搬运）。但 63 号路径的 `kbasep_cs_queue_group_create()`（`:1476-1479`）是直接透传整个 union，`cs_fault_report_enable` 会正常保留。所以只有走 58/112 的**老用户态**受损。
> 判定：**实证差异成立**，ARM 意图**UNKNOWN**。

---

## KB-005 — 队列错误载荷 16 → 32 字节（新增 trace 三元组）

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-005 |
| **r49p1** | `csf/mali_base_csf_kernel.h:481-486`（fatal）、`:500`（fault） |
| **r56p0** | `csf/mali_base_csf_kernel.h:433-447`（fatal）、`:468`（fault） |
| **差异类型** | 新增（字段扩展） |
| **影响 ABI** | **是**（sizeof 翻倍） |
| **影响 MTK** | 是（MTK dump 逻辑读这些字段） |
| **严重程度** | **P1** |
| **证据等级** | **实证** |

**r49p1**（`:481-486`）：

```c
struct base_gpu_queue_error_fatal_payload {
	__u64 sideband;
	__u32 status;
	__u8 csi_index;
	__u8 padding[3];
};                                    // sizeof = 16
```

**r56p0**（`:433-447`）：

```c
struct base_gpu_queue_error_fatal_payload {
	__u64 sideband;
	__u32 status;
	__u8 csi_index;
	__u8 padding[6];
	__u8 has_extra;      // 0x1 = trace 数据有效
	__u32 trace_id0;
	__u32 trace_id1;
	__u32 trace_task;
};                                    // sizeof = 32
```

`fault_payload` 做同样扩展，同为 16 → 32。

**新增语义**：`has_extra` 是显式有效性标志，`trace_id0/1` + `trace_task` 是与固件异常追踪（EXCEPTION_TRACE）的对接字段。

---

## KB-006 — `base_csf_notification` 总大小不变（64 B），但内部错误结构 24 → 40 B

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-006 |
| **r49p1** | `csf/mali_base_csf_kernel.h:609-625`；`base_gpu_queue_group_error` 在 `:546-554` |
| **r56p0** | `csf/mali_base_csf_kernel.h:557-570`；`base_gpu_queue_group_error` 在 `:515-523` |
| **差异类型** | 修改（内部布局变化，外部大小不变） |
| **影响 ABI** | **是**（隐性） |
| **影响 MTK** | **是** |
| **严重程度** | **P1** |
| **证据等级** | **实证** |

| 层级 | r49p1 | r56p0 | 变化 |
| --- | ---: | ---: | --- |
| `base_gpu_queue_error_fatal_payload` | 16 | 32 | +16 |
| `base_gpu_queue_group_error_fatal_payload` | 16 | 16 | 不变（`__u32 padding` → `__u8 padding[20]`，仍 16） |
| union 成员最大值 | 16 | 32 | +16 |
| `base_gpu_queue_group_error` | **24** | **40** | **+16** |
| `base_csf_notification.payload.csg_error` | 8+24 = 32 | 8+40 = 48 | +16 |
| `base_csf_notification.payload` union（含 `align[56]`） | max(32,56)=56 | max(48,56)=56 | **不变** |
| **`base_csf_notification`** | **64** | **64** | **不变** |

**这是本审计中最隐蔽的一处**：`sizeof` 完全相同，`copy_to_user` 不报错，用户态缓冲区不溢出。但 `csg_error.error.payload` 的**内部解释方式不同**——r56p0 内核写入 32 字节的 trace 数据，r49p1 用户态按 16 字节读取。

后果：用户态读到的 `error.payload.fatal_queue` 字段值正确（前 16 字节布局一致），但**看不到 trace 数据**；若用户态做 `memcmp` 或按旧结构 dump 整块，会把 trace 区当垃圾数据打印。

`align[56]` 的注释明确写着 "To fit the struct into a 64-byte cache line"，说明 56 是**硬约束**——这也解释了为什么 `group_error` 涨到 40 仍在 48 < 56 之内，没触发扩容。**再涨 8 字节就会溢出**，这是该设计的脆弱点。

---

## KB-007 — `gpu_props_user_data` 568 → 592 字节（GET_GPUPROPS 返回体扩容）

> ⚠️ **本节的两个数字是 `sizeof(struct)` 的人工推算，不是内核实际校验的量（2026-11-16 更正，`D-032`）**。
>
> `GET_GPUPROPS` 的校验对象是 `kbdev->gpu_props.prop_buffer_size` —— 即 **TLV 序列化流的总长度**，由 `Σ(4 + sizeof(value))` 逐属性累加得出，与结构体 padding 无关。
> 独立复算：**R49 = 749 B / R56 = 781 B（+32）**，属性 **83 项共同 + 3 项新增**（`RAW_BASE_PRESENT`=86 / `RAW_NEURAL_PRESENT`=87 / `NUM_ACTIVE_GRANULARITY`=88，无删除）。
> 判定规则本身不变（`size == 0` 探测返回所需长度；`size < prop_buffer_size` 才 `-EINVAL`），故**下文"越界 24 字节"的推演不成立**——拷贝长度是 `prop_buffer_size`，不是 `sizeof(struct)`。**本节保留原文以留痕**（`AGENTS.md` §0.7）。
> 现行结论见 `06_porting_design/STAGE4_REMAINING_AUDIT.md` §2 N-2。

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-007 |
| **r49p1** | `include/uapi/gpu/arm/midgard/mali_gpu_props.h:44-101` |
| **r56p0** | `include/uapi/gpu/arm/midgard/mali_gpu_props.h:50-114` |
| **差异类型** | 新增（字段扩展 + 显式 padding 插入） |
| **影响 ABI** | **是**（+24 B） |
| **影响 MTK** | **是** |
| **严重程度** | **P0** |
| **证据等级** | **实证**（字段逐项比对）+ **推断**（sizeof 为按 ARM64 LP64 规则手工推算，未编译验证） |

### 逐层大小（ARM64 / LP64，无 `__packed`、无 `aligned` 属性——已 grep 确认为 0 处）

| 子结构 | r49p1 | r56p0 | 变化原因 |
| --- | ---: | ---: | --- |
| `core_props` | 56 | 56 | 新增 `unused0[2]`、`unused1[4]` 补齐，总大小不变 |
| `l2_props` | 3 | 3 | 不变 |
| `tiler_props` | 8 | 8 | 不变 |
| `thread_props` | **24** | **28** | 新增 `num_active_granularity`(4) |
| `raw_props` | **200** | **216** | 新增 `base_present`(8)、`neural_present`(8) |
| `coherency_info` | 268 | 272 | 新增 `unused6[4]` |
| **总计** | **568** | **592** | **+24** |

### 字段级差异

```c
/* thread_props */
r49p1: max_threads, max_workgroup_size, max_barrier_size, max_registers,
       max_task_queue, max_thread_group_split, impl_tech, tls_alloc
r56p0: max_threads, max_workgroup_size, num_active_granularity,  ← 新
       max_barrier_size, max_registers, max_task_queue,
       max_thread_group_split, impl_tech, unused5, tls_alloc

/* raw_props 尾部 */
r49p1: ... thread_tls_alloc, gpu_features;
r56p0: ... thread_tls_alloc, gpu_features, base_present, neural_present;  ← 新
```

**`base_present` / `neural_present` 的含义**：位掩码，分别表示 BASE（tiler/几何）与 NEURAL（机器学习加速）硬件单元的 presence。这是 r56 代新增的 GPU 能力位图，G925 上应当非零（详见 `05_g925_hardware_support.md`）。

**为什么 P0**：`GET_GPUPROPS` 是用户态 init 阶段必经调用，返回体被写入用户态**固定大小**缓冲区。若用户态按 568 字节分配而内核写 592 字节 → **内核栈/用户缓冲区越界 24 字节**。kbase 的实现通常是 `copy_to_user(&user_props, &kbdev->gpu_props.props, sizeof(kbdev->gpu_props.props))`，即按**内核侧 sizeof** 拷贝，用户态缓冲区不够就写穿。

反之，568 字节用户态缓冲区配 r56p0 内核 → 覆写相邻用户态内存，可能踩坏堆上的其他对象。这类问题的表现是随机崩溃，极难归因。

> **验证方法（未执行，因禁止编译）**：`_Static_assert(sizeof(struct gpu_props_user_data) == 568, ...)`。建议在移植前用独立编译单元单独 include 两个版本的 UAPI 头做 `sizeof` 对拍——这不涉及编译驱动本身。

---

## KB-008 — MTK 私有 ioctl 80（`INTERNAL_FENCE_WAIT`）在 r56p0 中不存在

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-008 |
| **r49p1** | `mali_kbase_ioctl.h:655-663`（结构体）、`:662`（编号 80）；处理函数 `mali_kbase_core_linux.c:1828-1876`；分发 `:2264`；flag 定义 `mali_base_kernel.h:638-640` |
| **r56p0** | 全树零命中（`INTERNAL_FENCE_WAIT` / `internal_fence_wait`） |
| **差异类型** | 删除 |
| **影响 ABI** | **是** |
| **影响 MTK** | **是**（这是 MTK 在 UAPI 中的直接注入） |
| **严重程度** | **P0** |
| **证据等级** | **实证** |

**r49p1 私有 flag 定义**（`mali_base_kernel.h:638-640`）：

```c
#define BASE_INTERNAL_FENCE_WAIT_IDLE_FLAG  (1UL << 0)
#define BASE_INTERNAL_FENCE_WAIT_RESULT_FLAG (1UL << 1)
#define BASE_INTERNAL_FENCE_WAIT_DUMP_FLAG  (1UL << 31)
```

**r49p1 实现**（`mali_kbase_core_linux.c:1828` 起），在 `csf/mali_kbase_csf_reset_gpu.c:832` 还有一份对应的字符串表项 `"kbasep_ioctl_internal_fence_wait"`。

**性质判定**：这不是 ARM 原版接口。证据有三：

1. 命名前缀 `INTERNAL_` 且编号 80 远离 ARM 连续占用区（ARM 用到 63）
2. 依赖 `BASE_INTERNAL_FENCE_WAIT_DUMP_FLAG`——`DUMP` 语义对应 MTK 的 whitebox 故障转储，ARM 原版无此机制
3. r56p0 作为同代上游完全没有该接口

**对移植的影响**：MTK 的用户态组件（`libGLES_mali.so` 的 MTK 定制版、或 MTK 的 GPU 调试工具）若调用此 ioctl 做 fence 等待 + 故障转储，换 r56p0 后内核返回 `-ENOTTY`。**必须在 r56p0 上重新实现该接口**，且其依赖的 `csf_reset_gpu` 内部钩子（`mali_kbase_csf_reset_gpu.c:832` 附近）在 r56p0 中结构已变（该文件 1176 → 686 行，见 `02_csf_architecture_diff.md` KB-020）。

---

## KB-009 — `MTK_DEBUG_DUMP` 条件字段从 `base_csf_notification` 中移除

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-009 |
| **r49p1** | `csf/mali_base_csf_kernel.h:618-620` |
| **r56p0** | `csf/mali_base_csf_kernel.h:557-570`（无此分支） |
| **差异类型** | 删除 |
| **影响 ABI** | **是**（条件编译下的布局差异） |
| **影响 MTK** | **是** |
| **严重程度** | **P1** |
| **证据等级** | **实证** |

**r49p1 原文**：

```c
union {
    struct {
        __u8 handle;
        __u8 padding[7];
        struct base_gpu_queue_group_error error;
    } csg_error;                              // 8 + 24 = 32
#if IS_ENABLED(CONFIG_MALI_MTK_DEBUG_DUMP)
    struct {
        __u8 cmd;
    } dump;                                   // 1，但被 align[56] 吸收
#endif
    __u8 align[56];
} payload;
```

**这是 MTK 向 ARM UAPI 注入的第二处**（第一处是 KB-008 的 ioctl 80，第三处是 KB-010 的 core_count）。

因为 `dump` 只有 1 字节，被 `align[56]` 完全吸收，**sizeof 不受影响**。所以：

- r56p0 内核不会因缺少该字段而写越界
- 但 MTK 若开启 `CONFIG_MALI_MTK_DEBUG_DUMP`，其内核代码中对该 `dump.cmd` 的读写点会**编译失败**（成员不存在）

→ 移植时必须重写这部分 MTK 调试通路，无法直接搬运。

---

## KB-010 — `SET_LIMITED_CORE_COUNT`（55 号）被删除

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-010 |
| **r49p1** | `mali_kbase_ioctl.h:585-593`（结构体 `kbase_ioctl_set_limited_core_count`，1 B）；实现 `mali_kbase_core_linux.c:1803-1826`；分发 `:2258-2262` |
| **r56p0** | 全树零命中 |
| **差异类型** | 删除 |
| **影响 ABI** | **是** |
| **影响 MTK** | **间接**（MTK 平台层未直接调用，见下） |
| **严重程度** | **P1** |
| **证据等级** | **实证** |

**r49p1 实现**（`mali_kbase_core_linux.c:1803` 起）：

```c
static int kbasep_ioctl_set_limited_core_count(
    struct kbase_context *kctx,
    struct kbase_ioctl_set_limited_core_count *set_limited_core_count)
{
    const u8 max_core_count = set_limited_core_count->max_core_count;
    ...
```

**MTK 使用情况（已全树检索）**：`mali-r49p1` 内除 ARM 自身实现外，**无 MTK 代码调用**该 ioctl。MTK 的 core mask 控制走另一条路径：

- `mtk_set_core_mask()` → 注册为 `ged_dvfs_set_gpu_core_mask_fp` → GED 回调
- 见 `gpu_dependency_map.md` §4.2 的函数指针注入链

**所以 MTK 内核侧不受影响**。但**用户态**（Mali DDK 的省电策略）可能使用该 ioctl 做动态核心裁剪——G925 MC12 有 12 个核心，关核省电是常见策略。若用户态依赖此接口，换 r56p0 后失效。

> **UNKNOWN 项**：无法确认 K80U 的 `libGLES_mali.so` 是否调用 55 号 ioctl。该二进制不在已获取仓库中（见 `01_original_baseline/source_integrity.md` M1）。

---

## KB-011 — `HWCNT_SET` / `HWCNT_READER_SETUP` 被删除，HWCNT 接口整体重构

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-011 |
| **r49p1** | `mali_kbase_ioctl.h:165`（`HWCNT_READER_SETUP`，8 号）、`:180`（`HWCNT_SET`，32 号）；`mali_kbase_hwcnt_reader.h` 三个结构体（36/38/46 行） |
| **r56p0** | 均删除；新增 `MID/mali_kbase_hwcnt_trace.h` |
| **差异类型** | 删除 + 重构 |
| **影响 ABI** | **是** |
| **影响 MTK** | **是**（MTK 有 `mtk_mfg_counter.c` 做 GPU 计数器采集） |
| **严重程度** | **P2** |
| **证据等级** | **实证** |

被删的三个用户态结构体：

- `kbase_hwcnt_reader_metadata_cycles`（r49p1:57，16 B）
- `kbase_hwcnt_reader_metadata`（r49p1:69，32 B）
- `kbase_hwcnt_reader_api_version`（r49p1:101，8 B）

**MTK 侧影响**：`mtk_platform_common/mtk_mfg_counter.c` + `mtk_platform_upf_counter.c` 通过 kbase 内部 API（非 ioctl）读取计数器，不一定受 UAPI 变更影响。但 r56p0 的 HWCNT 后端从 2280 行涨到 3320 行（见 KB-021），内部结构变动较大，MTK 的采集代码需要重新对接。

降为 P2 的理由：hwcnt 是**性能监控功能**，不影响渲染正确性；且 MTK 走内核内部路径，不走 UAPI。

---

## KB-012 — `DISJOINT_QUERY`（12 号）被删除

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-012 |
| **r49p1** | `mali_kbase_ioctl.h:186-192` |
| **r56p0** | 零命中 |
| **差异类型** | 删除 |
| **影响 ABI** | 是 |
| **影响 MTK** | 否 |
| **严重程度** | **P3** |
| **证据等级** | **实证** |

`struct kbase_ioctl_disjoint_query { __u32 counter; }`，4 字节。该接口在 ARM 侧长期废弃（JM 时代遗留），CSF 架构下无意义。**无实际影响**。

---

## KB-013 — 新增 `CS_TILER_HEAP_SIZE`（62 号）

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-013 |
| **r49p1** | 不存在 |
| **r56p0** | `csf/mali_kbase_csf_ioctl.h:727` |
| **差异类型** | 新增 |
| **影响 ABI** | 是（新增，向后兼容） |
| **影响 MTK** | 否 |
| **严重程度** | **P2** |
| **证据等级** | **实证** |

新增接口，老用户态不会调用，无兼容风险。但它暗示 r56p0 的 tiler heap 管理有变化——用户态需要主动查询尺寸，可能与 r49p1 的固定尺寸假设不同。

---

## KB-014 — `base_fence` 更名为 `kbase_fence`

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-014 |
| **r49p1** | `mali_base_kernel.h:158`（`struct base_fence`，8 B） |
| **r56p0** | `mali_base_kernel.h:165`（`struct kbase_fence`，8 B） |
| **差异类型** | 重构（改名） |
| **影响 ABI** | 否（布局相同，仅类型名） |
| **影响 MTK** | 否 |
| **严重程度** | **P3** |
| **证据等级** | **实证** |

纯命名规范化，`base_` → `kbase_` 前缀统一。源码级需要改标识符，二进制无影响。

---

## KB-030 — UAPI 目录内联化 + 官方 ABI / DT 文档随包发布（形态变更，非功能差异）

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-030 |
| **r49p1** | 无 `Documentation/` 目录（`find -type d -name Documentation` **零命中**） |
| **r56p0** | `Documentation/` 共 10 个文件：`ABI/testing/sysfs-device-mali`（239 行）、`ABI/testing/sysfs-device-mali-coresight-source`、`csf_sync_state_dump.rst`、`ioctl-categories.rst`（93 行）、`devicetree/bindings/arm/arm,mali-midgard.yaml`（237 行）、`arm,physical-memory-group-manager.yaml`、`arm,priority-control-manager.yaml`、`arm,protected-memory-allocator.yaml`、`arm,coresight-mali-source.yaml`、`devicetree/bindings/power/arm,mali-operating-points.yaml` |
| **差异类型** | 新增 |
| **影响 ABI** | 否。文档不参与构建；`sysfs-device-mali` 描述的是**既有** sysfs 节点（`core_mask`、`debug_command` 等），不是新 ABI |
| **影响 MTK** | 间接。`arm,mali-midgard.yaml:206` 为 `unevaluatedProperties: true`，即 MTK 私有 DT 属性不会被 schema 判错，`sleep-mode-enable` 一类可继续保留 |
| **严重程度** | **P3** |
| **证据等级** | **实证**（文件存在与行数）；**推断**（对 MTK DT 的影响） |

意义有两点：

1. **交付形态从 out-of-tree 转向 in-tree**。r56p0 把 UAPI 头提升到内核树顶层 `include/uapi/gpu/arm/midgard/`（见 §0），并补齐 ABI 文档与 DT binding。这不是代码行为差异，但说明 R56p0 面向**其发布时的** Android 16 时代 / GKI 6.6+ 的 in-tree 集成方式——移植时目录布局不能照搬 r49p1。（2026-11-15 加"其发布时的"限定：本机设备实际为 Android 17，此处描述的是 R56p0 的交付代次，不是本机系统版本。）
2. **DT binding 从"MTK 自由发挥"变成"官方有约束"**。`compatible` 必须以 `arm,malit6xx` / `arm,mali-midgard` / `arm,mali-bifrost` 之一结尾（`arm,mali-midgard.yaml:44-46`），必需属性为 `compatible` / `reg` / `interrupts` / `interrupt-names`（`:190`）。K80U 现有 mali 节点的 `compatible` 是否满足此约束，属 DTS 范畴，交 `04_mtk_platform/` 核对。

> **证据折价（重要）**：`Documentation/devicetree/bindings/` 下 5 个 yaml 含 10 处非源码文本残留（形如 `:contentReference[oaicite:N]{index=N}`），说明这几个文件是**按网页文本重建**，而非取自官方归档。因此本条只把"文件存在"作为实证，**不把 yaml 正文当依据**。同项检查在 `drivers/`、`include/` 全树为零残留。详见 `MANIFEST.md` §5。

---

## 3. 结构体布局总表

> 大小为 ARM64 LP64 严格推算，无 `__packed`（已 grep 确认）。标 ⚠️ 者为人工推算未编译验证。

| 结构体 | r49p1 | r56p0 | Δ | ABI | ID |
| --- | ---: | ---: | ---: | :--: | --- |
| `base_mem_handle` | 8 | **不存在** | −8 | 语义破坏 | KB-002 |
| `basep_syncset` | 32 | 32 | 0 | 语义破坏 | KB-002 |
| `base_mem_aliasing_info` | 24 | 24 | 0 | 语义破坏 | KB-002 |
| `kbase_ioctl_mem_sync` | 32 | 32 | 0 | 语义破坏 | KB-002 |
| `kbase_ioctl_cs_queue_group_create.in` | 112 | **120** | +8 | 破坏（但保留 112 兼容槽） | KB-003 |
| `base_gpu_queue_error_fatal_payload` | 16 | **32** | +16 | 破坏 | KB-005 |
| `base_gpu_queue_error_fault_payload` | 16 | **32** | +16 | 破坏 | KB-005 |
| `base_gpu_queue_group_error_fatal_payload` | 16 | 16 | 0 | 内部布局变 | KB-005 |
| `base_gpu_queue_group_error` | 24 | **40** | +16 | 破坏（内部） | KB-006 |
| `base_csf_notification` | 64 | 64 | 0 | 隐蔽破坏 | KB-006 |
| `gpu_props_user_data` ⚠️ | **568** | **592** | +24 | **破坏** | KB-007 |
| `gpu_raw_gpu_props` ⚠️ | 200 | 216 | +16 | 破坏 | KB-007 |
| `mali_base_gpu_thread_props` | 24 | 32 | +8 | 破坏 | KB-007 |
| `kbase_ioctl_set_limited_core_count` | 1 | **不存在** | −1 | 破坏 | KB-010 |
| `kbase_hwcnt_reader_metadata` | 32 | **不存在** | — | 破坏 | KB-011 |
| `base_fence` → `kbase_fence` | 8 | 8 | 0 | 否 | KB-014 |

**合计**：84 个共有结构体中，**10 个字段布局变化**；10 个 r49p1 结构体被删；1 个新增。

---

## 4. ioctl 编号占用与移植余量

r56p0 已占用编号（含多版本共用）：

```
0 1 3 5 6 7 13 14 15 16 17 18 19 20 21 22 23 24 25 27 29 30 31
36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 56 57 58 59 60 61 62 63
```

**空闲且 ARM 短期内不会占用的号**：`2, 4, 8–12, 26, 28, 32–35, 55, 64–89`

关键判断：

- **80 号在 r56p0 中空闲** → MTK 的 `INTERNAL_FENCE_WAIT` **可以原样搬回 80 号**，无需改号
- 55 号也空闲 → 若需恢复 `SET_LIMITED_CORE_COUNT` 语义，有位置
- 但 32/33/34/35 虽空闲，**不要复用**——它们是 ARM 已废弃的号，未来可能复用，冲突风险

→ 移植时 MTK 私有 ioctl 建议使用 **64 以上**的号段，彻底避开 ARM 的未来扩张。

---

## 5. 本文件的结论

1. **UK ABI 从 1.30 跨到 1.39，9 个 minor。协商机制不变（`min_t`），所以握手永远成功——但握手成功不代表能用。**

2. **三处 P0 破坏性变更**：
   - `base_mem_handle` 删除 → `gpu_va`（大小不变，语义变，最难排查）
   - `CS_QUEUE_GROUP_CREATE` 编号 58→63、结构 112→120（但保留 58/112 兼容槽，老用户态数据层面可行）
   - `gpu_props_user_data` 568→592（GET_GPUPROPS 必然经过，越界风险）

3. **两处 MTK 注入被清除**：ioctl 80（`INTERNAL_FENCE_WAIT`）和 `CONFIG_MALI_MTK_DEBUG_DUMP` 的 `dump.cmd` 字段。二者都必须重新实现。

4. **一处隐蔽的兼容层缺陷（KB-004）**：1.35 兼容路径漏搬 `cs_fault_report_enable`，导致老用户态 CS_FAULT 上报静默失效。这条是"ARM 自己的坑"，与 MTK 无关，但会连带影响 MTK 的故障恢复机制。

5. **`base_csf_notification` 的 64 字节硬约束**（`align[56]`）已接近极限：`group_error` 从 24 涨到 40，剩 8 字节余量。再有一次字段扩展就会溢出结构体边界。

6. **移植余量充足**：r56p0 空闲 80 号，MTK 私有 ioctl 可原样搬回；但建议整体迁到 64+ 号段以规避未来冲突。
