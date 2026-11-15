# MANIFEST — 05_userspace_firmware

> TASK 04 交付登记。**不含任何厂商私有二进制**：全部 `.so` / `.bin` / `.ko` 实体均未采集、未上传，只登记路径、大小、SHA256 与分析结论。
>
> 本文件同时记录**两种状态**，且二者不等价：
> - **报告交付状态**：六份报告 + 一份设备证据登记是否已提交（§2、§3.2）；
> - **证据闭环状态**：每项 UNKNOWN 是否已被证据消解（§6）。

---

## 1. 基准核对

| 项 | 值 |
| --- | --- |
| 仓库 | `github.com/JiangXue5/K80U_GPU_R56_AUDIT` |
| 分支 | `main` |
| TASK 04 首轮 HEAD | `cbe7a26`（03-REA 补充审计）→ 提交 `efd8547` |
| TASK 04 补充核验基线 | `efd8547` → 提交 `04-fix: Stage 4 真机证据整合与兼容性复核` |
| 原厂基线 | `mali-r49p1-03bet0`（CSF UK ABI **1.30**）——真机 `/sys/module/.../version` 已实测一致 **[D]** |
| 目标基线 | `mali-r56p0-18eac0`（CSF UK ABI **1.39**） |
| 内核参照 | Linux **6.6.143-android15-8-gf9aa2fec23c3-4k**（真机 `uname -a`） |
| 系统 | **Android 17 / SDK 37**，HyperOS `OS4.0.3.0.XONCNM`（真机 `ro.build.*`） |

### 1.1 证据边界声明（本轮更新）

**首轮**：本阶段未获得任何用户态二进制或 CSF 固件实体 → 全部结论止于源码契约层。
**本轮**：已获得**设备侧元数据**（三份采集输出），但仍**未获得二进制实体**。因此：

| 结论类型 | 首轮 | 本轮 |
| --- | --- | --- |
| UAPI 契约兼容性 | **[E1]** 完整 | **[E1]** 完整（不变） |
| 固件加载机制 | **[E1]** 完整 | **[E1]** 完整（不变） |
| 固件本体属性 | **[U]** 无 | **[D]** 元数据（大小/哈希）+ **[U]** 头字节 |
| 用户态 DDK 构成 | **[U]** 无 | **[D]** 路径/大小/哈希/BuildID/NEEDED/部分符号 |
| 用户态 DDK 行为 | **[U]** 无 | **[U]** 仍无 |
| Android 图形栈 | **[E3]** 惯例 | **[D]** 依赖图 + VINTF + 服务状态 |
| 运行时行为（bootloop / GLB） | **[U]** | **[U]** 仍无 |

> **纪律**：`02` 章的核心判据已从"实测 0.3"改为"源码要求 0.3 / 0.4 + E2 级启动一致性推理"。**不得**把元数据当作实体字段的证据。

---

## 2. 文件清单

| # | 文件 | 行数 | 字节 | SHA256（前 16） | 内容 |
| ---: | --- | ---: | ---: | --- | --- |
| 1 | `01_component_inventory.md` | 见下 | 见下 | 见下 | 04-A 组件清点（双轨：仓库 / 真机） |
| 2 | `02_csf_firmware_abi.md` | 见下 | 见下 | 见下 | 04-B 固件 ABI（三层证据） |
| 3 | `03_gles_egl_abi.md` | 见下 | 见下 | 见下 | 04-C GLES/EGL 契约 + 实体 |
| 4 | `04_vulkan_abi.md` | 见下 | 见下 | 见下 | 04-D Vulkan（存在性已闭合） |
| 5 | `05_android_graphics_stack.md` | 见下 | 见下 | 见下 | 04-E 图形栈依赖（实测依赖图） |
| 6 | `06_abi_compatibility_matrix.md` | 见下 | 见下 | 见下 | 04-F 四组合矩阵（修订版） |
| 7 | **`07_device_evidence.md`** | 见下 | 见下 | 见下 | **新增**：真机证据登记与三件套解析 |
| 8 | `README.md` | — | — | — | 交付说明 |
| 9 | `tools/collect_device.sh` | 93 | 3,698 | `dac394480c017adb` | 只读采集脚本（首轮） |
| 10 | `MANIFEST.md` | 本文件 | — | — | — |

> 行数 / 字节 / SHA256 由 `§4.11` 的自校验命令生成，随文件变更而更新；本节不写死数字，避免"表格与实际不一致"。

