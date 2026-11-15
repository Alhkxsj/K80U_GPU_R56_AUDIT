# MANIFEST — 02_r56_source

> 登记 R56p0 交付源码树。**本目录内容冻结，禁止打补丁。**
>
> 最近更新：2026-11-15（R56p0 官方包已获取并校验通过）

## 文件清单

| 文件 | 类别 | 来源 | 版本 / 标识 | 采集日期 | 采集方式 | SHA256 |
| --- | --- | --- | --- | --- | --- | --- |
| `mali_r56p0/` | 源码树 | Arm 官方交付（用户登录下载） | `r56p0-18eac0`；454 文件 / 5,838,430 B / 161,943 行 C/H；UK ABI 1.39 | 2026-11-15 | `tar xzf` 原样解包，无改动 | 树级 `a315860` |
| `mali_r56p0` 原始包 | 交付物 | `AX504X08X-SW-99002-r56p0-18eac0.tar.gz` | 1,147,252 B；MD5 `62b168823691eb61ec29654cbf35e719`；SHA256 `1f7ad4d0…` | 2026-11-15 | 用户上传 → MD5 比对清单值 **一致** | 见 `_inventory/arm_r56p0_package.sha256` |
| `_inventory/mali_r56p0_sha256.txt` | 完整性 | 本地生成 | 454 个文件逐文件哈希 | 2026-11-15 | `sha256sum` | — |
| `_inventory/arm_r56p0_package.sha256` | 完整性 | 本地生成 | 原始包 MD5/SHA256/树哈希 + 清单比对结论 | 2026-11-15 | 手工整理 | — |
| `_arm_listing/arm_5thgen_package_listing_20261115.json` | 证据 | developer.arm.com CDN 清单 | 23 个版本包，含 r56p0 行（1,147,252 B / MD5 `62b16882…`） | 2026-11-15 | 页面内签名清单（只读） | — |
| `STRUCTURE_MAP.md` | 测绘报告 | 本次审计 | 目录结构 / 版本 ABI / CSF-only 判定 / G925 证据 / 差异跨度 | 2026-11-15 | 源码静态阅读 | — |
| `SOURCING_STATUS.md` | 状态说明 | 本次审计 | 获取结果 + 早期阻塞留痕 + 待补项 | 2026-11-15 | 手工整理 | — |

## 解包后关键标识（复核用）

| 标识 | 值 | 文件:行 |
| --- | --- | --- |
| `MALI_RELEASE_NAME` | `"r56p0-18eac0"` | `Kbuild:75` |
| `KERNEL_SIDE_DDK_VERSION_STRING` | `K:r56p0-18eac0(GPL)` | `mali_kbase_core_linux.c:113` |
| `BASE_UK_VERSION_MAJOR` | `1` | `include/uapi/.../csf/mali_kbase_csf_ioctl.h:148` |
| `BASE_UK_VERSION_MINOR` | `39` | 同上 `:149` |

## 登记规则

1. 源码树以"目录"为单位登记一行：填文件总数、总体积、解包时间，并附顶层校验和。
2. 版本列必须来自交付物内部版本宏或 Release Notes，**不得仅凭目录名**。
3. 交付渠道、交付单号（如有）写入"来源"列。
4. 若交付物内含固件或预编译库，单独追加一行并填 SHA256。
5. 任何对 `mali_r56p0/` 内文件的改动均视为违规 —— 包括格式转换、行尾修复、删除测试目录。
   需要改造时，一律在 `06_porting_design` 中以 diff 形式记录，不改动本目录。
