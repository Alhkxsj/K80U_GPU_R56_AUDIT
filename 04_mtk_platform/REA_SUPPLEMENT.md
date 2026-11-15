# TASK 03-REA：MT6991 原厂 GPU 平台二进制逆向补充审计

> 对 `TASK 03` 中依赖 ELF 符号分析、头文件比对或静态推断得出的结论，用反编译与交叉引用做定点复核。
> **性质**：只读。未修改任何 `.ko`、未修改 r49p1 / r56p0 源码、未生成补丁、未编译、未部署。
> **日期**：2026-11-15　**基线**：`56340bb`（TASK 03 提交）

---

## 0. 摘要

本轮共反编译 **12 个 `.ko`、5,440 个函数**（写出 4,533 个函数体），取得 4 项实质修正，并新增 7 项风险（含 1 项 P0）：

| # | 对象 | TASK 03 原判断 | 本轮结果 | 状态 |
| ---: | --- | --- | --- | --- |
| 1 | `gpufreq_fp` 表长度 | 72 B / 9 项 | **416 B / 52 项**（0x1a0） | **CORRECTED** |
| 2 | MGM `ops` 结构大小 | 7 项 56 B | **72 B** = 7 函数 + `data`@0x38 + `owner`@0x40 | **CORRECTED** |
| 3 | MGM 第 7 槽位错配后果 | "让不该缓存的判为允许缓存" | 非恒定错误：非零→允许缓存（= r56p0 默认），**池为空时→禁止缓存**（偏离默认） | **CORRECTED** |
| 4 | GED 未被引用导出数 | 115 | **114**（漏计 `mtk_gpu_pdma` 的 2 个引用） | **CORRECTED** |
| 5 | — | 未记录 | **kCFI 类型哈希校验**：替换任何表成员都必须保持原型一致，否则 `brk #0x8228` | **NEW P0** |

另有 3 项**直接确证**（电源回调链、MGM `update_gpu_pte` ABI、AP/IPI 双路径判据），6 项 UNKNOWN 部分或完全闭合。

**最重要的一条**：`gpufreq_fp` 是 52 项的表，不是 9 项。若按 TASK 03 的 9 项口径去复制结构体，会**欠分配 360 字节**，第 15 槽位的 init 回调直接越界。

---

## 1. REA 工具能力与实际使用情况

### 1.1 实际部署形态

| 组件 | 版本 | 路径 | 说明 |
| --- | --- | --- | --- |
| `rea-agents` | 6.9.0 | `/opt/node24/bin/rea` | CLI + MCP server（255 tools） |
| Node.js | 24.22.3 | `/opt/node24` | 系统 22.13.1 不满足 `>=22.23.4` |
| Ghidra | 12.2 | `/opt/ghidra_12.2_PUBLIC` | 唯一可用原生分析引擎（Linux） |
| OpenJDK | 25.0.5 | `/usr/lib/jvm/java-25-openjdk-amd64` | Ghidra 12.2 硬性要求 JDK 25+ |
| binutils-aarch64 | 2.42 | `/usr/bin/aarch64-linux-gnu-*` | 补齐 `objdump -d` 的 aarch64 后端 |

### 1.2 本轮实际用到的能力

| 能力 | 命令 | 用途 |
| --- | --- | --- |
| 模块元数据 | `rea inspect-kernel-module` | `.modinfo` / `__versions` 布局 / 签名尾 |
| 全量反编译 | `rea decompile-all` | 12 个模块 → 4,533 个函数体文件 |
| 单函数反编译 | `rea decompile --procedure` | 按符号名精确取证（probe 等未被批量导出的函数） |
| 符号/重定位 | `readelf -sW` / `-rW` | 导出识别、函数指针表还原 |
| 地址换算 | `aarch64-linux-gnu-nm` | Ghidra vaddr ↔ ELF 偏移 |

### 1.3 能力边界（实测）

1. **`.ko` 导出符号查不到**：`inspect-native-exports` 返回空数组。原因是内核模块导出在 `__ksymtab` 而非 `.dynsym`，REA 的 limitations 明确声明不解析 `__ksymtab`。**导出分析必须用 `readelf -sW`**。
2. **`decompile-all` 不覆盖全部函数**：MGM 132 个函数中写出 95 个函数体（其余为 stub / thunk / 无 body）；kbase 3,007 个中写出 2,564 个。`memory_group_manager_probe` 即需用 `--procedure` 单独取。
3. **反编译不含注释与原始变量名**，结构体字段只能按偏移推断，无法恢复字段名——本报告因此只写 `slot[n]` 与偏移，不编造名称。

### 1.4 地址换算表（Ghidra vaddr ↔ ELF `.text` 偏移）

Ghidra 将各 allocatable 节顺序拼接后分配地址空间，与 `nm` 的 `.text` 内偏移相差固定常量：

```
elf_text_offset = ghidra_vaddr − delta
```

| 模块 | delta | 模块 | delta |
| --- | ---: | --- | ---: |
| `mali_mgm_mt6991_r49` | `0x100a58` | `ged` | `0x10e7b8` |
| `mali_kbase_mt6991_r49` | `0x1240e8` | `mtk_gpueb` | `0x101380` |
| `mtk_gpufreq_wrapper` | `0x101698` | `mtk_gpu_hal` | `0x100dc0` |
| `mtk_gpufreq_mt6991` | `0x100928` | `mtk_gpu_qos` | `0x1002f0` |
| `mtk_gpu_power_throttling` | `0x100678` | `mali_prot_alloc_mt6991_r49` | `0x100190` |
| `mtk_gpu_pdma_mt6991` | `0x100490` | `mtk_gpu_iommu_mt6991` | `0x1000d0` |

> 常量由「同一符号的 Ghidra 地址减 `nm` 值」取众数得到，命中率 56/58 ~ 1084/1084，个别离群值来自 `.init.text` / `.exit.text` 节。

---

## 2. 分析对象清单

路径：`01_original_baseline/kernel_ref_mt6991/vendor_dlkm/`

