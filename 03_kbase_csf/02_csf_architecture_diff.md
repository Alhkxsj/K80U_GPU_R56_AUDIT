# CSF 核心架构差异审计：r49p1-03bet0 → r56p0-18eac0

> 审计标的：Redmi K80 至尊版（25060RK16C）/ MT6991 / Immortalis-G925 MC12
> 审计方式：纯静态比对，不改源码、不编译、不部署
> 审计日期：2026-11-15
> 行号均为实测，路径前缀统一省略为 `csf/`
> 依据：`02_r56_source/mali_r56p0/driver/product/kernel/drivers/gpu/arm/midgard/` @ **r56p0-18eac0**（`Kbuild:75`）
> 对照：`01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/` @ **r49p1-03bet0**（`Makefile:526`）

**基准路径**

| | 根 | CSF 目录 |
| --- | --- | --- |
| r49p1 | `01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/` | `csf/` |
| r56p0 | `02_r56_source/mali_r56p0/driver/product/kernel/drivers/gpu/arm/midgard/` | `csf/` |

---

## 0. 总体规模

| 指标 | r49p1 | r56p0 | Δ |
| --- | ---: | ---: | ---: |
| CSF 文件数（.c/.h） | 66 | 66 | 0 |
| CSF 总行数 | 41,825 | 43,156 | **+1,331** |
| 新增文件 | — | 6 个（1,680 行） | — |
| 删除文件 | 6 个（931 行） | — | — |
| 被 MTK 代码侵入的文件 | **30 / 66（45%）** | 0（结构上无 MTK） | — |

文件数恰好相同是个巧合——删了 6 个（门铃验证），加了 6 个（固件 I/O + NX + mem_flags）。

### 0.1 变动最大的文件

| 文件 | r49p1 | r56p0 | Δ | 性质 |
| --- | ---: | ---: | ---: | --- |
| `mali_kbase_csf_scheduler.c` | 8,194 | 8,745 | **+551** | 重构 + 新增页延迟控制 |
| `mali_kbase_csf_fw_io.h` | — | 512 | **+512** | **新增**：固件 I/O 抽象层 |
| `mali_kbase_csf_kcpu.c` | 3,459 | 2,966 | **−493** | 精简 |
| `mali_kbase_csf_reset_gpu.c` | 1,176 | 686 | **−490** | **重构**（MTK hook 全失） |
| `mali_kbase_csf_fw_io_no_mali.c` | — | 445 | **+445** | **新增**（nomali 变体） |
| `mali_kbase_csf_fw_io.c` | — | 413 | **+413** | **新增** |
| `mali_kbase_csf_db_validation.c` | 405 | — | **−405** | **删除** |
| `mali_kbase_csf_db_validation_test.c` | 321 | — | **−321** | **删除** |
| `mali_kbase_csf_defs.h` | 1,864 | 2,129 | **+265** | 扩展 |
| `mali_kbase_csf_nx_debugfs.c` | — | 238 | **+238** | **新增** |
| `mali_kbase_csf_registers.h` | 1,962 | 2,162 | +200 | 寄存器表扩展 |

---

## KB-020 — 新增固件 I/O 抽象层 `fw_io`，共享内存访问方式重构

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-020 |
| **r49p1** | 无此概念（直接内存访问） |
| **r56p0** | `csf/mali_kbase_csf_fw_io.h:1-512`、`mali_kbase_csf_fw_io.c:1-413`、`mali_kbase_csf_fw_io_no_mali.c:1-445` |
| **接入点** | `csf/mali_kbase_csf_defs.h:2009` — `struct kbase_csf_fw_io fw_io;`（嵌入 `kbase_device`） |
| **差异类型** | 新增（架构级重构） |
| **影响 ABI** | 否（内核内部） |
| **影响 MTK** | **是（重度）** |
| **严重程度** | **P1** |
| **证据等级** | **实证** |

### 这套抽象解决什么

`kbase_csf_fw_io` 把"CSF 固件共享内存读写"从**裸指针操作**封装成**带状态检查的对象**。核心接口（`mali_kbase_csf_fw_io.h`）：

