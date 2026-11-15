# G925 硬件支持核查：r49p1-03bet0 → r56p0-18eac0

> 审计标的：Redmi K80 至尊版（25060RK16C）/ MT6991 / **Immortalis-G925 MC12**
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

## 0. 核心结论（先说结果）

**在"能否驱动 G925"这个层面上，r56p0 不比 r49p1 弱，反而更强。** 三个直接证据：

1. **G925 的产品识别逻辑两版逐行相同** — `nr_cores >= 10 && rt_supported` → `"Mali-G925-Immortalis"`
2. **G925 实际使用的寄存器映射函数 `kbase_regmap_v12_init` 两版逐字节相同**（38 行，7 条赋值，连行号都是 1106）
3. **r56p0 的 GPU_ID 表新增到第 15 代**，说明它面向更新的硬件，向下兼容 G925

但有一个必须注意的脆弱点：**G925 的 arch_id（13.x）在两版的 regmap 分派表中都没有独立条目**，靠"区间匹配"落到 v12。这个机制在两版中**完全相同**，所以不是新增风险，但它是个隐含依赖——一旦 ARM 在后续版本插入 v13 条目，G925 的映射会切换，需要重新验证。

---

## KB-060 — G925 产品识别逻辑两版逐行相同

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-060 |
| **r49p1** | `A/mali_kbase_core_linux.c:3634-3643` |
| **r56p0** | `B/mali_kbase_core_linux.c:2583-2592` |
| **差异类型** | 无变化（仅行号位移） |
| **影响 ABI** | 否 |
| **影响 MTK** | 否 |
| **严重程度** | **P3** |
| **证据等级** | **实证** |

### 两版代码（逐字相同）

```c
const bool rt_supported = gpu_props->gpu_features.ray_intersection;
const u8 nr_cores = gpu_props->num_cores;

if ((nr_cores >= 10) && rt_supported)
	product_name = "Mali-G925-Immortalis";
else
	product_name = (nr_cores >= 6) ? "Mali-G725" : "Mali-G625";
```

### 对 K80U 的判定

| 条件 | K80U 实际 | 结果 |
| --- | --- | --- |
| `product_model == GPU_ID_PRODUCT_TKRX`（13,0） | G925 属 TKRX 族 | ✓ |
| `nr_cores >= 10` | MC12 = 12 核 | ✓ |
| `rt_supported`（`ray_intersection`） | G925 支持光追 | ✓ |
| **结论** | → `"Mali-G925-Immortalis"` | **成立** |

`nr_cores` 来自 `hweight64(shader_present)`（`mali_kbase_gpuprops.c:277` / `:278`），即对 `SHADER_PRESENT` 寄存器做**位计数**。MC12 配置下该寄存器有 12 个 bit 置位。

> **注意**：产品名只影响 `gpuinfo` 的显示字符串与部分日志，**不参与功能分支**。识别成什么名字，不影响驱动能否工作。这一条是"确认"，不是"风险"。

---

## KB-061 — G925 所用的 `kbase_regmap_v12_init` 逐字节相同（决定性证据）

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-061 |
| **r49p1** | `A/hw_access/regmap/mali_kbase_regmap_csf.c:1106-1143` |
| **r56p0** | `B/hw_access/regmap/mali_kbase_regmap_csf.c:1106-1143` |
| **差异类型** | 无变化 |
| **影响 ABI** | 否 |
| **影响 MTK** | 否 |
| **严重程度** | **P3（正面结论）** |
| **证据等级** | **实证**（`diff` 零输出） |

### 为什么这条最关键

`mali_kbase_regmap_csf.c` 从 1,525 行涨到 2,777 行（+1,252），看起来是巨变。但**增量全部是 v14/v15 的新函数**，G925 走的 v12 路径没有被碰。

### 分派机制（两版相同）

