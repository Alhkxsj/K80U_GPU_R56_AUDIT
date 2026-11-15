# DDK 双路线评估（DDK-A：R56 DDK / DDK-B：R46 DDK）

> **本文件做什么**：在同一套证据标准下评估两条用户态 DDK 路线，给出可核验的决策矩阵与推荐。
>
> **命名注意**：本文件的 **DDK-A / DDK-B** 指**用户态 DDK 版本选择**，与 [`README.md`](README.md) 中"移植策略 A–D"（整包替换 / 回移 / 仅换固件 / 不移植）是**正交维度**，不可混用编号。本文件的结论默认搭载在移植策略 **B（以 MTK 为底回移）** 上。
>
> **本文件不做**：不获取、不下载、不反编译、不使用任何来源不明的二进制。全部结论基于仓库内源码与可核验公开资料。

---

## 0. 结论先行

| 判定 | 结论 | 一句话理由 |
| --- | --- | --- |
| **DDK-A（R56）** | **首选，但受商业交付物阻断** | 技术上唯一能"完整保留 R56 特性"的路线；缺口是**资产**不是**方案** |
| **DDK-B（R46）** | **不可推荐**（当前证据下） | ①不解决固件问题；②存在**硬件时间线矛盾**（G925 发布晚于 R46）；③结构体版本落点未知 |
| 两条路线共同前提 | **都必须有 R56p0 的 `mali_csffw.bin`（header 0.4）** | 固件由 **kbase** 加载与校验，与 DDK 版本无关 |
| 最终结论归属 | **"R56 DDK 暂时受商业交付物阻断" + "R46 路线亦缺乏充分证据"** | 两者不能合并成"有条件可行" |

> **最容易犯的错误**：把"R46 DDK 更旧、所以更兼容"当成默认假设。**版本更旧意味着离 R56 更远**，而离原厂（R49）更远的用户态从未在本平台被验证过。

---

## 1. 三条决定性的机制（先讲清，后面全部结论都从这三条推出）

### 1.1 握手没有下限——任何 `1.x` DDK 都能"成功"

```c
/* mali_kbase_core_linux.c:357-378 */
static int kbase_api_handshake(struct kbase_file *kfile,
                               struct kbase_ioctl_version_check *version)
{
    switch (version->major) {
    case BASE_UK_VERSION_MAJOR:                       /* = 1 */
        version->minor = min_t(int, BASE_UK_VERSION_MINOR, (int)version->minor);
        break;                                        /* ← 取较小者，无下限检查 */
    default:
        version->major = BASE_UK_VERSION_MAJOR;
        version->minor = BASE_UK_VERSION_MINOR;       /* ← 不匹配则回显自己，让用户态自己决定 */
        break;
    }
    err = kbase_file_set_api_version(kfile, version->major, version->minor);
    ...
}
```

```c
/* mali_kbase_core_linux.c:241-259 —— set_api_version 只做状态机，不校验版本范围 */
kfile->api_version = KBASE_API_VERSION(major, minor);
atomic_set(&kfile->setup_state, KBASE_FILE_NEED_CTX);
return 0;
```

| 结论 | 含义 |
| --- | --- |
| **major = 1 是硬要求** | 所有 5th Gen CSF DDK（1.0–1.39）都是 major 1 |
| **minor 无下限** | 1.30 / 1.26 / 1.18 全部握手成功，kbase 直接接受 |
| **"握手成功"零信息量** | 它只说明"双方同意用较低版本号"，**不说明任何 ioctl 语义可用** |

> 这条推翻了两种常见误判：①"版本差太多会被拒绝"——不会；②"握手成功就能跑"——不能。

### 1.2 能力表把"旧语义"做成了显式分支

