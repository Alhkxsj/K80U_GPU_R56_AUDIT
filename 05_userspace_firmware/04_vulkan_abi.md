# 04 — Vulkan ICD 审计

> **本文件回答**：原厂 Vulkan ICD 能否与 R56p0 Kbase 配合？
>
> **答案**：**无法判定**。仓库内没有任何 Vulkan 二进制、JSON manifest 或 ICD 声明。本文件的作用是**把不确定性精确圈定**，并给出"一旦拿到 blob 应如何验证"的路径，而不是给出一个凭空的结论。
>
> 证据等级：**[E1]** 源码 · **[E2]** 交叉推导 · **[E3]** 惯例推断 · **[U]** UNKNOWN

---

## 0. 结论摘要

| 问题 | 答案 | 等级 |
| --- | --- | --- |
| 是否存在 Mali Vulkan ICD？ | **UNKNOWN**（U4-05） | [U] |
| Vulkan 驱动版本？ | **UNKNOWN** | [U] |
| Vulkan 是否走同一 Kbase UAPI？ | **必然如此**——内核只有一套 GPU 接口 | [E2] |
| 若有 ICD，其 ABI 兼容性判断？ | 可复用 `03_gles_egl_abi.md` 的全部结论 | [E2] |
| 原厂 Vulkan 是否存在兼容窗口？ | **条件性成立**：取决于是否共用 GLES 的 UK ABI 协商路径 | [E2]/[U] |

> 本文件刻意**不给出"大概率兼容"之类的措辞**。任务书明确要求："没有实际 Vulkan 二进制时，不得将源码推断写成已验证结论。"

---

## 1. 证据状态

### 1.1 仓库内检查结果

| 对象 | 期望路径 | 仓库状态 |
| --- | --- | --- |
| Vulkan ICD 库 | `/vendor/lib64/vulkan.*.so` | **不存在** |
| ICD manifest | `/vendor/etc/vulkan/icd.d/*.json` | **不存在** |
| EGL 侧 Vulkan 桥 | `/vendor/lib64/libvulkan.so` | **不存在** |
| VINTF 声明 | `/vendor/etc/vintf/manifest.xml` | **不存在** |

### 1.2 可用的间接线索

| 线索 | 内容 | 价值 |
| --- | --- | --- |
| `00_reference/third_party/panvk-kbase-android/docs/MALI-VULKAN-NATIVE-FEATURES.md` | 第三方 PanVK 文档 | **不可用作兼容证据**（任务书明令禁止） |
| 内核 UAPI 中无 Vulkan 专有 ioctl | 见 §2 | 支持 [E2] 推断 |

> 任务书规定："将第三方 PanVK 代码当成原厂 R56p0 兼容证据"属禁止事项。本文件严格遵守，仅将其列为"存在但不可用"。

---

## 2. Vulkan 必然复用同一套 Kbase UAPI（E2）

### 2.1 论证

内核侧不存在"Vulkan 专用"接口。检查全部 28 个 ioctl：

| 类别 | ioctl | 是否 Vulkan 专用 |
| --- | --- | --- |
| 版本/属性 | `VERSION_CHECK`、`GET_GPU_PROPS`、`GET_DDk_VERSION` | 否（共用） |
| 内存 | `MEM_ALLOC/IMPORT/FREE/ALIAS/QUERY/COMMIT/SYNC/...` | 否（共用） |
| CSG/CS | `CS_QUEUE_GROUP_CREATE`、`CS_QUEUE_REGISTER/BIND/KICK` | 否（共用） |
| 同步 | `FENCE_VALIDATE`、`CS_EVENT_*` | 否（共用） |
| 性能计数 | `KINSTR_PRFCNT_*` | 否（共用） |

**没有 `VK_*` 或 `VULKAN_*` 前缀的任何 ioctl。**

### 2.2 推论

> 任何 Mali Vulkan 驱动（Arm 官方 ICD）与 GLES 驱动**共享同一个内核契约**。二者区别只在于用户态如何组织 CSG/CS 与内存，**不改变 ioctl 语义**。

因此：

- 若原厂存在 Mali Vulkan ICD，其与 r56p0 的兼容性判断**与 GLES 完全一致**
- `03_gles_egl_abi.md` 的六条结论可直接迁移
- 唯一差异点在于：Vulkan 是否使用某些 GLES 不用的 ioctl（如 `MEM_ALIAS`、`CS_TILER_HEAP_INIT` 的高级参数）

### 2.3 哪些 Vulkan 特性可能引入额外风险

即使 UAPI 相同，Vulkan 的实现深度高于 GLES，可能触达 GLES 不用的路径：

