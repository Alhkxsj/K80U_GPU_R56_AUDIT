# docs/ — 项目长期上下文

> 本目录是**治理层**，不承载技术结论。技术结论永远在 `03_kbase_csf/`、`04_mtk_platform/`、`05_userspace_firmware/`。

| 文件 | 作用 | 何时读 |
| --- | --- | --- |
| `PROJECT_STATE.md` | 项目当前状态：阶段进度、Stage 4 未决项、设备事实、技术债、任务队列、Stage 5 准入判定 | **每次任务开始（首要恢复入口）** |
| `DECISION_LOG.md` | 已形成的决策 D-001…D-015，含状态与再审议条件 | 判断"能不能做/能不能改"时 |

配套的根目录 [`AGENTS.md`](../AGENTS.md) 定义**执行规范**（上下文恢复顺序、Git 检查、证据等级、九类禁止表述、仓库红线、交付格式）。

## 维护规则

1. `PROJECT_STATE.md` **每项任务完成后必须更新**（HEAD、阶段状态、未决项、下一任务）。
2. `DECISION_LOG.md` **仅在新决策产生时追加**；已失效决策标 `已被取代` 并保留原文，不删除（D-012）。
3. 两份文件中的数字（UNKNOWN 计数、P0 数）必须与 `05_userspace_firmware/06_abi_compatibility_matrix.md` §7 和 `MANIFEST.md` §6.1 **保持一致**；发现不一致时先核实，再同步。
4. 状态与证据必须分开记录：`报告已交付` ≠ `证据已闭环`。
5. 本目录不存放二进制、不存放采集原始数据（后者见 `05_userspace_firmware/07_device_evidence.md`）。
