# 07 — 真机证据登记（Stage 4 补充核验）

> **本文件的定位**：Stage 4 首轮（`efd8547`）的六份报告建立在"仓库内零用户态实体"的前提上，因此大量结论止步于**源码契约层**。本文件登记 2026-11-15 20:56 收到的三份真机采集结果，把"契约层"与"实体层"接上，并**逐条标出哪些原结论被证实、哪些被推翻、哪些仍不成立**。
>
> **证据分级**（本阶段统一口径）：
>
> | 级别 | 含义 | 可反驳性 |
> | --- | --- | --- |
> | **[D]** | **真机实测**：采集输出中可直接读到的值（路径、大小、哈希、ELF 动态段、getprop、`lsmod`） | 不可反驳，只能被"采集脚本写错"推翻 |
> | **[E1]** | 源码 / 二进制直接证据：仓库内文件的行号级内容 | 可被版本误认推翻 |
> | **[E2]** | 交叉推导：由两条以上 [D]/[E1] 推出，中间有一步推理 | 可被新证据推翻 |
> | **[E3]** | 惯例推断：基于 AOSP/Android 通用实现 | 最弱，仅作方向 |
> | **[U]** | UNKNOWN：无证据，或证据不足以定值 | — |
>
> **三态标注法**（贯穿全部七份文件）：每条结论必须落在这三档之一——
> `已实测`（[D]）/ `静态分析`（[E1]/[E2]）/ `尚未验证`（[E3]/[U]）。
> 禁止把"静态分析"写成"已实测"，也禁止把"报告已提交"写成"证据已闭环"。

---

## 0. 本次补充核验做了什么、不做什么

| 项 | 内容 |
| --- | --- |
| 做 | 解析三份真机采集输出；把可公开元数据（路径/大小/SHA256/Build ID/动态段/服务状态）整合进 `01`–`06`；复核首轮的五处过度推断；修正根 `README.md` |
| 不做 | 不重新执行 Stage 4；不开始 Stage 5；不编译；不替换任何固件或系统库；不上传任何 `.so` / `.bin` / `.ko` 实体；不要求用户重跑已有采集项目 |
| 唯一例外 | 若存在**可被 8 字节读数直接闭合**的 P0 缺口，提出最小只读命令并等待用户确认（见 §10） |

---

## 1. 输入三件套登记

| 文件 | 字节 | 行数 | SHA256（本次收到的副本） | 采集时间（文件内） |
| --- | ---: | ---: | --- | --- |
| `stage4_inventory.txt` | 85,684 | 1,732 | `d897ed47…1729a6` | `Sun Nov 15 19:54:06 CST 2026` |
| `stage4_file_metadata.txt` | 6,055 | 120 | `c8a856b5…e5f59dc` | 与上同批 |
| `stage4_elf_analysis.txt` | 79,123 | 1,244 | `9f95078f…8b3b3e33` | `Sun Nov 15 20:02:40 CST 2026` |

> 三份文件**均在设备侧生成**（`OUTPUT: /sdcard/GPU_AUDIT_STAGE4/…`），经本地副本转交，**未进入本仓库**。本仓库只登记其**哈希与解析结论**，不登记其正文。

### 1.1 三份文件各自的能力边界

| 文件 | 能回答 | 不能回答 |
| --- | --- | --- |
| `inventory` | 系统版本、模块清单、目录枚举、VINTF 清单名、DT 节点、getprop、`/dev` 节点 | 任何文件内容；任何字节级取值 |
| `file_metadata` | 22 个关键对象的**大小 / 权限 / SHA256** | 文件内部结构 |
| `elf_analysis` | 9 个 ELF 的**头 / 动态段 / Build ID / 部分符号**；固件的**可打印字符串** | 固件头字节（offset 0–19）；完整符号表；`.text` 反汇编 |

**关键限制（影响本阶段最重的一条结论）**：`strings` 输出的是可打印字符串，**不含二进制头字段**。固件的 `version_minor`/`version_major` 位于 offset 4 / 5，是原始字节，**不可能出现在任何一份 `strings` 结果里**。这一点直接决定了 §4 的结论。

