# 平台保留与重建矩阵 · 最小化移植路线

> 依据：`01`–`05` 五份报告的实测结论汇总
> 交叉引用：`03_kbase_csf/06_blocking_issues.md`（Stage 2 汇总）、`03_kbase_csf/03_memory_mmu_diff.md`、`03_kbase_csf/04_pm_interface_diff.md`
> 本文件同时承载 **TASK 03 第四节要求的六项 Stage 2 复核**

---

## 0. 总回答

> **问题：能否最大程度保留 MT6991 原厂平台管理体系，只重建它与 R56p0 Kbase/CSF 之间的连接层？**

**结论：可以，且"重建连接层"的工作量远小于"整体重写"。但"连接层"的实际边界比 Stage 2 描述的要窄、也更碎。**

三条量化事实支撑这一判断：

| # | 事实 | 数值 | 出处 |
| --- | --- | --- | --- |
| 1 | MTK 平台层对 kbase 的**反向符号依赖** | **0** | `01` §4 |
| 2 | kbase 对 MTK 平台层的**正向符号依赖** | **89**（ged 53 / gpufreq 16 / hal 13 / gpueb 6 / pdma 1） | `01` §4 |
| 3 | MTK 注入到 kbase **结构体内部**的字段块 | **45**（跨 7 个结构体，`kbase_device` 占 29） | `01` §9 |

即：**"接口"只有 89 个，"结构"有 45 处**。前者可以逐个重接，后者必须按 r56p0 的新布局重新安放——这才是真正不可机械化的部分。

---

## 1. 平台保留与重建矩阵

| 子系统 | 原厂实现（证据路径） | 是否依赖原厂 Kbase | R56p0 对接难度 | 建议 |
| --- | --- | --- | --- | --- |
| **GPUFreq** | `vendor_dlkm/mtk_gpufreq_wrapper.ko`（42 导出）+ `mtk_gpufreq_mt6991.ko`（123 定义，0 导出）<br>调用方：`platform/mt6991/mali_kbase_config_mt6991.c:128,150,178,209` | **否**（0 反向引用） | **低** | **保留**（源码不动，重编译）<br>仅需在 kbase 侧重接 16 个符号 |
| **GPUEB** | `vendor_dlkm/mtk_gpueb.ko`（31 导出）<br>DT：`/soc/gpueb@4b000000`，12 条 IPI 通道 | **否** | **低** | **保留**<br>kbase 侧只需恢复 `ghpm_ctrl`/`wait_gpueb`/`gpueb_dump_status` 等 6 个调用 |
| **GED** | `vendor_dlkm/ged.ko`（168 导出，2,371 定义）<br>调用方：`platform/mt6991/*.c`、`platform/mtk_platform_common/*.c` | **否** | **中** | **保留**<br>需重插 53 个调用点，其中 `ged_mali_event_*` 7 个在 r56p0 无天然落点 |
| **GPU Power** | `platform/mt6991/mali_kbase_config_mt6991.c`（775 行）<br>`pm_callbacks` @ `:641-652`，4 个回调 + 6 个 runtime PM 回调 | **是**（直接读写 `kbase_device` 字段与 `pm.*` 内部状态） | **高** | **适配**<br>回调原型不变（`kbase_pm_callback_conf` 12 成员逐项一致），但 GHPM 分支（`:247-290`、`:332-419`）与 5 条 `WARN_ON` 不变量需整体重写 |
| **MGM** | `vendor_dlkm/mali_mgm_mt6991_r49.ko`（92 定义，**0 导出**）<br>DT：`/mgm`，phandle `<0x164>`<br>绑定：`mali_kbase_mem.c:322-343` | **部分**（仅经 DT + `platform_get_drvdata`，无符号） | **中** | **适配**<br>① `mgm_update_gpu_pte` 4→6 参数；② 第 7 槽位语义被替换（`mgmm_cache_pool_size` → `mgm_get_import_memory_cached_access_permitted`），**必须显式处理** |
| **PMA** | `vendor_dlkm/mali_prot_alloc_mt6991_r49.ko`（25 定义，**0 导出**）<br>DT：`/protected-memory-allocator`，phandle `<0x165>`<br>绑定：`csf/mali_kbase_csf_protected_memory.c:31-58` | **部分**（同上） | **低** | **保留**<br>ops 表与 device 结构**逐字节相同**；`protected_memory.c` 两版 155 行/4463 B **完全相同** |
| **IOMMU** | `vendor_dlkm/mtk_gpu_iommu_mt6991.ko`（18 定义，0 导出）<br>DT：`/soc/iommu@48600000`（`arm,smmu-v3`）；PMA 下两个 `mediatek,gpu-iommu` 子节点 | **否** | **低** | **保留**<br>由通用 `arm-smmu-v3` 驱动接管；`mtk_gpu_iommu` 只服务 PMA 的两个 stream（1/2） |
| **DTS** | `kernel_ref_mt6991/dtb/mt6991.dtb`（DT-Table 封装，内层 2,194 节点）<br>GPU 节点 `/soc/mali@48000000` | **否**（属性由各驱动分别读取） | **低** | **保留**<br>MGM/PMA 的 phandle 名两版一致，**无需改 DTS**；但 `sleep-mode-enable=1` 必须保留 |

