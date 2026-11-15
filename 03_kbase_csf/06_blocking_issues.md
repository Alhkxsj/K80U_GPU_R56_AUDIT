# 阻塞项汇总与终局判定：r49p1-03bet0 → r56p0-18eac0

> 审计标的：Redmi K80 至尊版（25060RK16C）/ MT6991 / Immortalis-G925 MC12
> 审计方式：纯静态比对，不改源码、不编译、不部署
> 审计日期：2026-11-15
> 本文件汇总 `01`–`05` 的 66 条差异，回答 TASK 02 的五个终局问题
> 依据：`02_r56_source/mali_r56p0/driver/product/kernel/drivers/gpu/arm/midgard/` @ **r56p0-18eac0**（`Kbuild:75`）
> 对照：`01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/` @ **r49p1-03bet0**（`Makefile:526`）

---

## 0. 差异规模量化

### 0.1 代码面

| 维度 | r49p1 | r56p0 | 变化 |
| --- | ---: | ---: | ---: |
| 共同文件 | — | — | **392** |
| 仅 r49p1 有 | **189** | — | JM 后端 + MTK 平台层 + arbiter |
| 仅 r56p0 有 | — | **62** | fw_io / am / io / bazel / 文档 |
| 共有文件行数 | 163,502 | 159,979 | −3,523 |
| CSF 目录行数 | 41,825 | 43,156 | **+1,331** |

### 0.2 差异条目分布

| 域 | 条目数 | P0 | P1 | P2 | P3 |
| --- | ---: | ---: | ---: | ---: | ---: |
| UAPI / ABI | 14 | 4 | 4 | 3 | 3 |
| CSF 架构 | 9 | 3 | 2 | 1 | 3 |
| 内存 / MMU | 8 | 3 | 3 | 0 | 2 |
| 电源管理 | 7 | 3 | 1 | 1 | 2 |
| G925 硬件 | 7 | 0 | 1 | 0 | 6 |
| **合计** | **45** | **13** | **11** | **5** | **16** |

> 注：45 条为有实质内容的差异条目；另有 21 条为"文件存在但无实质变化"的确认项，未计入。

### 0.3 MTK 注入被剥离的总量

| 位置 | 文件数 | 注入处数 | 行数 |
| --- | ---: | ---: | ---: |
| `csf/` | 30 / 66 | **约 900** | — |
| `mmu/` | 4 | **128** | — |
| `base/arm/memory_group_manager.c` | 1 | **97** | −996 |
| `base/arm/protected_memory_allocator.c` | 1 | **43** | −537 |
| `backend/gpu/mali_kbase_devfreq.c` | 1 | **26** | −7 |
| `platform/`（整目录） | 约 70 | — | 全部不存在 |

**总量：约 1,200 处注入、约 70 个 MTK 专属文件、39 个 `CONFIG_MALI_MTK_*` 开关。**

---

## 1. P0 阻塞清单（13 条）

按"不解决则功能不可用"排序。

