# GPU 文件路径总清单（TASK 01-B 附录）

> 生成方式：脚本遍历已落盘文件 / `git ls-tree` 清单，非人工手写。
> 生成日期：2026-11-15
> 路径口径：**仓库内相对路径**，仓库对应关系见各节头部。

## 统计

| 分类 | 仓库 | 文件数 | 性质 |
| --- | --- | ---: | --- |
| A. ARM Kbase 核心驱动 | R2 `MTK_kernel_modules` | 581 | 源码 |
| A′. Mali 驱动副本 | R3 `MTK_kernel_device_modules` | 1,174 | 源码（r47p0 613 无关 + r49p1 559 为 A 的子集） |
| B. MTK GPU 平台适配 | R3 `drivers/gpu/mediatek/` | 188 | 源码 |
| B2. 功耗限流 | R3 `drivers/misc/mediatek/power_throttling/` | 23 | 源码 |
| C. 设备树 + 配置 | R3 `arch/` `kernel/` | 13 | 源码 |
| D. 预编译二进制 | R5 `android_device_xiaomi_dali-kernel` | 15 `.ko` + 1 `.dtb` + 4 `.load` | **二进制** |
| — | — | **清单 1,996 行 / 对应 2,016 个文件** | — |

## 图例

- 类型：`C`=.c 源码，`H`=.h 头文件，`MK`=Makefile/Kbuild/Kconfig，`ETC`=其他文本
- `G925` 列：`Y`=源码级直接确认 G925，`O`=处于 G925 运行路径但不标识型号，`-`=无关/未编译
- `MT6991` 列：`Y`=MT6991 专属，`共用`=多平台共用，`-`=非平台代码

---



## A. ARM Kbase 核心驱动源码 — R2 `mali-r49p1`（581 个文件）

仓库：`MiCode/MTK_kernel_modules` @ `fe0fa7ff`，本地 `01_original_baseline/mtk_kernel_modules/`

前缀：`gpu/gpu_mali/mali_avalon/mali-r49p1/`