```c
/* r49p1:1146-1169 / r56p0:2328-2352 */
struct { u32 arch_id; void (*init)(struct kbase_device *); } init_array[] = {
	{ GPU_ID_ARCH_MAKE(10, 8, 0),  kbase_regmap_v10_8_init },
	{ GPU_ID_ARCH_MAKE(10, 10, 0), kbase_regmap_v10_10_init },
	{ GPU_ID_ARCH_MAKE(11, 0, 0),  kbase_regmap_v11_init },
	{ GPU_ID_ARCH_MAKE(12, 0, 0),  kbase_regmap_v12_init },
	/* r56p0 额外追加： */
	{ GPU_ID_ARCH_MAKE(14, 8, 0),  kbase_regmap_v14_8_init },
	{ GPU_ID_ARCH_MAKE(14, 10, 0), kbase_regmap_v14_10_init },
	{ GPU_ID_ARCH_MAKE(15, 8, 0),  kbase_regmap_v15_8_init },
};

for (i = 0; i < ARRAY_SIZE(init_array) - 1; i++) {
	if (kbdev->gpu_props.gpu_id.arch_id < init_array[i + 1].arch_id) {
		init_array[i].init(kbdev);
		return init_array[i].arch_id;
	}
}
```

匹配规则是**区间匹配**：`arch_id` 严格小于下一个条目就取当前条目。

G925 的 `arch_id` 落在 13.x：

- **r49p1**：13.x 不小于 12.0，循环走完，落到最后一项 `init_array[i]` = **v12_init**
- **r56p0**：13.x **小于 14.8**，在第 5 次比较时命中，取 `init_array[i]` = **v12_init**

→ **两条路径都指向同一个函数**。这是"巧合的兼容"：r56p0 插入的 v14/v15 条目在 14.8 之后，没有切断 13.x 的匹配。

### 逐字节验证

```
$ awk '/static void kbase_regmap_v12_init/,/^}/' <r49p1> > a.txt
$ awk '/static void kbase_regmap_v12_init/,/^}/' <r56p0> > b.txt
$ wc -l a.txt b.txt
  38 a.txt
  38 b.txt
$ diff a.txt b.txt
（无输出）
```

寄存器赋值条数：**两版均 7 条**。

### 隐含依赖（需记录的风险）

G925 在 regmap 表中**没有自己的条目**。当前依赖"区间匹配 + v12 是最后一个 <= 13 的条目"这个巧合成立。

- 若未来 ARM 加入 `{ GPU_ID_ARCH_MAKE(13, 0, 0), kbase_regmap_v13_init }`，G925 会切换到新函数，**必须重新验证全部寄存器偏移**
- 若加入 `{ GPU_ID_ARCH_MAKE(13, 8, 0), ... }` 且 G925 的 arch 是 13.8，匹配结果会变

> **建议**：移植后立即读取 `dmesg | grep regmap` 或加临时打印，确认 `kbase_regmap_backend_init()` 返回的 `arch_id` 为 `GPU_ID_ARCH_MAKE(12, 0, 0)`。这是验证 G925 走对映射路径的唯一实证手段。

---

## KB-062 — GPU_ID 产品表新增第 14、15 代共 6 个产品

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-062 |
| **r49p1** | `include/uapi/gpu/arm/midgard/gpu/mali_kbase_gpu_id.h:155-175`（21 个产品，到 TKRX/LKRX） |
| **r56p0** | `include/uapi/gpu/arm/midgard/gpu/mali_kbase_gpu_id.h:243-269`（27 个产品，到 IMAX/TMAX/LMAX） |
| **差异类型** | 新增 |
| **影响 ABI** | 否（纯宏） |
| **影响 MTK** | 否 |
| **严重程度** | **P3** |
| **证据等级** | **实证** |

### 新增的 6 个

```c
#define GPU_ID_PRODUCT_IDRX GPU_ID_MODEL_MAKE(14, 0)   /* 第 14 代 */
#define GPU_ID_PRODUCT_TDRX GPU_ID_MODEL_MAKE(14, 1)
#define GPU_ID_PRODUCT_LDRX GPU_ID_MODEL_MAKE(14, 3)
#define GPU_ID_PRODUCT_IMAX GPU_ID_MODEL_MAKE(15, 0)   /* 第 15 代，新命名 */
#define GPU_ID_PRODUCT_TMAX GPU_ID_MODEL_MAKE(15, 1)
#define GPU_ID_PRODUCT_LMAX GPU_ID_MODEL_MAKE(15, 3)
```

第 15 代改用了 `IMAX`/`TMAX`/`LMAX` 命名（不再用 `Txxx`/`Lxxx` 的 X 后缀模式），暗示架构代际命名规则调整。

### G925 相关的两个定义未变

```c
#define GPU_ID_PRODUCT_TKRX GPU_ID_MODEL_MAKE(13, 0)   /* 两版相同 */
#define GPU_ID_PRODUCT_LKRX GPU_ID_MODEL_MAKE(13, 1)   /* 两版相同 */
```

