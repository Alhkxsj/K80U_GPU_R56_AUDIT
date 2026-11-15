# 电源管理接口差异审计：r49p1-03bet0 → r56p0-18eac0

> 审计标的：Redmi K80 至尊版（25060RK16C）/ MT6991 / Immortalis-G925 MC12
> 审计方式：纯静态比对，不改源码、不编译、不部署
> 审计日期：2026-11-15
> 依据：`02_r56_source/mali_r56p0/driver/product/kernel/drivers/gpu/arm/midgard/` @ **r56p0-18eac0**（`Kbuild:75`）
> 对照：`01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/` @ **r49p1-03bet0**（`Makefile:526`）

**基准路径**

| | 根 |
| --- | --- |
| A（r49p1） | `01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/` |
| B（r56p0） | `02_r56_source/mali_r56p0/driver/product/kernel/drivers/gpu/arm/midgard/` |

---

## 0. 结论摘要

**电源管理是本轮审计中"接口稳定、实现断层"最典型的一域。**

| 层 | 接口是否变 | 实现是否可搬 | 判断 |
| --- | :--: | :--: | --- |
| `kbase_pm_callback_conf`（平台→kbase 的 12 个回调） | **否，完全一致** | **可原样搬** | 好消息 |
| `kbase_platform_funcs_conf`（平台 init/term 四回调） | **否，完全一致** | **可原样搬** | 好消息 |
| `devfreq_dev_profile`（kbase→devfreq 的 governor 接口） | 否 | **否** | **MTK 分支被删** |
| 上电/掉电实际动作 | — | **否** | MTK 走 GPUEB，ARM 走 regulator |

→ **回调框架不用改，但所有回调的"身体"要重写**。这与 MGM（KB-040，签名都变了）形成鲜明对比。

---

## KB-050 — `kbase_pm_callback_conf` 结构体两版完全一致（12 个回调）

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-050 |
| **r49p1** | `A/mali_kbase_config.h`（`struct kbase_pm_callback_conf`） |
| **r56p0** | `B/mali_kbase_config.h`（同结构体） |
| **差异类型** | 无变化 |
| **影响 ABI** | 否 |
| **影响 MTK** | **否（利好）** |
| **严重程度** | **P3** |
| **证据等级** | **实证** |

逐个成员比对，**数量、顺序、签名全部一致**：

```
void (*power_off_callback)(struct kbase_device *kbdev);
int  (*power_on_callback)(struct kbase_device *kbdev);
void (*power_suspend_callback)(struct kbase_device *kbdev);
void (*power_resume_callback)(struct kbase_device *kbdev);
int  (*power_runtime_init_callback)(struct kbase_device *kbdev);
void (*power_runtime_term_callback)(struct kbase_device *kbdev);
void (*power_runtime_off_callback)(struct kbase_device *kbdev);
int  (*power_runtime_on_callback)(struct kbase_device *kbdev);
int  (*power_runtime_idle_callback)(struct kbase_device *kbdev);
int  (*soft_reset_callback)(struct kbase_device *kbdev);
void (*power_runtime_gpu_idle_callback)(struct kbase_device *kbdev);
void (*power_runtime_gpu_active_callback)(struct kbase_device *kbdev);
```

### 调用点也一致

| r49p1 `backend/gpu/mali_kbase_pm_backend.c` | r56p0 同文件 |
| --- | --- |
| `:68` `kbdev->pm.backend.callback_power_on = callbacks->power_on_callback;` | `:55` |
| `:69` `... callback_power_off = callbacks->power_off_callback;` | `:56` |
| `:107` `callbacks->power_on_callback(kbdev);` | `:94` |
| `:126` `callbacks->power_off_callback(kbdev);` | `:133` |

**含义**：MTK 的 `pm_callbacks` 实例（r49p1 `platform/mt6991/mali_kbase_config_mt6991.c:641-652`）**可以原样搬到 r56p0 的平台层**，结构体赋值不用改一个字。

> 这是本次审计中少见的"接口零成本"项。但要注意：能挂上去 ≠ 能跑起来，见 KB-052。

---