```c
void kbase_csf_fw_io_init(struct kbase_csf_fw_io *fw_io, struct kbase_device *kbdev);   // :103
int  kbase_csf_fw_io_groups_pages_init(struct kbase_csf_fw_io *fw_io, u32 group_num);   // :120
int  kbase_csf_fw_io_streams_pages_init(struct kbase_csf_fw_io *fw_io, u32 gid, u32 n); // :131
u32  kbase_csf_fw_io_global_input_read(struct kbase_csf_fw_io *fw_io, u32 offset);      // :260
void kbase_csf_fw_io_group_write(struct kbase_csf_fw_io *fw_io, u32 gid, u32 off, u32 v);// :280
void kbase_csf_fw_io_stream_write(...);                                                  // :360
void kbase_csf_fw_io_set_status_gpu_suspended(struct kbase_csf_fw_io *fw_io);           // :407
bool kbase_csf_fw_io_check_status_gpu_suspended(struct kbase_csf_fw_io *fw_io);         // :423
```

三级寻址：**global**（全局寄存器）/ **group**（CSG 级 input+output 页）/ **stream**（CS 级 input+output 页），对应 `struct kbasep_csf_fw_io_stream_pages { void *input; void *output; }`（`:46-49`）。

### 为什么对 MTK 是 P1

MTK 的调试转储体系（`mtk_platform_common/mtk_platform_debug_dump_*.c`，共 11 个文件）大量直接读取 CSG/CS 的 input/output 页来做故障现场还原。r56p0 把访问收口到 `fw_io` 对象后，这些 dump 代码要么改写为调用 `kbase_csf_fw_io_*_read()`，要么继续裸访问（但 `kbase_device` 内布局已变，取页指针的路径也变了）。

**注意 `fw_io_no_mali.c` 的存在**：r56p0 支持 `CONFIG_MALI_NO_MALI`（纯固件模拟、无真实 GPU），因此把这层做成可替换实现。对 K80U 实际编译无关（走 `fw_io.c`），但说明这是 ARM 的架构分层，不是可选优化。

---

## KB-021 — 门铃验证机制（db_validation）整体删除

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-021 |
| **r49p1** | `csf/mali_kbase_csf_db_validation.c`（405 行）、`.h`（85）、`_test.c`（321）、`mali_kbase_csf_db_irq_types.h`（65）、`mali_kbase_csf_db_valid_defs.h`（32）、`mali_kbase_csf_db_irq_valid_ring_queue.h`（23） |
| **r56p0** | 6 个文件全部不存在 |
| **调用点（r49p1）** | `csf/mali_kbase_csf_csg.c:31,582,592`；`csf/mali_kbase_csf_firmware.c:45,1775,1796,1817,1856,2006,2863,3148,3169` |
| **差异类型** | 删除（共 931 行） |
| **影响 ABI** | 否 |
| **影响 MTK** | 是（MTK whitebox 依赖） |
| **严重程度** | **P2** |
| **证据等级** | **实证** |

### r49p1 的使用方式

在门铃写入前后校验状态一致性，共 9 个校验点：

```c
/* csg.c:582 */
kbase_csf_db_valid_pend_event(DOORBELL_CSG_STATUS_UPDATE(csg_nr));
/* csg.c:592 */
kbase_csf_db_valid_flush_pending_events();
/* firmware.c:1775 等 */
kbase_csf_db_valid_push_event(DOORBELL_GLB_CFG_ALLOC_EN);
kbase_csf_db_valid_push_event(DOORBELL_GLB_CFG_PWROFF_TIMER);
kbase_csf_db_valid_push_event(DOORBELL_GLB_CFG_PROGRESS_TIMER);
kbase_csf_db_valid_push_event(DOORBELL_GLB_IDLE_ENABLE);
kbase_csf_db_valid_push_event(DOORBELL_GLB_DEBUG_CSF_REQ);
kbase_csf_db_valid_push_event(DOORBELL_GLB_PING);
/* firmware.c:2863 */
kbase_csf_db_valid_reset(kbdev);
```

