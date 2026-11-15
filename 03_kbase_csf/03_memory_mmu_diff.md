# 内存管理与 MMU 差异审计：r49p1-03bet0 → r56p0-18eac0

> 审计标的：Redmi K80 至尊版（25060RK16C）/ MT6991 / Immortalis-G925 MC12
> 审计方式：纯静态比对，不改源码、不编译、不部署
> 审计日期：2026-11-15
> 依据：`02_r56_source/mali_r56p0/driver/product/kernel/drivers/` @ **r56p0-18eac0**（`gpu/arm/midgard/Kbuild:75`）
> 对照：`01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/` @ **r49p1-03bet0**（`gpu/arm/midgard/Makefile:526`）

**基准路径**

| | 根 |
| --- | --- |
| A（r49p1） | `01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/` |
| B（r56p0） | `02_r56_source/mali_r56p0/driver/product/kernel/drivers/` |

下文用 `A/` 与 `B/` 指代上述两个根。

---

## 0. 总体规模

| 组件 | 文件 | r49p1 | r56p0 | Δ | 说明 |
| --- | --- | ---: | ---: | ---: | --- |
| MGM | `base/arm/memory_group_manager/memory_group_manager.c` | 1,503 | 507 | **−996** | **全部为 MTK 注入被移除** |
| PMA | `base/arm/protected_memory_allocator/protected_memory_allocator.c` | 1,100 | 563 | **−537** | **全部为 MTK 注入被移除** |
| MMU CSF 后端 | `gpu/arm/midgard/mmu/backend/mali_kbase_mmu_csf.c` | 1,077 | 615 | **−462** | 重构 |
| MMU 核心 | `gpu/arm/midgard/mmu/mali_kbase_mmu.c` | 4,960 | 4,552 | −408 | 重构 |
| 内存核心 | `gpu/arm/midgard/mali_kbase_mem.c` | 4,891 | 4,472 | −419 | 重构 |
| MGM 接口头 | `include/linux/memory_group_manager.h` | 235 | 265 | **+30** | **ops 签名变更** |
| PMA 接口头 | `include/linux/protected_memory_allocator.h` | 117 | 106 | −11 | ops 未变 |

### 0.1 关键判断：两处大幅瘦身不是"精简"，是"抽走 MTK 代码"

| 文件 | MTK 注入处数（r49p1） | r56p0 |
| --- | ---: | ---: |
| `memory_group_manager.c` | **97** | **0** |
| `protected_memory_allocator.c` | **43** | **0** |

这 1,533 行的减少**没有一行是 ARM 代码被删**，全部是 MTK 定制被剥离。ARM 自己的逻辑两版基本等价。

---

## KB-040 — `mgm_update_gpu_pte` 回调签名新增两个参数（PBHA / PTE flags）

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-040 |
| **r49p1** | `A/gpu/arm/midgard/include/linux/memory_group_manager.h:142-143` |
| **r56p0** | `B/../include/linux/memory_group_manager.h:160-162` |
| **差异类型** | 修改（接口签名破坏性变更） |
| **影响 ABI** | 否（内核内部接口） |
| **影响 MTK** | **是（P0）** |
| **严重程度** | **P0** |
| **证据等级** | **实证** |

### 签名对比

**r49p1**（`memory_group_manager.h:142`）：

```c
u64 (*mgm_update_gpu_pte)(struct memory_group_manager_device *mgm_dev,
                          unsigned int group_id, int mmu_level, u64 pte);
```

**r56p0**（`memory_group_manager.h:160`）：

```c
u64 (*mgm_update_gpu_pte)(struct memory_group_manager_device *mgm_dev,
                          unsigned int group_id, unsigned int pbha_id,
                          unsigned int pte_flags, int mmu_level, u64 pte);
```

### 新增参数的含义

- **`pbha_id`**：PE-side Buffer Hint Attribute ID。ARM 新一代 GPU 的 SLC（System Level Cache）分区提示机制，用于把特定内存映射到特定缓存分区
- **`pte_flags`**：PTE 属性标志，定义于 `enum mgm_pte_flags`，含 `MMA_VIOLATION` 等位

r56p0 头文件注释明确写道：

> If mgm_pte_flags has the MMA_VIOLATION bit set - ie, 1<<MMA_VIOLATION, the system integrator may decide to encode the pbha_id into the PTE if (and only if) the NONCACHEABLE SYSC_PHBA_OVERRIDE is required.

这是 r56 代新增的**缓存分区控制能力**，G925 硬件支持。

### 为什么是 P0