### 1.1 一句话版

| 结论类别 | 子系统 |
| --- | --- |
| **保留**（源码不改，重编译即可） | GPUFreq、GPUEB、GED、PMA、IOMMU、DTS |
| **适配**（改少量代码/签名） | MGM、GPU Power 胶水层 |
| **重写** | 无（没有哪个平台模块需要从零写） |

> 这与 Stage 2 的印象不同。Stage 2 因为只看了 `03_kbase_csf` 的内部注入数，得出"平台层被 Arm 大改、必须重写"的印象。TASK 03 从**模块边界**看，得到相反结论：**MTK 平台层是干净的，脏的是 kbase 内部。**

---

## 2. 最小化移植路线

### 2.1 路线图

```mermaid
graph LR
    P0[P0 基线验证<br/>平台 12 模块重编译] --> P1[P1 胶水层重建<br/>mt6991.c 775 行<br/>mtk_platform_common 42 文件]
    P1 --> P2[P2 89 个调用点回接]
    P2 --> P3[P3 45 处结构体字段迁移]
    P3 --> P4[P4 MGM 签名适配]
    P4 --> P5[P5 可观测性恢复<br/>热限幅 / GPUEB 计数 / WARN 不变量]
```

### 2.2 五个阶段的工作量

| 阶段 | 内容 | 涉及规模 | 风险 |
| --- | --- | ---: | --- |
| **P0** | 12 个平台模块用 r56p0 树头文件重编译；不改源码 | 12 个 `.ko` | 低。唯一风险是 `vermagic`/`__versions` CRC 必须与新内核匹配 |
| **P1** | 把 `platform/mt6991/mali_kbase_config_mt6991.c`（775 行）+ `platform/mtk_platform_common/`（42 文件、~7,000 行）搬到 r56p0 的 `platform/` 下 | ~7,800 行 | **中**。r56p0 的 `platform/Kconfig` 与 `Makefile` 需新增条目 |
| **P2** | 回接 89 个符号调用点 | 89 处 | 中。`csf/`+`backend/` 只有 11 处，其余 78 处在 `platform/` 内部 |
| **P3** | 迁移 45 处结构体字段块 | 7 个结构体 | **高**。r56p0 结构体布局有变动，每块都要重新定位 |
| **P4** | MGM ops 适配 | 1 个函数 + 1 个槽位 | **高**。第 7 槽位无编译期保护 |
| **P5** | 恢复可观测性 | 见 §4 | 中。热限幅是安全相关 |

### 2.3 P3 明细：45 处结构体注入的分布

| 结构体 | `CONFIG_MALI_MTK_*` 块数 | 代表字段 |
| --- | ---: | --- |
| `kbase_device` | **29** | `ghpm_lock`、`low_volt_count`、`brcast_timeout_count`、`api_sync_*`（8 个）、`current_nominal_freq`、`rank_boundary`、`pt_clustering_enable` |
| `kbase_context` | **6** | `api_version` 扩展、`jit_reclaim_*` |
| `kbase_mmu_debug_info` | 5 | MMU 调试扩展 |
| `kbase_sub_alloc` | 2 | 子分配扩展 |
| `kbase_mmu_mode` | 1 | MMU 模式扩展 |
| `job_status_qos` | 1 | QoS 状态 |
| `kbase_mem_migrate` | 1 | 迁移扩展 |
| **合计** | **45** | |

> 这是"不可机械化"的核心：这 45 个块不是函数调用，是**类型定义的一部分**。r56p0 若调整了同一结构体的成员顺序或大小（Stage 2 已证 `base_csf_notification` 内部有位移），每一块都要重新确认偏移。