---

## 2. 设备基线（[D] 实测）

| 项 | 实测值 | 来源 |
| --- | --- | --- |
| 机型代码 | `25060RK16C` | 采集 §1 第 1 行 |
| 代号 | `dali` | 采集 §1 第 2 行 |
| SoC | `mt6991`（第 3、4 行同值，对应 platform 与 hardware 两个字段） | 采集 §1 第 3–4 行 |
| **Android 版本** | **17** | 采集 §1 第 5 行 |
| **SDK** | **37** | 采集 §1 第 6 行 |
| 构建指纹 | `Redmi/dali/dali:17/CP2A.260605.016/OS4.0.3.0.XONCNXM:user/release-keys` | 采集 §1 第 7 行 |
| 系统版本名 | HyperOS `OS4.0.3.0.XONCNXM` | 同上 |
| 内核 | `6.6.143-android15-8-gf9aa2fec23c3-4k`，`#1 SMP PREEMPT Mon Oct 5 04:20:00 UTC 2026 aarch64` | `uname -a` |
| GPU 节点 | `/soc/mali@48000000`，`compatible = mediatek,mali` + `arm,mali-valhall` | `uevent` |
| 设备节点 | `/dev/mali0`，`crw-rw-rw- system graphics 10:282` | `ls -l /dev` |

> 说明：`inventory` 的 §1 只打印取值、不打印键名。上表的键名是按 Android 标准属性顺序对应，取值本身是原文照录；若需键名级确认，`getprop` 的完整输出可直接复核。
>
> **三处必须纠正的旧表述**：
> 1. 根 `README.md` 的 **"Android 16"已过时**——真机为 **Android 17 / SDK 37**。
> 2. 内核串里的 `android15` 是 **GKI 分支名**（`android15-8`），**不是** Android 版本；`6.6.143` 才是内核版本。旧文写作"Linux 6.6（GKI 形态）"方向正确但不够精确。
> 3. `compatible` 为 `arm,mali-valhall`（Valhall 家族字符串），与 Immortalis-G925 属同一 `regmap` 世代，和 `03_kbase_csf/05` 的 `kbase_regmap_v12_init` 判定一致 **[E2]**。

---

## 3. 内核侧实测：模块与版本（[D]）

### 3.1 版本串——首轮最重要的补强

```
/sys/module/mali_kbase_mt6991_r49/version  →  r49p1-03bet0 (UK version 1.30)
```

源码依据（r49p1）：

```c
/* mali_kbase_core_linux.c:6800 */
MODULE_VERSION(MALI_RELEASE_NAME " (UK version " __stringify(BASE_UK_VERSION_MAJOR) "."
               __stringify(BASE_UK_VERSION_MINOR) ")");
```

| 判定 | 内容 | 等级 |
| --- | --- | --- |
| 运行中的 kbase 版本 | `r49p1-03bet0` | **[D]** |
| 运行中的 kbase UK ABI | **1.30（major 1 / minor 30）** | **[D]** |
| 与仓库基线一致性 | 与 `01_original_baseline` 的 `MALI_RELEASE_NAME` 逐字符一致 | **[D]**+[E1] |

> 这是 Stage 4 首轮**拿不到、只能推测**的东西：首轮说"原厂 DDK 必然宣称 1.30"是源码推理 **[E1]**，而现在有设备侧字符串直接确认**内核**就是 1.30。注意区分：这确认的是**内核宣称值**，**不是 DDK 宣称值**（U4-04 仍开放，见 §5.3）。

### 3.2 MTK 平台层模块：15 个 `.ko` 的实际装载情况

`01_original_baseline/kernel_ref_mt6991/vendor_dlkm/` 共 15 个 `.ko`，真机 `lsmod` 对照：

