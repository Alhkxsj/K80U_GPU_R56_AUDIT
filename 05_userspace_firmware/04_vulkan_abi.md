# 04 — Vulkan ICD 审计

> **本文件回答**：原厂 Vulkan 实现能否与 R56p0 Kbase 配合？
>
> **答案（已更新）**：**存在性已确认，兼容性无法实测。** 首轮结论是"无法判定是否存在"，那是因为只有仓库；真机采集证明 Vulkan 实现**确实存在且系统声明 1.3**，但它是一个 **133 KB 的薄壳**（唯一导出 `mali_vk_vendor_stub`，NEEDED `libGLES_mali.so`），真正驱动在 GLES 库内。
>
> 因此本文件的结论从"存在性 UNKNOWN"变为"**结构已明、行为未测**"：Vulkan 的 ABI 风险面**完全被 GLES 覆盖**，不再有独立的未知接口层。
>
> 证据等级：**[D]** 真机实测 · **[E1]** 源码 · **[E2]** 交叉推导 · **[E3]** 惯例推断 · **[U]** UNKNOWN

---

## 0. 结论摘要

| 问题 | 答案 | 等级 |
| --- | --- | --- |
| 是否存在 Mali Vulkan 实现？ | **存在**：`/vendor/lib64/hw/mt6991/vulkan.mali.so`（133,416 B） | **[D]**（U4-05 闭合） |
| 系统是否声明 Vulkan？ | **是，Vulkan 1.3 + level-1 + compute-0** | **[D]**（VINTF permission xml） |
| 实现形态？ | **薄壳**：仅导出 `mali_vk_vendor_stub`，NEEDED `libGLES_mali.so` → 主体在 GLES 库 | **[D]** |
| Vulkan 是否走同一 Kbase UAPI？ | **必然如此**——内核只有一套 GPU 接口 | **[E2]** |
| 其 ABI 兼容性判断？ | **完全复用 `03_gles_egl_abi.md`**，无独立接口面 | **[E2]**（本轮由 [D] 强化） |
| ICD 的 `api_version` / `library_path` | **UNKNOWN**（无 `icd.d/*.json`，机制未确定） | **[U]**（U4-17） |

> 首轮此处写"本文件刻意不给大概率兼容"，这个纪律仍然有效；但"存在性"不再是未知项——它已经是被测到的事实。

---

## 1. 证据状态

### 1.1 仓库 vs 真机（首轮把两者混为一谈）

| 对象 | 期望路径 | 仓库 | 真机 |
| --- | --- | :---: | --- |
| Vulkan 厂商模块 | `/vendor/lib64/hw/vulkan.<name>.so` | **不存在** | ✅ `/vendor/lib64/hw/mt6991/vulkan.mali.so` |
| Vulkan loader | `/system/lib64/libvulkan.so` | **不存在** | ✅ 308,040 B，API 37 |
| ICD manifest | `/vendor/etc/vulkan/icd.d/*.json` | **不存在** | ❌ 同 |
| 选择属性 | `ro.hardware.vulkan` | 不可知 | ✅ **`mali`** |
| VINTF 声明 | `/vendor/etc/permissions/*vulkan*` | **不存在** | ✅ 4 个 xml |

> 首轮把左两列当成"世界状态"，得出"无法判定是否存在"。**仓库的缺失只能说明仓库缺失**——这是本轮最重要的方法学纠正之一。

### 1.2 实测明细（[D]）

| 项 | 值 |
| --- | --- |
| 路径 | `/vendor/lib64/hw/mt6991/vulkan.mali.so` |
| 大小 | 133,416 B |
| SHA256 | `336acc0fe5d8e425c0ef337979b576437fd9209e53307a311f6d5f3a6b9de991` |
| SONAME | `vulkan.mali.so` |
| `.note.android.ident` | API level 35 |
| Build ID | `9b2f75009917c80b` |
| `DT_NEEDED` | `libGLES_mali.so` + libc++/libc/libm/libdl（**仅此 5 项**） |
| 导出符号（采集中出现的） | **仅 1 个：`mali_vk_vendor_stub`** |