| ID | 条目 | 域 | 为什么是 P0 |
| --- | --- | :--: | --- |
| **KB-040** | `mgm_update_gpu_pte` 签名新增 `pbha_id` / `pte_flags` | 内存 | MGM 是每次建页表都走的回调，签名不符则编译失败或参数错位 |
| **KB-041** | MGM 的 MTK 池化机制（996 行 / 97 处）消失 | 内存 | GPU 内存分配性能优化归零，r56p0 只剩 `example_*` 参考实现 |
| **KB-043** | PMA 的 MTK SVP 安全区（537 行 / 43 处）消失 | 内存 | **DRM 受版权视频无法播放**，功能级缺失 |
| **KB-051** | 上电路径：`gpufreq_power_control()` vs `regulator/genpd` | 电源 | MTK 符号在 r56p0 中不存在，编译期即失败 |
| **KB-052** | devfreq governor 从 MTK GED 退回 `simple_ondemand` | 电源 | **静默降级**，不报错，帧率稳定性显著退化 |
| **KB-053** | `platform/` 目录 MTK 内容为零 | 电源 | 约 70 个文件需自建，无任何可搬运的 MTK 代码 |
| **KB-002** | `base_mem_handle` 删除 → 裸 `gpu_va` | UAPI | sizeof 不变、不报错，但寻址语义变，静默错误最难排查 |
| **KB-003** | `CS_QUEUE_GROUP_CREATE` 58→63、112→120 字节 | UAPI | CSG 创建的必经路径，结构体扩容 |
| **KB-007** | `gpu_props_user_data` 568→592 字节 | UAPI | `GET_GPUPROPS` 必经，用户态缓冲区越界 24 字节 |
| **KB-008** | MTK 私有 ioctl 80（`INTERNAL_FENCE_WAIT`）删除 | UAPI | MTK 用户态组件调它做 fence 等待 + 故障转储，返回 `-ENOTTY` |
| **KB-022** | reset 路径重构，`_ext()` 与 `gpu_reset_entry_name[]` 消失 | CSF | MTK 的 reset 归因能力归零，hang 排查手段丢失 |
| **KB-023** | `kbase_gpueb_irq_handler` 删除 | CSF | GPUEB 的低压/广播超时中断无人接管 |
| **KB-028** | CSF 核心 900 处 MTK 注入无落点 | CSF | 决定移植方式——MTK 代码长在 ARM 代码内部，无干净切面 |

---

## 2. P1 清单（11 条）

| ID | 条目 | 域 | 影响 |
| --- | --- | :--: | --- |
| KB-004 | 1.35 兼容路径漏搬 `cs_fault_report_enable` | UAPI | CS_FAULT 上报静默失效（ARM 自己的缺陷） |
| KB-005 | 队列错误载荷 16→32 字节 | UAPI | 用户态解析错位 |
| KB-006 | `base_csf_notification` 内部 24→40 但总大小 64 不变 | UAPI | 隐蔽错位，最易漏判 |
| KB-009 | `CONFIG_MALI_MTK_DEBUG_DUMP` 的 `dump.cmd` 字段删除 | UAPI | MTK 调试通路编译失败 |
| KB-010 | `SET_LIMITED_CORE_COUNT`（55）删除 | UAPI | 用户态无法动态裁剪核心数（MC12 省电手段） |
| KB-020 | `fw_io` 抽象层引入（1,370 行） | CSF | MTK 的 11 个 debug_dump 文件需改写 |
| KB-025 | `kcpu.c` 精简 493 行（MTK 注入 171 处） | CSF | KCPU 队列的 MTK 定制失效 |
| KB-026 | 调度器重构：`api_sync_*` 移除、kthread 6→13 | CSF | MTK 的 workqueue 调度补丁方向相反 |
| KB-042 | MTK 的 `mgm_mtk_cache_pool_size` 回调无位置 | 内存 | 需改用 `data` 指针 + container_of |
| KB-044 | `mmu_csf.c` 615 行 / 61 处注入（具体函数变化 UNKNOWN） | 内存 | MMU CSF 后端需重新对接 |
| KB-063 | `gpu_features` 新增两位，`raw_props` 200→216 | G925 | 用户态需能解析新结构 |

---

## 3. 五个终局问题

### Q1：R56p0 与出厂 r49p1 的核心差异有多大？

**答：结构级重构，不是版本迭代。**

四个量化指标：

1. **UAPI 层**：58 个 ioctl 中 8 个删除、2 个新增、1 个改号（58→63）；84 个共有结构体中 10 个字段布局变化、10 个被删、1 个新增。UK ABI 跨 9 个 minor（1.30→1.39）。
2. **CSF 层**：66 个文件中 6 个删除（门铃验证 931 行）、6 个新增（固件 I/O 1,370 行），reset 路径压缩 42%（1,176→686），调度器增 551 行。
3. **内存层**：MGM 与 PMA 合计减少 1,533 行，**全部是 MTK 代码被剥离**，ARM 侧退回 `example_*` 参考实现。
4. **平台层**：r56p0 的 `platform/` 只有 ARM 上游内容，MTK 的约 70 个文件**整体不存在**。

