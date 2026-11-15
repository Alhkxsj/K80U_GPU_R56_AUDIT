# MANIFEST — 05_userspace_firmware

> TASK 04 交付登记。**不含任何厂商私有二进制**：全部 `.so` / `.bin` / `.ko` 实体均未采集、未上传，只登记路径、大小、SHA256 与分析结论。
>
> 本文件同时记录**三种状态**，且三者不等价：
> - **报告交付状态**：六份报告 + 两份登记/审计（`07`、`08`）是否已提交（§2、§3.2）；
> - **来源归属状态**：每条设备证据属 A（厂商分区文件）/ B（第三方内核运行时）/ C（厂商模块）（§3.3）；
> - **证据闭环状态**：每项 UNKNOWN 是否已被证据消解（§6）。

---

## 1. 基准核对

| 项 | 值 |
| --- | --- |
| 仓库 | `github.com/JiangXue5/K80U_GPU_R56_AUDIT` |
| 分支 | `main` |
| TASK 04 首轮 HEAD | `cbe7a26`（03-REA 补充审计）→ 提交 `efd8547` |
| TASK 04 补充核验基线 | `efd8547` → 提交 `04-fix: Stage 4 真机证据整合与兼容性复核` |
| TASK 04 来源审计基线 | `a5b9a51` → 提交 `stage4: audit third-party GKI device evidence provenance` |
| TASK 04 P0 补采工具基线 | `0c1d1dd` → 提交 `stage4: add minimal P0 device evidence collector`（`65006de`） |
| TASK 04 P0 补采整合基线 | `65006de` → 提交 `stage4: close U4-01 with firmware header bytes, advance U4-04` |
| TASK U4-24 采集工具基线 | `e3d7bc0` → 提交 `stage4: add GPU module identity audit`（**工具就绪，未在真机运行**） |
| 设备运行时内核 | **第三方 GKI 构建**（KernelSU 补丁；GKI `android15-6.6`，源码提交 `f9aa2fec23c3…`，sublevel 143，patch `2026-10`）**[D·B]**+**[B]** |
| 设备 ROM | HyperOS `OS4.0.3.0.XONCNM` / Android 17 / SDK 37 **[D·A]** |
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

> **纪律**：`02` 章的核心判据已由字节读数坐实——**源码要求 0.3 / 0.4 + 原厂实测 0.3**。三轮之间结论未变，变的是证据等级（详见 `02` §9 文末三段式留痕）。**仍不得**把元数据（大小 / 哈希 / strings）当作实体字段的证据。

---

## 2. 文件清单

| # | 文件 | 行数 | 字节 | SHA256（前 16） | 内容 |
| ---: | --- | ---: | ---: | --- | --- |
| 1 | `01_component_inventory.md` | 见下 | 见下 | 见下 | 04-A 组件清点（**三轨**：仓库 / 真机 / 来源归属 A·B·C） |
| 2 | `02_csf_firmware_abi.md` | 见下 | 见下 | 见下 | 04-B 固件 ABI（三层证据） |
| 3 | `03_gles_egl_abi.md` | 见下 | 见下 | 见下 | 04-C GLES/EGL 契约 + 实体 |
| 4 | `04_vulkan_abi.md` | 见下 | 见下 | 见下 | 04-D Vulkan（存在性已闭合） |
| 5 | `05_android_graphics_stack.md` | 见下 | 见下 | 见下 | 04-E 图形栈依赖（实测依赖图） |
| 6 | `06_abi_compatibility_matrix.md` | 见下 | 见下 | 见下 | 04-F 四组合矩阵（修订版） |
| 7 | **`07_device_evidence.md`** | 见下 | 见下 | 见下 | **新增**：真机证据登记与三件套解析（含来源前置） |
| 8 | **`08_kernel_provenance_audit.md`** | 见下 | 见下 | 见下 | **新增**：第三方 GKI 环境下的设备证据来源审计 |
| 9 | `README.md` | — | — | — | 交付说明 |
| 10 | `tools/collect_device.sh` | 93 | 3,698 | `dac394480c017adb` | 只读采集脚本（首轮，adb 方式） |
| 11 | **`tools/collect_stage4_p0.sh`** | 284 | 11,547 | `b4083e0158748959` | **新增**：P0 最小只读采集（**手机端，无 adb**）；固件前 8 字节 + DDK 版本串；工具自检；失败报因 |
| 12 | **`tools/README_stage4_p0.md`** | 234 | 8,547 | `001e85e8e235ad1b` | 手机执行指南（aShell You、三种传脚本方式、判读表、兜底命令）+ **本机执行结果摘要** |
| 13 | **`tools/collect_gpu_module_identity.sh`** | 396 | 17,644 | `d6ff5a2c0efebad2` | **新增**：U4-24 模块身份采集（只读、无 adb、工具缺失输出 `NOT_AVAILABLE`、无 `modinfo` 依赖、路径多根搜索、压缩/内建降级判定） |
| 14 | **`tools/README_gpu_module_identity.md`** | 199 | 9,217 | `2238d43031af3108` | **新增**：手机执行指南 + 三行核心判读表 + `lsmod` 尺寸口径说明 + 兜底命令 + 失败排查 |
| 15 | `MANIFEST.md` | 本文件 | — | — | — |