| 模块 | 真机状态 | 备注 |
| --- | :---: | --- |
| `mali_kbase_mt6991_r49` | ✅ 已装载 | refcount 77 |
| `mali_mgm_mt6991_r49` | ✅ | |
| `mali_prot_alloc_mt6991_r49` | ✅ | PMA |
| `ged` | ✅ | 684,032 B，被 5 个模块引用 |
| `mtk_gpufreq_mt6991` | ✅ | |
| `mtk_gpufreq_wrapper` | ✅ | 被 9 个模块引用（含 kbase） |
| `mtk_gpueb` | ✅ | 被 10 个模块引用（含 kbase） |
| `mtk_gpu_hal` | ✅ | 被 8 个模块引用（含 kbase） |
| `mtk_gpu_pdma_mt6991` | ✅ | 被 1 个模块引用（kbase） |
| `mtk_gpu_qos` | ✅ | 被 1 个模块引用（ged） |
| `mtk_gpu_iommu_mt6991` | ✅ | refcount 0 |
| `mtk_gpu_power_throttling` | ✅ | refcount 0 |
| `met_gpu_api` | ❌ **未装载** | MET 追踪，本机未启用 |
| `met_gpu_adv_api` | ❌ **未装载** | 同上 |
| `met_gpueb_api` | ❌ **未装载** | 同上 |

**新增结论（TASK 03 未能观察到）**：三个 `met_*` 模块**在本机根本不装载**。因此 `04_mtk_platform/06_platform_retention_matrix.md` 中与 MET 相关的适配项，在本机型上**不构成风险面**；反之，任何"必须同步升级 MET"的担心可以撤回 **[D]**。

### 3.3 引用方向：设备侧交叉印证 TASK 03 的"89 处正向引用"

`lsmod` 的 used-by 列显示 `mali_kbase_mt6991_r49` 出现在以下模块的依赖列表中：`ged`、`mtk_gpufreq_wrapper`、`mtk_gpueb`、`mtk_gpu_hal`、`mtk_gpu_pdma_mt6991`。

> 这与 TASK 03 用 `__versions`/`.rela` 推出的 **kbase → MTK 正向引用 89 处（ged 53 / gpufreq_wrapper 16 / gpu_hal 13 / gpueb 6 / pdma 1）** 在**模块集合层面**完全吻合 **[D]**+[E1]。
>
> 注意：`lsmod` 只能证明"谁引用谁"这一层，**不能**给出符号粒度，也不能反驳"MTK 对 kbase 零反向依赖"定理（该定理的依据是 `__ksymtab` 与 `UND` 符号，仍以 `04_mtk_platform/01` 为准）。

---

## 4. CSF 固件实体：拿到大小与哈希，**仍然拿不到 header 字节**

### 4.1 实测元数据（[D]）

| 项 | 值 |
| --- | --- |
| 路径 | `/vendor/firmware/mali_csffw.bin` |
| 大小 | **307,200 B**（= 300 KiB 整） |
| 权限 | `-rw-r--r-- root:root 644` |
| SHA256 | `334fb67648f2ec43f57b24a8972e97b7d54919783d398a88327d7c136fa7de4a` |
| 唯一性 | `/vendor/firmware/` 下**仅此一个** `mali_csffw*`；`/vendor/firmware_mnt`、`/vendor/etc/firmware` **不存在** |

### 4.2 为什么"大小 + 哈希"不能推出 header 版本

| 假想判据 | 为什么无效 |
| --- | --- |
| 按大小推断（300 KiB 整） | 加载器只读到 `entry_end_offset`（offset 0x10），**尾部填充不参与解析**。整 KiB 对齐是打包惯例，与版本无关 **[E2]** |
| 按哈希比对 Arm 发布包 | R56p0 的 `mali_csffw.bin` **未随内核源码包交付**，仓库内无对照哈希 **[D]** |
| 按 strings 推断 | `strings` 只输出可打印字节；`version_minor` 是 offset 4 的**单字节 0x03/0x04**，非可打印串，**不可能出现** **[E1]** |

### 4.3 strings 提供了什么（有价值，但不是版本）

固件内可打印串含完整 CSF 时间线枚举与启动状态机：