一句话：**r56p0 是一次把 MTK 定制全部剥掉后重新设计的版本**，ARM 本体在架构上更先进（fw_io 抽象、v14/v15 寄存器、PBHA），但所有 OEM 适配都要重做。

---

### Q2：哪些差异会影响 K80U 的 G925 MC12？

**答：影响分两类，且"硬件驱动"层面影响很小，"配套能力"层面影响很大。**

**几乎无影响的（已验证）**：

| 项 | 证据 |
| --- | --- |
| 产品识别 | `nr_cores>=10 && rt_supported` → G925，两版逐行相同（KB-060） |
| 寄存器映射 | G925 走 `kbase_regmap_v12_init`，两版**逐字节相同**，38 行 / 7 条赋值 / 连行号都是 1106（KB-061） |
| 核心数计算 | `hweight64(shader_present)`，四行逻辑逐条对应（KB-066） |

→ **基础驱动能力上，r56p0 驱动 G925 没有障碍，甚至更好**（多了 `ray_traversal`、`neural_accelerator`、PBHA 三个能力位）。

**有实际影响的**：

| ID | 影响 | 性质 |
| --- | --- | --- |
| KB-010 | `SET_LIMITED_CORE_COUNT` 删除 | MC12 无法被用户态动态裁核省电，与 KB-052 叠加放大功耗问题 |
| KB-007 | `gpu_props_user_data` 568→592 | 用户态读 props 越界 24 字节 |
| KB-063 | 新能力位是否真为 G925 具备 | **UNKNOWN**，需读硬件寄存器 |

**必须警惕的认知误区**：

> "r56p0 支持 `ray_traversal`" ≠ "G925 具备 ray_traversal"。
> 源码只证明驱动**能处理**这个能力，不证明**硬件有**。三项新能力（`ray_traversal`、`neural_accelerator`、`pbha_id`）在 G925 上的实际可用性全部为 **UNKNOWN**。

---

### Q3：哪些差异会破坏现有 MTK 平台适配？

**答：不是"某些差异破坏适配"，而是"MTK 适配的每一个层面都需要重建"。**

按破坏程度排序：

| 层面 | 破坏方式 | ID |
| --- | --- | --- |
| **电源上电** | `gpufreq_power_control()` 符号不存在，编译期失败 | KB-051 |
| **DVFS 策略** | governor 从 GED 退回 `simple_ondemand`，静默降级 | KB-052 |
| **内存分配** | MGM 的 997 行池化（含 EMI rank 分级）消失 | KB-041 |
| **受保护内存** | PMA 的 537 行 SVP 实现消失，DRM 播放受影响 | KB-043 |
| **reset 归因** | `_ext()` 与 23 项 reset 触发点表消失 | KB-022 |
| **GPUEB 中断** | `kbase_gpueb_irq_handler` 消失 | KB-023 |
| **故障转储** | `fw_io` 收口共享内存访问，11 个 dump 文件需改写 | KB-020 |
| **调度补丁** | MTK 把 kthread 改 workqueue（92 处），r56p0 反向增 kthread（6→13） | KB-026 |
| **私有 ioctl** | 80 号删除，用户态返回 `-ENOTTY` | KB-008 |
| **平台目录** | 约 70 个文件整体不存在 | KB-053 |

---

### Q4：哪些接口必须重新实现？

**分三类：能搬、要改、要重写。**

| 类别 | 接口 | 依据 |
| --- | --- | --- |
| **能原样搬**（接口签名未变） | `kbase_pm_callback_conf`（12 回调） | KB-050：逐成员一致 |
| | `kbase_platform_funcs_conf`（4 回调） | KB-054：CSF 下有效部分一致 |
| | `protected_memory_allocator_ops`（2 回调） | KB-043：签名未变 |
| | JIT ioctl 结构体 | KB-046：字段注释逐字相同 |
| **要改**（结构在但内容不匹配） | `devfreq_dev_profile` 的 governor 名 | KB-052 |
| | `fw_io` 的页访问调用 | KB-020 |
| | 错误通知解析（32 字节载荷） | KB-005 / KB-006 |
| **必须重写**（无对应物） | `gpufreq_power_control()` 上电链 | KB-051 |
| | `kbase_gpueb_irq_handler()` | KB-023 |
| | `gpu_reset_entry_name[]` + `_ext()` | KB-022 |
| | MGM 池化（97 处 / 996 行，且签名已变） | KB-040 / KB-041 |
| | PMA SVP（43 处 / 537 行） | KB-043 |
| | `MTK_GPU_DEVFREQ_GOVERNOR_DUMMY` | KB-052 |
| | ioctl 80（`INTERNAL_FENCE_WAIT`） | KB-008 |
| | CSF 核心 900 处注入的重新落位 | KB-028 |