| # | 相对路径 | 类型 | 组件 | G925 | 字节 |
| ---: | --- | :--: | --- | :--: | ---: |
| 1 | `drivers/base/arm/Kbuild` | MK | ARM-base | O | 1189 |
| 2 | `drivers/base/arm/Kconfig` | MK | ARM-base | O | 2165 |
| 3 | `drivers/base/arm/Makefile` | MK | ARM-base | O | 5529 |
| 4 | `drivers/base/arm/Mconfig` | ETC | ARM-base | O | 2151 |
| 5 | `drivers/base/arm/dma_buf_test_exporter/Kbuild.bak` | MK | ARM-base | O | 892 |
| 6 | `drivers/base/arm/dma_buf_test_exporter/Makefile` | MK | ARM-base | O | 1265 |
| 7 | `drivers/base/arm/dma_buf_test_exporter/build.bp` | ETC | ARM-base | O | 1165 |
| 8 | `drivers/base/arm/dma_buf_test_exporter/dma-buf-test-exporter.c` | C | ARM-base | O | 21009 |
| 9 | `drivers/base/arm/memory_group_manager/Kbuild.bak` | MK | MGM | O | 879 |
| 10 | `drivers/base/arm/memory_group_manager/Makefile` | MK | MGM | O | 2672 |
| 11 | `drivers/base/arm/memory_group_manager/build.bp` | ETC | MGM | O | 1145 |
| 12 | `drivers/base/arm/memory_group_manager/init.mali_mgm.rc` | ETC | MGM | O | 316 |
| 13 | `drivers/base/arm/memory_group_manager/memory_group_manager.c` | C | MGM | O | 42735 |
| 14 | `drivers/base/arm/memory_group_manager/mtk_platform_utils.h` | H | MGM | O | 386 |
| 15 | `drivers/base/arm/protected_memory_allocator/Kbuild.bak` | MK | PMA | O | 891 |
| 16 | `drivers/base/arm/protected_memory_allocator/Makefile` | MK | PMA | O | 3258 |
| 17 | `drivers/base/arm/protected_memory_allocator/build.bp` | ETC | PMA | O | 1169 |
| 18 | `drivers/base/arm/protected_memory_allocator/init.mali_prot_alloc.rc` | ETC | PMA | O | 356 |
| 19 | `drivers/base/arm/protected_memory_allocator/protected_memory_allocator.c` | C | PMA | O | 36089 |
| 20 | `drivers/gpu/arm/Kbuild` | MK | other | O | 840 |
| 21 | `drivers/gpu/arm/Kconfig` | MK | other | O | 899 |
| 22 | `drivers/gpu/arm/Makefile` | MK | other | O | 880 |
| 23 | `drivers/gpu/arm/midgard/Kbuild-mtk-custom-env` | MK | kbase-core | O | 20224 |
| 24 | `drivers/gpu/arm/midgard/Kbuild.bak` | MK | kbase-core | O | 6981 |
| 25 | `drivers/gpu/arm/midgard/Kconfig` | MK | kbase-core | O | 12488 |
| 26 | `drivers/gpu/arm/midgard/Makefile` | MK | kbase-core | O | 26351 |
| 27 | `drivers/gpu/arm/midgard/Mconfig` | ETC | kbase-core | O | 11880 |
| 28 | `drivers/gpu/arm/midgard/arbiter/Kbuild` | MK | kbase-arbiter | O | 883 |
| 29 | `drivers/gpu/arm/midgard/arbiter/mali_kbase_arbif.c` | C | kbase-arbiter | O | 10266 |
| 30 | `drivers/gpu/arm/midgard/arbiter/mali_kbase_arbif.h` | H | kbase-arbiter | O | 4434 |
| 31 | `drivers/gpu/arm/midgard/arbiter/mali_kbase_arbiter_defs.h` | H | kbase-arbiter | O | 2896 |
| 32 | `drivers/gpu/arm/midgard/arbiter/mali_kbase_arbiter_pm.c` | C | kbase-arbiter | O | 35083 |
| 33 | `drivers/gpu/arm/midgard/arbiter/mali_kbase_arbiter_pm.h` | H | kbase-arbiter | O | 7691 |
| 34 | `drivers/gpu/arm/midgard/backend/gpu/Kbuild` | MK | kbase-backend | O | 2030 |
| 35 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_cache_policy_backend.c` | C | kbase-backend | O | 2229 |
| 36 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_cache_policy_backend.h` | H | kbase-backend | O | 1575 |
| 37 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_clk_rate_trace_mgr.c` | C | kbase-backend | O | 8853 |
| 38 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_clk_rate_trace_mgr.h` | H | kbase-backend | O | 4945 |
| 39 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_debug_job_fault_backend.c` | C | kbase-backend | O | 5247 |
| 40 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_defs.h` | H | kbase-backend | O | 4579 |
| 41 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_devfreq.c` | C | kbase-backend | O | 22382 |
| 42 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_devfreq.h` | H | kbase-backend | O | 2671 |
| 43 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_gpuprops_backend.c` | C | kbase-backend | O | 6523 |
| 44 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_instr_backend.c` | C | kbase-backend | O | 14319 |
| 45 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_instr_defs.h` | H | kbase-backend | O | 1855 |
| 46 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_instr_internal.h` | H | kbase-backend | O | 1334 |
| 47 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_irq_internal.h` | H | kbase-backend | O | 3467 |
| 48 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_irq_linux.c` | C | kbase-backend | O | 13088 |
| 49 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_as.c` | C | kbase-backend | O | 6769 |
| 50 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_hw.c` | C | kbase-backend | O | 41882 |
| 51 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_internal.h` | H | kbase-backend | O | 4670 |
| 52 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_rb.c` | C | kbase-backend | O | 58682 |
| 53 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_rb.h` | H | kbase-backend | O | 2710 |
| 54 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_js_backend.c` | C | kbase-backend | O | 13400 |
| 55 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_js_internal.h` | H | kbase-backend | O | 2350 |
| 56 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_l2_mmu_config.c` | C | kbase-backend | O | 4174 |
| 57 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_l2_mmu_config.h` | H | kbase-backend | O | 1329 |
| 58 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_model_dummy.c` | C | kbase-backend | O | 67566 |
| 59 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_model_dummy.h` | H | kbase-backend | O | 6836 |
| 60 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_model_linux.c` | C | kbase-backend | O | 4853 |
| 61 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_model_linux.h` | H | kbase-backend | O | 3882 |
| 62 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_always_on.c` | C | kbase-backend | O | 2005 |
| 63 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_always_on.h` | H | kbase-backend | O | 2664 |
| 64 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_backend.c` | C | kbase-backend | O | 41344 |
| 65 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_ca.c` | C | kbase-backend | O | 4795 |
| 66 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_ca.h` | H | kbase-backend | O | 3227 |
| 67 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_ca_devfreq.h` | H | kbase-backend | O | 1912 |
| 68 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_coarse_demand.c` | C | kbase-backend | O | 1956 |
| 69 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_coarse_demand.h` | H | kbase-backend | O | 2364 |
| 70 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_defs.h` | H | kbase-backend | O | 32186 |
| 71 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_driver.c` | C | kbase-backend | O | 146883 |
| 72 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_internal.h` | H | kbase-backend | O | 40647 |
| 73 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_l2_states.h` | H | kbase-backend | O | 2186 |
| 74 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_mcu_states.h` | H | kbase-backend | O | 6217 |
| 75 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_metrics.c` | C | kbase-backend | O | 23525 |
| 76 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_policy.c` | C | kbase-backend | O | 14286 |
| 77 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_policy.h` | H | kbase-backend | O | 3429 |
| 78 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_shader_states.h` | H | kbase-backend | O | 4233 |
| 79 | `drivers/gpu/arm/midgard/backend/gpu/mali_kbase_time.c` | C | kbase-backend | O | 15957 |
| 80 | `drivers/gpu/arm/midgard/build.bp` | ETC | kbase-core | O | 8357 |
| 81 | `drivers/gpu/arm/midgard/context/Kbuild` | MK | kbase-context | O | 1031 |
| 82 | `drivers/gpu/arm/midgard/context/backend/mali_kbase_context_csf.c` | C | kbase-context | O | 7255 |
| 83 | `drivers/gpu/arm/midgard/context/backend/mali_kbase_context_jm.c` | C | kbase-context | O | 8541 |
| 84 | `drivers/gpu/arm/midgard/context/mali_kbase_context.c` | C | kbase-context | O | 11285 |
| 85 | `drivers/gpu/arm/midgard/context/mali_kbase_context.h` | H | kbase-context | O | 4554 |
| 86 | `drivers/gpu/arm/midgard/context/mali_kbase_context_internal.h` | H | kbase-context | O | 2258 |
| 87 | `drivers/gpu/arm/midgard/csf/Kbuild` | MK | kbase-CSF | O | 2463 |
| 88 | `drivers/gpu/arm/midgard/csf/ipa_control/Kbuild` | MK | kbase-CSF | O | 862 |
| 89 | `drivers/gpu/arm/midgard/csf/ipa_control/mali_kbase_csf_ipa_control.c` | C | kbase-CSF | O | 33614 |
| 90 | `drivers/gpu/arm/midgard/csf/ipa_control/mali_kbase_csf_ipa_control.h` | H | kbase-CSF | O | 11150 |
| 91 | `drivers/gpu/arm/midgard/csf/ipa_control/mali_kbase_csf_ipa_control_ex.h` | H | kbase-CSF | O | 724 |
| 92 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf.c` | C | kbase-CSF | O | 138694 |
| 93 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf.h` | H | kbase-CSF | O | 21761 |
| 94 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_cpu_queue.c` | C | kbase-CSF | O | 6246 |
| 95 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_cpu_queue.h` | H | kbase-CSF | O | 3267 |
| 96 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_cpu_queue_debugfs.c` | C | kbase-CSF | O | 2545 |
| 97 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_cpu_queue_debugfs.h` | H | kbase-CSF | O | 1233 |
| 98 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_csg.c` | C | kbase-CSF | O | 23475 |
| 99 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_csg.h` | H | kbase-CSF | O | 1874 |
| 100 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_csg_debugfs.c` | C | kbase-CSF | O | 12217 |
| 101 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_csg_debugfs.h` | H | kbase-CSF | O | 1433 |
| 102 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_db_irq_types.h` | H | kbase-CSF | O | 2973 |
| 103 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_db_irq_valid_ring_queue.h` | H | kbase-CSF | O | 787 |
| 104 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_db_valid_defs.h` | H | kbase-CSF | O | 883 |
| 105 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_db_validation.c` | C | kbase-CSF | O | 10155 |
| 106 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_db_validation.h` | H | kbase-CSF | O | 2014 |
| 107 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_db_validation_test.c` | C | kbase-CSF | O | 9375 |
| 108 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_defs.h` | H | kbase-CSF | O | 88835 |
| 109 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_event.c` | C | kbase-CSF | O | 8500 |
| 110 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_event.h` | H | kbase-CSF | O | 6149 |
| 111 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware.c` | C | kbase-CSF | O | 122334 |
| 112 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware.h` | H | kbase-CSF | O | 37007 |
| 113 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_cfg.c` | C | kbase-CSF | O | 12609 |
| 114 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_cfg.h` | H | kbase-CSF | O | 3790 |
| 115 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_core_dump.c` | C | kbase-CSF | O | 25597 |
| 116 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_core_dump.h` | H | kbase-CSF | O | 2450 |
| 117 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_log.c` | C | kbase-CSF | O | 21897 |
| 118 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_log.h` | H | kbase-CSF | O | 2554 |
| 119 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_no_mali.c` | C | kbase-CSF | O | 52106 |
| 120 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_heap_context_alloc.c` | C | kbase-CSF | O | 7605 |
| 121 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_heap_context_alloc.h` | H | kbase-CSF | O | 2854 |
| 122 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu.c` | C | kbase-CSF | O | 115625 |
| 123 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu.h` | H | kbase-CSF | O | 16674 |
| 124 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu_debugfs.c` | C | kbase-CSF | O | 5373 |
| 125 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu_debugfs.h` | H | kbase-CSF | O | 1236 |
| 126 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu_fence_debugfs.c` | C | kbase-CSF | O | 4567 |
| 127 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu_fence_debugfs.h` | H | kbase-CSF | O | 1495 |
| 128 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_mcu_shared_reg.c` | C | kbase-CSF | O | 30434 |
| 129 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_mcu_shared_reg.h` | H | kbase-CSF | O | 6123 |
| 130 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_protected_memory.c` | C | kbase-CSF | O | 4463 |
| 131 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_protected_memory.h` | H | kbase-CSF | O | 2519 |
| 132 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_registers.h` | H | kbase-CSF | O | 108653 |
| 133 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_reset_gpu.c` | C | kbase-CSF | O | 43626 |
| 134 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_scheduler.c` | C | kbase-CSF | O | 293476 |
| 135 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_scheduler.h` | H | kbase-CSF | O | 27231 |
| 136 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_sync.c` | C | kbase-CSF | O | 29442 |
| 137 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_sync.h` | H | kbase-CSF | O | 1599 |
| 138 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_sync_debugfs.c` | C | kbase-CSF | O | 2657 |
| 139 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_sync_debugfs.h` | H | kbase-CSF | O | 1203 |
| 140 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap.c` | C | kbase-CSF | O | 45278 |
| 141 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap.h` | H | kbase-CSF | O | 6630 |
| 142 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_debugfs.c` | C | kbase-CSF | O | 5101 |
| 143 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_debugfs.h` | H | kbase-CSF | O | 1528 |
| 144 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_def.h` | H | kbase-CSF | O | 5835 |
| 145 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_reclaim.c` | C | kbase-CSF | O | 14129 |
| 146 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_reclaim.h` | H | kbase-CSF | O | 3200 |
| 147 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_timeout.c` | C | kbase-CSF | O | 5407 |
| 148 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_timeout.h` | H | kbase-CSF | O | 2397 |
| 149 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_tl_reader.c` | C | kbase-CSF | O | 11831 |
| 150 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_tl_reader.h` | H | kbase-CSF | O | 4868 |
| 151 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_trace_buffer.c` | C | kbase-CSF | O | 26058 |
| 152 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_trace_buffer.h` | H | kbase-CSF | O | 8235 |
| 153 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_util.c` | C | kbase-CSF | O | 7183 |
| 154 | `drivers/gpu/arm/midgard/csf/mali_kbase_csf_util.h` | H | kbase-CSF | O | 3279 |
| 155 | `drivers/gpu/arm/midgard/csf/mali_kbase_debug_csf_fault.c` | C | kbase-CSF | O | 7276 |
| 156 | `drivers/gpu/arm/midgard/csf/mali_kbase_debug_csf_fault.h` | H | kbase-CSF | O | 4019 |
| 157 | `drivers/gpu/arm/midgard/debug/Kbuild` | MK | kbase-debug | O | 1108 |
| 158 | `drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_coresight_csf.c` | C | kbase-debug | O | 24935 |
| 159 | `drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_coresight_internal_csf.h` | H | kbase-debug | O | 6897 |
| 160 | `drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_codes_csf.h` | H | kbase-debug | O | 13212 |
| 161 | `drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_codes_jm.h` | H | kbase-debug | O | 8132 |
| 162 | `drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_csf.c` | C | kbase-debug | O | 5869 |
| 163 | `drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_csf.h` | H | kbase-debug | O | 8728 |
| 164 | `drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_defs_csf.h` | H | kbase-debug | O | 4589 |
| 165 | `drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_defs_jm.h` | H | kbase-debug | O | 4197 |
| 166 | `drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_jm.c` | C | kbase-debug | O | 3997 |
| 167 | `drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_jm.h` | H | kbase-debug | O | 15722 |
| 168 | `drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_linux_ktrace_csf.h` | H | kbase-debug | O | 10918 |
| 169 | `drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_linux_ktrace_jm.h` | H | kbase-debug | O | 7442 |
| 170 | `drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace.c` | C | kbase-debug | O | 9665 |
| 171 | `drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace.h` | H | kbase-debug | O | 7587 |
| 172 | `drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace_codes.h` | H | kbase-debug | O | 6446 |
| 173 | `drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace_defs.h` | H | kbase-debug | O | 6349 |
| 174 | `drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace_internal.h` | H | kbase-debug | O | 3340 |
| 175 | `drivers/gpu/arm/midgard/debug/mali_kbase_debug_linux_ktrace.h` | H | kbase-debug | O | 4589 |
| 176 | `drivers/gpu/arm/midgard/device/Kbuild` | MK | kbase-device | O | 1163 |
| 177 | `drivers/gpu/arm/midgard/device/backend/mali_kbase_device_csf.c` | C | kbase-device | O | 18434 |
| 178 | `drivers/gpu/arm/midgard/device/backend/mali_kbase_device_hw_csf.c` | C | kbase-device | O | 10517 |
| 179 | `drivers/gpu/arm/midgard/device/backend/mali_kbase_device_hw_jm.c` | C | kbase-device | O | 4231 |
| 180 | `drivers/gpu/arm/midgard/device/backend/mali_kbase_device_jm.c` | C | kbase-device | O | 11947 |
| 181 | `drivers/gpu/arm/midgard/device/mali_kbase_device.c` | C | kbase-device | O | 17307 |
| 182 | `drivers/gpu/arm/midgard/device/mali_kbase_device.h` | H | kbase-device | O | 7300 |
| 183 | `drivers/gpu/arm/midgard/device/mali_kbase_device_hw.c` | C | kbase-device | O | 12007 |
| 184 | `drivers/gpu/arm/midgard/device/mali_kbase_device_internal.h` | H | kbase-device | O | 3333 |
| 185 | `drivers/gpu/arm/midgard/gpu/Kbuild` | MK | kbase-gpu | O | 1003 |
| 186 | `drivers/gpu/arm/midgard/gpu/backend/mali_kbase_gpu_fault_csf.c` | C | kbase-gpu | O | 5537 |
| 187 | `drivers/gpu/arm/midgard/gpu/backend/mali_kbase_gpu_fault_jm.c` | C | kbase-gpu | O | 3079 |
| 188 | `drivers/gpu/arm/midgard/gpu/mali_kbase_gpu.c` | C | kbase-gpu | O | 1306 |
| 189 | `drivers/gpu/arm/midgard/gpu/mali_kbase_gpu_fault.h` | H | kbase-gpu | O | 1602 |
| 190 | `drivers/gpu/arm/midgard/hw_access/Kbuild` | MK | kbase-hwaccess | O | 1187 |
| 191 | `drivers/gpu/arm/midgard/hw_access/backend/mali_kbase_hw_access_model_linux.c` | C | kbase-hwaccess | O | 4699 |
| 192 | `drivers/gpu/arm/midgard/hw_access/backend/mali_kbase_hw_access_real_hw.c` | C | kbase-hwaccess | O | 4962 |
| 193 | `drivers/gpu/arm/midgard/hw_access/mali_kbase_hw_access.c` | C | kbase-hwaccess | O | 4539 |
| 194 | `drivers/gpu/arm/midgard/hw_access/mali_kbase_hw_access.h` | H | kbase-hwaccess | O | 7961 |
| 195 | `drivers/gpu/arm/midgard/hw_access/mali_kbase_hw_access_regmap.h` | H | kbase-hwaccess | O | 24707 |
| 196 | `drivers/gpu/arm/midgard/hw_access/mali_kbase_hw_access_regmap_legacy.h` | H | kbase-hwaccess | O | 12237 |
| 197 | `drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_csf.c` | C | kbase-hwaccess | O | 91430 |
| 198 | `drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_csf_enums.h` | H | kbase-hwaccess | O | 20308 |
| 199 | `drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_csf_macros.h` | H | kbase-hwaccess | O | 21638 |
| 200 | `drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_jm.c` | C | kbase-hwaccess | O | 197638 |
| 201 | `drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_jm_enums.h` | H | kbase-hwaccess | O | 42666 |
| 202 | `drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_jm_macros.h` | H | kbase-hwaccess | O | 15161 |
| 203 | `drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_legacy_csf.h` | H | kbase-hwaccess | O | 3408 |
| 204 | `drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_legacy_jm.h` | H | kbase-hwaccess | O | 6069 |
| 205 | `drivers/gpu/arm/midgard/hwcnt/Kbuild` | MK | kbase-HWCNT | O | 1322 |
| 206 | `drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend.h` | H | kbase-HWCNT | O | 10379 |
| 207 | `drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf.c` | C | kbase-HWCNT | O | 88355 |
| 208 | `drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf.h` | H | kbase-HWCNT | O | 8991 |
| 209 | `drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf_if.h` | H | kbase-HWCNT | O | 14598 |
| 210 | `drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf_if_fw.c` | C | kbase-HWCNT | O | 29763 |
| 211 | `drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf_if_fw.h` | H | kbase-HWCNT | O | 1868 |
| 212 | `drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_jm.c` | C | kbase-HWCNT | O | 33348 |
| 213 | `drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_jm.h` | H | kbase-HWCNT | O | 1989 |
| 214 | `drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_jm_watchdog.c` | C | kbase-HWCNT | O | 33113 |
| 215 | `drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_jm_watchdog.h` | H | kbase-HWCNT | O | 2836 |
| 216 | `drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt.c` | C | kbase-HWCNT | O | 25636 |
| 217 | `drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_accumulator.h` | H | kbase-HWCNT | O | 5870 |
| 218 | `drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_context.h` | H | kbase-HWCNT | O | 6139 |
| 219 | `drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_gpu.c` | C | kbase-HWCNT | O | 31186 |
| 220 | `drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_gpu.h` | H | kbase-HWCNT | O | 19879 |
| 221 | `drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_types.c` | C | kbase-HWCNT | O | 16204 |
| 222 | `drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_types.h` | H | kbase-HWCNT | O | 50567 |
| 223 | `drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_virtualizer.c` | C | kbase-HWCNT | O | 24351 |
| 224 | `drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_virtualizer.h` | H | kbase-HWCNT | O | 6596 |
| 225 | `drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_watchdog_if.h` | H | kbase-HWCNT | O | 3051 |
| 226 | `drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_watchdog_if_timer.c` | C | kbase-HWCNT | O | 4790 |
| 227 | `drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_watchdog_if_timer.h` | H | kbase-HWCNT | O | 1738 |
| 228 | `drivers/gpu/arm/midgard/include/linux/mali_arbiter_interface.h` | H | kbase-UAPI | O | 7571 |
| 229 | `drivers/gpu/arm/midgard/include/linux/mali_hw_access.h` | H | kbase-UAPI | O | 1729 |
| 230 | `drivers/gpu/arm/midgard/include/linux/mali_kbase_debug_coresight_csf.h` | H | kbase-UAPI | O | 8289 |
| 231 | `drivers/gpu/arm/midgard/include/linux/memory_group_manager.h` | H | kbase-UAPI | O | 9657 |
| 232 | `drivers/gpu/arm/midgard/include/linux/priority_control_manager.h` | H | kbase-UAPI | O | 5478 |
| 233 | `drivers/gpu/arm/midgard/include/linux/protected_memory_allocator.h` | H | kbase-UAPI | O | 4001 |
| 234 | `drivers/gpu/arm/midgard/include/linux/protected_mode_switcher.h` | H | kbase-UAPI | O | 2085 |
| 235 | `drivers/gpu/arm/midgard/include/linux/version_compat_defs.h` | H | kbase-UAPI | O | 14286 |
| 236 | `drivers/gpu/arm/midgard/include/uapi/base/arm/dma_buf_test_exporter/dma-buf-test-exporter.h` | H | kbase-UAPI | O | 2783 |
| 237 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/backend/gpu/mali_kbase_model_dummy.h` | H | kbase-UAPI | O | 3161 |
| 238 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/backend/gpu/mali_kbase_model_linux.h` | H | kbase-UAPI | O | 1203 |
| 239 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/csf/mali_base_csf_kernel.h` | H | kbase-UAPI | O | 23588 |
| 240 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_errors_dumpfault.h` | H | kbase-UAPI | O | 3206 |
| 241 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_ioctl.h` | H | kbase-UAPI | O | 24731 |
| 242 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/backend/mali_kbase_gpu_regmap_csf.h` | H | kbase-UAPI | O | 1259 |
| 243 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/backend/mali_kbase_gpu_regmap_jm.h` | H | kbase-UAPI | O | 938 |
| 244 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/mali_kbase_gpu_coherency.h` | H | kbase-UAPI | O | 1066 |
| 245 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/mali_kbase_gpu_id.h` | H | kbase-UAPI | Y | 8504 |
| 246 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/mali_kbase_gpu_regmap.h` | H | kbase-UAPI | O | 1073 |
| 247 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/jm/mali_base_jm_kernel.h` | H | kbase-UAPI | O | 40692 |
| 248 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/jm/mali_kbase_jm_ioctl.h` | H | kbase-UAPI | O | 9757 |
| 249 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_base_common_kernel.h` | H | kbase-UAPI | O | 7556 |
| 250 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_base_kernel.h` | H | kbase-UAPI | O | 24582 |
| 251 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_base_mem_priv.h` | H | kbase-UAPI | O | 1870 |
| 252 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_gpu_props.h` | H | kbase-UAPI | O | 3120 |
| 253 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_kbase_hwcnt_reader.h` | H | kbase-UAPI | O | 18005 |
| 254 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_kbase_ioctl.h` | H | kbase-UAPI | O | 25023 |
| 255 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_kbase_kinstr_jm_reader.h` | H | kbase-UAPI | O | 2995 |
| 256 | `drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_kbase_mem_profile_debugfs_buf_size.h` | H | kbase-UAPI | O | 1360 |
| 257 | `drivers/gpu/arm/midgard/ipa/Kbuild` | MK | kbase-IPA | O | 1239 |
| 258 | `drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_common_csf.c` | C | kbase-IPA | O | 14601 |
| 259 | `drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_common_csf.h` | H | kbase-IPA | O | 7326 |
| 260 | `drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_common_jm.c` | C | kbase-IPA | O | 10430 |
| 261 | `drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_common_jm.h` | H | kbase-IPA | O | 9207 |
| 262 | `drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_csf.c` | C | kbase-IPA | O | 12715 |
| 263 | `drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_jm.c` | C | kbase-IPA | O | 16559 |
| 264 | `drivers/gpu/arm/midgard/ipa/mali_kbase_ipa.c` | C | kbase-IPA | O | 22528 |
| 265 | `drivers/gpu/arm/midgard/ipa/mali_kbase_ipa.h` | H | kbase-IPA | O | 11123 |
| 266 | `drivers/gpu/arm/midgard/ipa/mali_kbase_ipa_debugfs.c` | C | kbase-IPA | O | 7792 |
| 267 | `drivers/gpu/arm/midgard/ipa/mali_kbase_ipa_debugfs.h` | H | kbase-IPA | O | 2214 |
| 268 | `drivers/gpu/arm/midgard/ipa/mali_kbase_ipa_simple.c` | C | kbase-IPA | O | 11542 |
| 269 | `drivers/gpu/arm/midgard/ipa/mali_kbase_ipa_simple.h` | H | kbase-IPA | O | 1642 |
| 270 | `drivers/gpu/arm/midgard/jm/mali_kbase_jm_defs.h` | H | kbase-JM | - | 34890 |
| 271 | `drivers/gpu/arm/midgard/jm/mali_kbase_jm_js.h` | H | kbase-JM | - | 38760 |
| 272 | `drivers/gpu/arm/midgard/jm/mali_kbase_js_defs.h` | H | kbase-JM | - | 19329 |
| 273 | `drivers/gpu/arm/midgard/mali_base_hwconfig_features.h` | H | kbase-core | O | 6274 |
| 274 | `drivers/gpu/arm/midgard/mali_base_hwconfig_issues.h` | H | kbase-core | O | 28025 |
| 275 | `drivers/gpu/arm/midgard/mali_kbase.h` | H | kbase-core | O | 27744 |
| 276 | `drivers/gpu/arm/midgard/mali_kbase_as_fault_debugfs.c` | C | kbase-core | O | 3097 |
| 277 | `drivers/gpu/arm/midgard/mali_kbase_as_fault_debugfs.h` | H | kbase-core | O | 1678 |
| 278 | `drivers/gpu/arm/midgard/mali_kbase_cache_policy.c` | C | kbase-core | O | 2029 |
| 279 | `drivers/gpu/arm/midgard/mali_kbase_cache_policy.h` | H | kbase-core | O | 1555 |
| 280 | `drivers/gpu/arm/midgard/mali_kbase_caps.h` | H | kbase-core | O | 3480 |
| 281 | `drivers/gpu/arm/midgard/mali_kbase_ccswe.c` | C | kbase-core | O | 2653 |
| 282 | `drivers/gpu/arm/midgard/mali_kbase_ccswe.h` | H | kbase-core | O | 3197 |
| 283 | `drivers/gpu/arm/midgard/mali_kbase_config.c` | C | kbase-core | O | 3590 |
| 284 | `drivers/gpu/arm/midgard/mali_kbase_config.h` | H | kbase-core | O | 22389 |
| 285 | `drivers/gpu/arm/midgard/mali_kbase_config_defaults.h` | H | kbase-core | O | 14634 |
| 286 | `drivers/gpu/arm/midgard/mali_kbase_core_linux.c` | C | kbase-core | Y | 208790 |
| 287 | `drivers/gpu/arm/midgard/mali_kbase_cs_experimental.h` | H | kbase-core | O | 1146 |
| 288 | `drivers/gpu/arm/midgard/mali_kbase_ctx_sched.c` | C | kbase-core | O | 11460 |
| 289 | `drivers/gpu/arm/midgard/mali_kbase_ctx_sched.h` | H | kbase-core | O | 10162 |
| 290 | `drivers/gpu/arm/midgard/mali_kbase_debug.c` | C | kbase-core | O | 1387 |
| 291 | `drivers/gpu/arm/midgard/mali_kbase_debug.h` | H | kbase-core | O | 5988 |
| 292 | `drivers/gpu/arm/midgard/mali_kbase_debug_job_fault.c` | C | kbase-core | O | 15981 |
| 293 | `drivers/gpu/arm/midgard/mali_kbase_debug_job_fault.h` | H | kbase-core | O | 4170 |
| 294 | `drivers/gpu/arm/midgard/mali_kbase_debug_mem_allocs.c` | C | kbase-core | O | 4065 |
| 295 | `drivers/gpu/arm/midgard/mali_kbase_debug_mem_allocs.h` | H | kbase-core | O | 1340 |
| 296 | `drivers/gpu/arm/midgard/mali_kbase_debug_mem_view.c` | C | kbase-core | O | 9655 |
| 297 | `drivers/gpu/arm/midgard/mali_kbase_debug_mem_view.h` | H | kbase-core | O | 1370 |
| 298 | `drivers/gpu/arm/midgard/mali_kbase_debug_mem_zones.c` | C | kbase-core | O | 3271 |
| 299 | `drivers/gpu/arm/midgard/mali_kbase_debug_mem_zones.h` | H | kbase-core | O | 1357 |
| 300 | `drivers/gpu/arm/midgard/mali_kbase_debugfs_helper.c` | C | kbase-core | O | 6020 |
| 301 | `drivers/gpu/arm/midgard/mali_kbase_debugfs_helper.h` | H | kbase-core | O | 6737 |
| 302 | `drivers/gpu/arm/midgard/mali_kbase_defs.h` | H | kbase-core | O | 103307 |
| 303 | `drivers/gpu/arm/midgard/mali_kbase_disjoint_events.c` | C | kbase-core | O | 2167 |
| 304 | `drivers/gpu/arm/midgard/mali_kbase_dummy_job_wa.c` | C | kbase-core | O | 10880 |
| 305 | `drivers/gpu/arm/midgard/mali_kbase_dummy_job_wa.h` | H | kbase-core | O | 2158 |
| 306 | `drivers/gpu/arm/midgard/mali_kbase_dvfs_debugfs.c` | C | kbase-core | O | 3093 |
| 307 | `drivers/gpu/arm/midgard/mali_kbase_dvfs_debugfs.h` | H | kbase-core | O | 1198 |
| 308 | `drivers/gpu/arm/midgard/mali_kbase_event.c` | C | kbase-core | O | 8025 |
| 309 | `drivers/gpu/arm/midgard/mali_kbase_fence.c` | C | kbase-core | O | 1496 |
| 310 | `drivers/gpu/arm/midgard/mali_kbase_fence.h` | H | kbase-core | O | 8253 |
| 311 | `drivers/gpu/arm/midgard/mali_kbase_fence_ops.c` | C | kbase-core | O | 3024 |
| 312 | `drivers/gpu/arm/midgard/mali_kbase_gator.h` | H | kbase-core | O | 1836 |
| 313 | `drivers/gpu/arm/midgard/mali_kbase_gator_api.c` | C | kbase-core | O | 8700 |
| 314 | `drivers/gpu/arm/midgard/mali_kbase_gator_api.h` | H | kbase-core | O | 8088 |
| 315 | `drivers/gpu/arm/midgard/mali_kbase_gator_hwcnt_names.h` | H | kbase-core | O | 1009 |
| 316 | `drivers/gpu/arm/midgard/mali_kbase_gator_hwcnt_names_tkrx.h` | H | kbase-core | O | 9614 |
| 317 | `drivers/gpu/arm/midgard/mali_kbase_gator_hwcnt_names_ttix.h` | H | kbase-core | O | 8759 |
| 318 | `drivers/gpu/arm/midgard/mali_kbase_gpu_memory_debugfs.c` | C | kbase-core | O | 3035 |
| 319 | `drivers/gpu/arm/midgard/mali_kbase_gpu_memory_debugfs.h` | H | kbase-core | O | 1666 |
| 320 | `drivers/gpu/arm/midgard/mali_kbase_gpu_metrics.c` | C | kbase-core | O | 7726 |
| 321 | `drivers/gpu/arm/midgard/mali_kbase_gpu_metrics.h` | H | kbase-core | O | 6950 |
| 322 | `drivers/gpu/arm/midgard/mali_kbase_gpuprops.c` | C | kbase-core | O | 31513 |
| 323 | `drivers/gpu/arm/midgard/mali_kbase_gpuprops.h` | H | kbase-core | O | 5489 |
| 324 | `drivers/gpu/arm/midgard/mali_kbase_gpuprops_private_types.h` | H | kbase-core | O | 2969 |
| 325 | `drivers/gpu/arm/midgard/mali_kbase_gpuprops_types.h` | H | kbase-core | O | 8846 |
| 326 | `drivers/gpu/arm/midgard/mali_kbase_gwt.c` | C | kbase-core | O | 7619 |
| 327 | `drivers/gpu/arm/midgard/mali_kbase_gwt.h` | H | kbase-core | O | 1675 |
| 328 | `drivers/gpu/arm/midgard/mali_kbase_hw.c` | C | kbase-core | O | 14492 |
| 329 | `drivers/gpu/arm/midgard/mali_kbase_hw.h` | H | kbase-core | O | 2507 |
| 330 | `drivers/gpu/arm/midgard/mali_kbase_hwaccess_backend.h` | H | kbase-core | O | 1386 |
| 331 | `drivers/gpu/arm/midgard/mali_kbase_hwaccess_defs.h` | H | kbase-core | O | 1818 |
| 332 | `drivers/gpu/arm/midgard/mali_kbase_hwaccess_gpuprops.h` | H | kbase-core | O | 2828 |
| 333 | `drivers/gpu/arm/midgard/mali_kbase_hwaccess_instr.h` | H | kbase-core | O | 5279 |
| 334 | `drivers/gpu/arm/midgard/mali_kbase_hwaccess_jm.h` | H | kbase-core | O | 10568 |
| 335 | `drivers/gpu/arm/midgard/mali_kbase_hwaccess_pm.h` | H | kbase-core | O | 7543 |
| 336 | `drivers/gpu/arm/midgard/mali_kbase_hwaccess_time.h` | H | kbase-core | O | 7961 |
| 337 | `drivers/gpu/arm/midgard/mali_kbase_jd.c` | C | kbase-core | O | 48511 |
| 338 | `drivers/gpu/arm/midgard/mali_kbase_jd_debugfs.c` | C | kbase-core | O | 5324 |
| 339 | `drivers/gpu/arm/midgard/mali_kbase_jd_debugfs.h` | H | kbase-core | O | 1273 |
| 340 | `drivers/gpu/arm/midgard/mali_kbase_jm.c` | C | kbase-core | O | 4256 |
| 341 | `drivers/gpu/arm/midgard/mali_kbase_jm.h` | H | kbase-core | O | 3749 |
| 342 | `drivers/gpu/arm/midgard/mali_kbase_js.c` | C | kbase-core | O | 110396 |
| 343 | `drivers/gpu/arm/midgard/mali_kbase_js.h` | H | kbase-core | O | 1129 |
| 344 | `drivers/gpu/arm/midgard/mali_kbase_js_ctx_attr.c` | C | kbase-core | O | 11486 |
| 345 | `drivers/gpu/arm/midgard/mali_kbase_js_ctx_attr.h` | H | kbase-core | O | 4847 |
| 346 | `drivers/gpu/arm/midgard/mali_kbase_kinstr_jm.c` | C | kbase-core | O | 27718 |
| 347 | `drivers/gpu/arm/midgard/mali_kbase_kinstr_jm.h` | H | kbase-core | O | 10073 |
| 348 | `drivers/gpu/arm/midgard/mali_kbase_kinstr_prfcnt.c` | C | kbase-core | O | 77531 |
| 349 | `drivers/gpu/arm/midgard/mali_kbase_kinstr_prfcnt.h` | H | kbase-core | O | 9174 |
| 350 | `drivers/gpu/arm/midgard/mali_kbase_linux.h` | H | kbase-core | O | 1643 |
| 351 | `drivers/gpu/arm/midgard/mali_kbase_mem.c` | C | kbase-core | O | 152286 |
| 352 | `drivers/gpu/arm/midgard/mali_kbase_mem.h` | H | kbase-core | O | 105713 |
| 353 | `drivers/gpu/arm/midgard/mali_kbase_mem_linux.c` | C | kbase-core | O | 118879 |
| 354 | `drivers/gpu/arm/midgard/mali_kbase_mem_linux.h` | H | kbase-core | O | 21546 |
| 355 | `drivers/gpu/arm/midgard/mali_kbase_mem_lowlevel.h` | H | kbase-core | O | 6365 |
| 356 | `drivers/gpu/arm/midgard/mali_kbase_mem_migrate.c` | C | kbase-core | O | 22634 |
| 357 | `drivers/gpu/arm/midgard/mali_kbase_mem_migrate.h` | H | kbase-core | O | 4068 |
| 358 | `drivers/gpu/arm/midgard/mali_kbase_mem_pool.c` | C | kbase-core | O | 33046 |
| 359 | `drivers/gpu/arm/midgard/mali_kbase_mem_pool_debugfs.c` | C | kbase-core | O | 5275 |
| 360 | `drivers/gpu/arm/midgard/mali_kbase_mem_pool_debugfs.h` | H | kbase-core | O | 4910 |
| 361 | `drivers/gpu/arm/midgard/mali_kbase_mem_pool_group.c` | C | kbase-core | O | 3185 |
| 362 | `drivers/gpu/arm/midgard/mali_kbase_mem_pool_group.h` | H | kbase-core | O | 4362 |
| 363 | `drivers/gpu/arm/midgard/mali_kbase_mem_profile_debugfs.c` | C | kbase-core | O | 4037 |
| 364 | `drivers/gpu/arm/midgard/mali_kbase_mem_profile_debugfs.h` | H | kbase-core | O | 2199 |
| 365 | `drivers/gpu/arm/midgard/mali_kbase_mipe_gen_header.h` | H | kbase-core | O | 6133 |
| 366 | `drivers/gpu/arm/midgard/mali_kbase_mipe_proto.h` | H | kbase-core | O | 4284 |
| 367 | `drivers/gpu/arm/midgard/mali_kbase_native_mgm.c` | C | kbase-core | O | 6032 |
| 368 | `drivers/gpu/arm/midgard/mali_kbase_native_mgm.h` | H | kbase-core | O | 1371 |
| 369 | `drivers/gpu/arm/midgard/mali_kbase_pbha.c` | C | kbase-core | O | 9282 |
| 370 | `drivers/gpu/arm/midgard/mali_kbase_pbha.h` | H | kbase-core | O | 2300 |
| 371 | `drivers/gpu/arm/midgard/mali_kbase_pbha_debugfs.c` | C | kbase-core | O | 6705 |
| 372 | `drivers/gpu/arm/midgard/mali_kbase_pbha_debugfs.h` | H | kbase-core | O | 1098 |
| 373 | `drivers/gpu/arm/midgard/mali_kbase_platform_fake.c` | C | kbase-core | O | 3978 |
| 374 | `drivers/gpu/arm/midgard/mali_kbase_pm.c` | C | kbase-core | O | 10786 |
| 375 | `drivers/gpu/arm/midgard/mali_kbase_pm.h` | H | kbase-core | O | 10297 |
| 376 | `drivers/gpu/arm/midgard/mali_kbase_reg_track.c` | C | kbase-core | O | 45582 |
| 377 | `drivers/gpu/arm/midgard/mali_kbase_reg_track.h` | H | kbase-core | O | 15890 |
| 378 | `drivers/gpu/arm/midgard/mali_kbase_regs_history_debugfs.c` | C | kbase-core | O | 6382 |
| 379 | `drivers/gpu/arm/midgard/mali_kbase_regs_history_debugfs.h` | H | kbase-core | O | 2752 |
| 380 | `drivers/gpu/arm/midgard/mali_kbase_reset_gpu.h` | H | kbase-core | O | 11350 |
| 381 | `drivers/gpu/arm/midgard/mali_kbase_smc.c` | C | kbase-core | O | 2709 |
| 382 | `drivers/gpu/arm/midgard/mali_kbase_smc.h` | H | kbase-core | O | 2127 |
| 383 | `drivers/gpu/arm/midgard/mali_kbase_softjobs.c` | C | kbase-core | O | 47138 |
| 384 | `drivers/gpu/arm/midgard/mali_kbase_sync.h` | H | kbase-core | O | 6814 |
| 385 | `drivers/gpu/arm/midgard/mali_kbase_sync_common.c` | C | kbase-core | O | 1379 |
| 386 | `drivers/gpu/arm/midgard/mali_kbase_sync_file.c` | C | kbase-core | O | 9530 |
| 387 | `drivers/gpu/arm/midgard/mali_kbase_trace_gpu_mem.c` | C | kbase-core | O | 6650 |
| 388 | `drivers/gpu/arm/midgard/mali_kbase_trace_gpu_mem.h` | H | kbase-core | O | 2926 |
| 389 | `drivers/gpu/arm/midgard/mali_linux_trace.h` | H | kbase-core | O | 27624 |
| 390 | `drivers/gpu/arm/midgard/mali_malisw.h` | H | kbase-core | O | 3036 |
| 391 | `drivers/gpu/arm/midgard/mali_power_gpu_frequency_trace.c` | C | kbase-core | O | 995 |
| 392 | `drivers/gpu/arm/midgard/mali_power_gpu_frequency_trace.h` | H | kbase-core | O | 1865 |
| 393 | `drivers/gpu/arm/midgard/mali_power_gpu_work_period_trace.c` | C | kbase-core | O | 1103 |
| 394 | `drivers/gpu/arm/midgard/mali_power_gpu_work_period_trace.h` | H | kbase-core | O | 2708 |
| 395 | `drivers/gpu/arm/midgard/mmu/Kbuild` | MK | kbase-MMU | O | 1272 |
| 396 | `drivers/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_csf.c` | C | kbase-MMU | O | 43401 |
| 397 | `drivers/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_faults_decoder_luts_csf.c` | C | kbase-MMU | O | 4030 |
| 398 | `drivers/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_faults_decoder_luts_csf.h` | H | kbase-MMU | O | 1857 |
| 399 | `drivers/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_faults_decoder_luts_jm.c` | C | kbase-MMU | O | 2195 |
| 400 | `drivers/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_faults_decoder_luts_jm.h` | H | kbase-MMU | O | 1395 |
| 401 | `drivers/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_jm.c` | C | kbase-MMU | O | 15059 |
| 402 | `drivers/gpu/arm/midgard/mmu/mali_kbase_mmu.c` | C | kbase-MMU | O | 168956 |
| 403 | `drivers/gpu/arm/midgard/mmu/mali_kbase_mmu.h` | H | kbase-MMU | O | 15453 |
| 404 | `drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_faults_decoder.c` | C | kbase-MMU | O | 4481 |
| 405 | `drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_faults_decoder.h` | H | kbase-MMU | O | 5140 |
| 406 | `drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_faults_decoder_luts.c` | C | kbase-MMU | O | 30339 |
| 407 | `drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_faults_decoder_luts.h` | H | kbase-MMU | O | 4192 |
| 408 | `drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_hw.h` | H | kbase-MMU | O | 7634 |
| 409 | `drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_hw_direct.c` | C | kbase-MMU | O | 24841 |
| 410 | `drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_internal.h` | H | kbase-MMU | O | 1989 |
| 411 | `drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_mode_aarch64.c` | C | kbase-MMU | O | 6404 |
| 412 | `drivers/gpu/arm/midgard/platform/Kconfig` | MK | kbase-plat-other | - | 994 |
| 413 | `drivers/gpu/arm/midgard/platform/devicetree/Kbuild` | MK | kbase-plat-other | - | 1013 |
| 414 | `drivers/gpu/arm/midgard/platform/devicetree/mali_kbase_clk_rate_trace.c` | C | kbase-plat-other | - | 3548 |
| 415 | `drivers/gpu/arm/midgard/platform/devicetree/mali_kbase_config_devicetree.c` | C | kbase-plat-other | - | 1513 |
| 416 | `drivers/gpu/arm/midgard/platform/devicetree/mali_kbase_config_platform.h` | H | kbase-plat-other | - | 1597 |
| 417 | `drivers/gpu/arm/midgard/platform/devicetree/mali_kbase_runtime_pm.c` | C | kbase-plat-other | - | 8243 |
| 418 | `drivers/gpu/arm/midgard/platform/meson/Kbuild` | MK | kbase-plat-other | - | 944 |
| 419 | `drivers/gpu/arm/midgard/platform/meson/mali_kbase_config_meson.c` | C | kbase-plat-other | - | 1513 |
| 420 | `drivers/gpu/arm/midgard/platform/meson/mali_kbase_config_platform.h` | H | kbase-plat-other | - | 1485 |
| 421 | `drivers/gpu/arm/midgard/platform/meson/mali_kbase_runtime_pm.c` | C | kbase-plat-other | - | 6838 |
| 422 | `drivers/gpu/arm/midgard/platform/mt6768/Kbuild` | MK | kbase-plat-other | - | 1225 |
| 423 | `drivers/gpu/arm/midgard/platform/mt6768/mali_kbase_config_mt6768.c` | C | kbase-plat-other | - | 15829 |
| 424 | `drivers/gpu/arm/midgard/platform/mt6768/mali_kbase_config_platform.h` | H | kbase-plat-other | - | 583 |
| 425 | `drivers/gpu/arm/midgard/platform/mt6781/Kbuild` | MK | kbase-plat-other | - | 1165 |
| 426 | `drivers/gpu/arm/midgard/platform/mt6781/mali_kbase_config_mt6781.c` | C | kbase-plat-other | - | 16908 |
| 427 | `drivers/gpu/arm/midgard/platform/mt6781/mali_kbase_config_platform.h` | H | kbase-plat-other | - | 583 |
| 428 | `drivers/gpu/arm/midgard/platform/mt6833/Kbuild` | MK | kbase-plat-other | - | 1165 |
| 429 | `drivers/gpu/arm/midgard/platform/mt6833/mali_kbase_config_mt6833.c` | C | kbase-plat-other | - | 16908 |
| 430 | `drivers/gpu/arm/midgard/platform/mt6833/mali_kbase_config_platform.h` | H | kbase-plat-other | - | 583 |
| 431 | `drivers/gpu/arm/midgard/platform/mt6853/Kbuild` | MK | kbase-plat-other | - | 1165 |
| 432 | `drivers/gpu/arm/midgard/platform/mt6853/mali_kbase_config_mt6853.c` | C | kbase-plat-other | - | 16908 |
| 433 | `drivers/gpu/arm/midgard/platform/mt6853/mali_kbase_config_platform.h` | H | kbase-plat-other | - | 583 |
| 434 | `drivers/gpu/arm/midgard/platform/mt6877/Kbuild` | MK | kbase-plat-other | - | 1165 |
| 435 | `drivers/gpu/arm/midgard/platform/mt6877/mali_kbase_config_mt6877.c` | C | kbase-plat-other | - | 15895 |
| 436 | `drivers/gpu/arm/midgard/platform/mt6877/mali_kbase_config_platform.h` | H | kbase-plat-other | - | 583 |
| 437 | `drivers/gpu/arm/midgard/platform/mt6893/Kbuild` | MK | kbase-plat-other | - | 1165 |
| 438 | `drivers/gpu/arm/midgard/platform/mt6893/mali_kbase_config_mt6893.c` | C | kbase-plat-other | - | 16908 |
| 439 | `drivers/gpu/arm/midgard/platform/mt6893/mali_kbase_config_platform.h` | H | kbase-plat-other | - | 583 |
| 440 | `drivers/gpu/arm/midgard/platform/mt6899/Kbuild` | MK | kbase-plat-other | - | 1116 |
| 441 | `drivers/gpu/arm/midgard/platform/mt6899/mali_kbase_config_mt6899.c` | C | kbase-plat-other | - | 19771 |
| 442 | `drivers/gpu/arm/midgard/platform/mt6899/mali_kbase_config_platform.h` | H | kbase-plat-other | - | 538 |
| 443 | `drivers/gpu/arm/midgard/platform/mt6991/Kbuild` | MK | kbase-plat-mt6991 | O | 1116 |
| 444 | `drivers/gpu/arm/midgard/platform/mt6991/mali_kbase_config_mt6991.c` | C | kbase-plat-mt6991 | O | 25222 |
| 445 | `drivers/gpu/arm/midgard/platform/mt6991/mali_kbase_config_platform.h` | H | kbase-plat-mt6991 | O | 538 |
| 446 | `drivers/gpu/arm/midgard/platform/mtk_mfg_counter.h` | H | kbase-plat-other | - | 6428 |
| 447 | `drivers/gpu/arm/midgard/platform/mtk_platform_common.h` | H | kbase-plat-other | - | 6521 |
| 448 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/Kbuild` | MK | kbase-plat-common | O | 4525 |
| 449 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_gpu_power_model_sspm_ipi.c` | C | kbase-plat-common | O | 1696 |
| 450 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_gpu_power_model_sspm_ipi.h` | H | kbase-plat-common | O | 839 |
| 451 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_gpu_trace.h` | H | kbase-plat-common | O | 935 |
| 452 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_ltr_pmu.c` | C | kbase-plat-common | O | 3571 |
| 453 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_ltr_pmu.h` | H | kbase-plat-common | O | 778 |
| 454 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_mfg_counter.c` | C | kbase-plat-common | O | 22449 |
| 455 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_adaptive_power_policy.c` | C | kbase-plat-common | O | 1512 |
| 456 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_adaptive_power_policy.h` | H | kbase-plat-common | O | 312 |
| 457 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_cm7_trace.c` | C | kbase-plat-common | O | 2591 |
| 458 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_cm7_trace.h` | H | kbase-plat-common | O | 327 |
| 459 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_common.c` | C | kbase-plat-common | O | 32263 |
| 460 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug.h` | H | kbase-plat-common | O | 4684 |
| 461 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_cpu.c` | C | kbase-plat-common | O | 5983 |
| 462 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_csg.c` | C | kbase-plat-common | O | 6544 |
| 463 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_enop_metadata.c` | C | kbase-plat-common | O | 6963 |
| 464 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_gpu.c` | C | kbase-plat-common | O | 54848 |
| 465 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_gpu_debugfs.c` | C | kbase-plat-common | O | 2209 |
| 466 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_infra_status.c` | C | kbase-plat-common | O | 1789 |
| 467 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_iter_cshw.c` | C | kbase-plat-common | O | 17941 |
| 468 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_kcpu.c` | C | kbase-plat-common | O | 14539 |
| 469 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_pm_status.c` | C | kbase-plat-common | O | 4613 |
| 470 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_queue_data.c` | C | kbase-plat-common | O | 3650 |
| 471 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_queue_data.h` | H | kbase-plat-common | O | 303 |
| 472 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_devfreq_governor.c` | C | kbase-plat-common | O | 4473 |
| 473 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_devfreq_governor.h` | H | kbase-plat-common | O | 560 |
| 474 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_devfreq_thermal.c` | C | kbase-plat-common | O | 2279 |
| 475 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_devfreq_thermal.h` | H | kbase-plat-common | O | 1049 |
| 476 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_diagnosis_mode.c` | C | kbase-plat-common | O | 3822 |
| 477 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_diagnosis_mode.h` | H | kbase-plat-common | O | 424 |
| 478 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs.c` | C | kbase-plat-common | O | 13907 |
| 479 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs.h` | H | kbase-plat-common | O | 2691 |
| 480 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs_hint_26m_perf_cnting.c` | C | kbase-plat-common | O | 5095 |
| 481 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs_hint_26m_perf_cnting.h` | H | kbase-plat-common | O | 996 |
| 482 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs_hint_26m_perf_cnting_ex.h` | H | kbase-plat-common | O | 419 |
| 483 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_gpu_idle_test.c` | C | kbase-plat-common | O | 1458 |
| 484 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_gpu_idle_test.h` | H | kbase-plat-common | O | 301 |
| 485 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_logbuffer.c` | C | kbase-plat-common | O | 17935 |
| 486 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_logbuffer.h` | H | kbase-plat-common | O | 1808 |
| 487 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_mali_event.h` | H | kbase-plat-common | O | 1708 |
| 488 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_memtrack.c` | C | kbase-plat-common | O | 4074 |
| 489 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_memtrack.h` | H | kbase-plat-common | O | 476 |
| 490 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_qinspect.c` | C | kbase-plat-common | O | 50889 |
| 491 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_qinspect.h` | H | kbase-plat-common | O | 10802 |
| 492 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_qinspect_recovery.c` | C | kbase-plat-common | O | 20121 |
| 493 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_qinspect_recovery.h` | H | kbase-plat-common | O | 436 |
| 494 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_upf_counter.c` | C | kbase-plat-common | O | 2127 |
| 495 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_upf_counter.h` | H | kbase-plat-common | O | 413 |
| 496 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_directly_hard_reset.c` | C | kbase-plat-common | O | 2688 |
| 497 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_directly_hard_reset.h` | H | kbase-plat-common | O | 438 |
| 498 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_fault_worker.c` | C | kbase-plat-common | O | 2287 |
| 499 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_fault_worker.h` | H | kbase-plat-common | O | 309 |
| 500 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_force_hard_reset.c` | C | kbase-plat-common | O | 2610 |
| 501 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_force_hard_reset.h` | H | kbase-plat-common | O | 420 |
| 502 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_force_terminate_csg.c` | C | kbase-plat-common | O | 2688 |
| 503 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_force_terminate_csg.h` | H | kbase-plat-common | O | 438 |
| 504 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_memory_footprint.c` | C | kbase-plat-common | O | 2224 |
| 505 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_memory_footprint.h` | H | kbase-plat-common | O | 325 |
| 506 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_missing_doorbell.c` | C | kbase-plat-common | O | 2502 |
| 507 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_missing_doorbell.h` | H | kbase-plat-common | O | 420 |
| 508 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_scheduler.c` | C | kbase-plat-common | O | 4035 |
| 509 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_scheduler.h` | H | kbase-plat-common | O | 297 |
| 510 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_sync_update.c` | C | kbase-plat-common | O | 3205 |
| 511 | `drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_sync_update.h` | H | kbase-plat-common | O | 626 |
| 512 | `drivers/gpu/arm/midgard/platform/mtk_platform_utils.h` | H | kbase-plat-other | - | 386 |
| 513 | `drivers/gpu/arm/midgard/platform/vexpress/Kbuild` | MK | kbase-plat-other | - | 931 |
| 514 | `drivers/gpu/arm/midgard/platform/vexpress/mali_kbase_config_platform.h` | H | kbase-plat-other | - | 1335 |
| 515 | `drivers/gpu/arm/midgard/platform/vexpress/mali_kbase_config_vexpress.c` | C | kbase-plat-other | - | 2302 |
| 516 | `drivers/gpu/arm/midgard/platform/vexpress_1xv7_a57/Kbuild` | MK | kbase-plat-other | - | 931 |
| 517 | `drivers/gpu/arm/midgard/platform/vexpress_1xv7_a57/mali_kbase_config_platform.h` | H | kbase-plat-other | - | 1335 |
| 518 | `drivers/gpu/arm/midgard/platform/vexpress_1xv7_a57/mali_kbase_config_vexpress.c` | C | kbase-plat-other | - | 2246 |
| 519 | `drivers/gpu/arm/midgard/platform/vexpress_6xvirtex7_10mhz/Kbuild` | MK | kbase-plat-other | - | 988 |
| 520 | `drivers/gpu/arm/midgard/platform/vexpress_6xvirtex7_10mhz/mali_kbase_config_platform.h` | H | kbase-plat-other | - | 1335 |
| 521 | `drivers/gpu/arm/midgard/platform/vexpress_6xvirtex7_10mhz/mali_kbase_config_vexpress.c` | C | kbase-plat-other | - | 2246 |
| 522 | `drivers/gpu/arm/midgard/protected_mode_switcher.h` | H | kbase-core | O | 1918 |
| 523 | `drivers/gpu/arm/midgard/tests/Kbuild` | MK | kbase-tests | - | 1219 |
| 524 | `drivers/gpu/arm/midgard/tests/Kconfig` | MK | kbase-tests | - | 2130 |
| 525 | `drivers/gpu/arm/midgard/tests/Mconfig` | ETC | kbase-tests | - | 2170 |
| 526 | `drivers/gpu/arm/midgard/tests/build.bp` | ETC | kbase-tests | - | 1558 |
| 527 | `drivers/gpu/arm/midgard/tests/include/kutf/kutf_helpers.h` | H | kbase-tests | - | 4001 |
| 528 | `drivers/gpu/arm/midgard/tests/include/kutf/kutf_helpers_user.h` | H | kbase-tests | - | 6481 |
| 529 | `drivers/gpu/arm/midgard/tests/include/kutf/kutf_kprobe.h` | H | kbase-tests | - | 1197 |
| 530 | `drivers/gpu/arm/midgard/tests/include/kutf/kutf_mem.h` | H | kbase-tests | - | 2309 |
| 531 | `drivers/gpu/arm/midgard/tests/include/kutf/kutf_resultset.h` | H | kbase-tests | - | 5876 |
| 532 | `drivers/gpu/arm/midgard/tests/include/kutf/kutf_suite.h` | H | kbase-tests | - | 22873 |
| 533 | `drivers/gpu/arm/midgard/tests/include/kutf/kutf_utils.h` | H | kbase-tests | - | 2794 |
| 534 | `drivers/gpu/arm/midgard/tests/kutf/Kbuild` | MK | kbase-tests | - | 1008 |
| 535 | `drivers/gpu/arm/midgard/tests/kutf/build.bp` | ETC | kbase-tests | - | 1276 |
| 536 | `drivers/gpu/arm/midgard/tests/kutf/kutf_helpers.c` | C | kbase-tests | - | 3486 |
| 537 | `drivers/gpu/arm/midgard/tests/kutf/kutf_helpers_user.c` | C | kbase-tests | - | 13388 |
| 538 | `drivers/gpu/arm/midgard/tests/kutf/kutf_kprobe.c` | C | kbase-tests | - | 9043 |
| 539 | `drivers/gpu/arm/midgard/tests/kutf/kutf_mem.c` | C | kbase-tests | - | 2489 |
| 540 | `drivers/gpu/arm/midgard/tests/kutf/kutf_resultset.c` | C | kbase-tests | - | 3949 |
| 541 | `drivers/gpu/arm/midgard/tests/kutf/kutf_suite.c` | C | kbase-tests | - | 33918 |
| 542 | `drivers/gpu/arm/midgard/tests/kutf/kutf_utils.c` | C | kbase-tests | - | 2096 |
| 543 | `drivers/gpu/arm/midgard/tests/mali_kutf_clk_rate_trace/kernel/Kbuild` | MK | kbase-tests | - | 968 |
| 544 | `drivers/gpu/arm/midgard/tests/mali_kutf_clk_rate_trace/kernel/build.bp` | ETC | kbase-tests | - | 1361 |
| 545 | `drivers/gpu/arm/midgard/tests/mali_kutf_clk_rate_trace/kernel/mali_kutf_clk_rate_trace_test.c` | C | kbase-tests | - | 29596 |
| 546 | `drivers/gpu/arm/midgard/tests/mali_kutf_clk_rate_trace/mali_kutf_clk_rate_trace_test.h` | H | kbase-tests | - | 7975 |
| 547 | `drivers/gpu/arm/midgard/tests/mali_kutf_irq_test/Kbuild` | MK | kbase-tests | - | 926 |
| 548 | `drivers/gpu/arm/midgard/tests/mali_kutf_irq_test/build.bp` | ETC | kbase-tests | - | 1279 |
| 549 | `drivers/gpu/arm/midgard/tests/mali_kutf_irq_test/mali_kutf_irq_test_main.c` | C | kbase-tests | - | 7889 |
| 550 | `drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/kernel/mali_kutf_kernel_defect_GPUCORE-27226.c` | C | kbase-tests | - | 3783 |
| 551 | `drivers/gpu/arm/midgard/tests/mali_kutf_mgm_integration_test/Kbuild` | MK | kbase-tests | - | 963 |
| 552 | `drivers/gpu/arm/midgard/tests/mali_kutf_mgm_integration_test/build.bp` | ETC | kbase-tests | - | 1321 |
| 553 | `drivers/gpu/arm/midgard/tests/mali_kutf_mgm_integration_test/mali_kutf_mgm_integration_test_main.c` | C | kbase-tests | - | 6789 |
| 554 | `drivers/gpu/arm/midgard/thirdparty/Kbuild` | MK | kbase-3rd | - | 811 |
| 555 | `drivers/gpu/arm/midgard/thirdparty/mali_kbase_mmap.c` | C | kbase-3rd | - | 17807 |
| 556 | `drivers/gpu/arm/midgard/thirdparty/mm.h` | H | kbase-3rd | - | 948 |
| 557 | `drivers/gpu/arm/midgard/tl/Kbuild` | MK | kbase-TL | O | 1098 |
| 558 | `drivers/gpu/arm/midgard/tl/backend/mali_kbase_timeline_csf.c` | C | kbase-TL | O | 6181 |
| 559 | `drivers/gpu/arm/midgard/tl/backend/mali_kbase_timeline_jm.c` | C | kbase-TL | O | 3236 |
| 560 | `drivers/gpu/arm/midgard/tl/mali_kbase_timeline.c` | C | kbase-TL | O | 11946 |
| 561 | `drivers/gpu/arm/midgard/tl/mali_kbase_timeline.h` | H | kbase-TL | O | 4652 |
| 562 | `drivers/gpu/arm/midgard/tl/mali_kbase_timeline_io.c` | C | kbase-TL | O | 13614 |
| 563 | `drivers/gpu/arm/midgard/tl/mali_kbase_timeline_priv.h` | H | kbase-TL | O | 3814 |
| 564 | `drivers/gpu/arm/midgard/tl/mali_kbase_tl_serialize.h` | H | kbase-TL | O | 3259 |
| 565 | `drivers/gpu/arm/midgard/tl/mali_kbase_tlstream.c` | C | kbase-TL | O | 8352 |
| 566 | `drivers/gpu/arm/midgard/tl/mali_kbase_tlstream.h` | H | kbase-TL | O | 5710 |
| 567 | `drivers/gpu/arm/midgard/tl/mali_kbase_tracepoints.c` | C | kbase-TL | O | 122843 |
| 568 | `drivers/gpu/arm/midgard/tl/mali_kbase_tracepoints.h` | H | kbase-TL | O | 110829 |
| 569 | `drivers/hwtracing/coresight/mali/Kbuild` | MK | kbase-trace | O | 2034 |
| 570 | `drivers/hwtracing/coresight/mali/Kconfig` | MK | kbase-trace | O | 1587 |
| 571 | `drivers/hwtracing/coresight/mali/Makefile` | MK | kbase-trace | O | 3852 |
| 572 | `drivers/hwtracing/coresight/mali/Mconfig` | ETC | kbase-trace | O | 1578 |
| 573 | `drivers/hwtracing/coresight/mali/build.bp` | ETC | kbase-trace | O | 2567 |
| 574 | `drivers/hwtracing/coresight/mali/coresight_mali_common.c` | C | kbase-trace | O | 1861 |
| 575 | `drivers/hwtracing/coresight/mali/coresight_mali_common.h` | H | kbase-trace | O | 5617 |
| 576 | `drivers/hwtracing/coresight/mali/sources/coresight_mali_sources.c` | C | kbase-trace | O | 4885 |
| 577 | `drivers/hwtracing/coresight/mali/sources/coresight_mali_sources.h` | H | kbase-trace | O | 3035 |
| 578 | `drivers/hwtracing/coresight/mali/sources/ela/coresight-ela600.h` | H | kbase-trace | O | 3940 |
| 579 | `drivers/hwtracing/coresight/mali/sources/ela/coresight_mali_source_ela_core.c` | C | kbase-trace | O | 18334 |
| 580 | `drivers/hwtracing/coresight/mali/sources/etm/coresight_mali_source_etm_core.c` | C | kbase-trace | O | 9679 |
| 581 | `drivers/hwtracing/coresight/mali/sources/itm/coresight_mali_source_itm_core.c` | C | kbase-trace | O | 8788 |