| 文件 | 字节 | SHA256（前 16） | 分析函数 | 写出函数体 | 耗时 |
| --- | ---: | --- | ---: | ---: | ---: |
| `mali_kbase_mt6991_r49.ko` | 2,310,424 | `c5ebca1c2a8be8e8` | 3,007 | 2,564 | 122 s |
| `ged.ko` | 1,093,352 | `f53e8c6833e82d8f` | 1,478 | 1,281 | 81 s |
| `mtk_gpufreq_wrapper.ko` | 151,736 | `86e52c00daae6d11` | 170 | 131 | 33 s |
| `mtk_gpueb.ko` | 128,560 | `29a61def07bf31f6` | 197 | 140 | 13 s |
| `mtk_gpufreq_mt6991.ko` | 118,368 | `939e68b8a5d58376` | 109 | 86 | 28 s |
| `mtk_gpu_hal.ko` | 58,968 | `a2a3e56a50c3477c` | 63 | 55 | 16 s |
| `mali_mgm_mt6991_r49.ko` | 55,696 | `22d3f50867d0bf1c` | 132 | 95 | 25 s |
| `mtk_gpu_pdma_mt6991.ko` | 40,512 | `91d66e2e81b4d452` | 79 | 50 | 11 s |
| `mtk_gpu_power_throttling.ko` | 38,288 | `4a226ec226a1e9a4` | 77 | 55 | 16 s |
| `mtk_gpu_qos.ko` | 33,376 | `2830bec88492e519` | 61 | 37 | 24 s |
| `mali_prot_alloc_mt6991_r49.ko` | 21,080 | `4dc0f482a5d6631d` | 57 | 32 | 12 s |
| `mtk_gpu_iommu_mt6991.ko` | 12,840 | `5f79e6e44c4ba836` | 10 | 7 | 12 s |
| **合计** | 4,063,200 | — | **5,440** | **4,533** | 393 s |

完整 SHA256 见 §2.1。

### 2.1 完整哈希

```
c5ebca1c2a8be8e8a93dadc6efd2f4cc2012de224ad0144b708114247a53e03b  mali_kbase_mt6991_r49.ko
f53e8c6833e82d8fdb94aa5b97240b738943b7b5194fd2d43f2c9b7543f15cb5  ged.ko
86e52c00daae6d1152790e8ec70e2f5b22c24a464fd44715da109a6682db1d0c  mtk_gpufreq_wrapper.ko
939e68b8a5d583763ba87cd923ec14e9af07bdc2be1a030372d7fea8cc66541c  mtk_gpufreq_mt6991.ko
29a61def07bf31f671abc43a485073d41c1b44d759ba308ca49a3e31947ea656  mtk_gpueb.ko
a2a3e56a50c3477c8b9c292240e78d720aede499d5c3332c2bd4b4ec72781620  mtk_gpu_hal.ko
22d3f50867d0bf1c73b862d731d874fcb448676de9f9ab552ce94e86875aa9bb  mali_mgm_mt6991_r49.ko
4a226ec226a1e9a4f1744810e3bd8055b5b30376b4e48a9bebd853a28f42d28e  mtk_gpu_power_throttling.ko
91d66e2e81b4d452ded7dd963ef47b6b39fce9be3d15a341fac94c42cf8e9ff6  mtk_gpu_pdma_mt6991.ko
2830bec88492e519b97bf71008f6ab8b8003a9f547c471d83361bcce06fd7398  mtk_gpu_qos.ko
4dc0f482a5d6631d31304009aa72395e32ba6e46504eebd22e832d7f7bb6a3fc  mali_prot_alloc_mt6991_r49.ko
5f79e6e44c4ba8361e5e5599f5975ba41b2fb9e1d9656e189ebd3dd78d10caba  mtk_gpu_iommu_mt6991.ko
```

逆向产物存放于 `/workspace/_rea_analysis/<module>/`（`functions/*.c` + `decompile-index.json` + `decompile-journal.jsonl`），**未纳入仓库**，可由 `mali_kbase_mt6991_r49.ko` 等原文件完整重放。

---

## 3. GPUFreq 函数表恢复（P0-1）

### 3.1 注册即保存指针，不复制结构体

`mtk_gpufreq_wrapper.ko`，`gpufreq_register_gpufreq_fp` @ `0x104580`（ELF `.text` 偏移 `0x2ee8`）：

```c
void gpufreq_register_gpufreq_fp(long param_1) {
  if (param_1 == 0) { printk(..., "gpufreq_register_gpufreq_fp"); }
  else {
    pcVar1 = *(code **)(param_1 + 0x78);      /* slot[15] */
    gpufreq_fp = param_1;                     /* 仅保存指针 */
    if (pcVar1 != NULL) {
      if (*(int *)(pcVar1 - 4) != 0x004b35c1) /* kCFI 类型哈希 */
        SoftwareBreakpoint(0x8228);           /* ← CFI 失败陷阱 */
      (*pcVar1)(g_shared_status);             /* init 回调，传 shared_status */
    }
  }
}
```

**直接证据**：
- 表中偏移 `0x78` 处的成员在注册完成后**立即被调用**，实参是 `g_shared_status` → 该槽位语义为 **`init(shared_status)`**。
- 全局只有 `gpufreq_fp` 一个指针，`mtk_gpufreq_mt6991.ko` 侧传入的表在注册后**保持原址**，不被拷贝。

`gpufreq_register_gpuppm_fp` @ `0x1045ec`（偏移 `0x2f54`）同构，但：
- 取的是 `param_1 + 0x40`（`slot[8]`），同样 kCFI 校验后调用；
- 注册后额外挂接：`register_pbm_gpu_notify`、`register_devapc_power_callback` ×2、`register_devapc_exception_callback`、`gpufreq_debug_init`。

### 3.2 表的真实长度：52 项 / 416 字节

对全部 170 个 wrapper 函数扫描 `gpufreq_fp + 0xNN` 的访问，偏移集合为：

```
0x028 0x030 0x038 0x040 0x048 0x050 0x058 0x060 0x068 0x070
0x088 0x090 0x098
0x0e8 0x0f0 0x0f8 0x100 0x108 0x110 0x118
0x168 0x170 0x178 0x180 0x188
0x198
```

最大偏移 `0x198` + 8 = **`0x1a0` = 416 字节 = 52 项**。

这与 TASK 03 §8 里那条「另一处 416 B 同名项语义不明」**是同一个东西**——不是"另一处"，就是 `gpufreq_fp` 本身。TASK 03 同时记录的「72 B = 9 项」实际是 **`gpuppm_fp`** 的尺寸，两者被混为一谈。

### 3.3 槽位语义（22 项已由调用点确证）