TKRX = Immortalis-G925（12 核以上），LKRX = 对应的小核心版本。

---

## KB-063 — `gpu_features` 新增 `neural_accelerator` 与 `ray_traversal`

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-063 |
| **r49p1** | `A/mali_kbase_gpuprops_types.h:147-151`（2 个 bool） |
| **r56p0** | `B/mali_kbase_gpuprops_types.h:148-155`（4 个 bool） |
| **差异类型** | 新增 |
| **影响 ABI** | 是（`gpu_props_user_data` 的 `gpu_features` 位域，见 KB-007 的 568→592） |
| **影响 MTK** | 是 |
| **严重程度** | **P1** |
| **证据等级** | **实证** |

### 结构体对比

**r49p1**（`mali_kbase_gpuprops_types.h:147`）：

```c
struct kbase_gpu_features_props {
	bool ray_intersection;    /* 射线求交指令 */
	bool cross_stream_sync;   /* 跨流同步 */
};
```

**r56p0**（`mali_kbase_gpuprops_types.h:148`）：

```c
struct kbase_gpu_features_props {
	bool ray_intersection;     /* 射线求交指令 */
	bool cross_stream_sync;    /* 跨流同步 */
	bool neural_accelerator;   /* 神经加速器 — 新 */
	bool ray_traversal;        /* 硬件光追遍历 — 新 */
};
```

### 两个新增位的区别

| 位 | 含义 | G925 |
| --- | --- | --- |
| `ray_intersection` | 光追**求交指令**支持（软件光追的基础） | 有（两版都用它识别 G925） |
| `ray_traversal` | 硬件光追**遍历**（BVH 遍历加速单元） | 推测有（**UNKNOWN**，需读硬件寄存器确认） |
| `neural_accelerator` | 神经加速单元（NPU 类单元集成在 GPU 内） | 推测有（**UNKNOWN**） |

### 关键观察：G925 的识别**没有升级到用 `ray_traversal`**

r56p0 有了更精确的 `ray_traversal` 位，但 `mali_kbase_core_linux.c:2586` 的 G925 判定用的仍是旧的 `ray_intersection`。

这是 ARM 的保守做法——产品名映射保持稳定，避免同一颗芯片在不同驱动版本下显示不同名字。**对 K80U 无负面影响**。

### 对 UAPI 的影响

这两个位属于 `gpu_props_user_data.raw_props.gpu_features`（`__u64`），而 `raw_props` 在 r56p0 中从 200 涨到 216 字节（新增 `base_present` / `neural_present` 两个 `__u64`）。

用户态若要读取 `neural_accelerator`，必须能解析 592 字节的新结构体（见 `01_uapi_abi_diff.md` KB-007）。

---

## KB-064 — 新增 `kbase_gpuprops_refine_id_from_features()`：用能力位反推产品 ID

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-064 |
| **r49p1** | 无此函数 |
| **r56p0** | `B/mali_kbase_gpuprops.c:211-245` |
| **差异类型** | 新增 |
| **影响 ABI** | 是（可能改写 `gpu_id.product_major`） |
| **影响 MTK** | 否（对 G925 不生效） |
| **严重程度** | **P3（对 G925）** / **P1（对新架构）** |
| **证据等级** | **实证** |

### 代码

```c
static bool kbase_hw_has_magnihw_2110(struct kbase_device *kbdev)
{
	return (kbdev->gpu_props.gpu_id.arch_id & GPU_ID_ARCH_MAKE(0xFF, 0xFF, 0)) ==
	       GPU_ID_ARCH_MAKE(15, 8, 0);
}

static bool kbase_gpuprops_refine_id_from_features(struct kbase_device *kbdev)
{
	...
	if (!kbase_hw_has_magnihw_2110(kbdev))
		return false;                    /* ← G925 在这里返回 */

	has_rt = gpu_props->gpu_features.ray_traversal;
	has_nx = gpu_props->gpu_features.neural_accelerator;
	nr_cores = gpu_props->num_cores;

	if (nr_cores >= 10 && has_rt && has_nx)
		product_id = 0;
	else if (nr_cores >= 6)
		product_id = 1;
	else
		product_id = 3;

	if (gpu_props->gpu_id.product_major != product_id) {
		dev_info(kbdev->dev, "%s: massaging product_id field, %u -> %u\n",
			 __func__, gpu_props->gpu_id.product_major, product_id);
		gpu_props->gpu_id.product_major = product_id;
		...
	}
}
```