## B. MTK GPU 平台适配源码 — R3 `drivers/gpu/mediatek/`（188 个文件，已剔除 gpu_mali 副本）

仓库：`MiCode/MTK_kernel_device_modules` @ `e45c3199`，本地 `01_original_baseline/kernel_dev_modules_dali/`

| # | 相对路径 | 类型 | 组件 | MT6991 | 字节 |
| ---: | --- | :--: | --- | :--: | ---: |
| 1 | `Kconfig` | MK | 子系统入口 | - | 9110 |
| 2 | `Makefile` | MK | 子系统入口 | - | 2110 |
| 3 | `ged/Makefile` | MK | GED | 共用 | 3936 |
| 4 | `ged/include/ged.h` | H | GED | 共用 | 610 |
| 5 | `ged/include/ged_async.h` | H | GED | 共用 | 987 |
| 6 | `ged/include/ged_base.h` | H | GED | 共用 | 1324 |
| 7 | `ged/include/ged_bridge.h` | H | GED | 共用 | 3658 |
| 8 | `ged/include/ged_bridge_id.h` | H | GED | 共用 | 15287 |
| 9 | `ged/include/ged_dcs.h` | H | GED | 共用 | 1493 |
| 10 | `ged/include/ged_debugFS.h` | H | GED | 共用 | 818 |
| 11 | `ged/include/ged_dvfs.h` | H | GED | 共用 | 13666 |
| 12 | `ged/include/ged_eb.h` | H | GED | 共用 | 25707 |
| 13 | `ged/include/ged_global.h` | H | GED | 共用 | 3634 |
| 14 | `ged/include/ged_gpu_bm.h` | H | GED | 共用 | 1675 |
| 15 | `ged/include/ged_gpu_slc.h` | H | GED | 共用 | 679 |
| 16 | `ged/include/ged_gpu_tuner.h` | H | GED | 共用 | 932 |
| 17 | `ged/include/ged_gpufreq.h` | H | GED | 共用 | 2308 |
| 18 | `ged/include/ged_gpufreq_v1.h` | H | GED | 共用 | 1250 |
| 19 | `ged/include/ged_gpufreq_v2.h` | H | GED | 共用 | 1974 |
| 20 | `ged/include/ged_hal.h` | H | GED | 共用 | 431 |
| 21 | `ged/include/ged_hashtable.h` | H | GED | 共用 | 1277 |
| 22 | `ged/include/ged_kpi.h` | H | GED | 共用 | 3888 |
| 23 | `ged/include/ged_log.h` | H | GED | 共用 | 2613 |
| 24 | `ged/include/ged_mali_event.h` | H | GED | 共用 | 1981 |
| 25 | `ged/include/ged_monitor_3D_fence.h` | H | GED | 共用 | 369 |
| 26 | `ged/include/ged_notify_sw_vsync.h` | H | GED | 共用 | 2022 |
| 27 | `ged/include/ged_sysfs.h` | H | GED | 共用 | 912 |
| 28 | `ged/include/ged_thread.h` | H | GED | 共用 | 417 |
| 29 | `ged/include/ged_tracepoint.h` | H | GED | 共用 | 56209 |
| 30 | `ged/include/ged_type.h` | H | GED | 共用 | 3801 |
| 31 | `ged/src/ged.c` | C | GED | 共用 | 2872 |
| 32 | `ged/src/ged_base.c` | C | GED | 共用 | 1555 |
| 33 | `ged/src/ged_bridge.c` | C | GED | 共用 | 9360 |
| 34 | `ged/src/ged_dcs.c` | C | GED | 共用 | 9092 |
| 35 | `ged/src/ged_debugFS.c` | C | GED | 共用 | 4623 |
| 36 | `ged/src/ged_dvfs.c` | C | GED | 共用 | 134061 |
| 37 | `ged/src/ged_eb.c` | C | GED | 共用 | 50689 |
| 38 | `ged/src/ged_ge.c` | C | GED | 共用 | 11166 |
| 39 | `ged/src/ged_ge.h` | H | GED | 共用 | 736 |
| 40 | `ged/src/ged_gpu_bm.c` | C | GED | 共用 | 4897 |
| 41 | `ged/src/ged_gpu_slc.c` | C | GED | 共用 | 3665 |
| 42 | `ged/src/ged_gpu_tuner.c` | C | GED | 共用 | 15038 |
| 43 | `ged/src/ged_gpufreq_v1.c` | C | GED | 共用 | 2116 |
| 44 | `ged/src/ged_gpufreq_v2.c` | C | GED | 共用 | 30024 |
| 45 | `ged/src/ged_hal.c` | C | GED | 共用 | 72092 |
| 46 | `ged/src/ged_hashtable.c` | C | GED | 共用 | 7994 |
| 47 | `ged/src/ged_kpi.c` | C | GED | 共用 | 102084 |
| 48 | `ged/src/ged_log.c` | C | GED | 共用 | 32644 |
| 49 | `ged/src/ged_main.c` | C | GED | 共用 | 26672 |
| 50 | `ged/src/ged_mali_event.c` | C | GED | 共用 | 8712 |
| 51 | `ged/src/ged_monitor_3D_fence.c` | C | GED | 共用 | 4951 |
| 52 | `ged/src/ged_notify_sw_vsync.c` | C | GED | 共用 | 44627 |
| 53 | `ged/src/ged_sync.c` | C | GED | 共用 | 10738 |
| 54 | `ged/src/ged_sysfs.c` | C | GED | 共用 | 1943 |
| 55 | `ged/src/ged_thread.c` | C | GED | 共用 | 1560 |
| 56 | `ged/src/ged_thread.h` | H | GED | 共用 | 422 |
| 57 | `gpu_bm/Makefile` | MK | GPU-BM/QoS | 共用 | 1141 |
| 58 | `gpu_bm/gpu_bm.c` | C | GPU-BM/QoS | 共用 | 14785 |
| 59 | `gpu_bm/gpu_bm.h` | H | GPU-BM/QoS | 共用 | 1128 |
| 60 | `gpu_iommu/Makefile` | MK | IOMMU | - | 1285 |
| 61 | `gpu_iommu/gpu_iommu_mt6991.c` | C | IOMMU | Y | 1181 |
| 62 | `gpu_pdma/Makefile` | MK | PDMA | - | 975 |
| 63 | `gpu_pdma/gpu_pdma_mt6991.c` | C | PDMA | Y | 21173 |
| 64 | `gpu_pdma/include/gpu_pdma.h` | H | PDMA | - | 2394 |
| 65 | `gpueb/Makefile` | MK | GPUEB | 共用 | 1365 |
| 66 | `gpueb/ghpm.c` | C | GPUEB | 共用 | 23483 |
| 67 | `gpueb/ghpm_debug.c` | C | GPUEB | 共用 | 7593 |
| 68 | `gpueb/ghpm_swwa.c` | C | GPUEB | 共用 | 14347 |
| 69 | `gpueb/ghpm_wrapper.c` | C | GPUEB | 共用 | 4078 |
| 70 | `gpueb/gpueb.c` | C | GPUEB | 共用 | 7149 |
| 71 | `gpueb/gpueb_debug.c` | C | GPUEB | 共用 | 14311 |
| 72 | `gpueb/gpueb_gpumpu.c` | C | GPUEB | 共用 | 2105 |
| 73 | `gpueb/gpueb_hwvoter_dbg.c` | C | GPUEB | 共用 | 4891 |
| 74 | `gpueb/gpueb_ipi.c` | C | GPUEB | 共用 | 15427 |
| 75 | `gpueb/gpueb_logger.c` | C | GPUEB | 共用 | 5910 |
| 76 | `gpueb/gpueb_plat_service.c` | C | GPUEB | 共用 | 2120 |
| 77 | `gpueb/gpueb_reserved_mem.c` | C | GPUEB | 共用 | 6796 |
| 78 | `gpueb/gpueb_timesync.c` | C | GPUEB | 共用 | 7625 |
| 79 | `gpueb/include/ghpm.h` | H | GPUEB | 共用 | 5281 |
| 80 | `gpueb/include/ghpm_debug.h` | H | GPUEB | 共用 | 1753 |
| 81 | `gpueb/include/ghpm_swwa.h` | H | GPUEB | 共用 | 263 |
| 82 | `gpueb/include/ghpm_wrapper.h` | H | GPUEB | 共用 | 2867 |
| 83 | `gpueb/include/gpueb_common.h` | H | GPUEB | 共用 | 2149 |
| 84 | `gpueb/include/gpueb_debug.h` | H | GPUEB | 共用 | 4051 |
| 85 | `gpueb/include/gpueb_gpumpu.h` | H | GPUEB | 共用 | 875 |
| 86 | `gpueb/include/gpueb_helper.h` | H | GPUEB | 共用 | 1080 |
| 87 | `gpueb/include/gpueb_hwvoter_dbg.h` | H | GPUEB | 共用 | 457 |
| 88 | `gpueb/include/gpueb_ipi.h` | H | GPUEB | 共用 | 1388 |
| 89 | `gpueb/include/gpueb_logger.h` | H | GPUEB | 共用 | 1010 |
| 90 | `gpueb/include/gpueb_plat_service.h` | H | GPUEB | 共用 | 532 |
| 91 | `gpueb/include/gpueb_reserved_mem.h` | H | GPUEB | 共用 | 935 |
| 92 | `gpueb/include/gpueb_timesync.h` | H | GPUEB | 共用 | 311 |
| 93 | `gpufreq/Makefile` | MK | GPUFreq | - | 676 |
| 94 | `gpufreq/mtk_gpufreq.h` | H | GPUFreq | - | 427 |
| 95 | `gpufreq/v1/Makefile` | MK | GPUFreq | - | 1167 |
| 96 | `gpufreq/v1/include/mt6853/mtk_gpufreq_internal_plat.h` | H | GPUFreq | - | 17323 |
| 97 | `gpufreq/v1/include/mt6853/mtk_gpufreq_plat.h` | H | GPUFreq | - | 5516 |
| 98 | `gpufreq/v1/include/mt6885/mtk_gpufreq_internal_plat.h` | H | GPUFreq | - | 15260 |
| 99 | `gpufreq/v1/include/mt6885/mtk_gpufreq_plat.h` | H | GPUFreq | - | 5992 |
| 100 | `gpufreq/v1/include/mt6893/mtk_gpufreq_internal_plat.h` | H | GPUFreq | - | 15887 |
| 101 | `gpufreq/v1/include/mt6893/mtk_gpufreq_plat.h` | H | GPUFreq | - | 6185 |
| 102 | `gpufreq/v1/include/mtk_gpufreq_common.h` | H | GPUFreq | - | 684 |
| 103 | `gpufreq/v1/include/mtk_gpufreq_internal.h` | H | GPUFreq | - | 520 |
| 104 | `gpufreq/v1/include/mtk_gpufreq_v1.h` | H | GPUFreq | - | 466 |
| 105 | `gpufreq/v1/mt6853/mtk_gpufreq_plat.c` | C | GPUFreq | - | 92676 |
| 106 | `gpufreq/v1/mt6885/mtk_gpufreq_plat.c` | C | GPUFreq | - | 92916 |
| 107 | `gpufreq/v1/mt6893/mtk_gpufreq_plat.c` | C | GPUFreq | - | 98070 |
| 108 | `gpufreq/v1/mtk_gpufreq_common.c` | C | GPUFreq | - | 1905 |
| 109 | `gpufreq/v2/Makefile` | MK | GPUFreq | - | 3537 |
| 110 | `gpufreq/v2/gpufreq_debug.c` | C | GPUFreq | - | 40580 |
| 111 | `gpufreq/v2/gpufreq_history.c` | C | GPUFreq | - | 2350 |
| 112 | `gpufreq/v2/gpufreq_history_mt6899.c` | C | GPUFreq | - | 3710 |
| 113 | `gpufreq/v2/gpufreq_history_mt6991.c` | C | GPUFreq | Y | 3710 |
| 114 | `gpufreq/v2/gpufreq_mt6899.c` | C | GPUFreq | - | 31944 |
| 115 | `gpufreq/v2/gpufreq_mt6991.c` | C | GPUFreq | Y | 54438 |
| 116 | `gpufreq/v2/gpufreq_v2.c` | C | GPUFreq | - | 68727 |
| 117 | `gpufreq/v2/gpuppm.c` | C | GPUFreq | - | 26119 |
| 118 | `gpufreq/v2/include/gpu_smmu_common.h` | H | GPUFreq | - | 232 |
| 119 | `gpufreq/v2/include/gpufreq_common.h` | H | GPUFreq | - | 7921 |
| 120 | `gpufreq/v2/include/gpufreq_debug.h` | H | GPUFreq | - | 3145 |
| 121 | `gpufreq/v2/include/gpufreq_history.h` | H | GPUFreq | - | 674 |
| 122 | `gpufreq/v2/include/gpufreq_history_common.h` | H | GPUFreq | - | 1289 |
| 123 | `gpufreq/v2/include/gpufreq_history_mt6899.h` | H | GPUFreq | - | 2193 |
| 124 | `gpufreq/v2/include/gpufreq_history_mt6991.h` | H | GPUFreq | Y | 2193 |
| 125 | `gpufreq/v2/include/gpufreq_ipi.h` | H | GPUFreq | - | 3792 |
| 126 | `gpufreq/v2/include/gpufreq_mssv.h` | H | GPUFreq | - | 807 |
| 127 | `gpufreq/v2/include/gpufreq_mt6899.h` | H | GPUFreq | - | 3317 |
| 128 | `gpufreq/v2/include/gpufreq_mt6991.h` | H | GPUFreq | Y | 5602 |
| 129 | `gpufreq/v2/include/gpufreq_reg_mt6899.h` | H | GPUFreq | - | 11622 |
| 130 | `gpufreq/v2/include/gpufreq_reg_mt6991.h` | H | GPUFreq | Y | 25193 |
| 131 | `gpufreq/v2/include/gpufreq_v2.h` | H | GPUFreq | - | 22541 |
| 132 | `gpufreq/v2/include/gpuppm.h` | H | GPUFreq | - | 2260 |
| 133 | `gpufreq/v2_legacy/Makefile` | MK | GPUFreq | - | 4322 |
| 134 | `gpufreq/v2_legacy/gpufreq_debug_legacy.c` | C | GPUFreq | - | 33887 |
| 135 | `gpufreq/v2_legacy/gpufreq_early_init.c` | C | GPUFreq | - | 6346 |
| 136 | `gpufreq/v2_legacy/gpufreq_history_legacy.c` | C | GPUFreq | - | 2357 |
| 137 | `gpufreq/v2_legacy/gpufreq_history_mt6761.c` | C | GPUFreq | - | 1336 |
| 138 | `gpufreq/v2_legacy/gpufreq_history_mt6765.c` | C | GPUFreq | - | 1334 |
| 139 | `gpufreq/v2_legacy/gpufreq_history_mt6768.c` | C | GPUFreq | - | 1334 |
| 140 | `gpufreq/v2_legacy/gpufreq_history_mt6781.c` | C | GPUFreq | - | 1334 |
| 141 | `gpufreq/v2_legacy/gpufreq_history_mt6833.c` | C | GPUFreq | - | 1334 |
| 142 | `gpufreq/v2_legacy/gpufreq_history_mt6853.c` | C | GPUFreq | - | 1334 |
| 143 | `gpufreq/v2_legacy/gpufreq_history_mt6877.c` | C | GPUFreq | - | 1334 |
| 144 | `gpufreq/v2_legacy/gpufreq_history_mt6893.c` | C | GPUFreq | - | 1317 |
| 145 | `gpufreq/v2_legacy/gpufreq_mt6761.c` | C | GPUFreq | - | 73740 |
| 146 | `gpufreq/v2_legacy/gpufreq_mt6765.c` | C | GPUFreq | - | 71462 |
| 147 | `gpufreq/v2_legacy/gpufreq_mt6768.c` | C | GPUFreq | - | 85327 |
| 148 | `gpufreq/v2_legacy/gpufreq_mt6781.c` | C | GPUFreq | - | 86404 |
| 149 | `gpufreq/v2_legacy/gpufreq_mt6833.c` | C | GPUFreq | - | 115262 |
| 150 | `gpufreq/v2_legacy/gpufreq_mt6853.c` | C | GPUFreq | - | 86729 |
| 151 | `gpufreq/v2_legacy/gpufreq_mt6877.c` | C | GPUFreq | - | 89600 |
| 152 | `gpufreq/v2_legacy/gpufreq_mt6893.c` | C | GPUFreq | - | 84015 |
| 153 | `gpufreq/v2_legacy/gpufreq_v2_legacy.c` | C | GPUFreq | - | 71565 |
| 154 | `gpufreq/v2_legacy/gpuppm_legacy.c` | C | GPUFreq | - | 23896 |
| 155 | `gpufreq/v2_legacy/include/gpu_misc.h` | H | GPUFreq | - | 1350 |
| 156 | `gpufreq/v2_legacy/include/gpufreq_common_legacy.h` | H | GPUFreq | - | 8110 |
| 157 | `gpufreq/v2_legacy/include/gpufreq_debug_legacy.h` | H | GPUFreq | - | 3114 |
| 158 | `gpufreq/v2_legacy/include/gpufreq_early_init.h` | H | GPUFreq | - | 227 |
| 159 | `gpufreq/v2_legacy/include/gpufreq_history.h` | H | GPUFreq | - | 674 |
| 160 | `gpufreq/v2_legacy/include/gpufreq_history_common.h` | H | GPUFreq | - | 1289 |
| 161 | `gpufreq/v2_legacy/include/gpufreq_history_mt6761.h` | H | GPUFreq | - | 1909 |
| 162 | `gpufreq/v2_legacy/include/gpufreq_history_mt6765.h` | H | GPUFreq | - | 1909 |
| 163 | `gpufreq/v2_legacy/include/gpufreq_history_mt6768.h` | H | GPUFreq | - | 1909 |
| 164 | `gpufreq/v2_legacy/include/gpufreq_history_mt6781.h` | H | GPUFreq | - | 164 |
| 165 | `gpufreq/v2_legacy/include/gpufreq_history_mt6833.h` | H | GPUFreq | - | 164 |
| 166 | `gpufreq/v2_legacy/include/gpufreq_history_mt6853.h` | H | GPUFreq | - | 164 |
| 167 | `gpufreq/v2_legacy/include/gpufreq_history_mt6877.h` | H | GPUFreq | - | 164 |
| 168 | `gpufreq/v2_legacy/include/gpufreq_history_mt6893.h` | H | GPUFreq | - | 1903 |
| 169 | `gpufreq/v2_legacy/include/gpufreq_ipi.h` | H | GPUFreq | - | 3298 |
| 170 | `gpufreq/v2_legacy/include/gpufreq_mssv.h` | H | GPUFreq | - | 807 |
| 171 | `gpufreq/v2_legacy/include/gpufreq_mt6761.h` | H | GPUFreq | - | 11452 |
| 172 | `gpufreq/v2_legacy/include/gpufreq_mt6765.h` | H | GPUFreq | - | 8268 |
| 173 | `gpufreq/v2_legacy/include/gpufreq_mt6768.h` | H | GPUFreq | - | 10917 |
| 174 | `gpufreq/v2_legacy/include/gpufreq_mt6781.h` | H | GPUFreq | - | 11065 |
| 175 | `gpufreq/v2_legacy/include/gpufreq_mt6833.h` | H | GPUFreq | - | 17521 |
| 176 | `gpufreq/v2_legacy/include/gpufreq_mt6853.h` | H | GPUFreq | - | 14953 |
| 177 | `gpufreq/v2_legacy/include/gpufreq_mt6877.h` | H | GPUFreq | - | 16989 |
| 178 | `gpufreq/v2_legacy/include/gpufreq_mt6893.h` | H | GPUFreq | - | 11975 |
| 179 | `gpufreq/v2_legacy/include/gpufreq_v2_legacy.h` | H | GPUFreq | - | 21630 |
| 180 | `gpufreq/v2_legacy/include/gpuppm_legacy.h` | H | GPUFreq | - | 2454 |
| 181 | `gpufreq_v1/Makefile` | MK | GPUFreq-v1 | - | 1297 |
| 182 | `gpufreq_v1/include/mtk_gpufreq.h` | H | GPUFreq-v1 | - | 386 |
| 183 | `gpufreq_v1/include/mtk_gpufreq_common.h` | H | GPUFreq-v1 | - | 684 |
| 184 | `gpufreq_v1/include/mtk_gpufreq_internal.h` | H | GPUFreq-v1 | - | 440 |
| 185 | `gpufreq_v1/mtk_gpufreq_common.c` | C | GPUFreq-v1 | - | 1905 |
| 186 | `hal/Makefile` | MK | HAL | 共用 | 736 |
| 187 | `hal/mtk_gpu_utility.c` | C | HAL | 共用 | 19445 |
| 188 | `mt-plat/mtk_gpu_utility.h` | H | plat-head | - | 3723 |