```c
/* mali_kbase_core_linux.c:145-160 */
static const struct mali_kbase_capability_def kbase_caps_table[...] = {
    { 1,  0 }, /* SYSTEM_MONITOR */
    { 1,  0 }, /* JIT_PRESSURE_LIMIT */
    { 1, 22 }, /* QUERY_MEM_DONT_NEED */
    { 1,  0 }, /* QUERY_MEM_GROW_ON_GPF */
    { 1,  0 }, /* QUERY_MEM_PROTECTED */
    { 1, 26 }, /* QUERY_MEM_IMPORT_SYNC_ON_MAP_UNMAP */
    { 1, 26 }, /* QUERY_MEM_KERNEL_SYNC */
    { 1, 28 }, /* QUERY_MEM_SAME_VA */
    { 1, 31 }, /* REJECT_ALLOC_MEM_DONT_NEED */
    ...
    { 1, 32 }, /* REJECT_ALLOC_MEM_UNUSED_BIT_5 / _BIT_7 */
    { 1, 35 }, /* CSG_CS_USER_PAGE_ALLOCATION */
};
```

判定逻辑是 `api_version >= required_ver` → **低版本 DDK 得到"不支持"→ 走旧行为**。

| 结论 | 含义 |
| --- | --- |
| **R56 kbase 保留了 1.0 起的旧语义路径** | 不是"只支持 1.39"，而是"按 DDK 声称的版本降级" |
| **cap 的粒度是"行为开关"，不是"功能删除"** | 例：`CSG_CS_USER_PAGE_ALLOCATION`（1.35）对 1.30 的 DDK 走"CSG 自己分配 user page"旧路径 |
| **这是 R49 DDK（1.30）能在 R56 kbase 上工作的根本原因** | 并非巧合 |

### 1.3 ioctl 用"同一请求号 + 不同 size"做版本化

```c
/* 三个历史变体共存，靠 _IOC_SIZE 区分 */
#define KBASE_IOCTL_CS_QUEUE_GROUP_CREATE_1_6   _IOWR(KBASE_IOCTL_TYPE, 42, …_1_6)    /* 32 B */
#define KBASE_IOCTL_CS_QUEUE_GROUP_CREATE_1_18  _IOWR(KBASE_IOCTL_TYPE, 58, …_1_18)   /* 40 B */
#define KBASE_IOCTL_CS_QUEUE_GROUP_CREATE_1_35  _IOWR(KBASE_IOCTL_TYPE, 58, …_1_35)   /* 112 B */
#define KBASE_IOCTL_CS_QUEUE_GROUP_CREATE       _IOWR(KBASE_IOCTL_TYPE, 63, …)        /* 120 B */
```

`switch (cmd)` 按完整请求号分派 → **size 不同即不同分支**。

| 结论 | 含义 |
| --- | --- |
| 向后兼容的粒度是**结构体大小**，不是版本号 | 同一 minor 段内的多次扩展靠 size 区分 |
| **R49（112 B）精确命中 `_1_35`** | 已在上报文件 §4.1 验证 |
| 一个未知的 DDK 若发出**未被登记的 size** | `default: return -ENOTTY` → 该 ioctl 直接失败 |

> 这条是本文件最重要的**风险探针**：DDK-B（R46）的 CSG 结构体大小若是 32 或其它未登记值，**第一个 CSG 创建就会失败 → GPU 完全不可用**。

---

## 2. DDK-A：R56 DDK 路线

### 2.1 需要什么

| 组件 | 内容 | 现状 |
| --- | --- | --- |
| Kbase | `AX504X08X-SW-99002-r56p0-18eac0.tar.gz`（MD5 `62b168823691eb61ec29654cbf35e719`） | ✅ **在手**（`02_r56_source/`） |
| CSF 固件 | `mali_csffw.bin`，header **0.4**，**G925 MC12** SKU | ⛔ **不在手**（交付包 23 条目内 0 命中） |
| 用户态 DDK | GLES / EGL / Vulkan，UK ABI **1.39**，产品配置含 G925 MC12 | ⛔ **不在手** |
| MTK 平台层 | GED / GPUFreq / GPUEB / MGM / PMA / GPU Power | ✅ 源码在手（`01_original_baseline/`），需适配 2 项 |

### 2.2 技术可行性（假设资产到位）