### 对 G925 的影响：**无**

`kbase_hw_has_magnihw_2110()` 要求 `arch_id == 15.8.0`。G925 是 arch 13.x，第一行就 `return false`。

### 这个机制说明了什么

ARM 在新架构（"magnihw 2110" = 15.8）上遇到了**芯片上报的 product_id 不可靠**的问题，需要根据 `ray_traversal` + `neural_accelerator` + 核心数反推真实产品型号。

`dev_info` 的措辞 "massaging product_id field"（揉捏产品 ID 字段）很直白——承认了硬件字段的错误。

→ 对 K80U 无影响，但记录在此：**这说明 r56p0 时代的 GPU ID 寄存器语义开始变得不可信**，未来若移植到更新芯片需注意。

---

## KB-065 — `TNAX` 的定义在两版中不同（疑似修正笔误）

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-065 |
| **r49p1** | `include/uapi/gpu/arm/midgard/gpu/mali_kbase_gpu_id.h:162`：`GPU_ID_PRODUCT_TNAX GPU_ID_MODEL_MAKE(9, 3)` |
| **r56p0** | `include/uapi/gpu/arm/midgard/gpu/mali_kbase_gpu_id.h:250`：`GPU_ID_PRODUCT_TNAX GPU_ID_MODEL_MAKE(9, 1)` |
| **差异类型** | 修改 |
| **影响 ABI** | 否（宏值，只影响识别） |
| **影响 MTK** | 否（TNAX 是 Mali-G57，与 G925 无关） |
| **严重程度** | **P3** |
| **证据等级** | **实证** |

### 完整对照

| 宏 | r49p1 | r56p0 | 是否一致 |
| --- | --- | --- | :--: |
| `TTRX` | (9, 0) | (9, 0) | ✓ |
| **`TNAX`** | **(9, 3)** | **(9, 1)** | **✗** |
| `TBEX` | (9, 2) | (9, 2) | ✓ |
| `LBEX` | (9, 4) | (9, 4) | ✓ |
| `TBAX` | (9, 5) | (9, 5) | ✓ |

### 判断

r49p1 的 (9,3) 与同族其他产品的编号冲突模式不合理：(9,0)(9,2)(9,3)(9,4)(9,5) 里缺 (9,1)，而 TNAX（Mali-G57）历史上应为 (9,1)。

→ **r56p0 的 (9,1) 更可能是正确值，r49p1 的 (9,3) 是笔误**。

**对 K80U 完全无影响**：TNAX 是 Mali-G57（中低端），K80U 用的是 G925（TKRX）。记录此项仅为完整性——它证明两个代码库之间存在**非功能性差异**，提醒审计时不能假设"所有差异都与目标设备相关"。

---

## KB-066 — 核心数与 core mask 计算逻辑未变

| 字段 | 内容 |
| --- | --- |
| **ID** | KB-066 |
| **r49p1** | `A/mali_kbase_gpuprops.c:106, 166, 277, 305` |
| **r56p0** | `B/mali_kbase_gpuprops.c:78, 138, 278, 322` |
| **差异类型** | 无变化 |
| **影响 ABI** | 否 |
| **影响 MTK** | 否 |
| **严重程度** | **P3** |
| **证据等级** | **实证** |

### 四行代码逐条对应（内容相同，仅行号位移）

| 语义 | r49p1 | r56p0 | 代码 |
| --- | ---: | ---: | --- |
| 当前配置核数 | 106 | 78 | `curr_config->num_cores = hweight64(curr_config->shader_present);` |
| coherency 组核数 | 166 | 138 | `gpu_props->coherency_info.group.num_cores = hweight32(gpu_props->max_config.core_mask);` |
| 实际核数 | 277 | 278 | `gpu_props->num_cores = hweight64(regdump->shader_present);` |
| fallback | 305 | 322 | `gpu_props->coherency_info.group.num_cores = gpu_props->num_cores;` |

### MC12 的判定路径

- **主路径**：`hweight64(shader_present)` —— 读 `SHADER_PRESENT` 寄存器，数有多少 bit 置位。MC12 = 12 bit → `num_cores = 12`
- **core_mask 覆盖**：若设备树设了 `core-mask`，走 `max_config.core_mask`（`mali_kbase_gpuprops.c:138/110`）