## KB-051 — 上电/掉电实现路径根本不同：MTK 走 GPUEB，ARM 走 regulator/genpd

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-051 |
| **r49p1** | `A/platform/mt6991/mali_kbase_config_mt6991.c:150`（`gpufreq_power_control(GPU_PWR_ON)`）、`:209`（`GPU_PWR_OFF`） |
| **r56p0** | `B/platform/devicetree/mali_kbase_runtime_pm.c:86-104`（`pm_callback_power_on` → `enable_gpu_power_control()`）、`:105-123`（`power_off` → `disable_gpu_power_control()`） |
| **差异类型** | 重构（实现路径替换） |
| **影响 ABI** | 否 |
| **影响 MTK** | **是（P0）** |
| **严重程度** | **P0** |
| **证据等级** | **实证** |

### r49p1 的路径

```c
/* mali_kbase_config_mt6991.c:29 */
#include <mtk_gpufreq.h>
/* :150 */
if (gpufreq_power_control(GPU_PWR_ON) < 0) {
/* :209 */
if (gpufreq_power_control(GPU_PWR_OFF) < 0) {
```

调用链：

```
kbase pm backend
  → pm_callback_power_on()
    → gpufreq_power_control(GPU_PWR_ON)          [MTK 导出符号]
      → GPUFreq 模块 (mtk_gpufreq_wrapper.ko)
        → IPI 命令 CMD_...
          → GPUEB 协处理器（MT6991 独有）
            → 实际操作 MTCMOS / BUCK / SWCG
```

### r56p0 的路径

```c
static int pm_callback_power_on(struct kbase_device *kbdev)
{
	...
	enable_gpu_power_control(kbdev);
	return 1;
}
```

`enable_gpu_power_control()` 是 ARM 的通用实现，走 Linux 标准电源框架：`regulator_enable` + `clk_prepare_enable` + `genpd`（`dev->pm_domain`，见 `:90` 的 `dev_dbg(... kbdev->dev->pm_domain)`）。

### 为什么是 P0

`gpufreq_power_control` 是 **MTK 的导出符号**，r56p0 的 kbase 树里**不存在**。两个层面：

1. **编译期**：MTK 的 `mali_kbase_config_mt6991.c` 无法直接编译进 r56p0 树（找不到 `<mtk_gpufreq.h>` 与符号声明）
2. **运行期**：即使强行链接，`gpufreq_power_control` 的内部实现依赖 MTK 的 GPUFreq 模块已初始化，而这个模块的初始化时序与 kbase 的 probe 顺序耦合

→ MTK 的平台层必须**整体移植**（不是复制文件，是重建），并保持与 GPUFreq 模块的加载顺序契约（`modules.load.vendor` 中的顺序，见 `01_original_baseline/gpu_dependency_map.md` §11）。

---

## KB-052 — devfreq governor 被 MTK 整体接管，r56p0 退回 `simple_ondemand`

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-052 |
| **r49p1** | `A/backend/gpu/mali_kbase_devfreq.c:677-686`（`CONFIG_MALI_MTK_DEVFREQ_GOVERNOR` 分支） |
| **r56p0** | `B/backend/gpu/mali_kbase_devfreq.c:681`（无分支，固定 `"simple_ondemand"`） |
| **差异类型** | 删除（MTK 分支） |
| **影响 ABI** | 否 |
| **影响 MTK** | **是（P0）** |
| **严重程度** | **P0** |
| **证据等级** | **实证** |

### r49p1 原文（`mali_kbase_devfreq.c:677-686`）

```c
#if IS_ENABLED(CONFIG_MALI_MTK_DEVFREQ_GOVERNOR)
	mtk_devfreq_governor_update_profile(dp);

	kbdev->devfreq = devfreq_add_device(kbdev->dev, dp,
				MTK_GPU_DEVFREQ_GOVERNOR_DUMMY, NULL);
#else
	kbdev->devfreq = devfreq_add_device(kbdev->dev, dp, "simple_ondemand", NULL);
#endif /* CONFIG_MALI_MTK_DEVFREQ_GOVERNOR */
```

### r56p0 原文（`mali_kbase_devfreq.c:681`）

```c
	kbdev->devfreq = devfreq_add_device(kbdev->dev, dp, "simple_ondemand", NULL);
```

无 `#if`，无 `mtk_devfreq_governor_update_profile()`，无 `MTK_GPU_DEVFREQ_GOVERNOR_DUMMY`。

