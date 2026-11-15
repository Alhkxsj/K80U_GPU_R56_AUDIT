# 03 — GLES / EGL 用户态 ABI 审计

> **本文件回答**：原厂 `libGLES_mali.so` 能否与 R56p0 Kbase 配合？
>
> **答案**：**从 UAPI 契约看，可以**——这是本阶段最反直觉、也是证据最充分的结论。但"契约兼容"不等于"实测可用"，关键 gap 见 §12。
>
> **前置声明（已更新）**：仓库内**没有** `libGLES_mali.so`；**真机上有**（53,105,232 B，`/vendor/lib64/egl/mt6991/`），并已取得 ELF 头、动态段、Build ID 与部分符号。因此本文的证据结构是：
> - **契约面**：源码 [E1]，完整；
> - **实体面**：真机元数据 [D]，部分（无版本串、无完整符号表、无 `.text`）；
> - **行为面**：[U]，完全缺失。
>
> 证据等级：**[D·A]** 厂商分区静态实测 · **[E1]** 源码直接证据 · **[E2]** 交叉推导 · **[U]** UNKNOWN

---

## 0. 结论摘要

| 检查面 | 结果 | 证据 |
| --- | --- | --- |
| **实体与依赖（本轮新增）** | 真机 53,105,232 B / Build ID `700e6d41` / API 35；NEEDED **绑定 `libged` + `libgpud`**，非自包含 | §1.2–§1.3 **[D]** |
| **EGL 路径（本轮新增）** | 无 `libEGL_mali.so` **不是缺陷**；系统 `libEGL.so`(API 37) + `egl/<soc>/libGLES_mali.so` 布局可用 | §1.4 **[D]** |
| ioctl 编号 | 28 个共有，**定义逐字相同**；r56p0 删 5 个、**零新增** | §4 |
| ioctl 结构体 | 30 个共有，**仅 1 个字段改名**（布局不变） | §5 |
| 内存标志位 | CSF 视图 **24/24 一致** | §7 |
| `gpu_props` 属性 ID | 83 个**值全部不变**，新增 3 个**追加在末尾** | §8 |
| 版本协商 | `min()` **夹取**（非校验），有效版本恒 ≤ 1.30 | §1.5、§2 |
| 能力门槛 | 1.31/1.32/1.35 的新能力在 ≤1.30 下**全部不生效** | §3 |
| padding 校验 | r56p0 新增 48 个钩子：28 空 / 5 替用户态清零 / **15 强制**（含 CS 队列与 CSG 注册）→ **是真实门槛**，非"Arm 全替你清零" | §9 |
| MTK UAPI 扩展 | 存在 3 组，**均为尾部追加**，不破坏标准值 | §10 |

> **总体判断**：这是一次**减法 + 尾部追加**式演进，不是重排。原厂 1.30 用户态在 r56p0 上会走"旧版本路径"，而这些路径的代码与接口在 r56p0 中被完整保留。

---

## 1. DDK 版本确认

### 1.1 首轮状态：只有契约，没有实体

| 目标 | 首轮状态 | 本轮状态 |
| --- | --- | --- |
| `libGLES_mali.so` 存在性 | **[U]** 无文件 | ✅ **已实测** |
| 路径 | 猜测 `egl/` 或 `egl/libEGL_mali.so` | ✅ `/vendor/lib64/egl/**mt6991**/libGLES_mali.so` |
| 大小 / SHA256 | **[U]** | ✅ 53,105,232 B / `d84ae538…` |
| Build ID / API level | **[U]** | ✅ `700e6d4112a6a8a5` / **API 35** |
| 依赖库列表 | **[U]** | ✅ 全量 `DT_NEEDED` 已取得 |
| **release 串（版本代次）** | **[U]** | ✅ **`r49p1-03bet0`**（2026-11-15 23:20 补采，`07` §5.4） |
| **UK ABI 宣称值** | **[U]** | ⚠️ **1.30（由 release 映射，非库内自报）**；`UK version N.N` 字面量未命中 |

### 1.2 实测字段（[D]）

| 字段 | 值 | 说明 |
| --- | --- | --- |
| 类型 | `DYN` / `arm64` / `ELF64 LE` | 标准共享库 |
| SONAME | `libGLES_mali.so` | |
| 大小 | 53,105,232 B（50.6 MiB） | 含全部着色器编译器/预编译体，属"肥 DDK" |
| `.note.android.ident` | **API level 35** | vendor 侧按 Android 15 VNDK 级构建，**低于** system 侧 37 |
| `.note.gnu.build-id` | `700e6d4112a6a8a5` | 可与 r56p0 DDK 比对是否同批 |
| `FLAGS` | `SYMBOLIC` + `BIND_NOW` | 符号绑定为**自库优先**且立即绑定 → `LD_PRELOAD` 式拦截对其内部调用无效 |
| `ANDROID_RELA` / `RELR` | 存在（1,636 B / 30,432 B） | 使用 Android 专有重定位与相对重定位压缩 |