| slot | 偏移 | 调用者 | 推断语义 | 置信度 |
| ---: | ---: | --- | --- | --- |
| 0 | `0x000` | `gpufreq_commit` | `commit(target, freq)`（`gpuppm_fp`，见 §3.4） | 直接 |
| 2 | `0x010` | `gpufreq_set_limit` | `set_limit(...)`（`gpuppm_fp`） | 直接 |
| 3 | `0x018` | `gpufreq_switch_limit` | `switch_limit(...)`（`gpuppm_fp`） | 直接 |
| 5 | `0x028` | `gpufreq_power_control` | `power_ctrl(on)` | 直接 |
| 6 | `0x030` | `gpufreq_active_sleep_control` | `active_sleep_ctrl(...)` | 直接 |
| 7 | `0x038` | `gpufreq_dump_infra_status_no_lock` | `dump_infra_1(...)` | 直接 |
| 8 | `0x040` | `gpufreq_dump_infra_status_no_lock` | `dump_infra_2(...)` | 直接 |
| 9 | `0x048` | `gpufreq_bus_tracker_vio_callback` | `bus_tracker_vio(...)` | 直接 |
| 10 | `0x050` | `gpufreq_set_mfgsys_config` | `set_mfgsys_config(...)` | 直接 |
| 11 | `0x058` | `gpufreq_get_core_mask_table` | `get_core_mask_table(...)` | 直接 |
| 12 | `0x060` | `gpufreq_get_core_num` | `get_core_num(...)` | 直接 |
| 13 | `0x068` | `gpufreq_pdca_config` | `pdca_config(...)` | 直接 |
| 14 | `0x070` | `gpufreq_update_debug_opp_info` | `update_debug_opp_info(...)` | 直接 |
| 15 | `0x078` | `gpufreq_register_gpufreq_fp` | **`init(shared_status)`** | 直接 |
| 17 | `0x088` | `gpufreq_fix_dual_target_oppidx` | `fix_dual_target_oppidx(...)` | 直接 |
| 18 | `0x090` | `gpufreq_fix_dual_custom_freq_volt` | `fix_dual_custom_freq_volt(...)` | 直接 |
| 19 | `0x098` | `gpufreq_dual_commit` | `dual_commit(...)` | 直接 |
| 29 | `0x0e8` | `gpufreq_get_freq_by_idx` | `get_freq_by_idx(...)` | 直接 |
| 30 | `0x0f0` | `gpufreq_get_power_by_idx` | `get_power_by_idx(...)` | 直接 |
| 31 | `0x0f8` | `gpufreq_get_oppidx_by_freq` | `get_oppidx_by_freq(...)` | 直接 |
| 32 | `0x100` | `gpufreq_get_leakage_power` | `get_leakage_power(...)` | 直接 |
| 33 | `0x108` | `gpufreq_get_dynamic_power` | `get_dynamic_power(...)` | 直接 |
| 34 | `0x110` | `gpufreq_fix_target_oppidx` | `fix_target_oppidx(...)` | 直接 |
| 35 | `0x118` | `gpufreq_fix_custom_freq_volt` | `fix_custom_freq_volt(...)` | 直接 |
| 45–49 | `0x168`–`0x188` | 同 slot 29–33 的调用者 | **第二组**（STACK / 双 buck 路径） | 推断 |
| 51 | `0x198` | `gpufreq_fix_custom_freq_volt` | 第二组 `fix_custom_freq_volt` | 推断 |

**未观测到的槽位**：1, 4, 16, 20–28, 36–44, 50。这些在本模块内**无访问点**，语义 UNKNOWN。不能因为"表长 52"就假设它们都有成员——空洞可能来自对齐或保留区。

> slot 45–49 与 29–33 的调用者完全重叠，且 `gpufreq_commit` 里有 `g_dual_buck ? 2 : 1` 的 target 选择逻辑，倾向判断为「GPU / STACK 两套同构子表」。**这是推断，不是直接证据。**

### 3.4 AP 直写与 GPUEB IPI 的分叉点

`gpufreq_power_control` @ `0x102e5c`（偏移 `0x17c4`）：

```c
if (g_shared_status == 0) return 0;
if (*(int *)(g_shared_status + 0xcc) == 0) return 0;      /* power_ctrl_enable 标志 */

if (g_gpueb_support == 0 || g_gpufreq_ready == 0) {        /* ── 路径 A：AP 直写 */
    pcVar5 = *(code **)(gpufreq_fp + 0x28);                /* slot[5] */
    if (CFI_ok(pcVar5)) return (*pcVar5)(param_1);         /* → mtk_gpufreq_mt6991 */
    printk(...); return -2;
} else {                                                   /* ── 路径 B：IPI */
    spin_lock_irqsave(&gpufreq_ipi_lock);
    local_58 = 0x6_00000000;                               /* IPI ID = 6 */
    local_48 = param_1;
    iVar3 = gpufreq_ipi_to_gpueb(&local_58);
    iVar4 = g_recv_msg._16_4_;                             /* 返回值在 msg[4] */
    spin_unlock_irqrestore(...);
    if (iVar3 != 0) iVar4 = -0x16;
}
```

`gpufreq_commit` @ `0x10318c`（偏移 `0x1af4`）：

```c
if ((g_gpueb_support == 0) || ((g_gpufreq_ready & 1) == 0)) {
    pcVar6 = (code *)*gpuppm_fp;                           /* slot[0] */
    iVar4 = (*pcVar6)(uVar5, param_2);                     /* → commit(target, freq) */
} else {
    local_68 = 0x8_00000000;                               /* IPI ID = 8 */
    local_60 = uVar5;  local_58 = param_2;
    gpufreq_ipi_to_gpueb(&local_68);
}
```

**判据统一**：`g_gpueb_support == 0 || g_gpufreq_ready == 0` → AP 直写；否则走 IPI。

### 3.5 两套 IPI 通道的参数差异（新建对照）

| 项 | wrapper `gpufreq_ipi_to_gpueb` | GED `ged_to_fdvfs_command` |
| --- | --- | --- |
| 函数地址 | `0x102780` | `0x13d4f0` |
| 通道变量 | `g_ipi_channel` | `g_fast_dvfs_ipi_channel` |
| 消息长度 | **8 × u32（32 B）** | **6 × u32（24 B）** |
| 超时 | **10000 ms** | **2000 ms** |
| 前置校验 | `msg[1] < 0x13`（IPI ID < 19） | `cmd < 0x11` 且 `(1<<cmd) & 0x7bca` |
| 失败返回 | `-0x16`（-22） | `-2` / 原样透传 |

`0x7bca` = bit 1,3,6,7,8,9,10,12,13,14 —— GED 只允许这 10 个 DVFS 命令进入 IPI，**其余命令在 GED 内被静默丢弃**（函数返回时未置错误）。

> 这条差异直接构成一个移植风险：若把 GED 的 6-word 消息布局套到 wrapper 的 8-word 通道上，后 2 个 word 会读到栈上残留值。

### 3.6 错误路径（直接证据）