```
CSFFW_TL_ITER_vb421b363699b1165c0a40c789b8a54f822bece74     ← 唯一构建标识（v + 40 hex）
CSFFW_TL_FW_NORMAL_MODE / _PROTECTED_MODE / _SLEEPING
CSFFW_CSI_STOPPED / _SUSPENDING / _BLOCKED_PROTM_PEND / _FAULT
CSFFW_TL_CSG_ENABLED / _DISABLED / _PROTM_SUSPENDING
BOOT WARM / BOOT WARM AFTER PMODE
MCU_GPU_IRQ_MASK / GPU_FEATURES_LO / MCU_GPU_FAULTADDRESS_LO
Firmware hang detected at PC 0x%08x        （"CSFFW Oops!" 路径）
```

| 可读出 | 不可读出 |
| --- | --- |
| 固件是**完整的 CSF 调度器**（含 CSG/CS/ITER 状态机、保护模式、warm boot、hang 检测） | header 版本（0.3 / 0.4） |
| 存在**构建标识** `b421b363…`，可作未来比对锚点 | GLB 接口运行时版本（需运行后读共享内存） |
| 具备 `PROTECTED_MODE`，与 DRM/SVP 路径的存在性自洽 | core mask / 是否匹配 G925 MC12（U4-12） |

> 该构建标识 `vb421b363…` 是本次唯一新增的**可追踪锚点**：若日后取得 Arm R56p0 固件，可直接比对它是同一分支的不同 commit，还是完全不同的代码线。

### 4.4 结论：U4-01 **保持 UNKNOWN**

- **字节未实测** → 不得宣称"已通过真机固件字节确认 0.3"。
- 但存在一条**强度很高、性质不同**的推理，见 `02_csf_firmware_abi.md` §3.0（"启动一致性"论证）。该推理**不改变 U4-01 的状态**，只把"0.3"从"实测结论"降级为"E2 级推理"。
- 是否值得补采：见 §10。

---

## 5. 用户态实体清单（[D] 实测）

### 5.1 图形相关对象全表

| 对象 | 路径 | 字节 | SHA256（前 8） | 判定要点 |
| --- | --- | ---: | --- | --- |
| GLES 驱动 | `/vendor/lib64/egl/mt6991/libGLES_mali.so` | **53,105,232** | `d84ae538` | SONAME `libGLES_mali.so`；Build ID `700e6d4112a6a8a5`；note **API level 35**；`FLAGS: SYMBOLIC BIND_NOW` |
| Vulkan 厂商模块 | `/vendor/lib64/hw/mt6991/vulkan.mali.so` | **133,416** | `336acc0f` | SONAME `vulkan.mali.so`；**仅导出 1 个符号 `mali_vk_vendor_stub`**；NEEDED **`libGLES_mali.so`** |
| mapper HAL | `/vendor/lib64/hw/mt6991/mapper.mediatek.so` | 187,640 | `eaa9b03c` | SONAME `mapper.mediatek.so`；导出 `GrallocMapperV5*` + `arm::mapper::common::*` + `ANDROID_HAL_MAPPER_VERSION` |
| HWC | `/vendor/lib64/hw/hwcomposer.mtk_common.so` | 2,086,232 | `1b911b83` | SONAME `hwcomposer.mtk_common.so`；**NEEDED 中无任何 Mali 库** |
| gralloc（default） | `/vendor/lib64/hw/gralloc.default.so` | 52,344 | `c2588383` | 仅 NEEDED `liblog/libcutils/libc++/libc/libm/libdl`——**无分配后端**，是 passthrough 占位 |
| Mali 平台 HAL | `/vendor/lib64/mt6991/arm.mali.platform-V2-ndk.so` | 85,344 | `74c7d175` | AIDL `arm.mali.platform`（压缩率/EGL 格式协商） |
| EGL 属性注入 | `/vendor/lib64/mt6991/libarm_egl_properties_sysprop.so` | 35,704 | `f30bc153` | 对应 `ro.vendor.arm.egl.configs.*` 一整族属性 |
| gralloc 属性注入 | `/vendor/lib64/mt6991/libarm_gralloc_properties_sysprop.so` | 35,672 | `325567a1` | 对应 `ro.vendor.arm.gralloc.*` |
| Mali 配置属性 | `/vendor/lib64/mt6991/libarm_mali_config_sysprops.so` | 52,056 | `f6d92135` | |
| GPU 数据面 | `/vendor/lib64/libgpud.so` | 395,856 | `de46f6ee` | MTK 性能/抓帧数据生产者的 vendor 副本 |
| GPU 数据面（system） | `/system_ext/lib64/libgpud_sys.so` | 未采集 | — | 被 `/system/lib64/libvulkan.so` NEEDED |
| GPU 辅助 | `/vendor/lib64/libgpu_aux.so` | 151,760 | `a03447df` | |
| 系统 EGL | `/system/lib64/libEGL.so` | 287,664 | `bca71cbf` | note **API level 37**；NEEDED 含 `libnativebridge_lazy`/`libnativeloader_lazy`/`libvndksupport` |
| 系统 GLESv2 | `/system/lib64/libGLESv2.so` | 117,312 | `cac82021` | API 37；NEEDED `libEGL.so` |
| 系统 Vulkan loader | `/system/lib64/libvulkan.so` | 308,040 | `d69f6469` | API 37；**NEEDED `libgpud_sys.so`（MTK 定制）** |
| MEOW 拦截层 | `/vendor/lib64/egl/libGLES_meow.so` 等 5 个 | 未采集 | — | 小米图形拦截/追踪层 |