## B2. MTK 功耗限流源码 — R3 `drivers/misc/mediatek/power_throttling/`（23 个文件）

> 此前被误判为「缺失」。`mtk_gpu_power_throttling.ko` 的源码在此。

| # | 相对路径 | 类型 | 组件 | 字节 |
| ---: | --- | :--: | --- | ---: |
| 1 | `Kconfig` | MK | 其他功耗限流 | 3496 |
| 2 | `Makefile` | MK | 其他功耗限流 | 1017 |
| 3 | `mtk_battery_oc_throttling.c` | C | 其他功耗限流 | 26627 |
| 4 | `mtk_battery_oc_throttling.h` | H | 其他功耗限流 | 1172 |
| 5 | `mtk_bp_thl.c` | C | 其他功耗限流 | 16612 |
| 6 | `mtk_bp_thl.h` | H | 其他功耗限流 | 1510 |
| 7 | `mtk_bp_thl_dbg.c` | C | 其他功耗限流 | 2348 |
| 8 | `mtk_cpu_power_throttling.c` | C | 其他功耗限流 | 12484 |
| 9 | `mtk_cpu_power_throttling.h` | H | 其他功耗限流 | 752 |
| 10 | `mtk_dynamic_loading_throttling.c` | C | 其他功耗限流 | 11483 |
| 11 | `mtk_dynamic_loading_throttling.h` | H | 其他功耗限流 | 736 |
| 12 | `mtk_gpu_power_throttling.c` | C | GPU 功耗限流 | 6254 |
| 13 | `mtk_gpu_power_throttling.h` | H | GPU 功耗限流 | 336 |
| 14 | `mtk_low_battery_throttling.c` | C | 其他功耗限流 | 45813 |
| 15 | `mtk_low_battery_throttling.h` | H | 其他功耗限流 | 2317 |
| 16 | `mtk_low_battery_throttling_trace.h` | H | 其他功耗限流 | 1935 |
| 17 | `mtk_md_power_throttling.c` | C | 其他功耗限流 | 9065 |
| 18 | `mtk_md_power_throttling.h` | H | 其他功耗限流 | 712 |
| 19 | `pmic_dual_lbat_service.c` | C | 其他功耗限流 | 29511 |
| 20 | `pmic_lbat_service.c` | C | 其他功耗限流 | 36456 |
| 21 | `pmic_lbat_service.h` | H | 其他功耗限流 | 2554 |
| 22 | `pmic_lvsys_notify.c` | C | 其他功耗限流 | 17410 |
| 23 | `pmic_lvsys_notify.h` | H | 其他功耗限流 | 997 |