### 1.3 依赖面：这是"可保留"判断的真实边界（[D]）

```
NEEDED: android.hardware.graphics.allocator-V2-ndk.so   ← 分配走 AIDL allocator HAL
        android.hardware.graphics.mapper@4.0.so
        android.hardware.graphics.common-V5-ndk.so
        arm.mali.platform-V2-ndk.so                     ← ARM 平台 AIDL（压缩率/EGL 格式）
        libged.so                                       ← MTK GED 用户态
        libgpud.so                                      ← MTK GPU 数据面
        libgralloc_extra.so / libgralloc_metadata.so / libgralloctypes_mtk.so
        libion.so / libdmabufheap.so
        libladder.so / libbinder_ndk.so / libhardware.so / libbase.so / libutils.so
        libnativewindow.so / libutilscallstack.so / liblog.so / libcutils.so
        libz.so / libc++_shared? (libc++.so) / libc.so / libm.so / libdl.so
```

未定义符号里有两组值得单独记录：

| 组 | 数量级 | 含义 |
| --- | ---: | --- |
| `gpudInitialize`、`gpudIsEnabled`、`gpudVk*`、`gpudMisc*`、`g_gpud_context` | **80+** | MTK 在 **GLES 与 Vulkan 两条路径上都插了数据面钩子**；`gpudVkUnion` 说明 Vulkan 也被同一套仪表覆盖 |
| `ged_create` / `ged_destroy` / `ged_get_sys_info` | 3 | GLES 直接用 GED 做调度/信息查询 |

> **这条推翻了首轮一个隐含假设**："用户态只要 UAPI 兼容就能整体搬过去"。实际上 `libGLES_mali.so` **不是自包含的**——它绑定 `libged`（内核 GED 驱动的用户态）与 `libgpud`（MTK 私有数据面）。**"保留原厂用户态"必须是"整套保留"**，不能替换其中任何一个 MTK 库。

### 1.4 EGL 侧：为什么"没有 `libEGL_mali.so`"不是问题

| 事实 | 值 | 等级 |
| --- | --- | --- |
| `ro.hardware.egl` | `mali` | **[D]** |
| `libEGL_mali.so` | **全域不存在** | **[D]**（`egl/` 目录完整枚举 6 项） |
| 系统 `libEGL.so` | 287,664 B，API 37，NEEDED 含 `libnativebridge_lazy`/`libnativeloader_lazy`/`libvndksupport` | **[D]** |
| 系统 `libGLESv2.so` | 117,312 B，API 37，NEEDED `libEGL.so` | **[D]** |
| 系统运行状态 | HWC/gralloc/gpuserv/SurfaceFlinger 全在跑 | **[D]** |

**推理（[E2]）**：设备能显示画面 ⇒ EGL 初始化成功 ⇒ loader 找到了驱动。因此"缺 `libEGL_mali.so`"**不能**作为异常判据；`egl/<soc>/` 子目录布局说明搜索路径由厂商 linker 配置注入，而非默认平铺。

**仍未确定（[U]，U4-06 降为 P2）**：`mt6991` 子目录如何进入搜索路径；`libGLES_meow.so`（小米拦截层）的注入方式；`libGLES_mali.so` 是否导出 `egl*` 入口（符号输出被采集脚本按关键字筛选，**未见 ≠ 未导出**）。

### 1.5 "它宣称的版本"只能约束上界——首轮此处有过度推断

首轮写的是"原厂 DDK **必然**宣称 1.30"。核对 `kbase_api_handshake` 后，**这句是错的**：

```c
/* r49p1 mali_kbase_core_linux.c:461-479；r56p0 同构 */
switch (version->major) {
case BASE_UK_VERSION_MAJOR:
        version->minor = min_t(int, BASE_UK_VERSION_MINOR, (int)version->minor);  /* ← 夹取 */
        break;
default:
        version->major = BASE_UK_VERSION_MAJOR;      /* ← 不是失败，而是回填内核版本 */
        version->minor = BASE_UK_VERSION_MINOR;
        break;
}
kbase_file_set_api_version(kfile, version->major, version->minor);   /* 以夹取后的值为准 */
```

