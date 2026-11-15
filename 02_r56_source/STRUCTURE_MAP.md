# R56p0 源码结构测绘

> 本文件只记录**可复核的客观事实**及其直接推论。凡属推断的内容均标注 `[推断]`，凡属未验证的均标注 `[待验证]`。
> 本阶段不产出可行性结论 —— 那属于 `06_porting_design` 与 `final_report` 的职责。
>
> 测绘对象：`02_r56_source/mali_r56p0/`（Arm 官方原包解包，未做任何改动）
> 测绘日期：2026-11-15

---

## 1. 交付物标识

| 项 | 值 |
| --- | --- |
| 包名 | `AX504X08X-SW-99002-r56p0-18eac0.tar.gz` |
| 大小 | 1,147,252 字节 |
| MD5 | `62b168823691eb61ec29654cbf35e719` |
| SHA256 | `1f7ad4d058bb993a95714d7823f279df9097ae45efe622970a53373217fa92f4` |
| 源码树 SHA256 | `a3158608ef6c55ef932b305384a927411d4887bb0339b39b68a14af11b13f292` |
| 校验结论 | **与 Arm CDN 清单登记值逐字节一致**（清单见 `_arm_listing/arm_5thgen_package_listing_20261115.json`） |
| 采集方式 | 用户从 `developer.arm.com` 登录并接受 EULA 后下载，上传至会话 |
| 是否改动 | **否**。原样 `tar xzf`，无 patch、无格式转换、无删减 |

包内条目 454 个，解包后 454 个文件，无符号链接逃逸、无额外文件。

```
条目数(tar) = 454     文件数(find) = 454     一致性: ✓
```

---

## 2. 交付树形态

Arm 的 DDK 交付采用固定的四层前缀，**不是**内核树内路径：

```
mali_r56p0/
└── driver/product/kernel/          ← 固定前缀，对应内核树的 drivers/ 挂载点
    ├── Documentation/                  ← DT binding 与 ABI 文档（10 个）
    │   ├── devicetree/bindings/arm/    ← 含 arm,mali-midgard.yaml ★
    │   ├── devicetree/bindings/power/  ← arm,mali-operating-points.yaml ★
    │   ├── ABI/testing/                ← sysfs 稳定接口声明
    │   └── csf_sync_state_dump.rst
    ├── include/uapi/gpu/arm/midgard/   ← 用户态可见 ABI 头（18 个）
    ├── drivers/gpu/arm/midgard/        ← 内核驱动主体
    └── drivers/hwtracing/coresight/mali/ ← Coresight 集成（3 文件）
```

`Documentation/devicetree/bindings/` 是本包中对 `04_mtk_platform` 最有价值的副产品 ——
它是 Arm 对 DT 节点的**权威 schema**，MTK 的 out-of-tree 节点必须满足它：

```
arm,mali-midgard.yaml              主 compatible 与必需属性
arm,mali-operating-points.yaml     OPP 表结构（MTK GPUFREQ 的对接基础）
arm,protected-memory-allocator.yaml
arm,priority-control-manager.yaml
arm,physical-memory-group-manager.yaml
arm,coresight-mali-source.yaml
```

挂载到内核树时，`driver/product/kernel/` 的内容被铺到内核根下。
基线 r49 的构建路径 `vendor/mediatek/kernel_modules/gpu/mt6991/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/`
说明 MTK 是把 **`drivers/gpu/arm/midgard/` 这一层**单独摘出来内嵌的，而非整包铺开。`[推断]` 移植时需复现同样的摘取方式。

### 2.1 内核驱动主体目录

```
drivers/gpu/arm/midgard/
├── backend/            36 files  15,013 lines   GPU 后端（电源/时钟/DVFS/gpuprops）
│   └── gpu/
├── context/             4 files     813 lines   上下文管理（仅 CSF 变体）
│   └── backend/
├── csf/                67 files  44,534 lines   ★ 命令流前端（最大子系统）
│   └── ipa_control/
├── debug/              13 files   3,501 lines
├── device/              6 files   2,117 lines   设备抽象层（仅 CSF 变体）
│   └── backend/
├── gpu/                 3 files     292 lines
├── hw_access/          10 files   6,132 lines
│   └── regmap/                                    ← regmap_csf.c 达 168 KB
├── hwcnt/              19 files  10,872 lines   硬件计数器
├── ipa/                 9 files   2,888 lines   实时性能控制
├── mmu/                13 files   8,195 lines
├── platform/           13 files   1,136 lines   平台适配（devicetree/meson/vexpress）
├── tests/              18 files   5,311 lines   KUTF 单元测试
├── thirdparty/          2 files     558 lines   仅 mm.h + mmap.c（GPL 边界）
├── tl/                 10 files  10,324 lines   Tracepoint/时间线
└── <顶层散文件>        105 files  41,453 lines   kbase 核心
```