### 2.4 路线是否成立？

**成立，但成立的条件与"最小化"的直觉相反。**

不成立的做法：
> "把 r56p0 的 `drivers/gpu/arm/midgard` 整个替换进来，再把 MTK 的 `platform/` 拷回去。"

理由：MTK 的 `platform/` **不满足** r56p0 的接口契约。它依赖
- `kbase_device` 里的 29 个 MTK 字段（r56p0 没有）
- `pm_callbacks` 的 6 个 runtime 回调在 `mtk_platform_pm_init()` 里**动态注册**（r56p0 的 devicetree 实现是无条件静态注册）
- `csf/` 里的 1 处 `gpufreq_get_cur_freq`（`ipa_control`）与 `backend/` 的 10 处 MTK 注入

成立的做法：
> "以 MTK 的 `platform/` 为主干，把它移植到 r56p0 的骨架里，同时把 45 处结构体字段补回 r56p0 的结构体定义。"

即**方向是"MTK 平台层向 r56p0 对齐"，不是"r56p0 向 MTK 对齐"**。这与"只重建连接层"字面不同，但实质相同——**连接层 = 45 处字段 + 89 个调用点**，而不是 900 处零散引用。

---

## 3. 六项 Stage 2 复核

### 复核 1：`CONFIG_MALI_MTK_*` 的 87 与 39 两种口径

**结论：87 与 39 均无法从归档树复现；实测应为 91 / 85 / 88 / 81 / 38 五个口径，必须按口径分别引用。**

| 口径 | 命令 | 结果 |
| --- | --- | ---: |
| 全树（含 Makefile/Kbuild/Kconfig） | `grep -rho 'CONFIG_MALI_MTK[A-Z0-9_]*' . \| sort -u \| wc -l` | **91** |
| 仅 `.c` / `.h` | 同上去重后过滤扩展名 | **85** |
| 构建清单 `Kbuild-mtk-custom-env` | `grep -o 'CONFIG_MALI_MTK[A-Z0-9_]*' Kbuild-mtk-custom-env \| sort -u \| wc -l` | **88** |
| 其中以 `-D` 实际注入的 | `grep -o '\-DCONFIG_MALI_MTK[A-Z0-9_]*' … \| sort -u \| wc -l` | **81** |
| `csf/` 目录 | `grep -rho … csf \| sort -u \| wc -l` | **38** |

**87 的近似来源**：85（源文件）+ 2（仅出现在 `Makefile`/`Kbuild` 的 `CONFIG_MALI_MTK_GPU_BM_2`、`CONFIG_MALI_MTK_NO_THERMAL`）= **87**。这是一个**合理的口径**，但不是全树口径。
**39 的来源未复现**：`csf/` 无论按 `.c/.h` 还是全文件都只有 38。

> **统一表述建议**：
> "MTK 在 r49p1 中引入了 **81 个由 `-DCONFIG_MALI_MTK_*` 实际注入的编译开关**（构建清单枚举 88 个，源码引用 85 个，全树出现 91 个），其中 **38 个** 落在 `csf/` 子目录。"
> 任何"87""39"的写法应废弃或在脚注中说明其口径。

### 复核 2：66 / 45 / 21 的统计关系

**结论：66 不可枚举；可枚举的是 46。**

实测 `03_kbase_csf/` 下：

| 指标 | 值 |
| --- | ---: |
| `^## KB-` 标题数 | **46** |
| 唯一 `KB-` ID 数 | **46** |
| 其中"形态变更"（KB-030，UAPI 目录内联化） | 1 |
| 实质差异 | **45** |

Stage 2 `06_blocking_issues.md:6` 声称"汇总 66 条差异"，`:35` 注"45 条实质 + 21 条确认项"。

问题：**那 21 条确认项没有独立条目**，只以聚合计数散见于各报告 §0 的规模统计。因此

- 可逐条追溯：**46 条**（45 + KB-030）
- 声称但不可追溯：**20 条**（21 条确认项减去已单列的 KB-030）

> **统一表述建议**：
> "本阶段共形成 **46 条可追溯记录**（45 条实质差异 + 1 条目录形态变更），另有约 20 项'文件存在但无实质变化'的确认结论以规模统计形式记录在各报告 §0，不单独编号。"
> 应停止使用"66 条差异"这一表述。

### 复核 3：`gpu_props_user_data` 增加 24 字节是否导致用户态缓冲区越界

**结论：不成立。Stage 2 的 KB-007（P0 越界）应降级为 P2。**