**性质**：这是 ARM 的内部**调试**机制（`_test.c` 320 行是 KUTF 单元测试），不是生产路径的必要组件。删除它本身不损失功能。

**但对 MTK 有连带影响**：`mali_kbase_csf_db_validation.c` 里有 2 处 `CONFIG_MALI_MTK_WHITEBOX_MISSING_DOORBELL`（该开关全树 81 处）。MTK 的"门铃丢失"检测挂在这个调试框架上，框架没了，检测点也无处安放。

→ 移植时 MTK 的 missing-doorbell whitebox 需要**重新找挂载点**，不能在原位置恢复。

---

## KB-022 — GPU 重置路径重构：`reset_gpu.c` 从 1,176 行压到 686 行，MTK 注入全数消失

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-022 |
| **r49p1** | `csf/mali_kbase_csf_reset_gpu.c:829-864`（`gpu_reset_entry_name[]`）、`:866-870`、`:893-897`、`:899-926`（`__kbase_prepare_to_reset_gpu` 包装） |
| **r56p0** | `csf/mali_kbase_csf_reset_gpu.c:558-696`（重构后的 reset API） |
| **差异类型** | 重构 + 删除 |
| **影响 ABI** | 否 |
| **影响 MTK** | **是（P0 级）** |
| **严重程度** | **P0** |
| **证据等级** | **实证** |

### 被删除的 r49p1 函数

| 函数 | r49p1 行号 | r56p0 |
| --- | ---: | --- |
| `kbase_is_register_accessible(u32 offset)` | 248 | **不存在** |
| `kbase_reg_read_directly(kbdev, offset)` | 261 | **不存在** |
| `kbase_mcu_state_to_string()` / `kbase_l2_core_state_to_string()` | 289-290 | **不存在** |
| `__kbase_prepare_to_reset_gpu()` | 867 | **不存在** |
| `kbase_prepare_to_reset_gpu_ext()`（带 file/func） | 900 | **不存在** |
| `__kbase_prepare_to_reset_gpu_locked()` | 929 | **不存在** |
| `gpu_reset_entry_name[]`（23 项字符串表） | 830-861 | **不存在** |

### r56p0 新增的重置 API

```
kbase_reset_gpu()                  :581
kbase_reset_gpu_silent()           :598
kbase_reset_gpu_is_active()        :615
kbase_reset_gpu_is_not_pending()   :626
kbase_reset_gpu_wait()             :631
kbase_reset_gpu_init()             :669
kbase_reset_gpu_term()             :683
```

职责被拆细，`prepare_to_reset` 的多个变体合并为单一 `kbase_prepare_to_reset_gpu()`（`:558`）。

### MTK 注入的具体内容（r49p1:829-864）

```c
#if IS_ENABLED(CONFIG_MALI_MTK_GPU_RESET_DEBUG)
char *gpu_reset_entry_name[] = {
	"kbasep_ioctl_internal_fence_wait", //0     ← MTK 私有 ioctl
	"kcpu_fence_timeout_dump",          //1
	"wait_mcu_as_inactive",             //2
	"kbase_pm_timed_out",               //3
	...
	"kbase_gpueb_irq_handler",          //19    ← MTK 专有 IRQ
	...
	"apply_hw_issue_GPU2019_3901_wa",   //23
};
#endif /* CONFIG_MALI_MTK_GPU_RESET_DEBUG */
```

`CONFIG_MALI_MTK_GPU_RESET_DEBUG` 在本文件出现 **20 次**（4 组 `#if` 块）。机制是：MTK 在每次可能触发 reset 的调用点传入一个**索引**，重置发生时把索引翻译成函数名打日志，用于定位"谁触发了 reset"。

`kbase_prepare_to_reset_gpu_ext(kbdev, flags, __FILE__, __func__)`（`:900`）是这个机制的核心——它把调用者文件/函数名带进 reset 流程。

**r56p0 完全没有这套东西**：既无 `_ext` 版本，也无索引表，更无 `__kbase_prepare_to_reset_gpu` 包装。