## A′. R3 中的 Mali 驱动副本 — `drivers/gpu/mediatek/gpu_mali/`（1174 个文件）

仓库：`MiCode/MTK_kernel_device_modules` @ `e45c3199`

> **性质**：与 §A 属同一份上游代码的另一份拷贝。其中 `mali-r49p1/` 559 条经 `comm` 验证为 R2 的**严格子集**（仅 R2 多 22 条，见报告 §7）；`mali-r47p0/` 613 条为上一代 DDK，**与目标无关**。

| # | 相对路径 | 类型 | 字节 |
| ---: | --- | :--: | ---: |
| 1 | `gpu_mali/Makefile` | MK | 570 |
| 2 | `gpu_mali/mali_avalon/Makefile` | MK | 1112 |
| 3 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/Kbuild` | MK | 1189 |
| 4 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/Kconfig` | MK | 2165 |
| 5 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/Makefile` | MK | 5415 |
| 6 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/Mconfig` | ETC | 2151 |
| 7 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/dma_buf_test_exporter/Kbuild.bak` | MK | 892 |
| 8 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/dma_buf_test_exporter/Makefile` | MK | 1265 |
| 9 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/dma_buf_test_exporter/build.bp` | ETC | 1165 |
| 10 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/dma_buf_test_exporter/dma-buf-test-exporter.c` | C | 21009 |
| 11 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/memory_group_manager/Kbuild.bak` | MK | 879 |
| 12 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/memory_group_manager/Makefile` | MK | 1547 |
| 13 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/memory_group_manager/build.bp` | ETC | 1145 |
| 14 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/memory_group_manager/init.mali_mgm.rc` | ETC | 316 |
| 15 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/memory_group_manager/memory_group_manager.c` | C | 36689 |
| 16 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/memory_group_manager/mtk_platform_utils.h` | H | 386 |
| 17 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/protected_memory_allocator/Kbuild.bak` | MK | 891 |
| 18 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/protected_memory_allocator/Makefile` | MK | 2121 |
| 19 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/protected_memory_allocator/build.bp` | ETC | 1169 |
| 20 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/protected_memory_allocator/init.mali_prot_alloc.rc` | ETC | 356 |
| 21 | `gpu_mali/mali_avalon/mali-r47p0/drivers/base/arm/protected_memory_allocator/protected_memory_allocator.c` | C | 34909 |
| 22 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/Kbuild` | MK | 840 |
| 23 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/Kconfig` | MK | 899 |
| 24 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/Makefile` | MK | 880 |
| 25 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/Kbuild-mtk-custom-env` | MK | 14654 |
| 26 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/Kbuild.bak` | MK | 7087 |
| 27 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/Kconfig` | MK | 13195 |
| 28 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/Makefile` | MK | 14000 |
| 29 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/Mconfig` | ETC | 13095 |
| 30 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/arbiter/Kbuild` | MK | 882 |
| 31 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/arbiter/mali_kbase_arbif.c` | C | 9869 |
| 32 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/arbiter/mali_kbase_arbif.h` | H | 4433 |
| 33 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/arbiter/mali_kbase_arbiter_defs.h` | H | 2896 |
| 34 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/arbiter/mali_kbase_arbiter_pm.c` | C | 35341 |
| 35 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/arbiter/mali_kbase_arbiter_pm.h` | H | 7663 |
| 36 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/Kbuild` | MK | 2096 |
| 37 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_cache_policy_backend.c` | C | 2049 |
| 38 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_cache_policy_backend.h` | H | 1575 |
| 39 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_clk_rate_trace_mgr.c` | C | 8853 |
| 40 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_clk_rate_trace_mgr.h` | H | 4945 |
| 41 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_debug_job_fault_backend.c` | C | 5247 |
| 42 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_defs.h` | H | 4451 |
| 43 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_devfreq.c` | C | 22417 |
| 44 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_devfreq.h` | H | 2671 |
| 45 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_gpuprops_backend.c` | C | 4810 |
| 46 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_instr_backend.c` | C | 13809 |
| 47 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_instr_defs.h` | H | 1855 |
| 48 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_instr_internal.h` | H | 1334 |
| 49 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_irq_internal.h` | H | 3455 |
| 50 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_irq_linux.c` | C | 13195 |
| 51 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_as.c` | C | 6665 |
| 52 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_hw.c` | C | 46207 |
| 53 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_internal.h` | H | 3990 |
| 54 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_rb.c` | C | 57684 |
| 55 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_rb.h` | H | 2710 |
| 56 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_js_backend.c` | C | 12704 |
| 57 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_js_internal.h` | H | 2350 |
| 58 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_l2_mmu_config.c` | C | 4174 |
| 59 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_l2_mmu_config.h` | H | 1329 |
| 60 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_model_dummy.c` | C | 56815 |
| 61 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_model_dummy.h` | H | 6793 |
| 62 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_model_error_generator.c` | C | 5235 |
| 63 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_model_linux.c` | C | 4853 |
| 64 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_model_linux.h` | H | 4243 |
| 65 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_always_on.c` | C | 1981 |
| 66 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_always_on.h` | H | 2664 |
| 67 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_backend.c` | C | 34102 |
| 68 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_ca.c` | C | 3842 |
| 69 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_ca.h` | H | 3227 |
| 70 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_ca_devfreq.h` | H | 1912 |
| 71 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_coarse_demand.c` | C | 1932 |
| 72 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_coarse_demand.h` | H | 2364 |
| 73 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_defs.h` | H | 30103 |
| 74 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_driver.c` | C | 108538 |
| 75 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_internal.h` | H | 34032 |
| 76 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_l2_states.h` | H | 2186 |
| 77 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_mcu_states.h` | H | 6181 |
| 78 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_metrics.c` | C | 18627 |
| 79 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_policy.c` | C | 12783 |
| 80 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_policy.h` | H | 3429 |
| 81 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_shader_states.h` | H | 4153 |
| 82 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_time.c` | C | 10798 |
| 83 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/build.bp` | ETC | 8859 |
| 84 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/context/Kbuild` | MK | 1031 |
| 85 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/context/backend/mali_kbase_context_csf.c` | C | 7035 |
| 86 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/context/backend/mali_kbase_context_jm.c` | C | 8558 |
| 87 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/context/mali_kbase_context.c` | C | 10473 |
| 88 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/context/mali_kbase_context.h` | H | 4536 |
| 89 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/context/mali_kbase_context_internal.h` | H | 2258 |
| 90 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/Kbuild` | MK | 2198 |
| 91 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/ipa_control/Kbuild` | MK | 862 |
| 92 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/ipa_control/mali_kbase_csf_ipa_control.c` | C | 33212 |
| 93 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/ipa_control/mali_kbase_csf_ipa_control.h` | H | 11150 |
| 94 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/ipa_control/mali_kbase_csf_ipa_control_ex.h` | H | 724 |
| 95 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf.c` | C | 115335 |
| 96 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf.h` | H | 20941 |
| 97 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_cpu_queue.c` | C | 6246 |
| 98 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_cpu_queue.h` | H | 3267 |
| 99 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_cpu_queue_debugfs.c` | C | 2545 |
| 100 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_cpu_queue_debugfs.h` | H | 1233 |
| 101 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_csg.c` | C | 22831 |
| 102 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_csg.h` | H | 1874 |
| 103 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_csg_debugfs.c` | C | 9077 |
| 104 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_csg_debugfs.h` | H | 1433 |
| 105 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_defs.h` | H | 84231 |
| 106 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_event.c` | C | 8073 |
| 107 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_event.h` | H | 6149 |
| 108 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware.c` | C | 105122 |
| 109 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware.h` | H | 35736 |
| 110 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_cfg.c` | C | 12334 |
| 111 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_cfg.h` | H | 3790 |
| 112 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_core_dump.c` | C | 25597 |
| 113 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_core_dump.h` | H | 2450 |
| 114 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_log.c` | C | 21897 |
| 115 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_log.h` | H | 2554 |
| 116 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_no_mali.c` | C | 51002 |
| 117 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_heap_context_alloc.c` | C | 7605 |
| 118 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_heap_context_alloc.h` | H | 2854 |
| 119 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu.c` | C | 103965 |
| 120 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu.h` | H | 15532 |
| 121 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu_debugfs.c` | C | 5373 |
| 122 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu_debugfs.h` | H | 1236 |
| 123 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu_fence_debugfs.c` | C | 4567 |
| 124 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu_fence_debugfs.h` | H | 1495 |
| 125 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_mcu_shared_reg.c` | C | 29896 |
| 126 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_mcu_shared_reg.h` | H | 6123 |
| 127 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_protected_memory.c` | C | 4463 |
| 128 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_protected_memory.h` | H | 2519 |
| 129 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_registers.h` | H | 102552 |
| 130 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_reset_gpu.c` | C | 29072 |
| 131 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_scheduler.c` | C | 264268 |
| 132 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_scheduler.h` | H | 24470 |
| 133 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_sync.c` | C | 29122 |
| 134 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_sync.h` | H | 1599 |
| 135 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_sync_debugfs.c` | C | 2657 |
| 136 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_sync_debugfs.h` | H | 1203 |
| 137 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap.c` | C | 45177 |
| 138 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap.h` | H | 6630 |
| 139 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_debugfs.c` | C | 5101 |
| 140 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_debugfs.h` | H | 1528 |
| 141 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_def.h` | H | 5835 |
| 142 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_reclaim.c` | C | 13979 |
| 143 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_reclaim.h` | H | 3116 |
| 144 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_timeout.c` | C | 5407 |
| 145 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_timeout.h` | H | 2397 |
| 146 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tl_reader.c` | C | 11356 |
| 147 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tl_reader.h` | H | 4868 |
| 148 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_trace_buffer.c` | C | 24146 |
| 149 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_trace_buffer.h` | H | 7608 |
| 150 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_util.c` | C | 6966 |
| 151 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_csf_util.h` | H | 3279 |
| 152 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_debug_csf_fault.c` | C | 7276 |
| 153 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/csf/mali_kbase_debug_csf_fault.h` | H | 4019 |
| 154 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/Kbuild` | MK | 1108 |
| 155 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_coresight_csf.c` | C | 24935 |
| 156 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_coresight_internal_csf.h` | H | 6897 |
| 157 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_codes_csf.h` | H | 12932 |
| 158 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_codes_jm.h` | H | 8132 |
| 159 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_csf.c` | C | 5852 |
| 160 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_csf.h` | H | 8728 |
| 161 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_defs_csf.h` | H | 4589 |
| 162 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_defs_jm.h` | H | 4197 |
| 163 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_jm.c` | C | 3982 |
| 164 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_jm.h` | H | 15722 |
| 165 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_linux_ktrace_csf.h` | H | 10799 |
| 166 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_linux_ktrace_jm.h` | H | 7442 |
| 167 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace.c` | C | 9650 |
| 168 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace.h` | H | 7503 |
| 169 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace_codes.h` | H | 6356 |
| 170 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace_defs.h` | H | 6260 |
| 171 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace_internal.h` | H | 3340 |
| 172 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/debug/mali_kbase_debug_linux_ktrace.h` | H | 4505 |
| 173 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/device/Kbuild` | MK | 1163 |
| 174 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/device/backend/mali_kbase_device_csf.c` | C | 18508 |
| 175 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/device/backend/mali_kbase_device_hw_csf.c` | C | 7490 |
| 176 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/device/backend/mali_kbase_device_hw_jm.c` | C | 4044 |
| 177 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/device/backend/mali_kbase_device_jm.c` | C | 12037 |
| 178 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/device/mali_kbase_device.c` | C | 16561 |
| 179 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/device/mali_kbase_device.h` | H | 7130 |
| 180 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/device/mali_kbase_device_hw.c` | C | 11236 |
| 181 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/device/mali_kbase_device_internal.h` | H | 3333 |
| 182 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/gpu/Kbuild` | MK | 1003 |
| 183 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/gpu/backend/mali_kbase_gpu_fault_csf.c` | C | 5537 |
| 184 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/gpu/backend/mali_kbase_gpu_fault_jm.c` | C | 3079 |
| 185 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/gpu/mali_kbase_gpu.c` | C | 1306 |
| 186 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/gpu/mali_kbase_gpu_fault.h` | H | 1602 |
| 187 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/Kbuild` | MK | 1187 |
| 188 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/backend/mali_kbase_hw_access_model_linux.c` | C | 4579 |
| 189 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/backend/mali_kbase_hw_access_real_hw.c` | C | 5136 |
| 190 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/mali_kbase_hw_access.c` | C | 3430 |
| 191 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/mali_kbase_hw_access.h` | H | 7433 |
| 192 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/mali_kbase_hw_access_regmap.h` | H | 24089 |
| 193 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/mali_kbase_hw_access_regmap_legacy.h` | H | 12159 |
| 194 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_csf.c` | C | 91430 |
| 195 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_csf_enums.h` | H | 20247 |
| 196 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_csf_macros.h` | H | 21572 |
| 197 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_jm.c` | C | 194301 |
| 198 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_jm_enums.h` | H | 41969 |
| 199 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_jm_macros.h` | H | 14852 |
| 200 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_legacy_csf.h` | H | 3324 |
| 201 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_legacy_jm.h` | H | 6069 |
| 202 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/Kbuild` | MK | 1322 |
| 203 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend.h` | H | 9524 |
| 204 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf.c` | C | 83370 |
| 205 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf.h` | H | 7874 |
| 206 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf_if.h` | H | 13191 |
| 207 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf_if_fw.c` | C | 27345 |
| 208 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf_if_fw.h` | H | 1868 |
| 209 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_jm.c` | C | 32891 |
| 210 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_jm.h` | H | 1989 |
| 211 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_jm_watchdog.c` | C | 32828 |
| 212 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_jm_watchdog.h` | H | 2836 |
| 213 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt.c` | C | 25409 |
| 214 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_accumulator.h` | H | 5870 |
| 215 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_context.h` | H | 6139 |
| 216 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_gpu.c` | C | 31543 |
| 217 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_gpu.h` | H | 20485 |
| 218 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_types.c` | C | 16177 |
| 219 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_types.h` | H | 50567 |
| 220 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_virtualizer.c` | C | 24351 |
| 221 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_virtualizer.h` | H | 6596 |
| 222 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_watchdog_if.h` | H | 3051 |
| 223 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_watchdog_if_timer.c` | C | 4790 |
| 224 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_watchdog_if_timer.h` | H | 1738 |
| 225 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/linux/mali_arbiter_interface.h` | H | 7544 |
| 226 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/linux/mali_kbase_debug_coresight_csf.h` | H | 8289 |
| 227 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/linux/memory_group_manager.h` | H | 9532 |
| 228 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/linux/priority_control_manager.h` | H | 5478 |
| 229 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/linux/protected_memory_allocator.h` | H | 4001 |
| 230 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/linux/protected_mode_switcher.h` | H | 2085 |
| 231 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/linux/version_compat_defs.h` | H | 12007 |
| 232 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/base/arm/dma_buf_test_exporter/dma-buf-test-exporter.h` | H | 2783 |
| 233 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/backend/gpu/mali_kbase_model_dummy.h` | H | 3045 |
| 234 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/backend/gpu/mali_kbase_model_linux.h` | H | 1203 |
| 235 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/csf/mali_base_csf_kernel.h` | H | 21938 |
| 236 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_errors_dumpfault.h` | H | 3206 |
| 237 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_ioctl.h` | H | 23458 |
| 238 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/backend/mali_kbase_gpu_regmap_csf.h` | H | 1259 |
| 239 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/backend/mali_kbase_gpu_regmap_jm.h` | H | 938 |
| 240 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/mali_kbase_gpu_coherency.h` | H | 1066 |
| 241 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/mali_kbase_gpu_id.h` | H | 8504 |
| 242 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/mali_kbase_gpu_regmap.h` | H | 977 |
| 243 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/jm/mali_base_jm_kernel.h` | H | 46344 |
| 244 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/jm/mali_kbase_jm_ioctl.h` | H | 9235 |
| 245 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_base_common_kernel.h` | H | 7556 |
| 246 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_base_kernel.h` | H | 24703 |
| 247 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_base_mem_priv.h` | H | 1870 |
| 248 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_gpu_props.h` | H | 3120 |
| 249 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_kbase_hwcnt_reader.h` | H | 18005 |
| 250 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_kbase_ioctl.h` | H | 24938 |
| 251 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_kbase_kinstr_jm_reader.h` | H | 2995 |
| 252 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_kbase_mem_profile_debugfs_buf_size.h` | H | 1360 |
| 253 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/ipa/Kbuild` | MK | 1239 |
| 254 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_common_csf.c` | C | 14601 |
| 255 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_common_csf.h` | H | 7326 |
| 256 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_common_jm.c` | C | 10430 |
| 257 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_common_jm.h` | H | 9207 |
| 258 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_csf.c` | C | 12715 |
| 259 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_jm.c` | C | 16559 |
| 260 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/ipa/mali_kbase_ipa.c` | C | 22528 |
| 261 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/ipa/mali_kbase_ipa.h` | H | 11123 |
| 262 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/ipa/mali_kbase_ipa_debugfs.c` | C | 7792 |
| 263 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/ipa/mali_kbase_ipa_debugfs.h` | H | 2214 |
| 264 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/ipa/mali_kbase_ipa_simple.c` | C | 11425 |
| 265 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/ipa/mali_kbase_ipa_simple.h` | H | 1642 |
| 266 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/jm/mali_kbase_jm_defs.h` | H | 38769 |
| 267 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/jm/mali_kbase_jm_js.h` | H | 39542 |
| 268 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/jm/mali_kbase_js_defs.h` | H | 19329 |
| 269 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_base_hwconfig_features.h` | H | 6387 |
| 270 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_base_hwconfig_issues.h` | H | 27028 |
| 271 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase.h` | H | 22741 |
| 272 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_as_fault_debugfs.c` | C | 3097 |
| 273 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_as_fault_debugfs.h` | H | 1678 |
| 274 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_cache_policy.c` | C | 2029 |
| 275 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_cache_policy.h` | H | 1555 |
| 276 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_caps.h` | H | 2225 |
| 277 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_ccswe.c` | C | 2653 |
| 278 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_ccswe.h` | H | 3197 |
| 279 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_config.c` | C | 2196 |
| 280 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_config.h` | H | 18192 |
| 281 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_config_defaults.h` | H | 11456 |
| 282 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_core_linux.c` | C | 171622 |
| 283 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_cs_experimental.h` | H | 1296 |
| 284 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_ctx_sched.c` | C | 10811 |
| 285 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_ctx_sched.h` | H | 9622 |
| 286 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_debug.c` | C | 1387 |
| 287 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_debug.h` | H | 5988 |
| 288 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_debug_job_fault.c` | C | 15981 |
| 289 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_debug_job_fault.h` | H | 4170 |
| 290 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_debug_mem_allocs.c` | C | 4065 |
| 291 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_debug_mem_allocs.h` | H | 1340 |
| 292 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_debug_mem_view.c` | C | 9622 |
| 293 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_debug_mem_view.h` | H | 1370 |
| 294 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_debug_mem_zones.c` | C | 3247 |
| 295 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_debug_mem_zones.h` | H | 1357 |
| 296 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_debugfs_helper.c` | C | 6020 |
| 297 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_debugfs_helper.h` | H | 6737 |
| 298 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_defs.h` | H | 100896 |
| 299 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_disjoint_events.c` | C | 2167 |
| 300 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_dummy_job_wa.c` | C | 10880 |
| 301 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_dummy_job_wa.h` | H | 1795 |
| 302 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_dvfs_debugfs.c` | C | 2913 |
| 303 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_dvfs_debugfs.h` | H | 1198 |
| 304 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_event.c` | C | 8025 |
| 305 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_fence.c` | C | 1496 |
| 306 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_fence.h` | H | 4296 |
| 307 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_fence_ops.c` | C | 2389 |
| 308 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_gator.h` | H | 1836 |
| 309 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_gpu_memory_debugfs.c` | C | 3035 |
| 310 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_gpu_memory_debugfs.h` | H | 1666 |
| 311 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_gpu_metrics.c` | C | 10120 |
| 312 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_gpu_metrics.h` | H | 6931 |
| 313 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_gpuprops.c` | C | 30421 |
| 314 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_gpuprops.h` | H | 5489 |
| 315 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_gpuprops_private_types.h` | H | 2969 |
| 316 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_gpuprops_types.h` | H | 8846 |
| 317 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_gwt.c` | C | 7079 |
| 318 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_gwt.h` | H | 1675 |
| 319 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_hw.c` | C | 14358 |
| 320 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_hw.h` | H | 2507 |
| 321 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_hwaccess_backend.h` | H | 1386 |
| 322 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_hwaccess_defs.h` | H | 1735 |
| 323 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_hwaccess_gpuprops.h` | H | 2828 |
| 324 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_hwaccess_instr.h` | H | 5279 |
| 325 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_hwaccess_jm.h` | H | 10013 |
| 326 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_hwaccess_pm.h` | H | 6978 |
| 327 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_hwaccess_time.h` | H | 6538 |
| 328 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_jd.c` | C | 50532 |
| 329 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_jd_debugfs.c` | C | 5324 |
| 330 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_jd_debugfs.h` | H | 1273 |
| 331 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_jm.c` | C | 951 |
| 332 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_jm.h` | H | 927 |
| 333 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_js.c` | C | 129159 |
| 334 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_js.h` | H | 1129 |
| 335 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_js_ctx_attr.c` | C | 11486 |
| 336 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_js_ctx_attr.h` | H | 4847 |
| 337 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_kinstr_jm.c` | C | 27718 |
| 338 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_kinstr_jm.h` | H | 10073 |
| 339 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_kinstr_prfcnt.c` | C | 67257 |
| 340 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_kinstr_prfcnt.h` | H | 8630 |
| 341 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_linux.h` | H | 1349 |
| 342 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mem.c` | C | 142132 |
| 343 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mem.h` | H | 103794 |
| 344 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mem_linux.c` | C | 117637 |
| 345 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mem_linux.h` | H | 21546 |
| 346 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mem_lowlevel.h` | H | 6365 |
| 347 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mem_migrate.c` | C | 23354 |
| 348 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mem_migrate.h` | H | 4346 |
| 349 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mem_pool.c` | C | 33030 |
| 350 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mem_pool_debugfs.c` | C | 5275 |
| 351 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mem_pool_debugfs.h` | H | 4910 |
| 352 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mem_pool_group.c` | C | 3185 |
| 353 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mem_pool_group.h` | H | 4362 |
| 354 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mem_profile_debugfs.c` | C | 4037 |
| 355 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mem_profile_debugfs.h` | H | 2199 |
| 356 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mipe_gen_header.h` | H | 6133 |
| 357 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_mipe_proto.h` | H | 4284 |
| 358 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_native_mgm.c` | C | 6993 |
| 359 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_native_mgm.h` | H | 1371 |
| 360 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_pbha.c` | C | 9031 |
| 361 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_pbha.h` | H | 2300 |
| 362 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_pbha_debugfs.c` | C | 6504 |
| 363 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_pbha_debugfs.h` | H | 1098 |
| 364 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_platform_fake.c` | C | 3978 |
| 365 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_pm.c` | C | 8947 |
| 366 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_pm.h` | H | 9407 |
| 367 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_reg_track.c` | C | 42431 |
| 368 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_reg_track.h` | H | 15123 |
| 369 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_regs_history_debugfs.c` | C | 6382 |
| 370 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_regs_history_debugfs.h` | H | 2752 |
| 371 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_reset_gpu.h` | H | 10569 |
| 372 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_smc.c` | C | 2709 |
| 373 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_smc.h` | H | 2127 |
| 374 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_softjobs.c` | C | 2634 |
| 375 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_sync.h` | H | 2965 |
| 376 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_sync_common.c` | C | 1142 |
| 377 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_sync_file.c` | C | 2485 |
| 378 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_trace_gpu_mem.c` | C | 6650 |
| 379 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_kbase_trace_gpu_mem.h` | H | 2926 |
| 380 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_linux_trace.h` | H | 22336 |
| 381 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_malisw.h` | H | 3036 |
| 382 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_power_gpu_frequency_trace.c` | C | 995 |
| 383 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_power_gpu_frequency_trace.h` | H | 1865 |
| 384 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_power_gpu_work_period_trace.c` | C | 1103 |
| 385 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mali_power_gpu_work_period_trace.h` | H | 2708 |
| 386 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mmu/Kbuild` | MK | 1063 |
| 387 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_csf.c` | C | 40790 |
| 388 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_jm.c` | C | 13852 |
| 389 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu.c` | C | 132796 |
| 390 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu.h` | H | 14192 |
| 391 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_hw.h` | H | 7634 |
| 392 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_hw_direct.c` | C | 23764 |
| 393 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_internal.h` | H | 2520 |
| 394 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_mode_aarch64.c` | C | 6400 |
| 395 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/Kconfig` | MK | 994 |
| 396 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/devicetree/Kbuild` | MK | 1013 |
| 397 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/devicetree/mali_kbase_clk_rate_trace.c` | C | 3428 |
| 398 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/devicetree/mali_kbase_config_devicetree.c` | C | 1358 |
| 399 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/devicetree/mali_kbase_config_platform.h` | H | 1597 |
| 400 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/devicetree/mali_kbase_runtime_pm.c` | C | 7330 |
| 401 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/meson/Kbuild` | MK | 944 |
| 402 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/meson/mali_kbase_config_meson.c` | C | 1358 |
| 403 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/meson/mali_kbase_config_platform.h` | H | 1485 |
| 404 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/meson/mali_kbase_runtime_pm.c` | C | 6838 |
| 405 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mt6991/Kbuild` | MK | 1056 |
| 406 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mt6991/mali_kbase_config_mt6991.c` | C | 15429 |
| 407 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mt6991/mali_kbase_config_platform.h` | H | 538 |
| 408 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common.h` | H | 5111 |
| 409 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/Kbuild` | MK | 2942 |
| 410 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_gpu_power_model_sspm_ipi.c` | C | 1696 |
| 411 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_gpu_power_model_sspm_ipi.h` | H | 839 |
| 412 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_adaptive_power_policy.c` | C | 1512 |
| 413 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_adaptive_power_policy.h` | H | 312 |
| 414 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_cm7_trace.c` | C | 2591 |
| 415 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_cm7_trace.h` | H | 327 |
| 416 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_common.c` | C | 20127 |
| 417 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug.h` | H | 3395 |
| 418 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_cpu.c` | C | 3976 |
| 419 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_csg.c` | C | 6313 |
| 420 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_enop_metadata.c` | C | 6963 |
| 421 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_gpu.c` | C | 54846 |
| 422 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_gpu_debugfs.c` | C | 2209 |
| 423 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_infra_status.c` | C | 1393 |
| 424 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_kcpu.c` | C | 14539 |
| 425 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_pm_status.c` | C | 4267 |
| 426 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_devfreq_governor.c` | C | 4473 |
| 427 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_devfreq_governor.h` | H | 560 |
| 428 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_devfreq_thermal.c` | C | 2279 |
| 429 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_devfreq_thermal.h` | H | 1049 |
| 430 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_diagnosis_mode.c` | C | 3822 |
| 431 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_diagnosis_mode.h` | H | 424 |
| 432 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs.c` | C | 13907 |
| 433 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs.h` | H | 2691 |
| 434 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs_hint_26m_perf_cnting.c` | C | 5143 |
| 435 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs_hint_26m_perf_cnting.h` | H | 1094 |
| 436 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs_hint_26m_perf_cnting_ex.h` | H | 419 |
| 437 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_logbuffer.c` | C | 12787 |
| 438 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_logbuffer.h` | H | 1393 |
| 439 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_memtrack.c` | C | 4064 |
| 440 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_memtrack.h` | H | 476 |
| 441 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_qinspect.c` | C | 50890 |
| 442 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_qinspect.h` | H | 10802 |
| 443 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_qinspect_recovery.c` | C | 19051 |
| 444 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_qinspect_recovery.h` | H | 436 |
| 445 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_fault_worker.c` | C | 2287 |
| 446 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_fault_worker.h` | H | 309 |
| 447 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_force_hard_reset.c` | C | 2610 |
| 448 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_force_hard_reset.h` | H | 420 |
| 449 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/mtk_platform_utils.h` | H | 386 |
| 450 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/vexpress/Kbuild` | MK | 931 |
| 451 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/vexpress/mali_kbase_config_platform.h` | H | 1335 |
| 452 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/vexpress/mali_kbase_config_vexpress.c` | C | 2147 |
| 453 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/vexpress_1xv7_a57/Kbuild` | MK | 931 |
| 454 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/vexpress_1xv7_a57/mali_kbase_config_platform.h` | H | 1335 |
| 455 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/vexpress_1xv7_a57/mali_kbase_config_vexpress.c` | C | 2091 |
| 456 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/vexpress_6xvirtex7_10mhz/Kbuild` | MK | 988 |
| 457 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/vexpress_6xvirtex7_10mhz/mali_kbase_config_platform.h` | H | 1335 |
| 458 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/platform/vexpress_6xvirtex7_10mhz/mali_kbase_config_vexpress.c` | C | 2091 |
| 459 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/protected_mode_switcher.h` | H | 1918 |
| 460 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/Kbuild` | MK | 1838 |
| 461 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/Kconfig` | MK | 3006 |
| 462 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/Mconfig` | ETC | 3047 |
| 463 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/build.bp` | ETC | 1558 |
| 464 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/include/kutf/kutf_helpers.h` | H | 4001 |
| 465 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/include/kutf/kutf_helpers_user.h` | H | 6481 |
| 466 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/include/kutf/kutf_kprobe.h` | H | 1124 |
| 467 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/include/kutf/kutf_mem.h` | H | 2309 |
| 468 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/include/kutf/kutf_resultset.h` | H | 5876 |
| 469 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/include/kutf/kutf_suite.h` | H | 22873 |
| 470 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/include/kutf/kutf_utils.h` | H | 2055 |
| 471 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf/Kbuild` | MK | 1008 |
| 472 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf/build.bp` | ETC | 1276 |
| 473 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf/kutf_helpers.c` | C | 3486 |
| 474 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf/kutf_helpers_user.c` | C | 13388 |
| 475 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf/kutf_kprobe.c` | C | 8896 |
| 476 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf/kutf_mem.c` | C | 2489 |
| 477 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf/kutf_resultset.c` | C | 3949 |
| 478 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf/kutf_suite.c` | C | 33916 |
| 479 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf/kutf_utils.c` | C | 1893 |
| 480 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test/kernel/Kbuild` | MK | 960 |
| 481 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test/kernel/build.bp` | ETC | 1051 |
| 482 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test/kernel/kutf_test_kprobe.c` | C | 1791 |
| 483 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test/kernel/kutf_test_kprobe.h` | H | 996 |
| 484 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test/kernel/kutf_test_main.c` | C | 5573 |
| 485 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test/kernel/kutf_test_userdata.c` | C | 5448 |
| 486 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test/kernel/kutf_test_userdata.h` | H | 1291 |
| 487 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test/test_runner/build.bp` | ETC | 1028 |
| 488 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test/test_runner/mali_kutf_simple_test_kprobe.c` | C | 4262 |
| 489 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test/test_runner/mali_kutf_simple_test_kprobe.h` | H | 724 |
| 490 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test/test_runner/mali_kutf_simple_test_runner_main.c` | C | 2509 |
| 491 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test/test_runner/mali_kutf_simple_test_userdata.c` | C | 11120 |
| 492 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test/test_runner/mali_kutf_simple_test_userdata.h` | H | 871 |
| 493 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test_runner/build.bp` | ETC | 1298 |
| 494 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test_runner/mali_kutf_test_helpers.c` | C | 15029 |
| 495 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test_runner/mali_kutf_test_helpers.h` | H | 7205 |
| 496 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test_runner/mali_kutf_test_runner.c` | C | 28904 |
| 497 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test_runner/mali_kutf_test_runner.h` | H | 6353 |
| 498 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/kutf_test_runner/mali_kutf_test_runner_main.c` | C | 1115 |
| 499 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_clk_rate_trace/kernel/Kbuild` | MK | 968 |
| 500 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_clk_rate_trace/kernel/build.bp` | ETC | 1361 |
| 501 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_clk_rate_trace/kernel/mali_kutf_clk_rate_trace_test.c` | C | 29446 |
| 502 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_clk_rate_trace/mali_kutf_clk_rate_trace_test.h` | H | 7975 |
| 503 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_fault_unit_test/kernel/Kbuild` | MK | 955 |
| 504 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_fault_unit_test/kernel/build.bp` | ETC | 1349 |
| 505 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_fault_unit_test/kernel/mali_kutf_csf_fault_unit_test_main.c` | C | 34563 |
| 506 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_fault_unit_test/mali_kutf_csf_fault_unit_test.h` | H | 2645 |
| 507 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_fault_unit_test/test_runner/build.bp` | ETC | 1280 |
| 508 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_fault_unit_test/test_runner/mali_kutf_csf_fault_unit_test_extra.c` | C | 49112 |
| 509 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_fault_unit_test/test_runner/mali_kutf_csf_fault_unit_test_extra.h` | H | 832 |
| 510 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_fault_unit_test/test_runner/mali_kutf_csf_fault_unit_test_runner_main.c` | C | 2148 |
| 511 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_ipa_control_unit_test/kernel/Kbuild` | MK | 972 |
| 512 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_ipa_control_unit_test/kernel/build.bp` | ETC | 1367 |
| 513 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_ipa_control_unit_test/kernel/mali_kutf_csf_ipa_control_unit_test_main.c` | C | 51028 |
| 514 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_ipa_control_unit_test/mali_kutf_csf_ipa_control_unit_test.h` | H | 2394 |
| 515 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_ipa_control_unit_test/test_runner/build.bp` | ETC | 1294 |
| 516 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_ipa_control_unit_test/test_runner/mali_kutf_csf_ipa_control_unit_test_extra.c` | C | 4833 |
| 517 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_ipa_control_unit_test/test_runner/mali_kutf_csf_ipa_control_unit_test_extra.h` | H | 851 |
| 518 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_ipa_control_unit_test/test_runner/mali_kutf_csf_ipa_control_unit_test_runner_main.c` | C | 2090 |
| 519 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_tiler_heap_unit_test/kernel/Kbuild` | MK | 970 |
| 520 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_tiler_heap_unit_test/kernel/build.bp` | ETC | 1364 |
| 521 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_tiler_heap_unit_test/kernel/mali_kutf_csf_tiler_heap_unit_test_main.c` | C | 15959 |
| 522 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_tiler_heap_unit_test/mali_kutf_csf_tiler_heap_unit_test.h` | H | 1771 |
| 523 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_tiler_heap_unit_test/test_runner/build.bp` | ETC | 1118 |
| 524 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_tiler_heap_unit_test/test_runner/mali_kutf_csf_tiler_heap_unit_test_extra.c` | C | 24763 |
| 525 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_tiler_heap_unit_test/test_runner/mali_kutf_csf_tiler_heap_unit_test_extra.h` | H | 852 |
| 526 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_tiler_heap_unit_test/test_runner/mali_kutf_csf_tiler_heap_unit_test_runner_main.c` | C | 2196 |
| 527 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_timeout_unit_test/kernel/Kbuild` | MK | 961 |
| 528 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_timeout_unit_test/kernel/build.bp` | ETC | 1355 |
| 529 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_timeout_unit_test/kernel/mali_kutf_csf_timeout_unit_test_main.c` | C | 13025 |
| 530 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_timeout_unit_test/mali_kutf_csf_timeout_unit_test.h` | H | 1368 |
| 531 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_timeout_unit_test/test_runner/build.bp` | ETC | 1265 |
| 532 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_timeout_unit_test/test_runner/mali_kutf_csf_timeout_unit_test_extra.c` | C | 9896 |
| 533 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_timeout_unit_test/test_runner/mali_kutf_csf_timeout_unit_test_extra.h` | H | 840 |
| 534 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_csf_timeout_unit_test/test_runner/mali_kutf_csf_timeout_unit_test_runner_main.c` | C | 2166 |
| 535 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_ipa_unit_test/kernel/Kbuild` | MK | 952 |
| 536 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_ipa_unit_test/kernel/build.bp` | ETC | 1066 |
| 537 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_ipa_unit_test/kernel/mali_kutf_ipa_unit_test_main.c` | C | 43911 |
| 538 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_ipa_unit_test/mali_kutf_ipa_unit_test.h` | H | 4922 |
| 539 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_ipa_unit_test/test_runner/build.bp` | ETC | 976 |
| 540 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_ipa_unit_test/test_runner/mali_kutf_ipa_unit_test_extra.c` | C | 200011 |
| 541 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_ipa_unit_test/test_runner/mali_kutf_ipa_unit_test_extra.h` | H | 1102 |
| 542 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_ipa_unit_test/test_runner/mali_kutf_ipa_unit_test_runner_main.c` | C | 2418 |
| 543 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_irq_test/Kbuild` | MK | 926 |
| 544 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_irq_test/build.bp` | ETC | 1279 |
| 545 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_irq_test/mali_kutf_irq_test_main.c` | C | 7889 |
| 546 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/kernel/Kbuild` | MK | 1197 |
| 547 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/kernel/build.bp` | ETC | 1725 |
| 548 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/kernel/mali_kutf_kernel_defect_GPUCORE-27226.c` | C | 3783 |
| 549 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/kernel/mali_kutf_kernel_defect_GPUCORE-35490.c` | C | 6177 |
| 550 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/kernel/mali_kutf_kernel_defect_GPUCORE-37201.c` | C | 1307 |
| 551 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/kernel/mali_kutf_kernel_defect_GPUCORE-37465.c` | C | 11221 |
| 552 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/kernel/mali_kutf_kernel_defect_GPUCORE-39614.c` | C | 10055 |
| 553 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/kernel/mali_kutf_kernel_defect_test_main.c` | C | 5049 |
| 554 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/kernel/mali_kutf_kernel_defect_test_main.h` | H | 1687 |
| 555 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/mali_kutf_kernel_defect_test.h` | H | 1312 |
| 556 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/mali_kutf_kernel_defect_test_GPUCORE_37465.h` | H | 2237 |
| 557 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/test_runner/GPUCORE-35490.c` | C | 9964 |
| 558 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/test_runner/GPUCORE-37201.c` | C | 1142 |
| 559 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/test_runner/GPUCORE-37465.c` | C | 12074 |
| 560 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/test_runner/GPUCORE-39614.c` | C | 10851 |
| 561 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/test_runner/build.bp` | ETC | 1447 |
| 562 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/test_runner/mali_kutf_kernel_defect_test_extra.c` | C | 2085 |
| 563 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/test_runner/mali_kutf_kernel_defect_test_extra.h` | H | 1284 |
| 564 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/test_runner/mali_kutf_kernel_defect_test_helpers.c` | C | 1736 |
| 565 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/test_runner/mali_kutf_kernel_defect_test_helpers.h` | H | 1640 |
| 566 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/test_runner/mali_kutf_kernel_defect_test_runner_main.c` | C | 2191 |
| 567 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/kernel/Kbuild` | MK | 1223 |
| 568 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/kernel/build.bp` | ETC | 1720 |
| 569 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/kernel/mali_kutf_kernel_power_cycle.c` | C | 8674 |
| 570 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/kernel/mali_kutf_kernel_power_helpers.c` | C | 1545 |
| 571 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/kernel/mali_kutf_kernel_power_helpers.h` | H | 1078 |
| 572 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/kernel/mali_kutf_kernel_power_test_main.c` | C | 6553 |
| 573 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/kernel/mali_kutf_kernel_power_test_main.h` | H | 1816 |
| 574 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/kernel/mali_kutf_power_core_availability_cg0.c` | C | 2459 |
| 575 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/kernel/mali_kutf_power_core_mask.c` | C | 9532 |
| 576 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/kernel/mali_kutf_power_policy_unit.c` | C | 7228 |
| 577 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/mali_kutf_kernel_power_test.h` | H | 1837 |
| 578 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/test_runner/build.bp` | ETC | 1285 |
| 579 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/test_runner/mali_kutf_kernel_power_test_extra.c` | C | 9607 |
| 580 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/test_runner/mali_kutf_kernel_power_test_extra.h` | H | 2530 |
| 581 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_power_test/test_runner/mali_kutf_kernel_power_test_runner_main.c` | C | 2221 |
| 582 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_mgm_integration_test/Kbuild` | MK | 963 |
| 583 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_mgm_integration_test/build.bp` | ETC | 1321 |
| 584 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_mgm_integration_test/mali_kutf_mgm_integration_test_main.c` | C | 6789 |
| 585 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_pma_unit_test/kernel/Kbuild` | MK | 937 |
| 586 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_pma_unit_test/kernel/build.bp` | ETC | 1013 |
| 587 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tests/mali_kutf_pma_unit_test/kernel/mali_kutf_pma_unit_test_main.c` | C | 9449 |
| 588 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/thirdparty/Kbuild` | MK | 811 |
| 589 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/thirdparty/mali_kbase_mmap.c` | C | 13212 |
| 590 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/thirdparty/mm.h` | H | 948 |
| 591 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tl/Kbuild` | MK | 1098 |
| 592 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tl/backend/mali_kbase_timeline_csf.c` | C | 6142 |
| 593 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tl/backend/mali_kbase_timeline_jm.c` | C | 3236 |
| 594 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tl/mali_kbase_timeline.c` | C | 11335 |
| 595 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tl/mali_kbase_timeline.h` | H | 4652 |
| 596 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tl/mali_kbase_timeline_io.c` | C | 13566 |
| 597 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tl/mali_kbase_timeline_priv.h` | H | 3766 |
| 598 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tl/mali_kbase_tl_serialize.h` | H | 3259 |
| 599 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tl/mali_kbase_tlstream.c` | C | 8328 |
| 600 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tl/mali_kbase_tlstream.h` | H | 5686 |
| 601 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tl/mali_kbase_tracepoints.c` | C | 122843 |
| 602 | `gpu_mali/mali_avalon/mali-r47p0/drivers/gpu/arm/midgard/tl/mali_kbase_tracepoints.h` | H | 98736 |
| 603 | `gpu_mali/mali_avalon/mali-r47p0/drivers/hwtracing/coresight/mali/Kbuild` | MK | 2034 |
| 604 | `gpu_mali/mali_avalon/mali-r47p0/drivers/hwtracing/coresight/mali/Kconfig` | MK | 1587 |
| 605 | `gpu_mali/mali_avalon/mali-r47p0/drivers/hwtracing/coresight/mali/Makefile` | MK | 3781 |
| 606 | `gpu_mali/mali_avalon/mali-r47p0/drivers/hwtracing/coresight/mali/Mconfig` | ETC | 1578 |
| 607 | `gpu_mali/mali_avalon/mali-r47p0/drivers/hwtracing/coresight/mali/build.bp` | ETC | 2567 |
| 608 | `gpu_mali/mali_avalon/mali-r47p0/drivers/hwtracing/coresight/mali/coresight_mali_common.c` | C | 1861 |
| 609 | `gpu_mali/mali_avalon/mali-r47p0/drivers/hwtracing/coresight/mali/coresight_mali_common.h` | H | 5617 |
| 610 | `gpu_mali/mali_avalon/mali-r47p0/drivers/hwtracing/coresight/mali/sources/coresight_mali_sources.c` | C | 4774 |
| 611 | `gpu_mali/mali_avalon/mali-r47p0/drivers/hwtracing/coresight/mali/sources/coresight_mali_sources.h` | H | 3035 |
| 612 | `gpu_mali/mali_avalon/mali-r47p0/drivers/hwtracing/coresight/mali/sources/ela/coresight-ela600.h` | H | 3940 |
| 613 | `gpu_mali/mali_avalon/mali-r47p0/drivers/hwtracing/coresight/mali/sources/ela/coresight_mali_source_ela_core.c` | C | 18334 |
| 614 | `gpu_mali/mali_avalon/mali-r47p0/drivers/hwtracing/coresight/mali/sources/etm/coresight_mali_source_etm_core.c` | C | 9679 |
| 615 | `gpu_mali/mali_avalon/mali-r47p0/drivers/hwtracing/coresight/mali/sources/itm/coresight_mali_source_itm_core.c` | C | 8788 |
| 616 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/Kbuild` | MK | 1189 |
| 617 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/Kconfig` | MK | 2165 |
| 618 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/Makefile` | MK | 5529 |
| 619 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/Mconfig` | ETC | 2151 |
| 620 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/dma_buf_test_exporter/Kbuild.bak` | MK | 892 |
| 621 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/dma_buf_test_exporter/Makefile` | MK | 1265 |
| 622 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/dma_buf_test_exporter/build.bp` | ETC | 1165 |
| 623 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/dma_buf_test_exporter/dma-buf-test-exporter.c` | C | 21009 |
| 624 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/memory_group_manager/Kbuild.bak` | MK | 879 |
| 625 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/memory_group_manager/Makefile` | MK | 1791 |
| 626 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/memory_group_manager/build.bp` | ETC | 1145 |
| 627 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/memory_group_manager/init.mali_mgm.rc` | ETC | 316 |
| 628 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/memory_group_manager/memory_group_manager.c` | C | 39677 |
| 629 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/memory_group_manager/mtk_platform_utils.h` | H | 386 |
| 630 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/protected_memory_allocator/Kbuild.bak` | MK | 891 |
| 631 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/protected_memory_allocator/Makefile` | MK | 2453 |
| 632 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/protected_memory_allocator/build.bp` | ETC | 1169 |
| 633 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/protected_memory_allocator/init.mali_prot_alloc.rc` | ETC | 356 |
| 634 | `gpu_mali/mali_avalon/mali-r49p1/drivers/base/arm/protected_memory_allocator/protected_memory_allocator.c` | C | 35865 |
| 635 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/Kbuild` | MK | 840 |
| 636 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/Kconfig` | MK | 899 |
| 637 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/Makefile` | MK | 880 |
| 638 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/Kbuild-mtk-custom-env` | MK | 18747 |
| 639 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/Kbuild.bak` | MK | 7087 |
| 640 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/Kconfig` | MK | 12928 |
| 641 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/Makefile` | MK | 17459 |
| 642 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/Mconfig` | ETC | 12100 |
| 643 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/arbiter/Kbuild` | MK | 883 |
| 644 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/arbiter/mali_kbase_arbif.c` | C | 10189 |
| 645 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/arbiter/mali_kbase_arbif.h` | H | 4434 |
| 646 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/arbiter/mali_kbase_arbiter_defs.h` | H | 2896 |
| 647 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/arbiter/mali_kbase_arbiter_pm.c` | C | 35062 |
| 648 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/arbiter/mali_kbase_arbiter_pm.h` | H | 7691 |
| 649 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/Kbuild` | MK | 2030 |
| 650 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_cache_policy_backend.c` | C | 2229 |
| 651 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_cache_policy_backend.h` | H | 1575 |
| 652 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_clk_rate_trace_mgr.c` | C | 8853 |
| 653 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_clk_rate_trace_mgr.h` | H | 4945 |
| 654 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_debug_job_fault_backend.c` | C | 5247 |
| 655 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_defs.h` | H | 4579 |
| 656 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_devfreq.c` | C | 22382 |
| 657 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_devfreq.h` | H | 2671 |
| 658 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_gpuprops_backend.c` | C | 5457 |
| 659 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_instr_backend.c` | C | 14319 |
| 660 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_instr_defs.h` | H | 1855 |
| 661 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_instr_internal.h` | H | 1334 |
| 662 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_irq_internal.h` | H | 3467 |
| 663 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_irq_linux.c` | C | 13088 |
| 664 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_as.c` | C | 6769 |
| 665 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_hw.c` | C | 46209 |
| 666 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_internal.h` | H | 4670 |
| 667 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_rb.c` | C | 57716 |
| 668 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_jm_rb.h` | H | 2710 |
| 669 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_js_backend.c` | C | 13400 |
| 670 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_js_internal.h` | H | 2350 |
| 671 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_l2_mmu_config.c` | C | 4174 |
| 672 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_l2_mmu_config.h` | H | 1329 |
| 673 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_model_dummy.c` | C | 67566 |
| 674 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_model_dummy.h` | H | 6836 |
| 675 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_model_linux.c` | C | 4853 |
| 676 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_model_linux.h` | H | 3882 |
| 677 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_always_on.c` | C | 2005 |
| 678 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_always_on.h` | H | 2664 |
| 679 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_backend.c` | C | 41916 |
| 680 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_ca.c` | C | 4447 |
| 681 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_ca.h` | H | 3227 |
| 682 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_ca_devfreq.h` | H | 1912 |
| 683 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_coarse_demand.c` | C | 1956 |
| 684 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_coarse_demand.h` | H | 2364 |
| 685 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_defs.h` | H | 31258 |
| 686 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_driver.c` | C | 136954 |
| 687 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_internal.h` | H | 39623 |
| 688 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_l2_states.h` | H | 2186 |
| 689 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_mcu_states.h` | H | 6181 |
| 690 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_metrics.c` | C | 23525 |
| 691 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_policy.c` | C | 13742 |
| 692 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_policy.h` | H | 3429 |
| 693 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_pm_shader_states.h` | H | 4233 |
| 694 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_time.c` | C | 15500 |
| 695 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/build.bp` | ETC | 8530 |
| 696 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/context/Kbuild` | MK | 1031 |
| 697 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/context/backend/mali_kbase_context_csf.c` | C | 7255 |
| 698 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/context/backend/mali_kbase_context_jm.c` | C | 8541 |
| 699 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/context/mali_kbase_context.c` | C | 11095 |
| 700 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/context/mali_kbase_context.h` | H | 4554 |
| 701 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/context/mali_kbase_context_internal.h` | H | 2258 |
| 702 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/Kbuild` | MK | 2405 |
| 703 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/ipa_control/Kbuild` | MK | 862 |
| 704 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/ipa_control/mali_kbase_csf_ipa_control.c` | C | 33614 |
| 705 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/ipa_control/mali_kbase_csf_ipa_control.h` | H | 11150 |
| 706 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/ipa_control/mali_kbase_csf_ipa_control_ex.h` | H | 724 |
| 707 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf.c` | C | 132739 |
| 708 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf.h` | H | 21761 |
| 709 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_cpu_queue.c` | C | 6246 |
| 710 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_cpu_queue.h` | H | 3267 |
| 711 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_cpu_queue_debugfs.c` | C | 2545 |
| 712 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_cpu_queue_debugfs.h` | H | 1233 |
| 713 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_csg.c` | C | 23475 |
| 714 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_csg.h` | H | 1874 |
| 715 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_csg_debugfs.c` | C | 9077 |
| 716 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_csg_debugfs.h` | H | 1433 |
| 717 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_db_irq_types.h` | H | 2973 |
| 718 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_db_irq_valid_ring_queue.h` | H | 787 |
| 719 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_db_valid_defs.h` | H | 883 |
| 720 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_db_validation.c` | C | 10155 |
| 721 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_db_validation.h` | H | 2014 |
| 722 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_db_validation_test.c` | C | 9375 |
| 723 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_defs.h` | H | 87389 |
| 724 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_event.c` | C | 8500 |
| 725 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_event.h` | H | 6149 |
| 726 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware.c` | C | 111118 |
| 727 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware.h` | H | 35854 |
| 728 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_cfg.c` | C | 12609 |
| 729 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_cfg.h` | H | 3790 |
| 730 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_core_dump.c` | C | 25597 |
| 731 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_core_dump.h` | H | 2450 |
| 732 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_log.c` | C | 21897 |
| 733 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_log.h` | H | 2554 |
| 734 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_firmware_no_mali.c` | C | 51801 |
| 735 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_heap_context_alloc.c` | C | 7605 |
| 736 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_heap_context_alloc.h` | H | 2854 |
| 737 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu.c` | C | 108774 |
| 738 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu.h` | H | 16674 |
| 739 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu_debugfs.c` | C | 5373 |
| 740 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu_debugfs.h` | H | 1236 |
| 741 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu_fence_debugfs.c` | C | 4567 |
| 742 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_kcpu_fence_debugfs.h` | H | 1495 |
| 743 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_mcu_shared_reg.c` | C | 30248 |
| 744 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_mcu_shared_reg.h` | H | 6123 |
| 745 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_protected_memory.c` | C | 4463 |
| 746 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_protected_memory.h` | H | 2519 |
| 747 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_registers.h` | H | 103534 |
| 748 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_reset_gpu.c` | C | 39022 |
| 749 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_scheduler.c` | C | 287889 |
| 750 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_scheduler.h` | H | 26814 |
| 751 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_sync.c` | C | 29442 |
| 752 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_sync.h` | H | 1599 |
| 753 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_sync_debugfs.c` | C | 2657 |
| 754 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_sync_debugfs.h` | H | 1203 |
| 755 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap.c` | C | 45265 |
| 756 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap.h` | H | 6630 |
| 757 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_debugfs.c` | C | 5101 |
| 758 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_debugfs.h` | H | 1528 |
| 759 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_def.h` | H | 5835 |
| 760 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_reclaim.c` | C | 14123 |
| 761 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap_reclaim.h` | H | 3200 |
| 762 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_timeout.c` | C | 5407 |
| 763 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_timeout.h` | H | 2397 |
| 764 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tl_reader.c` | C | 11831 |
| 765 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tl_reader.h` | H | 4868 |
| 766 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_trace_buffer.c` | C | 26058 |
| 767 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_trace_buffer.h` | H | 8235 |
| 768 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_util.c` | C | 6959 |
| 769 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_util.h` | H | 3279 |
| 770 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_debug_csf_fault.c` | C | 7276 |
| 771 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_debug_csf_fault.h` | H | 4019 |
| 772 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/Kbuild` | MK | 1108 |
| 773 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_coresight_csf.c` | C | 24935 |
| 774 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_coresight_internal_csf.h` | H | 6897 |
| 775 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_codes_csf.h` | H | 12932 |
| 776 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_codes_jm.h` | H | 8132 |
| 777 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_csf.c` | C | 5869 |
| 778 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_csf.h` | H | 8728 |
| 779 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_defs_csf.h` | H | 4589 |
| 780 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_defs_jm.h` | H | 4197 |
| 781 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_jm.c` | C | 3997 |
| 782 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_ktrace_jm.h` | H | 15722 |
| 783 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_linux_ktrace_csf.h` | H | 10799 |
| 784 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/backend/mali_kbase_debug_linux_ktrace_jm.h` | H | 7442 |
| 785 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace.c` | C | 9665 |
| 786 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace.h` | H | 7587 |
| 787 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace_codes.h` | H | 6446 |
| 788 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace_defs.h` | H | 6349 |
| 789 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/mali_kbase_debug_ktrace_internal.h` | H | 3340 |
| 790 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/debug/mali_kbase_debug_linux_ktrace.h` | H | 4589 |
| 791 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/device/Kbuild` | MK | 1163 |
| 792 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/device/backend/mali_kbase_device_csf.c` | C | 18434 |
| 793 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/device/backend/mali_kbase_device_hw_csf.c` | C | 8468 |
| 794 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/device/backend/mali_kbase_device_hw_jm.c` | C | 4231 |
| 795 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/device/backend/mali_kbase_device_jm.c` | C | 11947 |
| 796 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/device/mali_kbase_device.c` | C | 17307 |
| 797 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/device/mali_kbase_device.h` | H | 7300 |
| 798 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/device/mali_kbase_device_hw.c` | C | 12007 |
| 799 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/device/mali_kbase_device_internal.h` | H | 3333 |
| 800 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/gpu/Kbuild` | MK | 1003 |
| 801 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/gpu/backend/mali_kbase_gpu_fault_csf.c` | C | 5537 |
| 802 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/gpu/backend/mali_kbase_gpu_fault_jm.c` | C | 3079 |
| 803 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/gpu/mali_kbase_gpu.c` | C | 1306 |
| 804 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/gpu/mali_kbase_gpu_fault.h` | H | 1602 |
| 805 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/Kbuild` | MK | 1187 |
| 806 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/backend/mali_kbase_hw_access_model_linux.c` | C | 4699 |
| 807 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/backend/mali_kbase_hw_access_real_hw.c` | C | 4962 |
| 808 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/mali_kbase_hw_access.c` | C | 4539 |
| 809 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/mali_kbase_hw_access.h` | H | 7951 |
| 810 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/mali_kbase_hw_access_regmap.h` | H | 24707 |
| 811 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/mali_kbase_hw_access_regmap_legacy.h` | H | 12237 |
| 812 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_csf.c` | C | 91430 |
| 813 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_csf_enums.h` | H | 20308 |
| 814 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_csf_macros.h` | H | 21638 |
| 815 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_jm.c` | C | 197638 |
| 816 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_jm_enums.h` | H | 42666 |
| 817 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_jm_macros.h` | H | 15161 |
| 818 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_legacy_csf.h` | H | 3408 |
| 819 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_legacy_jm.h` | H | 6069 |
| 820 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/Kbuild` | MK | 1322 |
| 821 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend.h` | H | 9524 |
| 822 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf.c` | C | 84104 |
| 823 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf.h` | H | 8991 |
| 824 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf_if.h` | H | 13197 |
| 825 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf_if_fw.c` | C | 28500 |
| 826 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_csf_if_fw.h` | H | 1868 |
| 827 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_jm.c` | C | 32870 |
| 828 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_jm.h` | H | 1989 |
| 829 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_jm_watchdog.c` | C | 32828 |
| 830 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/backend/mali_kbase_hwcnt_backend_jm_watchdog.h` | H | 2836 |
| 831 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt.c` | C | 25409 |
| 832 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_accumulator.h` | H | 5870 |
| 833 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_context.h` | H | 6139 |
| 834 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_gpu.c` | C | 31186 |
| 835 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_gpu.h` | H | 19879 |
| 836 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_types.c` | C | 16204 |
| 837 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_types.h` | H | 50567 |
| 838 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_virtualizer.c` | C | 24351 |
| 839 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_virtualizer.h` | H | 6596 |
| 840 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_watchdog_if.h` | H | 3051 |
| 841 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_watchdog_if_timer.c` | C | 4790 |
| 842 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hwcnt/mali_kbase_hwcnt_watchdog_if_timer.h` | H | 1738 |
| 843 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/linux/mali_arbiter_interface.h` | H | 7571 |
| 844 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/linux/mali_hw_access.h` | H | 1729 |
| 845 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/linux/mali_kbase_debug_coresight_csf.h` | H | 8289 |
| 846 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/linux/memory_group_manager.h` | H | 9657 |
| 847 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/linux/priority_control_manager.h` | H | 5478 |
| 848 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/linux/protected_memory_allocator.h` | H | 4001 |
| 849 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/linux/protected_mode_switcher.h` | H | 2085 |
| 850 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/linux/version_compat_defs.h` | H | 13918 |
| 851 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/base/arm/dma_buf_test_exporter/dma-buf-test-exporter.h` | H | 2783 |
| 852 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/backend/gpu/mali_kbase_model_dummy.h` | H | 3161 |
| 853 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/backend/gpu/mali_kbase_model_linux.h` | H | 1203 |
| 854 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/csf/mali_base_csf_kernel.h` | H | 23282 |
| 855 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_errors_dumpfault.h` | H | 3206 |
| 856 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_ioctl.h` | H | 24731 |
| 857 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/backend/mali_kbase_gpu_regmap_csf.h` | H | 1259 |
| 858 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/backend/mali_kbase_gpu_regmap_jm.h` | H | 938 |
| 859 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/mali_kbase_gpu_coherency.h` | H | 1066 |
| 860 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/mali_kbase_gpu_id.h` | H | 8504 |
| 861 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/gpu/mali_kbase_gpu_regmap.h` | H | 1073 |
| 862 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/jm/mali_base_jm_kernel.h` | H | 46548 |
| 863 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/jm/mali_kbase_jm_ioctl.h` | H | 9650 |
| 864 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_base_common_kernel.h` | H | 7556 |
| 865 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_base_kernel.h` | H | 24660 |
| 866 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_base_mem_priv.h` | H | 1870 |
| 867 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_gpu_props.h` | H | 3120 |
| 868 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_kbase_hwcnt_reader.h` | H | 18005 |
| 869 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_kbase_ioctl.h` | H | 25023 |
| 870 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_kbase_kinstr_jm_reader.h` | H | 2995 |
| 871 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_kbase_mem_profile_debugfs_buf_size.h` | H | 1360 |
| 872 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/ipa/Kbuild` | MK | 1239 |
| 873 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_common_csf.c` | C | 14601 |
| 874 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_common_csf.h` | H | 7326 |
| 875 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_common_jm.c` | C | 10430 |
| 876 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_common_jm.h` | H | 9207 |
| 877 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_csf.c` | C | 12715 |
| 878 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/ipa/backend/mali_kbase_ipa_counter_jm.c` | C | 16559 |
| 879 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/ipa/mali_kbase_ipa.c` | C | 22528 |
| 880 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/ipa/mali_kbase_ipa.h` | H | 11123 |
| 881 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/ipa/mali_kbase_ipa_debugfs.c` | C | 7792 |
| 882 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/ipa/mali_kbase_ipa_debugfs.h` | H | 2214 |
| 883 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/ipa/mali_kbase_ipa_simple.c` | C | 11542 |
| 884 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/ipa/mali_kbase_ipa_simple.h` | H | 1642 |
| 885 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/jm/mali_kbase_jm_defs.h` | H | 38769 |
| 886 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/jm/mali_kbase_jm_js.h` | H | 39542 |
| 887 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/jm/mali_kbase_js_defs.h` | H | 19329 |
| 888 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_base_hwconfig_features.h` | H | 6274 |
| 889 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_base_hwconfig_issues.h` | H | 27417 |
| 890 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase.h` | H | 28268 |
| 891 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_as_fault_debugfs.c` | C | 3097 |
| 892 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_as_fault_debugfs.h` | H | 1678 |
| 893 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_cache_policy.c` | C | 2029 |
| 894 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_cache_policy.h` | H | 1555 |
| 895 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_caps.h` | H | 3480 |
| 896 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_ccswe.c` | C | 2653 |
| 897 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_ccswe.h` | H | 3197 |
| 898 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_config.c` | C | 3590 |
| 899 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_config.h` | H | 22389 |
| 900 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_config_defaults.h` | H | 13086 |
| 901 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_core_linux.c` | C | 201222 |
| 902 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_cs_experimental.h` | H | 1296 |
| 903 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_ctx_sched.c` | C | 11206 |
| 904 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_ctx_sched.h` | H | 9646 |
| 905 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_debug.c` | C | 1387 |
| 906 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_debug.h` | H | 5988 |
| 907 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_debug_job_fault.c` | C | 15981 |
| 908 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_debug_job_fault.h` | H | 4170 |
| 909 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_debug_mem_allocs.c` | C | 4065 |
| 910 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_debug_mem_allocs.h` | H | 1340 |
| 911 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_debug_mem_view.c` | C | 9655 |
| 912 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_debug_mem_view.h` | H | 1370 |
| 913 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_debug_mem_zones.c` | C | 3271 |
| 914 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_debug_mem_zones.h` | H | 1357 |
| 915 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_debugfs_helper.c` | C | 6020 |
| 916 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_debugfs_helper.h` | H | 6737 |
| 917 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_defs.h` | H | 100169 |
| 918 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_disjoint_events.c` | C | 2167 |
| 919 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_dummy_job_wa.c` | C | 10880 |
| 920 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_dummy_job_wa.h` | H | 2158 |
| 921 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_dvfs_debugfs.c` | C | 3093 |
| 922 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_dvfs_debugfs.h` | H | 1198 |
| 923 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_event.c` | C | 8025 |
| 924 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_fence.c` | C | 1496 |
| 925 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_fence.h` | H | 8253 |
| 926 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_fence_ops.c` | C | 3024 |
| 927 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gator.h` | H | 1836 |
| 928 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gator_api.c` | C | 8700 |
| 929 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gator_api.h` | H | 8088 |
| 930 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gator_hwcnt_names.h` | H | 1009 |
| 931 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gator_hwcnt_names_tkrx.h` | H | 9614 |
| 932 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gator_hwcnt_names_ttix.h` | H | 8759 |
| 933 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gpu_memory_debugfs.c` | C | 3035 |
| 934 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gpu_memory_debugfs.h` | H | 1666 |
| 935 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gpu_metrics.c` | C | 7726 |
| 936 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gpu_metrics.h` | H | 6950 |
| 937 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gpuprops.c` | C | 31513 |
| 938 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gpuprops.h` | H | 5489 |
| 939 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gpuprops_private_types.h` | H | 2969 |
| 940 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gpuprops_types.h` | H | 8846 |
| 941 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gwt.c` | C | 7619 |
| 942 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_gwt.h` | H | 1675 |
| 943 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_hw.c` | C | 14492 |
| 944 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_hw.h` | H | 2507 |
| 945 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_hwaccess_backend.h` | H | 1386 |
| 946 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_hwaccess_defs.h` | H | 1818 |
| 947 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_hwaccess_gpuprops.h` | H | 2828 |
| 948 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_hwaccess_instr.h` | H | 5279 |
| 949 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_hwaccess_jm.h` | H | 10568 |
| 950 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_hwaccess_pm.h` | H | 7543 |
| 951 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_hwaccess_time.h` | H | 7961 |
| 952 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_jd.c` | C | 50532 |
| 953 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_jd_debugfs.c` | C | 5324 |
| 954 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_jd_debugfs.h` | H | 1273 |
| 955 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_jm.c` | C | 4256 |
| 956 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_jm.h` | H | 3749 |
| 957 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_js.c` | C | 129157 |
| 958 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_js.h` | H | 1129 |
| 959 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_js_ctx_attr.c` | C | 11486 |
| 960 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_js_ctx_attr.h` | H | 4847 |
| 961 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_kinstr_jm.c` | C | 27718 |
| 962 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_kinstr_jm.h` | H | 10073 |
| 963 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_kinstr_prfcnt.c` | C | 76359 |
| 964 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_kinstr_prfcnt.h` | H | 9060 |
| 965 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_linux.h` | H | 1643 |
| 966 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mem.c` | C | 151532 |
| 967 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mem.h` | H | 105359 |
| 968 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mem_linux.c` | C | 119081 |
| 969 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mem_linux.h` | H | 21546 |
| 970 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mem_lowlevel.h` | H | 6365 |
| 971 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mem_migrate.c` | C | 23550 |
| 972 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mem_migrate.h` | H | 4346 |
| 973 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mem_pool.c` | C | 33054 |
| 974 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mem_pool_debugfs.c` | C | 5275 |
| 975 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mem_pool_debugfs.h` | H | 4910 |
| 976 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mem_pool_group.c` | C | 3185 |
| 977 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mem_pool_group.h` | H | 4362 |
| 978 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mem_profile_debugfs.c` | C | 4037 |
| 979 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mem_profile_debugfs.h` | H | 2199 |
| 980 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mipe_gen_header.h` | H | 6133 |
| 981 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_mipe_proto.h` | H | 4284 |
| 982 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_native_mgm.c` | C | 6032 |
| 983 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_native_mgm.h` | H | 1371 |
| 984 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_pbha.c` | C | 9282 |
| 985 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_pbha.h` | H | 2300 |
| 986 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_pbha_debugfs.c` | C | 6705 |
| 987 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_pbha_debugfs.h` | H | 1098 |
| 988 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_platform_fake.c` | C | 3978 |
| 989 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_pm.c` | C | 10786 |
| 990 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_pm.h` | H | 10297 |
| 991 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_reg_track.c` | C | 45582 |
| 992 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_reg_track.h` | H | 15890 |
| 993 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_regs_history_debugfs.c` | C | 6382 |
| 994 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_regs_history_debugfs.h` | H | 2752 |
| 995 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_reset_gpu.h` | H | 11350 |
| 996 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_smc.c` | C | 2709 |
| 997 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_smc.h` | H | 2127 |
| 998 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_softjobs.c` | C | 46119 |
| 999 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_sync.h` | H | 6814 |
| 1000 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_sync_common.c` | C | 1379 |
| 1001 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_sync_file.c` | C | 9530 |
| 1002 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_trace_gpu_mem.c` | C | 6650 |
| 1003 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_trace_gpu_mem.h` | H | 2926 |
| 1004 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_linux_trace.h` | H | 27040 |
| 1005 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_malisw.h` | H | 3036 |
| 1006 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_power_gpu_frequency_trace.c` | C | 995 |
| 1007 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_power_gpu_frequency_trace.h` | H | 1865 |
| 1008 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_power_gpu_work_period_trace.c` | C | 1103 |
| 1009 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mali_power_gpu_work_period_trace.h` | H | 2708 |
| 1010 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/Kbuild` | MK | 1272 |
| 1011 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_csf.c` | C | 48818 |
| 1012 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_faults_decoder_luts_csf.c` | C | 4030 |
| 1013 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_faults_decoder_luts_csf.h` | H | 1857 |
| 1014 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_faults_decoder_luts_jm.c` | C | 2195 |
| 1015 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_faults_decoder_luts_jm.h` | H | 1395 |
| 1016 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/backend/mali_kbase_mmu_jm.c` | C | 14819 |
| 1017 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu.c` | C | 143174 |
| 1018 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu.h` | H | 14216 |
| 1019 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_faults_decoder.c` | C | 4482 |
| 1020 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_faults_decoder.h` | H | 5140 |
| 1021 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_faults_decoder_luts.c` | C | 24765 |
| 1022 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_faults_decoder_luts.h` | H | 4192 |
| 1023 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_hw.h` | H | 7634 |
| 1024 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_hw_direct.c` | C | 24841 |
| 1025 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_internal.h` | H | 2520 |
| 1026 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/mmu/mali_kbase_mmu_mode_aarch64.c` | C | 6400 |
| 1027 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/Kconfig` | MK | 994 |
| 1028 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/devicetree/Kbuild` | MK | 1013 |
| 1029 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/devicetree/mali_kbase_clk_rate_trace.c` | C | 3548 |
| 1030 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/devicetree/mali_kbase_config_devicetree.c` | C | 1513 |
| 1031 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/devicetree/mali_kbase_config_platform.h` | H | 1597 |
| 1032 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/devicetree/mali_kbase_runtime_pm.c` | C | 8243 |
| 1033 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/meson/Kbuild` | MK | 944 |
| 1034 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/meson/mali_kbase_config_meson.c` | C | 1513 |
| 1035 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/meson/mali_kbase_config_platform.h` | H | 1485 |
| 1036 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/meson/mali_kbase_runtime_pm.c` | C | 6838 |
| 1037 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mt6768/Kbuild` | MK | 1165 |
| 1038 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mt6768/mali_kbase_config_mt6768.c` | C | 15724 |
| 1039 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mt6768/mali_kbase_config_platform.h` | H | 583 |
| 1040 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mt6991/Kbuild` | MK | 1056 |
| 1041 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mt6991/mali_kbase_config_mt6991.c` | C | 20014 |
| 1042 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mt6991/mali_kbase_config_platform.h` | H | 538 |
| 1043 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_mfg_counter.h` | H | 6428 |
| 1044 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common.h` | H | 5784 |
| 1045 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/Kbuild` | MK | 4172 |
| 1046 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_gpu_power_model_sspm_ipi.c` | C | 1696 |
| 1047 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_gpu_power_model_sspm_ipi.h` | H | 839 |
| 1048 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_gpu_trace.h` | H | 935 |
| 1049 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_ltr_pmu.c` | C | 3571 |
| 1050 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_ltr_pmu.h` | H | 778 |
| 1051 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_mfg_counter.c` | C | 22449 |
| 1052 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_adaptive_power_policy.c` | C | 1512 |
| 1053 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_adaptive_power_policy.h` | H | 312 |
| 1054 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_cm7_trace.c` | C | 2591 |
| 1055 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_cm7_trace.h` | H | 327 |
| 1056 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_common.c` | C | 25671 |
| 1057 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug.h` | H | 3564 |
| 1058 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_cpu.c` | C | 3829 |
| 1059 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_csg.c` | C | 6544 |
| 1060 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_enop_metadata.c` | C | 6963 |
| 1061 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_gpu.c` | C | 54848 |
| 1062 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_gpu_debugfs.c` | C | 2209 |
| 1063 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_infra_status.c` | C | 1789 |
| 1064 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_iter_cshw.c` | C | 9756 |
| 1065 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_kcpu.c` | C | 14539 |
| 1066 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_pm_status.c` | C | 4267 |
| 1067 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_queue_data.c` | C | 3650 |
| 1068 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_debug_dump_queue_data.h` | H | 303 |
| 1069 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_devfreq_governor.c` | C | 4473 |
| 1070 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_devfreq_governor.h` | H | 560 |
| 1071 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_devfreq_thermal.c` | C | 2279 |
| 1072 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_devfreq_thermal.h` | H | 1049 |
| 1073 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_diagnosis_mode.c` | C | 3822 |
| 1074 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_diagnosis_mode.h` | H | 424 |
| 1075 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs.c` | C | 15203 |
| 1076 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs.h` | H | 2691 |
| 1077 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs_hint_26m_perf_cnting.c` | C | 5095 |
| 1078 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs_hint_26m_perf_cnting.h` | H | 996 |
| 1079 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_dvfs_hint_26m_perf_cnting_ex.h` | H | 419 |
| 1080 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_gpu_idle_test.c` | C | 1458 |
| 1081 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_gpu_idle_test.h` | H | 301 |
| 1082 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_logbuffer.c` | C | 12787 |
| 1083 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_logbuffer.h` | H | 1393 |
| 1084 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_mali_event.h` | H | 1604 |
| 1085 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_memtrack.c` | C | 4064 |
| 1086 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_memtrack.h` | H | 476 |
| 1087 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_qinspect.c` | C | 50890 |
| 1088 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_qinspect.h` | H | 10802 |
| 1089 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_qinspect_recovery.c` | C | 19115 |
| 1090 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_qinspect_recovery.h` | H | 436 |
| 1091 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_fault_worker.c` | C | 2287 |
| 1092 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_fault_worker.h` | H | 309 |
| 1093 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_force_hard_reset.c` | C | 2610 |
| 1094 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_force_hard_reset.h` | H | 420 |
| 1095 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_force_terminate_csg.c` | C | 2688 |
| 1096 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_force_terminate_csg.h` | H | 438 |
| 1097 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_memory_footprint.c` | C | 2224 |
| 1098 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_memory_footprint.h` | H | 325 |
| 1099 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_missing_doorbell.c` | C | 2502 |
| 1100 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_missing_doorbell.h` | H | 420 |
| 1101 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_scheduler.c` | C | 4035 |
| 1102 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_scheduler.h` | H | 297 |
| 1103 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_sync_update.c` | C | 3205 |
| 1104 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_whitebox_sync_update.h` | H | 626 |
| 1105 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_utils.h` | H | 386 |
| 1106 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/vexpress/Kbuild` | MK | 931 |
| 1107 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/vexpress/mali_kbase_config_platform.h` | H | 1335 |
| 1108 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/vexpress/mali_kbase_config_vexpress.c` | C | 2302 |
| 1109 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/vexpress_1xv7_a57/Kbuild` | MK | 931 |
| 1110 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/vexpress_1xv7_a57/mali_kbase_config_platform.h` | H | 1335 |
| 1111 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/vexpress_1xv7_a57/mali_kbase_config_vexpress.c` | C | 2246 |
| 1112 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/vexpress_6xvirtex7_10mhz/Kbuild` | MK | 988 |
| 1113 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/vexpress_6xvirtex7_10mhz/mali_kbase_config_platform.h` | H | 1335 |
| 1114 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/platform/vexpress_6xvirtex7_10mhz/mali_kbase_config_vexpress.c` | C | 2246 |
| 1115 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/protected_mode_switcher.h` | H | 1918 |
| 1116 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/Kbuild` | MK | 1219 |
| 1117 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/Kconfig` | MK | 2130 |
| 1118 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/Mconfig` | ETC | 2170 |
| 1119 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/build.bp` | ETC | 1558 |
| 1120 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/include/kutf/kutf_helpers.h` | H | 4001 |
| 1121 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/include/kutf/kutf_helpers_user.h` | H | 6481 |
| 1122 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/include/kutf/kutf_kprobe.h` | H | 1197 |
| 1123 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/include/kutf/kutf_mem.h` | H | 2309 |
| 1124 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/include/kutf/kutf_resultset.h` | H | 5876 |
| 1125 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/include/kutf/kutf_suite.h` | H | 22873 |
| 1126 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/include/kutf/kutf_utils.h` | H | 2055 |
| 1127 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/kutf/Kbuild` | MK | 1008 |
| 1128 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/kutf/build.bp` | ETC | 1276 |
| 1129 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/kutf/kutf_helpers.c` | C | 3486 |
| 1130 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/kutf/kutf_helpers_user.c` | C | 13388 |
| 1131 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/kutf/kutf_kprobe.c` | C | 9043 |
| 1132 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/kutf/kutf_mem.c` | C | 2489 |
| 1133 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/kutf/kutf_resultset.c` | C | 3949 |
| 1134 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/kutf/kutf_suite.c` | C | 33916 |
| 1135 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/kutf/kutf_utils.c` | C | 1893 |
| 1136 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/mali_kutf_clk_rate_trace/kernel/Kbuild` | MK | 968 |
| 1137 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/mali_kutf_clk_rate_trace/kernel/build.bp` | ETC | 1361 |
| 1138 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/mali_kutf_clk_rate_trace/kernel/mali_kutf_clk_rate_trace_test.c` | C | 29596 |
| 1139 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/mali_kutf_clk_rate_trace/mali_kutf_clk_rate_trace_test.h` | H | 7975 |
| 1140 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/mali_kutf_irq_test/Kbuild` | MK | 926 |
| 1141 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/mali_kutf_irq_test/build.bp` | ETC | 1279 |
| 1142 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/mali_kutf_irq_test/mali_kutf_irq_test_main.c` | C | 7889 |
| 1143 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/mali_kutf_kernel_defect_test/kernel/mali_kutf_kernel_defect_GPUCORE-27226.c` | C | 3783 |
| 1144 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/mali_kutf_mgm_integration_test/Kbuild` | MK | 963 |
| 1145 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/mali_kutf_mgm_integration_test/build.bp` | ETC | 1321 |
| 1146 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tests/mali_kutf_mgm_integration_test/mali_kutf_mgm_integration_test_main.c` | C | 6789 |
| 1147 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/thirdparty/Kbuild` | MK | 811 |
| 1148 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/thirdparty/mali_kbase_mmap.c` | C | 19829 |
| 1149 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/thirdparty/mm.h` | H | 948 |
| 1150 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tl/Kbuild` | MK | 1098 |
| 1151 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tl/backend/mali_kbase_timeline_csf.c` | C | 6142 |
| 1152 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tl/backend/mali_kbase_timeline_jm.c` | C | 3236 |
| 1153 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tl/mali_kbase_timeline.c` | C | 11946 |
| 1154 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tl/mali_kbase_timeline.h` | H | 4652 |
| 1155 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tl/mali_kbase_timeline_io.c` | C | 13614 |
| 1156 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tl/mali_kbase_timeline_priv.h` | H | 3814 |
| 1157 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tl/mali_kbase_tl_serialize.h` | H | 3259 |
| 1158 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tl/mali_kbase_tlstream.c` | C | 8352 |
| 1159 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tl/mali_kbase_tlstream.h` | H | 5710 |
| 1160 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tl/mali_kbase_tracepoints.c` | C | 122843 |
| 1161 | `gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/tl/mali_kbase_tracepoints.h` | H | 110829 |
| 1162 | `gpu_mali/mali_avalon/mali-r49p1/drivers/hwtracing/coresight/mali/Kbuild` | MK | 2034 |
| 1163 | `gpu_mali/mali_avalon/mali-r49p1/drivers/hwtracing/coresight/mali/Kconfig` | MK | 1587 |
| 1164 | `gpu_mali/mali_avalon/mali-r49p1/drivers/hwtracing/coresight/mali/Makefile` | MK | 3852 |
| 1165 | `gpu_mali/mali_avalon/mali-r49p1/drivers/hwtracing/coresight/mali/Mconfig` | ETC | 1578 |
| 1166 | `gpu_mali/mali_avalon/mali-r49p1/drivers/hwtracing/coresight/mali/build.bp` | ETC | 2567 |
| 1167 | `gpu_mali/mali_avalon/mali-r49p1/drivers/hwtracing/coresight/mali/coresight_mali_common.c` | C | 1861 |
| 1168 | `gpu_mali/mali_avalon/mali-r49p1/drivers/hwtracing/coresight/mali/coresight_mali_common.h` | H | 5617 |
| 1169 | `gpu_mali/mali_avalon/mali-r49p1/drivers/hwtracing/coresight/mali/sources/coresight_mali_sources.c` | C | 4885 |
| 1170 | `gpu_mali/mali_avalon/mali-r49p1/drivers/hwtracing/coresight/mali/sources/coresight_mali_sources.h` | H | 3035 |
| 1171 | `gpu_mali/mali_avalon/mali-r49p1/drivers/hwtracing/coresight/mali/sources/ela/coresight-ela600.h` | H | 3940 |
| 1172 | `gpu_mali/mali_avalon/mali-r49p1/drivers/hwtracing/coresight/mali/sources/ela/coresight_mali_source_ela_core.c` | C | 18334 |
| 1173 | `gpu_mali/mali_avalon/mali-r49p1/drivers/hwtracing/coresight/mali/sources/etm/coresight_mali_source_etm_core.c` | C | 9679 |
| 1174 | `gpu_mali/mali_avalon/mali-r49p1/drivers/hwtracing/coresight/mali/sources/itm/coresight_mali_source_itm_core.c` | C | 8788 |