### 1.3 结构判读：这不是 ICD，是"厂商模块薄壳"

| 观察 | 推论 | 等级 |
| --- | --- | --- |
| 133 KB vs GLES 的 53 MB | 不含编译器/运行时主体 | [D] |
| 唯一非 libc 依赖是 `libGLES_mali.so` | 运行时把调用转发给 GLES 库内的 Vulkan 实现 | [E2] |
| 导出名 `mali_vk_vendor_stub`（而非 `vk_icdGetInstanceProcAddr`） | **不是标准 ICD 入口**，是 MTK 自定义的厂商分发点 | [E2] |
| 存在 `ro.hardware.vulkan=mali` + `hw/vulkan.mali.so`，但**无 `icd.d/*.json`** | 走的是 **hw-module 路径**（`vulkan.<ro.hardware.vulkan>.so`），不是 AOSP 10+ 的 ICD json 路径 | [E2] |
| `/system/lib64/libvulkan.so` NEEDED **`libgpud_sys.so`** | 系统 Vulkan loader 被 MTK/Xiaomi 改过，额外挂 GPU 数据面 | [D] |

> **由此得出一条对移植有实际意义的结论**：Vulkan **没有独立的内核契约**，也没有独立的驱动器——它就是 GLES 库的另一个入口。因此：
> - 组合 C 里"Vulkan 能否用"这个问题**不存在**：Vulkan 与 GLES 同生共死；
> - 但 `libvulkan.so` → `libgpud_sys.so` 这条额外依赖，是**系统侧**的耦合，换 kbase 不影响它，换 system 镜像才会。

### 1.4 `libvulkan.so` 与 `libgpud_sys.so` 的符号关系（[D]）

```
/system/lib64/libvulkan.so (API 37)
  NEEDED  libgpud_sys.so          ← /system_ext/lib64/
  UND     gpudInitialize
  UND     gpudVkDumpPresentFrame
  UND     g_gpud_context
  EXPORT  vk*（每个 16 B 的跳板桩，共 40+ 个，如 vkAllocateMemory@0x252c0）
```

| 判读 | 内容 |
| --- | --- |
| `vk*` 导出体积极小（16 B） | 典型 PLT/GOT 跳板 → 真正实现在别处（ICD） |
| 对 gpud 的依赖是 **present 阶段**（`gpudVkDumpPresentFrame`） | MTK 的抓帧/性能工具插在**呈现**路径上，而非命令提交路径 |
| 与 GLES 侧的 `gpud*` 引用（80+ 个 `gpudVkCmd*`/`gpudVk*`）不同 | 两侧用的是**同一套 API 的不同子集**：GLES 库插在命令流，loader 插在呈现 |

> 另记一处**同名符号双库**现象：`/vendor/lib64/libgpud.so`（GLES 依赖）与 `/system_ext/lib64/libgpud_sys.so`（libvulkan 依赖）都提供 `gpudInitialize`/`g_gpud_context`。二者处于不同 linker namespace，是否互相干扰**未验证**，登记为观察项而非结论。

### 1.5 可用的间接线索（首轮遗留）

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
| "MediaTek 设备都用 Mali Vulkan" | 不成立。MTK 部分平台使用 **Imagination PowerVR**；**本机已实测为 Mali**（`ro.hardware.vulkan=mali` + `vulkan.mali.so`），但这是**本机型**的结论，不可外推 |
| "有 `libGLES_mali.so` 就一定有 Vulkan" | 逻辑上不成立（可只发 GLES）；**本机实测确实有**，且是薄壳 |
| "Vulkan 不可用就说明 GPU 不可用" | 不成立。Vulkan 缺失时 Android 可回退 GLES（`ro.hardware.vulkan` 为空） |
| "Vulkan 是独立驱动，需要单独验证" | **本机不成立**：薄壳 + NEEDED `libGLES_mali.so` → 无独立驱动主体 |

> 本轮把三条"惯例判断"换成了"本机实测"，同时保留"不可外推到其他 MTK 机型"的限定。