| 检查项 | 判定 | 依据 |
| --- | --- | --- |
| kbase ↔ DDK 的 UK ABI | **同代，1.39 对 1.39** | 同一 release 交付 |
| GLES/EGL/Vulkan 完整性 | **完整**（Arm 官方整套） | 商业 DDK 定义 |
| G925 MC12 支持 | **有**——`TKRX` 产品 ID + `tKRx` workaround 表 | `mali_kbase_hw.c:272`、`mali_kbase_core_linux.c:2582` |
| CSF 固件匹配 | **需验收**，判据已预写（`05/09` §6.2 四项） | — |
| MTK 私有接口 | **需重建连接层**（保留 10 / 适配 2） | `04/06` §1 |
| R56 新特性 | **可全保**（DDK 同代） | — |

### 2.3 唯一缺口：资产与授权

| 问题 | 答案 |
| --- | --- |
| R56 源码包里有没有固件/DDK | **没有**。23 个条目，`firmware`/`.bin`/`ddk`/`libGLES`/`vulkan`/`csffw` 命中全为 0 [E1] |
| 有没有公开合法渠道 | **没有公开渠道**。Arm 的 DDK 与 CSF 固件属**商业授权交付件**（随 SoC 厂商授权包分发），不在 `developer.arm.com` 的公开下载区 |
| 能否用别的机型的 R56 DDK | **不可以**。DDK 是 per-GPU 产品配置（核数、SKU、频率表、平台扩展）编译的；跨机型 = 未经验证的组合 |
| 能否改 R49 固件的 header 冒充 0.4 | **禁止**。header 只是入口校验，内部 entry 表（GLB 接口版本、region 布局）随 release 变化；改 8 字节只会把"早失败"变成"晚崩溃" |

> **DDK-A 的状态是"方案成立、资产缺失"，不是"技术不可行"。** 这与"没找到"有本质区别——`05/09` §6 已把原因钉在交付包内容上。

---

## 3. DDK-B：R46 DDK 路线

### 3.1 先纠正一个前提

用户描述的路线 B 是"**R56 Kbase + R46 DDK**"。这条组合必须先回答一个问题：

> **为什么"降级到 R46"能绕过阻断？**

| 假设 | 现实 |
| --- | --- |
| "R46 更旧，所以更容易获得" | R46 与 R56 同属 Arm 商业交付体系，**授权门槛相同**；公开渠道均无 |
| "R46 不需要 R56 固件" | **错**。固件由 **R56 kbase** 加载并校验 header `0.4`（`!=` 严格）。DDK 版本与固件无关 |
| "R46 的固件能配 R56 kbase" | 取决于 header 版本，而 header 由 **kbase release** 决定，不由 DDK 决定 |

**结论：DDK-B 不减少任何一项资产需求。** 它需要：R56 源码（有）+ **R56 固件（无）** + R46 DDK（无）。资产缺口从 2 项变成 2 项，且多了一个"版本跨代"的技术风险。

### 3.2 逐项核验（用户要求的 10 项）

| # | 核验项 | 现状 | 判定 |
| ---: | --- | --- | --- |
| 1 | R46 DDK 的具体版本 / ABI / 发布信息 | 仅有间接时间锚点：`r46p0` 修复 CVE-2023-5249，该 CVE 公布于 **2024-02-05** → R46 ≤ 2024-02。**UK minor 未知** | **UNKNOWN** |
| 2 | 与 R56 kbase 的 ABI 兼容性 | major=1 必然握手成功（§1.1）；minor 未知 → caps 走哪条分支未知 | **无法判定** |
| 3 | 是否依赖 R56 才有的接口 | 取决于 minor：若 < 1.35 则不会调用 1.35+ 的 ioctl（它还不存在） | **结构上不会** |
| 4 | R56 是否保留 R46 所需旧接口 | **部分保留**：`_1_6` / `_1_18` / `_1_35` 三代 CSG 变体都在；但 R56 **删了 6 个 ioctl**（含 MTK 私有 80） | **有真实删除** |
| 5 | CSG / CSF / props / 内存 / ioctl 兼容性 | CSG 依赖"R46 的 size 是否被登记"（§1.3）；props 两阶段协商与版本无关 | **存在一个致命未知** |
| 6 | 能否正确使用 G925 MC12 | **高度可疑**：G925 发布于 **2024-05-29**，晚于 R46 约 4 个月；R46 时代的 DDK 产品配置不可能包含 G925 | **大概率否** |
| 7 | 所需固件与 R56 kbase 是否匹配 | 必须用 0.4 固件（R56 kbase 决定）；R46 时代固件为 0.3 或更低 | **需换固件，即回到 §2.3** |
| 8 | MTK 私有接口可否恢复 | 与 DDK 版本无关；取决于 kbase 侧适配 | **与路线无关** |
| 9 | 损失哪些 R56 新特性 | 全部 1.31–1.39 新增（`CSG_CS_USER_PAGE_ALLOCATION`、`neural_*`、`comp_pri_*`、`fragment_endpoint_task_limit`、`CS_TILER_HEAP_SIZE` 等） | **大量损失** |
| 10 | 是否必须改 R56 kbase | 若 R46 的 CSG size 未被登记 → 需在 kbase 加一个分支（**违反"不改核心"约束**） | **可能需要** |