| 特性 | 涉及的接口 | 风险点 |
| --- | --- | --- |
| 显式内存（`VK_KHR_external_memory`） | `MEM_IMPORT` 的 dma-buf 路径 | 两版结构一致（[E1]），低风险 |
| 稀疏资源（sparse binding） | `MEM_ALIAS` | 两版一致，低风险 |
| Timeline semaphore | `CS_EVENT_*` | 两版一致 |
| Ray tracing / NX | `neural_*` 字段（仅 `_1_35`） | 1.30 用户态用不到 |
| Protected memory（DRM） | `BASE_MEM_PROTECTED` + PMA | TASK 03 已证 PMA 兼容 |

> **这张表的价值**：它说明"若 Vulkan 存在，其增量风险面很小"，因为高级特性恰好落在两版最稳定的接口上。

---

## 3. 一个必须澄清的常见误解

| 误解 | 事实 |
| --- | --- |
| "MediaTek 设备都用 Mali Vulkan" | 不成立。MTK 部分平台使用 **Imagination PowerVR**，Vulkan 由 PowerVR 提供；MT6991 用 Immortalis-G925，理论上可用 Mali Vulkan，但**厂商是否启用未知** |
| "有 `libGLES_mali.so` 就一定有 Vulkan ICD" | 不成立。二者是独立交付物，厂商可只发 GLES |
| "Vulkan 不可用就说明 GPU 不可用" | 不成立。Vulkan 缺失时 Android 可回退 GLES（`ro.hardware.vulkan` 为空） |

> 因此**不能**从"GLES 可用"推断"Vulkan 可用"，反之亦然。

---

## 4. 一旦拿到 blob 的验证路径

若后续采集到 Vulkan ICD，按以下顺序验证（每步都给出可观测证据）：

| 步骤 | 操作 | 判据 |
| ---: | --- | --- |
| 1 | `readelf -d <icd>.so \| grep NEEDED` | 是否依赖 `libGLES_mali.so`（若是，则共用 DDK 主体） |
| 2 | `strings <icd>.so \| grep -E "^1\.[0-9]{2}$"` | 找 UK ABI 版本串（预期出现 `1.30`） |
| 3 | `readelf -n <icd>.so` | Build ID，用于与 GLES 比对是否同批构建 |
| 4 | `cat /vendor/etc/vulkan/icd.d/*.json` | ICD 入口 `library_path` 与 `api_version` |
| 5 | `dumpsys SurfaceFlinger \| grep -i vulkan` | 系统实际加载的 Vulkan 实现 |
| 6 | `strace -f -e ioctl <vk_app>` | 观察 `VERSION_CHECK` 的 major/minor 实参 |

**第 6 步是关键**：它直接观察用户态宣称的 UK ABI 版本，是 §2 推断的实证检验。

---

## 5. 结论

### 5.1 严格回答

| 任务书问题 | 答案 |
| --- | --- |
| 确认 Vulkan 驱动版本 | **无法确认**（无 blob） |
| 分析与 Kbase 的接口调用 | **无法直接分析**；但 [E2] 证明必然复用同一 UAPI |
| 检查 GPU 属性及内存管理接口 | 接口本身已审计（见 `03`§8、`03`§11），**与 Vulkan 无关地成立** |
| 检查 CSF 初始化依赖 | 与 GLES 共用；CSF 侧结论见 `02_csf_firmware_abi.md` |
| 对比 r49p1 与 R56p0 的 UAPI 差异 | 已完成（`03`§4–§8），**该对比对 Vulkan 同样有效** |
| 判断原厂 Vulkan 是否存在兼容窗口 | **条件性成立**：若 ICD 走标准 `VERSION_CHECK` 且宣称 1.30，则与 GLES 同结论 |

### 5.2 一句话

> **UAPI 层面，Vulkan 不会比 GLES 更糟**——它没有独立的接口面。真正的不确定性在于"该 ICD 是否存在"，而不在于"它是否兼容"。

### 5.3 UNKNOWN

| ID | 内容 | 补齐方式 |
| --- | --- | --- |
| U4-05 | 是否存在 Mali Vulkan ICD | 采集 `/vendor/lib64/vulkan/`、`/vendor/etc/vulkan/icd.d/` |
| U4-17 | ICD 的 `api_version` 与 `library_path` | 采集 JSON manifest |
| U4-18 | Vulkan 是否与 GLES 同批构建（Build ID 比对） | 采集两个 so 的 `readelf -n` |
| U4-19 | Vulkan 是否使用 GLES 不用的 ioctl 子集 | 实机 `strace` |