### 2.1 二进制资产

| 项 | 状态 |
| --- | --- |
| 厂商 `.so` | **未采集、未入库**（仅登记路径/大小/SHA256） |
| CSF 固件 `.bin` | **未采集、未入库**（仅登记路径/大小/SHA256） |
| VINTF / init.rc | **未采集内容、未入库**（仅登记文件名与大小） |
| 采集输出三件套 | **未入库**（仅登记哈希，见 §2.2） |

### 2.2 设备采集输入登记（[D] 证据源）

| 文件 | 字节 | 行数 | SHA256 |
| --- | ---: | ---: | --- |
| `stage4_inventory.txt` | 85,684 | 1,732 | `d897ed473ae18330845d0ca6cfadbb8b3d279aedf940082ab98a2d35af1729a6` |
| `stage4_file_metadata.txt` | 6,055 | 120 | `c8a856b525a3a090b4274904215c1c42c8f9c9d704f790b6eecb6f248e5f59dc` |
| `stage4_elf_analysis.txt` | 79,123 | 1,244 | `9f95078fe536076a8bb00825a6898cb3de6ec6fb1f1bc3813f07f8b8ab8b3e33` |

> 三份文件在设备侧生成（`/sdcard/GPU_AUDIT_STAGE4/`），采集时间 2026-11-15 19:54 与 20:02（CST）。本仓库只登记哈希与解析结论，**不登记正文**，避免间接扩散厂商信息。

---

## 3. 内容索引：每条结论落在哪一节

| 任务书要求 | 落点 |
| --- | --- |
| 04-A 组件清点（路径/大小/SHA256/版本串/架构/BuildID/依赖） | `01` §2（双轨结论）、§3（实测路径台账）、§5（常量级标识）；逐对象明细见 `07` §5 |
| 04-B 固件版本串/格式/头部/型号/接口版本/加载流程/差异/校验 | `02` §1（流程）、§2（头结构）、**§3.0（三层证据）**、§3.1–3.3（版本检查）、§4（entry）、§5（接口版本）、§6（GLB 字段）、§7（失败路径） |
| 04-C DDK 版本/BuildID/UK ABI 协商/属性 ioctl/内存接口/UAPI 对照/错误处理 | `03` §1（实体+版本）、§2（协商）、§4（ioctl）、§5（结构体）、§7（标志）、§8（属性）、§11（内存） |
| 04-D Vulkan 版本/接口/CSF 依赖/UAPI 差异/兼容窗口 | `04` §1（实测：薄壳+依赖）、§2（UAPI 复用论证）、§4（验证路径状态）、§5（结论） |
| 04-E 依赖关系/buffer 路径/DRM/失败行为/降级 | `05` §2（通路）、§3（实测依赖图）、§4（DRM）、§6（失败）、§7（降级） |
| 04-F 四组合八维矩阵 + 最终回答 | `06` §1（总表）、§2（逐组合）、§3（最小范围）、§6（回答） |
| **真机证据整合** | **`07`（三件套解析、方法学限制、补采建议）** |
| 设备证据采集（首轮） | `tools/collect_device.sh` |

### 3.2 报告交付状态 vs 证据闭环状态

| 文件 | 报告交付 | 证据闭环 | 说明 |
| --- | :---: | :---: | --- |
| `01` | ✅ 已提交（`efd8547` + 本轮修订） | ⚠️ 部分 | 路径类 UNKNOWN 闭合；U4-01/04 未闭合 |
| `02` | ✅ | ❌ **核心未闭环** | 固件头字节未实测（U4-01） |
| `03` | ✅ | ⚠️ 部分 | 实体+依赖闭合；版本串/行为未闭合 |
| `04` | ✅ | ⚠️ 部分 | 存在性闭合；`api_version`/机制未闭合 |
| `05` | ✅ | ⚠️ 部分 | 依赖图闭合；bootloop 未闭合（P0） |
| `06` | ✅ | ⚠️ 部分 | 矩阵结论稳定；组合 B 证据等级下调 |
| `07` | ✅ | — | 本文件即证据登记，不含独立结论 |

> **不要把"六份报告已提交"读成"Stage 4 已闭环"。** 交付状态是文档维度的，闭环状态是证据维度的；当前 23 项 UNKNOWN 中仅 4 项闭合（另有 3 项部分闭合）。

---

## 4. 可执行复核命令（全部实测跑通）