## C. GPU 设备树与内核配置（源码级）

| # | 相对路径 | 类型 | 与 GPU 的关系 |
| ---: | --- | :--: | --- |
| 1 | `arch/arm64/boot/dts/mediatek/mt6991.dts` | DTS | GPU 顶层节点 mali@48000000 + mgm/ged/gpufreq_wrapper/gpupdma/gpu_smmu/gpu_mali_opp |
| 2 | `arch/arm64/boot/dts/mediatek/dali.dts` | DTS | 板级主设备树，include dali-mt6991-common.dtsi |
| 3 | `arch/arm64/boot/dts/mediatek/dali-mt6991-common.dtsi` | DTSI | dali 平台公共节点 |
| 4 | `arch/arm64/boot/dts/mediatek/dali-sensor-common.dtsi` | DTSI | 传感器，与 GPU 无关 |
| 5 | `arch/arm64/boot/dts/mediatek/dali_mt6991_battery_table.dtsi` | DTSI | 电池表，与 GPU 无关 |
| 6 | `arch/arm64/boot/dts/mediatek/dali_mt6991_camera_v4l2.dtsi` | DTSI | 相机，与 GPU 无关 |
| 7 | `arch/arm64/boot/dts/mediatek/xiaomi_dali_mt6991_fingerprint.dtsi` | DTSI | 指纹，与 GPU 无关 |
| 8 | `arch/arm64/boot/dts/mediatek/xiaomi_dali_mt6991_mitee.dtsi` | DTSI | TEE，与 GPU 无关 |
| 9 | `arch/arm64/boot/dts/mediatek/xiaomi_dali_mt6991_touch.dtsi` | DTSI | 触控，与 GPU 无关 |
| 10 | `arch/arm64/boot/dts/mediatek/xiaomi_dali_t1_chip.dtsi` | DTSI | T1 安全芯片，与 GPU 无关 |

