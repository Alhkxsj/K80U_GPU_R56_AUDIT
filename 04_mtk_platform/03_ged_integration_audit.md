# GED 对接审计

> 依据：`01_original_baseline/kernel_ref_mt6991/vendor_dlkm/ged.ko`（1,093,352 B，`not stripped`）@ **r49p1-03bet0**
> 源码侧：`…/mali-r49p1/drivers/gpu/arm/midgard/platform/mtk_platform_common/mtk_platform_devfreq_governor.c`（183 行）
> 对照：`02_r56_source/mali_r56p0/…/midgard/backend/gpu/mali_kbase_devfreq.c` @ **r56p0-18eac0**
> 方式：ELF 符号 + 重定位调用边 + 源码逐行对读 · 未编译、未运行

---

## 0. 结论先行

| # | 结论 | 强度 |
| --- | --- | --- |
| 1 | GED 与 kbase 是**严格单向**：kbase 调用 GED 的 53 个符号；GED 对 kbase 的符号引用为 **0** | `[实证]` |
| 2 | GED 是**策略层**，本身不碰寄存器。它向下依赖 GPUFreq（20 符号）、GPU HAL（约 30 符号）、GPUEB（4 符号）、SSPM（3 符号）、DRM（2 符号） | `[实证]` |
| 3 | 原厂 devfreq **不是调频引擎**。MTK 的 `mtk_devfreq_governor_dummy` 把 `polling_ms` 设为 **0**，`get_target_freq` 只返回 `scaling_max_freq`，`target` 回调把上限翻译成 `gpufreq_set_limit(TARGET_DEFAULT, LIMIT_THERMAL_AP, …)`。它的唯一职责是**让 thermal 框架能限住 GPU** | `[实证]` |
| 4 | r56p0 固定使用 `simple_ondemand`（`polling_ms = 100`），会引入**三重副作用**：core mask 双写、`current_nominal_freq` 被覆盖、热限幅失效 | `[实证]`（代码路径）+ `[推断]`（实际影响幅度，需实机） |
| 5 | kbase↔GED 的 53 个接口**全部是标量/指针参数**，无结构体跨界，可逐个重建 | `[实证]` |

---

## 1. GED 的规模与结构

`ged.ko` 是 15 个模块里最大的（1.09 MB，2371 个定义符号，240 个未定义符号，**168 个导出**）。导出符号按前缀分布：

| 前缀 | 数量 | 职责 |
| --- | ---: | --- |
| `ged_dvfs_*` | **29** | DVFS 核心：负载计算、频点提交、sysram 写入、core mask |
| `ged_get_*` | 22 | 状态读取（活跃/空闲时间、APO 参数、白盒测试开关） |
| `ged_kpi_*` | 18 | 帧率/掉帧 KPI，FPSGO 对接 |
| `mtk_gpueb_*` | 18 | GPUEB 侧 IPI 封装（**注意：前缀是 `mtk_gpueb_`，不是 `ged_`**） |
| `ged_set_*` | 17 | 状态设置 |
| `ged_gpu_*` | 16 | GPU 级动作（APO、压力测试、自动挂起） |
| `ged_mali_*` | 14 | **面向 kbase 的事件上报接口** |
| `ged_log_*` | 8 | 日志 |
| `dcs_get_*` / `dcs_set_*` | 4 + 4 | DCS（动态缓存 sizing） |
| `ged_check_*` | 4 | 状态查询 |
| `check_pm_callback_state` | 1 | PM 回调去重 |

> `ged.ko` 里出现 `mtk_gpueb_*` 前缀的 18 个导出，说明 GED 直接持有 GPUEB 的 IPI 封装，**不经过** `gpufreq_wrapper`。这是"GED 与 GPUEB 有独立通道"的证据。

---

## 2. kbase → GED：53 个接口，按语义分组