| 首轮说法 | 实际语义 | 正确表述 |
| --- | --- | --- |
| "DDK 必然宣称 1.30" | DDK 宣称 `1.x` 任一值都能握手；`x>30` 被夹到 30，`x<30` 保留 `x` | **DDK 的有效 API 版本恒 ≤ 1.30** [E1] |
| "DDK 若违反，握手就失败" | major 不为 1 时**不失败**，内核回填自己的版本，由 DDK 自行决定是否继续 | 握手是**夹取**而非**校验** [E1] |

**由此得到一条比首轮更强的结论**：

> 无论原厂 DDK 宣称 `1.28` / `1.30` / 甚至 `1.39`，只要它是在 r49p1 头文件下构建的，其在 **r56p0 内核**上的有效版本都 ≤ 1.30——因为 `min(39, claim) = claim ≤ 30`。
>
> 也就是说：**r56p0 不会把原厂 DDK 抬到 1.39 语义**，这一点由 `min()` 单向保证，无需知道 DDK 的宣称值。U4-04 缺的是"它到底宣称多少"，而这个缺口**不改变方向性结论**。

| 项 | 原厂（r49p1 生态） | r56p0 |
| --- | --- | --- |
| 内核 `BASE_UK_VERSION` | **1.30**（真机 `/sys/module/.../version` 已确认 **[D·C]**） | 1.39 |
| DDK 自称 release | **`r49p1-03bet0`**（库内可打印串，**[D·A]**，2026-11-15 23:20 补采） | — |
| DDK 的 UK ABI | **1.30**（由 release 串映射 **[D·A]+[E1]**，非库内自报，见下） | — |
| 在 r56p0 上的有效版本 | `min(39, 30) = 30` | 39 |

> 真机证据补强（两侧现已齐备）：
>
> - **内核侧**：`/sys/module/mali_kbase_mt6991_r49/version` = `r49p1-03bet0 (UK version 1.30)`，由 `MODULE_VERSION(MALI_RELEASE_NAME " (UK version " …)` 展开（`mali_kbase_core_linux.c:6800`）。**[D·C]**
> - **DDK 侧**：`libGLES_mali.so` 内含 `r49p1-03bet0`（`07` §5.4）。**[D·A]**
> - **两侧同 release 串** → 原厂是"固件 0.3 + kbase r49p1 + DDK r49p1"的**配套组合**。
>
> **⚠️ 证据强度必须分开表述**：DDK **不自报** `UK version N.N`（该字面量全文未命中，`grep` 输出 `NOT_FOUND`）。1.30 是由 release 串 `r49p1-03bet0` 经 `BASE_UK_VERSION` 映射得出，不是"库内读到 1.30"。写成"DDK 实测宣称 1.30"属**证据越级**，禁止。

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

### 2.2 逐步推演：原厂 DDK（有效版本 ≤ 1.30）会发生什么

> 前提说明：下表按"DDK 宣称 30"推演，这是**最可能**的情形（DDK 用 r49p1 头构建）。若实际宣称 28 或 29，第 2 步结果相应变为 28/29，**第 3–6 步完全不变**——这正是 §1.5 的"上界结论"。

| 步骤 | 用户态 | 内核（r56p0） |
| --- | --- | --- |
| 1 | 发 `VERSION_CHECK{major=1, minor=30}` | `major==1` → 命中 `case` |
| 2 | — | `minor = min(39, 30) = **30**` |
| 3 | — | `kbase_file_set_api_version(kfile, 1, 30)` |
| 4 | — | `mali_kbase_supports_system_monitor(1.30)` → 表项是 `{1,0}` → **true** |
| 5 | — | 因 true，**不**提前建 kctx（走正常路径） |
| 6 | 收到 `{1, 30}` | 与自身期望一致 → 继续初始化 |

**关键**：内核不会"假装自己是 1.39"。它把 `kfile->api_version` **固定为 1.30**，后续所有能力判断都以 1.30 为基准。**这一步不依赖 DDK 的宣称值**，只依赖 `min()` 的单向性。

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

> **⚠️ 2026-11-16 更正（留痕）**：本节原文写"**只有两个真正检查**"（`GET_DDK_VERSION` + `MEM_JIT_INIT`），并据此在 §9.3 断言"padding 校验不构成兼容门槛"。**该统计错了**：`mali_kbase_ioctl_helpers.h` 共 **48** 个 `check_padding_*` 定义，原文只看了前 20 个（行 99–215）。全量分类如下，`CS_QUEUE_REGISTER`、`CS_QUEUE_GROUP_CREATE*` 等 **CS 热路径都在强制校验集里**。推导见 `09_stage4_closure.md` §5。

