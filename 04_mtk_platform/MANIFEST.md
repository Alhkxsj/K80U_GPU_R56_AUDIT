# MANIFEST — 04_mtk_platform

> 目录用途：TASK 03「MT6991 原厂 GPU 平台适配层深度审计」交付物
> 审计日期：2026-11-15 · 性质：**只读静态审计**（未编译、未打补丁、未部署、未修改任何源码树）
> 上游依赖：`03_kbase_csf/`（Stage 2 结论）、`01_original_baseline/`、`02_r56_source/`

---

## 1. 基准核对

| 项 | 值 | 出处 |
| --- | --- | --- |
| 原厂 Kbase 源码 | 581 文件 / 210,424 行 | `01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/` |
| 原厂版本串 | `r49p1-03bet0` | 同上 `Makefile:526` |
| 原厂平台模块 | **15 个 `.ko`**，4.13 MB，全部 `not stripped` | `01_original_baseline/kernel_ref_mt6991/vendor_dlkm/` |
| 原厂 DTB | 532,322 B，Android DT-Table 封装（内层 FDT 532,258 B / 2,194 节点） | `01_original_baseline/kernel_ref_mt6991/dtb/mt6991.dtb` |
| 加载清单 | 262 行；GPU 相关 12 条（行 38–53、87） | `01_original_baseline/kernel_ref_mt6991/modules.load.vendor` |
| Arm R56p0 源码 | 454 文件 / 161,943 行 | `02_r56_source/mali_r56p0/driver/product/kernel/drivers/gpu/arm/midgard/` |
| R56p0 版本串 | `r56p0-18eac0` | 同上 `Kbuild:75` |
| UK ABI | 1.30 → 1.39 | `…/csf/mali_kbase_csf_ioctl.h:122` / `:149` |

### 1.1 与任务书描述不符的一处，已按实测修正

任务书要求检查 `01_original_baseline/mtk_kernel_modules/drivers/`。**该目录不存在**。`mtk_kernel_modules/` 下只有 `gpu/gpu_mali/mali_avalon/mali-r49p1`（581 文件）。

MTK 平台层的实际归档形态是 `kernel_ref_mt6991/vendor_dlkm/` 下的 **15 个二进制 `.ko`**，无源码。

因此本目录全部结论的证据基础是：

- **二进制侧**：`.symtab` / `__ksymtab` / `__versions` / `.modinfo` / `.rela.*`（15 个 `.ko` 均可完整解析）
- **源码侧**：r49p1 的 581 文件（Kbase 本体，含 MTK 注入）
- **硬件侧**：`mt6991.dtb` 反解析

凡只能从二进制推断者标 `[推断]`，无法判定者标 `UNKNOWN`。

---

## 2. 文件清单

| # | 文件 | 行数 | 字节 | SHA256 | 对应任务 |
| ---: | --- | ---: | ---: | --- | --- |
| 1 | `01_module_dependency_audit.md` | 320 | 20,095 | `9c65d83b23b97c85d28f6c6b8fb84b53f5bb4de9e038891d0600a9fa22a1e64d` | 03-A |
| 2 | `02_gpufreq_gpueb_architecture.md` | 343 | 20,160 | `3ba3c238e6a2949e0060c4e0fdb0f6467f773a3ac92a0048e93f230e9f585221` | 03-B |
| 3 | `03_ged_integration_audit.md` | 208 | 14,707 | `1dd2af2c1482a412109de240d81612c57d066adddef1220396382fb3bc210fb9` | 03-C |
| 4 | `04_mgm_pma_memory_audit.md` | 312 | 16,184 | `d186e90da254f7681ce8c622693d3279448d8387916d246235e6d1eff2da45a2` | 03-D |
| 5 | `05_dts_hardware_resource_audit.md` | 316 | 16,236 | `86d58e8fceac189bf47f25799f958eeaee3db579f40183011e23388f6d122ce5` | 03-E |
| 6 | `06_platform_retention_matrix.md` | 354 | 21,581 | `7bd80387b45727d9e8f99bdeccd2688d8652252103cf27cfcbd896d251cdbc46` | 03-F + §四复核 |
| 7 | `REA_SUPPLEMENT.md` | 713 | 39,909 | `dcb442a39a78b3343a1d422ae6b946ca79e9999eb5b9a72170926c3d8cdaa1dd` | 03-REA |
| 8 | `MANIFEST.md` | 本文件 | — | — | — |

