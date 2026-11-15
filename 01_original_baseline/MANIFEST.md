# MANIFEST — 01_original_baseline

> 登记出厂基线快照。**本目录内容冻结，登记只增不改。**

## 采集来源（Stage 1）

| 字段 | 值 |
| --- | --- |
| 仓库 | `xiaomi-mt6991-devs/android_device_xiaomi_dali-kernel` |
| 地址 | https://github.com/xiaomi-mt6991-devs/android_device_xiaomi_dali-kernel |
| 分支 / commit | `lineage-23.2` / `057642643c9ff9ecd75d2442ca6be9766ece90d1` |
| commit 日期 | 2026-09-28 |
| commit 摘要 | `Initial commit: add Redmi K80 Ultra (dali) prebuilt kernel` |
| 采集日期 | 2026-11-15 |
| 采集方式 | GitHub REST `git/blobs` API，`Accept: application/vnd.github.raw`，**只读**，未 clone |
| 基线可信度 | **中** — 第三方社区镜像（LineageOS 项目组织），README 声明产物抽取自 `OS3.0.305.0.WONCNXM` 固件，未经真机核对 |

> **注意**：该仓库是**预编译产物仓**（`Image.lz4` / `.ko` / `.dtb` / uapi 头），不含 MTK 内核源码。详见根目录 `SOURCE_ACQUISITION.md` §2.3。

## 文件清单

| 文件 | 类别 | 来源 | 版本 / 标识 | 采集日期 | 采集方式 | SHA256(前16) |
| --- | --- | --- | --- | --- | --- | --- |
| `vendor_dlkm/mali_kbase_mt6991_r49.ko` | kbase 模块 | 上述仓库 | **r49p1-03bet0(GPL)**，srcversion `9E8156B93E2E5E961FF9A20` | 2026-11-15 | API 只读 | `c5ebca1c2a8be8e8` |
| `vendor_dlkm/mali_mgm_mt6991_r49.ko` | 配套模块 | 同上 | r49（模块名后缀） | 2026-11-15 | API 只读 | `22d3f50867d0bf1c` |
| `vendor_dlkm/mali_prot_alloc_mt6991_r49.ko` | 配套模块 | 同上 | r49 | 2026-11-15 | API 只读 | `4dc0f482a5d6631d` |
| `vendor_dlkm/mtk_gpufreq_mt6991.ko` | DVFS | 同上 | — | 2026-11-15 | API 只读 | `939e68b8a5d58376` |
| `vendor_dlkm/mtk_gpufreq_wrapper.ko` | DVFS 对接 | 同上 | — | 2026-11-15 | API 只读 | `86e52c00daae6d11` |
| `vendor_dlkm/mtk_gpu_hal.ko` | 平台 HAL | 同上 | — | 2026-11-15 | API 只读 | `a2a3e56a50c3477c` |
| `vendor_dlkm/mtk_gpueb.ko` | 带宽控制 | 同上 | — | 2026-11-15 | API 只读 | `29a61def07bf31f6` |
| `vendor_dlkm/mtk_gpu_pdma_mt6991.ko` | PDMA | 同上 | — | 2026-11-15 | API 只读 | `91d66e2e81b4d452` |
| `vendor_dlkm/mtk_gpu_iommu_mt6991.ko` | IOMMU | 同上 | — | 2026-11-15 | API 只读 | `5f79e6e44c4ba836` |
| `vendor_dlkm/mtk_gpu_power_throttling.ko` | 功耗墙 | 同上 | — | 2026-11-15 | API 只读 | `4a226ec226a1e9a4` |
| `vendor_dlkm/mtk_gpu_qos.ko` | QoS | 同上 | — | 2026-11-15 | API 只读 | `2830bec88492e519` |
| `vendor_dlkm/ged.ko` | 调度框架 | 同上 | — | 2026-11-15 | API 只读 | `f53e8c6833e82d8f` |
| `vendor_dlkm/met_gpu_api.ko` | MET | 同上 | — | 2026-11-15 | API 只读 | `6e6041f816fb21e8` |
| `vendor_dlkm/met_gpueb_api.ko` | MET | 同上 | — | 2026-11-15 | API 只读 | `06a7676f4926525c` |
| `vendor_dlkm/met_gpu_adv_api.ko` | MET | 同上 | — | 2026-11-15 | API 只读 | `444829590e067716` |
| `modules.load.vendor` | 加载清单 | 同上 | 4,339 B | 2026-11-15 | API 只读 | `ef29ab691cb13b01` |
| `modules.load.vendor_ramdisk` | 加载清单 | 同上 | 4,209 B | 2026-11-15 | API 只读 | `29fe689ad775d5c9` |
| `modules.load.system` | 加载清单 | 同上 | 940 B | 2026-11-15 | API 只读 | `aa93a85185742ca6` |
| `modules.load.recovery` | 加载清单 | 同上 | 4,436 B | 2026-11-15 | API 只读 | `69c139937e534fab` |
| `dtb/mt6991.dtb` | 设备树 | 同上 | 532,322 B | 2026-11-15 | API 只读 | `223984cc1daf6f91` |
| `README.md` | 仓库说明 | 同上 | — | 2026-11-15 | API 只读 | `8d181bc7b767bdd9` |
| `_inventory/kernel_repo_tree_0576426.json` | 完整清单 | 同上 | 1,585 条文件记录 | 2026-11-15 | API 只读 | —（JSON 索引） |