### 为什么是 P0

MTK 的 reset 调试是**量产机上排查 GPU hang 的主要手段**。K80U 的 `mtk_platform_whitebox_force_hard_reset.c` / `whitebox_fault_worker.c` 依赖它。换 r56p0 后：

1. 所有 `kbase_prepare_to_reset_gpu_ext(...)` 调用点编译失败（函数不存在）
2. 强行改成 `kbase_prepare_to_reset_gpu(...)` 则丢失调用者信息，hang 排查能力归零
3. `gpu_reset_entry_name[]` 里的索引必须重新映射到 r56p0 的新调用点

→ **必须重写**，不能搬运。

---

## KB-023 — MTK 专有 GPUEB 中断处理 `kbase_gpueb_irq_handler` 完全消失

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-023 |
| **r49p1** | `csf/mali_kbase_csf_reset_gpu.c:1077-1110`（`static irqreturn_t kbase_gpueb_irq_handler(int irq, void *data)`） |
| **r56p0** | 全树零命中（`kbase_gpueb_irq_handler` / `gpueb_irq`） |
| **差异类型** | 删除 |
| **影响 ABI** | 否 |
| **影响 MTK** | **是（P0）** |
| **严重程度** | **P0** |
| **证据等级** | **实证** |

### r49p1 的处理逻辑

函数对两类硬件异常计数并打日志：

```c
/* :1084 */
dev_err(kbdev->dev, "kbase_gpueb_irq_handler: ++LOW_VOLT[%llu] BRCAST_TIMEOUT[%llu]", ...);
/* :1093 */
dev_err(kbdev->dev, "kbase_gpueb_irq_handler: LOW_VOLT[%llu] ++BRCAST_TIMEOUT[%llu]", ...);
```

- `LOW_VOLT`：GPUEB 报告的低压事件
- `BRCAST_TIMEOUT`：广播超时

这与 `01_original_baseline/gpu_dependency_map.md` §6 记录的 kbase↔GPUEB 交互（`gpueb_get_mbox1_irq` / `gpueb_clr_mbox1_irq`，见 `csf/mali_kbase_csf_reset_gpu.c:1081,1112,1114`）是同一处代码。

**r56p0 没有等价物**。GPUEB 是 MT6991 独有的协处理器，ARM 上游不可能有。

→ 移植时该 IRQ handler 必须**整段重写**，并重新找到在 r56p0 reset 流程中的挂载点。

---

## KB-024 — 新增 NX 调试接口 `csf_nx_debugfs`

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-024 |
| **r49p1** | 不存在 |
| **r56p0** | `csf/mali_kbase_csf_nx_debugfs.c:1-238`、`.h:1-34` |
| **差异类型** | 新增 |
| **影响 ABI** | 否 |
| **影响 MTK** | 否 |
| **严重程度** | **P3** |
| **证据等级** | **实证** |

新增 debugfs 节点。`NX` 推测为 "Nested eXecution" 或新一代固件特性代号（**UNKNOWN**，源码内无展开说明）。因是纯 debugfs 接口，不影响功能路径。

---

## KB-025 — KCPU 队列实现精简 493 行

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-025 |
| **r49p1** | `csf/mali_kbase_csf_kcpu.c`（3,459 行） |
| **r56p0** | `csf/mali_kbase_csf_kcpu.c`（2,966 行） |
| **差异类型** | 重构（精简） |
| **影响 ABI** | 间接（KCPU 队列是 UAPI 的一部分，但 ioctl 定义未变） |
| **影响 MTK** | **是（重度）** |
| **严重程度** | **P1** |
| **证据等级** | 实证（行数）+ 推断（内部重构细节） |

**MTK 在 kcpu.c 注入 171 处**（仅次于 scheduler），涉及开关：

```
CONFIG_MALI_MTK_CREATE_KCPU_QUEUE_DEBUG   (12)
CONFIG_MALI_MTK_CROSS_QUEUE_SYNC_RECOVERY (6)
CONFIG_MALI_MTK_FENCE_DEBUG               (52)
CONFIG_MALI_MTK_USE_WORKQUEUE_FOR_CSF_SCHEDULE (92)
```

