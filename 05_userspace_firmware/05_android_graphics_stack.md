# 05 — Android 图形系统依赖分析

> **本文件回答**：gralloc / mapper / HWC / SurfaceFlinger 是否存在额外兼容约束？
>
> **答案（已更新）**：内核侧通路完整（[E1]）；**用户态依赖关系已由真机实测取得**（[D]），结论比首轮更精确、也更保守：
> **HWC 与 mapper 确实不链接 Mali DDK，但两者都 NEEDED `libged`**——即它们与 GPU 的耦合不是"无"，而是"不经过 DDK、经过 MTK 的 GED 用户态"。因此首轮"**gralloc/mapper/HWC 免疫**"的表述**必须撤回**。
>
> 证据等级：**[D]** 真机实测 · **[E1]** 二进制/源码 · **[E2]** 交叉推导 · **[E3]** 惯例推断 · **[U]** UNKNOWN

---

## 0. 结论摘要

| 问题 | 答案 | 等级 |
| --- | --- | --- |
| 哪些组件直接链接 Mali DDK？ | **只有 EGL/GLES 使用者**；HWC、mapper、gralloc 均**不链接** | **[D]** |
| 哪些完全不依赖 GPU？ | **只有 `gralloc.default.so` 这层占位库**；mapper/HWC 都 NEEDED `libged`（MTK GED 用户态） | **[D]** |
| GPU buffer 分配/导入/映射/释放路径 | 内核侧完整（§2）；用户态为 `allocator-V2 AIDL` → `mapper.mediatek.so` → dma-buf | **[E1]** + **[D]** |
| DRM / protected / SVP 依赖 | PMA + `BASE_MEM_PROTECTED`，两版 ops 逐字节相同；DT 可见 `mblock-17-me_GPUmputab_PMA` | [E1] + **[D]** |
| 驱动初始化失败时系统行为 | 推导见 §6，**仍无实机证据** | [E2]/[U] |
| 是否存在软件渲染降级 | **本机 `ro.vendor.mtk.gpu.sw3d=0`**——未配置 CPU 3D 回退 | **[D]** |
| kbase 换版是否影响 gralloc/mapper/HWC | **影响性质为"降级"而非"崩溃"**（`ged.ko` 不依赖 kbase）；程度未量化 | **[D]** + **[E1]** + **[U]** |

---

## 1. 证据状态

### 1.1 仓库 vs 真机

| 对象 | 仓库 | 真机（[D]） |
| --- | --- | --- |
| gralloc | **不存在** | `gralloc.default.so` 52,344 B（占位）+ `vendor.gralloc-v2` 服务 |
| mapper | **不存在** | `mapper.mediatek.so` 187,640 B + `mapper.mediatek.xml` |
| HWC / composer | **不存在** | `hwcomposer.mtk_common.so` 2,086,232 B，composer **3.3** |
| SurfaceFlinger 配置 | **不存在** | 服务在册，`ro.vendor.composer_version=3.3` |
| VINTF manifest | **不存在** | 10 个（含 3 个图形相关） |
| init `*.rc` | **不存在** | 15 个（含 `gpuserv-default.rc`、`composer@3.3-service.rc`） |

> 首轮据此只能靠内核 `UND` 符号做间接论证（§1.2）；本轮直接读到了依赖图，论证方式从"推导"变为"观测"。

### 1.2 可用替代证据：内核侧 UND 符号

虽然没有 HAL，但 **kbase 对 Android 图形基础设施的依赖是二进制的、可精确枚举的**。

```bash
readelf -sW mali_kbase_mt6991_r49.ko | awk '$7=="UND"{print $8}' \
  | grep -E "^(dma_buf|dma_fence|dma_resv|sync_file|ion_)"
```

结果：**18 个符号，零 `ion_*`**：

