# DTS / 硬件资源对接审计

> 依据：`01_original_baseline/kernel_ref_mt6991/dtb/mt6991.dtb`（532,322 B）
> 对照：`02_r56_source/mali_r56p0/driver/product/kernel/Documentation/devicetree/bindings/arm/*.yaml`
> 方式：自写 FDT 解析器解包 + 逐属性导出 + 与官方 binding 对规 · 未编译 DTS、未烧写

---

## 0. 结论先行

| # | 结论 | 强度 |
| --- | --- | --- |
| 1 | 归档的 `mt6991.dtb` **不是单个 FDT**，而是 Android **DT-Table（dtbo）封装**，magic `0xd7b7ab1e`。必须先按表头拆包才能解析 | `[实证]` |
| 2 | GPU 节点是 `/soc/mali@48000000`，`compatible = "mediatek,mali", "arm,mali-valhall"`，寄存器 `0x48000000 + 0x480000` | `[实证]` |
| 3 | **6 路中断**（JOB/MMU/GPU/EVENT/PWR/GPUEB_MBOX1 → GIC SPI 574/573/572/575/576/580），而 Arm 官方 binding 只允许 3 路 | `[实证]` |
| 4 | **`clocks`、`power-domains`、`iommus`、`mboxes` 四个属性在 GPU 节点上全部缺失**。这不是遗漏，是 MTK 的设计：时钟/电源由 GPUFreq 直写寄存器接管，IOMMU 由 PMA 子节点持有 | `[实证]` + `[推断]` |
| 5 | `sleep-mode-enable = <1>` → 6 个 runtime PM 回调**在运行时确实被注册**。Stage 2 的 U 项（属性位置未知）由此闭环 | `[实证]` |
| 6 | `/protected-memory-allocator` **缺少 binding 要求的 `memory-region`**，改用 MTK 私有 `protected-reserve-size`。说明 MTK 的 PMA 走 dma-heap + FFA，不走 reserved memory | `[实证]` |
| 7 | `/mgm` 节点 `compatible = "arm,physical-memory-group-manager"`，**完全符合**官方 binding | `[实证]` |

---

## 1. 载体格式：必须先拆 DT-Table

`file` 与十六进制头部显示 magic 不是 `0xd00dfeed`：

```
magic = 0xd7b7ab1e      ← Android DT_TABLE_MAGIC（mkdtboimg / libufdt）
total_size  = 532,322
header_size = 32
dt_entry_size = 32
dt_entry_count = 1
dt_entries_offset = 32
page_size = 2048
version = 0
```

`dt_table_entry[0]`：`size = 532,258`、`offset = 0x40`、`id = 0`、`rev = 0`。

拆包后内层是标准 FDT（magic `0xd00dfeed`，532,258 字节，**2,194 个节点**）。

> **方法学提醒**：直接对 `mt6991.dtb` 跑 `dtc -I dtb` 会报 "not a valid dtb"。必须先剥掉 64 字节表头。这一点决定了"DTB 能否反编译"这个前置问题的答案是**能**，但需要两步。

解析结果落地为可复核的文本（本报告所有属性均来自该转储）。

---

## 2. GPU 主节点：`/soc/mali@48000000`

| 属性 | 值 | 说明 |
| --- | --- | --- |
| `compatible` | `"mediatek,mali"`, `"arm,mali-valhall"` | **注意：`arm,mali-valhall` 不在官方 binding 的枚举内**（见 §7） |
| `reg` | `<0x0 0x48000000 0x0 0x480000>` | 512 KB 寄存器窗口 |
| `interrupts` | 6 组 `<0, N, 4, 0>` | 见 §3 |
| `interrupt-names` | `JOB` `MMU` `GPU` `EVENT` `PWR` `GPUEB_MBOX1` | — |
| `physical-memory-group-manager` | `<0x164>` → `/mgm` | MGM 绑定 |
| `protected-memory-allocator` | `<0x165>` → `/protected-memory-allocator` | PMA 绑定 |
| `operating-points-v2` | `<0x166>` → `/soc/opp-table0` | OPP 表 |
| `ged-supply` | `<0x167>` → `/ged` | GED 句柄 |
| `#cooling-cells` | `<2>` | 作为 thermal cooling device |
| `system-coherency` | `<0>` | 非一致（ACE-Lite 由运行时读寄存器判定） |
| `dbg-force-sync` | `<0>` | 关闭强制同步调试 |
| **`sleep-mode-enable`** | **`<1>`** | **开启 runtime PM 六回调** |
| `firmware-idle-hysteresis-time-us` | `<0>` | 固件 idle 迟滞关闭 |
| `default-glb-pwroff-timeout-us` | `<0x0a>` = 10 | 全局断电等待 10 µs |
| `autosuspend-delay-ms` | `<0x0a>` = 10 | 自动挂起延时 10 ms |
| `adaptive-power-policy` | `<2>` | APO 2.0 |
| `reset-exception-mask` | `<0>` | 不复位屏蔽 |
| `iter-trace-enable` | `<1>` | 迭代器 trace 开启 |
| `gpu-frame-base-optimize` | `<1>` | 帧基优化开启 |
| `l2-hash-values` | `<0x0b 0x0e 0x00>` | L2 哈希配置 |
| `phandle` | `<0x37c>` | 无其他节点引用它 |