`FENCE_DEBUG` 与 `CROSS_QUEUE_SYNC` 都是 MTK 在 KCPU 队列上的定制（跨队列同步恢复是 MTK 的调度增强）。

r56p0 精简 493 行后，这些挂载点全部失效。

> **UNKNOWN**：未逐函数比对 kcpu.c，无法给出"具体哪个函数被删"。仅能从行数与 MTK 注入密度判断影响面大。建议移植前单独做 kcpu.c 的函数级 diff。

---

## KB-026 — 调度器重构：`api_sync_*` 系列移除，新增页延迟控制

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-026 |
| **r49p1** | `csf/mali_kbase_csf_scheduler.c`（8,194 行） |
| **r56p0** | `csf/mali_kbase_csf_scheduler.c`（8,745 行，+551） |
| **差异类型** | 重构 |
| **影响 ABI** | 否 |
| **影响 MTK** | **是（重度）** |
| **严重程度** | **P1** |
| **证据等级** | **实证**（函数集差）+ 推断（语义） |

### 新增函数（r56p0）

```
kbase_csf_scheduler_kcpuq_kthread()
kbase_csf_scheduler_pages_defer_ctrl_init/term()
kbase_csf_scheduler_protm_pages_defer_worker()
kbase_csf_scheduler_protm_pages_defer_has_pools()
kbase_csf_scheduler_protm_free_deferred_imported_bufs()
prepare_all_csg_suspension()
process_cs_pending_events()
save_cs_wait_state()
handle_tiler_oom_request_on_cs_resume()
check_sync_update_for_all_on_slot_groups()
enable_all_csg_slots_status_change_irq()
```

### 删除函数（r49p1 有、r56p0 无）

```
api_sync_change_pm_policy()
api_sync_timer_callback()
refine_api_sync_flag()
update_api_sync_flag()
apo_idle_timer_callback()
scheduler_suspend_on_idle()
save_slot_cs()
wait_for_mcu_sleep_after_idle_stress_test()
```

### 两处关键判断

**（1）`api_sync_*` 被删，而 MTK 有 `CONFIG_MALI_MTK_API_SYNC_UPDATE`（4 处）**

MTK 定制了 API sync 更新逻辑（`mtk_platform_whitebox_sync_update.c`）。r56p0 把 `api_sync_*` 整组函数移除或并入其他路径，MTK 的定制点**必须重新定位**。

**（2）新增 `protm_pages_defer_*` 表明受保护模式（Protected Mode）的页管理改为延迟释放**

`protm` = Protected Mode。r56p0 引入"页延迟回收"（defer），说明受保护模式进入/退出的内存生命周期管理变了。K80U 的 DRM 播放场景会走 protected mode，这条路径需要重点回归。

### 线程模型

| | r49p1 | r56p0 |
| --- | ---: | ---: |
| `kthread_run` / `kthread_create` | 6 | **13** |
| workqueue 相关 | 4 | 5 |

r56p0 的 kthread 数量翻倍（新增 kcpuq 专用线程、pages_defer worker）。**MTK 的 `CONFIG_MALI_MTK_USE_WORKQUEUE_FOR_CSF_SCHEDULE`（92 处）正好是把 kthread 换成 workqueue 的补丁**——r56p0 反而增加了 kthread，两者方向相反。

→ MTK 的 workqueue 调度补丁在 r56p0 上**无法直接套用**，需要按新的线程模型重做。

---

## KB-027 — CSF 固件加载路径基本不变

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-027 |
| **r49p1** | `csf/mali_kbase_csf_firmware.c:2735`（`request_firmware(&firmware, fw_name, kbdev->dev)`）、`:84`（`default_fw_name = "mali_csffw.bin"`） |
| **r56p0** | 同文件 `:2660`（`request_firmware`）、`:61`（`default_fw_name = "mali_csffw.bin"`） |
| **差异类型** | 无实质变化（仅行号位移） |
| **影响 ABI** | 否 |
| **影响 MTK** | 否 |
| **严重程度** | **P3** |
| **证据等级** | **实证** |