合计 2,566 行 / 148,872 字节（不含本文件与 `README.md`）。

---

## 3. 内容索引

| 文件 | 核心结论 | 关键量化 |
| --- | --- | --- |
| `01` | 依赖严格单向：MTK → kbase 为 **0**，kbase → MTK 为 **89** | 15 模块台账；5 个必答问题；MGM/PMA 零导出 |
| `02` | GPUFreq 无需重写，只需重建 kbase 侧调用方 | 12 条 IPI 通道；52 项 OPP（1612→338 MHz）；16 个符号 |
| `03` | GED 可原样保留；devfreq 是热限幅 shim 不是调频引擎 | 168 导出 / 53 被 kbase 使用；`polling_ms` 0 vs 100 |
| `04` | PMA 保留（ops 逐字节相同）；MGM 需改签名 + 换槽位 | ops 7 vs 7，第 7 槽语义替换；PBHA 4 bit |
| `05` | DTS 无需改（phandle 名两版一致）；`sleep-mode-enable=1` | 2,194 节点；6 路中断；`clocks`/`power-domains` 缺失 |
| `06` | 保留 10 模块 / 适配 2 项 / 重写 0 项；最小化路线成立 | 45 处结构体字段；六项 Stage 2 复核（2 项推翻） |
| `REA` | 反编译确证三条量化前提错误：`gpufreq_fp` 52 项、MGM 72 B、GED 114 未被引用 | 5,440 函数；22 槽位映射；kCFI 哈希；7 项新风险 |

---

## 4. 可执行复核命令

以下命令均**实际执行过**，输出即本目录引用值。

### 4.1 模块清单与符号数

```bash
cd 01_original_baseline/kernel_ref_mt6991/vendor_dlkm
for f in *.ko; do
  printf "%-32s " "$f"
  readelf -sW "$f" | grep -cE " FUNC | OBJECT "
done
# 期望：ged 2371 / kbase 2881 / mgm 92 / prot_alloc 25 ...
```

### 4.2 依赖方向为 0（本目录最重要的一条）

```bash
cd 01_original_baseline/kernel_ref_mt6991/vendor_dlkm
for f in *.ko; do
  [ "$f" = "mali_kbase_mt6991_r49.ko" ] && continue
  n=$(readelf -sW "$f" | awk '$7=="UND"{print $8}' | grep -c "kbase")
  printf "%-32s %s\n" "$f" "$n"
done
# 期望：全部 0
```

### 4.3 kbase 依赖 MTK 的 89 个符号

```bash
cd 01_original_baseline/kernel_ref_mt6991/vendor_dlkm
echo "kbase UND 总数: $(readelf -sW mali_kbase_mt6991_r49.ko | awk '$7=="UND"{print $8}' | sort -u | wc -l)"
for f in ged.ko mtk_gpufreq_wrapper.ko mtk_gpu_hal.ko mtk_gpueb.ko mtk_gpu_pdma_mt6991.ko; do
  printf "%-28s %s\n" "$f" \
    "$(comm -12 <(readelf -sW "$f" | grep -o '__ksymtab_[A-Za-z0-9_]*' | sed 's/__ksymtab_//' | sort -u) \
                <(readelf -sW mali_kbase_mt6991_r49.ko | awk '$7=="UND"{print $8}' | sort -u) | wc -l)"
done
# 期望：53 / 16 / 13 / 6 / 1
```

### 4.4 MGM ops 表第 7 槽位差异（`04` 的核心证据）

```bash
A=01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/linux/memory_group_manager.h
B=02_r56_source/mali_r56p0/driver/product/kernel/include/linux/memory_group_manager.h
grep -n "mgm_mtk_cache_pool_size" "$A"                          # 期望：192 行（#if CONFIG_MALI_MTK_MGMM）
grep -n "mgm_get_import_memory_cached_access_permitted" "$B"    # 期望：存在
readelf -sW 01_original_baseline/kernel_ref_mt6991/vendor_dlkm/mali_mgm_mt6991_r49.ko \
  | grep mgmm_cache_pool_size    # 期望：LOCAL FUNC，offset 0x19c4，28 字节
```