| 组 | 数量 | 代表符号 | kbase 侧用途 |
| --- | ---: | --- | --- |
| **DVFS 提交** | 5 | `ged_dvfs_gpu_freq_commit_fp`、`ged_dvfs_gpu_freq_dual_commit_fp`、`ged_dvfs_set_gpu_core_mask_fp`、`ged_dvfs_update_step_size`、`ged_dvfs_cal_gpu_utilization_ex_fp` | 请求调频 / 调核 |
| **sysram 影子写** | 10 | `ged_dvfs_write_sysram_last_commit_top_idx`、`_dual`、`_idx`、`_stack_idx` 及 4 个 `_test` 变体、`_protm_enter`、`_protm_exit` | 把目标频点写进 GPUEB 可见的 SRAM，供断电后恢复 |
| **last_commit 读回** | 3 | `ged_dvfs_get_last_commit_{idx,top_idx,stack_idx}` | 读取上次提交 |
| **功耗/APO** | 12 | `ged_gpu_apo_support`、`ged_gpu_apo_notify`、`ged_gpu_apo_reset`、`ged_gpu_predict_apo_*`、`ged_get_apo_autosuspend_delay_{ctrl,ms}`、`ged_get_apo_wakeup_ns`、`ged_gpu_autosuspend_timeout_notify`、`ged_get_autosuspend_stress`、`ged_gpu_power_stress_test_enable`、`ged_check_predict_power_autosuspend` | Adaptive Power Policy |
| **时间统计** | 4 | `ged_get_active_time`、`ged_get_idle_time`、`ged_get_predict_active_time`、`ged_get_predict_idle_time` | IPA / 功耗模型 |
| **KPI** | 2 | `ged_kpi_get_target_fps`、`ged_kpi_get_panel_refresh_rate` | 动态 autosuspend 延时 |
| **mali 事件上报** | 7 | `ged_mali_event_init`、`_notify_gpu_reset_done`、`_notify_fence_timeout_event`、`_update_gpu_reset_nolock`、`_update_cs_error_nolock`、`_update_device_lost_nolock`、`_update_pmode_flag_nolock` | **GED 靠这些知道 GPU 出了什么事** |
| **白盒/调试** | 4 | `ged_get_whitebox_power_test_case`、`_clear`、`_support`、`ged_set_whitebox_power_state_store` | 工厂测试 |
| **PM 断言** | 2 | `check_pm_callback_state`、`dump_pm_callback_kbase_info` | 上下电状态机去重与 dump |
| **其他** | 4 | `ged_dvfs_gpu_clock_switch_notify`、`ged_dvfs_record_soc_timer`、`get_api_sync_flag`、`mtk_bandwidth_resource_init` | 时钟切换通知、SOC timer、API sync、带宽资源 |

### 2.1 `ged_mali_event_*` 的特殊性

这 7 个符号是**唯一一组"kbase 主动告诉 GED 发生了什么"的接口**。在 r49p1 的注入里，它们被放在 GPU 复位、CS 错误、device lost、保护模式切换的路径上。

`[推断]` 它们的作用是让 GED 在 GPU 异常后**不要**继续按正常负载调频（否则会在复位期间把频率拉到高档）。移植时若漏掉，表现是"复位后一段时间频率行为异常"，而非崩溃——属于难查的软故障。

---

## 3. GED → kbase：确认为 0

对 `ged.ko` 的 240 个 `UND` 做 `kbase` 匹配，命中 **0**。GED 完全不知道 kbase 的存在。

GED 的真实下游依赖（`UND` 中可归属的部分）：

| 下游 | 符号数 | 代表 |
| --- | ---: | --- |
| `mtk_gpufreq_wrapper` | **20** | `gpufreq_set_limit`、`gpufreq_get_cur_freq`、`gpufreq_get_cur_oppidx`、`gpufreq_get_dynamic_power`、`gpufreq_get_leakage_power`、`gpufreq_get_working_table`、`gpufreq_get_core_mask_table`、`gpufreq_get_oppidx_by_freq` |
| `mtk_gpu_hal` | 约 **30** | `mtk_custom_boost_gpu_freq(_fp)`、`mtk_set_bottom_gpu_freq(_fp)`、`mtk_get_gpu_loading(_fp)`、`mtk_register_gpu_power_change`、`mtk_dvfs_loading_mode(_fp)`、`mtk_timer_base_dvfs_margin(_fp)` |
| `mtk_gpueb` | **4** | `get_gpueb_ipidev`、`gpueb_get_send_PIN_ID_by_name`、`gpueb_get_recv_PIN_ID_by_name`、`mtk_ipi_send_compl_to_gpueb` |
| `sspm_v3` | 3 | `sspm_reserve_mem_get_{phys,size,virt}` |
| `mediatek-drm` | 2 | `drm_register_fps_chg_callback`、`drm_unregister_fps_chg_callback` |
| `mtk_gpu_qos` | 3 | `MTKGPUQoS_{mode,mode_ratio,setup}` |

**这张表说明 GED 是"平台生态的汇聚点"**：它同时挂住 DRM（拿刷新率）、SSPM（拿共享内存）、QoS（拿带宽）、GPUEB（走 IPI）、GPUFreq（设限幅）、HAL（广播状态）。这 6 条边**没有一条**通向 kbase。

---

## 4. devfreq governor 的真相（Stage 2 结论需要修正）

### 4.1 原厂：`mtk_devfreq_governor_dummy` 不是 governor，是热限幅适配器

`platform/mtk_platform_common/mtk_platform_devfreq_governor.c`（183 行）全文只做三件事：