### 5.2 依赖关系（[D]，来自 `DT_NEEDED`）

```
libGLES_mali.so
├─ libged.so            ← MTK GED 用户态（→ /dev/ged → 内核 ged.ko）
├─ libgpud.so           ← MTK GPU 数据面（80+ 个 gpudVk*/gpudMisc* UND 符号）
├─ libgralloc_extra.so / libgralloc_metadata.so / libgralloctypes_mtk.so
├─ android.hardware.graphics.allocator-V2-ndk.so   ← 分配走 AIDL allocator HAL（gralloc-v2 服务）
├─ android.hardware.graphics.mapper@4.0.so
├─ libdmabufheap.so / libion.so
├─ arm.mali.platform-V2-ndk.so
└─ libc++/libc/libm/libdl/libz/libbase/liblog/libcutils/libhardware/libnativewindow/libutils/libbinder_ndk

vulkan.mali.so  →  libGLES_mali.so（唯一非 libc 依赖）
libvulkan.so    →  libgpud_sys.so（MTK 定制，非 AOSP 原样）
mapper.mediatek.so → libged.so / libgpud.so / libdrm.so / mapper@4.0 / libdmabufheap / libsync
hwcomposer.mtk_common.so → libged.so / libdpframework.so / libdrm.so / libpq_sec.so / mapper@2.0,2.1,4.0
                          （**无 libGLES_mali.so**）
```

**三条硬结论（[D]）**：

1. **Vulkan 不是独立实现**：`vulkan.mali.so` 仅 133 KB、SONAME 为自身、唯一导出 `mali_vk_vendor_stub`，且 NEEDED 直指 `libGLES_mali.so` → 它是**薄壳**，Vulkan 主体在 GLES 库内。
2. **HWC 不链接 Mali DDK**：这是首轮只能靠 [E3] 惯例推断的结论，现在是 [D] 事实。
3. **MTK 用户态库是 GLES 的硬依赖**：`libged` + `libgpud` + 4 个 gralloc 私有库。**"原厂用户态可整体保留"必须限定为"整套保留"**，不能只留 `libGLES_mali.so`。

### 5.3 仍然没有的东西

| 缺口 | 状态 | 影响 |
| --- | --- | --- |
| `libGLES_mali.so` 内部版本串（`UK version` / `r49p1-…`） | **无**（只做了 `readelf`，未做 `strings`） | U4-04 开放 |
| `libGLES_mali.so` 完整符号表 / `.text` | **无**（符号输出被采集脚本按关键字筛选） | U4-04/U4-14 开放 |
| `libgpud_sys.so` 的元数据 | **无**（未列入 metadata 目标） | 只知被 NEEDED，不知其导出 |
| `libEGL_mali.so` | 全域未见（`egl/` 目录完整枚举 6 项，无此项） | 见 §6 |

---