| 场景 | 行为 | 证据 |
| --- | --- | --- |
| 注册时 `param_1 == 0` | `printk` 告警，不置全局指针 | `0x104580`/`0x1045ec` 首分支 |
| 表中 `slot[5]` 为空 | `printk` + 返回 `-2` | `0x102e5c` |
| `gpuppm_fp` 为空 / `slot[0]` 为空 | `printk` + 返回 `-2` | `0x10318c` |
| IPI 发送失败 | 返回 `-0x16` | `0x102e5c` |
| IPI ID 越界 | 返回 `-0x16` | `0x102780` |
| `power_ctrl_enable == 0` | **静默返回 0**（视为成功） | `0x102e5c` |

最后一条值得注意：`g_shared_status + 0xcc` 为 0 时，`gpufreq_power_control` **返回成功但不做任何事**。这是 TASK 03 §3.2 里 `!gpufreq_power_ctrl_enable() ? → return 0` 的二进制对应，确证存在。

---

## 4. MGM ops 表逆向（P0-2）

### 4.1 结构体真实布局：72 字节

`mali_mgm_mt6991_r49.ko`，`memory_group_manager_probe` @ `0x101180`（偏移 `0x728`）：

```c
puVar4 = kmalloc_trace(_kmalloc_trace, 0xdc0, 0x48);   /* ← 72 字节 */
if (!puVar4) return -12;

puVar4[0] = example_mgm_alloc_page;                    /* 0x00 */
puVar4[1] = example_mgm_free_page;                     /* 0x08 */
puVar4[2] = example_mgm_get_import_memory_id;          /* 0x10 */
puVar4[3] = example_mgm_update_gpu_pte;                /* 0x18 */
puVar4[4] = example_mgm_pte_to_original_pte;           /* 0x20 */
puVar4[5] = example_mgm_vmf_insert_pfn_prot;           /* 0x28 */
uVar9 = _kthread_create_worker;
puVar4[6] = mgmm_cache_pool_size;                      /* 0x30 ← 第 7 槽位 */
...
puVar4[7] = puVar5;                                    /* 0x38 = 私有数据 */
puVar4[8] = &__this_module;                            /* 0x40 = owner */

*(undefined8 **)(param_1 + 0xa8) = puVar4;             /* platform drvdata */
```

**结论**：

```c
struct {                              /* 总 0x48 = 72 B */
    /* ops: 7 × 8 = 56 B */           /* 0x00 … 0x37 */
    void *data;                       /* 0x38 */
    struct module *owner;             /* 0x40 */
};
```

- TASK 03 说「ops 7 项 56 B」——**这是对的**，`ops` 子结构确实是 56 B。
- 但整个 `memory_group_manager_device` 是 **72 B**，不是 56 B。移植时按 56 B 分配会丢失 `data` 指针，`mgmm_cache_pool_size` 里 `*(long *)(param_1 + 0x38)` 立刻读到 `owner`（`&__this_module`）→ 后续 `+0x178` 越界读。

> 注意：源码 `memory_group_manager.c:1342-1349` 的**赋值顺序**与内存顺序不同（源码先 vmf_insert 再 update_pte），内存顺序由**头文件字段声明顺序**决定。按赋值顺序推布局会错位。

### 4.2 第 7 槽位：`mgmm_cache_pool_size(long)` → `size_t`

`mgmm_cache_pool_size` @ `0x10241c`（偏移 `0x19c4`）：

```c
long mgmm_cache_pool_size(long param_1) {
  long lVar1 = *(long *)(param_1 + 0x38);            /* → data */
  return *(long *)(lVar1 + 0x178) + *(long *)(lVar1 + 0x170)
       + (*(long *)(lVar1 + 0x188) + *(long *)(lVar1 + 0x180)) * 0x200;
}
```

- **1 个参数**，返回 `long`（缓存池字节数）。
- 语义：把 4 个池的页数换算成字节（`× 0x200` = 512 B/页）。

对照 r56p0 第 7 槽位 `mgm_get_import_memory_cached_access_permitted`（`mali_kbase_mem_linux.c:1465-1478`）：

```c
if (mgm_dev->ops.mgm_get_import_memory_cached_access_permitted) {     /* 判空通过！ */
    mgm_import_data.type = MEMORY_GROUP_MANAGER_IMPORT_TYPE_DMA_BUF;
    mgm_import_data.u.dma_buf = dma_buf;
    if (mgm_dev->ops.mgm_get_import_memory_cached_access_permitted(
            mgm_dev, &mgm_import_data))          /* ← 2 参数 */
        *flags |=  BASE_MEM_CACHED_CPU;
    else
        *flags &= ~BASE_MEM_CACHED_CPU;
} else {
    *flags |= BASE_MEM_CACHED_CPU;               /* 无 API 时默认：强制缓存 */
}
```

### 4.3 错配后果的方向修正（CORRECTED）

TASK 03 的表述是「让不该缓存的导入内存被判为允许缓存」。实测方向**不完全是**这样：

| 条件 | `mgmm_cache_pool_size` 返回 | r56p0 解读 | 与"无 API 默认"比较 |
| --- | --- | --- | --- |
| 池非空（稳态） | > 0 | `true` → `|= CACHED_CPU` | **一致**（默认也是置位） |
| 池为空（启动早期/低内存/回收后） | `0` | `false` → `&= ~CACHED_CPU` | **相反**（默认是置位） |

即：**多数时间行为与 r56p0 的降级默认一致，只在池空的瞬间反向清除缓存标志**。

因此：
- 「静默错配存在」——**CONFIRMED**（结构、槽位、签名三重证据）。
- 「必然导致错误缓存标记」——**CORRECTED**：是**非确定性**行为，随运行时池水位漂移，而不是恒定错误。
- 危害性质从「持续错误」变为「偶发、依赖内存压力」——**更难复现，但不是更安全**：一旦在 DMA-buf 导入时恰好池空，会清除本应置位的 `BASE_MEM_CACHED_CPU`，可能导致 CPU/GPU 缓存不一致。

### 4.4 r49p1 侧从不消费该槽位

```
01_original_baseline/.../mali-r49p1/drivers/gpu/arm/midgard/mali_kbase_native_mgm.c:162
        .mgm_mtk_cache_pool_size = NULL,
```

全树检索 `mgm_mtk_cache_pool_size` 仅 4 处命中：定义（`memory_group_manager.c:1136`）、赋值（`:1349`）、头文件声明（`memory_group_manager.h:192`）、native 置 NULL。**没有任何调用点**。

结论：第 7 槽位在 r49p1 中是**纯占位**，r56p0 复用它不会破坏 r49p1 的既有逻辑——风险完全落在「r49p1 的 MGM 二进制/源码直接配 r56p0 kbase」这一种组合上。