```c
/* :14-29 —— get_target_freq 不做任何负载计算 */
static int mtk_devfreq_governor_get_target_freq(struct devfreq *df, unsigned long *freq) {
    err = devfreq_update_stats(df);
    if (err) return err;
    *freq = (!df->scaling_max_freq) ? UINT_MAX : df->scaling_max_freq;   /* 只回上限 */
    return 0;
}

/* :138-141 —— 关键：polling 被关掉 */
void mtk_devfreq_governor_update_profile(struct devfreq_dev_profile *dp) {
    dp->polling_ms = 0;                       /* ← 不轮询，devfreq 永不主动调频 */
    dp->target = mtk_devfreq_governor_target;
}

/* :69-116 —— target 把 devfreq 的上限翻译成 GPUFreq 的热限幅 */
static int mtk_devfreq_governor_target(struct device *dev, unsigned long *freq, u32 flags) {
    freq_khz = *freq / 1000;
    if (mtk_common_gpufreq_bringup() || IS_ERR_OR_NULL(kbdev)) { ... return 0; }
    gpufreq_set_limit(TARGET_DEFAULT, LIMIT_THERMAL_AP, freq_khz, GPUPPM_KEEP_IDX);
    kbdev->current_nominal_freq = gpufreq_get_cur_freq(TARGET_DEFAULT) * 1000;
    return 0;
}
```

三点结论：

1. **`polling_ms = 0`**：devfreq 核心不会周期性调用 `target`。频率由 GED 通过 `gpufreq_set_limit` + `gpufreq_commit` 驱动，与 devfreq 无关。
2. **`get_target_freq` 返回 `scaling_max_freq`**：devfreq 在此只承担"上限"语义。
3. **`target` 不写寄存器**：它把上限转成 `gpufreq_set_limit(...LIMIT_THERMAL_AP...)`，即**把 thermal 的约束注入 GPUFreq 的限幅仲裁器**。

> **因此原厂设计的语义是：devfreq 是 thermal cooling device 的挂载点，不是 DVFS 引擎。** 名称里的 `_DUMMY` 名副其实。

### 4.2 r56p0：`simple_ondemand` + `polling_ms = 100`

`backend/gpu/mali_kbase_devfreq.c`：

```c
:655    dp->polling_ms = 100;                                        /* 每 100 ms 轮询 */
:681    kbdev->devfreq = devfreq_add_device(kbdev->dev, dp, "simple_ondemand", NULL);
```

`simple_ondemand` 会周期性调用 `kbase_devfreq_target`（`:111`），其行为链：

```
kbase_devfreq_target(dev, target_freq, flags)                        :111
├─ devfreq_recommended_opp(dev, &nominal_freq, flags)                :130
├─ dev_pm_genpd_set_performance_state(kbdev->dev, nominal_freq)      :142
│    ENODEV / EOPNOTSUPP 被显式容忍（"do not return error code"）     :143-147
├─ if (kbdev->current_nominal_freq == nominal_freq) return 0;        :151-154
├─ kbase_devfreq_opp_translate(...)                                  :156
├─ for (i < kbdev->nr_clocks) regulator_set_voltage(...)             :178-188
├─ for (i < kbdev->nr_clocks) clk_set_rate(...)                      :196-207
└─ kbase_devfreq_set_core_mask(kbdev, core_mask)                     :210
```

### 4.3 为什么这不是"简单退化"，而是三重副作用

结合 DTS 实测（`/soc/mali@48000000` **没有 `clocks`、没有 `power-domains` 属性**，见 `05_dts_hardware_resource_audit.md` §6）：

| 环节 | 原厂 | r56p0 + simple_ondemand | 实际后果 |
| --- | --- | --- | --- |
| genpd performance state | 不走这条 | `dev_pm_genpd_set_performance_state` → **-ENODEV**（无 power-domains），被容忍 | 无害，但每 100 ms 一次无效调用 |
| `clk_set_rate` | 不走这条 | `kbdev->nr_clocks == 0`（无 `clocks` 属性）→ **循环体不执行** | 无害：**频率根本设不动** |
| `regulator_set_voltage` | 不走这条 | 同样 `nr_clocks==0` → 不执行 | 无害 |
| **`kbase_devfreq_set_core_mask`** | 由 GED 经 `ged_dvfs_set_gpu_core_mask_fp` 控制 | **每 100 ms 按 devfreq 计算出的 core_mask 改写一次** | ⚠ **与 GED 双写 core mask** |
| **`current_nominal_freq`** | 由 `gpufreq_get_cur_freq()` 回填（真实值） | 被 `= nominal_freq` 覆盖为 **devfreq 的期望值** | ⚠ IPA 功耗模型、`kbase_devfreq_get_cur_freq` 上报全部失真 |
| **热限幅** | `gpufreq_set_limit(LIMIT_THERMAL_AP, ...)` | **无此调用** | ⚠ thermal cooling device 无法限住 GPU 频率 |

