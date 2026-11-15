# SOURCING_STATUS — R56p0 源码获取状态

## 状态：❌ 未获取（Stage 1）

`mali_r56p0/` 目录当前为空壳（仅 `.gitkeep`）。本文件记录**为什么空**、**卡在哪**、**怎么补**。

---

## 1. 目标包（已确认存在）

| 字段 | 值 |
| --- | --- |
| 包名 | `AX504X08X-SW-99002-r56p0-18eac0.tar.gz` |
| 发布日期 | 2026-06-30 |
| 大小 | 1,147,252 字节 |
| MD5 | `62b168823691eb61ec29654cbf35e719` |
| 来源页面 | https://developer.arm.com/downloads/-/mali-drivers/5th-gen-gpu-architecture-kernel |
| 授权 | GPLv2（内核驱动部分），需先接受 Arm EULA |

包清单原始 JSON 已存档：`_arm_listing/arm_5thgen_package_listing_20261115.json`（共 23 个版本包）。

---

## 2. 阻塞证据链

1. **页面可读**：`HTTP 200`，能完整渲染 `Mali-GPU-Kernel-Device-Drivers` 表格，r56p0 行可见。
2. **清单可读**：前端通过
   `/-/cdn-downloads/Mali-Drivers-5th-Gen-GPU-Architecture/Mali-GPU-Kernel-Device-Drivers/_rel_.json?__token__=exp=...~hmac=...`
   拉取文件列表；该 JSON 需要带时效签名的 `__token__`，脱离页面直连返回 `403`（Akamai）。
3. **直链被拒**：用页面内实时令牌拼出文件 URL 后请求，仍 `403`；说明令牌是**目录级清单用**，不用于文件下载。
4. **点击即跳登录**：在真实浏览器（Chromium，接受下载）中点击 r56p0 链接，导航目标为

   ```
   https://developer.arm.com/user-login?returnUrl=/downloads/-/Mali%205th%20Gen%20GPU%20Architecture
     ?params=,/Mali-Drivers-5th-Gen-GPU-Architecture/Mali-GPU-Kernel-Device-Drivers/AX504X08X-SW-99002-r56p0-18eac0.tar.gz
   ```

   → 结论：**该包对未登录用户不开放**，与"Entitlements could not be checked"提示一致。

> 未尝试绕过登录、伪造令牌或从非授权镜像抓取。技术边界的判定到此为止。

---

## 3. 补齐路径

### 方案 A（推荐）

1. 用 Arm 账号登录上面的页面，接受 EULA，下载 `AX504X08X-SW-99002-r56p0-18eac0.tar.gz`（仅 1.1 MB）。
2. 把文件放到任意本地目录，告知路径。
3. 我执行：MD5 校验（对照 `62b168823691eb61ec29654cbf35e719`）→ 解包到 `mali_r56p0/` → 生成 `SOURCE_TREE.md` → 更新 `MANIFEST.md`。

### 方案 B

由我在受控浏览器中打开登录页，你亲自输入凭据与 MFA。**不推荐**：账号凭据不应经过我。

### 方案 C（不推荐）

从第三方镜像或他人 vendor 树取同版本 kbase。问题有二：

- 无法证明与 Arm 官方交付物逐字节一致（无 MD5 可比）；
- 极易混入其他机型/其他 GPU 的改动，直接违背本次审计"不把其他型号代码当作 G925 适配代码"的红线。

---

## 4. 缺失导致的下游影响

| 目录 | 影响 |
| --- | --- |
| `02_r56_source/` | 无原树，`SOURCE_TREE.md`、版本宏核实无法进行 |
| `03_kbase_csf/` | **无法开展源码级测绘**；仅能凭公开架构文档做概念性描述，不足以支撑结论 |
| `04_mtk_platform/` | 缺失对照物，"MTK 私有改动 vs R56p0 等价钩子"的判定无法落地 |
| `06_porting_design/` | 方案比选缺少关键输入，只能给出结构性判断，不能给工作量估算 |

> 因此 Stage 2 起，除"基线二进制分析"外，**不建议在缺 R56p0 源码的情况下继续推进**。

---

## 5. 已确认的替代性事实（不依赖 R56p0 源码）

- 出厂 kbase = `r49p1-03bet0(GPL)`，移植跨度为 7 个主版本（r49 → r56）。
- 该版本已含 `Mali-G925-Immortalis` 识别串 → G925 在 r49p1 即有支持，r56p0 属于版本升级而非新架构引入。
- 平台侧依赖 12 个 MTK 模块，加载顺序固定（见 `01_original_baseline/MANIFEST.md`）。