### 4.5 `update_gpu_pte` ABI：双向确证

MTK 侧 @ `0x1023b0`（偏移 `0x1958`）：

```c
ulong example_mgm_update_gpu_pte(long mgm_dev, uint group_id, undefined8 mmu_level, ulong pte) {
  if (group_id > 0xf) SoftwareBreakpoint(0x800);         /* 越界即 BUG */
  /* 独占写 *(u32 *)(data + group_id*0x10 + 0xc) += 1  —— 引用计数 */
  return pte | ((ulong)group_id << 0x3b) | 0x8000000000000000;
}
```

kbase 侧 @ `0x144aec`（偏移 `0x20a04`）：

```c
ulong kbase_native_mgm_update_gpu_pte(long mgm_dev, uint group_id, undefined8 mmu_level, ulong pte) {
  if (group_id > 0xf) SoftwareBreakpoint(0x800);
  return pte | ((ulong)group_id << 0x3b) | 0x8000000000000000;
}
```

**两者逐字节等价**（仅 MTK 版多一次引用计数自增）。

关键位域：
- `group_id << 59` —— 这就是 `PTE_PBHA_SHIFT = 59`，**实测确证**，与 DTS `/soc/mali@48000000/pbha` 的 `propagate-bits = <0x0f>`（4 bit）完全对应；
- `| (1 << 63)` —— 置 PTE 的 bit63，作用未在二进制中体现，推断为「已标记 MGM 处理」的哨兵位；
- `pte_to_original_pte` = `pte & 0x07FFFFFFFFFFFFFF` —— **清除 bit 59–63**（PBHA 4 bit + 哨兵位）。

`0x07FFFFFFFFFFFFFF` 是 59 位掩码，比 TASK 03 记的 `PTE_PBHA_MASK = 0xf << 59` **多清了 bit63**。移植时若只清 4 bit 而保留 bit63，`pte_to_phy_addr` 会得到带 bit63 的物理地址 → 非法。

### 4.6 引用计数副作用（新发现）

`example_mgm_update_gpu_pte` 在返回前对 `data + group_id*0x10 + 0xc` 做原子自增。即**每次 PTE 更新都会累加该 group 的计数**。

`kbase_native_mgm_update_gpu_pte` **没有**这个动作。这意味着：
- 用 MTK MGM 时，group 计数会被高频 PTE 更新推高；
- 该计数唯一消费者是 debugfs `update_gpu_pte` 节点（`mgm_update_gpu_pte_get` @ `0x102ac0`）；
- 无溢出保护（`u32`），长时间运行会回绕。

风险等级 P3（仅影响调试读数），但记录在案。

---

## 5. GED 间接调用分析（P1-1）

### 5.1 导出结构：169 = 154 FUNC + 15 OBJECT

```
readelf -sW ged.ko | grep __ksymtab_   → 169
其中 FUNC 154、OBJECT 15（含 9 个 _fp 全局函数指针，各 8 字节）
```

9 个 `_fp` 是**数据对象**，不是函数：

| 符号 | 类型 | 大小 | 地址 |
| --- | --- | ---: | ---: |
| `ged_vsync_notifier_fp` | OBJECT | 8 | `0x000150` |
| `ged_sw_vsync_event_fp` | OBJECT | 8 | `0x1048` |
| `ged_kpi_gpu_dvfs_fp` | OBJECT | 8 | `0x5408` |

这类符号即使没有 `UND` 引用，其**存在本身即接口**——外部模块可直接对其赋值来注册回调。

### 5.2 跨模块引用矩阵（修正 TASK 03 的 115）

| 引用方 | 命中数 | 说明 |
| --- | ---: | --- |
| `mali_kbase_mt6991_r49.ko` | 53 | TASK 03 已统计 |
| `mtk_gpu_pdma_mt6991.ko` | **2** | `ged_gpu_slc_dynamic_mode`、`ged_gpu_slc_get_dynamic_mode` |
| 其余 12 个模块 | 0 | — |

**被任一模块引用的 ged 导出 = 55，未被引用 = 114**（TASK 03 记 115，漏了 pdma 的 2 个）。

### 5.3 「无引用」不等于「无用途」——75/114 有内部调用

用已写出的 1,281 个 ged 函数体，对 114 个符号做标识符检索（排除自身定义文件）：

| 分类 | 数量 | 例证 |
| --- | ---: | --- |
| **A. 被 ged 内部函数调用** | **75** | `dcs_get_adjust_support` ← `dcs_adjust_support_show`/`ged_dvfs_gpu_freq_commit`；`ged_dvfs_set_sysram_last_commit_dual_idx` ← `ged_gpufreq_commit` |
| B. 无任何调用证据 | 37 | 见 §5.4 |
| （伪符号，需剔除） | 2 | `gpl`、`strings`（`__ksymtab_gpl` / `__ksymtab_strings` 前缀误匹配） |

A 类的典型结构：这些函数是 **sysfs/debugfs 的 `_show`/`_store` 后端**，或 `ged_dvfs_*commit` 的内部辅助。它们被导出多半是为了调试或其他 MTK 模块复用，**不是死代码**。

> 这一条直接回应任务书的警告：「不得将没有 ELF UND 引用直接等同于没有实际用途」。A 类 75 个如果按 TASK 03 的口径被判为"未使用"，会造成 66% 的误判率。

### 5.4 B 类 37 个的构成

| 子类 | 数量 | 说明 |
| --- | ---: | --- |
| `mtk_gpueb_*` | **11** | GED 对 GPUEB 的封装，见 §5.5 |
| `ged_mali_event_register/unregister_*` | 4 | 回调注册 API，无调用者 = 回调从未注册 |
| `ged_gpu_apo_*_nolock` / `ged_set_apo_*_nolock` | 8 | 加锁版本的内部实现，可能被内联 |
| `ged_set_target_fps` / `ged_kpi_set_target_FPS_margin` | 2 | FPSGO 用户态接口 |
| 其他 | 12 | `ged_log_*`、`ged_gpu_is_heavy`、`dcs_set_adjust_*` 等 |

**排除了动态查找路径**：全部 12 个模块对 `kallsyms_lookup_name` 的引用数为 **0**。因此不存在「运行时按名字查符号」的间接调用方式——这是重要的**否定证据**，把「无法判定」的范围收窄了。

### 5.5 GED → GPUEB：20 个封装函数，其中 3 个是纯桩