### 这条为什么比 KB-051 更隐蔽

`gpufreq_power_control` 缺失会导致**编译失败**，问题立刻暴露。

但 devfreq governor 缺失是**静默降级**：

- `simple_ondemand` 是 Linux 内核自带的有效 governor，能正常注册、正常工作
- GPU 会按"负载高就升频、负载低就降频"的简单规则跑
- 不报错、不警告、dmesg 干净

后果表现在**体验指标**上，不在**功能指标**上：

| 维度 | MTK GED governor | ARM simple_ondemand |
| --- | --- | --- |
| 升降频依据 | 负载预测 + 温度 + 功耗预算 + 游戏帧率目标 | 上一窗口利用率 |
| 响应延迟 | 提前升频（预测） | 滞后升频（事后） |
| 温控联动 | 有（GED↔thermal） | 无 |
| 典型表现 | 帧率稳 | **帧率锯齿、卡顿** |

→ 移植时若只关注"能不能编译过"，会漏掉这条。**必须在性能测试阶段专门验证 governor 是否生效**（`/sys/class/devfreq/*/governor` 应显示 MTK 的 governor 名，而非 `simple_ondemand`）。

### 配套：MTK 的 thermal cooling 也一并消失

r49p1 `mali_kbase_devfreq.c` 有 **26 处 MTK 注入**：

| 符号 | 处数 |
| --- | ---: |
| `CONFIG_MALI_MTK_DEVFREQ_THERMAL` | 10 |
| `CONFIG_MALI_MTK_DEVFREQ_GOVERNOR` | 8 |
| `CONFIG_MALI_MTK_DVFS_POLICY` | 2 |
| `mtk_devfreq_cooling_power_ops` | 1 |
| `mtk_devfreq_governor_update_profile` | 1 |
| 其他 | 4 |

`mtk_devfreq_cooling_power_ops` 是 devfreq cooling device 的 power model 回调——MTK 用它告诉 thermal 框架"GPU 在频率 F 电压 V 下耗多少电"。缺失后 thermal 无法对 GPU 做精确的功耗预算分配。

---

## KB-053 — 平台层实现整体缺失：`platform/` 目录只剩 ARM 参考平台

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-053 |
| **r49p1** | `platform/` 含 `mt6991/`（775 行）、`mtk_platform_common/`（约 60 文件）、6 个其他 MTK SoC 目录 |
| **r56p0** | `platform/` 仅 `devicetree/`（49+252+99 行）、`meson/`、`vexpress/`、`vexpress_1xv7_a57/`、`vexpress_6xvirtex7_10mhz/` |
| **差异类型** | 删除（MTK 平台层整体不存在） |
| **影响 ABI** | 否 |
| **影响 MTK** | **是（P0）** |
| **严重程度** | **P0** |
| **证据等级** | **实证** |

### 目录对照

| r49p1 | r56p0 |
| --- | --- |
| `devicetree` | `devicetree` |
| `Kconfig` | `Kconfig` |
| `meson` | `meson` |
| `vexpress` | `vexpress` |
| `vexpress_1xv7_a57` | `vexpress_1xv7_a57` |
| `vexpress_6xvirtex7_10mhz` | `vexpress_6xvirtex7_10mhz` |
| **`mt6768`** | — |
| **`mt6781`** | — |
| **`mt6833`** | — |
| **`mt6853`** | — |
| **`mt6877`** | — |
| **`mt6893`** | — |
| **`mt6899`** | — |
| **`mt6991`** | — |
| **`mtk_platform_common/`**（约 60 文件） | — |
| **`mtk_mfg_counter.h`** | — |
| **`mtk_platform_common.h`** | — |
| **`mtk_platform_utils.h`** | — |

r56p0 的 `platform/` 是**纯 ARM 上游内容**，一个 MTK 文件都没有。

### r56p0 唯一的可参考实现：`platform/devicetree/`

| 文件 | 行数 | 内容 |
| --- | ---: | --- |
| `mali_kbase_runtime_pm.c` | 252 | 完整 PM 回调（power_on/off、runtime on/off、gpu active/idle、resume/suspend）+ regulator/clk 控制 |
| `mali_kbase_clk_rate_trace.c` | 99 | 时钟频率追踪 |
| `mali_kbase_config_devicetree.c` | 49 | devicetree 绑定入口 |
| `mali_kbase_config_platform.h` | 47 | 平台配置头 |