固件文件名、加载 API、错误处理流程一致。**这是本次审计中少数几个"真的没变"的地方**。

但要注意：文件名不变 ≠ 固件二进制不变。r56p0 需要匹配 R56 固件 ABI 的 `mali_csffw.bin`，而 K80U 出厂固件是为 r49p1 编译的。**固件与内核驱动必须成对**——这是 `05_userspace_firmware` 的关键未决项（该固件在所有已获取仓库中零命中，见 `source_integrity.md` M2）。

---

## KB-028 — MTK 对 CSF 核心的注入面：30/66 文件、39 个开关、约 900 处引用

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-028 |
| **r49p1** | `csf/` 目录 30 个文件含 `CONFIG_MALI_MTK_*` / `mtk_platform_*` / `ged_*` / `gpufreq_*` |
| **r56p0** | 0（结构上不含任何 MTK 代码） |
| **差异类型** | 结构差异 |
| **影响 ABI** | 否 |
| **影响 MTK** | **是（决定移植工作量）** |
| **严重程度** | **P0** |
| **证据等级** | **实证** |

### 按文件排序（处数 = 含 MTK 符号的行数）

| 文件 | 处数 | 主要开关 |
| --- | ---: | --- |
| `mali_kbase_csf_scheduler.c` | **308** | ADAPTIVE_POWER_POLICY, API_SYNC_UPDATE, USE_WORKQUEUE_FOR_CSF_SCHEDULE |
| `mali_kbase_csf_kcpu.c` | **171** | CREATE_KCPU_QUEUE_DEBUG, CROSS_QUEUE_SYNC, FENCE_DEBUG |
| `mali_kbase_csf.c` | **154** | ACP_FORCE_SYNC_DEBUG, ADAPTIVE_POWER_POLICY |
| `mali_kbase_csf_firmware.c` | **119** | ACP_FORCE_SYNC_DEBUG, COMMON, RESET_RELOAD_ON_FW |
| `mali_kbase_csf_reset_gpu.c` | **108** | GPU_RESET_DEBUG, DEFERRED_LOGGING, DEBUG_DUMP |
| `mali_kbase_csf_defs.h` | 35 | 结构体字段级注入 |
| `mali_kbase_csf_ipa_control.c` | 30 | DVFS_POLICY, GPU_DVFS_HINT_26M_LOADING |
| `mali_kbase_csf_cpu_queue.c` | 26 | CPUQ_DUMP_ENHANCEMENT, DEBUG_DUMP |
| `mali_kbase_csf_trace_buffer.c` | 18 | CSG_ERROR_HANDLING, KE_DUMP_FWLOG |
| `mali_kbase_csf_scheduler.h` | 15 | KBASE_THREAD_DEBUG |
| `mali_kbase_csf_util.c` | 14 | COMMON, DEFERRED_LOGGING |
| `mali_kbase_csf_mcu_shared_reg.c` | 14 | ACP_FORCE_SYNC_DEBUG, MBRAIN_SUPPORT |
| 其余 18 个文件 | 1–8 | 分散 |

### 开关总量 Top 10

| 开关 | 出现次数 | 含义 |
| --- | ---: | --- |
| `CONFIG_MALI_MTK_LOG_BUFFER` | 172 | 内核日志环形缓冲 |
| `CONFIG_MALI_MTK_USE_WORKQUEUE_FOR_CSF_SCHEDULE` | 92 | **把 CSF 调度线程改 workqueue** |
| `CONFIG_MALI_MTK_DEBUG_DUMP` | 91 | 故障现场转储 |
| `CONFIG_MALI_MTK_WHITEBOX_MISSING_DOORBELL` | 81 | 门铃丢失检测 |
| `CONFIG_MALI_MTK_MBRAIN_SUPPORT` | 76 | MTK 自研调度/功耗协同 |
| `CONFIG_MALI_MTK_FENCE_DEBUG` | 52 | fence 追踪 |
| `CONFIG_MALI_MTK_DEFERRED_LOGGING` | 52 | 延迟日志 |
| `CONFIG_MALI_MTK_KBASE_THREAD_DEBUG` | 50 | 线程调试 |
| `CONFIG_MALI_MTK_CPUQ_DUMP_ENHANCEMENT` | 28 | CPU 队列转储增强 |
| `CONFIG_MALI_MTK_ADAPTIVE_POWER_POLICY` | 25 | 自适应功耗策略 |