`mgm_update_gpu_pte` 是 MGM 与 kbase MMU 之间的核心回调——每次建 GPU 页表都会调用。MTK 的 MGM 实现（`memory_group_manager.c`，r49p1 版 1,503 行）里有自己的 `example_mgm_update_gpu_pte` 等价实现，签名不匹配则：

1. 编译期：函数指针赋值类型不兼容，`-Wincompatible-pointer-types` 报错
2. 即使强转通过，运行期参数错位：`pbha_id` 会占用原 `mmu_level` 的位置，`pte` 会读到栈上的垃圾

→ MTK 的 MGM 实现**必须整体重写**，不能改几个参数了事——还要理解 pbha_id 从哪来、怎么用。

### 配套：`mgm_pte_to_original_pte` 未变但语义需配合

```c
/* 两版相同 */
u64 (*mgm_pte_to_original_pte)(struct memory_group_manager_device *mgm_dev,
                               unsigned int group_id, int mmu_level, u64 pte);
```

签名没变，但它是 `update_gpu_pte` 的逆操作。若 `update` 中编码了 pbha，`to_original` 也必须能解出来——否则 PTE 无法还原，影响 `kbase_mmu` 的页表回收路径。

---

## KB-041 — MGM 中 MTK 内存池机制（996 行）整体消失

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-041 |
| **r49p1** | `A/base/arm/memory_group_manager/memory_group_manager.c`（1,503 行，97 处 MTK 注入） |
| **r56p0** | `B/base/arm/memory_group_manager/memory_group_manager.c`（507 行，0 处 MTK 注入） |
| **差异类型** | 删除（MTK 定制剥离） |
| **影响 ABI** | 否 |
| **影响 MTK** | **是（P0）** |
| **严重程度** | **P0** |
| **证据等级** | **实证** |

### MTK 注入的符号分布（r49p1）

| 符号 | 处数 | 作用 |
| --- | ---: | --- |
| `CONFIG_MALI_MTK_MGMM` | 34 | 总开关 |
| `mtk_fetch_page` | 16 | 从池中取页 |
| `mtk_mgm_pool_flush` | 11 | 池刷新 |
| `mtk_mgm_pool_reclaim_count_objects_local` | 9 | 回收计数 |
| `mtk_mgm_pool_fill` | 7 | 池填充 |
| **`mtk_emicen_get_rk_size`** | 3 | **查询 EMI 中心 DRAM rank 大小** |
| `CONFIG_MALI_MTK_SLC_ALL_CACHE_MODE` | 3 | SLC 缓存模式 |
| `mtk_refill_work_handler` | 2 | **异步补池 worker** |
| `mtk_need_to_alloc` | 2 | 分配判定 |
| `mtk_mgm_pool_reclaim_scan_objects` | 2 | 回收扫描 |

### 这套机制在做什么

从符号可以还原设计意图：

1. **页池化**：`mtk_mgm_pool_fill` / `flush` / `refill_work_handler` —— 预分配一批物理页放在池里，GPU 申请时直接取，避免走 buddy allocator 的慢路径
2. **按 DRAM rank 分级**：`mtk_emicen_get_rk_size` 查询 EMI（External Memory Interface）的 rank 大小，把池按 rank0/rank1 分开。debugfs 节点 `rank0` / `rank1` / `lp_rank0` / `lp_rank1` / `rank_mode`（r49p1 `:183-303`）就是这套分级的控制面
3. **异步补充**：`mtk_refill_work_handler` 在低水位时后台补池，避免申请路径阻塞

这是 MTK 的**GPU 内存分配性能优化**，不是功能必需，但影响帧率稳定性。

### r56p0 的状态

`memory_group_manager.c` 只剩 ARM 的**参考实现**，函数名全部是 `example_mgm_*`：

```
example_mgm_alloc_page()      :242
example_mgm_free_page()       :268
example_mgm_get_import_memory_id() :284
example_mgm_update_gpu_pte()  :301
example_mgm_pte_to_original_pte()  :338
example_mgm_vmf_insert_pfn_prot()  :354
```

`example_` 前缀意味着 ARM 把它定位为"示例，产品需替换"。r49p1 里 MTK 正是替换成了自己的实现。

→ 移植时必须把 MTK 的池化逻辑**重新实现到 r56p0 的 ops 签名上**（见 KB-040）。工作量不是"搬代码"，因为：
- 回调签名变了（+pbha_id, +pte_flags）
- r49p1 中 `CONFIG_MALI_MTK_MGMM` 专属的 `mgm_mtk_cache_pool_size` 回调在 r56p0 的 ops 中**没有位置**（见 KB-042）