> 行数 / 字节 / SHA256 由 §4.10 的自校验命令生成，随文件变更而更新；本节不写死数字，避免"表格与实际不一致"。

### 2.1 二进制资产

| 项 | 状态 |
| --- | --- |
| 厂商 `.so` | **未采集、未入库**（仅登记路径/大小/SHA256） |
| CSF 固件 `.bin` | **未采集、未入库**（仅登记路径/大小/SHA256） |
| VINTF / init.rc | **未采集内容、未入库**（仅登记文件名与大小） |
| 采集输出三件套 | **未入库**（仅登记哈希，见 §2.2） |
| P0 补采输出（纯文本） | **已产生、未入库**：设备端 `/data/local/tmp/gpu_audit_p0/stage4_p0_20261115_232021.txt`，仅登记其内容摘要（§2.3）；**U4-01 已闭合 / U4-04 部分闭合** |
| U4-24 模块身份输出（纯文本） | **尚未产生**。脚本会把结果写到设备端 `/data/local/tmp/gpu_audit_mod/stage4_mod_<ts>.txt`；回传后只登记摘要与哈希，**不登记正文**，**不含任何 `.ko`** |

### 2.2 设备采集输入登记（[D] 证据源）

| 文件 | 字节 | 行数 | SHA256 |
| --- | ---: | ---: | --- |
| `stage4_inventory.txt` | 85,684 | 1,732 | `d897ed473ae18330845d0ca6cfadbb8b3d279aedf940082ab98a2d35af1729a6` |
| `stage4_file_metadata.txt` | 6,055 | 120 | `c8a856b525a3a090b4274904215c1c42c8f9c9d704f790b6eecb6f248e5f59dc` |
| `stage4_elf_analysis.txt` | 79,123 | 1,244 | `9f95078fe536076a8bb00825a6898cb3de6ec6fb1f1bc3813f07f8b8ab8b3e33` |

> 三份文件在设备侧生成（`/sdcard/GPU_AUDIT_STAGE4/`），采集时间 2026-11-15 19:54 与 20:02（CST）。本仓库只登记哈希与解析结论，**不登记正文**，避免间接扩散厂商信息。

### 2.3 P0 补采登记（2026-11-15 23:20）

| 项 | 值 |
| --- | --- |
| 文件 | `stage4_p0_20261115_232021.txt`（设备侧 `/data/local/tmp/gpu_audit_p0/`） |
| 生成方式 | `tools/collect_stage4_p0.sh` v1.0，POSIX sh，只读 |
| 采集时间 | 2026-11-15 23:20:21 CST |
| 设备 / 内核 | `25060RK16C` / `dali`，Android 17 (SDK 37)，`6.6.143-android15-8-gf9aa2fec23c3-4k` |
| 环境标记 | `u:r:ksu:s0`，UID 0（**第三方 GKI 内核**，B 类环境） |
| 工具可用性 | `od` YES · `xxd` YES · `strings` YES · `readelf` YES · `hexdump` **NO** |
| **关键读数** | 固件前 8 字节 `6e 3a f1 c3 03 00 00 00` → **header 0.3**；DDK `r49p1-03bet0` |
| 入库内容 | 仅上述文本摘要；**无任何二进制** |

---

## 3. 内容索引：每条结论落在哪一节