**总量：156 个 `.c` + 207 个 `.h`，161,943 行 C/H 代码，5.58 MB。**
不含二进制、不含预编译产物、不含固件 blob。

### 2.2 单文件体量 TOP 5

| 文件 | 大小 | 说明 |
| --- | --- | --- |
| `csf/mali_kbase_csf_scheduler.c` | 300.7 KB | CSF 调度器，全局最大 |
| `hw_access/regmap/mali_kbase_regmap_csf.c` | 168.8 KB | 寄存器映射表 |
| `mmu/mali_kbase_mmu.c` | 150.2 KB | MMU |
| `mali_kbase_core_linux.c` | 146.1 KB | ioctl 入口、版本协商、GPU 识别 |
| `mali_kbase_mem.c` | 135.3 KB | 内存管理 |

---

## 3. 版本与 ABI

| 标识 | 取值 | 出处 |
| --- | --- | --- |
| DDK 发布名 | **`r56p0-18eac0`** | `Kbuild:75` `MALI_RELEASE_NAME ?= '"r56p0-18eac0"'` |
| 内核侧版本串 | `K:r56p0-18eac0(GPL)` | `mali_kbase_core_linux.c:113` |
| UK ABI major | **1** | `include/uapi/.../csf/mali_kbase_csf_ioctl.h:148` |
| UK ABI minor | **39** | 同上 `:149` |
| 模块版本串 | `r56p0-18eac0 (UK version 1.39)` | `MODULE_VERSION()` @ `core_linux.c:5009` |

### 3.1 与基线的版本跨度

| 维度 | 基线（出厂） | R56p0 | 跨度 |
| --- | --- | --- | --- |
| DDK | `r49p1-03bet0` | `r56p0-18eac0` | **7 个主版本** |
| UK ABI | 1.30 | 1.39 | **9 个 minor** |
| 后端架构 | Valhall-C（`arm,mali-valhallC*`） | 仅 CSF | 同为 CSF |
| 内核基线 | `6.6.118-android15-8` | 交付不带 vermagic | 需自家内核重建 |

基线 DDK / UK 值来源：`mali_kbase_mt6991_r49.ko` 的 `.modinfo` 段 `version=r49p1-03bet0 (UK version 1.30)`。

### 3.2 UK 1.30 → 1.39 变更（决定用户态 blobs 能否复用）

摘自 `mali_kbase_csf_ioctl.h` 的官方变更日志，仅列涉及 ABI 语义者：

| UK | 变更 | 性质 |
| --- | --- | --- |
| 1.31 | 拒绝带 `BASE_MEM_PROTECTED` / `BASE_MEM_DONT_NEED` / `BASE_MEM_UNUSED_BIT` 的非受保护分配 | 校验收紧，老 blobs 可能被拒 |
| 1.33 | 增大 `KBASE_MEM_PROFILE_MAX_BUF_SIZE` | 缓冲区尺寸变化 |
| 1.35 | CS_USER IO 分配从 **CS binding 移至 CSG creation** | **行为时序变更** |
| 1.36 | `QUEUE_GROUP_CREATE` 增加 reserved 字段；旧版保留为 `_1_35` 变体 | **结构变更 + 双版本并存** |
| 1.37 | 默认启用 TIMESTAMP broadcast | 默认行为变更 |
| 1.38 | CSG 配置增加 `fragment_endpoint_task_limit` | 结构扩展 |
| 1.39 | **移除** `KBASE_IOCTL_SET_LIMITED_CORE_COUNT`、`KBASE_IOCTL_DISJOINT_QUERY` | **ABI 破坏** |

协商机制（`kbase_api_handshake()` @ `core_linux.c:357`）：

```c
case BASE_UK_VERSION_MAJOR:
    version->minor = min_t(int, BASE_UK_VERSION_MINOR, (int)version->minor);
```

major 相同即取 minor 的**较小值**。故 UK 1.30 的用户态与 UK 1.39 内核**可以在 1.30 语义下协商通过**。

`[待验证]` 三点必须实测，不能凭此代码下结论：