### 4.1 核心判据：固件 header 版本

```bash
R49=01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard
R56=02_r56_source/mali_r56p0/driver/product/kernel/drivers/gpu/arm/midgard
grep -n "FIRMWARE_HEADER_VERSION_M" $R49/csf/mali_kbase_csf_firmware.c $R56/csf/mali_kbase_csf_firmware.c
# 期望：r49p1 = 0/3，r56p0 = 0/4
```

### 4.2 UK ABI 版本

```bash
grep -n "BASE_UK_VERSION" $R49/include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_ioctl.h \
                          02_r56_source/mali_r56p0/driver/product/kernel/include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_ioctl.h
# 期望：1.30 vs 1.39
```

### 4.3 能力阈值表

```bash
sed -n '148,166p' $R56/mali_kbase_core_linux.c
# 期望：18 项，含 {1,35} CSG_CS_USER_PAGE_ALLOCATION
```

### 4.4 ioctl 面比对

```bash
python3 - <<'EOF'
import re
R49="01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard"
R56="02_r56_source/mali_r56p0/driver/product/kernel/include/uapi/gpu/arm/midgard"
def c(root):
    d={}
    for f in ["mali_kbase_ioctl.h","csf/mali_kbase_csf_ioctl.h"]:
        for line in open(f"{root}/{f}",errors="ignore"):
            m=re.match(r'\s*#define\s+(KBASE_IOCTL_[A-Z0-9_]+)\s+_IOW?R?\(([^)]*)\)',line)
            if m: d[m.group(1)]=m.group(2).replace(" ","")
    return d
a,b=c(R49),c(R56)
print("r49p1",len(a),"r56p0",len(b))
print("共有且相同:",len([k for k in set(a)&set(b) if a[k]==b[k]]))
print("仅 r49p1:",sorted(set(a)-set(b)))
print("仅 r56p0:",sorted(set(b)-set(a)))
EOF
# 期望：r49p1 33 / r56p0 28 / 共有且相同 28 / 仅 r56p0 为空
```

### 4.5 `gpu_props` 结构体实测大小

```bash
python3 - <<'PY'
import re,os
for tag,path in [("r49","01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_gpu_props.h"),
                 ("r56","02_r56_source/mali_r56p0/driver/product/kernel/include/uapi/gpu/arm/midgard/mali_gpu_props.h")]:
    txt=open(path).read()
    m=re.search(r'(struct gpu_props_user_data \{.*?\n\};)',txt,re.S)
    hdr=("#include <stdio.h>\n#include <stddef.h>\n#include <stdint.h>\n"
         "typedef uint8_t __u8;typedef uint16_t __u16;typedef uint32_t __u32;typedef uint64_t __u64;\n"
         "#define BASE_GPU_NUM_TEXTURE_FEATURES_REGISTERS 4\n#define BASE_MAX_COHERENT_GROUPS 16\n#define GPU_MAX_JOB_SLOTS 16\n")
    open(f"/tmp/props_{tag}.c","w").write(hdr+m.group(1)+"\nint main(void){printf(\"%zu\\n\",sizeof(struct gpu_props_user_data));return 0;}\n")
PY
for t in r49 r56; do gcc -o /tmp/p_$t /tmp/props_$t.c && /tmp/p_$t; done
# 期望：568 / 592
```

### 4.6 属性 ID 未移位

```bash
python3 - <<'EOF'
import re
def c(p):
    return {m.group(1):int(m.group(2)) for m in re.finditer(r'#define\s+KBASE_GPUPROP_([A-Z0-9_]+)\s+(\d+)',open(p,errors='ignore').read())}
a=c("01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/mali_kbase_ioctl.h")
b=c("02_r56_source/mali_r56p0/driver/product/kernel/include/uapi/gpu/arm/midgard/mali_kbase_ioctl.h")
print("r49p1",len(a),"r56p0",len(b))
print("ID 值变化:",[k for k in set(a)&set(b) if a[k]!=b[k]])
print("新增:",{k:v for k,v in b.items() if k not in a})
EOF
# 期望：83 / 86 / ID 值变化 [] / 新增 {86,87,88}
```

### 4.7 固件 entry 类型差异

```bash
for f in $R49/csf/mali_kbase_csf_firmware.c $R56/csf/mali_kbase_csf_firmware.c; do
  echo "== $f"; grep -o "CSF_FIRMWARE_ENTRY_TYPE_[A-Z0-9_]*" $f | sort -u; done
# 期望：r56p0 多 CSF_FIRMWARE_ENTRY_TYPE_PAGE_FAULT_CNT
```