### 4.5 PMA ops 逐字节一致（`04` 的核心证据）

```bash
diff <(sed -n '/struct protected_memory_allocator_ops/,/^};/p' \
  01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/linux/protected_memory_allocator.h) \
     <(sed -n '/struct protected_memory_allocator_ops/,/^};/p' \
  02_r56_source/mali_r56p0/driver/product/kernel/include/linux/protected_memory_allocator.h)
# 期望：无输出

diff 01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_protected_memory.c \
     02_r56_source/mali_r56p0/driver/product/kernel/drivers/gpu/arm/midgard/csf/mali_kbase_csf_protected_memory.c
# 期望：无输出（两版均 155 行 / 4,463 B）
```

### 4.6 CONFIG_MALI_MTK_* 五种口径（`06` §3 复核 1）

```bash
cd 01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard
grep -rho 'CONFIG_MALI_MTK[A-Z0-9_]*' . | sort -u | wc -l                                       # 91 全树
find . -name '*.c' -o -name '*.h' | xargs grep -ho 'CONFIG_MALI_MTK[A-Z0-9_]*' | sort -u | wc -l # 85
grep -o 'CONFIG_MALI_MTK[A-Z0-9_]*' Kbuild-mtk-custom-env | sort -u | wc -l                     # 88 清单
grep -o '\-DCONFIG_MALI_MTK[A-Z0-9_]*' Kbuild-mtk-custom-env | sort -u | wc -l                  # 81 注入
grep -rho 'CONFIG_MALI_MTK[A-Z0-9_]*' csf | sort -u | wc -l                                     # 38 csf/
```

### 4.7 `gpu_props` 越界结论复核（`06` §3 复核 3）

```bash
for t in 01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1 \
         02_r56_source/mali_r56p0/driver/product/kernel; do
  grep -n "get_props->size < kprops->prop_buffer_size" -A2 \
    "$t/drivers/gpu/arm/midgard/mali_kbase_core_linux.c"
done
# 期望：两版都有该守卫并返回 -EINVAL；copy_to_user 长度为内核侧 prop_buffer_size
```

### 4.8 DTB 解析（`05` 的全部数据来源）

```bash
# ① 确认是 DT-Table 封装而非裸 FDT
xxd -l 8 01_original_baseline/kernel_ref_mt6991/dtb/mt6991.dtb
# 期望：d7b7ab1e ...    ← magic = DT_TABLE_MAGIC，不是 d00dfeed

# ② 拆包：表头 32 字节 + 条目 32 字节，entry[0].offset = 0x40
python3 - <<'PY'
import struct
b=open("01_original_baseline/kernel_ref_mt6991/dtb/mt6991.dtb","rb").read()
sz,off=struct.unpack(">2I", b[32:40])
open("/tmp/inner.dtb","wb").write(b[off:off+sz])
print("inner size", sz, "magic", hex(struct.unpack(">I", b[off:off+4])[0]))
PY
# 期望：inner size 532258 magic 0xd00dfeed

# ③ 用任意 FDT 工具读取 /soc/mali@48000000、/ged、/gpufreq-wrapper、/soc/opp-table0
```

本目录使用自写 FDT 解析器（token：`BEGIN_NODE=1 / END_NODE=2 / PROP=3 / NOP=4 / END=9`），未依赖 `dtc`（沙箱内不可用）。

### 4.9 devfreq governor 语义（`03` §4）

```bash
A=01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard
B=02_r56_source/mali_r56p0/driver/product/kernel/drivers/gpu/arm/midgard
sed -n '138,142p' "$A/platform/mtk_platform_common/mtk_platform_devfreq_governor.c"  # dp->polling_ms = 0
sed -n '655p'     "$B/backend/gpu/mali_kbase_devfreq.c"                               # dp->polling_ms = 100
sed -n '677,684p' "$A/backend/gpu/mali_kbase_devfreq.c"                               # #if MTK_DEVFREQ_GOVERNOR
sed -n '681p'     "$B/backend/gpu/mali_kbase_devfreq.c"                               # 裸 "simple_ondemand"
```