设备树侧：`mt6991.dts` 的 mali 节点（`:7874`）**未设置 core-mask**（01-C 已逐属性核对），故走主路径，由硬件寄存器决定。

→ `nr_cores = 12 ≥ 10` 成立 → G925 判定成立。

### 核心数与 OPP 的关系

`mt6991.dts` 的 mali 节点含完整 OPP 表（`:7915` 起），最高 `opp-hz = 1508000000`（1,508 MHz）。这 12 档 OPP 对应 12 核配置的电压/频率曲线，由 GPUFreq 管理（非 kbase）。

---

## 1. G925 硬件能力矩阵

| 能力 | 判定依据 | 位置 | r49p1 | r56p0 | 结论 |
| --- | --- | --- | :--: | :--: | --- |
| 产品识别 | `TKRX` + `nr_cores>=10` + `rt_supported` | `core_linux.c` | ✓ | ✓ | **两版相同** |
| MC12 核数 | `hweight64(shader_present)` | `gpuprops.c` | ✓ | ✓ | **两版相同** |
| 寄存器映射 | `v12_init`（arch 13 区间匹配） | `regmap_csf.c:1106` | ✓ | ✓ | **逐字节相同** |
| 光追（求交） | `ray_intersection` | `gpuprops_types.h` | ✓ | ✓ | 两版相同 |
| 光追（遍历） | `ray_traversal` | `gpuprops_types.h` | ✗ | ✓ | **r56p0 新增** |
| 神经加速 | `neural_accelerator` | `gpuprops_types.h` | ✗ | ✓ | **r56p0 新增** |
| base/neural present 位图 | `base_present` / `neural_present` | `mali_gpu_props.h` | ✗ | ✓ | **r56p0 新增** |
| core mask 控制 | `SET_LIMITED_CORE_COUNT` ioctl | UAPI 55 号 | ✓ | ✗ | **r56p0 删除**（见 KB-010） |
| SLC 缓存提示 | `pbha_id` (MGM PTE) | `memory_group_manager.h` | ✗ | ✓ | **r56p0 新增**（见 KB-040） |

---

## 2. 三个"新增能力"对 G925 的实际意义

| 新能力 | 是否 G925 硬件具备 | 证据 |
| --- | :--: | --- |
| `ray_traversal` | **UNKNOWN** | 需读 `GPU_FEATURES` 寄存器 bit，静态源码无法判定 |
| `neural_accelerator` | **UNKNOWN** | 同上 |
| `pbha_id`（SLC 分区） | **UNKNOWN** | 需确认 G925 是否支持 PBHA 编码 |

这三项无法从源码判定，必须实测。但它们**不影响基础功能**——即使 G925 不具备，驱动也只是少用一项优化，不会失败。

> **不应把"r56p0 支持这些能力"误读为"G925 具备这些能力"**。源码只证明驱动能处理，不证明硬件有。

---

## 3. 本文件的结论

1. **G925 的驱动能力在两版中都成立，且 r56p0 不弱于 r49p1。** 三条硬证据：识别逻辑逐行相同、`v12_init` 逐字节相同、支持到第 15 代架构。

2. **`kbase_regmap_v12_init` 逐字节相同是本轮最有价值的单条证据。** 它把"寄存器表膨胀 1,252 行"这个吓人的数字，还原成"增量全在 v14/v15，G925 路径未动"。

3. **G925 在 regmap 表中没有自己的条目，靠区间匹配落到 v12。** 两版机制相同，所以不是新增风险，但是个隐含依赖——必须在移植后用 `kbase_regmap_backend_init()` 的返回值确认。

4. **r56p0 新增三项 G925 可能受益的能力**（`ray_traversal`、`neural_accelerator`、`pbha_id`），但**是否真能用取决于硬件**，静态分析无法确认，标 UNKNOWN。

5. **`SET_LIMITED_CORE_COUNT` 被删（KB-010）是 G925 唯一的功能性减项。** MC12 是 12 核，用户态若通过该 ioctl 做核心裁剪省电，r56p0 上会失效。这条与 `04_pm_interface_diff.md` 的 governor 降级叠加，会放大功耗问题。

6. **一处非功能性差异（TNAX 定义）提醒审计纪律**：不能用"两个版本有 N 处差异"作为风险评估，很多差异与目标设备无关。
