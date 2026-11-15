# 01 — 原厂组件清点

> **本文件的诚实前提（已更新）**：仓库内仍然**没有任何用户态二进制、没有 CSF 固件实体**；但 **2026-11-15 已获得设备侧元数据**（路径 / 大小 / SHA256 / ELF 头 / 动态段 / 服务状态），登记于 [`07_device_evidence.md`](07_device_evidence.md)。
>
> 因此本文件改为**双轨清点**：
> - **仓库轨**：界定"哪些结论只能到源码契约层"；
> - **真机轨**：登记"哪些对象确实存在、叫什么、多大、依赖谁"。
>
> 证据等级：**[D]** 真机实测 · **[E1]** 源码/二进制直接证据 · **[E2]** 交叉推导 · **[E3]** 命名/惯例推断 · **[U]** UNKNOWN

---

## 0. 一句话结论

TASK 04 的三大对象（CSF 固件、用户态 DDK、Android 图形栈）在**仓库中**全部缺失，在**真机上都存在**。

| 对象 | 仓库 | 真机 | 差距性质 |
| --- | :---: | :---: | --- |
| CSF 固件 `mali_csffw.bin` | ❌ | ✅ 307,200 B | 有实体元数据，**无头字节** |
| GLES 驱动 `libGLES_mali.so` | ❌ | ✅ 53,105,232 B | 有元数据与依赖，**无版本串** |
| Vulkan 实现 | ❌ | ✅ 133,416 B 薄壳 + VINTF 1.3 | 存在性已确认 |
| mapper / HWC / gralloc | ❌ | ✅ 三件齐备 | 存在性已确认 |
| 平台层 `.ko` | ✅ 15 个 | ✅ 12 个已装载 | 可交叉印证 |

> 这个区分贯穿全部七份报告：**"契约是否兼容"可由源码精确回答，"blob 是否遵守契约"必须看实体，而"实体的大小/哈希"又不等于"实体的内部字段"。** 三层不能混用。

---

## 1. 证据边界核查

### 1.1 实际执行的检查

```bash
# 全仓 ELF 用户态库
find . -name "*.so" -o -name "*.so.*"        → 0 个
# 固件实体
find . -iname "*csffw*" -o -iname "*.bin"     → 0 个（仅源码文件命中）
# 打包体
find . -name "*.apk" -o -name "*.img" -o -name "*.zip" → 0 个
# 固件目录
find . -type d -name "firmware"               → 0 个
```

### 1.2 结论

| 类别 | 仓库内状态 | 真机状态（[D]） |
| --- | --- | --- |
| `mali_csffw.bin` | **不存在** | ✅ `/vendor/firmware/`，307,200 B，SHA256 `334fb676…` |
| `libGLES_mali.so` | **不存在** | ✅ `/vendor/lib64/egl/mt6991/`，53,105,232 B |
| `libEGL_mali.so` | **不存在** | ❌ **真机也没有**——不是缺失，见 §3.2.1 |
| Vulkan 实现 | **不存在** | ✅ `/vendor/lib64/hw/mt6991/vulkan.mali.so`，133,416 B（薄壳） |
| gralloc / mapper / HWC | **不存在** | ✅ `gralloc.default.so` / `mapper.mediatek.so` / `hwcomposer.mtk_common.so` |
| VINTF manifest / init rc | **不存在** | ✅ 10 个 manifest + 16 个 rc（含 `hw/init.mtkgki.rc`） |
| 设备 `/vendor` 树 | **不存在** | ✅ 可枚举（清单经筛选，见 `07` §9） |

> **首轮错误更正**：原文此表把 Vulkan ICD 记为"不存在"，那是**仓库判据**，却被读成了**设备判据**。真机实测表明 Vulkan 实现存在且系统声明 1.3。详见 `04_vulkan_abi.md` §1。