### 2.1 子节点 `/soc/mali@48000000/pbha`

```
propagate-bits = <0x0f>       ← 4 bit
```

与 `include/linux/memory_group_manager.h:38` 的 `PTE_PBHA_MASK = 0xf << 59` **完全对应**。这条是 PBHA 迁移的 DTS 侧锚点（见 `04_mgm_pma_memory_audit.md` §4）。

---

## 3. 中断表

GIC-v3，`#interrupt-cells = <4>`，格式 `<type, number, flags, 0>`，`type=0` 为 SPI，`flags=4` 为电平高有效。

| 名称 | 中断号 | GIC SPI | 处理者 | 在 r56p0 的命运 |
| --- | ---: | ---: | --- | --- |
| `JOB` | 606 | 574 | kbase | 保留 |
| `MMU` | 605 | 573 | kbase | 保留 |
| `GPU` | 604 | 572 | kbase | 保留 |
| `EVENT` | 607 | 575 | kbase | 保留 |
| `PWR` | 608 | 576 | kbase | 保留 |
| **`GPUEB_MBOX1`** | **612** | **580** | **kbase**（`CONFIG_MALI_MTK_GPUEB_IRQ`） | **r56p0 无对应处理函数** |

`GPUEB_MBOX1` 的处理函数在 r49p1 是 `kbase_gpueb_irq_handler()`（`csf/mali_kbase_csf_reset_gpu.c:1076-1110`），只做两件事：

```c
gpueb_irq_status = gpueb_get_mbox1_irq();
if (status & BIT(0)) { kbdev->low_volt_count++;        dev_err(...); }
else if (status & BIT(1)) { kbdev->brcast_timeout_count++; dev_err(...); }
```

**这两个计数器在全树中仅被该函数读写**（`grep -rn 'low_volt_count\|brcast_timeout_count'` 命中 10 处，全部在 `reset_gpu.c:1083-1139` 与 `mali_kbase_defs.h:1201-1202`）。

> **修正 Stage 2 的 KB-023**：该中断处理**不属于功能路径**，属纯可观测性。丢失后果是"拿不到低压/广播超时计数"，**不会**导致 GPU 不能工作。
>
> 另需记录一处易混淆的中断号重叠：`/soc/gpueb@4b000000` 的 `interrupts = <0 608 4 0>`（名字 `mbox0`），与 mali 的 **`PWR`（608）是同一个号**；而 mali 的 `GPUEB_MBOX1` 是 **612**，两者不同。即 **608 被 mali 与 gpueb 同时声明**，612 只由 mali 声明。
> `[推断]` 若 kbase 在 r56p0 下不再 request 612，该线将无人 request；由于 612 不出现在 gpueb 节点内，需运行确认是否会产生未处理中断。此项列为 U3-22。

---

## 4. OPP 表：`/soc/opp-table0`

`compatible = "operating-points-v2"`，52 个子节点，`opp-hz` 为 **8 字节大端 u64**。

| 项 | 值 |
| --- | --- |
| 条目数 | 52（`opp00` … `opp51`） |
| 最高频 | **1612 MHz**（`opp00`，880 mV） |
| 最低频 | 338 MHz（`opp49`/`opp50`/`opp51`，500 mV） |
| 步长 | 26 MHz（`opp00`→`opp49` 严格等差） |
| 电压范围 | 880 mV → 500 mV，单调不增 |
| 异常点 | 末三档同频同压（338 MHz / 500 mV） |