### 4.8 padding 校验的兼容让步

```bash
sed -n '152,167p' $R56/mali_kbase_ioctl_helpers.h
# 期望：注释 "padding bytes are set as zero here on behalf on user space"
```

### 4.9 dma-buf 依赖

```bash
readelf -sW 01_original_baseline/kernel_ref_mt6991/vendor_dlkm/mali_kbase_mt6991_r49.ko \
  | awk '$7=="UND"{print $8}' | grep -E "^(dma_buf|dma_fence|sync_file|ion_)" | sort -u
# 期望：18 个，零 ion_
```

### 4.10 文件哈希自校验

```bash
cd 05_userspace_firmware && sha256sum 0*.md README.md tools/collect_device.sh
```

### 4.11 真机证据复核（本阶段新增，需设备）

```bash
# 固件头 8 字节（U4-01，唯一能闭合该项的读法）
adb shell "od -An -tx1 -N 8 /vendor/firmware/mali_csffw.bin"
# 期望：6e 3a f1 c3 03 00 …（=0.3）或 6e 3a f1 c3 04 00 …（=0.4）

# DDK 自称版本（U4-04）
adb shell "grep -a -o -m 3 -E 'UK version [0-9]+\.[0-9]+' /vendor/lib64/egl/mt6991/libGLES_mali.so"
adb shell "grep -a -o -m 3 -E 'r[0-9]{2}p[0-9]-[0-9a-z]+' /vendor/lib64/egl/mt6991/libGLES_mali.so"
```

> 三条命令均只读、无需 root（固件 644、库 644），不落地任何二进制。返回结果前，U4-01/U4-04 保持 UNKNOWN。

---

## 5. 来源完整性

| 证据 | 来源 | 完整性 |
| --- | --- | --- |
| r49p1 UAPI 头 | `01_original_baseline/mtk_kernel_modules/.../include/uapi/gpu/arm/midgard/` | **21 个全在** |
| r56p0 UAPI 头 | `02_r56_source/mali_r56p0/driver/product/kernel/include/uapi/gpu/arm/midgard/` | **19 个全在** |
| r49p1 固件加载器 | `.../csf/mali_kbase_csf_firmware.c` | 完整 |
| r56p0 固件加载器 | `.../csf/mali_kbase_csf_firmware.c` | 完整 |
| 能力表 | `.../mali_kbase_core_linux.c` | 完整 |
| kbase `.ko` | `kernel_ref_mt6991/vendor_dlkm/` | 完整（`not stripped`） |
| 固件实体 | 设备 `/vendor/firmware/mali_csffw.bin` | **元数据完整（大小/哈希）；字节未取** |
| 用户态 blob | 设备 `/vendor/lib64/…` | **元数据部分（9 个 ELF 的头/动态段）** |
| 三份采集输出 | 设备 `/sdcard/GPU_AUDIT_STAGE4/` | 完整副本，已登记哈希 |

### 5.1 方法学陷阱（累计，含本轮新增）

| 陷阱 | 表现 | 纠正 |
| --- | --- | --- |
| 比较口径错误 | 把 JM 头当基线 → "5 个内存标志位消失" | 限定 CSF 视图 → 24/24 一致 |
| 同名不同义 | `*_FLAGS_KERNEL_ONLY` 两版含义不同 | 展开宏值而非比名字 |
| 结构体≠ABI | `gpu_props` +24 字节 → 误判越界 | 查序列化路径 + size 协商 |
| 版本化结构体 | 同号 58 有两种 size → 误判冲突 | 查 `_IOC_SIZE` 编码 |
| **仓库缺失 ≠ 设备缺失** | 把"仓库无 Vulkan"写成"无 Vulkan ICD" | 分双轨登记（`01` §1.2） |
| **元数据 ≠ 实体字段** | 把"有固件文件"当成"知道 header 版本" | 三层证据拆分（`02` §3.0） |
| **不链接 ≠ 不依赖** | 把"HWC 不 NEEDED Mali"写成"HWC 免疫" | 追 `libged` 事件面（`05` §3.2） |
| **依赖 ≠ 会崩** | 撤"免疫"时反向过冲为"ged 装载失败" | 回查 TASK 03 反依赖定理：`ged→kbase` 为 0，故只能推"降级" |
| **协商 ≠ 校验** | 把 `min()` 当成版本校验 | 读 `kbase_api_handshake` 全文（`03` §1.5） |