> 仓库性质决定了这一点：`01_original_baseline` 归档的是 **kernel 树**（`mtk_kernel_modules` + `kernel_ref_mt6991`），不含 Android userspace 镜像。

---

## 2. 仓库内**实际可用**的资产

### 2.1 内核实测资产（TASK 03 已审计）

`01_original_baseline/kernel_ref_mt6991/vendor_dlkm/` 下 15 个 `.ko`，全部 `not stripped`，合计 4.13 MB。与本阶段直接相关的两个：

| 文件 | 字节 | 说明 |
| --- | ---: | --- |
| `mali_kbase_mt6991_r49.ko` | 2,310,424 | 原厂 Kbase，即"固件加载者"与"UAPI 提供者" |
| `mali_prot_alloc_mt6991_r49.ko` | 21,080 | PMA，保护内存分配者（DRM/SVP 路径） |

SHA256 全表见 `04_mtk_platform/MANIFEST.md` §2（已核验）。

**真机装载情况（[D]，本轮新增）**：15 个中 **12 个已装载**；`met_gpu_api`、`met_gpu_adv_api`、`met_gpueb_api` **未装载**。

> 这一条对 Stage 3 的结论有实际影响：任何"MET 追踪模块需同步适配"的风险项，**在本机型上不成立**。详见 [`07_device_evidence.md`](07_device_evidence.md) §3.2。

### 2.2 源码资产（本阶段的主要证据面）

| 位置 | 用途 | 证据等级 |
| --- | --- | --- |
| `01_original_baseline/.../mali-r49p1/drivers/gpu/arm/midgard/include/uapi/**` | r49p1 的 UAPI 头（21 个头文件） | **[E1]** |
| `02_r56_source/.../kernel/include/uapi/gpu/arm/midgard/**` | r56p0 的 UAPI 头（19 个） | **[E1]** |
| `01_original_baseline/.../csf/mali_kbase_csf_firmware.c` | r49p1 固件加载器 | **[E1]** |
| `02_r56_source/.../csf/mali_kbase_csf_firmware.c` | r56p0 固件加载器 | **[E1]** |
| `02_r56_source/.../mali_kbase_caps.h` + `mali_kbase_core_linux.c:148-166` | **UK ABI 能力阈值表** | **[E1]** |

---

## 3. 组件台账：首轮"期望路径"→ 本轮"实测路径"

> 首轮按任务书给的目录逐项登记"该位置应有但仓库没有"。本轮用真机实测替换为"**该位置实际有什么**"，并标出每条 UNKNOWN 的现状。
> 数据来源：`stage4_file_metadata.txt`（22 个对象的大小/哈希）、`stage4_elf_analysis.txt`（9 个 ELF 的动态段）。完整表见 [`07_device_evidence.md`](07_device_evidence.md) §5。

### 3.1 固件

| 首轮期望 | 实测结果 | 状态 |
| --- | --- | --- |
| `/vendor/firmware/mali_csffw.bin` | ✅ 存在，307,200 B，`334fb676…` | 实体元数据已取；**头字节未取**（U4-01） |
| `/vendor/etc/*.xml`（firmware 配置） | ❌ 无 firmware 相关 xml；`/vendor/etc/mali_platform.config`（86 B）属平台配置 | U4-03 已闭合（无 `firmware-name`） |
| `/vendor_dlkm/lib/modules/*` 的 insmod 参数 | ❌ 未采集 | **残留缺口**，见 `02` §3.0.1 第⑦环 |

> **关键更正**：首轮把"无法验证固件头 minor=3"归因于"没有固件实体"。事实是**有实体、有大小、有哈希，仍无法验证头字节**——因为 `strings` 与 `sha256sum` 在原理上都不读二进制头。这是**工具选型问题**，不是**采集深度问题**。

### 3.2 用户态 DDK