| 类别 | 数量 | 行为 |
| --- | ---: | --- |
| 空实现 | **28** | 不校验、不清零 |
| 替用户态清零 | **5** | `MEM_SYNC` / `CS_QUEUE_BIND` / `KCPU_QUEUE_DELETE` / `KCPU_QUEUE_ENQUEUE` / `QUEUE_GROUP_CLEAR_FAULTS` |
| **强制校验（非零 → `-EINVAL`）** | **12** | 见 §9.4 |

### 9.3 部分 ioctl 由 Arm 主动替旧用户态清零

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

> **这段注释仍是重要的文本证据**，但它证明的范围**比原以为的小**：它只覆盖 5 个 ioctl（`MEM_SYNC` / `CS_QUEUE_BIND` / `KCPU_QUEUE_DELETE` / `KCPU_QUEUE_ENQUEUE` / `QUEUE_GROUP_CLEAR_FAULTS`）。
> 1. Arm **知道**旧版用户态可能不清零 padding → 成立
> 2. Arm 在**这 5 个** ioctl 上选择替它清零 → 成立
> 3. 严格检查被推迟到兼容窗口结束后（`GPUCORE-42000`）→ 成立，**但仅对这 5 个**成立
>
> ~~这直接排除了"padding 校验构成兼容门槛"的假设。~~ → **撤回**：另外 12 个 ioctl 已经是强制校验，其中包含 CS 队列与 CSG 注册。

### 9.4 强制校验的 15 个函数（2026-11-16 全量重算；`28 + 5 + 15 = 48`）

| # | ioctl | 检查 | 触不到的后果 |
| ---: | --- | --- | --- |
| 1 | `GET_DDK_VERSION` | `p->padding` 必须 0 | 版本查询失败，可降级 |
| 2 | `MEM_JIT_INIT` | `padding[]` 全 0 | JIT 初始化失败 → tiler heap 不可用 |
| 3 | `MEM_PROFILE_ADD` | `p->padding` 必须 0 | 性能分析注册失败，可忽略 |
| 4 | `GET_CPU_GPU_TIMEINFO` | `in.paddings[]` 全 0 | 时间戳查询失败 |
| 5 | **`CS_QUEUE_REGISTER`** | `padding[]` 全 0 | **CS 队列注册失败 → 无法提交 GPU 工作** |
| 6 | **`CS_QUEUE_REGISTER_EX`** | `padding[]` + `ex_padding[]` | 同上（扩展注册路径） |
| 7–10 | **`CS_QUEUE_GROUP_CREATE`**（联合体分派）**/ `_1_6` / `_1_18` / `_1_35`** | `in.padding[]` 全 0 | **CSG 创建失败 → 上下文无法建立** |
| 11 | **`CS_QUEUE_GROUP_TERMINATE`** | `padding[]` 全 0 | CSG 无法正常销毁（泄漏/卡死） |
| 12–13 | **`CS_TILER_HEAP_INIT` / `_1_13`** | `in.padding` 必须 0 | tiler heap 不可用 |
| 14–15 | `MEM_ALLOC_EX` / `READ_USER_PAGE` | `in.extra` / `in.padding` 必须 0 | 分配/回读失败 |

> 逐函数清单与行号见 `09` §5.2（由脚本对 48 个定义全量分类生成）。

**风险等级（2026-11-16 上调）**：

> 原文写"`MEM_JIT_INIT` 是唯一需要关注的"。实际上 **5–11 号全在 CSF 主链路上**：注册 CS 队列、创建 CSG 是任何一次 GPU 提交的前置步骤。若 1.30 DDK 不清零 padding，**GPU 不是"降级"而是"完全不可用"**。
>
> 是否清零仍属 **[U] U4-04**——必须从 `libGLES_mali.so` 取得证据（一条 `strace -e ioctl` 或一次反编译）。这是组合 C（r56p0 kbase + 原厂 DDK）的**单点致命风险**。

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
| 1 | 用户态 DDK 版本 | **存在性/路径/大小/哈希已实测**；**版本串仍缺**，但有效 API 版本恒 ≤ 1.30 可证 | **[D]** + **[E1]** + **[U]** |
| 2 | ELF Build ID / SONAME / 依赖 | Build ID `700e6d4112a6a8a5`、SONAME `libGLES_mali.so`、API 35、19 条 NEEDED 全部实测 | **[D]** |
| 3 | UK ABI 识别与协商逻辑 | `handshake` 取 `min()`（**夹取，不是校验**），major 不匹配则回填内核版本 | [E1] |
| 4 | GPU 属性查询 ioctl | `GET_GPU_PROPS`，两阶段 size 协商，83 ID 不变 + 3 新增 | [E1] |
| 5 | 内存分配/导入/释放接口 | 12 个主干 ioctl 全部逐字相同；`MEM_SYNC` 仅字段改名 | [E1] |
| 6 | r49p1 vs R56p0 UAPI 对照 | 见 §4/§5/§7/§8 | [E1] |
| 7 | `gpu_props_user_data` / 句柄 / CSG 创建变化 | 结构体 +24 但**不越界**；句柄语义不变；CSG 有 `_1_6/_1_18/_1_35` 三代，≤1.30 走 `_1_18` | [E1] |
| 8 | 不兼容时的错误处理 | **无兼容性拒绝**——见 §2.4、§9.3；唯一硬失败点是固件（见 `02` §3.0） | [E1] |