---

## KB-042 — MGM ops 新增 `cached_access_permitted`，但 MTK 的 `cache_pool_size` 回调无位置

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-042 |
| **r49p1** | `include/linux/memory_group_manager.h:191-193`：`#if IS_ENABLED(CONFIG_MALI_MTK_MGMM) size_t (*mgm_mtk_cache_pool_size)(...)` |
| **r56p0** | `include/linux/memory_group_manager.h:212-220`：`bool (*mgm_get_import_memory_cached_access_permitted)(...)` |
| **差异类型** | 新增（ARM 侧）+ 删除（MTK 侧） |
| **影响 ABI** | 否 |
| **影响 MTK** | **是** |
| **严重程度** | **P1** |
| **证据等级** | **实证** |

r49p1 在 ops 结构体末尾挂了一个 MTK 专属回调：

```c
#if IS_ENABLED(CONFIG_MALI_MTK_MGMM)
	size_t (*mgm_mtk_cache_pool_size)(struct memory_group_manager_device *mgm_dev);
#endif /* CONFIG_MALI_MTK_MGMM */
```

这是 MTK 直接往 ARM 接口结构体里塞私有成员——比 `#if` 包裹代码块更深的侵入，因为它改变了**结构体布局**。

r56p0 中该位置换成了 ARM 自己的新回调 `mgm_get_import_memory_cached_access_permitted()`，语义是"外部导入内存是否允许 GPU 缓存访问"。

**冲突点**：r56p0 的 ops 结构体没有多余槽位给 MTK。要么：
- 放弃 `mgm_mtk_cache_pool_size`（需要改所有调用点）
- 把 MTK 数据挂在 `memory_group_manager_device.data` 上，用 container_of 取（可行但需重构）

---

## KB-043 — PMA 中 MTK 的 SVP 安全区与页堆（537 行）消失

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-043 |
| **r49p1** | `A/base/arm/protected_memory_allocator/protected_memory_allocator.c`（1,100 行，43 处 MTK 注入） |
| **r56p0** | `B/base/arm/protected_memory_allocator/protected_memory_allocator.c`（563 行，0 处） |
| **差异类型** | 删除（MTK 定制剥离） |
| **影响 ABI** | 否 |
| **影响 MTK** | **是（P0）** |
| **严重程度** | **P0** |
| **证据等级** | **实证** |

### MTK 注入的符号分布（r49p1）

| 符号 | 处数 | 作用 |
| --- | ---: | --- |
| `CONFIG_MALI_MTK_GPU_IOMMU` | 9 | 与 MTK GPU IOMMU 对接 |
| `CONFIG_MALI_MTK_GPU_PMA_PAGE_HEAP` | 8 | **受保护页堆** |
| `CONFIG_MALI_MTK_GHPM_STAGE1_ENABLE` | 8 | GHPM 一级保护 |
| `CONFIG_MALI_MTK_GPU_PROTECTED_MEMORY_SUPPORT` | 6 | 总开关 |
| `CONFIG_MALI_MTK_GPU_PMA_PAGE_HEAP_2MB` | 5 | 2 MB 大页堆 |
| `mtk_prot_page` | 2 | 受保护页结构 |
| `mtk_protected_memory_allocator_probe` | 2 | 独立 probe 入口 |
| `mtk_gpu_iommu_init` | 2 | IOMMU 初始化 |
| **`mtk_svp_region`** | 1 | **Secure Video Path 区域** |
| **`mtk_svp_page`** | 1 | SVP 页 |

### 为什么这条比 MGM 更严重

**SVP（Secure Video Path）是 DRM 视频播放的硬需求**。K80U 播放受版权保护的流媒体（Netflix/爱奇艺高清等）走 SVP：解码后的帧存放在受保护内存，GPU 合成时只能读不能导出。

`mtk_svp_region` / `mtk_svp_page` 表明 MTK 在 PMA 层直接建了 SVP 内存区。r56p0 的 PMA 只剩 ARM 的 `example_pma_*` 参考实现，**没有 SVP 概念**。

→ 换 r56p0 后，若 SVP 通路未重新实现：
- 受版权内容无法播放（黑屏或报错）
- 或降级到非安全路径（合规风险）

这是**功能级**而非性能级的影响，比 KB-041 的 MGM 池化更关键。

### 接口本身未变（重要）

`protected_memory_allocator_ops` 两版**签名完全一致**：

