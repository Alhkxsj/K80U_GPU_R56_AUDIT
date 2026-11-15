# 01 — 原厂组件清点

> **本文件的诚实前提**：仓库内**没有任何用户态二进制、没有 CSF 固件实体**。
> 因此本文件的实质内容不是"登记文件属性"，而是**精确界定证据边界**——哪些结论有实体支撑，哪些只能到源码契约层，哪些必须等设备采集。
>
> 证据等级：**[E1]** 二进制/源码直接证据 · **[E2]** 源码交叉推导 · **[E3]** 命名/惯例推断 · **[U]** UNKNOWN

---

## 0. 一句话结论

TASK 04 的三大对象（CSF 固件、用户态 DDK、Android 图形栈）在仓库中**全部缺失**。可用证据只有两版的**内核侧 UAPI 头文件与加载代码**——它们是"用户态与内核之间的契约"，可以精确回答"契约是否兼容"，但**无法回答"原厂 blob 是否遵守该契约"**。

这个区分贯穿全部六份报告。

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

| 类别 | 仓库内状态 |
| --- | --- |
| `mali_csffw.bin` | **不存在** |
| `libGLES_mali.so` / `libEGL_mali.so` | **不存在** |
| Vulkan ICD（`.so` + JSON） | **不存在** |
| gralloc / mapper / HWC / composer | **不存在** |
| VINTF manifest / init rc | **不存在** |
| 设备 `/vendor` 树整体 | **不存在** |

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

### 2.2 源码资产（本阶段的主要证据面）

| 位置 | 用途 | 证据等级 |
| --- | --- | --- |
| `01_original_baseline/.../mali-r49p1/drivers/gpu/arm/midgard/include/uapi/**` | r49p1 的 UAPI 头（21 个头文件） | **[E1]** |
| `02_r56_source/.../kernel/include/uapi/gpu/arm/midgard/**` | r56p0 的 UAPI 头（19 个） | **[E1]** |
| `01_original_baseline/.../csf/mali_kbase_csf_firmware.c` | r49p1 固件加载器 | **[E1]** |
| `02_r56_source/.../csf/mali_kbase_csf_firmware.c` | r56p0 固件加载器 | **[E1]** |
| `02_r56_source/.../mali_kbase_caps.h` + `mali_kbase_core_linux.c:148-166` | **UK ABI 能力阈值表** | **[E1]** |

---

## 3. 缺失资产台账（按任务书指定的检查位置逐项）

> 说明：任务书要求检查 `/vendor/lib64`、`/vendor/lib64/egl`、`/vendor/lib64/hw`、`/vendor/etc`、`/vendor/firmware`、`/vendor_dlkm`、`/system/lib64`、`/system/etc`。以下按"该位置应有但仓库没有"逐条登记，并给出**该文件存在与否会推翻哪条结论**。

### 3.1 固件

| 期望路径 | 期望对象 | 缺失影响 | 触发 UNKNOWN |
| --- | --- | --- | --- |
| `/vendor/firmware/mali_csffw.bin` | CSF 固件本体 | **无法验证固件头 minor=3 是否真为原厂值**；无法验证 GLB 接口运行时版本 | U4-01、U4-02 |
| `/vendor/etc/*.xml`（firmware 配置） | 固件配置项 | 无法确认 MTK 是否用 `firmware-name` DTB 覆盖固件名 | U4-03 |
| `/vendor_dlkm/lib/modules/*` | 模块加载参数 | 无法确认 `fw_name=` 的 insmod 参数 | U4-03 |

### 3.2 用户态 DDK

| 期望路径 | 期望对象 | 缺失影响 | 触发 UNKNOWN |
| --- | --- | --- | --- |
| `/vendor/lib64/egl/libGLES_mali.so` | GLES 驱动 | 无法取得 DDK 版本、Build ID、实际协商的 UK ABI minor | **U4-04（最关键）** |
| `/vendor/lib64/egl/libEGL_mali.so` | EGL 驱动 | 同上 | U4-04 |
| `/vendor/lib64/libGLES_mali.so` | 可能的主路径 | 同上 | U4-04 |
| `/vendor/lib64/vulkan/` 或 `/vendor/lib64/hw/vulkan.*.so` | Vulkan ICD | 无法确认是否存在 Mali Vulkan | U4-05 |
| `/vendor/etc/vulkan/icd.d/*.json` | ICD manifest | 无法确认 ICD 入口 | U4-05 |
| `/vendor/etc/egl/*.json`、`egl.cfg` | EGL 配置 | 无法确认 EGL 加载路径 | U4-06 |

### 3.3 Android 图形栈

| 期望路径 | 期望对象 | 缺失影响 | 触发 UNKNOWN |
| --- | --- | --- | --- |
| `/vendor/lib64/hw/gralloc.*.so` | gralloc HAL | 无法确认 buffer 分配是否走 dma-buf heap | U4-07 |
| `/vendor/lib64/hw/android.hardware.graphics.mapper@*.so` | mapper HAL | 同上 | U4-07 |
| `/vendor/lib64/hw/hwcomposer.*.so` | HWC | 无法确认 HWC 是否直接用 GPU | U4-08 |
| `/vendor/etc/vintf/manifest.xml` | VINTF | 无法确认 HAL 声明与版本 | U4-09 |
| `/vendor/etc/init/*.rc` | init 启动配置 | 无法确认 GPU 相关服务与权限 | U4-09 |

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
| 固件头版本 | **0.3** | **0.4** | `:108-109` / `:85-86` |
| 固件接口版本门槛 | ≥ 1.0.0 / 1.1.0 | ≥ 1.0.0 / 1.1.0 | 两版 `kbase_csf_interface_version(1,1,0)` |

> **这六行是本阶段最硬的证据**。它们全部来自 [E1] 源码，可直接用于 04-F 的矩阵判定。

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
| U4-01 | 原厂 `mali_csffw.bin` 的实际 header minor 值 | 固件实体 | 采集后读 offset 4/5 |
| U4-02 | 原厂固件的 GLB 接口运行时版本 | 固件实体 | 需实机 dmesg `Loading Mali firmware 0x...` |
| U4-03 | MTK 是否用 DTB `firmware-name` 覆盖固件名 | dtbo 中 mali 节点是否含该属性 | 已在 03 章 dtbo 解析中检查：**未见**（见 05 章 §7） |
| U4-04 | 原厂 DDK 的 UK ABI minor 实际值 | `libGLES_mali.so` | 采集 + `strings` 搜版本串 |
| U4-05 | 是否存在 Mali Vulkan ICD | `/vendor/lib64/vulkan/` | 采集 |
| U4-06 | EGL 加载路径与配置 | `/vendor/etc/egl/` | 采集 |
| U4-07 | gralloc 是否走 dma-buf heap | gralloc HAL | 采集 |
| U4-08 | HWC 是否直接依赖 GPU | HWC HAL | 采集 |
| U4-09 | VINTF 声明与 init 服务 | manifest.xml / *.rc | 采集 |

> U4-03 已在 TASK 03 的 dtbo 解析中顺便回答：`/soc/mali@48000000` 节点属性表（`05_dts_hardware_resource_audit.md` §2）**不含** `firmware-name`，因此走默认名。此项从 UNKNOWN 降级为 **已闭合**。

---

## 8. 与相邻章节的分工

- 本文档只做**清点与边界**，不做兼容性判定 → 判定在 `06_abi_compatibility_matrix.md`
- 固件的加载机制与版本检查 → `02_csf_firmware_abi.md`
- 用户态 ABI 契约逐项比对 → `03_gles_egl_abi.md`
- 图形栈路径 → `05_android_graphics_stack.md`