## 6. EGL 加载路径：不能因"缺 `libEGL_mali.so`"判定异常

### 6.1 实测事实（[D]）

| 事实 | 值 |
| --- | --- |
| `ro.hardware.egl` | **`mali`** |
| `ro.hardware.vulkan` | **`mali`** |
| `ro.hardware.gralloc` | `common` |
| `ro.hardware.hwcomposer` | `mtk_common` |
| `/vendor/lib64/egl/` 内容 | `libGLES_meow.so`、`libMEOW_data/gift/qt/trace.so`、**`mt6991/libGLES_mali.so`**（共 6 项，含 1 个子目录） |
| `libEGL_mali.so` | **不存在**（`/vendor/lib64/egl`、`/vendor/lib64`、`/system/lib64` 均未见） |
| 系统 EGL/GLES | `libEGL.so` 287,664 B、`libGLESv2.so` 117,312 B，**均为 API 37 AOSP 构建** |
| 运行状态 | `init.svc.vendor.hwcomposer=running`、SurfaceFlinger 服务在册、`ro.vendor.composer_version=3.3` |

### 6.2 为什么缺 `libEGL_mali.so` 不是故障

| 论证 | 内容 |
| --- | --- |
| 反证法 | 设备**正在运行**（HWC pid 1708、SurfaceFlinger 进程在 binder 服务表内）。若 EGL 真的加载失败，系统不可能进入此状态。因此"加载路径是通的"是 [D] 事实 |
| 结构解释 | 自 Android 8 起，供应商**不再提供 `libEGL_*.so`**；EGL 前端由系统 `libEGL.so` 承担，供应商只提供 GLES 驱动库，由 loader `dlopen` 后取 `egl*` 入口 |
| 目录布局 | `egl/**mt6991**/libGLES_mali.so` 的 SoC 子目录布局，说明加载路径由**厂商 linker 配置**注入（而非默认 `egl/` 平铺），这与"多 GPU 变体共用 vendor 分区"的打包方式一致 |
| 反例排除 | 若 `libEGL_mali.so` 真的是必需项且缺失，`libEGL.so` 会在 `eglGetDisplay` 阶段直接失败——与实测运行状态矛盾 |

### 6.3 仍未确定的部分（[U]）

| 项 | 为什么不能定论 |
| --- | --- |
| `mt6991` 子目录是如何被加入搜索路径的 | 需读 `/linkerconfig/ld.config.txt` 或 `ro.egl.additional_libraries`（后者**未出现在 getprop 采集结果中**，但该结果本身是筛选输出，不能据此断定未设置） |
| `libGLES_meow.so` 的注入方式 | 需 `ro.egl.additional_libraries` 或 `LD_PRELOAD`/`debug.egl.*` 佐证 |
| `libGLES_mali.so` 是否导出 `egl*` 入口 | 符号输出被关键字筛选，未见 `eglGetDisplay` **不能**证明未导出 |

> **因此本文件的措辞是**：EGL **实际可用**（[D]），加载**机制细节 UNKNOWN**（[U]）。首轮 01 §3.2 把 `libEGL_mali.so` 列为"期望路径"的写法，已按本节修正为"不存在且不必存在"。

---

## 7. 图形栈服务与声明（[D]）

### 7.1 运行中的服务

| 服务 | pid | 含义 |
| --- | ---: | --- |
| `vendor.hwcomposer` | 1708 | composer 3.3 HAL |
| `vendor.gralloc-v2` | 1706 | **AIDL allocator，实际分配者** |
| `vendor.gpuserv-default` | 1982 | MTK GPU 服务（`IGpuService`） |
| `gpu`（framework） | 1812 | `android.graphicsenv.IGpuService` |
| `vendor.mediatek.hardware.mmagent-default` | 2213 | 显示/多媒体代理 |

### 7.2 VINTF 与特性声明