---

## 6. 未决项

### 6.1 UNKNOWN 汇总（23 项，闭合 4 项，部分闭合 3 项）

| 优先级 | ID | 内容 | 状态 |
| --- | --- | --- | --- |
| **P0** | U4-01 | 原厂固件 header 实际值 | **开放**（8 字节可闭合） |
| **P0** | U4-04 | DDK 自称 UK ABI / padding 清零 / props 严格校验 | 部分闭合（实体+依赖已取） |
| **P0** | U4-10 | GPU 失败后是否 bootloop | 开放 |
| **P0** | U4-12 | R56p0 固件是否匹配 G925 MC12 | 开放 |
| P1 | U4-02 | 原厂固件运行时 GLB 版本 | 开放 |
| P1 | U4-11 | 原厂固件 GLB 尾部版本号 | 开放 |
| P1 | U4-14 | DDK 是否用被删的 5 个 ioctl | 开放 |
| P1 | U4-15 | DDK 对 props 新 ID 的处理 | 开放 |
| P1 | U4-17 | 薄壳 `api_version` / 加载机制 | 开放 |
| P1 | **U4-22** | `libged` 失效对 mapper/HWC 的传导 | **新增开放** |
| P2 | U4-06/07/16/19/20/21 | 见各章 | 部分闭合 |
| P3 | U4-13/18/**U4-23** | NX 字段 / 同批构建 / gpud 同名符号 | 开放或判据不足 |
| ✅ 闭合 | U4-03 | DTB 无 `firmware-name` | 双向确认 |
| ✅ 闭合 | U4-05 | Vulkan 是否存在 | **存在（薄壳）** |
| ✅ 闭合 | U4-08 | HWC 是否依赖 DDK | **不依赖** |
| ✅ 闭合 | U4-09 | VINTF / init | **实测齐备** |

### 6.2 本阶段未做（按任务书限制）

- 未修改任何 r49p1 / r56p0 源码
- 未生成补丁
- 未编译内核或模块
- 未替换任何 `.so` 或固件
- 未部署设备、未刷写、未改分区
- 未上传厂商二进制
- 未进入 Stage 5
- **未要求用户重跑已有采集项目**（三件套已足够支撑本轮全部结论）

---

## 7. 目录边界

```
05_userspace_firmware/
├── README.md
├── MANIFEST.md
├── 01_component_inventory.md
├── 02_csf_firmware_abi.md
├── 03_gles_egl_abi.md
├── 04_vulkan_abi.md
├── 05_android_graphics_stack.md
├── 06_abi_compatibility_matrix.md
├── 07_device_evidence.md          # 真机证据登记（本轮新增）
└── tools/
    └── collect_device.sh          # 只读采集，不落地二进制
```

**不设** `firmware/`、`userspace/` 等二进制存放目录——本阶段不采集二进制。

---

## 8. 登记规则

1. 任何新增二进制必须先登记 SHA256 与来源，且注明**是否允许再分发**
2. 每条结论必须标注证据等级（**[D]**/[E1]/[E2]/[E3]/[U]）与三态（已实测/静态分析/尚未验证）
3. [U] 结论不得在 README 或汇报中表述为"可行/兼容"
4. 引用 TASK 03 结论时须注明章节，不得只写"已验证"
5. 修改任一报告后须重算 §2 的 SHA256 与合计
6. **[D] 结论必须能指回 §2.2 三份输入中的具体段落**，否则降级为 [E2]

---

## 9. 修订记录

| 日期 | 版本 | 变更 |
| --- | --- | --- |
| 2026-11-15 | v1.0 | 首次提交：6 份报告 + README + MANIFEST + 采集脚本。核心结论：固件硬不兼容（组合 B 否决）；用户态契约兼容（组合 C 候选） |
| 2026-11-15 | **v1.1** | **补充核验**：整合三份真机采集（新增 `07`）；固件 header 由"实测 0.3"降级为"E2 推理 + U4-01 UNKNOWN"；Vulkan 存在性由 UNKNOWN 升级为已闭合；撤回"gralloc/mapper/HWC 免疫"；`min()` 语义由"校验"更正为"夹取"；新增 U4-22/U4-23；README 修正为 Android 17 / SDK 37 / kernel 6.6.143 |