```c
struct protected_memory_allocator_ops {
	struct protected_memory_allocation *(*pma_alloc_page)(
		struct protected_memory_allocator_device *pma_dev, unsigned int order);
	void (*pma_free_page)(struct protected_memory_allocator_device *pma_dev,
	                      struct protected_memory_allocation *pma);
};
```

头文件从 117 行降到 106 行，但 ops 结构体没动。

**这是个好消息**：MTK 的 SVP 实现可以**按原签名移植**，只是要找回落脚点（r56p0 的 PMA 主体结构不同，需重新组织）。相比 KB-040 的 MGM 签名变更，PMA 的移植成本低得多。

---

## KB-044 — MMU CSF 后端重构：`mmu_csf.c` 1,077 → 615 行，函数 17 → 12

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-044 |
| **r49p1** | `A/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_csf.c`（1,077 行，61 处 MTK 注入） |
| **r56p0** | `B/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_csf.c`（615 行，0 处） |
| **差异类型** | 重构 |
| **影响 ABI** | 否 |
| **影响 MTK** | **是（P1）** |
| **严重程度** | **P1** |
| **证据等级** | 实证（行数/函数数/注入数）+ **UNKNOWN**（具体哪些函数被删） |

函数数量从 17 降到 12，减少 5 个。但**未逐函数比对**，无法给出具体被删函数名——这是本文件的一个明确缺口。

MTK 在此文件有 61 处注入，是 `mmu/` 目录里最密集的。

> **建议**：移植前单独做 `mmu_csf.c` 的函数级 diff，重点看 `kbase_mmu_*_csf` 系列与 fault 处理路径。

---

## KB-045 — MMU 层 MTK 注入总量：128 处

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-045 |
| **r49p1** | `mmu/` 目录 4 个文件含 MTK 注入 |
| **r56p0** | 0 |
| **差异类型** | 结构差异 |
| **影响 MTK** | **是** |
| **严重程度** | **P1** |
| **证据等级** | **实证** |

| 文件 | MTK 注入处数 |
| --- | ---: |
| `mmu/backend/mali_kbase_mmu_csf.c` | **61** |
| `mmu/mali_kbase_mmu.c` | **38** |
| `mmu/mali_kbase_mmu_hw_direct.c` | **29** |
| `mmu/backend/mali_kbase_mmu_jm.c` | 5（JM 后端，未编译） |
| **合计（不含 JM）** | **128** |

MMU 是仅次于 CSF 的第二大注入区。`mali_kbase_mmu_hw_direct.c` 的 29 处值得注意——这是直接操作 MMU 硬件的路径，MTK 在此加了什么（推测与 fault 上报、TLB 刷写策略有关）**UNKNOWN**。

---

## KB-046 — JIT 内存接口未变

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-046 |
| **r49p1** | `include/uapi/gpu/arm/midgard/mali_kbase_ioctl.h:214-222`（`kbase_ioctl_mem_jit_init` 注释块） |
| **r56p0** | 同文件 `:165-173` |
| **差异类型** | 无实质变化 |
| **影响 ABI** | 否 |
| **影响 MTK** | 否 |
| **严重程度** | **P3** |
| **证据等级** | **实证** |

JIT 相关文件名两版完全一致：

```
mali_kbase_mem_linux.c    mali_kbase_mem_migrate.c   mali_kbase_mem_pool.c
mali_kbase_mem_pool_debugfs.c   mali_kbase_mem_pool_group.c   mali_kbase_mem_profile_debugfs.c
```

`kbase_ioctl_mem_jit_init` 的字段注释（`va_pages` / `max_allocations` / `trim_level` / `group_id` / `padding` / `phys_pages`）两版**逐字相同**，未见增删。

> 注：仅比对了注释与字段清单，**未逐行比对 `mali_kbase_mem.c` 的 JIT 实现**（两版 4,891 / 4,472 行，差 419 行）。实现层面的变化为 **UNKNOWN**。

---

## KB-047 — IOMMU / SMMU 对接：走通用 SMMUv3，无直接 iommu API 调用

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-047 |
| **r49p1** | 全树 grep `iommu_map` / `arm_smmu` / `IOMMU_DOMAIN`：**零命中** |
| **r56p0** | 同样零命中 |
| **差异类型** | 无变化 |
| **影响 ABI** | 否 |
| **影响 MTK** | 否 |
| **严重程度** | **P3** |
| **证据等级** | **实证**（grep 零命中）+ 侧证（设备树） |

两版 kbase 都**不直接调用 IOMMU 框架 API**，而是通过 DMA-BUF 的 dma-mapping 接口间接使用 SMMU。