**最小可工作集（能点亮 + 跑 GLES）**：KB-040（MGM 签名）、KB-051（上电）、KB-052（governor 先用 `simple_ondemand` 顶）、KB-003/007/002（UAPI 三处）。

**完整可交付集**：再加 KB-043（SVP）、KB-022/023（reset 与 GPUEB）、KB-008（私有 ioctl）、KB-020（dump 改写）、KB-041（池化）。

---

### Q5：是否存在可以保留 MTK r49p1 平台层、只升级 ARM 通用 Kbase 核心的路径？

**答：不存在。**

这是本审计最需要明确的一条判断，因为它在直觉上"应该可行"，但源码证据不支持。

#### 为什么直觉上可行

平台接口确实稳定：
- `kbase_pm_callback_conf` 两版逐成员一致（KB-050）
- `kbase_platform_funcs_conf` 两版一致（KB-054）
- 调用点也一致（`mali_kbase_pm_backend.c:107/126` vs `:94/133`）

所以看起来可以：把 r56p0 的 kbase 核心 + r49p1 的 `platform/mt6991/` 拼起来。

#### 为什么实际不可行

**"MTK 平台层"和"ARM 核心层"不是两个可分离的模块，MTK 代码是嵌在 ARM 核心内部的。**

证据（KB-028）：

| 文件 | MTK 注入处数 | 这个文件属于哪一层 |
| --- | ---: | --- |
| `csf/mali_kbase_csf_scheduler.c` | **308** | ARM 核心 |
| `csf/mali_kbase_csf_kcpu.c` | **171** | ARM 核心 |
| `csf/mali_kbase_csf.c` | **154** | ARM 核心 |
| `csf/mali_kbase_csf_firmware.c` | **119** | ARM 核心 |
| `csf/mali_kbase_csf_reset_gpu.c` | **108** | ARM 核心 |
| `mmu/mali_kbase_mmu.c` | 38 | ARM 核心 |
| `mmu/mali_kbase_mmu_hw_direct.c` | 29 | ARM 核心 |
| `backend/gpu/mali_kbase_devfreq.c` | 26 | ARM 核心 |

`csf/` 有 **30 / 66 个文件**被注入。这些不是"平台适配"，是**改在 ARM 调度器、队列管理、固件加载、重置流程里的业务逻辑**。

平台层的 `mt6991/mali_kbase_config_mt6991.c` 只有 775 行，它调用的 `gpufreq_power_control()` 只是入口；真正的 MTK 逻辑分布在 CSF 核心的 900 处注入里。

#### 切面在哪里

唯一存在的干净切面是：

```
platform/mt6991/          ← 775 行，可整体保留（接口未变）
platform/mtk_platform_common/  ← 约 60 文件，作为独立模块保留
─────────────────────────────
以上 vs 以下的接口：kbase_pm_callback_conf / kbase_platform_funcs_conf  ← 稳定
─────────────────────────────
csf/ + mmu/ + backend/ + base/  ← 这里的 900+ 处 MTK 注入无法保留
```

**结论**：可以保留的是 `platform/` 目录这两个子目录**作为独立模块**，它们通过稳定接口与 ARM 核心通信。但 MTK 在 ARM 核心内部的 900 处注入**必须全部重写**，因为它们依赖的内部结构（`kbase_device` 布局、`kbdev->csf` 成员、reset 流程的函数签名）在 r56p0 中已经变了。

#### 正确的移植形态