### 3.3 关键未知：G925 支持的时间线矛盾

| 事实 | 值 | 等级 |
| --- | --- | --- |
| `Immortalis-G925` 发布日 | **2024-05-29**（与 Cortex-X925 同场） | [E2] 公开资料一致 |
| `r46p0` 存在的最晚时间锚 | ≤ 2024-02（CVE-2023-5249 的修复版本） | [E2] Arm 安全公告 |
| 时间差 | **≥ 4 个月** | 计算 |

**推论链**：

1. GPU 产品 ID 是硬件流片时确定的。G925 / G725 共用 `GPU_ID_PRODUCT_TKRX`，该 ID 随 2024 年 5 月的产品线引入。
2. R46 若早于该时间点，其 `mali_kbase_hw.c` 的 workaround 表中**不会有 `tKRx` 条目**。
3. 没有 `tKRx` workaround 的 kbase 即使能"跑起来"，也会**缺少该芯片的硬件规避**——表现为随机 hang / 数据损坏，而非干净的报错。
4. DDK 侧同理：DDK 是 per-GPU 产品配置编译的，R46 不可能有 G925 MC12 的配置。

> **置信度**：中高（[E2]，两条独立时间线同向）。**验证方法**（成本极低，仅需 R46 源码包）：在 R46 的 `mali_kbase_hw.c` 中检索 `GPU_ID_PRODUCT_TKRX` 与 `base_hw_issues_tKRx_*`。**若无 → 路线 B 在硬件层直接判死，无需再讨论 ABI。**
>
> **注意**：这一条是本文件中**最需要被实测检验**的推断。它一旦被推翻（R46 确实含 TKRX），路线 B 的技术评估就要重做。

### 3.4 若 R46 确实支持 G925，还剩什么

即使乐观情况成立，仍有：

| 残留问题 | 说明 |
| --- | --- |
| CSG 结构体 size 落点 | 若 R46 的 CSG 是 32 B（`_1_6` 之前的形态）而 R56 只登记了 40/112/120 → `-ENOTTY` |
| 固件仍是 0.4 | 与 DDK-A 相同的阻断 |
| 特性损失 | 1.31–1.39 全部新增能力失效，"尽可能保留 R56 新特性"的目标落空 |
| 维护成本 | 一条**从未在任何平台被验证过**的组合，后续每次升级都要重新论证 |

---

## 4. 决策矩阵