| 任务书要求 | 落点 |
| --- | --- |
| 04-A 组件清点（路径/大小/SHA256/版本串/架构/BuildID/依赖） | `01` §2（**三轨**结论）、§3（实测路径台账）、§5（常量级标识）；逐对象明细见 `07` §5 |
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
| `01` | ✅ 已提交（`efd8547` + 多轮修订） | ✅ 路径类 + 固件头 | U4-01 已闭合；U4-04 版本代次已取 |
| `02` | ✅ | ✅ **核心已闭环** | 固件头字节已实测：`03`/`00` → 0.3（§3.0.5） |
| `03` | ✅ | ⚠️ 部分 | 实体+依赖+**版本代次**闭合；padding/props 行为未闭合 |
| `04` | ✅ | ⚠️ 部分 | 存在性闭合；`api_version`/机制未闭合 |
| `05` | ✅ | ⚠️ 部分 | 依赖图闭合；bootloop 未闭合（P0） |
| `06` | ✅ | ⚠️ 部分 | 矩阵结论稳定；**组合 B 升为实测否决** |
| `07` | ✅ | — | 本文件即证据登记，不含独立结论 |
| `08` | ✅ | — | 来源审计：分类与判定，不新增 ABI 结论；§3.6 为 U4-24 的判定矩阵 |

> **不要把"六份报告已提交"读成"Stage 4 已闭环"。** 交付状态是文档维度的，闭环状态是证据维度的；当前 27 项 UNKNOWN 中 **5 项闭合**（另有 3 项部分闭合），P0 由 4 降为 3。**同样不要把"证据已实测"读成"原厂环境实测"**，见 §3.3。

### 3.3 来源归属状态（A / B / C）

| 类 | 内容 | 来源 | 是否被 2026-11-14 安装改动 | 详见 |
| --- | --- | --- | :---: | --- |
| **A** | `/vendor` GPU 库、`mali_csffw.bin`、配置、VINTF | 厂商分区（HyperOS `OS4.0.3.0`） | **否** | `08` §2.2 |
| **B** | `uname`、`lsmod`、`/sys/module`、`/dev/mali0`、服务、属性、DT | **第三方 GKI 内核**（KernelSU 补丁） | 是（内核被替换） | `08` §2.3 |
| **C** | Kbase / MGM / PMA / GED / GPUFreq / GPUEB 等 `.ko` | 厂商 `/vendor_dlkm` | **否**（`do.modules=0`） | `08` §2.4 |

> 判据：SELinux 域 `u:r:ksu:s0`（B 为第三方）；安装脚本 `block=boot` / `do.modules=0` / `do.systemless=0`（A、C 未变）；产物清单无 `.ko` / 固件 / `.so`。

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

### 4.11 真机证据复核（**已执行**，2026-11-15 23:20）

```bash
# 固件头 8 字节（U4-01）
adb shell "od -An -tx1 -N 8 /vendor/firmware/mali_csffw.bin"
# 实测：6e 3a f1 c3 03 00 00 00  → 0.3（已闭合）

# DDK 自称版本（U4-04）
adb shell "grep -a -o -m 3 -E 'UK version [0-9]+\.[0-9]+' /vendor/lib64/egl/mt6991/libGLES_mali.so"
# 实测：NOT_FOUND
adb shell "grep -a -o -m 3 -E 'r[0-9]{2}p[0-9]-[0-9a-z]+' /vendor/lib64/egl/mt6991/libGLES_mali.so"
# 实测：r49p1-03bet0
```

> 三条命令均只读，不落地任何二进制。**本轮已由用户在手机端执行**（无 adb，改用 `tools/collect_stage4_p0.sh`），结果见 §2.3 与 `07` §4.5 / §5.4。
>
> **可选（非 P0）**：U4-24 模块 `vermagic` / `sha256sum`（见 `07` §10.3）；U4-27 `mount | grep -i overlay`。两者均只回传文本。**本次未执行**。

### 4.12 U4-24 模块身份采集（**已就绪，未执行**）

```bash
# 手机端（aShell You，已 root）；只读，无 adb，输出纯文本
su
sh /data/local/tmp/c.sh          # c.sh = tools/collect_gpu_module_identity.sh
cat /data/local/tmp/gpu_audit_mod/stage4_mod_*.txt
```

离线可先复核脚本语法：

```bash
sh -n 05_userspace_firmware/tools/collect_gpu_module_identity.sh   # dash
bash -n 05_userspace_firmware/tools/collect_gpu_module_identity.sh # bash
```