`[推断]` 末三档重复的原因：`/gpufreq-wrapper` 的 `dual-buck = <1>`，双 BUCK 需要为每个 rail 留独立索引；或为"关核保底"预留多个档位。`UNKNOWN`：无法从 DTB 判定。

> **对 Stage 2 的修正**：`gpu_source_inventory.md` 记"最高频 1.508 GHz"，DTB 实测 **1612 MHz**。1508 是 `opp04`，不是顶点。以 DTB 为准。

---

## 5. 平台子节点全景

### 5.1 `/mgm`

```
compatible = "arm,physical-memory-group-manager"
```

无子节点、无其他属性。**完全符合** `arm,physical-memory-group-manager.yaml`（`required: [compatible]`）。

kbase 侧引用：`mali_kbase_mem.c:322` 的 `of_parse_phandle(..., "physical-memory-group-manager", 0)`。

### 5.2 `/protected-memory-allocator`

| 属性 | 值 | 官方 binding 要求 |
| --- | --- | --- |
| `compatible` | `"arm,protected-memory-allocator"` | ✔ |
| `pma-version` | `<2>` | 非官方属性（`unevaluatedProperties` 放行） |
| `gpr-id` | `<6>` | MTK 私有 |
| `gmpu-table-size` | `<0>` | MTK 私有 |
| `protected-reserve-size` | `<0x200000>` = 2 MB | MTK 私有 |
| `disable-init-gpu-iommu` | `<0>` | MTK 私有 |
| `gpufreq-supply` | `<0xa8>` → `/soc/gpufreq@48500000` | MTK 私有 |
| **`memory-region`** | **缺失** | ❌ **binding 要求但未提供** |

子节点两个：

```
/protected-memory-allocator/gpu-iommu
    compatible = "mediatek,gpu-iommu"
    iommus = <0xa9 1>              ← SMMU stream ID 1
    mtk,smmu-dma-mode = "disable"

/protected-memory-allocator/gpu-iommu-protected
    compatible = "mediatek,gpu-iommu"
    iommus = <0xa9 2>              ← SMMU stream ID 2（保护域）
    mtk,smmu-dma-mode = "disable"
```

> **关键推断**：`memory-region` 缺失 + `protected-reserve-size` 存在，说明 **MTK 的 PMA 不走 Arm 样例的 reserved-memory 方案**，而是走 `dma_heap_buffer_alloc` + `trusted_mem_ffa_query_pa`（见 `04` §3.4）。这解释了为什么 PMA 模块的 `UND` 里有 `dma_buf_attach`、`dma_heap_find`、`trusted_mem_ffa_query_pa` 而非 `of_reserved_mem_device_init`。

### 5.3 `/ged`

```
compatible = "mediatek,ged"
gpufreq-supply = <0xa8>        ← 指向 /soc/gpufreq@48500000
```

无子节点。GED 通过它拿到 GPUFreq 设备引用。

### 5.4 `/gpufreq-wrapper`

```
compatible = "mediatek,gpufreq_wrapper"
gpufreq-version  = <2>
dual-buck        = <1>          ← 双 BUCK 供电
gpueb-support    = <1>          ← 走 GPUEB（IPI）而非 AP 直写
gpufreq-bringup  = <0>          ← 非 bringup 模式，正常上电
ghpm-supply      = <0xac>  → /soc/ghpm@4b800000
```

这四个值直接决定 GPUFreq 的运行形态：**双 BUCK + GPUEB 卸载 + 正常运行**。

### 5.5 `/soc/gpufreq@48500000`

```
compatible = "mediatek,gpufreq"
reg = 0x48500000 + 0x100000,
      0x48600000 + 0x200000,
      0x48800000 + 0x100000,
      0x4b190000 + …
reg-names = mfg_top_config, mfg_smmu, mfg_vgpu_bus_trk, mfg_gpueb_bus_…
gpufreq-wrapper-supply = <0x168>
```

**`mfg_smmu` 在 GPUFreq 的寄存器范围内**——这是"GPU SMMU 的寄存器由 GPUFreq 管"的 DTS 级证据（见 §5.7）。

### 5.6 `/soc/gpueb@4b000000`