| 声明 | 值 | 意义 |
| --- | --- | --- |
| `android.hardware.vulkan.version-1_3` | 存在 | **Vulkan 1.3 能力已被系统承认** |
| `android.hardware.vulkan.level-1` | 存在 | |
| `android.hardware.vulkan.compute-0` | 存在 | |
| `android.software.vulkan.deqp.level-2024-03-01` | 存在 | CTS/VTS 合规等级 |
| `android.hardware.opengles.aep` | 存在 | GLES AEP |
| manifest | `manifest_hwcomposer.xml`(395 B)、`mapper.mediatek.xml`(311 B)、`manifest_mtkgpuserv.xml`(208 B) | 三者齐备 |

### 7.3 与"GPU 是否可缺席"相关的属性

| 属性 | 值 | 读法 |
| --- | --- | --- |
| `ro.vendor.mtk.gpu.sw3d` | **`0`** | **软件 3D 关闭**——无 CPU 光栅化回退 |
| `ro.vendor.mtk.gpu.service` | `1` | GPU 服务启用 |
| `ro.hwui.use_vulkan` | `true` | HWUI 走 Vulkan |
| `persist.sys.enable_systemui_mali` | `true` | 系统 UI 显式绑定 Mali |
| `persist.miui.gpu.partition.enable` | `true` | MIUI 侧 GPU 分区特性 |
| `graphics.gpu.profiler.support` | `true` | 抓帧/性能工具链 |

> 这张表**只是风险信号，不是 bootloop 结论**。`sw3d=0` 说明本机没有配置 CPU 3D 回退；但"SurfaceFlinger 在无 GL 时是否仍能起 client 合成"是另一回事，二者不能互相替代。U4-10 保持 UNKNOWN。

### 7.4 DT 侧（[D]）

`/sys/firmware/devicetree/base/` 可见：`soc/mali@48000000`（含 `gpu-frame-base-optimize`）、`soc/gpueb@4b000000`（`gpueb_mem_size`、`gpueb-mem-table`）、`gpufreq-wrapper`（`gpufreq-version`、`gpufreq-bringup`、`gpueb-support`）、`reserved-memory/mblock-17-me_GPUmputab_PMA` 与 `mblock-52-me_GPUEB_SHARED`。

| 结论 | 等级 |
| --- | --- |
| PMA 页表区由 DT 预留，PMA 路径真实存在（呼应首轮"PMA 可保留"） | **[D]** |
| `mall@48000000` 节点**未见** `firmware-name` → 走默认 `mali_csffw.bin` | **[D]**（与 TASK 03 dtbo 解析一致，U4-03 闭合） |
| `gpufreq-wrapper` 同时具备 `gpueb-support` 与 `gpufreq-version` 属性 → 频率策略仍由 MTK 层承担 | **[D]** |

---

## 8. 三份采集文件的净收益

| 首轮结论 | 本次判定 | 依据 |
| --- | --- | --- |
| "仓库内零用户态实体" | ✅ 仍成立（仓库层面） | 仓库仍未提交任何 `.so`/`.bin` |
| "Vulkan ICD 是否存在 UNKNOWN" | ✅ **升级为"存在"** | `ro.hardware.vulkan=mali` + `vulkan.mali.so` 实体 + VINTF 1.3 声明 |
| "gralloc/mapper/HWC 免疫" | ⚠️ **撤回** | HWC 不链接 Mali DDK（[D] 证实），但 NEEDED `libged`；`ged.ko` 不反向依赖 kbase → 失效表现为降级而非崩溃 |
| "原厂固件 header = 0.3" | ⚠️ **降级为 E2 推理** | 字节未实测，见 `02` §3.0 |
| "原厂用户态契约层可保留" | ✅ **不变**，且新增实现层约束 | 整套依赖 MTK 用户态库，不能拆 |
| "bootloop UNKNOWN" | ✅ 保持 UNKNOWN | 无 HyperOS 4.0.3.0 实机故障证据 |
| "EGL 路径 UNKNOWN" | ⚠️ 拆成"可用 [D] / 机制 [U]" | 见 §6 |

---

## 9. 方法学限制（读本文件前必须知道）