> 输出中的关键三行：`VERMAGIC_CHECK:` / `VERMAGIC_MATCHES_UNAME_R:` / `FILE_SHA256:`。
> **注意**：`LSMOD_SIZE_BYTES` 是运行时内存（`core_layout.size`，页对齐），**不是文件大小**，不可与仓库 `.ko` 字节数相减（`08` §3.6.2）。

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
| **第三方内核构建记录** | `GKI_KernelSU_SUSFS` Actions run `43629124514`（公开页） | **完整**（矩阵参数、产物清单、模板源码）；**不代表设备字节** |
| **AnyKernel3 模板** | `WildKernels/AnyKernel3 @ gki-2.0` 的 `anykernel.sh` | **完整**（`block=boot` / `do.modules=0` / `do.systemless=0`） |
| 设备侧 GPU `.ko` 实体 | `/vendor_dlkm`（或 `/vendor/lib64/modules`） | **未采集**（仅装载状态 + 版本串） |

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
| **实测 ≠ 原厂实测** | 把 B 类（第三方内核运行时）写成"原厂内核实测" | 查 `u:r:ksu:s0` + 安装范围（`08` §2.5） |
| **装载 ≠ 同源** | 把"12 个 `.ko` 已装载"写成"仓库 12 个 `.ko` 已装载" | vermagic `6.6.118` vs 运行内核 `6.6.143`（`08` §3.4） |
| **补丁 ≠ 改 GPU 驱动** | 把第三方调度/调频补丁的影响写成"GPU 驱动被改" | GKI `common/` 不含 mali，补丁结构上改不到（`08` §4.1） |

---

## 6. 未决项

### 6.1 UNKNOWN 汇总（27 项，闭合 5 项，部分闭合 3 项）

| 优先级 | ID | 内容 | 状态 |
| --- | --- | --- | --- |
| **P0** | ~~U4-01~~ | 原厂固件 header 实际值 | ✅ **闭合**：`03`/`00` → 0.3（`07` §4.5） |
| **P0** | U4-04 | DDK 自称 UK ABI / padding 清零 / props 严格校验 | 部分闭合（**版本代次 `r49p1-03bet0` 已取**；padding/props 开放） |
| **P0** | U4-10 | GPU 失败后是否 bootloop | 开放 |
| **P0** | U4-12 | R56p0 固件是否匹配 G925 MC12 | 开放 |
| P1 | U4-02 | 原厂固件运行时 GLB 版本 | 开放 |
| P1 | U4-11 | 原厂固件 GLB 尾部版本号 | 开放 |
| P1 | U4-14 | DDK 是否用被删的 5 个 ioctl | 开放 |
| P1 | U4-15 | DDK 对 props 新 ID 的处理 | 开放 |
| P1 | U4-17 | 薄壳 `api_version` / 加载机制 | 开放 |
| P1 | **U4-22** | `libged` 失效对 mapper/HWC 的传导 | **新增开放** |
| P1 | **U4-24** | 设备侧 GPU `.ko` 的路径 / 文件大小 / SHA256 / vermagic / srcversion（a）；`__ksymtab` CRC 与 kCFI 常量（b） | **a：工具已就绪、待执行**；**b：未开始**（已证"非仓库构建"，见 `08` §3.6） |
| P1 | **U4-25** | 第三方内核与原厂 boot 的运行时差异范围 | **新增开放** |
| P2 | **U4-26** | 设备当前 boot 是否即所链接 run 的产物 | **新增开放**（时间戳不可判） |
| P2 | **U4-27** | `/vendor` 是否被 KSU/NoMount overlay 覆盖 | **新增开放**（未采 mount 表） |
| P2 | U4-06/07/16/19/20/21 | 见各章 | 部分闭合 |
| P3 | U4-13/18/**U4-23** | NX 字段 / 同批构建 / gpud 同名符号 | 开放或判据不足 |
| ✅ 闭合 | U4-01 | 原厂固件 header 实际值 | **0.3**（实测 16 字节） |
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
- **U4-24 采集脚本未在真机运行**（仅语法检查 + 5 条伪造分支演练）

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
├── 07_device_evidence.md          # 真机证据登记（补充核验新增）
├── 08_kernel_provenance_audit.md  # 来源审计（来源审计轮新增）
└── tools/
    ├── collect_device.sh          # 只读采集，不落地二进制（首轮，adb）
    ├── collect_stage4_p0.sh       # P0 最小采集（手机端，无 adb）
    ├── README_stage4_p0.md        # 手机执行指南与判读表
    ├── collect_gpu_module_identity.sh   # U4-24 模块身份采集（手机端，无 adb）
    └── README_gpu_module_identity.md    # 该脚本的执行指南与判读表
```

**不设** `firmware/`、`userspace/` 等二进制存放目录——本阶段不采集二进制。

---

## 8. 登记规则

1. 任何新增二进制必须先登记 SHA256 与来源，且注明**是否允许再分发**
2. 每条结论必须标注证据等级（**[D]**/[E1]/[E2]/[E3]/[U]）与三态（已实测/静态分析/尚未验证）
3. [U] 结论不得在 README 或汇报中表述为"可行/兼容"
4. 引用 TASK 03 结论时须注明章节，不得只写"已验证"
5. 修改任一报告后须重算 §2 的 SHA256 与合计
6. **[D] 结论必须能指回 §2.2 三份输入（或 §2.3 P0 补采）中的具体段落**，否则降级为 [E2]
7. **每条 [D] 结论必须标注来源类别**（`[D·A]` / `[D·B]` / `[D·C]`）；无法归类者不得写作 [D]
8. **[B]（构建记录）不得替代 [D]（设备实测）**：CI 运行页只能证明"构建了什么"，不能证明"设备在跑什么"
9. **"原厂"一词仅可用于厂商发布物**（分区文件、源码标签、ROM 版本）；不得用于运行时状态