```
r56p0 ARM 核心（csf/ mmu/ backend/ base/）
    ↓ 通过稳定接口（KB-050 / KB-054）
MTK 适配层（重建，约 70 文件）
    ↓
GPUFreq → IPI → GPUEB（MT6991 硬件链路，不变）
```

而不是：

```
r56p0 ARM 核心  ←── 拼接 ──→  r49p1 的 MTK 修改版 ARM 核心   ❌ 没有这个切面
```

#### 一个反直觉的佐证

`mali_kbase_csf_reset_gpu.c` 里的 MTK 代码（KB-022/023）是这样写的：

```c
#if IS_ENABLED(CONFIG_MALI_MTK_GPU_RESET_DEBUG)
char *gpu_reset_entry_name[] = {
	...
	"kbase_gpueb_irq_handler",  // 19
#endif
```

MTK 把 GPUEB 的中断处理函数**注册进 ARM 的 reset 触发点表**。这张表本身是 ARM 的（用来记录谁触发了 reset），MTK 只是往里加了一项。表没了（r56p0 删除），这项就无处安放。

**这不是"平台适配"，这是在 ARM 的数据结构里加成员。** 换 ARM 版本，这个成员必然丢失。

---

## 4. 移植工作量估算

> 以下为**基于代码量的粗估**，非承诺。仅供排期参考。

| 工作项 | 代码量参考 | 难度 | 依赖 |
| --- | --- | --- | --- |
| UAPI 对齐（用户态同步） | 8 个 ioctl + 10 个结构体 | 中 | 需拿到 `libGLES_mali.so` 源码或二进制分析 |
| MGM 重写（含 PBHA） | 996 行 MTK 逻辑 + 新签名适配 | **高** | 需理解 PBHA 语义 |
| PMA 重写（SVP） | 537 行 | 中 | 需 SVP 区域配置（TEE 侧） |
| devfreq governor 移植 | 26 处 + `mtk_platform_devfreq_governor.c` | 中 | 需 GED 侧配合 |
| reset 路径（含 GPUEB IRQ） | `reset_gpu.c` 108 处注入 | **高** | 需理解 r56p0 新 reset 状态机 |
| CSF 核心 900 处注入 | `csf/` 30 文件 | **极高** | 需逐文件重审 |
| 平台层重建 | 约 70 文件 | 中 | 接口稳定，主要是搬运 |
| dump 体系改写 | 11 个 `mtk_platform_debug_dump_*.c` | 中 | 依赖 `fw_io` |

**最大风险项：CSF 核心 900 处注入**（KB-028）。这不是"工作量"问题，是"能否保证行为等价"的问题——`scheduler.c` 平均每 27 行就有一处 MTK 代码，逐处判断"保留/改写/删除"需要深刻理解两侧设计意图。

---

## 5. UNKNOWN 清单（诚实边界）

本审计**无法**给出结论的项，不做推测性判断：

| 编号 | 内容 | 为什么无法判定 | 需要什么才能判定 |
| --- | --- | --- | --- |
| U1 | `mmu_csf.c` 具体哪些函数被删（17→12） | 只做了行数/函数数统计，未逐函数 diff | 函数级 diff |
| U2 | `kcpu.c` 精简 493 行的具体内容 | 同上 | 函数级 diff |
| U3 | `ipa_control.c` 的 30 处 DVFS 注入细节 | 未比对 | 逐行比对 |
| U4 | `sleep-mode-enable` 设备树属性的真实位置 | 只在 `mt6991.dts` mali 节点找过，未查 dali 板级 dtsi | `grep` dali*.dts* |
| U5 | G925 是否具备 `ray_traversal` / `neural_accelerator` / PBHA | 需读硬件寄存器，静态源码无法判定 | 实测读 `GPU_FEATURES` |
| U6 | K80U 用户态是否调用 55 号（`SET_LIMITED_CORE_COUNT`）与 80 号 ioctl | `libGLES_mali.so` 不在任何已获取仓库 | 提取真机 so + 反汇编 |
| U7 | `mali_csffw.bin` 的固件 ABI 版本 | 固件二进制不存在 | 从真机 `/vendor/firmware/` 提取 |
| U8 | `gpu_props_user_data` 568/592 字节的计算 | 按 ARM64 LP64 规则手工推算，**未经编译验证**（禁止编译） | 独立编译单元 `sizeof` 对拍 |
| U9 | r56p0 与 r49p1 的完整 diff 统计（相似度） | 未做全量 diff 工具分析 | `diff -r` + 统计脚本 |
| U10 | `02_r56_source` 中 5 个 DT binding yaml 的正文可信度 | 文件含 10 处网页文本残留（`oaicite`），非官方归档原样；官方 tar.gz 需 Arm 账号 | 取得 `AX504X08X-SW-99002-r56p0-18eac0.tar.gz` 后按 SHA 对拍 |