1. **目录清单是被筛选的**。`inventory` 的 `/vendor/lib64`、`/system/lib64` 等段落明显为模式匹配输出（含大量 camera/audio 库，但不含全部库）。因此"某文件不在清单里"**只能弱推断其不存在**；本文件中所有"不存在"判断都已在正文注明其强度。`egl/` 子目录的 6 项枚举看起来是完整 `ls`。
2. **符号输出是被筛选的**。`elf_analysis` §2 只覆盖 `gpud*`/`ged_*`/`Egl*`/`vk*`/mali 平台类符号，**不是完整 `.dynsym`**。因此"未见 `eglGetDisplay`"不能推出"未导出"。
3. **无 dmesg / logcat**。因此所有"运行时行为"结论（GLB 版本、DDK 协商值、失败表现）仍无从验证。
4. **无文件内容**。`mali_platform.config`(86 B)、`gralloc/gpu.xml`(1,166 B)、`gpuserv-default.rc`(366 B)、三个 VINTF manifest（208–395 B）都只有大小与哈希，**内容未采集**。
5. **同一份采集不可重复演绎**。本次所有 [D] 结论都指向上表的三个文件；任何超出其内容的推断都已标 [E2]/[E3]/[U]。

---

## 10. 是否需要一次最小化只读补充采集

**需要，且只有 3 条命令。** 理由是存在两个**能被几十字节直接闭合**的 P0 缺口，而现有采集在原理上无法覆盖：

### 10.1 缺口一：固件 header 实际版本（U4-01，P0）

- 为什么必须采：`version_minor` 是 offset 4 的**单字节**，`strings` 原理上取不到；而它是"组合 B 是否确定不可行"的唯一实测依据。
- 命令（文件权限 644，通常 `shell` 用户即可读；若被 SELinux 拒绝，前置 `su -c`）：

```bash
adb shell "od -An -tx1 -N 8 /vendor/firmware/mali_csffw.bin"
# 若 od 不可用：
adb shell "dd if=/vendor/firmware/mali_csffw.bin bs=1 count=8 2>/dev/null | hexdump -C"
```

- 读法（`02` §2 已证字段布局）：`6e 3a f1 c3` 是 magic `0xC3F13A6E` 的小端字节；**第 5 个字节 = minor，第 6 个字节 = major**。
  - `6e 3a f1 c3 03 00 …` → **0.3**，`02` §3 的硬阻断判定由"推理"升级为"实测"；
  - `6e 3a f1 c3 04 00 …` → **0.4**，则首轮最核心的结论被推翻，必须重写 `02`/`06`。

### 10.2 缺口二：DDK 自称的 UK ABI 版本（U4-04，P0）

- 为什么必须采：`03` 的整套论证是"1.30 DDK 在 r56p0 上走旧语义"，但**DDK 是否真的宣称 1.30** 从未被观测。设备上直接 `grep` 二进制即可，**不需要 pull 53 MB**。
- 命令：

```bash
adb shell "grep -a -o -m 3 -E 'UK version [0-9]+\.[0-9]+' /vendor/lib64/egl/mt6991/libGLES_mali.so"
adb shell "grep -a -o -m 3 -E 'r[0-9]{2}p[0-9]-[0-9a-z]+' /vendor/lib64/egl/mt6991/libGLES_mali.so"
```

- 读法：若出现 `UK version 1.30` 与 `r49p1-…`，则"原厂 DDK 与内核同代"由 [E1] 推理变为 [D]；若出现 `1.31+`，则需重算 `min()` 协商的实际落点（结论方向不变，但"1.30 语义"的前提要改）。

### 10.3 明确不要求的采集

| 不做 | 原因 |
| --- | --- |
| `pull` 任何 `.so` / `.bin` / `.ko` | 合规红线；且上述缺口用设备内 `od`/`grep` 即可闭合 |
| `strace` / `dmesg` / `logcat` | 需 root 或重启，超出"最小只读"；待 P0 闭合后再议（U4-14/U4-16/U4-02） |
| 重跑整份 `collect_device.sh` | 三份文件已覆盖其绝大部分输出 |

> **在用户确认之前，本仓库不会把上述两条缺口写成"已闭合"。** 当前状态：U4-01 = UNKNOWN（有 E2 级推理），U4-04 = UNKNOWN（有 E1 级推理）。
