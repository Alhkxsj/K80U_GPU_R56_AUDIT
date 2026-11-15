# MANIFEST — 05_userspace_firmware

> TASK 04 交付登记。**不含任何厂商私有二进制**（本阶段未采集、未上传）。

---

## 1. 基准核对

| 项 | 值 |
| --- | --- |
| 仓库 | `github.com/JiangXue5/K80U_GPU_R56_AUDIT` |
| 分支 | `main` |
| 本阶段起始 HEAD | `cbe7a26`（03-REA 补充审计） |
| 原厂基线 | `mali-r49p1-03bet0`（CSF UK ABI **1.30**） |
| 目标基线 | `mali-r56p0-18eac0`（CSF UK ABI **1.39**） |
| 内核参照 | Linux 6.6 / MT6991 |

### 1.1 证据边界声明

本阶段**未获得**任何用户态二进制或 CSF 固件实体。因此：

| 结论类型 | 证据强度 | 覆盖范围 |
| --- | --- | --- |
| UAPI 契约兼容性 | **[E1]** 完整 | 可下确定结论 |
| 固件加载机制 | **[E1]** 完整 | 可下确定结论 |
| 固件本体属性 | **[U]** 无 | 只能给"必须是什么"的约束 |
| 用户态实现行为 | **[U]** 无 | 只能给"契约允许什么"的边界 |
| Android 图形栈 | **[E3]** 惯例 | 只能给架构级判断 |

> **任务书要求"没有固件实体时，只能完成加载代码与接口定义分析，不能宣称已验证固件兼容"**。本目录严格遵循：`02` 章的全部结论均标注为"分析加载代码得出"，而非"验证固件得出"。

---

## 2. 文件清单

| # | 文件 | 行数 | 字节 | SHA256（前 16） | 内容 |
| ---: | --- | ---: | ---: | --- | --- |
| 1 | `01_component_inventory.md` | 175 | 9,292 | `b47759438625a61a` | 04-A 组件清点 + 证据边界 |
| 2 | `02_csf_firmware_abi.md` | 396 | 15,413 | `21743a6253044f9e` | 04-B 固件 ABI（**硬不兼容**） |
| 3 | `03_gles_egl_abi.md` | 736 | 30,168 | `ac45a443f90b9a0a` | 04-C GLES/EGL 契约比对 |
| 4 | `04_vulkan_abi.md` | 142 | 6,807 | `6856c97fe6f4adce` | 04-D Vulkan（证据不足） |
| 5 | `05_android_graphics_stack.md` | 259 | 11,073 | `9567824b2df805cd` | 04-E 图形栈依赖 |
| 6 | `06_abi_compatibility_matrix.md` | 288 | 14,513 | `1e68db1cb5b7b914` | 04-F 四组合矩阵 |
| 7 | `README.md` | 85 | 4,610 | `b4f1097823b38ce6` | 交付说明 |
| 8 | `tools/collect_device.sh` | 93 | 3,698 | `dac394480c017adb` | 只读采集脚本 |
| 9 | `MANIFEST.md` | 本文件 | — | — | — |

**六份报告合计 1,996 行 / 87,266 字节**（不含 `README.md` 与 `tools/`）。

### 2.1 二进制资产

| 项 | 状态 |
| --- | --- |
| 厂商 `.so` | **未采集、未入库** |
| CSF 固件 `.bin` | **未采集、未入库** |
| VINTF / init.rc | **未采集、未入库** |

---

## 3. 内容索引：每条结论落在哪一节