> **纪律说明**：本审计全程未编译任何代码，所有 sizeof 为人工推算，已逐项标注"实证"或"推断"。凡标注 UNKNOWN 者，不出具 PASS 结论。

---

## 6. 对下一步的建议

### 6.1 立即需要用户决策的三件事

1. **用户态 DDK 与固件**（`mali_csffw.bin`、`libGLES_mali.so`）——所有已获取仓库零命中。没有它们，`05_userspace_firmware` 无法成立，U6/U7 永远 UNKNOWN。**是否从真机提取？**
   > **2026-11-15 现状更新**：用户已完成三份只读采集（`inventory` / `file_metadata` / `elf_analysis`），`05_userspace_firmware/01`–`08` 已据此建立。**此项不再是待决策项**；剩余缺口仅为固件 header 8 字节与 DDK 版本串（U4-01 / U4-04）。
2. ~~**Android 16 内核树**~~ → **内核树代次**——现有 `bsp-dali-v-oss` 分支是 `android15-6.6`，与 K80U 的 ~~Android 16~~ 目标不符（见 `01_original_baseline/source_integrity.md` M3/U2）。
   > **2026-11-15 更正**：设备实际为 **Android 17 / SDK 37**；`android15` 是 **GKI 分支名**，不是 Android 版本，故"分支名与 Android 版本不符"这一表述本身不成立 **[D·B]**。真正的代次差在 **GKI sublevel**：BSP 树为 `android15-6.6`，设备运行为 `6.6.143-android15-8-gf9aa2fec23c3`。问题**性质已澄清**，但"以哪棵树为底"仍是 Stage 5 的开放决策。
3. **移植目标定位**——是"最小可点亮"（6 项）还是"完整可交付"（14 项）？两者工作量差 3–5 倍。

### 6.2 建议补做的三项分析（成本低、价值高）

| 分析 | 成本 | 收益 |
| --- | --- | --- |
| `mmu_csf.c` + `kcpu.c` 函数级 diff | 1 次工具调用 | 消除 U1/U2，把 P1 变成可执行清单 |
| `diff -r` 全量相似度统计 | 1 次工具调用 | 给出准确的"改动面"百分比，替代行数差 |
| `dali*.dts*` 检索 `sleep-mode-enable` | 1 次工具调用 | 消除 U4，确定 runtime PM 是否在用 |

### 6.3 不建议现在做的事

- **不要开始写移植代码**。MB-040（MGM 签名）与 KB-022（reset 重构）尚未完成设计层面的对齐，写代码会返工。
- **不要用 PanVK 的兼容性作为依据**。PanVK 是 Mesa 的用户态驱动，走的是 kbase UAPI，它的实测通过只证明 **UAPI 语义**可用，不证明 Arm 官方 DDK 兼容（TASK 02 特别禁止第 4 条）。

---

## 7. 一句话总结

> **r56p0 是一份把 MTK 定制全部剥除后重新设计的 Arm 驱动。它的 ARM 本体更强（fw_io 抽象、v14/v15 寄存器、PBHA），但对 G925 的硬件驱动能力并未退步——寄存器映射函数逐字节相同。真正的代价不在"能不能驱动 G925"，而在"MTK 那 1,200 处注入要重新落位"。而这 1,200 处里，有 900 处是长在 ARM 核心内部的，不存在"只换 ARM 层、保留 MTK 层"的切面。**