1. 内核内部对 1.35 / 1.36 的行为差异是否有 `kfile->api_version` 条件分支，还是无条件走新路径（若是后者，min_t 只改数字、不改行为）。
2. 现网 blobs 是否真的调用被 1.39 移除的两个 ioctl —— 调用即 `ENOTTY`。
3. Mali **用户态** DDK 自身通常另做精确版本校验，可能在内核放行后仍拒绝启动。

---

## 4. 架构路径：CSF-only

这是本次测绘中**对移植影响最大**的一条事实。

```
device/backend/   只有:  mali_kbase_device_csf.c
                         mali_kbase_device_hw_csf.c
context/backend/  只有:  mali_kbase_context_csf.c
全树 JM 相关文件:  无（find -name '*jm*' 空结果）
```

`device/Kbuild` 的编译单元写死为 CSF 两个文件，无 `ifeq` 分支。

结合 `Kbuild:207`：

```make
ifeq ($(CONFIG_MALI_CSF_SUPPORT),y)
    INCLUDE_SUBDIR += $(src)/csf/Kbuild
endif
```

`CONFIG_MALI_CSF_SUPPORT` 只控制是否编入 `csf/` 子目录，**不控制是否存在 JM 后端** —— 因为 JM 后端代码本身已不在交付中。

`[推断]` R56p0 是面向 5th Gen（CSF 原生架构）的收敛分支，Job Manager 路径已彻底移除。对 G925 无影响（G925 本身即 CSF 架构），但意味着该 DDK **不可能**回退到支持老 Valhall JM 机型。

---

## 5. G925 支持证据

`mali_kbase_core_linux.c:2576-2592`：

```c
if (product_model == GPU_ID_PRODUCT_TKRX) {
    const bool rt_supported = gpu_props->gpu_features.ray_intersection;
    const u8 nr_cores = gpu_props->num_cores;

    if ((nr_cores >= 10) && rt_supported)
        product_name = "Mali-G925-Immortalis";
    else
        product_name = (nr_cores >= 6) ? "Mali-G725" : "Mali-G625";
```

K80 至尊版规格为 Immortalis-G925 **MC12**：`nr_cores = 12 ≥ 10`，且 5th Gen Immortalis 具备 ray intersection → 落在第一分支，产品名正确解析为 `Mali-G925-Immortalis`。

**结论（事实层）：R56p0 具备对 G925 的型号级识别能力，不是"借用他型号代码"。**
`[待验证]` 识别 ≠ 适配：具体 SKU 的时钟/电源/OPP/固件配置仍需 MTK 侧补充，见 §7。

---

## 6. 平台适配层现状

`platform/` 目录内容：

```
platform/
├── devicetree/              ← 唯一可用于 MTK 的路径
├── meson/                   ← Amlogic，无关
├── vexpress/                ← Arm 自家 FPGA 参考板，无关
├── vexpress_1xv7_a57/       ← 无关
├── vexpress_6xvirtex7_10mhz/ ← 无关
├── Kconfig                  ← 仅声明扩展点
└── ...
```

**没有任何 `platform/mt6991/` 或 MediaTek 相关目录。**

`platform/Kconfig` 原文只留了一个扩展点注释：

```
# Add your platform specific Kconfig file here
# "$(MALI_KCONFIG_EXT_PREFIX)drivers/gpu/arm/midgard/platform/xxx/Kconfig"
```

`[推断]` MTK 的 GPUFREQ / GPU QoS / 电源域 / EB / GED 等适配，全部是 **out-of-tree 的 MTK 私有补丁**，Arm 原包不提供。这与基线 `.ko` 中出现的 `mtk_gpufreq_mt6991.ko`、`mtk_gpu_qos.ko`、`mtk_gpueb.ko`、`ged.ko` 等 12 个平台模块相互印证。

这部分差异将在 `04_mtk_platform` 中逐条比对，是本次审计的工作量重心。

---

## 7. 重要文件清单

按审计用途分组，均为 R56p0 原树内路径（相对 `drivers/gpu/arm/midgard/`）。

### 7.1 版本 / ABI 接口面

| 文件 | 用途 |
| --- | --- |
| `Kbuild` | `MALI_RELEASE_NAME`、编译单元、ccflags |
| `Kconfig` | 编译开关 |
| `../include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_ioctl.h` | **UK 1.39 权威定义 + 完整变更日志** |
| `../include/uapi/gpu/arm/midgard/mali_base_kernel.h` | 用户态基础 ABI |
| `../include/uapi/gpu/arm/midgard/mali_kbase_ioctl.h` | ioctl 编号表 |
| `mali_kbase_core_linux.c` | 版本协商、GPU 识别、ioctl 分发 |

