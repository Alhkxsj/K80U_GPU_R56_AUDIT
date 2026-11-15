# 05_userspace_firmware — 用户态图形栈与 CSF 固件 ABI

> **状态：TASK 04 已交付**（2026-11-15）。本目录不再是规划占位。

## 一句话结论

> **这次移植的真正边界不在用户态，而在固件。**
>
> `Kbase + CSF 固件` 是必须**成对替换的原子单元**；原厂用户态 DDK 在**契约层可以保留**；Android 图形栈（gralloc/mapper/HWC）与 MTK 平台层基本不受影响。

## 三个决定性事实

| # | 事实 | 证据 | 后果 |
| ---: | --- | --- | --- |
| 1 | **固件 header 0.3 ≠ 0.4**，严格 `!=` 检查，无兼容分支 | `02_csf_firmware_abi.md` §3 | **组合 B（只换内核）确定不可行** |
| 2 | **UK ABI 能力表显式为 1.30 保留旧语义**（1.31/1.32/1.35 新能力在 1.30 下全部不生效） | `03_gles_egl_abi.md` §3 | 原厂用户态会走"旧版本路径"，而这些路径被完整保留 |
| 3 | **ioctl 28/28 逐字相同、结构体 30/30 兼容、属性 ID 83/83 不变** | `03_gles_egl_abi.md` §4–§8 | 契约层兼容，用户态可保留 |

## 交付物

| 文件 | 回答什么 |
| --- | --- |
| `01_component_inventory.md` | 有哪些资产、缺哪些、缺了会否定哪条结论 |
| `02_csf_firmware_abi.md` | 固件能否直接用于 r56p0（**不能**，附完整加载流程） |
| `03_gles_egl_abi.md` | GLES/EGL 与 Kbase 的 UAPI 契约逐项比对 |
| `04_vulkan_abi.md` | Vulkan ICD 的存在性与兼容性（证据不足，明确圈定） |
| `05_android_graphics_stack.md` | GPU buffer 通路、组件耦合度、失败行为 |
| `06_abi_compatibility_matrix.md` | **四组合八维矩阵 + 最终回答** |
| `MANIFEST.md` | 文件清单、SHA256、可复核命令、UNKNOWN 台账 |
| `tools/collect_device.sh` | **只读**设备采集脚本（不落地二进制） |

## 证据基础

1. **UAPI 头文件逐字段比对**（[E1]）：r49p1 `include/uapi/**`（21 个）vs r56p0 `product/kernel/include/uapi/**`（19 个）
2. **固件加载器逐行对照**（[E1]）：两版 `csf/mali_kbase_csf_firmware.c`
3. **能力阈值表**（[E1]）：`mali_kbase_core_linux.c:148-166`
4. **编译器实测**（[E1]）：`gcc` 提取 `gpu_props_user_data` 并 `sizeof`/`offsetof`
5. **内核二进制符号**（[E1]）：`mali_kbase_mt6991_r49.ko` 的 18 个 dma-buf/dma-fence UND 引用

## 三条方法学教训

1. **比较口径决定结论**：首次扫描整个 UAPI 目录（含 JM 头）得出"5 个内存标志位消失"；改为纯 CSF 视图后变成"24/24 一致"。r56p0 是 **CSF-only 发布**，把 JM 头当基线会系统性高估差异。

2. **结构体不是 ABI**：`gpu_props_user_data` 从 568 → 592 字节，看似越界；但内核实际按 `ID+value` 流序列化，且有两阶段 size 协商。**结构体大小不等于跨界数据量**。

3. **同名不同义**：两版都有 `*_FLAGS_KERNEL_ONLY`，r49p1 指 bit5/7，r56p0 指 bit60–63。按名字比对会得出完全错误的"用户态传 bit5 会被拒"。

## 原规划子目录的去向

| 原规划 | 实际 |
| --- | --- |
| `firmware/` | 无固件实体，合并入 `02` |
| `userspace/` | 无 blob，契约分析入 `03`/`04` |
| `abi_matrix/` | 合并为 `06` |
| `load_path/` | 加载链路并入 `02` §1 |

## 与相邻目录的边界

- `03_kbase_csf/` → 内核内部 CSF 机制（调度器、KCU、队列）
- `04_mtk_platform/` → MTK 平台层 15 个 `.ko`
- **本目录** → 内核**之外**的两段：固件 + 用户态，以及二者与内核的**契约**
- `06_porting_design/` → 移植方案与合规风险

## 遗留风险（按优先级）

| 风险 | 说明 | 状态 |
| --- | --- | --- |
| **U4-01/04/10/12（4 项 P0）** | 固件实际 minor、DDK 实际行为、失败是否 bootloop、r56p0 固件是否匹配 G925 MC12 | 待采集 |
| `MEM_JIT_INIT` padding 校验 | 若 DDK 未清零 → tiler heap 不可用 → **可能渲染失败** | 待反编译 |
| 固件 0.4 的调度默认值 | 1.30 DDK 的性能假设可能失效（表现为性能异常而非功能故障） | 待实机 |

## 如何补齐证据

```bash
# 1. 采集元数据（只读，不导出二进制）
adb push tools/collect_device.sh /data/local/tmp/
adb shell su -c 'sh /data/local/tmp/collect_device.sh' > evidence.txt

# 2. 重点核对三项
grep -A6 "mali_csffw" evidence.txt        # header minor = 3 ?
grep -iE "libGLES_mali|libEGL_mali" evidence.txt
grep -iE "vulkan" evidence.txt            # ICD 是否存在
```

> 脚本**不 pull** 任何 `.so` / `.bin`。若需 blob 本体做 REA 分析，属用户自主决定，须先评估 `06_porting_design` 的合规风险登记。