两版 `kbase_ioctl_get_gpuprops` **代码完全相同**：

```c
/* r49p1 mali_kbase_core_linux.c:882-902 / r56p0 :871-891 */
if (get_props->flags != 0)                return -EINVAL;
if (get_props->size == 0)                 return (int)kprops->prop_buffer_size;   /* 查询模式 */
if (get_props->size < kprops->prop_buffer_size) return -EINVAL;                   /* ← 关键守卫 */
err = copy_to_user(u64_to_user_ptr(get_props->buffer), kprops->prop_buffer,
                   kprops->prop_buffer_size);
```

`copy_to_user` 的长度取的是**内核侧的 `prop_buffer_size`**，且进入拷贝前已用 `get_props->size` 做了下界检查。因此：

| 用户态行为 | 结果 |
| --- | --- |
| `size = 0` | 返回所需大小（r56p0 为 592），用户态据此重分配 → **正常兼容路径** |
| `size = 568`（旧版大小） | **返回 `-EINVAL`**，不发生任何拷贝 → **干净失败，不是越界** |
| `size >= 592` | 正常拷贝 592 字节 |

**没有任何路径会把 592 字节写进 568 字节缓冲区。**

`[推断]` Stage 2 的误判来源：把"结构体变大"直接等同于"越界"，未读实际 ioctl 处理函数。

**影响重估**：旧用户态 DDK 调用 `GET_GPUPROPS` 会收到 `-EINVAL`，表现为"取不到 GPU 属性 → 初始化失败"，属**显式失败**，不是内存破坏。严重度从 **P0 → P2**。

### 复核 4：PMA 缺失是否必然导致 DRM 版权视频无法播放

**结论：不必然。是"受保护内容路径降级"，不是"视频打不开"。**

三条实测代码路径：

```c
/* ① 初始化：PMA 找不到不报错，只打印 */
csf/mali_kbase_csf_protected_memory.c:36
    dev_info(kbdev->dev, "Protected memory allocator not available\n");   /* 注意是 info，不是 err */

/* ② 固件加载：protected 段直接跳过，返回 0（成功） */
csf/mali_kbase_csf_firmware.c:843-847
    if (protected_mode && kbdev->csf.pma_dev == NULL) {
        dev_err(kbdev->dev, "Protected memory allocator not found, "
                "Firmware protected mode entry will not be supported");
        return 0;                      /* ← 关键：return 0，不是 -EINVAL */
    }

/* ③ 运行期分配：WARN_ON 后返回 NULL，不 deref */
csf/mali_kbase_csf_protected_memory.c:96
    if (WARN_ON(!pma_dev) || WARN_ON(!phys) || !pma) return NULL;
```

因此实际影响链：

| 场景 | 是否受影响 |
| --- | --- |
| 普通视频播放（非保护内容） | **不受影响**，走普通 dma-buf 路径 |
| DRM 高等级（L1/L3）受保护内容 | **受影响**：GPU 无法进入 PROTM，安全路径不可用 |
| 内核稳定性 | **不受影响**：`return 0` + `WARN_ON`，不 panic、不 deref |
| 用户可见现象 | 受保护内容播放失败或退回软件/非安全路径；`dmesg` 有一条 `dev_err` |

**修正**：Stage 2 KB-043 的"PMA 缺失 → DRM 版权视频无法播放"应改为
> "PMA 缺失 → 固件 protected 段被静默跳过（`return 0`）→ GPU 无法进入保护模式 → 仅影响需要 secure video path 的受保护内容；普通播放不受影响。"

严重度维持 **P0（功能缺失）**，但需去掉"必然无法播放"的绝对表述。

### 复核 5：devfreq governor 变化是否必然造成帧率稳定性退化

**结论：不是"帧率退化"，是"控制语义被替换"，且应标注为待实机验证。**

详见 `03_ged_integration_audit.md` §4。要点：

| 维度 | 原厂 `mtk_devfreq_governor_dummy` | r56p0 `simple_ondemand` |
| --- | --- | --- |
| `polling_ms` | **0**（不轮询） | **100**（每 100 ms） |
| `get_target_freq` | 返回 `scaling_max_freq` | 按负载计算 |
| `target` 做什么 | `gpufreq_set_limit(LIMIT_THERMAL_AP, …)` | `clk_set_rate` + `regulator_set_voltage` + **`kbase_devfreq_set_core_mask`** |
| 频率能否真的变 | 不通过 devfreq 变 | **不能**（`nr_clocks == 0`，DTS 无 `clocks`） |
| 核心掩码 | 由 GED 控制 | **被 devfreq 每 100 ms 改写** |