| 首轮期望 | 实测结果 | 状态 |
| --- | --- | --- |
| `/vendor/lib64/egl/libGLES_mali.so` | ❌ 该平铺路径无此文件 | — |
| `/vendor/lib64/egl/**mt6991**/libGLES_mali.so` | ✅ **真实路径**，53,105,232 B，Build ID `700e6d4112a6a8a5`，note API 35 | 路径类 UNKNOWN 闭合 |
| `/vendor/lib64/egl/libEGL_mali.so` | ❌ **不存在（且不必存在）** | 见 §3.2.1 |
| `/vendor/lib64/libGLES_mali.so` | ❌ 不存在 | 首轮的"可能主路径"假设排除 |
| `/vendor/lib64/vulkan/` 或 `hw/vulkan.*.so` | ✅ `/vendor/lib64/hw/mt6991/vulkan.mali.so` | U4-05 闭合 |
| `/vendor/etc/vulkan/icd.d/*.json` | ❌ 未见该目录 | 加载机制转 U4-17 |
| `/vendor/etc/egl/*.json`、`egl.cfg` | ❌ 均不存在 | EGL 选择靠 `ro.hardware.egl=mali` |

#### 3.2.1 为什么 `libEGL_mali.so` 不存在却不是缺陷

| 论证 | 内容 |
| --- | --- |
| 实测 | `ro.hardware.egl=mali`，但系统内无任何 `libEGL_mali.so` |
| 系统仍在跑 | HWC（pid 1708）、gralloc-v2（1706）、gpuserv（1982）、SurfaceFlinger 在册 **[D]** |
| 结构 | 自 Android 8 起 EGL 前端由系统 `libEGL.so`（API 37，287,664 B）承担，厂商只交 GLES 库，由 loader `dlopen` 后取 `egl*` 入口 |
| 布局 | 驱动放在 `egl/**<soc>**/` 子目录，说明搜索路径由厂商 linker 配置注入 |

> 结论：**"缺 `libEGL_mali.so`"不能作为异常判据**。真正未知的是"`mt6991` 子目录如何进入搜索路径"（U4-06 保留，降为 P2）。

### 3.3 Android 图形栈

| 组件 | 实测路径 | 字节 | 关键依赖 |
| --- | --- | ---: | --- |
| mapper HAL | `/vendor/lib64/hw/mt6991/mapper.mediatek.so` | 187,640 | `libged` `libgpud` `libdrm` `mapper@4.0` `libdmabufheap` |
| HWC | `/vendor/lib64/hw/hwcomposer.mtk_common.so` | 2,086,232 | `libged` `libdpframework` `libdrm` `libpq_sec`；**无 Mali DDK** |
| gralloc | `/vendor/lib64/hw/gralloc.default.so` | 52,344 | 仅 liblog/libcutils → **passthrough 占位** |
| 实际分配器 | `vendor.gralloc-v2` 服务（AIDL allocator-V2） | — | 被 `libGLES_mali.so` 直接 NEEDED |
| VINTF | `manifest_hwcomposer.xml`(395) / `mapper.mediatek.xml`(311) / `manifest_mtkgpuserv.xml`(208) | — | 三者齐备 |
| init | `gpuserv-default.rc`(366)、`composer@3.3-service.rc`(331) | — | 服务在跑 |

> **这一节推翻了两条首轮假设**：
> 1. "gralloc 走 `/dev/dma_heap`，与 GPU 无关"——实际分配走 **AIDL allocator HAL + mapper.mediatek.so**，而 mapper NEEDED `libged`；
> 2. "HWC 判断只能靠 [E3] 惯例"——现在是 [D]：HWC **确实不链接 Mali DDK**，但**链接了 `libged`**（MTK GPU 调度器用户态）。
>
> 因此"免疫"一词已从 `05`/`06` 中撤下。准确表述是：**不直接依赖 DDK，但依赖 `libged`（事件面）**；由于 `ged.ko` 不反向依赖 kbase，故障表现为**降级**而非装载失败。