### C2. 内核配置

| # | 相对路径 | 类型 | 与 GPU 的关系 |
| ---: | --- | :--: | --- |
| 1 | `kernel/configs/dali.config` | Kconfig 片段 | 123 行，**不含任何 GPU 配置**（全为显示/充电/NFC/音频等） |
| 2 | `kernel/configs/dali_stability.config` | Kconfig 片段 | 稳定性配置片段 |
| 3 | `arch/arm64/configs/mgk_64_k66_defconfig` | defconfig | **GPU 配置的唯一来源**：CONFIG_MTK_GPU_SUPPORT=m、MTK_GPU_MT6991_SUPPORT=m、MTK_TINYSYS_GPUEB_SUPPORT=m、MTK_GPUFREQ_V2=y、MTK_GPU_POWER_THROTTLING=m、MTK_GPU_COMMON_DVFS_SUPPORT=y、MTK_GPU_SWPM_SUPPORT=y |

## D. 预编译二进制模块（**非源码**）

仓库：`xiaomi-mt6991-devs/android_device_xiaomi_dali-kernel` @ `0576426`

本地：`01_original_baseline/kernel_ref_mt6991/`

| # | 路径 | 类型 | 字节 | 源码归属 |
| ---: | --- | :--: | ---: | --- |
| 1 | `vendor_dlkm/ged.ko` | .ko | 1093352 | R3 drivers/gpu/mediatek/ged/ |
| 2 | `vendor_dlkm/mali_kbase_mt6991_r49.ko` | .ko | 2310424 | R2 mali-r49p1/drivers/gpu/arm/midgard/ |
| 3 | `vendor_dlkm/mali_mgm_mt6991_r49.ko` | .ko | 55696 | R2 mali-r49p1/drivers/base/arm/memory_group_manager/ |
| 4 | `vendor_dlkm/mali_prot_alloc_mt6991_r49.ko` | .ko | 21080 | R2 mali-r49p1/drivers/base/arm/protected_memory_allocator/ |
| 5 | `vendor_dlkm/met_gpu_adv_api.ko` | .ko | 12184 | R2 met_drv_v3/default/met_api/met_gpu_adv_api/ |
| 6 | `vendor_dlkm/met_gpu_api.ko` | .ko | 14336 | R2 met_drv_v3/default/met_api/met_gpu_api/ |
| 7 | `vendor_dlkm/met_gpueb_api.ko` | .ko | 14120 | R2 met_drv_v3/default/met_api/met_gpueb_api/ |
| 8 | `vendor_dlkm/mtk_gpu_hal.ko` | .ko | 58968 | R3 drivers/gpu/mediatek/hal/mtk_gpu_utility.c |
| 9 | `vendor_dlkm/mtk_gpu_iommu_mt6991.ko` | .ko | 12840 | R3 drivers/gpu/mediatek/gpu_iommu/gpu_iommu_mt6991.c |
| 10 | `vendor_dlkm/mtk_gpu_pdma_mt6991.ko` | .ko | 40512 | R3 drivers/gpu/mediatek/gpu_pdma/gpu_pdma_mt6991.c |
| 11 | `vendor_dlkm/mtk_gpu_power_throttling.ko` | .ko | 38288 | R3 drivers/misc/mediatek/power_throttling/mtk_gpu_power_throttling.c |
| 12 | `vendor_dlkm/mtk_gpu_qos.ko` | .ko | 33376 | R3 drivers/gpu/mediatek/gpu_bm/gpu_bm.c |
| 13 | `vendor_dlkm/mtk_gpueb.ko` | .ko | 128560 | R3 drivers/gpu/mediatek/gpueb/ |
| 14 | `vendor_dlkm/mtk_gpufreq_mt6991.ko` | .ko | 118368 | R3 drivers/gpu/mediatek/gpufreq/v2/gpufreq_mt6991.c |
| 15 | `vendor_dlkm/mtk_gpufreq_wrapper.ko` | .ko | 151736 | R3 drivers/gpu/mediatek/gpufreq/v2/gpufreq_v2.c |
| 16 | `dtb/mt6991.dtb` | .dtb | 524288 | 编译产物（源：§C 的 dts） |
| 17 | `modules.load.vendor` / `.system` / `.recovery` / `.vendor_ramdisk` | 文本清单 | — | 加载列表（非模块） |

> **声明**：上表 `.ko` / `.dtb` 均为**预编译二进制**。其「源码归属」列指向的是**能生成该二进制的源码位置**，不代表二进制本身是源码。