---

## 9. 修订记录

| 日期 | 版本 | 变更 |
| --- | --- | --- |
| 2026-11-15 | v1.0 | 首次提交：6 份报告 + README + MANIFEST + 采集脚本。核心结论：固件硬不兼容（组合 B 否决）；用户态契约兼容（组合 C 候选） |
| 2026-11-15 | **v1.1** | **补充核验**：整合三份真机采集（新增 `07`）；固件 header 由"实测 0.3"降级为"E2 推理 + U4-01 UNKNOWN"；Vulkan 存在性由 UNKNOWN 升级为已闭合；撤回"gralloc/mapper/HWC 免疫"；`min()` 语义由"校验"更正为"夹取"；新增 U4-22/U4-23；README 修正为 Android 17 / SDK 37 / kernel 6.6.143 |
| 2026-11-15 | **v1.2** | **来源审计**（新增 `08`）：确认设备运行**第三方 GKI 内核**（KernelSU 补丁，`f9aa2fec`），非原厂 boot；建立 A/B/C 三类归属并重标 `01`/`07`/`06`；核验安装范围（仅 `boot`，`do.modules=0`，产物无 `.ko`/固件/`.so`）；判定设备 `.ko` 与仓库基线 `.ko` **非同一构建**（vermagic 118 vs 143）；定性补丁间接影响；新增 U4-24…U4-27（23→27 项）；增 [B]/[P] 两级证据与 `[D·A/B/C]` 细分 |
| 2026-11-15 | **v1.3** | **P0 补采工具**（`stage4: add minimal P0 device evidence collector`）：新增 `tools/collect_stage4_p0.sh`（284 行，POSIX sh，只读，无 adb，工具自检，失败报因，版本串缺失输出 `NOT_FOUND` 而非 `INCOMPATIBLE`）与 `tools/README_stage4_p0.md`（218 行，aShell You 执行指南 + 判读表 + 兜底命令）。**仅为采集准备，U4-01 / U4-04 状态未变（仍 UNKNOWN）**；脚本已在 `dash`/`bash` 下通过语法检查并对 4 条分支做伪造文件演练，**未在真机运行** |
| 2026-11-15 | **v1.4** | **P0 补采执行与整合**（`stage4: close U4-01 with firmware header bytes, advance U4-04`）：用户回传 `stage4_p0_20261115_232021.txt`。**U4-01 闭合**：固件前 16 字节 `6e 3a f1 c3 03 00 00 00 00 00 0a 03 00 00 00 00`，header **0.3**（§2.3、`07` §4.5）。**U4-04 部分闭合**：DDK 内含 `r49p1-03bet0`，与 kbase `MODULE_VERSION` 同串 → 原厂三方配套（`07` §5.4）。组合 B 由「[E1]+[E2] 推理否决」升为「[E1]+[D·A] 实测否决」。计数 27/4/3/4 → **27/5/3/3**。新增 D-016 / D-017，D-008 转为生效。**新增两条禁止表述**：`version_hash` ≠ GLB 版本；"DDK 实测宣称 1.30"（应为 release 映射） |
| 2026-11-15 | **v1.5** | **U4-24 采集工具 + 三处口径更正**（`stage4: add GPU module identity audit`）：新增 `tools/collect_gpu_module_identity.sh`（396 行，POSIX sh，只读，无 adb，路径多根搜索，缺工具输出 `NOT_AVAILABLE`）与 `tools/README_gpu_module_identity.md`（199 行）。`08` 新增 **§3.6**（U4-24 判定矩阵、模块集合映射、kCFI/CRC 重导依赖分类、子项 a/b 拆分）；修正三处口径：①`lsmod` size 是 `core_layout.size` 非文件大小（取消"差 409 KB"的相减表述）②设备多出 `mtk_ghpm`，仓库无此文件，集合不对称 ③`met_*`「未装载」受筛选口径限制。**计数不变（27/5/3/3），U4-24 仍未闭合** |