| 属性 | 值 |
| --- | --- |
| `compatible` | `"mediatek,gpueb"` |
| `gpueb-support` | `<1>` |
| `ghpm-support` | `<1>` |
| `gpueb-logger-support` | `<0>` |
| `mbox-count` / `mbox-size` / `slot-size` | `1` / `0xa0` / `4` |
| `reg` | 5 段：`0x4b000000`(0xa0000)、`0x4b09fd00`(0x800)、`0x4b140100`(2)、`0x4b120000`(1)、… |
| `interrupts` | `<0 608 4 0>`（mbox0） |
| `gpueb-mem-table` | `MEM_ID_GPUFREQ`(0x4000=16 KB)、`MEM_ID_LOG`(0x180000=1.5 MB) |
| `send-table` / `recv-table` | 12 条 IPI 通道，见 `02` §2 |
| `gpueb-diagnosis-mode` | `<0>` |

### 5.7 `/soc/iommu@48600000`

```
compatible = "arm,smmu-v3", "mtk,smmu-v700", "mediatek,mt6991-gpu-smmu"
reg        = 0x48600000 + 0x1e0000, 0x487e0000 + 0x10000
interrupts = <0 616 4 0>            ← 注意是 616，不是 mali 的 604~612
interrupt-names = "combined"
interrupt-disable = <1>             ← SMMU 中断被显式关闭
mtk,gmpam-cfg = <5 0>
mtk,mpam-cfg  = <1 5 0 2 5 0>
mediatek,dvm                       ← 空属性，存在即启用
dma-coherent
```

三个要点：

1. **`arm,smmu-v3` 排在第一位** → 由通用 `arm-smmu-v3` 驱动接管，不是 Mali 驱动。
2. **`interrupt-disable = <1>`** → SMMU 故障中断不使能。这意味着 GPU 侧的内存违规**不会**通过 SMMU 中断上报，只能靠 GPU 自己的 MMU fault（IRQ 605）。
3. **`mali` 节点没有 `iommus` 属性** → GPU 主数据路径不走 mali 设备的 IOMMU 域。只有 PMA 的两个子节点用了 `iommus = <0xa9 1|2>`。

> 这一组合解释了为什么 kbase 里 `iommu_map` / `arm_smmu` 的命中为 0（Stage 2 KB-047 已证）：**GPU 用自己的 MMU 管 GPU VA→PA，SMMU 只用于 PMA 的保护内存域**，且主域可能由 bootloader 预设。

---

## 6. 四个"缺失属性"的含义

| 缺失属性 | 后果 | 依据 |
| --- | --- | --- |
| **`clocks`** | `kbdev->nr_clocks = 0` → `clk_set_rate` 循环体不执行。GPU 时钟完全由 GPUFreq 直写 MFGPLL 寄存器决定 | `mali_kbase_devfreq.c:196` 的 `for (i < kbdev->nr_clocks)`；`mtk_gpufreq_mt6991` 定义 `g_mfg_pll_base` 等基址 |
| **`power-domains`** | `dev_pm_genpd_set_performance_state` 返回 `-ENODEV`，被显式容忍 | `mali_kbase_devfreq.c:142-147` |
| **`iommus`** | GPU 主路径不走 SMMU 域；SMMU 只服务 PMA | §5.7 |
| **`mboxes`** | GPU 节点不直接持有 mailbox，IPI 由 `mtk_gpueb` 独占 | `/soc/gpueb@4b000000` 有 `mbox-count`；mali 节点无 |

**这四条合起来是一个统一的结论**：MTK 把 GPU 的"时钟/电源/地址转换/通信"四类资源**全部从设备树的标准绑定点上移走**，改由 GPUFreq + GPUEB + PMA 三个私有驱动接管。

> 这既是移植的**难点**（r56p0 的 `platform/devicetree` 实现假设这些属性存在），也是移植的**便利点**（因为不依赖，所以不需要在 DTS 里补齐）。

---

## 7. 与 Arm 官方 binding 的对规结果