| 函数 | 实现 | 性质 |
| --- | --- | --- |
| `mtk_gpueb_dvfs_commit` @`0x13d6e8` | `if (p3) *p3 = 1; return;` | **纯桩** |
| `mtk_gpueb_dvfs_dcs_commit` @`0x13d6fc` | `return;` | **纯桩** |
| `mtk_gpueb_dvfs_set_taget_frame_time` @`0x13d7fc` | `return 0;` | **纯桩** |
| `mtk_gpueb_dvfs_set_frame_done` @`0x13d704` | `ged_to_fdvfs_command(1, ...)` | 真实 IPI |
| `mtk_gpueb_set_stability_mode` @`0x13d890` | `ged_to_fdvfs_command(0xd, ...)` | 真实 IPI |
| `mtk_gpueb_dvfs_get_desire_freq` @`0x13d8f0` | 读 `sysram_base + 0xe8` | sysram 直读 |
| 其余 14 个 | 未逐一展开 | 待定 |

**意义**：GED 的 GPUEB 通道是**混合**的——部分命令走 IPI，部分命令在当前构建中被编译成空桩。TASK 03 把 GED 描述为「完整封装 GPUEB」是不准确的。移植时不能假设 `mtk_gpueb_dvfs_commit` 会真的提交 DVFS。

---

## 6. 电源管理回调调用图（P1-2）

### 6.1 八个回调的实际地址

| 回调 | Ghidra vaddr | ELF `.text` 偏移 |
| --- | ---: | ---: |
| `pm_callback_power_on` | `0x139740` | `0x15658` |
| `pm_callback_power_off` | `0x139410` | `0x15328` |
| `pm_callback_suspend` | `0x13997c` | `0x15894` |
| `pm_callback_resume` | `0x1399e0` | `0x158f8` |
| `pm_callback_runtime_on` | `0x139d00` | `0x15c18` |
| `pm_callback_runtime_off` | `0x139d0c` | `0x15c24` |
| `pm_callback_runtime_gpu_idle` | `0x139d14` | `0x15c2c` |
| `pm_callback_runtime_gpu_active` | `0x139e50` | `0x15d68` |

### 6.2 `pm_callback_power_on` 实测序列

```
spin_lock_irqsave(kbdev + 0x30b8)                    ← hwaccess_lock
├─ SoftwareBreakpoint(0x800)  @0x139964              ← WARN_ON(gpu_powered)      ①
├─ SoftwareBreakpoint(0x800)  @0x13996c              ← WARN_ON(!active_count)    ②
├─ SoftwareBreakpoint(0x800)  @0x139974              ← WARN_ON(runtime_active)   ③
mutex_lock(kbdev + 0x3150)                           ← ghpm_lock
check_pm_callback_state(2)                           ← GED_POWER_ON
ghpm_ctrl(1, 0)                                      ← GHPM_ON
wait_gpueb(1)                                        ← SUSPEND_POWER_ON
mutex_lock(&g_mfg_lock)
gpufreq_power_control(1)                             ← GPU_PWR_ON
mtk_notify_gpu_power_change(1)
```

与 TASK 03 §3.2 的行号链**逐项一一对应**（`:226` → `:237/240/241` → `:248` → `:253` → `:255` → `:265` → `:274` → `:275` → `:276`）。

`SoftwareBreakpoint(0x800)` 即 AArch64 的 `brk #0x800`，内核 `WARN_ON` 的编译产物——**三条断言的二进制证据**。

### 6.3 `pm_callback_power_off` 实测序列

```
SoftwareBreakpoint(0x800)  @0x13971c                ← WARN_ON(gpu_powered)      ①(重复)
kbase_csf_scheduler_get_nr_active_csgs(kbdev)
├─ SoftwareBreakpoint(0x800) @0x13972c              ← WARN_ON(nr_active_csgs)   ④
└─ SoftwareBreakpoint(0x800) @0x139738              ← WARN_ON(mcu_state)        ⑤
check_pm_callback_state(0)                           ← GED_POWER_OFF
mtk_notify_gpu_power_change(0)                       ← 先通知
gpufreq_power_control(0)                             ← GPU_PWR_OFF
ghpm_ctrl(0, 0)                                      ← GHPM_OFF
wait_gpueb()                                         ← SUSPEND_POWER_OFF
```

**5 条不变量全部在二进制中存在**，且顺序与源码一致 → 不变量清单 **CONFIRMED**。

### 6.4 失败路径（实测分支）

| 失败点 | 行为 | 证据 |
| --- | --- | --- |
| `check_pm_callback_state(2) != 0` | `dump_pm_callback_kbase_info()` + 返回 | `0x139740` 分支 |
| `ghpm_ctrl(1,0) != 0` | `dump_pm_callback_kbase_info()` + `dump_ghpm_info()` | 同上 |
| `wait_gpueb(1) != 0` | `gpueb_dump_status(NULL,NULL,0)` | 同上 |
| `gpufreq_power_control(1)` 失败 | 上电中止，不调用 `mtk_notify` | 同上 |

与 TASK 03 §3.2 记录的失败处理一致 → **CONFIRMED**。

> 注意 `pm_callback_power_off` 中 `gpufreq_power_control(0)` 失败后**不断电但已解锁 `g_mfg_lock`**（TASK 03 已记录为「**不断电但仍解锁**」）。二进制中该路径确实跳过了 `ghpm_ctrl(0,0)`，直接返回 → **CONFIRMED**。

---

## 7. 对 TASK 03 原结论的逐项验证

状态定义：**CONFIRMED** 直接证据支持 / **CORRECTED** 需修正 / **REJECTED** 存在直接反证 / **UNKNOWN** 证据不足。

### 7.1 GPUFreq 相关

| 编号 | 原结论 | 状态 | 依据 |
| --- | --- | --- | --- |
| G-1 | `gpufreq_register_gpufreq_fp` 接收 72 B / 9 项结构 | **CORRECTED** | `gpufreq_fp` 访问偏移达 `0x198` → 416 B / 52 项。72 B / 9 项属于 `gpuppm_fp` |
| G-2 | 「416 B 同名项语义不明」 | **CORRECTED** | 416 B 就是 `gpufreq_fp` 本体，不是"另一处" |
| G-3 | AP 直写与 IPI 双路径存在 | **CONFIRMED** | `0x102e5c` / `0x10318c` 双分支，判据 `g_gpueb_support \|\| g_gpufreq_ready` |
| G-4 | `power_ctrl_enable == 0` 时静默返回成功 | **CONFIRMED** | `g_shared_status + 0xcc == 0` → `return 0` |
| G-5 | 表为空时返回 `-2` | **CONFIRMED** | `0x102e5c` / `0x10318c` |
| G-6 | 函数表注册后由 MTK 侧持有 | **CONFIRMED** | `gpufreq_fp = param_1`，无 memcpy |
| G-7 | IPI 超时 10000 ms | **CONFIRMED**（新增参数） | `mtk_ipi_send_compl_to_gpueb(..., 8, 10000)` |
| G-8 | GED 与 wrapper 用同一 IPI 通道 | **REJECTED** | 两套通道、两种长度（8/6 word）、两种超时（10 s/2 s） |

