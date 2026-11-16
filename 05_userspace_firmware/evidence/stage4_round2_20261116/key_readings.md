# 第二轮真机采集：关键读数与台账影响（2026-11-16 13:13）

> 原始报告：`stage4_remainder_20261116_131307.txt`（56,138 B，770 行，`SELFCHECK` = **668**）。
> 同一 zip 内另附 `F_mali_kbase_mt6991_r49_versions.txt`（135,468 B）、`F_ged_versions.txt`（63,660 B）。
> 证据等级：**[D·A]** = 设备上直读；**[E1]** = 源码；**[D·B]** = 设备行为（在渲染）。

---

## 1. 十二组读数

| # | 读数 | 值 | 等级 | 作用 |
| ---: | --- | --- | :---: | --- |
| 1 | 设备指纹 | `25060RK16C` / `dali` / `OS4.0.3.0.XONCNXM` / SDK 37 / `6.6.143-android15-8-gf9aa2fec23c3-4k` | **[D·A]** | 与既有基线一致，采集对象无歧义 |
| 2 | 固件 header | magic `0xC3F13A6E`、**0.3**、`version_hash 0x030A0000`、**`entry_end_offset = 1000`**、首 entry `0x2000`（INTERFACE / 32 B） | **[D·A]**+**[E1]** | U4-11 子项闭合；U4-12 阻断机制定死（见 `firmware_header.md`） |
| 3 | 固件尾部 | 末 32 B 全 `00`；尾部 4 KiB 可打印串 **0** 条 | **[D·A]** | 否掉"从尾部读 GLB 版本"的路线 |
| 4 | 内核 `build-id` | `0c637c57d1ad6f81f4de95c6dbbc92a8f9153408`（20 B，`/sys/kernel/notes` 直读） | **[D·A]** | **U4-26 闭合** |
| 5 | kbase 模块版本 | `r49p1-03bet0`、**`UK version 1.30`**、`srcversion CAC308B0D61305ACE6017E3` | **[D·A]** | UK ABI 1.30 从"源码推断"升为"设备确证" |
| 6 | **驱动版本串** | `GLES: ARM, Mali-G925-Immortalis MC12, OpenGL ES 3.2 v1.r49p1-03bet0.4505ac1771886c7c25f13653ad4cdff7` | **[D·A]** | **用户态 DDK 与内核 kbase 同为 `r49p1-03bet0`**；MC12 确证；OpenGL ES 3.2 |
| 7 | **padding / reserved 校验串** | `padding is only supported for UMM`、`Invalid reserved field not 0 in queue group create` | **[D·A]** | `D-031` 的"R49 内联校验 padding"从源码 [E1] 升为**二进制确证** |
| 8 | ioctl 55 处理函数 | `kbasep_ioctl_set_limited_core_count` 字符串存在 | **[D·A]** | 处理函数**被编入**（≠ 被调用），U4-14 证据加强 |
| 9 | **`vulkan.mali.so` 是桩** | 133,416 B；dynsym 仅 3 项；已定义函数只有 `mali_vk_vendor_stub`（**24 字节**，Ndx=13）；`DT_NEEDED` 头一项是 `libGLES_mali.so`；`RUNPATH $ORIGIN/../egl` | **[D·A]** | **U4-17 大幅收窄**：真实现在 `libGLES_mali.so`，无需 REA 分析这 133 KB |
| 10 | `libgpud` / `libgpud_sys` / `libged` 的 `DT_NEEDED` | 16 / 17 / 10 项，全表已取；`libged.so` 直接 import `ioctl` | **[D·A]** | U4-23 的 NEEDED 面闭合（符号面因脚本缺陷未取，见 `README.md` §3） |
| 11 | SF RenderEngine 后端 | `------------RE GLES (Ganesh)------------` | **[D·A]** | **U4-20 闭合**：走 GLES(Ganesh)，不是 Skia Graphite/Vulkan |
| 12 | `/vendor` 挂载 | `/vendor` = `erofs /dev/block/dm-13 ro`；`/vendor_dlkm` = `erofs dm-18 ro`；**无 overlay** | **[D·A]** | **U4-27 闭合**：本轮全部字节证据取自原厂只读镜像 |

---

## 2. 第 6 条为什么重要

`v1.r49p1-03bet0.4505ac1771886c7c25f13653ad4cdff7` 这串来自 `dumpsys SurfaceFlinger` 的 RenderEngine 段，是**用户态 GLES 驱动自报的版本**。

它与内核侧 `MODULE_VERSION` 的 `r49p1-03bet0` **逐字符相同**。此前"原厂三方（kbase / DDK / 固件）配套"是 [E1] 推理（源码里 `MODULE_VERSION` 与 DDK 内嵌串一致），现在是 **[D·A] 双侧实测**：

| 组件 | 版本串 | 来源 |
| --- | --- | --- |
| 内核 kbase | `r49p1-03bet0` | `/sys/module/mali_kbase_mt6991_r49/version` |
| 用户态 DDK | `v1.r49p1-03bet0.4505ac17...` | `dumpsys SurfaceFlinger`（RenderEngine 自报） |
| CSF 固件 | header 0.3（无版本串） | `/vendor/firmware/mali_csffw.bin` |

这直接支撑"**替换任一侧都会破坏配套**"这个判断——也正是 DDK-B 路线（R56 Kbase + R49-derived DDK）要处理的真实难点：**换 Kbase 就同时要求换固件**（header 0.4），而固件不可得（U4-12）。

