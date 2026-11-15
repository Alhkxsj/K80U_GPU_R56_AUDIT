# 05 — Android 图形系统依赖分析

> **本文件回答**：gralloc / mapper / HWC / SurfaceFlinger 是否存在额外兼容约束？
>
> **答案**：**内核侧确认了完整通路，用户态侧全部 UNKNOWN**。这一章的价值在于把"GPU buffer 从分配到处方"的整条链在**内核契约层**画清楚——这部分与 kbase 版本无关，因此是**稳定的**；而链路上的 Android 组件实现则完全缺乏证据。
>
> 证据等级：**[E1]** 二进制/源码 · **[E2]** 交叉推导 · **[E3]** 惯例推断 · **[U]** UNKNOWN

---

## 0. 结论摘要

| 问题 | 答案 | 等级 |
| --- | --- | --- |
| 哪些组件直接依赖 Mali 用户态库？ | 只有 **EGL/GLES 使用者**（SurfaceFlinger RenderEngine、应用、部分 HAL）。HWC 在现代设备上通常**不用** GPU | [E3] |
| 哪些只依赖 Android 通用接口？ | gralloc/mapper（走 **dma-buf**）、HWC（走 DRM/KMS 或 composer HAL） | [E2] |
| GPU buffer 分配/导入/映射/释放路径 | **内核侧已完整确认**（§2），使用标准 dma-buf | **[E1]** |
| DRM / protected / SVP 依赖 | PMA（`mali_prot_alloc_mt6991_r49.ko`）+ `BASE_MEM_PROTECTED`，两版 ops 逐字节相同 | [E1] |
| 驱动初始化失败时系统行为 | 推导见 §6，**需实机确认** | [E2]/[U] |
| 是否存在软件渲染降级 | **存在**（SwiftShader），但退化严重 | [E3] |

---

## 1. 证据状态

### 1.1 仓库内

| 对象 | 状态 |
| --- | --- |
| gralloc HAL | **不存在** |
| mapper HAL | **不存在** |
| HWC / composer HAL | **不存在** |
| SurfaceFlinger 配置 | **不存在** |
| VINTF manifest | **不存在** |
| init *.rc | **不存在** |

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

## 3. 哪些组件直接依赖 Mali 用户态库

### 3.1 依赖关系（[E3] 基于 Android 架构惯例）

| 组件 | 是否链接 `libGLES_mali.so` | 说明 |
| --- | :---: | --- |
| 应用进程（GLES/Vulkan 应用） | **是** | 通过 EGL/Vulkan loader |
| SurfaceFlinger **RenderEngine** | **是** | GPU 合成路径；但可回退 GL 之外的路径 |
| SurfaceFlinger **HWC 路径** | 否 | 走 `hwcomposer` HAL |
| gralloc HAL | **否** | 只做 buffer 分配，不碰 GPU |
| mapper HAL | **否** | 只做 lock/unlock，走 dma-buf ioctl |
| HWC HAL | **通常否** | 现代 HWC 用 DRM/KMS + 硬件合成器 |
| `libhwui`（HWUI） | **间接** | 通过 EGL 使用 GPU |
| 相机/视频 HAL | 否 | 走各自硬件 |

### 3.2 关键判断：HWC 不依赖 GPU

> 若 HWC 不依赖 GPU，则**即使 GPU 完全不可用，屏幕仍能显示**（走硬件合成器或 GPU 合成回退到 CPU）。
> 这是"GPU 挂了会怎样"这个问题的核心分水岭。

**但这条是 [E3] 惯例推断**，MediaTek 的具体 HWC 实现未验证（U4-08）。

### 3.3 一个反直觉的事实

Android 的**显示通路**与**渲染通路**是分离的：

```
应用 → HWUI → EGL/GLES → GPU 驱动 → kbase      【渲染】
                                            ↓
                              产出 graphic buffer（dma-buf）
                                            ↓
SurfaceFlinger → HWC → DRM/KMS → 显示控制器    【显示】
```

**GPU 驱动失效只切断"渲染"，不切断"显示"**——只要 HWC 能用硬件合成已有 buffer，画面仍在。这解释了为什么 GPU 故障常表现为"卡顿/黑块"而非"完全黑屏"。

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

## 5. 组件与 kbase 版本的实际耦合度