| 组 | 符号 | 含义 |
| --- | --- | --- |
| dma-buf | `dma_buf_get`、`dma_buf_put`、`dma_buf_attach`、`dma_buf_detach` | 导入/引用/挂接外部 buffer |
| dma-buf 映射 | `dma_buf_map_attachment_unlocked`、`dma_buf_unmap_attachment_unlocked`、`dma_buf_mmap` | 建立 GPU 侧映射 |
| dma-fence | `dma_fence_init`、`dma_fence_signal`、`dma_fence_add_callback`、`dma_fence_remove_callback`、`dma_fence_context_alloc`、`dma_fence_default_wait`、`dma_fence_get_status`、`dma_fence_release`、`dma_fence_array_ops` | 同步原语 |
| sync_file | `sync_file_create`、`sync_file_get_fence` | Android sync framework 桥接 |

**三条硬结论**：

1. **GPU 与外部 buffer 的唯一通道是 dma-buf**（无 ion、无 gralloc 私有 ioctl）
2. **同步走标准 dma-fence / sync_file**（Android 的 sync framework）
3. 使用 `*_unlocked` 变体 → 表明适配了较新内核的 dma-buf API（Linux 6.2+），与 6.6 内核一致

---

## 2. GPU buffer 完整通路（内核侧可证）

### 2.1 分配路径（gralloc → GPU）

```
[用户态] gralloc 通过 /dev/dma_heap/* 或 ION 兼容层分配
   ↓ 得到 dma-buf fd
[用户态] 把 fd 交给 GPU 用户态（EGL/Vulkan）
   ↓ ioctl(MEM_IMPORT) { type=BASE_MEM_IMPORT_TYPE_DMA_BUF, handle=fd }
[内核]  kbase_api_mem_import()
   ↓
   dma_buf_get(fd)                    ← UND 符号
   dma_buf_attach(dmabuf, dev)        ← UND 符号
   dma_buf_map_attachment_unlocked()  ← UND 符号
   ↓ 得到 sg_table → 建 GPU 页表
[内核]  mgm_dev->ops.mgm_update_gpu_pte()   ← 见 04 章 §2
```

### 2.2 同步路径（fence）

```
[GPU 完成渲染]
[内核] kbase 生成 dma_fence → dma_fence_signal()
   ↓
[用户态] sync_file_create() / 或通过 CS_EVENT 获取
   ↓
[SurfaceFlinger] 用 sync_wait / fence fd 等待
```

### 2.3 释放路径

```
[用户态] ioctl(MEM_FREE) { handle }
[内核]  kbase_api_mem_free()
   ↓ dma_buf_detach / dma_buf_unmap_attachment_unlocked / dma_buf_put
[内核]  释放 GPU 页表、归还 VA
```

### 2.4 为什么这条通路是"版本无关"的

| 层 | 是否随 kbase 版本变化 |
| --- | --- |
| dma-buf / dma-fence 内核 API | **否**（属 Linux 公共 API，只随内核版本变） |
| `MEM_IMPORT` ioctl 结构 | **否**（30 个共有结构体之一，逐字相同） |
| PMA / MGM 的 PTE 处理 | MGM 需适配（TASK 03 结论），但**用户态不可见** |

> **这是本章最重要的判断**：Android 图形栈与 GPU 的耦合点是 **dma-buf fd**，而不是任何 Mali 私有句柄。因此 gralloc/mapper/HWC 对 kbase 版本**基本不敏感**。

---

## 3. 哪些组件直接依赖 Mali 用户态库（[D] 实测，取代首轮 [E3] 推断）

### 3.1 实测依赖矩阵

| 组件 | 是否 NEEDED Mali DDK | 实际 NEEDED（图形相关） | 判定 |
| --- | :---: | --- | --- |
| `libGLES_mali.so` | 自身 | `libged` `libgpud` `libgralloc_extra` `libgralloc_metadata` `libgralloctypes_mtk` `libion` `libdmabufheap` `allocator-V2` `arm.mali.platform-V2` | **DDK 本体** |
| `vulkan.mali.so` | ✅（唯一非 libc 依赖） | `libGLES_mali.so` | 薄壳 |
| `libvulkan.so`（system） | ❌ | `libgpud_sys.so` | 被 MTK 定制，挂数据面 |
| `mapper.mediatek.so` | ❌ | **`libged`** `libgpud` `libdrm` `mapper@4.0` `libdmabufheap` `libsync` `arm.graphics-V5` | **间接耦合** |
| `hwcomposer.mtk_common.so` | ❌ | **`libged`** `libdpframework` `libdrm` `libpq_sec` `mapper@2.0/2.1/4.0` `libmml` | **间接耦合** |
| `gralloc.default.so` | ❌ | 仅 liblog/libcutils | passthrough 占位 |
| SurfaceFlinger（进程） | — | 经 `libEGL.so` 间接 | 见 §6 |