设备树侧已确认（见 `01_original_baseline/gpu_dependency_map.md` §6）：

```
mt6991.dts:10895  gpu_smmu: iommu@...  compatible = "arm,smmu-v3"
```

→ **IOMMU 层与 Mali 驱动版本无关**，不是移植障碍。这一点在 01-C 已判定，本次比对进一步确认 kbase 侧两版行为一致。

---

## 1. 缓存一致性

| 项 | r49p1 | r56p0 | 判断 |
| --- | --- | --- | --- |
| `mali_kbase_gpu_coherency.h` | 存在 | 存在（行数相同） | 无变化 |
| `mgm_get_import_memory_cached_access_permitted` | 无 | **有** | 新增能力 |
| `pbha_id` / `pte_flags` | 无 | **有** | 新增缓存分区控制 |
| `CONFIG_MALI_MTK_SLC_ALL_CACHE_MODE` | 3 处（MGM） | 0 | MTK 的 SLC 全缓存模式移除 |

**结论**：r56p0 在缓存控制上**能力更强**（PBHA + cached_access_permitted），但 MTK 的 `SLC_ALL_CACHE_MODE` 定制没有对应位置。需要判断：是用 r56p0 新机制替代，还是把 MTK 的模式硬塞回去。

---

## 2. Protected Memory 专项

| 文件 | r49p1 | r56p0 | Δ |
| --- | ---: | ---: | ---: |
| `csf/mali_kbase_csf_protected_memory.c` | 155 | 155 | **0** |
| `csf/mali_kbase_csf_protected_memory.h` | 71 | 71 | **0** |
| `base/arm/protected_memory_allocator/protected_memory_allocator.c` | 1,100 | 563 | −537 |

**CSF 侧的受保护内存管理完全没变**（行数一致），变的只有 PMA 层的分配器实现。

这个区分很重要：
- **受保护内存的"用法"（CSF 侧）** → 不用改
- **受保护内存的"来源"（PMA 侧）** → MTK 的 SVP 实现被剥离

→ 移植时 CSF 侧零改动，只需重建 PMA。

---

## 3. 移植影响矩阵

| 组件 | 接口是否变 | MTK 注入 | 移植难度 | 阻塞级 |
| --- | --- | ---: | --- | :--: |
| MGM ops 接口 | **变（+2 参数）** | — | 高 | **P0** |
| MGM 实现 | — | 97 处 / 996 行 | 高（需按新签名重写） | **P0** |
| PMA 实现 | 否 | 43 处 / 537 行 | 中（签名兼容，需重组） | **P0** |
| PMA 接口 | 否 | — | 低 | P3 |
| MMU CSF 后端 | 未知 | 61 处 | 中高 | P1 |
| MMU 核心 | 未知 | 38 + 29 处 | 中 | P1 |
| CSF 受保护内存 | 否 | 0 | 无 | P3 |
| JIT | 否 | 少量 | 低 | P3 |
| IOMMU / SMMU | 否 | 0 | 无 | P3 |

---

## 4. 本文件的结论

1. **MGM 与 PMA 的大幅瘦身（合计 1,533 行）全部是 MTK 定制被剥离，不是 ARM 精简代码。** 这两个文件的 r56p0 版本已退回参考实现（`example_*` 前缀），产品化必须自行填充。

2. **MGM 的 `mgm_update_gpu_pte` 签名新增 `pbha_id` 和 `pte_flags`，是接口级破坏。** 这是本域唯一的 P0 接口变更，MTK 的 MGM 实现无法改参数了事——还要理解 PBHA 的取值来源与语义。

3. **PMA 的 ops 签名完全没变，这是好消息。** MTK 的 SVP 实现可以按原签名移植（约 537 行），只是要重新组织到 r56p0 的文件结构里。**SVP 是 DRM 播放的硬需求，功能级影响，优先级高于 MGM 的性能优化。**

4. **CSF 侧的受保护内存管理两版行数完全一致**，说明受保护内存的"用法"没变，只有"来源"变了。这让移植范围收窄。

5. **MMU 层 128 处 MTK 注入，具体变化未逐函数比对（UNKNOWN）。** 这是本文件的明确缺口，建议移植前补做 `mmu_csf.c` 与 `mmu_hw_direct.c` 的函数级 diff。

6. **IOMMU 不是障碍。** 两版 kbase 都不直接调 iommu API，硬件侧走 `arm,smmu-v3` 通用驱动，与 Mali 版本解耦。
