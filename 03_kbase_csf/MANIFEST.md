# MANIFEST — 03_kbase_csf

> 登记本目录的分析产物。分析笔记不是"证据"，必须注明所依据的源码版本。
> 最后更新：2026-11-15 · 产物：6 份报告 + 本清单 · 差异条目：45 条实质差异（+21 条形态确认项）
> 审计性质：**纯静态比对**。全程未编译、未打补丁、未部署、未刷机；`01_original_baseline/` 与 `02_r56_source/` 未被写入。

## 1. 审计基准（先核对，再比对）

| 角色 | 树路径（仓库相对） | DDK 版本 | UK ABI | 版本串出处 |
| --- | --- | --- | --- | --- |
| 对照（出厂） | `01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/` | **r49p1-03bet0** | **1.30** | `drivers/gpu/arm/midgard/Makefile:526`；`include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_ioctl.h:122` |
| 依据（官方） | `02_r56_source/mali_r56p0/driver/product/kernel/` | **r56p0-18eac0** | **1.39** | `drivers/gpu/arm/midgard/Kbuild:75`；`include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_ioctl.h:149` |

两树的 kbase 主体均落在 `…/drivers/gpu/arm/midgard/`，故各报告内行号一律省略该前缀。

**路径结构本身已变**（r56p0 的目录重构之一，不属功能差异但影响移植落点）：

- r49p1：UAPI 头在 `drivers/gpu/arm/midgard/include/uapi/` **内部**
- r56p0：UAPI 头提升到树顶层 `include/uapi/`，与 `drivers/` 平级；并新增 `Documentation/`（见 `01` KB-030）

## 2. 文件清单

| 文件 | 类别 | 来源 | 版本 / 标识 | 采集日期 | 采集方式 | SHA256 |
| --- | --- | --- | --- | --- | --- | --- |
| `01_uapi_abi_diff.md` | UAPI / UK ABI 差异 | `02_r56_source/mali_r56p0/driver/product/kernel/` ⟷ `01_original_baseline/…/mali-r49p1/` | r56p0-18eac0（UK ABI 1.39）⟷ r49p1-03bet0（1.30） | 2026-11-15 | 静态比对：ioctl 编码 `_IOWR` 全量抽取 + 结构体逐字段布局推算 | `b32bd9d17a213807acab3b430e6d562a15f49bcd2a61493b4693952e05b757e6` |
| `02_csf_architecture_diff.md` | CSF 核心架构差异 | 同上，`…/midgard/csf/` | 同上 | 2026-11-15 | 静态比对：文件级 `diff` + 行数统计 + 编译开关计数 + 符号检索 | `479e070ea3a8f6b0182d6be45627f75f65feb4b12ff42287c6cd08fd2c4da7b5` |
| `03_memory_mmu_diff.md` | 内存管理与 MMU 差异 | 同上，`…/midgard/{mmu,base/arm}` | 同上 | 2026-11-15 | 静态比对：函数签名对拍 + MTK 符号计数（MGM 97→0、PMA 43→0） | `9b6cef1dc8d462266aff1a6608b65ab8ed0549942462a65f9fd240eb8720caba` |
| `04_pm_interface_diff.md` | 电源管理接口差异 | 同上，`…/midgard/{backend/gpu,platform}` | 同上 | 2026-11-15 | 静态比对：`kbase_pm_callback_conf` 成员逐项对拍 + devfreq 注册路径追踪 | `c04682ec5474b0c11b7897adf3560762737edc7a08ec548ce51702a77e24b698` |
| `05_g925_hardware_support.md` | G925 硬件支持核查 | 同上，`…/midgard/{gpu,platform/devicetree}` | 同上 | 2026-11-15 | 静态比对：`kbase_regmap_v12_init` 整函数 `diff`（结果为空）+ GPU_ID 表 + 产品识别分支 | `bfa9c6f2d3ce78749dadcae54655ada13f536dcd7b3081aed712ee169568ddf9` |
| `06_blocking_issues.md` | 阻塞项汇总与终局判定 | 汇总 `01`–`05` | 同上 | 2026-11-15 | 二次归纳：按 P0/P1/P2/P3 分级 + 回答五个终局问题 + UNKNOWN 清单 | `336acbf4b63e488cc5a75cdd0da7cecfc94bbcf42cb890c67416c2acbdb8e291` |
| `MANIFEST.md` | 清单（本文件） | — | — | 2026-11-15 | 手工登记 | 不登记自身哈希（自引用无意义） |