### 3.2 为什么"免疫"这个词必须撤回（但不是因为"会挂"）

先说清依赖方向，否则容易推到反面去：

| 方向 | 事实 | 来源 |
| --- | --- | --- |
| `kbase` → `ged` | kbase 从 ged 导入 **53 个符号** | TASK 03（`__versions`/`.rela`）**[E1]** |
| `ged` → `kbase` | **0 个**（14 个 MTK 模块对 kbase 反向引用全为 0） | TASK 03 反依赖定理 **[E1]** |
| `mapper/HWC` → `libged` | NEEDED | 真机 `DT_NEEDED` **[D]** |

**因此不能说"kbase 挂了会导致 ged 装载失败"**——`ged.ko` 本身不依赖 kbase，TASK 03 的定理在此仍然成立。

那为什么"免疫"仍然要撤回？因为"依赖不存在"和"依赖存在但方向相反"是两回事：

| 首轮表述 | 实测事实 | 修订结论 |
| --- | --- | --- |
| "gralloc/mapper/HWC 只依赖 dma-buf，**免疫**" | mapper NEEDED `libged` + `libgpud`；HWC NEEDED `libged` + `libdpframework` | **架构描述错误**：它们不是"只碰 dma-buf"，而是"碰 MTK GPU 生态的用户态库" |
| （隐含）"kbase 换版对这些组件无影响" | 依赖方向是 kbase→ged，ged 不反向依赖 kbase；但 kbase 一旦不工作，**ged 就收不到 GPU 侧事件**（调度提示、频率请求、fence 回调） | **影响性质是"上游事件缺失"，不是"装载失败"** |

> **准确表述**：`kbase 换版` 对 mapper/HWC 的影响是——**库继续加载，功能可能降级**（GED 从"有 GPU 事件驱动"变成"空转"）。这既不是"免疫"，也不是"会崩"，而是"**降级风险，程度未知**"（U4-22）。
>
> 这也是为什么不能简单用 dma-buf 通用性来论证安全：dma-buf 只覆盖**数据面**，而 `libged` 覆盖的是**调度/事件面**，两者是不同维度。

### 3.3 显示通路与渲染通路仍然分离（这条首轮结论继续成立）

```
应用 → HWUI → EGL/GLES → GPU 驱动 → kbase      【渲染】
                                            ↓
                              产出 graphic buffer（dma-buf）
                                            ↓
SurfaceFlinger → HWC → DRM/KMS → 显示控制器    【显示】
```

**GPU 驱动失效只切断"渲染"，不切断"显示"**——本机 HWC 不链接 DDK（[D]），且 `ged.ko` 不依赖 kbase（[E1]），两个条件都支持"显示通路能独立存活"。但"能存活"≠"不降级"：GED 的事件面会失效。

---

## 4. DRM / Protected / SVP 路径

### 4.1 依赖链

```
[用户态] 视频播放器（Widevine L1）请求 secure buffer
   ↓ gralloc 分配带 GRALLOC_USAGE_PROTECTED 的 buffer
[用户态] EGL/Vulkan 以 BASE_MEM_PROTECTED 导入
[内核]   kbase → PMA（mali_prot_alloc_mt6991_r49.ko）
   ↓ pma_alloc_page / pma_release_pages
[硬件]   GPU 在保护模式下读写
```

### 4.2 两版兼容性（引用 TASK 03 结论）

| 组件 | r49p1 | r56p0 | 判定 |
| --- | --- | --- | --- |
| `struct protected_memory_allocator_ops` | 5 个函数指针 | **逐字节相同** | 兼容 |
| `protected_memory.c` | 155 行 / 4,463 B | **完全一致**（diff 为空） | 兼容 |
| `BASE_MEM_PROTECTED`（bit16） | 定义 | 定义 | 一致 |

> 依据：`04_mtk_platform/04_mgm_pma_memory_audit.md` §3。