对 MTK 的意义：这 400 行给出了 r56p0 **期望的平台层最小实现**，可作移植模板。MTK 需要把 775 行的 `mt6991` 实现改造成同样的形状——但内部调用的仍是 GPUFreq/GPUEB。

---

## KB-054 — `kbase_platform_funcs_conf` 四回调一致（init/term 钩子可用）

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-054 |
| **r49p1** | `A/mali_kbase_config.h:52`（`struct kbase_platform_funcs_conf`，含 JM 专用 4 回调） |
| **r56p0** | `B/mali_kbase_config.h:44`（同结构体，去掉 `#if !MALI_USE_CSF` 块） |
| **差异类型** | 无实质变化（仅删 CSF 下不编译的 JM 分支） |
| **影响 ABI** | 否 |
| **影响 MTK** | 否 |
| **严重程度** | **P3** |
| **证据等级** | **实证** |

CSF 配置下有效的四个回调两版一致：

```c
int  (*platform_init_func)(struct kbase_device *kbdev);
void (*platform_term_func)(struct kbase_device *kbdev);
int  (*platform_late_init_func)(struct kbase_device *kbdev);
void (*platform_late_term_func)(struct kbase_device *kbdev);
```

r49p1 多出的四个（`platform_handler_context_init_func`、`platform_handler_atom_submit_func` 等）位于 `#if !MALI_USE_CSF` 内，**出厂构建是 CSF-only（`kbase_csf_*` 461 处 vs `kbase_jd_*` 5 处），本来就没编译**。

→ MTK 的平台 init/term 挂载点可以直接沿用。

---

## KB-055 — Runtime PM 与 `sleep-mode-enable` 设备树属性

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-055 |
| **r49p1** | `A/platform/mt6991/mali_kbase_config_mt6991.c:654-678`（`mtk_platform_pm_init` 读 `sleep-mode-enable`） |
| **r56p0** | `B/platform/devicetree/mali_kbase_runtime_pm.c:174-215`（`kbase_device_runtime_init/disable`、`pm_callback_runtime_on/off`） |
| **差异类型** | 修改（条件化注册 vs 固定注册） |
| **影响 ABI** | 否 |
| **影响 MTK** | **是** |
| **严重程度** | **P1** |
| **证据等级** | **实证** |

### r49p1 的做法：按设备树属性决定是否启用 runtime PM

```c
/* :660 */
if (!of_property_read_u32(np, "sleep-mode-enable", &sleep_mode_enable)) {
	dev_info(kbdev->dev, "Sleep mode %s", (sleep_mode_enable)? "enabled": "disabled");
	if (sleep_mode_enable == 1) {
		pm_callbacks.power_runtime_init_callback = kbase_device_runtime_init;
		pm_callbacks.power_runtime_term_callback = kbase_device_runtime_disable;
		pm_callbacks.power_runtime_on_callback = pm_callback_runtime_on;
		pm_callbacks.power_runtime_off_callback = pm_callback_runtime_off;
		pm_callbacks.power_runtime_gpu_idle_callback = pm_callback_runtime_gpu_idle;
		pm_callbacks.power_runtime_gpu_active_callback = pm_callback_runtime_gpu_active;
	}
} else
	dev_info(kbdev->dev, "Sleep mode: No dts property setting, default disabled");
```

注意 `pm_callbacks` 的静态初始化（`:641-652`）中，6 个 runtime 回调**初始为 NULL**，只有设备树里 `sleep-mode-enable = <1>` 才挂上。

### r56p0 的做法：固定注册

`platform/devicetree/` 的 `mali_kbase_runtime_pm.c` 里 12 个回调全部无条件实现并注册，不读 `sleep-mode-enable`。

### 影响

MT6991 的设备树里是否有 `sleep-mode-enable` 属性，决定了 r49p1 走不走 runtime PM 路径。**该属性未在 `mt6991.dts:7874-7908` 的 mali 节点内**（01-C 已核对过该节点全部属性），需进一步确认是在 dali 板级 dtsi 还是根本未设置。

