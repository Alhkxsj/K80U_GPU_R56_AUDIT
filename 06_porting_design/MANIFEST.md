# MANIFEST — 06_porting_design

> 登记方案设计文档与其引用的证据条目。

## 文件清单

| 文件 | 类别 | 来源 | 版本 / 标识 | 采集日期 | 采集方式 | SHA256 |
| --- | --- | --- | --- | --- | --- | --- |
| `STAGE4_FINAL_REPORT.md` | Stage 4 收尾台账 | 本项目 `05/01`–`09` + `04/*` 汇总 | v1.0 | 2026-11-16 | 纯文档撰写（零新增采集） | 见 `git hash-object` |
| `DDK_DUAL_TRACK_ASSESSMENT.md` | DDK 路线评估 | `02_r56_source` 源码 + 公开资料 | v1.0 | 2026-11-16 | 源码静态分析 | 同上 |
| `STAGE5_PREREQUISITES.md` | 准入清单 | 上述两份 + `docs/DECISION_LOG.md` | v1.0 | 2026-11-16 | 纯文档撰写 | 同上 |

## 登记规则

1. 每份设计文档需在文末附"引用清单"，列出所引用的 `KB-xxx` / `MTK-xxx` / `FW-xxx` 条目 ID。
2. 风险登记册（`04_risk_register.md`）使用 `R-001` 起的稳定 ID，不随排序变化而重编号。**Stage 4 收尾阶段的风险已提前占用 `R-A*`（P0）/ `R-B*`（P1）前缀**，见 `STAGE4_FINAL_REPORT.md` §6。
3. 方案一旦定稿，修改需在文首记录版本与修订原因。
4. 本目录产物可迭代，但**推翻既有结论必须保留原结论与推翻理由**，不允许静默改写。

## 本目录的编号约定

| 编号 | 含义 | 出处 |
| --- | --- | --- |
| 路线 **A/B/C/D** | **移植策略**：整包替换 / 以 MTK 为底回移 / 仅换固件与用户态 / 不移植 | `README.md` |
| **DDK-A / DDK-B** | **用户态 DDK 版本**：R56 DDK / R46 DDK | `DDK_DUAL_TRACK_ASSESSMENT.md` |
| **P-1 … P-4** | Stage 5B 的 4 项硬前置 | `STAGE5_PREREQUISITES.md` §1 |
| **C-1 / C-2** | 可带 BLOCKED 进入 Stage 5A 的 2 项 | `STAGE5_PREREQUISITES.md` §2 |
| **R-A\* / R-B\*** | P0 / P1 风险 | `STAGE4_FINAL_REPORT.md` §6 |

> 两套"路线"编号**正交**且不可互相引用：移植策略决定"改多少代码"，DDK 路线决定"用户态用哪一代"。

## 修订记录

| 日期 | 版本 | 变更 |
| --- | --- | --- |
| 2026-11-16 | v1.0 | 首次登记三份 Stage 4 收尾文档；建立编号约定（避免"路线 A/B"二义） |