### 4.3 修正 Stage 2 的结论

Stage 2 曾判定"PMA 缺失导致 DRM 版权视频无法播放"。TASK 03 已推翻：**PMA 接口完全兼容，MTK 的 `mali_prot_alloc_mt6991_r49.ko` 可保留**。

本文件补充一层：**即使 PMA 正常，DRM 播放还依赖 Widevine HAL 与 secure heap**，这些与 GPU 无关。因此"DRM 视频能否播放"不是 GPU 移植的判据。

---

## 5. 组件与 kbase 版本的实际耦合度（修订版）

| 组件 | 耦合点 | 对 kbase 版本敏感度 | 依据 |
| --- | --- | --- | --- |
| gralloc（`gralloc.default.so`） | 无（仅占位） | **无** | [D] 仅 liblog/libcutils |
| 分配器（`gralloc-v2` + `mapper.mediatek.so`） | `libged`（事件面）；dma-buf（数据面） | **弱耦合 · 降级型** | **[D]** + TASK 03 |
| HWC（`hwcomposer.mtk_common.so`） | `libged`；不链接 DDK | **弱耦合 · 降级型** | **[D]** |
| SurfaceFlinger | `libEGL` → `libGLES_mali.so` | **强耦合（一跳，装载即失败）** | [E2] |
| 应用（GLES/Vulkan） | 同上 | **强耦合** | [E2] |
| `libvulkan` → `libgpud_sys` | 系统侧，不经 kbase | **无** | **[D]** |

> **修订后的结论**（替换首轮"gralloc/mapper/HWC 全部免疫"）：
>
> `kbase 换版` 的影响面分三层——**第一层**（DDK 使用者：SF / 应用）**装载即失败**；**第二层**（mapper / HWC）**能装载，但 GED 事件面失效 → 降级**；**第三层**（`gralloc.default.so`、`libvulkan` 的 gpud 依赖）**不受影响**。
>
> 首轮把第二层归入第三层，是**把"依赖 dma-buf"当成了"只依赖 dma-buf"**；本轮开头一度反向过冲成"会崩"，同样不准确——`ged.ko` 不依赖 kbase 这一定理限制了故障传导方式。

---

## 6. GPU 驱动初始化失败时系统的行为

### 6.1 内核侧（[E1]）

见 `02_csf_firmware_abi.md` §7：固件加载失败 → `probe` 失败 → `/dev/mali0` 不存在。

### 6.2 用户态侧（[E2] 推导，**仍无实机故障证据**）

| 阶段 | 预期行为 | 本机相关实测信号 |
| --- | --- | --- |
| EGL 初始化 | `eglGetDisplay` 失败或返回无效 display | `ro.hardware.egl=mali`，驱动在 `egl/mt6991/` |
| HWUI | 无法创建 GL context → 回退或崩溃 | `ro.hwui.use_vulkan=true`（**HWUI 主路径是 Vulkan**，不是 GLES） |
| SurfaceFlinger | RenderEngine 无法初始化 → Client 合成或失败 | 无 SF 配置采集 |
| 系统启动 | 可能 bootloop | **无实机故障证据** |
| 应用 | GPU 应用全部失败 | `persist.sys.enable_systemui_mali=true`（SystemUI 显式绑 Mali） |

### 6.3 是否 bootloop：**UNKNOWN，且本轮不升级为结论**

首轮把这一项列为 P0，措辞是"视 `ro.hardware.egl` 与 init 逻辑；**可能 bootloop**"。本轮补齐了设备侧信号，但**没有任何一条构成 bootloop 的证据**：

| 变量 | 本机实测 | 对 bootloop 的含义 |
| --- | --- | --- |
| `ro.vendor.mtk.gpu.sw3d` | **`0`** | **未启用软件 3D 回退** → 少了一条降级路径（风险信号，非结论） |
| `ro.vendor.mtk.gpu.service` | `1` | GPU 服务是常驻组件 |
| `ro.hwui.use_vulkan` | `true` | HWUI 依赖 Vulkan → 依赖 GLES 库 → 依赖 kbase |
| SurfaceFlinger 是否强制 GL | **无 dmesg / 无源码** | 无法判定 |
| `vendor.mediatek.hardware.mmagent` | 运行中（pid 2213） | 显示/多媒体代理是否硬依赖 GPU 未知 |
| 是否存在"无 GPU 启动"配置 | 无证据 | 无法判定 |