## kbase 模块关键元数据（从文件内提取）

| 字段 | 值 |
| --- | --- |
| `name` | `mali_kbase_mt6991_r49` |
| DDK 版本串 | `r49p1-03bet0(GPL)` |
| `license` | GPL |
| `vermagic` | `6.6.118-android15-8-g57e634f35c1b-4k SMP preempt mod_unload modversions aarch64` |
| `alias` | `of:N*T*Carm,mali-valhall`、`of:N*T*Carm,mali-valhallC*` |
| `depends` | `mtk_gpufreq_wrapper,aee_aed,ged,irq-dbg,mtk_gpu_hal,mrdump,mtk_gpueb,emi,mtk_sec_heap,tmem_ffa,mtk_slbc,mtk_gpu_pdma_mt6991` |
| 源码构建路径 | `../vendor/mediatek/kernel_modules/gpu/mt6991/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/…` |
| 是否 strip | 否（保留符号，可做符号级分析） |

## GPU 模块加载顺序（`modules.load.vendor`）

```
mtk_gpu_power_throttling(38) → mtk_gpueb(43) → mtk_gpu_hal(45)
→ mtk_gpufreq_wrapper(46) → mtk_gpufreq_mt6991(47) → mtk_gpu_iommu_mt6991(48)
→ ged(49) → mtk_gpu_pdma_mt6991(50)
→ mali_prot_alloc(51) → mali_mgm(52) → mali_kbase(53)
→ mtk_gpu_qos(87)
```

## 登记规则

1. 一文件一行，新增文件必须先登记后提交。
2. 版本列填写**文件内提取**的版本串（如 kbase 版本宏、固件内部版本号），禁止用文件名推断。
3. `*.ko`、固件、`*.so` 必须填 SHA256；目录型快照填写文件总数 + 顶层校验和。
4. 采集方式必须写明"只读"，例如：`adb pull（只读）`、`cat /sys/...`。
5. 设备若已被改动，在版本列后追加 `[基线可信度：低]` 并在备注说明。
6. 采集日期格式 `YYYY-MM-DD`。

## 待办

- [ ] 用真机 `modinfo` / `/sys/kernel/debug/mali0/version` 交叉核对上述版本串
- [ ] 补充 CSF 固件 `mali_csffw.bin`（本仓库未包含，需从设备分区只读提取）
- [ ] 补充用户态 `libGLES_mali.so` 等 blobs 元数据（→ `05_userspace_firmware/`）
- [ ] `Image.lz4` / `dtbo.img` / `kernel-headers` 暂未下载，需要时按路径补取