### 7.2 MGM 相关

| 编号 | 原结论 | 状态 | 依据 |
| --- | --- | --- | --- |
| M-1 | `ops` 为 7 项 56 B | **CONFIRMED**（子结构） | probe 填 `puVar4[0..6]` |
| M-2 | `memory_group_manager_device` 大小为 56 B | **CORRECTED** | `kmalloc(0x48)` = 72 B，含 `data`@0x38、`owner`@0x40 |
| M-3 | 第 7 槽位是 `mgmm_cache_pool_size` | **CONFIRMED** | `puVar4[6] = mgmm_cache_pool_size` |
| M-4 | 错配导致"让不该缓存的判为允许缓存" | **CORRECTED** | 非零→允许（=默认）；**零→禁止**（偏离默认）。非确定性 |
| M-5 | `mgm_update_gpu_pte` r49p1 为 4 参数 | **CONFIRMED** | `0x1023b0` 与 `0x144aec` 逐字节等价 |
| M-6 | `PTE_PBHA_SHIFT = 59` | **CONFIRMED** | `group_id << 0x3b` |
| M-7 | `PTE_PBHA_MASK = 0xf << 59` | **CORRECTED** | 实际清除 `0x07FFFFFFFFFFFFFF` → 清 bit 59–63（含哨兵位） |
| M-8 | r49p1 无该槽位消费者 | **CONFIRMED** | 全树 4 处命中，0 调用；native_mgm 置 NULL |
| M-9 | MGM 通过 DT phandle 绑定 | **CONFIRMED** | `*(param_1 + 0xa8) = puVar4`（platform drvdata） |

### 7.3 GED 相关

| 编号 | 原结论 | 状态 | 依据 |
| --- | --- | --- | --- |
| D-1 | 168 个导出 | **CORRECTED** | `__ksymtab_` 命中 169（154 FUNC + 15 OBJECT） |
| D-2 | 115 个未被 kbase 引用 | **CORRECTED** | 114（`mtk_gpu_pdma` 另引用 2 个） |
| D-3 | 未被引用 = 可能无用途 | **REJECTED** | 114 中 75 个被 ged 内部函数调用，误判率 66% |
| D-4 | GED 完整封装 GPUEB | **CORRECTED** | 20 个 `mtk_gpueb_*` 中至少 3 个是纯桩 |
| D-5 | GED→kbase 反向调用为 0 | **CONFIRMED** | REL 层无 kbase 符号引用 |
| D-6 | 存在 `kallsyms_lookup_name` 动态查找 | **REJECTED** | 全部 12 模块引用数为 0 |

### 7.4 电源相关

| 编号 | 原结论 | 状态 | 依据 |
| --- | --- | --- | --- |
| P-1 | 5 条电源状态机不变量 | **CONFIRMED** | 6 处 `brk #0x800`，位置与语义一致 |
| P-2 | power_on 顺序（ghpm → wait_gpueb → gpufreq → notify） | **CONFIRMED** | `0x139740` 实测序列 |
| P-3 | power_off 先 `notify(0)` 再断电 | **CONFIRMED** | `0x139410` |
| P-4 | `gpufreq_power_control(0)` 失败仍解锁 | **CONFIRMED** | 失败分支跳过 `ghpm_ctrl(0,0)` 直接返回 |

### 7.5 六项 Stage 2 复核的维持情况

TASK 03 的六项复核结论本轮**未被推翻**，其中第 5 项（devfreq）需要一条精确化补注：

- `mali_kbase_mt6991_r49.ko` 的 UND 表中**确实存在** 9 个时钟/稳压器接口：`clk_enable`、`clk_disable`、`clk_prepare`、`clk_unprepare`、`clk_set_rate`、`clk_put`、`regulator_get_optional`、`regulator_set_voltage`、`regulator_put`。
- 因此「改不动频率」的成因**不是**「kbase 不调用 `clk_set_rate`」，而是「DTS 的 GPU 节点无 `clocks` 属性 → `kbdev->nr_clocks == 0` → 调用点所在的循环体一次都不执行」。
- 这个区别有实践后果：**若移植时给 DTS 补上 `clocks`，这些调用会突然生效**，行为将不同于 TASK 03 基线。移植方案必须显式决定「保持 `nr_clocks == 0`」还是「接入新的时钟接口」。

---

## 8. 已消除的 UNKNOWN

| ID | 原描述 | 本轮结果 | 消除程度 |
| --- | --- | --- | --- |
| **U3-06** | `gpufreq_register_gpufreq_fp` 结构体字段布局 | 表长 **52 项 / 416 B**；22 个槽位语义 + 偏移 + 调用者已恢复；init 在 `slot[15]` | **部分闭合**（字段类型仍为推断） |
| **U3-07** | `wait_gpueb` 超时阈值 | IPI 发送超时已确证：wrapper **10000 ms**、GED **2000 ms** | **部分闭合**（`wait_gpueb` 自身为 mailbox 等待，超时仍未定位） |
| **U3-09** | `IPI_ID_FAST_DVFS` 与 `IPI_ID_GPUFREQ` 分工 | 两套独立通道已区分：wrapper `g_ipi_channel`（ID<0x13）/ GED `g_fast_dvfs_ipi_channel`（mask `0x7bca`） | **部分闭合** |
| **U3-11** | 115 个未使用导出的性质 | 114 个，其中 75 个有内部调用、37 个无调用证据（含 11 个 `mtk_gpueb_*`） | **闭合**（分类完成） |
| **U3-17** | `mgmm_cache_pool_size` 的消费者 | 全树 **0 个调用者**，仅 4 处符号性出现 | **闭合** |
| **U3-03** | 间接函数指针调用 | GED 内部 422 条数据段引用已枚举，全部指向 static 回调（debugfs/sysfs），无导出函数 | **闭合**（GED 范围） |

---

## 9. 仍存在的 UNKNOWN