## 3. 内容索引

| 文件 | 覆盖域 | KB ID 区间 | 条目数 | P0 | P1 | P2 | P3 | 主要回答 |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| `01` | UAPI / UK ABI | `KB-001`…`KB-014` + `KB-030` | 14 | 4 | 4 | 3 | 3 | 握手为何永远成功、哪些结构体动了、ioctl 号段还剩多少 |
| `02` | CSF 核心 | `KB-020`…`KB-028` | 9 | 3 | 2 | 1 | 3 | CSF-only 化、`fw_io` 抽象、reset 路径重构、900 处注入无落点 |
| `03` | 内存 / MMU | `KB-040`…`KB-047` | 8 | 3 | 3 | 0 | 2 | MGM 签名破坏、PMA 的 SVP 安全区消失、IOMMU 对接方式 |
| `04` | 电源管理 | `KB-050`…`KB-056` | 7 | 3 | 1 | 1 | 2 | 回调接口未变但实现断层、devfreq 静默降级、`platform/` 归零 |
| `05` | G925 硬件 | `KB-060`…`KB-066` | 7 | 0 | 1 | 0 | 6 | G925 能否被 r56p0 正确识别与驱动（结论：能，且不比 r49p1 弱） |
| `06` | 汇总 | 引用 `KB-001`…`KB-066` | 45 | 13 | 11 | 5 | 16 | 五个终局问题 + 工作量估算 + U1–U10 |

> 计数口径见 `06` §0.2：45 条为**有实质内容**的差异；另有 21 条为"文件存在但无实质变化"的确认项（含 `KB-030`），合计 66 条记录。`01`/`04`/`05` 中出现的 `KB-020`、`KB-022`、`KB-040` 等为他文件条目的**交叉引用**，不重复计数。

## 4. 复核方法

任何人都可用以下命令复核本清单与各报告的关键断言，无需编译：

```bash
cd 03_kbase_csf

# 4.1 校验报告未被篡改
sha256sum -c <<'EOF'
b32bd9d17a213807acab3b430e6d562a15f49bcd2a61493b4693952e05b757e6  01_uapi_abi_diff.md
479e070ea3a8f6b0182d6be45627f75f65feb4b12ff42287c6cd08fd2c4da7b5  02_csf_architecture_diff.md
9b6cef1dc8d462266aff1a6608b65ab8ed0549942462a65f9fd240eb8720caba  03_memory_mmu_diff.md
c04682ec5474b0c11b7897adf3560762737edc7a08ec548ce51702a77e24b698  04_pm_interface_diff.md
bfa9c6f2d3ce78749dadcae54655ada13f536dcd7b3081aed712ee169568ddf9  05_g925_hardware_support.md
336acbf4b63e488cc5a75cdd0da7cecfc94bbcf42cb890c67416c2acbdb8e291  06_blocking_issues.md
EOF

cd ..

# 4.2 核对两个版本的版本串（§1 的出处）
sed -n '526p' 01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/Makefile
sed -n  '75p' 02_r56_source/mali_r56p0/driver/product/kernel/drivers/gpu/arm/midgard/Kbuild

# 4.3 核对 UK ABI 1.30 / 1.39
grep -n 'BASE_UK_VERSION_MINOR' \
  01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_ioctl.h \
  02_r56_source/mali_r56p0/driver/product/kernel/include/uapi/gpu/arm/midgard/csf/mali_kbase_csf_ioctl.h

# 4.4 复核 G925 的寄存器映射路径两版是否真的一致（`05` KB-061 的核心证据）
A=01_original_baseline/mtk_kernel_modules/gpu/gpu_mali/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_csf.c
B=02_r56_source/mali_r56p0/driver/product/kernel/drivers/gpu/arm/midgard/hw_access/regmap/mali_kbase_regmap_csf.c
awk '/^static void kbase_regmap_v12_init/,/^}/' "$A" > /tmp/a.c
awk '/^static void kbase_regmap_v12_init/,/^}/' "$B" > /tmp/b.c
wc -l /tmp/a.c /tmp/b.c                                  # 期望：38 / 38
diff /tmp/a.c /tmp/b.c && echo IDENTICAL                 # 期望：无输出 + IDENTICAL
grep -n '^static void kbase_regmap_v12_init' "$A" "$B"   # 期望：两边都是 1106

# 4.5 复核 §5 的文本残留
grep -rl 'oaicite\|contentReference' 02_r56_source/ | wc -l
```