**结论修正**：Stage 2 的 `04_pm_interface_diff.md` KB-052 写"静默退化为 simple_ondemand，只影响帧率稳定性"。实测应改为：

> r56p0 退回 `simple_ondemand` 不是"换成另一个调频器"，而是**换成了一个完全不同的控制语义**：频率改不动（无时钟），但**核心掩码会被改写**、**上报频率失真**、**热限幅通路断开**。
> 其中"热限幅断开"风险最高——GPU 在持续高负载下失去 thermal 约束，可能导致降频失效、温升超出 SoC 预算。
> `[推断]` 实际是否触发过热保护，取决于 GPUEB 固件自身的 PTP3 保护是否会兜底。**必须实机验证**，不可在静态阶段下"必然"结论。

---

## 5. 接口映射表：原厂 → r56p0

| 原厂接口 | 原厂落点 | r56p0 对应 | 可迁移性 |
| --- | --- | --- | --- |
| `kbase_pm_callback_conf`（12 成员） | `mt6991.c:641-652`（初始化 10 个，2 个留 `NULL`） | `include/mali_kbase_config.h` 同名结构，**12 成员逐项一致** | ✅ **直接保留** |
| `power_on/off_callback` | `mt6991.c:217/295` | 同名字段 | ✅ 保留（需连带 GHPM 分支） |
| `power_suspend/resume_callback` | `mt6991.c:633/625` | 同名字段 | ✅ 保留 |
| `power_runtime_*` 6 个 | `mt6991.c:666-678` 依 `sleep-mode-enable` 动态注册 | 同名字段存在 | ✅ 保留（DT 本机 `=1`，必须注册） |
| `devfreq` governor | `mtk_platform_devfreq_governor.c` 全文件 | r56p0 固定 `"simple_ondemand"` | ⚠ **需把 governor 注册与 `update_profile` 重新接上** |
| `ged_dvfs_gpu_freq_commit_fp` | GED 导出 | 无对应 | ⚠ 需在 kbase 的调频决策点重新插入 |
| `ged_dvfs_set_gpu_core_mask_fp` | GED 导出 | 无对应 | ⚠ 同上 |
| `ged_kpi_get_target_fps` / `panel_refresh_rate` | GED 导出 | 无对应 | ⚠ 需接进 runtime PM 的 autosuspend 逻辑 |
| `ged_mali_event_*`（7 个） | GED 导出 | 无对应 | ⚠ 需插到 r56p0 的复位/错误路径 |
| `mtk_notify_gpu_power_change` | HAL 导出 | 无对应 | ⚠ 上/下电回调里补 |
| FPSGO 对接 | 经 `ged_kpi_*` + DRM `fps_chg_callback` | 无对应 | ❌ **GED 内部完成，kbase 不参与 → 无需迁移** |

**"可迁移性"列的含义**：✅ = 原型与语义都不变；⚠ = 原型在、调用点需重插；❌ = kbase 本来就不参与。

---

## 6. 判定

| 问题 | 答案 |
| --- | --- |
| GED 能否原样保留？ | **能**。它对 kbase 零依赖，重新编译即可（`vermagic`/`__versions` 需匹配新内核）。 |
| kbase 侧要做什么？ | 把 53 个调用点按 r56p0 的位置重新插入。**不需要改 GED 一行代码。** |
| 最大风险点 | `ged_mali_event_*` 7 个事件接口在 r56p0 的复位路径上没有天然落点——r56p0 把 `reset_gpu.c` 从 1,176 行砍到 686 行，原有的 `gpu_reset_entry_name[]`（23 项）都被删了，事件上报的插入位置需要重新设计。 |
| 热限幅 | **必须显式恢复**。这是本报告认为优先级最高的单项：不是性能问题，是散热安全问题。 |

---

## 7. UNKNOWN

| ID | 项 | 缺什么 |
| --- | --- | --- |
| U3-11 | GED 的 168 个导出中，另有 115 个未被 kbase 直接引用，是否被 kbase 通过函数指针间接使用 | 函数指针不经 `UND`，ELF 无法证否 |
| U3-12 | `ged_kpi_*` 的 18 个接口与 FPSGO 用户态的具体协议 | 无 GED 源码，无用户态 |
| U3-13 | APO（Adaptive Power Policy）的 `APO_NORMAL_SUPPORT` / `APO_2_0_NORMAL_SUPPORT` 判定依据 | 无源码；kbase 侧只做 `==` 比较（`mt6991.c:476`、`:532`） |
| U3-14 | `simple_ondemand` 在 `nr_clocks==0` 时的确切行为（是否报错刷屏） | 需运行验证 |
| U3-15 | 热限幅失效后 GPUEB 固件 PTP3 是否独立兜底 | 需实机 + 固件行为 |