---

## 4. 从源码侧**反向推导**的用户态必需文件

虽然拿不到 blob，但可以从内核代码确证"用户态**一定**会打开哪些路径"。这是 E2 级证据，用于指导采集。

| 内核依据 | 推导的用户态依赖 |
| --- | --- |
| `mali_kbase_core_linux.c`：设备节点名由 `KBASE_DEVICE_NAME` 决定 → `/dev/mali0` | 用户态必须 `open("/dev/mali0")` 并 `ioctl` |
| `kbase_api_handshake` 要求首次 ioctl 为 `KBASE_IOCTL_VERSION_CHECK`（否则 `kbase_api_handshake_dummy` 返回 `-EPERM`） | 用户态必须在任何其他 ioctl 前完成版本协商 |
| `request_firmware(&firmware, "mali_csffw.bin", ...)` | 系统内必须有 `/vendor/firmware/mali_csffw.bin`（或 DTB `firmware-name` 指定的名字） |
| `KBASE_IOCTL_GET_GPU_PROPS` 两阶段协议 | 用户态必须先以 `size=0` 查询，再按返回大小分配 |

> **重要**：这四条说明用户态与内核之间存在**严格的启动顺序契约**。任何一条不满足，GPU 都无法初始化。

---

## 5. 已确认的组件**标识**（非文件级，是常量级）

虽然没有 blob，但"原厂用户态会宣称什么版本"是**由内核头文件定义**的，可精确确定：

| 标识 | r49p1（原厂） | r56p0（目标） | 证据 |
| --- | --- | --- | --- |
| CSF UK ABI major | **1** | **1** | `csf/mali_kbase_csf_ioctl.h:121` / `:148` |
| CSF UK ABI minor | **30** | **39** | 同上 `:122` / `:149` |
| JM UK ABI | 11.46（存在） | **不存在** | `jm/mali_kbase_jm_ioctl.h:171-172`（r56p0 无此文件） |
| 固件名 | `mali_csffw.bin` | `mali_csffw.bin` | 两版 `mali_kbase_csf_firmware.c:84` / `:61` |
| **固件头版本（源码要求）** | **0.3** | **0.4** | `:108-109` / `:85-86` |
| **固件头版本（固件实测）** | **UNKNOWN** | — | 字节未采集，见 `02` §3.0 |
| 固件接口版本门槛 | ≥ 1.0.0 / 1.1.0 | ≥ 1.0.0 / 1.1.0 | 两版 `kbase_csf_interface_version(1,1,0)` |

> **口径说明（本轮修正）**：上表前四行 + 门槛行是 [E1] 源码常量，可直接用于矩阵判定；**"固件头版本（源码要求）"只描述"内核期望什么"，不描述"固件是什么"**。首轮没有区分这两件事，是本阶段最需要记住的教训。
>
> 设备侧另有一条 [D] 实测可交叉印证 UK 1.30：
> `/sys/module/mali_kbase_mt6991_r49/version` = `r49p1-03bet0 (UK version 1.30)`（`MODULE_VERSION` 宏展开，`mali_kbase_core_linux.c:6800`）。注意这是**内核**宣称值，**不是** DDK 宣称值。

---

## 6. 采集脚本

见 `tools/collect_device.sh`（本目录下 `tools/`），设计原则：

1. **只读**：全部 `adb shell` 只执行 `ls` / `sha256sum` / `strings` / `getprop`，无 `push`/`rm`/`mount -w`
2. **不落地厂商二进制**：脚本只输出**元数据**（路径、大小、SHA256、ELf 头摘要、版本串），不 `adb pull` 二进制本体
3. **可核对**：输出为 CSV + 文本双格式，便于与本文档表格逐行比对

> 若后续需要 blob 本体做 REA 分析，属于**用户自主决定**，且需注意 `06_porting_design` 的合规风险登记。

---

## 7. UNKNOWN 清单（本文件负责部分）