| 评估项目 | **DDK-A（R56）** | **DDK-B（R46）** |
| --- | --- | --- |
| **获取渠道** | Arm 商业交付（随 SoC 厂商授权包） | 同左，未见更易获得的渠道 |
| **授权状态** | 需授权；本机原厂包只含 R49 | 需授权；本机**完全无** R46 资产 |
| **ABI 兼容性** | 1.39 ↔ 1.39 **同代，无风险** | minor 未知；major=1 必过握手，但语义落点未知 |
| **G925 MC12 支持证据** | ✅ `TKRX` + `tKRx` workaround（`mali_kbase_hw.c:272`） | ❌ 无证据；**时间线矛盾**（G925 晚于 R46 ≥4 个月） |
| **CSF 固件匹配** | 需 0.4；判据已预写 | **同样需 0.4**（由 kbase 决定），R46 自身固件不可用 |
| **MTK 私有接口兼容** | 保留 10 / 适配 2（`04/06`） | 同左（与 DDK 版本无关） |
| **GLES/EGL/Vulkan 完整性** | 官方整套 | 官方整套，但为旧代 |
| **R56 新特性保留程度** | **100%** | 仅 ≤1.2x 语义；1.31–1.39 全失 |
| **需要修改 Kbase 的程度** | 只需 MTK 连接层（平台目录），核心不改 | **可能需在核心加 CSG 分支**（若 size 未登记） |
| **预计维护成本** | 低（与上游同代） | **高**（跨代组合，每次升级重新论证） |
| **当前可行性** | **技术可行 / 资产阻断** | **不可推荐 / 证据不足** |

---

## 5. 推荐决策

### 5.1 结论

> **推荐 DDK-A（R56），并把"取得 R56p0 商业交付件（固件 + DDK）"列为唯一真正的阻断项。DDK-B 在现有证据下不可推荐——它不解除任何阻断，却引入硬件时间线与结构体版本两个新风险。**

### 5.2 为什么**不**选"先用 R46 顶着、以后再换 R56"

| 理由 | 说明 |
| --- | --- |
| 顶不住 | 固件 0.4 是硬门槛，R46 也过不去 |
| 换不掉 | 若有 R56 交付件，一开始就该用 R56；若没有，R46 也拿不到 |
| 代价高 | 每多一条"未验证组合"，验证矩阵就多一维，而本项目的人力预算不支持 |

### 5.3 什么情况下会重启 DDK-B 评估

| 触发条件 | 说明 |
| --- | --- |
| R56 DDK **确认不可获得**，且 R46 DDK **可获得** | 此时 DDK-B 才有存在意义 |
| 且 R46 源码包被证实含 `GPU_ID_PRODUCT_TKRX` / `tKRx` | 硬件层不判死 |
| 且 R46 的 CSG create size ∈ {40, 112, 120} | 分派能命中 |
| 且明确接受"放弃 1.31–1.39 全部新特性" | 目标降级需用户书面确认 |

> 四条同时满足才值得做可行性论证。**当前一条都不满足。**

### 5.4 不能说的话

| 禁止表述 | 原因 |
| --- | --- |
| "R46 与 R56 版本接近，应该兼容" | 版本接近≠兼容；`_1_35` 的存在恰恰说明"接近"要专门写迁移代码 |
| "handshake 通过就说明 DDK 可用" | §1.1，握手零信息量 |
| "用 R46 可以先跑起来验证平台适配" | 固件 0.4 挡住，跑不起来 |
| "R56 固件可以从别处找" | 来源不明二进制违反 `D-004`，且 SKU 风险不可控 |

---

## 6. 引用

| 引用 | 位置 |
| --- | --- |
| 握手 `min()` 与无下限 | `02_r56_source/.../mali_kbase_core_linux.c:357-385`、`:241-259` |
| caps 表与 `>=` 语义 | 同上 `:145-196` |
| CSG 三代变体与 size | `02_r56_source/.../include/uapi/.../csf/mali_kbase_csf_ioctl.h:296-436`、`:767-796` |
| `_1_35` 逐字段迁移 | `02_r56_source/.../mali_kbase_core_linux.c:1446-1472` |
| 固件 header 0.4 严格比对 | `02_r56_source/.../csf/mali_kbase_csf_firmware.c:85-87, 2698-2704` |
| TKRX 与 `tKRx` workaround | `02_r56_source/.../mali_kbase_hw.c:272`、`mali_kbase_core_linux.c:2512/2582` |
| 交付包 23 条目、0 固件 | `05/09` §6.1 |
| 平台保留矩阵 | `04/06` §1 |
| G925 发布日 / CVE 日期 | 公开资料（见 `05/09` §10 体例，本文件 §3.3 已注明为 [E2]） |

*本文件不含任何源码或配置改动。*
