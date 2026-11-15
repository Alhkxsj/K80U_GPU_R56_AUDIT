# 05_userspace_firmware — 用户态图形栈与 CSF 固件 ABI

> **状态：TASK 04 已交付（`efd8547`）+ 真机证据补充核验（`04-fix`）**
>
> **两种状态分开记录**：报告 ✅ 已交付；证据 ⚠️ **未闭环**（23 项 UNKNOWN，闭合 4 项 + 部分闭合 3 项）。

## 一句话结论

> **这次移植的真正边界不在用户态，而在固件。**
>
> `Kbase + CSF 固件` 是必须**成对替换的原子单元**；原厂用户态 DDK 在**契约层可以保留**（且必须**整套**保留，含 `libged`/`libgpud`）；Android 图形栈与 MTK 平台层**不直接依赖 DDK，但不是"免疫"**。

## 五个决定性事实（含本轮修订）

| # | 事实 | 证据 | 后果 |
| ---: | --- | --- | --- |
| 1 | 两版**源码要求**的固件 header：`0.3` vs `0.4`，严格 `!=`，无兼容分支 | `02` §3.1–3.2 **[E1]** | 组合 B 否决的**逻辑**成立 |
| 2 | **原厂固件实际 header 值：UNKNOWN**（字节未采）；有 E2 级启动一致性推理指向 `0.3` | `02` §3.0；`07` §4 | 组合 B 否决的**证据等级**为"高但不实测" |
| 3 | `handshake` 用 `min()` **夹取**而非校验 → 原厂 DDK 有效版本恒 ≤ 1.30 | `03` §1.5 **[E1]** + 真机模块串 **[D]** | 原厂用户态不会被抬到 1.39 语义 |
| 4 | `libGLES_mali.so` 实测 **53,105,232 B**，NEEDED **`libged` + `libgpud`** + 4 个 gralloc 私有库 | `03` §1.3；`07` §5 **[D]** | "保留用户态"= **整套保留**，不能只留一个 `.so` |
| 5 | HWC/mapper **不链接 DDK**，但都 NEEDED **`libged`** | `05` §3.2 **[D]** | "gralloc/mapper/HWC 免疫"**已撤回** |

## 交付物

| 文件 | 回答什么 |
| --- | --- |
| `01_component_inventory.md` | 双轨清点：仓库有什么 / 真机有什么 / 缺了会否定哪条结论 |
| `02_csf_firmware_abi.md` | 固件能否直接用于 r56p0（**源码判据：不能**；含三层证据拆分） |
| `03_gles_egl_abi.md` | GLES/EGL 与 Kbase 的 UAPI 契约 + 实体构成 |
| `04_vulkan_abi.md` | Vulkan（**已确认存在，是薄壳**；兼容性与 GLES 绑定） |
| `05_android_graphics_stack.md` | buffer 通路、实测依赖图、失败行为、降级 |
| `06_abi_compatibility_matrix.md` | **四组合八维矩阵 + 最终回答** |
| **`07_device_evidence.md`** | **真机证据登记：三件套解析、方法学限制、补采建议** |
| `MANIFEST.md` | 文件清单、哈希、复核命令、UNKNOWN 台账、交付 vs 闭环状态 |
| `tools/collect_device.sh` | **只读**设备采集脚本（不落地二进制） |

## 证据基础

| 级 | 内容 |
| --- | --- |
| **[D]** | 三份真机采集：`getprop` / `lsmod` / 目录枚举 / `stat`+`sha256sum` / `readelf -d/-n` / 固件 `strings` |
| **[E1]** | UAPI 头逐字段比对（21 vs 19）、固件加载器逐行对照、能力阈值表、编译器实测 `sizeof`、`.ko` 符号 |
| **[E2]** | 由 [D]+[E1] 交叉推出的结论（如"原厂固件为 0.3"） |
| **[U]** | 运行时行为：bootloop、GLB 版本、DDK 自称值 |