全部 **39 个开关**，此处不逐一列出。

### 判读

MTK 不是在 CSF 核心"打补丁"，而是**重写了将近一半的核心文件**。以 `scheduler.c` 为例：308 处注入分布在 8,194 行里，平均每 27 行一处。

这决定了移植策略：**不能"换掉 ARM 层保留 MTK 层"**——MTK 层是**长在 ARM 层里面的**，不是并列关系。详见 `06_blocking_issues.md` Q5 的结论。

---

## 1. CSF 文件集合差异明细

### 1.1 r49p1 独有（r56p0 已删，6 个文件 931 行）

```
mali_kbase_csf_db_validation.c              405
mali_kbase_csf_db_validation_test.c         321
mali_kbase_csf_db_validation.h               85
mali_kbase_csf_db_irq_types.h                65
mali_kbase_csf_db_valid_defs.h               32
mali_kbase_csf_db_irq_valid_ring_queue.h     23
```

### 1.2 r56p0 独有（6 个文件 1,680 行）

```
mali_kbase_csf_fw_io.h                      512
mali_kbase_csf_fw_io_no_mali.c              445
mali_kbase_csf_fw_io.c                      413
mali_kbase_csf_nx_debugfs.c                 238
mali_kbase_csf_nx_debugfs.h                  34
mali_kbase_csf_mem_flags.h                   38
```

---

## 2. 保持不变的部分（同样重要）

以下文件两版**行数完全一致**，可视为无变化：

| 文件 | 行数 |
| --- | ---: |
| `mali_kbase_csf_timeout.c` / `.h` | 183 / 66 |
| `mali_kbase_csf_protected_memory.c` / `.h` | 155 / 71 |
| `mali_kbase_debug_csf_fault.c` / `.h` | 277 / 138 |
| `mali_kbase_csf_event.h` | 170 |
| `mali_kbase_csf_kcpu_debugfs.c` / `.h` | 183 / 37 |
| `mali_kbase_csf_tiler_heap_debugfs.c` / `.h` | 164 / 44 |
| `mali_kbase_csf_sync.h` | 51 |

**`mali_kbase_csf_timeout.c` 未变**值得注意：超时框架没动，说明 KB-022 的 reset 重构不是由超时机制驱动的。

---

## 3. 本文件的结论

1. **CSF 层整体是"重构 + 换血"，不是增量修改**。文件数巧合相同，但 6 个进、6 个出，内部变动 4.3 万行。

2. **两处 P0 断点都集中在 reset 路径**：
   - KB-022：`kbase_prepare_to_reset_gpu_ext()` 与 `gpu_reset_entry_name[]` 消失，MTK 的 reset 归因能力归零
   - KB-023：`kbase_gpueb_irq_handler` 消失，GPUEB 的低压/广播超时中断无人接管

3. **一处 P1 架构变更影响所有 MTK 转储工具**：KB-020 的 `fw_io` 把共享内存访问收口，MTK 的 11 个 debug_dump 文件需要改写。

4. **调度模型方向相反**：MTK 把 kthread 改 workqueue（92 处），r56p0 反而增加 kthread（6→13）。KB-026 的两个新增 `protm_pages_defer_*` 函数说明受保护模式的内存生命周期也变了。

5. **固件加载路径是少数没变的地方**（KB-027），但固件二进制本身必须与驱动配对，这是 `05_userspace_firmware` 的未决项。

6. **MTK 注入密度决定移植方式**（KB-028）：`csf/` 有 30/66 文件、39 个开关、约 900 处引用。MTK 代码是**嵌在 ARM 代码内部**的，不存在"只换 ARM 层"的干净切面。