> **必须保持 UNKNOWN 的理由**：
> 1. 本机是 HyperOS **4.0.3.0**（Android 17），而首轮报告与任务书均按"HyperOS 3"讨论——**版本前提已变**，任何基于旧版本的推断都不成立；
> 2. 没有一台"GPU 驱动故意失败"的同型机可供观察；
> 3. `sw3d=0` 只说明"没配置软件 3D"，不说明"不能启动"。
>
> 因此本项在 `06` 中仍标 P0-UNKNOWN，**禁止**在 Stage 5 之前写成"不会 bootloop"或"会 bootloop"。

---

## 7. 降级路径（按本机实测收敛）

| 降级 | 本机是否已具备 | 依据 |
| --- | --- | --- |
| SwiftShader（软件 Vulkan） | **未见**（`sw3d=0`，且 `/system/lib64` 未见 SwiftShader 库） | [D] 弱（清单经筛选） |
| CPU 合成（SurfaceFlinger Client） | 属 SF 内建能力，通常可用 | [E3] |
| 纯硬件合成（HWC 不经 GPU） | **结构上可行**：HWC 不链接 DDK | **[D]** |
| 无 GPU 启动 Android | 理论可行 | [E3] |

> **结论**：首轮"不是变砖，而是严重降级"这句话**方向仍成立**，但**不能当作已验证结论**——`sw3d=0` 削弱了"能降级"的把握，而 HWC 的 `libged` 依赖削弱了"显示完全不受影响"的把握。正确表述：**"存在降级的结构性可能，但未见配置层面的保障"**。

---

## 8. UNKNOWN

| ID | 内容 | 补齐方式 | 现状 |
| --- | --- | --- | --- |
| U4-07 | 分配是否走 dma-buf heap（vs 遗留 ion） | `ls /dev/dma_heap/` | ⚠️ 部分闭合：`libdmabufheap` 被 NEEDED，`libion` 同时在列 → **两者并存**，实际路径未定 |
| ~~U4-08~~ | ~~HWC 是否直接依赖 Mali DDK~~ | — | ✅ **已闭合：不依赖**（NEEDED 无 Mali 库） |
| ~~U4-09~~ | ~~VINTF 声明与 init 服务~~ | — | ✅ **已闭合**：10 manifest / 16 rc / 5 个服务 pid |
| U4-10 | GPU 驱动失败后的实际系统行为（是否 bootloop） | **同型机故障注入**（可回滚环境） | **P0 开放** |
| U4-20 | SurfaceFlinger 的 RenderEngine 后端选择逻辑 | `dumpsys SurfaceFlinger` / SF 源码 | 开放 |
| U4-21 | 是否有服务硬依赖 `/dev/mali0` | `*.rc` 内容（未采集） | 开放 |
| **U4-22**（新增） | `libged` 在 kbase 缺失时的行为，及对 mapper/HWC 的传导 | 故障注入 | **新增 P1** |

---

## 9. 本章的净结论（修订）

1. **GPU buffer 通路是版本无关的**（dma-buf + dma-fence）——这一条**不变**，且由真机的 `libdmabufheap`/`mapper@4.0` 依赖进一步印证
2. ~~耦合面被限制在 DDK 侧，gralloc/mapper/HWC 免疫~~ → **改为**：mapper/HWC 不直接链接 DDK，但依赖 `libged`（事件面）。因 `ged.ko` 不反向依赖 kbase，故障表现为**降级**而非崩溃
3. **GPU 失效不等于系统失效**——结构上成立（HWC 不链接 DDK + ged 不依赖 kbase），但本机 `sw3d=0` 且无降级配置证据，**不能断言"能起"**
4. **MTK 平台层不受牵连**（TASK 03 零反向依赖）——仍成立；且本轮进一步发现 `met_*` 三个模块**根本不装载**，风险面更小
5. 具体表现依赖 **5 项**未采集证据（U4-07 部分闭合后，P0 只剩 U4-10）