---

## 4. 验证路径（第 1–3 步已用现有采集完成）

| 步骤 | 操作 | 判据 | 状态 |
| ---: | --- | --- | --- |
| 1 | `readelf -d <vulkan 模块> \| grep NEEDED` | 是否依赖 `libGLES_mali.so` | ✅ **已完成：是，唯一非 libc 依赖** |
| 2 | `strings <libGLES_mali.so> \| grep -E "^1\.[0-9]{2}$"` | 找 UK ABI 版本串 | ❌ 未做（`readelf` 只有动态段） |
| 3 | `readelf -n <so>` | Build ID，用于与 GLES 比对 | ✅ **已完成**：`9b2f75009917c80b` |
| 4 | `cat /vendor/etc/vulkan/icd.d/*.json` | ICD 入口 `library_path` 与 `api_version` | ❌ 该目录不存在 |
| 5 | `dumpsys SurfaceFlinger \| grep -i vulkan` | 系统实际加载的 Vulkan 实现 | ❌ 需 root |
| 6 | `strace -f -e ioctl <vk_app>` | 观察 `VERSION_CHECK` 的 major/minor 实参 | ❌ 需 root |

**第 6 步仍是关键**：它直接观察用户态宣称的 UK ABI 版本，是 §2 推断的实证检验。第 2 步可用设备内 `grep -a` 完成，不需 pull 53 MB（见 `07` §10.2）。

---

## 5. 结论

### 5.1 严格回答

| 任务书问题 | 答案 |
| --- | --- |
| 确认 Vulkan 驱动版本 | **部分确认**：系统声明 Vulkan **1.3**（VINTF `vulkan.version-1_3` + `deqp.level-2024-03-01`）；`api_version` 字段**未取** |
| 分析与 Kbase 的接口调用 | **无独立接口调用**——Vulkan 经 `libGLES_mali.so` 进入同一套 ioctl；[E2] 成立且被 [D] 强化 |
| 检查 GPU 属性及内存管理接口 | 接口本身已审计（见 `03`§8、`03`§11），**与 Vulkan 无关地成立** |
| 检查 CSF 初始化依赖 | 与 GLES 共用；CSF 侧结论见 `02_csf_firmware_abi.md` |
| 对比 r49p1 与 R56p0 的 UAPI 差异 | 已完成（`03`§4–§8），**该对比对 Vulkan 同样有效** |
| 判断原厂 Vulkan 是否存在兼容窗口 | **存在**：因其无独立接口面，结论与 GLES 完全绑定；实际可用性仍待实机 |

### 5.2 一句话

> **Vulkan 是 GLES 的影子**——本机实测为 133 KB 薄壳 + NEEDED `libGLES_mali.so`，唯一导出名是 MTK 自定义的 `mali_vk_vendor_stub`。因此"Vulkan 兼容性"不是一个独立问题：**GLES 通，Vulkan 通；GLES 不通，Vulkan 无从谈起。**

### 5.3 UNKNOWN

| ID | 内容 | 补齐方式 | 现状 |
| --- | --- | --- | --- |
| ~~U4-05~~ | ~~是否存在 Mali Vulkan ICD~~ | — | ✅ **已闭合：存在（薄壳 + 系统声明 1.3）** |
| U4-17 | 薄壳的 `api_version` / 加载机制（hw-module vs `icd.d`） | `dumpsys` / `ld.config` / 反编译 `mali_vk_vendor_stub` | 开放（P1） |
| U4-18 | Vulkan 与 GLES 是否同批构建 | Build ID 比对：`700e6d41…`(GLES) vs `9b2f7500…`(vulkan.mali) — **已取到，但缺构建时间戳无法判定同批** | 降 P3 |
| U4-19 | Vulkan 是否用 GLES 不用的 ioctl | 实机 `strace`（需 root） | 开放（P2） |
| **U4-23**（新增） | `libgpud.so` 与 `libgpud_sys.so` 同名符号是否冲突 | 实机 `dlopen` 观察 / namespace 检查 | 新增（P3） |