| 检查项 | 官方要求 | 实际 DTS | 结论 |
| --- | --- | --- | --- |
| `compatible` 末项 | 必须是 `arm,malit6xx` / `arm,mali-midgard` / `arm,mali-bifrost` 之一 | `arm,mali-valhall` | ❌ **不在枚举内** |
| `interrupts` 数量 | `minItems: 3, maxItems: 3` | **6** | ❌ **超限 100%** |
| `reg` 数量 | `maxItems: 1` | 1 | ✅ |
| `unevaluatedProperties` | `true` | — | ✅ MTK 私有属性不被判错 |
| `/mgm` required | `compatible` | `compatible` | ✅ |
| `/protected-memory-allocator` required | `compatible` + **`memory-region`** | 缺 `memory-region` | ❌ |

**结论：这个 DTS 无法通过 `dtbs_check`。** 但这不影响运行——kbase 不做 binding 校验，只按 `of_parse_phandle` / `of_property_read_*` 取自己认识的属性。

> 这也解释了一个反直觉现象：`arm,mali-valhall` 明明是 Arm 的命名，却不在 Arm 自己的 binding 枚举里——因为该 yaml 只覆盖 Midgard/Bifrost，Valhall（含 G925 所在的 5th Gen）走的是另一套未随包发布的 binding。
> **注意**：`Documentation/` 下这 5 个 yaml 含网页重构残留（`:contentReference[oaicite:N]`，见 `03_kbase_csf/MANIFEST.md` §5）。本报告**只引用其结构性字段**（`compatible` 枚举、`required` 列表、`minItems/maxItems`），**未引用任何叙述性文字**。

---

## 8. `sleep-mode-enable` 闭环（解决 Stage 2 的 U 项）

Stage 2 `04_pm_interface_diff.md` KB-055 把"`sleep-mode-enable` 属性在哪里"列为 UNKNOWN。现在闭环：

```
/soc/mali@48000000/sleep-mode-enable = <1>
        ↓
mali_kbase_config_mt6991.c:666   of_property_read_u32(np, "sleep-mode-enable", &sleep_mode_enable)
        ↓ sleep_mode_enable == 1
:670  pm_callbacks.power_runtime_init_callback        = kbase_device_runtime_init;
:671  pm_callbacks.power_runtime_term_callback        = kbase_device_runtime_disable;
:672  pm_callbacks.power_runtime_on_callback          = pm_callback_runtime_on;
:673  pm_callbacks.power_runtime_off_callback         = pm_callback_runtime_off;
:674  pm_callbacks.power_runtime_gpu_idle_callback    = pm_callback_runtime_gpu_idle;
:675  pm_callbacks.power_runtime_gpu_active_callback  = pm_callback_runtime_gpu_active;
```

**这 6 个回调在本机是启用的**，因此：

- `pm_callback_runtime_gpu_active` 里的 APO 逻辑（`ged_gpu_apo_support() == APO_NORMAL_SUPPORT` 时按目标帧率调 autosuspend 延时，`mt6991.c:475-496`）**会执行**
- `pm_callback_runtime_gpu_idle` 里的 `pm_runtime_put_autosuspend` + `ged_dvfs_gpu_clock_switch_notify(GED_SLEEP)` **会执行**

r56p0 的 `platform/devicetree/mali_kbase_runtime_pm.c` 是**无条件注册**这组回调，没有 `sleep-mode-enable` 开关。移植时若直接用它，行为上等价于"永远开启 sleep mode"——本机恰好就是开启的，**所以这一项反而可以低风险复用**。

---

## 9. UNKNOWN

| ID | 项 | 缺什么 |
| --- | --- | --- |
| U3-20 | DTS 源文件（`mt6991.dts`）是否可得 | 仓库内只有编译后的 dtbo；`gpu_source_inventory.md` 记载源在 `mt6991.dts:7874`，但该仓库未归档 |
| U3-21 | GPU 主路径的 SMMU 域由谁建立 | `mali` 无 `iommus`，`interrupt-disable=1`；可能是 bootloader 预设 stream mapping |
| U3-22 | IRQ 612（GPUEB_MBOX1）在 gpueb 侧是否也 request | 共享中断的分配方式需运行确认 |
| U3-23 | `l2-hash-values = <0x0b 0x0e 0x00>` 的语义 | 无 binding 说明，kbase 源码亦无对应属性读取点（`[推断]` 供 GPUEB 固件使用） |
| U3-24 | `adaptive-power-policy = <2>` 与 GED 的 `APO_2_0_NORMAL_SUPPORT` 是否一一对应 | 无 GED 源码 |