| ID | 内容 | 缺失证据 | 补齐方式 |
| --- | --- | --- | --- |
| U4-01 | 原厂 `mali_csffw.bin` 的 header minor 值 | **8 字节**（不是整个文件） | 按 `02` §3.0.4 的 `od` 命令读数 |
| U4-02 | 原厂固件的 GLB 接口运行时版本 | dmesg `Loading Mali firmware 0x...` | 需 root/重启，暂不采集 |
| U4-03 | MTK 是否用 DTB `firmware-name` 覆盖固件名 | — | ✅ **已闭合**：DT 无该属性（TASK 03 dtbo + 本轮 `/sys/firmware/devicetree` 双向确认） |
| U4-04 | 原厂 DDK 的 UK ABI 实际值 / padding 清零 / props 校验 | 设备内 `grep` 两条 | 按 `07` §10.2 采集 |
| U4-05 | 是否存在 Mali Vulkan ICD | — | ✅ **已闭合：存在**（`hw/mt6991/vulkan.mali.so` + `ro.hardware.vulkan=mali` + VINTF 1.3） |
| U4-06 | EGL 加载路径与配置 | `ld.config.txt` / `ro.egl.additional_libraries` | 降为 P2：EGL **可用**已 [D] 证实，仅机制未知 |
| U4-07 | gralloc 是否走 dma-buf heap | — | ⚠️ **部分闭合**：分配链为 allocator-V2 AIDL + `mapper.mediatek.so`（NEEDED `libdmabufheap`）；`/dev/dma_heap` 未枚举 |
| U4-08 | HWC 是否直接依赖 GPU | — | ✅ **已闭合：不直接依赖**（NEEDED 无 Mali 库）；新开 U4-22（经 `libged` 的间接耦合） |
| U4-09 | VINTF 声明与 init 服务 | — | ✅ **已闭合**：10 个 manifest、16 个 rc（含 `hw/init.mtkgki.rc`）、服务 pid 全部实测 |
| **U4-22**（新增） | **`libged` 失效时 mapper/HWC 的实际行为** | 需故障注入 | 新风险面，见 `05` §3.2 |

> U4-03 的双重确认：TASK 03 的 dtbo 解析（`04_mtk_platform/05_dts_hardware_resource_audit.md` §2）与本轮 `/sys/firmware/devicetree/base/soc/mali@48000000` 属性枚举，**两侧都不含** `firmware-name`，因此走默认名。此项为 **已闭合**。
>
> **U4-01 不受 U4-03 闭合的影响**：固件名确定，只能证明"加载的是哪个文件"，不能证明"该文件的 offset 4 是多少"。

---

## 7.1 本轮新增的两个观察

| 观察 | 内容 | 等级 |
| --- | --- | --- |
| **USER 侧依赖是"整套"而非"单库"** | `libGLES_mali.so` NEEDED `libged` / `libgpud` / `libgralloc_extra` / `libgralloc_metadata` / `libgralloctypes_mtk` / `libion` / `arm.mali.platform-V2-ndk` —— 无法只保留 GLES 库而丢弃 MTK 运行库 | **[D]** |
| **存在两份 `gpud`** | `/vendor/lib64/libgpud.so`（被 GLES 引用）与 `/system_ext/lib64/libgpud_sys.so`（被系统 `libvulkan.so` 引用），二者被不同模块引用**同名符号**（`gpudInitialize`、`g_gpud_context`） | **[D]** 事实 / 后果 **[U]** |

---

## 8. 与相邻章节的分工

- 本文档只做**清点与边界**，不做兼容性判定 → 判定在 `06_abi_compatibility_matrix.md`
- 固件的加载机制与版本检查 → `02_csf_firmware_abi.md`
- 用户态 ABI 契约逐项比对 → `03_gles_egl_abi.md`
- 图形栈路径 → `05_android_graphics_stack.md`