| 组件 | 耦合点 | 对 kbase 版本敏感度 | 依据 |
| --- | --- | --- | --- |
| gralloc | dma-buf heap | **无** | [E2] 只产出 fd |
| mapper | dma-buf ioctl | **无** | [E2] |
| HWC | DRM/KMS | **无** | [E3] |
| SurfaceFlinger | EGL（间接） | **有**（通过 DDK） | [E3] |
| 应用 | EGL/Vulkan（间接） | **有**（通过 DDK） | [E3] |

> **结论**：`kbase 换版` 的影响面被限制在"EGL/Vulkan 使用者"这一侧。gralloc/mapper/HWC 全部免疫。

这与常见直觉相反——很多人认为"换 GPU 驱动要动整个图形栈"，实际只需要 DDK 与内核契约对齐。

---

## 6. GPU 驱动初始化失败时系统的行为

### 6.1 内核侧（[E1]）

见 `02_csf_firmware_abi.md` §7：固件加载失败 → `probe` 失败 → `/dev/mali0` 不存在。

### 6.2 用户态侧（[E2] 推导，需实机确认）

| 阶段 | 预期行为 |
| --- | --- |
| EGL 初始化 | `eglGetDisplay(EGL_DEFAULT_DISPLAY)` 失败或返回无效 display |
| HWUI | 无法创建 GL context → 回退 CPU 渲染（极慢）或崩溃 |
| SurfaceFlinger | RenderEngine 无法初始化 GL → 走 **Client 合成**（CPU）或直接失败 |
| 系统启动 | 视 `ro.hardware.egl` 与 init 逻辑；可能 bootloop |
| 应用 | 所有 GPU 应用失败 |

### 6.3 是否 bootloop 的关键变量（U4-10）

| 变量 | 影响 |
| --- | --- |
| SurfaceFlinger 是否强制要求 GL | 若强制 → bootloop；若有 CPU 回退 → 能起但极卡 |
| `ro.hardware.egl` 指向 | 指向不存在的库 → 加载失败 |
| VINTF 的 `graphics.composer` 声明 | 缺失 → 系统服务启动失败 |
| MTK 的 GPU 服务（GED/GPUEB 相关）是否依赖 kbase | TASK 03 已证：**零反向依赖**，故 MTK 服务不受影响 |

> 最后一条很重要：TASK 03 证明 MTK 平台层对 kbase 零反向引用，所以**GPU 挂了不会连带拖垮 MTK 的电源/频率框架**——这些 `.ko` 仍能正常加载。

---

## 7. 降级路径

| 降级 | 是否可行 | 代价 |
| --- | --- | --- |
| SwiftShader（软件 Vulkan/GL） | 可行 | 性能极低，仅够显示 UI |
| CPU 合成（SurfaceFlinger Client） | 可行 | 高功耗、掉帧 |
| 纯硬件合成（HWC 不经 GPU） | 可行 | 只能合成已有 buffer，无法渲染新内容 |
| 无 GPU 启动 Android | 理论可行 | 能否进入 launcher 取决于 SF 实现 |

> **结论**：不是"变砖"，而是"严重降级"。但具体到 MT6991 + HyperOS 3，是否 bootloop 属 **U4-10**。

---

## 8. UNKNOWN

| ID | 内容 | 补齐方式 |
| --- | --- | --- |
| U4-07 | gralloc 是否走 dma-buf heap（vs 遗留 ion） | 采集 gralloc HAL + `ls /dev/dma_heap/` |
| U4-08 | HWC 是否直接依赖 GPU / Mali DDK | 采集 HWC HAL + `ldd` |
| U4-09 | VINTF 声明与 init 服务 | 采集 manifest.xml / *.rc |
| U4-10 | GPU 驱动失败后的实际系统行为（是否 bootloop） | 实机（危险，需可恢复环境） |
| U4-20 | SurfaceFlinger 的 RenderEngine 后端选择逻辑 | 采集 SF 配置 + `dumpsys` |
| U4-21 | MTK 是否有 GPU 相关 systemd/init 服务依赖 `/dev/mali0` | 采集 *.rc |

---

## 9. 本章的净结论

1. **GPU buffer 通路是版本无关的**（dma-buf + dma-fence），这是最强的稳定性保障
2. **耦合面被限制在 DDK 侧**，gralloc/mapper/HWC 免疫
3. **GPU 失效不等于系统失效**，但会严重降级
4. **MTK 平台层不受牵连**（TASK 03 已证零反向依赖）
5. 具体表现依赖 6 项未采集证据