## 四条方法学教训

1. **比较口径决定结论**：首次扫描整个 UAPI 目录（含 JM 头）得出"5 个内存标志位消失"；改为纯 CSF 视图后变成"24/24 一致"。r56p0 是 **CSF-only 发布**。
2. **结构体不是 ABI**：`gpu_props_user_data` 568 → 592 字节，看似越界；内核实际按 `ID+value` 流序列化 + 两阶段 size 协商。
3. **同名不同义**：两版都有 `*_FLAGS_KERNEL_ONLY`，r49p1 指 bit5/7，r56p0 指 bit60–63。
4. **（本轮新增）有文件 ≠ 知道字段**：拿到了固件的路径、大小、SHA256、甚至 `strings`，**仍然不知道 offset 4 是 0x03 还是 0x04**——因为 `strings` 只输出可打印字节。这是首轮把"推理"写成"实测"的根本原因。

## 原规划子目录的去向

| 原规划 | 实际 |
| --- | --- |
| `firmware/` | 无固件实体，合并入 `02`；元数据登记于 `07` |
| `userspace/` | 无 blob 本体，契约入 `03`/`04`，实体元数据入 `07` |
| `abi_matrix/` | 合并为 `06` |
| `load_path/` | 加载链路并入 `02` §1；EGL 路径见 `03` §1.4 |

## 与相邻目录的边界

- `03_kbase_csf/` → 内核内部 CSF 机制（调度器、KCU、队列）
- `04_mtk_platform/` → MTK 平台层 15 个 `.ko`
- **本目录** → 内核**之外**的两段：固件 + 用户态，以及二者与内核的**契约**
- `06_porting_design/` → 移植方案与合规风险

## 遗留风险（按优先级）

| 风险 | 说明 | 状态 |
| --- | --- | --- |
| **U4-01**（P0） | 原厂固件 header 实际值 | **8 字节可闭合**，见 §如何补齐证据 |
| **U4-04**（P0） | DDK 自称 UK ABI / padding 清零 / props 严格校验 | 实体已在，缺版本串与反编译 |
| **U4-10**（P0） | GPU 失败后是否 bootloop | 需同型机故障注入；`sw3d=0` 是风险信号 |
| **U4-12**（P0） | R56p0 固件是否匹配 G925 MC12 | 需 Arm 固件实体 |
| **U4-22**（P1，新） | `libged` 失效对 mapper/HWC 的传导 | 新识别的耦合面 |
| `MEM_JIT_INIT` padding | 若 DDK 未清零 → tiler heap 不可用 → 可能渲染失败 | 待反编译 |

## 如何补齐证据（最小化，3 条命令）

```bash
# U4-01：固件头 8 字节（关键：offset 4 = minor，offset 5 = major）
adb shell "od -An -tx1 -N 8 /vendor/firmware/mali_csffw.bin"
#   6e 3a f1 c3 03 00 …  → 0.3（首轮结论由推理升为实测）
#   6e 3a f1 c3 04 00 …  → 0.4（首轮结论被推翻）

# U4-04：DDK 自称版本（设备内 grep，不 pull 53 MB）
adb shell "grep -a -o -m 3 -E 'UK version [0-9]+\.[0-9]+' /vendor/lib64/egl/mt6991/libGLES_mali.so"
adb shell "grep -a -o -m 3 -E 'r[0-9]{2}p[0-9]-[0-9a-z]+' /vendor/lib64/egl/mt6991/libGLES_mali.so"
```

> **不要**用 `grep mali_csffw evidence.txt` 去"看 header minor"——首轮 `README` 就是这么写的，而任何 `ls`/`sha256sum`/`strings` 输出都**不含**那个字节。这是本轮修正的一处具体错误。
>
> 脚本与上述命令**均不 pull** 任何 `.so` / `.bin`。若需 blob 本体做 REA 分析，属用户自主决定，须先评估 `06_porting_design` 的合规风险登记。