### 7.2 CSF 核心（工作量重心）

| 文件 | 大小 | 用途 |
| --- | --- | --- |
| `csf/mali_kbase_csf_scheduler.c` | 300.7 KB | CSG/CS 调度 |
| `csf/mali_kbase_csf.c` | 135.0 KB | 前端主体 |
| `csf/mali_kbase_csf_firmware.c` | 120.1 KB | **固件加载（与 blob 强相关）** |
| `csf/mali_kbase_csf_firmware_cfg.c` | — | 固件配置项解析 |
| `csf/mali_kbase_csf_csg.c` | — | 队列组 |
| `csf/mali_kbase_csf_tiler_heap.c` | — | tiler 堆（UK 1.34 新增 ioctl） |
| `csf/mali_kbase_csf_kcpu.c` | — | KCPU 队列 |
| `csf/ipa_control/mali_kbase_csf_ipa_control.c` | — | IPA 控制环 |

### 7.3 后端与硬件层

| 文件 | 用途 |
| --- | --- |
| `backend/gpu/mali_kbase_pm_driver.c` (132.9 KB) | 电源管理驱动 |
| `backend/gpu/mali_kbase_devfreq.c` | DVFS 接口（**MTK GPUFREQ 的对接点**） |
| `hw_access/regmap/mali_kbase_regmap_csf.c` (168.8 KB) | 寄存器映射 |
| `device/backend/mali_kbase_device_csf.c` | 设备抽象（CSF） |
| `mmu/mali_kbase_mmu.c` (150.2 KB) | MMU |
| `mali_kbase_gpuprops.c` | GPU 属性采集（含 core 数、特性位） |

### 7.4 平台与集成

| 文件 | 用途 |
| --- | --- |
| `platform/devicetree/mali_kbase_config_platform.h` | DT 平台配置模板（MTK 需改造对象） |
| `thirdparty/mm.h` / `mali_kbase_mmap.c` | GPL 边界封装 |
| `../drivers/hwtracing/coresight/mali/` | Coresight trace 集成 |

---

## 8. 未收录 / 不属本包

以下内容**不在** Arm 内核驱动交付内，须另行获取，否则 `05` / `06` 无法闭环：

| 缺失项 | 归属目录 | 说明 |
| --- | --- | --- |
| CSF 固件 blob（`mali_csffw.bin`） | `05_userspace_firmware` | 与固件版本强绑定，必须与 DDK 匹配 |
| 用户态 Mali DDK（`libmali.so` / gralloc / EGL） | `05_userspace_firmware` | UK 1.39 对应版本 |
| MTK 私有 GPU 补丁 | `04_mtk_platform` | 原包完全没有 |
| MT6991 GPU 设备树节点 | `04_mtk_platform` | 需从 `dtb/mt6991.dtb` 反编译提取 |
| 内核基线源码 | `01_original_baseline` | 当前参考仓库只提供 `Image.lz4` + `.ko`，无源码 |

---

## 9. 本阶段未做的事

明确记录边界，避免后续误读：

- **未修改任何源码**（只读解包，`git status` 中 R56p0 全部为新增未改动文件）
- **未编译**（未执行 `make`、未调用交叉编译器、未生成任何 `.o` / `.ko`）
- **未合并**任何基线代码与 R56p0 代码
- **未接触设备**（无 adb、无 fastboot、无刷写）
- **未下可行性结论**

---

## 10. 下一阶段入口

按依赖顺序，`03_kbase_csf` 现在具备开工条件（源码已在手）：

1. **ABI 面比对**：基线 `mali_kbase_mt6991_r49.ko` 的 uapi 头 vs R56p0 的 18 个 uapi 头，逐结构体/ioctl 做差异表。
2. **CSF 子系统差异**：r49p1 的 `csf/` 与 R56p0 的 `csf/` 结构对照（r49p1 源码未获取，需先从 `.ko` 的调试符号或另行取得源码）。
3. **MTK 补丁定位**：从 `dtb/mt6991.dtb` 反编译出 GPU 节点，倒推 out-of-tree 补丁需要挂接的位置。
4. **固件 / blobs 版本矩阵**：确认 K80U 现网 `mali_csffw.bin` 版本与 R56p0 要求的固件 ABI。

其中第 2 项的阻塞点是明确的：**r49p1 的源码尚未取得**，只有二进制。这会限制差异分析的精度，需在开工前决定是补取 r49p1 源码，还是接受"二进制侧推断 + 符号级比对"的精度损失。