### 12.2 核心判断

> **原厂 DDK 与 r56p0 的 UAPI 契约兼容；其有效 API 版本恒 ≤ 1.30。**
>
> 支撑：
> 1. ioctl 面是严格子集，28/28 定义逐字相同
> 2. 结构体 30/30 兼容（1 个仅改名）
> 3. 内存标志 CSF 视图 24/24 一致
> 4. 属性 ID 83/83 不变，新增严格追加
> 5. 能力表**显式保留 1.30 时代的全部旧行为**
> 6. padding 校验被 Arm 主动放宽
> 7. （本轮更新）`min()` 单向夹取 → **DDK 已实测为 `r49p1-03bet0`（→ 1.30）**，因此 r56p0 上的有效版本是 `min(39,30)=30`，不是"假设不会超过 30"，而是"已知就是 30"
>
> 这个结论**比 TASK 03 的预期更乐观**——TASK 03 认为用户态必须替换，契约层面不需要。
>
> **但"契约兼容"≠"实测可用"**：真机证据只证明"库存在、依赖是谁、构建于 API 35"，**没有**证明"它在 r56p0 上跑得起来"。措辞上只能写 **"契约层兼容候选"**，不能写"已验证可复用"。

### 12.3 但这不等于"能用"

契约兼容是**必要条件**，不是充分条件。以下 gap 仍会阻断：

| Gap | 说明 | 归属 |
| --- | --- | --- |
| **固件不兼容** | header 期望 0.3→0.4；**实际值已实测为 0.3**（`07` §4.5） | `02_csf_firmware_abi.md` §3 |
| 用户态是否用被删的 5 个 ioctl | 若用则 `-ENOTTY` | [U] U4-14 |
| 用户态是否清零 padding | `MEM_JIT_INIT` 会拒 | [U] U4-04 |
| 用户态是否严格校验 props 字节数 | 会因 +32 报错 | [U] U4-04 |
| MTK 扩展是否被依赖 | `internal_fence_wait`/`HWCNT` 失效 | [E3] |
| **MTK 运行库耦合**（本轮新增） | 依赖 `libged`/`libgpud`/`libgralloc_*_mtk`，**不能拆**；且 `libged` 本身依赖内核 GED | **[D]** |
| CSF 协议语义 | 需固件实体 + 运行时才能验 | [U] |

**结论**：`R56p0 Kbase + R56p0 固件 + 原厂用户态`（组合 C）在契约层是**可行候选**，但必须实机验证。详见 `06_abi_compatibility_matrix.md`。

### 12.4 UNKNOWN（本文件负责部分）

| ID | 内容 | 补齐方式 | 现状 |
| --- | --- | --- | --- |
| ~~U4-04~~ | 原厂 DDK 的 UK ABI **宣称值**（✅ 已取）、是否清 padding（开放）、是否严格校验 props（开放） | 反编译 / `strace` | ⚠️ **部分闭合**：release `r49p1-03bet0` [D·A] → UK 1.30；**两个行为子项仍开放** |
| U4-06 | EGL 加载机制（子目录注入、MEOW、`egl*` 导出） | `ld.config.txt` / `ro.egl.additional_libraries` | 降 P2：可用性已 [D] |
| U4-14 | 原厂 DDK 是否调用被删的 5 个 ioctl | `strace -e ioctl`（需 root） | 开放 |
| U4-15 | 原厂 DDK 对 `gpu_props` 新 ID 的处理（跳过 or 报错） | 实机 + 反编译 | 开放 |
| U4-16 | 原厂 DDK 是否依赖 `HWCNT` 通知做 DVFS | 反编译 + perfetto | 开放 |