> **UNKNOWN**：未在 `dali.dts` / `dali-mt6991-common.dtsi` 中检索该属性。若 K80U 未启用 sleep mode，则 runtime PM 路径在出厂机上**本就不活跃**，KB-055 的实际影响降为 P3。
> 建议在移植前用 `grep -n "sleep-mode-enable" arch/arm64/boot/dts/mediatek/{dali*,mt6991*}` 确认。

---

## KB-056 — IPA（Intelligent Power Allocation）实现差异

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-056 |
| **r49p1** | `ipa/` 含 `mali_kbase_ipa_counter_common_jm.c` 等 6 文件（JM 后端，未编译）；CSF 侧 IPA 在 `csf/ipa_control/` |
| **r56p0** | `ipa/mali_kbase_ipa.c` 等（无 JM 变体） |
| **差异类型** | 删除（JM 部分）+ 重构 |
| **影响 ABI** | 否 |
| **影响 MTK** | 是 |
| **严重程度** | **P2** |
| **证据等级** | 实证（文件集）+ **UNKNOWN**（CSF IPA 细节未比对） |

r49p1 的 `ipa/backend/` 下 4 个 `*_jm.c` 文件在 r56p0 中不存在（JM 后端整体移除）。CSF 侧的 `csf/ipa_control/mali_kbase_csf_ipa_control.c` 两版都有，且该文件有 **30 处 MTK 注入**（`CONFIG_MALI_MTK_DVFS_POLICY`、`CONFIG_MALI_MTK_GPU_DVFS_HINT_26M_LOADING`）。

> 未逐函数比对 `ipa_control.c`。MTK 在此处的 DVFS 提示机制属于电源域的一部分，需在移植时单独处理。

---

## 1. 电源域接口稳定性总表

| 接口 | 层级 | r49p1 → r56p0 | 能否原样搬 |
| --- | --- | :--: | :--: |
| `kbase_pm_callback_conf`（12 回调） | 平台 → kbase | 一致 | **能** |
| `kbase_platform_funcs_conf`（4 回调，CSF） | 平台 → kbase | 一致 | **能** |
| `devfreq_dev_profile` | kbase → devfreq | 一致 | 能（但 governor 名要改） |
| `gpufreq_power_control()` | kbase → GPUFreq | **r56p0 无此符号** | **否** |
| `MTK_GPU_DEVFREQ_GOVERNOR_DUMMY` | kbase → devfreq | **r56p0 无此分支** | **否** |
| `mtk_devfreq_cooling_power_ops` | kbase → thermal | **r56p0 无** | **否** |

---

## 2. 本文件的结论

1. **电源域的两层接口都稳定**：`kbase_pm_callback_conf`（12 回调）与 `kbase_platform_funcs_conf`（4 回调）在两版中**逐成员一致**，调用点也一致（`mali_kbase_pm_backend.c:107/126` vs `:94/133`）。MTK 的注册代码可以原样搬。

2. **但回调的"身体"必须全部重写**：MTK 的 `power_on` 调 `gpufreq_power_control(GPU_PWR_ON)` 走 GPUEB 协处理器，r56p0 的模板调 `enable_gpu_power_control()` 走 regulator/genpd。**这是两套完全不同的硬件控制路径，不是同一件事的两种写法。**

3. **最危险的差异是 KB-052 的 devfreq governor 静默降级**：`simple_ondemand` 能正常注册、不报错、dmesg 干净，但 GPU 频率策略从"预测式 + 温控联动"退化为"事后式"。这条不会在编译或启动阶段暴露，只在帧率稳定性上体现。

4. **`platform/` 目录里 MTK 内容为零**：r56p0 是纯 ARM 上游，唯一的平台实现参考是 `platform/devicetree/`（400 行）。MTK 的 775 行 `mt6991` 实现 + 约 60 个 `mtk_platform_common` 文件需要自建。

5. **`sleep-mode-enable` 属性决定 runtime PM 是否启用**（KB-055），但该属性未在 mali 节点内找到，其真实位置为 **UNKNOWN**，需在移植前确认。

6. **总判断**：电源域的移植成本**低于** CSF 核心（KB-022/023 那些是路径级重构），但**高于**纯粹的文件搬运——因为 GPUFreq 的符号契约、模块加载顺序、设备树属性三者必须同时成立。