## 5. 来源完整性备注（必须与结论一起读）

审计过程中对 `02_r56_source/` 做过一次全树文本残留扫描，发现 **5 个文件含 10 处非源码残留**，形如 `:contentReference[oaicite:0]{index=0}`：

| 文件 | 命中 |
| --- | ---: |
| `Documentation/devicetree/bindings/arm/arm,mali-midgard.yaml` | 1 |
| `Documentation/devicetree/bindings/arm/arm,physical-memory-group-manager.yaml` | 2 |
| `Documentation/devicetree/bindings/arm/arm,priority-control-manager.yaml` | 2 |
| `Documentation/devicetree/bindings/arm/arm,protected-memory-allocator.yaml` | 3 |
| `Documentation/devicetree/bindings/power/arm,mali-operating-points.yaml` | 2 |

判定与处置：

1. 这 5 个 yaml 是**按网页文本重建**的，不是官方归档原样。`drivers/`、`include/` 全树**零命中**，代码侧证据不受影响。
2. 因此 `01` KB-030 只把"文档文件存在与行数"当实证，**不引用 yaml 正文作为依据**；`06` U10 登记为 UNKNOWN。
3. 现有 6 份报告的结论**没有任何一条依赖这 5 个文件的内容**——已逐条核对引用：唯一的 Documentation 引用（`01` 行 27）指向 `ABI/testing/sysfs-device-mali`，该文件不在残留名单内。
4. 官方 `AX504X08X-SW-99002-r56p0-18eac0.tar.gz` 需 Arm 账号，尚未取得；取得后应对拍 SHA 并关闭 U10。

## 6. 未决项

`06` §5 列出 U1–U10 共 10 项 UNKNOWN，其中影响结论强度的三项：

| 编号 | 内容 | 消除成本 |
| --- | --- | --- |
| U8 | `gpu_props_user_data` 568/592 字节为人工推算，**未经编译验证** | 独立编译单元 `sizeof` 对拍（本审计禁止编译） |
| U6 / U7 | K80U 用户态是否调用 80 号 ioctl；`mali_csffw.bin` 的固件 ABI | 需从真机提取 `libGLES_mali.so` 与固件 |
| U5 | G925 是否真具备 `ray_traversal` / `neural_accelerator` / PBHA | 需读 `GPU_FEATURES` 寄存器 |

## 7. 与其他目录的边界

- 本目录只处理**驱动通用逻辑**。判据：换一块别的 SoC 也成立 → 本目录；只有 MT6991 成立 → `04_mtk_platform/`。
- ABI 结论需回写 `05_userspace_firmware/`，但接口清单本身在本目录维护。
- 移植方案（改什么、按什么顺序改）属 `06_porting_design/`，本目录**只描述差异，不设计补丁**。

## 登记规则

1. 每份分析笔记在文件首行注明：`依据：<树路径> @ <版本>`，并同步登记到本表"版本 / 标识"列。（现有 6 份均已在标题区声明 `依据：` / `对照：` 两行）
2. 差异条目建议在笔记内使用稳定 ID（如 `KB-001`），便于 `06` 引用。
3. 引用代码一律给 `路径:行号`，不接受仅给函数名。
4. 本目录产物不纳入"冻结"范围，可迭代修订；修订需保留历史版本或在文末记录变更。
5. **新增或修订报告后必须重算 SHA256 并更新本表**，否则视为未登记。
6. 证据等级只用三档：**实证**（源码可见且可直接复核）/ **推断**（基于实证的逻辑外推）/ **UNKNOWN**（静态源码无法判定）。禁止第四档。

## 修订记录

| 日期 | 版本 | 变更 |
| --- | --- | --- |
| 2026-11-15 | v0 | 占位（目录初始化） |
| 2026-11-15 | v1 | 登记 6 份报告；补 §1 基准核对、§3 内容索引、§4 复核命令、§5 来源完整性、§6 未决项；各报告标题区补 `依据：`/`对照：` 声明；`01` 新增 KB-030 并修正其悬空引用；`06` 新增 U10 |
