# MANIFEST — 06_porting_design

> 登记方案设计文档与其引用的证据条目。

## 文件清单

| 文件 | 类别 | 来源 | 版本 / 标识 | 采集日期 | 采集方式 | SHA256 |
| --- | --- | --- | --- | --- | --- | --- |
| `STAGE4_FINAL_REPORT.md` | Stage 4 收尾台账（**时点快照**） | 本项目 `05/01`–`09` + `04/*` 汇总 | v1.0（文首已加时点警告块） | 2026-11-16 | 纯文档撰写（零新增采集） | 见 `git hash-object` |
| `DDK_DUAL_TRACK_ASSESSMENT.md` | DDK 路线评估 | `02_r56_source` 源码 + `01_original_baseline` r49p1 源码 + `05/07` 设备证据 + `_rea_analysis` | **v2.0**（DDK-B 由 R46 改为 R49-derived，`D-030`） | 2026-11-16 | 源码静态分析 + `strings` 抽样 | 同上 |
| `STAGE4_REMAINING_AUDIT.md` | **现行** Stage 4 台账 | `01_original_baseline`（r49p1）+ `02_r56_source`（R56p0）+ `05/*` + `06/STAGE4_FINAL_REPORT.md` | v1.0 | 2026-11-16 | 逐项重核（源码 grep + 脚本对拍） | 同上 |
| `R49_DDK_ADAPTATION_PLAN.md` | R49 深度改造预研框架（17 节） | 同上两份源码树 + `05/07` 设备证据 | v1.0（**纯设计，零源码改动**） | 2026-11-16 | 源码静态分析 + 设计推演 | 同上 |
| `STAGE4_DEVICE_COLLECTION_PLAN.md` | 真机最小只读采集方案 + **两轮执行评估** | 上述台账的未闭合项 + `05/tools/*.sh` 既有采集范围 | v1.0（**已执行 2 轮**，见 §9/§10） | 2026-11-16 | 方案撰写 + 脚本冒烟 + 回传判读 | 同上 |
| `STAGE5_PREREQUISITES.md` | 准入清单 | 上述若干份 + `docs/DECISION_LOG.md` | v1.0 | 2026-11-16 | 纯文档撰写 | 同上 |

## 登记规则

1. 每份设计文档需在文末附"引用清单"，列出所引用的 `KB-xxx` / `MTK-xxx` / `FW-xxx` 条目 ID。
2. 风险登记册（`04_risk_register.md`）使用 `R-001` 起的稳定 ID，不随排序变化而重编号。**Stage 4 收尾阶段的风险已提前占用 `R-A*`（P0）/ `R-B*`（P1）前缀**，见 `STAGE4_FINAL_REPORT.md` §6。
3. 方案一旦定稿，修改需在文首记录版本与修订原因。
4. 本目录产物可迭代，但**推翻既有结论必须保留原结论与推翻理由**，不允许静默改写。

## 本目录的编号约定

| 编号 | 含义 | 出处 |
| --- | --- | --- |
| 路线 **A/B/C/D** | **移植策略**：整包替换 / 以 MTK 为底回移 / 仅换固件与用户态 / 不移植 | `README.md` |
| **DDK-A / DDK-B** | **用户态 DDK 版本**：**DDK-A = 完整 R56 DDK** / **DDK-B = R56 Kbase + R49-derived compatibility DDK**（原第 1 版曾写 R46，已由 `D-030` 取代） | `DDK_DUAL_TRACK_ASSESSMENT.md` |
| **P-1 … P-4** | Stage 5B 的 4 项硬前置 | `STAGE5_PREREQUISITES.md` §1 |
| **C-1 / C-2** | 可带 BLOCKED 进入 Stage 5A 的 2 项 | `STAGE5_PREREQUISITES.md` §2 |
| **R-A\* / R-B\*** | P0 / P1 风险 | `STAGE4_FINAL_REPORT.md` §6 |

> 两套"路线"编号**正交**且不可互相引用：移植策略决定"改多少代码"，DDK 路线决定"用户态用哪一代"。

## 修订记录

| 日期 | 版本 | 变更 |
| --- | --- | --- |
| 2026-11-16 | v1.0 | 首次登记三份 Stage 4 收尾文档；建立编号约定（避免"路线 A/B"二义） |
| 2026-11-16 | **v1.1** | 补登 **3 份**新文档（`STAGE4_REMAINING_AUDIT.md` / `R49_DDK_ADAPTATION_PLAN.md` / `STAGE4_DEVICE_COLLECTION_PLAN.md`）；`DDK_DUAL_TRACK_ASSESSMENT.md` 升 **v2.0**；编号约定中 **DDK-B 由「R46 DDK」改为「R49-derived compatibility DDK」**（`D-030`），旧定义留痕于本行 |
| 2026-11-16 | **v1.2** | `STAGE4_DEVICE_COLLECTION_PLAN.md` 追加 **§9 第一轮执行结果评估**（v1.0 输出缺陷、可用项、缺口清单、重跑方式），原 §9 引用顺延为 §10；`STAGE4_REMAINING_AUDIT.md` 追加 **§2 N-6**（SKU 确证 + import 面量化）并更新 N-5 边界表；`R49_DDK_ADAPTATION_PLAN.md` §7 追加 **7.1 84 条 MTK 侧符号**。**计数不变 27/5/8/1/13** |
| 2026-11-16 | **v1.3** | **第二轮真机采集回传**：`STAGE4_REMAINING_AUDIT.md` 升 **第 2 版**——追加 **§2 N-7**（12 组读数 + 三条推论 + 脚本三处缺陷）、§3.3 补固件阻断实测、§4 计数 **8/12/1/6**、§5 核验表 13 行重写、§6 分档重写、§7 更正清单 7 → **10 条**；`STAGE4_DEVICE_COLLECTION_PLAN.md` 追加 **§10 第二轮执行结果评估**（原 §10 引用顺延为 §11）；`DDK_DUAL_TRACK_ASSESSMENT.md` 与 `R49_DDK_ADAPTATION_PLAN.md` 的固件节补实测证据。**P0 仍 3 且一项未动** |
| 2026-11-16 | **v1.4** | **第三轮真机采集回传**：`STAGE4_REMAINING_AUDIT.md` 升 **第 3 版**——追加 **§2 N-8～N-10**（N-8 为"第三方内核"既有记录的独立复现与 U4-26 表述更正；N-9 为 `deps` 反向依赖语义；N-10 为 HWUI vs SF 双渲染路径）、§4 计数 **8/13/1/5**、§5 核验表 4 行重写（U4-22/U4-23/U4-24/U4-26）、§6 分档重写、§7 更正清单 10 → **12 条**、§8 引用增 R-16～R-18；`STAGE4_DEVICE_COLLECTION_PLAN.md` 追加 **§11 第三轮执行结果评估**（原 §11 引用顺延为 §12）。**P0 仍 3 且一项未动** |