三重副作用：① core mask 双写；② `current_nominal_freq` 被覆盖导致上报/IPA 失真；③ **热限幅通路断开**。

> **表述要求**：必须写成"**潜在**影响，需实机验证"，不得写成"必然造成帧率抖动"。
> 理由：频率实际改不动（无时钟），所以"帧率抖动"这一具体现象未必出现；真正确定的是热限幅断开与 core mask 双写。
> 风险等级：**P1**，理由是热限幅涉及散热安全，而非性能。

### 复核 6：GPUEB 中断处理缺失是否影响正常 GPU 工作

**结论：不影响。属纯可观测性损失，应从 P0/P1 降为 P2。**

`csf/mali_kbase_csf_reset_gpu.c:1076-1110` 的处理函数全文只做计数与打印：

```c
static irqreturn_t kbase_gpueb_irq_handler(int irq, void *data) {
    unsigned int gpueb_irq_status = gpueb_get_mbox1_irq();
    if (gpueb_irq_status & BIT(0)) {
        kbdev->low_volt_count++;
        dev_err(..., "++LOW_VOLT[%llu] BRCAST_TIMEOUT[%llu]", ...);
    } else if (gpueb_irq_status & BIT(1)) {
        kbdev->brcast_timeout_count++;
        dev_err(..., "LOW_VOLT[%llu] ++BRCAST_TIMEOUT[%llu]", ...);
    }
    ...
}
```

关键验证：`low_volt_count` / `brcast_timeout_count` 在全树的**全部**出现位置：

```
csf/mali_kbase_csf_reset_gpu.c:1083,1085,1089,1092,1094,1098  ← 仅此函数内
csf/mali_kbase_csf_reset_gpu.c:1138-1139                       ← 复位时清零
mali_kbase_defs.h:1201-1202                                    ← 字段声明
```

**没有任何其他代码读取这两个计数器**——不参与 DVFS 决策、不参与 thermal、不参与 IPA。因此：

- 正常路径：**完全不受影响**
- 异常路径：失去"低压 / 广播超时"的现场计数，排障时少一条线索
- 中断本身：IRQ 612 仅 mali 声明，r56p0 不再 request → 该线无人处理，但因未 `request_irq` 也不会使能，**不产生中断风暴**

**降级理由**：从"影响正常运行"（P0/P1）降为"可观测性缺失"（**P2**）。

### 3.7 复核汇总表

| # | Stage 2 原结论 | 复核结果 | 严重度变化 |
| ---: | --- | --- | --- |
| 1 | 87 / 39 两种口径 | 均不可复现；实测 91/85/88/81/38 | 表述问题，非技术结论 |
| 2 | 66 条差异（45 实质 + 21 确认） | 可枚举 46；20 条确认项不可追溯 | 表述问题 |
| 3 | `gpu_props_user_data` 568→592 导致 P0 越界 | **推翻**。有 `size < prop_buffer_size → -EINVAL` 守卫，干净失败 | **P0 → P2** |
| 4 | PMA 缺失必然导致 DRM 版权视频无法播放 | **部分推翻**。仅 protected 路径降级，`return 0` 不 panic；普通播放不受影响 | P0 保留（功能），表述收紧 |
| 5 | devfreq governor 变化必然造成帧率退化 | **修正**。频率改不动（无 clocks），实际是 core mask 双写 + 热限幅断开 | P1，标注待实机 |
| 6 | GPUEB 中断缺失影响正常运行 | **推翻**。纯计数器与日志，无人消费 | **P0/P1 → P2** |

> 六项复核中，**两项被推翻（3、6）**，**两项需收紧表述（4、5）**，**两项属统计口径问题（1、2）**。
> 没有任何一项复核是"为了维持原结论而忽略反证"——第 3、6 项的反证（守卫代码、计数器消费者缺失）是直接读源码得到的。

---

## 4. 风险登记