| 任务书要求 | 落点 |
| --- | --- |
| 04-A 组件清点（路径/大小/SHA256/版本串/架构/BuildID/依赖） | `01` §3（缺失台账）、§5（常量级标识） |
| 04-B 固件版本串/格式/头部/型号/接口版本/加载流程/差异/校验 | `02` §1（流程）、§2（头结构）、§3（版本检查）、§4（entry）、§5（接口版本）、§6（GLB 字段）、§7（失败路径） |
| 04-C DDK 版本/BuildID/UK ABI 协商/属性 ioctl/内存接口/UAPI 对照/错误处理 | `03` §1（版本）、§2（协商）、§4（ioctl）、§5（结构体）、§7（标志）、§8（属性）、§11（内存） |
| 04-D Vulkan 版本/接口/CSF 依赖/UAPI 差异/兼容窗口 | `04` §2（UAPI 复用论证）、§4（验证路径）、§5（结论） |
| 04-E 依赖关系/buffer 路径/DRM/失败行为/降级 | `05` §2（通路）、§3（依赖）、§4（DRM）、§6（失败）、§7（降级） |
| 04-F 四组合八维矩阵 + 最终回答 | `06` §1（总表）、§2（逐组合）、§3（最小范围）、§6（回答） |
| 设备证据采集 | `tools/collect_device.sh`、`README.md` §如何补齐 |

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
| **固件实体** | — | **缺失** |
| **用户态 blob** | — | **缺失** |

### 5.1 方法学陷阱（本轮踩过并纠正）

| 陷阱 | 表现 | 纠正 |
| --- | --- | --- |
| 比较口径错误 | 把 JM 头当基线 → "5 个内存标志位消失" | 限定 CSF 视图 → 24/24 一致 |
| 同名不同义 | `*_FLAGS_KERNEL_ONLY` 两版含义不同 | 展开宏值而非比名字 |
| 结构体≠ABI | `gpu_props` +24 字节 → 误判越界 | 查序列化路径 + size 协商 |
| 版本化结构体 | 同号 58 有两种 size → 误判冲突 | 查 `_IOC_SIZE` 编码 |

---

## 6. 未决项

### 6.1 UNKNOWN 汇总（21 项，闭合 1 项）

| 优先级 | ID | 内容 |
| --- | --- | --- |
| **P0** | U4-01 | 原厂固件 header minor 实际值 |
| **P0** | U4-04 | DDK 的 UK ABI 实际值 / padding 清零 / props 严格校验 |
| **P0** | U4-10 | GPU 失败后是否 bootloop |
| **P0** | U4-12 | R56p0 固件是否匹配 G925 MC12 |
| P1 | U4-02 | 原厂固件运行时 GLB 版本 |
| P1 | U4-05 | 是否存在 Vulkan ICD |
| P1 | U4-11 | 原厂固件 GLB 尾部版本号 |
| P1 | U4-14 | DDK 是否用被删的 5 个 ioctl |
| P1 | U4-15 | DDK 对 gpu_props 新 ID 的处理 |
| P1 | U4-17 | ICD 的 api_version / library_path |
| P2 | U4-06/07/08/09/16/18/19/20/21 | 见各章 |
| P3 | U4-13 | NX 相关 GLB 字段使用 |
| ✅ 闭合 | U4-03 | DTB 无 `firmware-name`（TASK 03 已查） |

### 6.2 本阶段未做（按任务书限制）

- 未修改任何 r49p1 / r56p0 源码
- 未生成补丁
- 未编译内核或模块
- 未替换任何 `.so` 或固件
- 未部署设备、未刷写、未改分区
- 未上传递厂商二进制
- 未进入 Stage 5

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
└── tools/
    └── collect_device.sh          # 只读采集，不落地二进制
```

**不设** `firmware/`、`userspace/` 等二进制存放目录——本阶段不采集二进制。

---

## 8. 登记规则

1. 任何新增二进制必须先登记 SHA256 与来源，且注明**是否允许再分发**
2. 每条结论必须标注证据等级（[E1]/[E2]/[E3]/[U]）
3. [U] 结论不得在 README 或汇报中表述为"可行/兼容"
4. 引用 TASK 03 结论时须注明章节，不得只写"已验证"
5. 修改任一报告后须重算 §2 的 SHA256 与合计

---

## 9. 修订记录

| 日期 | 版本 | 变更 |
| --- | --- | --- |
| 2026-11-15 | v1.0 | 首次提交：6 份报告 + README + MANIFEST + 采集脚本。核心结论：固件硬不兼容（组合 B 否决）；用户态契约兼容（组合 C 候选） |