---

## 5. 来源完整性说明

| 项 | 状态 |
| --- | --- |
| `01_original_baseline/` 与 `02_r56_source/` 是否被修改 | **否**。本目录以外的两条基线树 `git status` 为空 |
| 是否编译 | **否**。全部结论来自静态解析 |
| 是否运行 | **否** |
| `02_r56_source/Documentation/` 正文可信度 | ⚠ **有损**。5 个 yaml 含网页重构残留 `:contentReference[oaicite:N]`（详见 `03_kbase_csf/MANIFEST.md` §5）。本目录**只引用其结构性字段**（`compatible` 枚举、`required` 列表、`minItems/maxItems`），**未引用任何叙述性文字** |
| 15 个 `.ko` 符号完整性 | ✅ 全部 `not stripped`，`.symtab` + `.strtab` + `__versions` 完整；无 BTF、无 DWARF |
| `mt6991.dtb` 完整性 | ✅ 内层 FDT 头 `totalsize` 与文件长度一致，无截断 |

### 5.1 两个方法学陷阱的记录

1. `grep 'gpufreq_'` 会命中 `mtk_set_gpufreq_clock_parking`，使 `backend/` 的计数从真实的 **10** 虚高到 **14**。本目录统一使用 `grep -E '\bgpufreq_'`（词边界）。
2. 源码标识符 **18** 个 ≠ 链接符号 **16** 个——差额 `gpufreq_check_bus_idle`、`gpufreq_set_ocl_timestamp` 被 `#if` 排除。**判断移植接口面必须以 `UND` 集合为准**，`grep` 仅用于定位调用点。

---

## 6. 未决项

24 项 `UNKNOWN`（U3-01 … U3-24），分布见 `06_platform_retention_matrix.md` §5。共同根缺口两个：

1. **MTK 平台层源码未归档**（`MiCode/MTK_kernel_modules @ fe0fa7ff` 的 `drivers/gpu/mediatek/**`，211 文件）。补齐后可闭环 U3-01/06/11/13/16/17。
2. **CSF 固件与用户态 DDK 缺失**（`mali_csffw.bin`、`libGLES_mali.so` 全仓 0 命中）。补齐后可评估 U3-10/15/22。

---

## 7. 目录边界

本目录**只包含审计文档**：

- 不含补丁、不含 `.dts` 修改、不含 Makefile/Kconfig 改动
- 不含编译产物
- 不含从设备提取的二进制
- 未引用第三方 PanVK 代码作为 R56p0 兼容性证据

---

## 8. 登记规则

1. 每份报告首行注明 `依据：<树路径> @ <版本>`，并登记到 §2 的 SHA256 列。
2. 结论条目在各自文件内使用 `[实证]` / `[推断]` / `UNKNOWN` 三级标注，不使用"应当""大概""推测为"等无标记措辞。
3. `UNKNOWN` 必须给出 ID 与缺失的具体证据，不得只写"未验证"。
4. 引用行号必须实测，可 `sed -n 'Np'` 复核。
5. 任何推翻上游（Stage 2）结论的条目，必须在 `06_platform_retention_matrix.md` §3 显式登记并说明反证。

---

## 9. 修订记录

| 日期 | 版本 | 变更 |
| --- | --- | --- |
| 2026-11-15 | v1.0 | 首次提交：6 份报告 + 本 MANIFEST。含六项 Stage 2 复核（推翻 2 项、收紧 2 项、口径修正 2 项） |
| 2026-11-15 | v1.1 | 新增 `REA_SUPPLEMENT.md`（TASK 03-REA 二进制逆向补充审计）。反编译 12 个 `.ko` / 5,440 函数，修正 4 项量化前提（`gpufreq_fp` 52 项、MGM 72 B、错配后果方向、GED 114 而非 115），新增 kCFI 类型哈希等 7 项风险。原 6 份报告**未改动** |