---

## 3. 第 7 条为什么重要

这两条串在 `mali_kbase_mt6991_r49.ko` 的 `.rodata` 里：

```
padding is only supported for UMM
Invalid reserved field not 0 in queue group create
```

它们与 `D-031` 找出的 9 处内联校验一一对应（后者就是 `csf/mali_kbase_csf.c:1367-1370` 那个 `padding[9]` 检查的报错串）。

⇒ **R49 kbase 确实校验 padding 与 reserved，且校验代码就在设备上这份二进制里。**

这不能直接证明"R49 DDK 把 padding 清零"（那是 DDK 侧，不是 kbase 侧），但它把 §3.1 的推理链补完整：

```
R49 kbase 校验 padding[9]（offset 40–111）        ← [E1]+[D·A]（第 7 条）
            ⊃
R56 kbase 校验 padding[62]（offset 50–111）      ← [E1]
            ∧
设备在渲染（说明 R49 侧校验全部通过）             ← [D·B]（第 6 条）
            ⇒
offset 40–111 必为 0 ⇒ R56 这一关必过            ← [E2]
```

**剩余致命位仍是 `CS_QUEUE_REGISTER`**（R56 查、R49 未见校验、也未见 `{0}` 初始化证据），这一条不受第 7 条影响，U4-04c 仍是 PARTIAL。

---

## 4. 第 9 条为什么重要

`mali_vk_vendor_stub` 只有 **24 字节**，且整个 `vulkan.mali.so` 的已定义函数只有它一个。

24 字节在 aarch64 上大致就是「保存参数 → 跳到某处 → 返回」的量级。结合 `DT_NEEDED: libGLES_mali.so` 与 `RUNPATH: $ORIGIN/../egl`，可以判定：

- 这个库**不是 Vulkan 实现**，是**入口桩**；
- 真正的 `vkXXX` 实现在 `libGLES_mali.so`（53 MB）里；
- `vkAcquireImageANDROID` 在 `vulkan.mali.so` 里是 **UND**（未定义），进一步说明它靠外部提供。

**对 U4-17 的影响**：原计划"REA 分析 133 KB 薄壳找 `api_version` 来源与 ioctl 面"——**这一步可以取消**。要分析 ioctl 面，目标应改为 `libGLES_mali.so`，而它的体量与难度都远大于原估计。所以 U4-17 从 OPEN 转 PARTIAL，但**不是**因为变简单，而是因为**问题被重新定位**。

---

## 5. 第 12 条为什么重要

`mountinfo` 完整读出后，`/vendor` 与 `/vendor_dlkm` 都是 `erofs` 只读、**无 overlay 层**。overlay 只出现在 `/product`、`/system`、`/system_ext` 的若干子路径，且 `lowerdir` 指向小米自己的 `mi_ext` / `mi_product`。

⇒ 本轮采到的 `mali_csffw.bin`、`mali_kbase_mt6991_r49.ko`、`ged.ko`、`libGLES_mali.so` 相关读数**都来自原厂镜像**，不是被 root 方案替换过的版本。

这条同时给后续所有设备证据提供了一个前提：**只要 mount 表不变，设备读数就仍然代表原厂栈。**

---

## 6. 一条旁证：`mtk_gpufreq` 的 refs 组合

本轮 E-3 段（`/proc/modules`）读数：

| 模块 | size | refs | state |
| --- | ---: | ---: | --- |
| `mtk_gpufreq_mt6991` | 65,536 | **0** | Live |
| `mtk_gpufreq_wrapper` | 90,112 | **9** | Live |
| `mali_kbase_mt6991_r49` | 2,494,464 | 93 | Live |
| `ged` | 684,032 | 5 | Live |

`mtk_gpufreq_mt6991` 的 refs 为 **0**（没有任何模块通过符号引用它），而 `mtk_gpufreq_wrapper` 有 9 个引用——这与 `R49_DDK_ADAPTATION_PLAN.md` §7.1 的推论 1（`_fp` 后缀 = **运行时解析的函数指针**，非编译期强绑定）**互相印证**。

标签 **LIKELY**（不是 CONFIRMED）：refs 为 0 也可能只是该模块的导出符号未被 `EXPORT_SYMBOL` 登记，需看 `__ksymtab` 才能定论。

---

## 7. 本文件未采用的数据（脚本缺陷，见 `README.md` §3）

| 读数 | 为什么不采用 |
| --- | --- |
| `taint=0x0000000000000000`（E-3） | 实为 `/proc/modules` 第 6 列**加载地址**，被 `kptr_restrict` 清零；**不是 taint** |
| `build-id: 474e5500c5eac1f08ba2434defdeb72d2f4185c4`（D-4） | 从 note 偏移 12 读起，把 name `"GNU\0"` 当成 desc 前 4 字节；**真实 build-id 未取到** |
| `GLOBAL DEFAULT FUNC: 0`（J） | 正则顺序错误（readelf 是 `FUNC GLOBAL DEFAULT`），**假 0**；实际有导出函数 |
| `/vendor/lib64/hw/vulkan.mali.so size: 21`（J） | 符号链接，`stat -c` 取到的是链接自身长度；与 `hw/mt6991/vulkan.mali.so` 同一文件（SHA256 相同） |

以上四项**均不影响**本文 §1 的任何结论（结论只依赖字符串与数值本身，不依赖这些统计列）。