| ID | 描述 | 缺失证据 | 可否闭环 |
| --- | --- | --- | --- |
| U3-06b | `gpufreq_fp` 52 个槽位中 30 个的**参数类型与返回值** | 需要 `mtk_gpufreq_mt6991` 侧的赋值点（该表由它填充，但填充函数未被反编译导出） | 可用 `--procedure` 逐个定位，成本高 |
| U3-06c | slot 45–49 是否为 STACK 子表 | 仅有调用者重叠这一间接证据 | 需 DTS / debugfs 交叉验证 |
| U3-07b | `wait_gpueb` 的 mailbox 等待超时 | 函数在 `mtk_gpueb.ko`，需定位其同步原语 | 可闭环 |
| U3-08 | `gpufreq_commit` 的实际触发点 | `csf/` 调度器内调用点未逐一分析（3,007 函数中未筛出） | 可闭环（工作量大） |
| U3-10 | GHPM 状态机细节 | `ghpm_ctrl` 实现在 `mtk_gpu_hal.ko`，本轮未展开 | 可闭环 |
| U3-13 | IRQ 612（GPUEB_MBOX1）归属 | 已确认 `gpueb_clr_mbox1_irq` 写 `IPI_base + 0x84`，但中断注册方未定位 | 部分 |
| U3-16 | MGM 内部 SLC 策略 | `data + 0x69` 等字段语义无符号线索 | 难 |
| U3-20…24 | DTS 源文件、SMMU 域建立者等 | 需 DTS 源码或设备树反编译 | 需新证据源 |

**未变的两个根缺口**：MTK 平台层源码未归档（`drivers/gpu/mediatek/**` 211 文件）、CSF 固件与用户态 DDK 缺失。

---

## 10. 新发现的风险

### R-1　kCFI 类型哈希（P0，新）

`gpufreq_fp` 与 `gpuppm_fp` 的每个成员在调用前都检查 `*(int *)(fn - 4)`：

| 调用点 | 期望哈希 | 用途 |
| --- | --- | --- |
| `gpufreq_register_gpufreq_fp` `slot[15]` | `0x004b35c1` | init |
| `gpufreq_register_gpuppm_fp` `slot[8]` | `0x004b35c1` | init |
| `gpufreq_power_control` `slot[5]` | `0xcd827f92`（`-0x327d806e`） | power_ctrl |
| `gpufreq_commit` `slot[0]` | `0x99f170f1`（`-0x660e8f0f`） | commit |

不匹配则执行 `brk #0x8228`，内核直接 panic（`CONFIG_CFI_CLANG`）。

**影响**：移植时**不能**用「参数个数相同但类型不同」的函数替换表成员，也不能用 C 强转绕过去。任何 r56p0 侧的新回调若要放进 MTK 表，必须编译出相同的 kCFI hash——这实际上要求**完全一致的函数原型**，比 TASK 03 假设的「ABI 兼容」严格得多。

### R-2　`gpufreq_fp` 欠分配（P0，新）

若按 TASK 03 的「9 项 72 B」复制结构体，`slot[15]`（`0x78`）已越界 8 字节，`slot[51]`（`0x198`）越界 **360 字节**。表现是写入相邻堆块 → 随机崩溃或静默数据损坏。

**证据**：`0x198 + 8 = 0x1a0`；`kmalloc` 大小若为 0x48 则必然越界。

### R-3　两套 IPI 消息长度不一致（P1，新）

wrapper 8 word / GED 6 word。若按统一结构体传递，GED 路径会**多读 2 word 栈残留**，wrapper 路径会**少填 2 word**。命令字位置（`msg[0]` vs `msg[1]`）也不同。

### R-4　`pte_to_original_pte` 掩码差异（P1，新）

实际清 `bit 59–63`（`0x07FFFFFFFFFFFFFF`），TASK 03 记为只清 `bit 59–62`（`0xf << 59`）。漏清 bit63 会让 `pte_to_phy_addr` 得到非法物理地址。

### R-5　GED 的 GPUEB 提交可能是空桩（P1，新）

`mtk_gpueb_dvfs_commit` / `dcs_commit` / `set_taget_frame_time` 三个实现为空。移植时若依赖 GED 完成 DVFS 提交，会得到「调用成功但无效果」的静默失败。

### R-6　MGM PTE 引用计数回绕（P3，新）

`example_mgm_update_gpu_pte` 每次调用自增 `u32` 计数，无饱和保护。仅 debugfs 消费，不影响功能。

### R-7　补 DTS `clocks` 会激活休眠路径（P1，新）

kbase 的 UND 表含 9 个时钟/稳压器接口，当前因 `nr_clocks == 0` 全部不执行。若移植时「顺手」给 GPU 节点补上 `clocks`，`clk_set_rate` / `regulator_set_voltage` 会立即生效，而 MTK 的调频实际由 GPUFreq + GPUEB 完成——两条电压/频率控制通路**同时生效会互相覆盖**，且写序不确定。

**处置**：DTS 不补 `clocks`，或在补的同时屏蔽 kbase 侧的 `clk_set_rate` 循环。这个决定必须在移植前固定，不能留给运行时。

---

## 11. 与 TASK 03 结论的关系

本轮**没有推翻** TASK 03 的路线判断（保留 10 / 适配 2 / 重写 0），但修正了三个量化前提：

1. **`gpufreq_fp` 是 52 项不是 9 项** —— 影响「GPUFreq 可原样保留」的可行性：结构体定义必须按 416 B 重建，不能沿用 72 B。
2. **MGM 是 72 B 不是 56 B** —— 影响「MGM 只需适配 `update_gpu_pte`」的判断：`data` 指针一旦错位，`mgmm_cache_pool_size` 会读 `owner` 再越界。
3. **kCFI 约束此前完全未计** —— 这是对「89 个符号调用点可机械化」这一乐观估计的实质削弱：符号名对得上不等于能链接通过，函数原型必须逐一对齐。

结论仍然成立：**最小化移植路线可行**，但 P3 阶段（45 处结构体字段块）的实际难度高于 TASK 03 的估计，且新增一类无法靠编译器捕获的失败模式（kCFI trap）。

---

## 附：可重放命令

```bash
export PATH=/opt/node24/bin:$PATH
export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64
export GHIDRA_INSTALL_DIR=/opt/ghidra_12.2_PUBLIC
cd 01_original_baseline/kernel_ref_mt6991/vendor_dlkm

# 表布局
rea decompile --procedure memory_group_manager_probe ./mali_mgm_mt6991_r49.ko
rea decompile --procedure gpufreq_register_gpufreq_fp ./mtk_gpufreq_wrapper.ko

# 偏移扫描（需先 decompile-all）
rea decompile-all ./mtk_gpufreq_wrapper.ko --output /tmp/w
grep -ohE "gpufreq_fp \+ 0x[0-9a-f]+" /tmp/w/functions/*.c | sort -u

# 全量重建
for f in *.ko; do rea decompile-all "./$f" --output "/tmp/rea/${f%.ko}"; done
```
