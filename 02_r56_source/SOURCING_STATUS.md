# SOURCING_STATUS — R56p0 源码获取状态

## 状态：✅ 已获取并校验通过（2026-11-15 更新）

`mali_r56p0/` 已落盘 Arm 官方原包解包结果，454 个文件 / 5.58 MB，**MD5 与 Arm 清单登记值逐字节一致**。
本文件保留完整的获取经过、早期阻塞证据（作为审计留痕）与后续待补项。

| 项 | 结果 |
| --- | --- |
| 获取方式 | 用户登录 `developer.arm.com`、接受 EULA 后下载，上传至会话 |
| 校验 | `MD5 62b168823691eb61ec29654cbf35e719` = 清单值 ✓ |
| 落盘 | `02_r56_source/mali_r56p0/driver/product/kernel/...` |
| 改动 | 无。原样解包，未 patch、未格式化、未编译 |
| 测绘报告 | [`STRUCTURE_MAP.md`](./STRUCTURE_MAP.md) |
| 完整性记录 | `_inventory/arm_r56p0_package.sha256`、`_inventory/mali_r56p0_sha256.txt` |

---

## 1. 已获取包的身份

| 字段 | 值 |
| --- | --- |
| 包名 | `AX504X08X-SW-99002-r56p0-18eac0.tar.gz` |
| 发布日期 | 2026-06-30 |
| 大小 | 1,147,252 字节 |
| MD5 | `62b168823691eb61ec29654cbf35e719` |
| SHA256 | `1f7ad4d058bb993a95714d7823f279df9097ae45efe622970a53373217fa92f4` |
| 来源页面 | https://developer.arm.com/downloads/-/mali-drivers/5th-gen-gpu-architecture-kernel |
| 授权 | GPLv2（内核驱动部分），需接受 Arm EULA |
| 包内条目 | 454，全部为源码/构建脚本，无二进制 |

包清单原始 JSON：`_arm_listing/arm_5thgen_package_listing_20261115.json`（共 23 个版本包，已存档以证明该版本确由 Arm 官方发布）。

---

## 2. 关键结论（由源码直接读出，非推测）

| 项 | 值 | 出处 |
| --- | --- | --- |
| DDK 发布名 | `r56p0-18eac0` | `Kbuild:75` |
| UK ABI | **1.39** | `include/uapi/.../csf/mali_kbase_csf_ioctl.h:149` |
| 后端架构 | **仅 CSF，无 JM** | `device/Kbuild` 无 `ifeq` 分支，全树无 `*jm*` 文件 |
| G925 识别 | `GPU_ID_PRODUCT_TKRX` + `nr_cores>=10` + RT → `Mali-G925-Immortalis` | `mali_kbase_core_linux.c:2576` |
| MTK 平台目录 | **不存在**，仅 `devicetree`/`meson`/`vexpress` | `platform/` |

与基线的跨度：DDK `r49p1 → r56p0`（7 个主版本），UK ABI `1.30 → 1.39`（9 个 minor）。

---

## 3. 早期阻塞记录（2026-11-15 上午，已解除）

> 本节保留作为审计留痕：证明源码来源正规，且期间**未**采用任何非授权途径。

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

   → 结论：该包对未登录用户不开放，与 "Entitlements could not be checked" 提示一致。

5. **解除**：由用户本人登录下载后上传，完成校验。全程未绕过登录、未伪造令牌、未从第三方镜像抓取。

---

## 4. 本包不含、仍待补齐的内容

R56p0 只交付**内核驱动**。以下缺口不解，`05` / `06` 无法闭环：

| 缺失项 | 归属 | 影响 |
| --- | --- | --- |
| CSF 固件 blob（`mali_csffw.bin`） | `05_userspace_firmware` | 固件与 DDK 版本强绑定，版本不符则 GPU 起不来 |
| 用户态 Mali DDK（`libmali.so` 等，UK 1.39） | `05_userspace_firmware` | ABI 面必须与内核 1.39 对齐 |
| **r49p1 内核源码** | `01_original_baseline` | 当前仅有 `.ko` 二进制，差异分析只能到符号级 |
| MTK 私有 GPU 补丁 | `04_mtk_platform` | Arm 原包完全没有，须从 DT / 二进制倒推 |
| MT6991 GPU 设备树节点 | `04_mtk_platform` | `dtb/mt6991.dtb` 可直接反编译 |
| 内核基线源码（6.6.118-android15-8） | `01_original_baseline` | 参考仓库只给 `Image.lz4`，无源码 |

**其中「r49p1 源码」是最需要你决策的一项**：它是 `03_kbase_csf` 差异对比的对照物。缺它的话，
差异分析只能做"R56p0 内部结构测绘 + 基线 `.ko` 符号/字符串推断"，精度会明显下降。
（Arm 历史上 r49p1 未在 5th Gen 页面公开发布，可能需从 MTK BSP 或 Xiaomi 开源包取得。）

---

## 5. 目录内容一览

```
02_r56_source/
├── STRUCTURE_MAP.md                 ← 本阶段核心产出：结构测绘报告
├── SOURCING_STATUS.md               ← 本文件
├── MANIFEST.md                      ← 留档登记
├── _arm_listing/
│   └── arm_5thgen_package_listing_20261115.json   ← 23 个版本包清单（证据）
├── _inventory/
│   ├── arm_r56p0_package.sha256     ← 原始包完整性记录
│   └── mali_r56p0_sha256.txt        ← 454 个文件的逐文件哈希
└── mali_r56p0/
    └── driver/product/kernel/
        ├── include/uapi/gpu/arm/midgard/            （18 个 uapi 头）
        ├── drivers/gpu/arm/midgard/                 （主体：156 .c + 207 .h，161,943 行）
        └── drivers/hwtracing/coresight/mali/        （3 文件）
```