| 风险 | 等级 | 触发条件 | 缓解 |
| --- | --- | --- | --- |
| MGM 第 7 号 ops 槽位静默错配 | **P0** | 旧 MGM 二进制/源码直接配新 kbase | 编译期断言 + 显式实现 `mgm_get_import_memory_cached_access_permitted` 返回保守值 |
| 热限幅通路断开 | **P1**（安全） | 使用 `simple_ondemand` 而不恢复 MTK governor | 必须移植 `mtk_platform_devfreq_governor.c`（183 行） |
| 核心掩码双写 | P1 | 同上 | 同上 |
| 5 条电源状态机不变量丢失 | P1 | 直接使用 r56p0 的 `devicetree/mali_kbase_runtime_pm.c` | 把 `WARN_ON` 断言搬进 MTK 版回调 |
| `ged_mali_event_*` 7 个事件无落点 | P2 | 复位/错误路径未重新插入 | 在 r56p0 新的 `reset_gpu.c`（686 行）里找对应位置 |
| GPUEB 计数丢失 | P2 | 不移植该 handler | 可接受 |
| `rank_boundary` / 页表聚类丢失 | P2（性能） | MGM 不移植 | 需实测 TLB miss 影响 |
| 模块卸载引用计数泄漏 | P3 | 需要 `rmmod` 调试时 | 补 `module_put` 对称清理 |

---

## 5. UNKNOWN 汇总

TASK 03 全部 UNKNOWN 共 24 项，分布：

| 报告 | ID 范围 | 数量 | 主要缺口 |
| --- | --- | ---: | --- |
| `01_module_dependency_audit.md` | U3-01 … U3-05 | 5 | 函数表字段语义、间接函数指针调用、模块签名策略 |
| `02_gpufreq_gpueb_architecture.md` | U3-06 … U3-10 | 5 | `gpufreq_register_gpufreq_fp` 结构布局、`wait_gpueb` 超时、IPI 分工 |
| `03_ged_integration_audit.md` | U3-11 … U3-15 | 5 | 未使用的 115 个导出、FPSGO 协议、APO 判定、热限幅兜底 |
| `04_mgm_pma_memory_audit.md` | U3-16 … U3-19 | 4 | MGM 内部 SLC 策略、`mgmm_cache_pool_size` 消费者、PAGE_HEAP 开关 |
| `05_dts_hardware_resource_audit.md` | U3-20 … U3-24 | 5 | DTS 源文件、SMMU 域建立者、IRQ 612 归属、`l2-hash-values` |

**共同的根缺口只有两个**：

1. **MTK 平台层无源码**。`MiCode/MTK_kernel_modules @ fe0fa7ff` 里有（`drivers/gpu/mediatek/**` 共 211 文件），但未归档进本仓库。若补齐，U3-01/06/11/13/16/17 六项可直接闭环。
2. **CSF 固件与用户态 DDK 缺失**。`mali_csffw.bin` 与 `libGLES_mali.so` 在所有已获取仓库中 0 命中，导致固件行为类问题（U3-10/15/22）无法静态解决。

---

## 6. 最终回答

> **哪些 MTK 平台模块可以保留？**
> GPUFreq（2 个模块）、GPUEB、GED、GPU HAL、GPU QoS、GPU PDMA、Power Throttling、GPU IOMMU、PMA——**共 10 个模块，源码不改**。

> **哪些必须适配？**
> MGM（1 个函数签名 + 1 个槽位语义）、GPU Power 胶水层（`mali_kbase_config_mt6991.c` 775 行中的约 430 行 + `mtk_platform_common/` 42 文件）。

> **哪些必须重写？**
> **无**。

> **最小化移植路线是否成立？**
> **成立**。条件是接受一个方向性反转：不是"保留 MTK 平台层、替换 Arm 核心"，而是"**以 MTK 平台层为主干，把 r56p0 的核心嫁接到它的接口上**"。
> 代价集中在两处：45 处结构体字段块（不可机械化）+ 89 个符号调用点（可机械化）。前者是 3 天量级的手工核对，后者是 1 天量级的机械替换。

---

## 7. 与 Stage 2 Q5 的关系

Stage 2 `06_blocking_issues.md` 的 Q5 结论是"不存在干净切面"。TASK 03 的结论是"存在，但在另一个位置"。

| 视角 | 切面位置 | 结论 |
| --- | --- | --- |
| Stage 2（kbase 内部注入点） | `csf/` `mmu/` `backend/` 内部 | **不存在**——注入嵌在函数体里 |
| TASK 03（模块边界） | kbase ↔ MTK 模块之间 | **存在**——89 个符号 + 45 个字段块 |

两个结论不矛盾：**接口边界是干净的，函数体内部是脏的**。移植的可行路径是"沿着接口边界搬模块，再逐个清理函数体内的字段引用"，而不是"整块替换"。
