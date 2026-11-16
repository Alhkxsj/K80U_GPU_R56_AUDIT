# 第三轮关键读数（2026-11-16 14:12）

> 逐条给出读数、判读、以及"这条支撑哪个 U4 项"。凡本文件判定**不采用**的，都写明理由。

---

## 0. 环境指纹

| 项 | 读数 | 备注 |
| --- | --- | --- |
| 型号 / 代号 | `25060RK16C` / `dali` | Redmi K80 至尊版 |
| 指纹 | `Redmi/dali/dali:17/CP2A.260605.016/OS4.0.3.0.XONCNXM:user/release-keys` | `user` 版、`release-keys` |
| SDK | `37` | Android 17 |
| 内核 | `6.6.143-android15-8-gf9aa2fec23c3-4k` | `-4k` = 4 KiB page size |
| 内核构建者 | `chandr1000@SukiSU-Ultra-v41181` | **第三方重编**；`05/MANIFEST` §1 早已登记（`D-020` 三层内核表），本轮 [D·A] 直读复现 |
| UID / SELinux | `0` / `u:r:ksu:s0` | root + KSU 域 |
| 工具可用性 | 15/15 全部 `OK` | `od`/`xxd`/`strings`/`readelf`/`sha256sum`/`stat` 等齐全 |
| 写文件自检 | `WRITE_TEST: OK (/sdcard/GPU_AUDIT_STAGE4)` | 输出通道可用 |

---

## 1. CSF 固件（B 段）

| 项 | 读数 | 判读 |
| --- | --- | --- |
| 路径 / 大小 | `/vendor/firmware/mali_csffw.bin` / **307,200 B** | 与上一轮一致 |
| magic | `6e 3a f1 c3` | 固定值，通过 |
| `version_major` | `byte[0x05] = 0` | — |
| `version_minor` | `byte[0x04] = 3` | **固件 0.3** |
| `version_hash` | `u32[0x08] = 50987008` (`0x030a0000`) | 仅作锚点 |
| `entry_end_offset` | `u32[0x10] = 1000` | ≤ 307,200 → 截断检查必过 |
| 首 entry | `u32[0x14] = 0x2000` → `type=0`(INTERFACE) / `size=32` | 三项对齐与长度校验全过 |
| 尾部 32 B | 全 `00` | 尾部不携带版本 |
| 尾部 4 KiB 可打印串 | **0 条** | 再次确认（第三轮独立复现） |

**判读**：与第二轮逐字节相同。R56p0 要求 header **0.4** 且用 `!=` 严格相等（`csf_firmware.c:86` / `:2698`），设备 **0.3** → **header 校验阶段即 `-EINVAL`，早于 entry 解析**。U4-12 维持 **BLOCKED**，是独立阻断项，DDK 改造无法消除。

---

## 2. 分区与 overlay（C 段）

| 项 | 读数 | 判读 |
| --- | --- | --- |
| `/vendor` | `erofs /dev/block/dm-13 ro` | **只读原厂分区** |
| `/vendor_dlkm` | `erofs /dev/block/dm-18 ro` | **只读原厂分区** |
| `mountinfo` 中 `/vendor` 的 overlay 条目 | **0 条** | `/vendor` 未被覆盖 |
| overlay 覆盖范围 | 仅 `/product`、`/system`、`/system_ext` 的**子路径** | `lowerdir` 指向 `mi_ext` / `mi_product` |
| `vendor_lines` / `overlay_lines` / `erofs_lines` | `29` / `18` / `19` | 计数与上轮同量级 |
| `/data/adb/ksu` | `EXISTS` | KSU 痕迹（在 `/data`，不在 `/vendor`） |
| `/data/adb/modules` | `EXISTS` | 模块机制在 |
| `/data/adb/susfs` | `ABSENT` | 无 SUSFS |
| `/sbin/.magisk` | `ABSENT` | 非 Magisk |

**判读**：**U4-27 结论不变且加强**——`/vendor` 与 `/vendor_dlkm` 是只读 `erofs`，KSU 的存在只影响 `/data`，**没有**改写 vendor 分区。所以第 1 节的固件、第 5 节的 `kbase.ko` 都是**原厂文件本体**，不是被替换过的版本。

> 这是本轮最重要的"证据有效性"支柱：环境虽然 root，但被审计的关键文件未被篡改。

---

## 3. 内核 build-id（D 段）

| 项 | 读数 |
| --- | --- |
| `/sys/kernel/notes` 大小 | **84 B** |
| 内核 `build-id` | `0c637c57d1ad6f81f4de95c6dbbc92a8f9153408` |
| kbase 模块 `version` | `r49p1-03bet0` (UK version 1.30) |
| kbase 模块 `srcversion` | `CAC308B0D61305ACE6017E3` |
| kbase 模块 `holders` | `NONE` |
| kbase note 头 | `namesz=4 descsz=20 desc_off=16` |
| kbase 模块 `build-id` | `c5eac1f08ba2434defdeb72d2f4185c4a2217bb3` |

**判读**：
- 内核 build-id 与第二轮**逐字节相同**（`0c637c57…`）→ 内核镜像未变，两轮采集同一环境。
- kbase 模块 `version = r49p1-03bet0`，与 `dumpsys SurfaceFlinger` 自报的 `v1.r49p1-03bet0.4505ac17…` 前缀一致 → **kernel 侧与用户态侧版本对齐**。
- `holders: NONE` 表示没有模块依赖 kbase 的符号（与 README N-9 的 `deps=-` 互证）。

---

## 4. GPU 识别（E 段）

| 路径 | 读数 |
| --- | --- |
| `/sys/class/misc/mali0/device/gpuinfo` | `Mali-G925-Immortalis 12 cores r0p1 0x0D080300` |
| `/sys/devices/platform/soc/48000000.mali/gpuinfo` | 同上（逐字符相同） |

**判读**：**G925 MC12 第三次确证**，`r0p1`、`0x0D080300` 均未变。U4-12 的"产品是否匹配"这一半（硬件对得上）与"固件是否匹配"这一半（固件对不上）必须分开表述。

### 4.1 模块链表（`refs` / `deps` / `state`）

| 模块 | size | refs | deps（= 谁在用我） | state |
| --- | ---: | ---: | --- | --- |
| `mali_kbase_mt6991_r49` | 2,494,464 | **91** | `-` | Live |
| `ged` | 684,032 | 5 | `mtk_mbraink_v6991,…,mali_kbase_mt6991_r49,mtk_gpu_pdma_mt6991` | Live |
| `mtk_gpufreq_wrapper` | 90,112 | 9 | 含 `mali_kbase_mt6991_r49` | Live |
| `mtk_gpueb` | 73,728 | 10 | 含 `mali_kbase_mt6991_r49` | Live |
| `mtk_gpu_pdma_mt6991` | 28,672 | 1 | `mali_kbase_mt6991_r49` | Live |
| `mtk_gpu_hal` | 53,248 | 8 | 含 `mali_kbase_mt6991_r49` | Live |
| `mtk_slbc` | 32,768 | 20 | 含 `mali_kbase_mt6991_r49` | Live |
| `emi` | 49,152 | 11 | 含 `mali_kbase_mt6991_r49` | Live |
| `irq_dbg` | 16,384 | 10 | 含 `mali_kbase_mt6991_r49` | Live |
| `mtk_sec_heap` | 45,056 | 74 | 含 `mali_kbase_mt6991_r49` | Live |

> **注意**：`size` 是**内存布局大小**，不是文件大小。`kbase.ko` 文件 2,328,064 B，加载后 2,494,464 B，两者不可混用（这条差异在上一轮曾被误当作"模块被换过"的线索）。

`tainted（全局）= 4609` = `0x1201`：bit0 `P` + bit9 `W` + bit12 `O`。见 README N-8。

---

## 5. `__versions`（F 段，U4-24b）

| 模块 | 文件大小 | `sha256` | `__versions` 条数 | dump `sha256` |
| --- | ---: | --- | ---: | --- |
| `ged.ko` | 1,093,352 | `e4ff2a35e3019a97aa587e7453a62b5bed595b6d9b76a29ab245cf0e515c50b8` | **241** | `934556f5ad33ffdc42f50dd3b4d59e91196ddc53c548f9496b28f754fd0ec771` |
| `mali_kbase_mt6991_r49.ko` | 2,328,064 | `ad0e0ff25a2918a2e0820257d415b69db60cf6cd72753114c7dcc42fc85b1fa8` | **513** | `b8f118d283d04cfb992d917a57c46ff61b807054eeebdec52cee3ac71624d9a9` |

全量符号已结构化落盘：

- `symbols/ged_versions.tsv` — 241 条
- `symbols/kbase_versions.tsv` — 513 条
- `symbols/kbase_mtk_side.tsv` — 其中 MTK 侧 84 条，带分类

**两模块的 `module_layout` CRC 相同**：`0x4e276f37`（`1311207223`）→ 两个模块对内核 `module_layout` 结构布局的期望一致，说明它们由**同一内核头/同一配置**编译。

**`ged.ko` 中 `kbase` 相关符号：0 条。** 这是 README N-9 的核心读数。

---

## 6. OEM 扩展编入情况（G 段，U4-14）

| 探针字符串 | 命中数 | 判读 |
| --- | ---: | --- |
| `Internal fence wait` | **1** | `CONFIG_MALI_MTK_FENCE_DEBUG` **开启** |
| `Internal fence timeouts` | **4** | 超时/跨队列恢复路径在 |
| `ged_mali_event_notify_fence_timeout_event` | **2** | MBRAIN 通道在 |
| `padding is only supported for UMM` | 命中 | R49 内联 padding 校验存在 |
| `Invalid reserved field not 0 in queue group create` | 命中 | CSG create 的 reserved 校验存在 |
| `kbasep_ioctl_set_limited_core_count` | 命中 | ioctl 55 的处理函数**被编入** |

**判读**：`ioctl 80`（`INTERNAL_FENCE_WAIT`）的代码路径在设备构建上**可达**；`ioctl 55` 的处理函数**编入**。但"编入 ≠ 被调用"——`strace` 才能看调用面，故 **U4-14 维持 PARTIAL**。

### 6.1 源码树路径泄漏（新）

G-6 段从 `.rodata` 里读出的调试路径：

```
../vendor/mediatek/kernel_modules/gpu/mt6991/mali_avalon/mali-r49p1/drivers/gpu/arm/midgard/csf/mali_kbase_csf_tiler_heap.c
```

**判读**：这是 **[E1] 级**证据，直接证实：
1. OEM 的 kbase 源码树是 **`mali-r49p1`**（不是 R46、不是 R56）；
2. 目录名为 `mali_avalon`，`drivers/gpu/arm/midgard` 结构；
3. 与 `DDK_DUAL_TRACK_ASSESSMENT` 中"DDK-B = R56 Kbase + R49-derived 兼容 DDK"的路线**方向一致**——本机出厂 DDK 就是 R49p1 系。

这条不改变任何 U4 状态，但**加固了路线判断的证据等级**（从"版本字符串推断"升级为"源码路径直接可见"）。

---

## 7. dmesg（H 段）

| 探针 | 命中数 | 判读 |
| --- | ---: | --- |
| `Loading Mali firmware` | **0** | 开机 75,469 s，早已滚出环形缓冲 |
| `Version check failed` / `firmware may have failed` | 0 | 同上 |
| `disagrees about version of symbol` | **0** | **加载成功**的旁证（见 README N-8 推论 3） |
| dmesg 总行数 | 97,407 | 环形缓冲，非全量 |

**判读**：U4-02（运行时 GLB 版本）仍是 **OPEN**。两条低成本路径均已排除：dmesg 已滚掉、`/sys/kernel/debug` 未挂载（I 段 `NOT_AVAILABLE`）。

> `disagrees` 为 0 **不能**用来证明"CRC 完全一致"，因为环形缓冲可能已经滚掉早期加载日志；它只能作为**弱旁证**，与"模块确实 Live"合起来才成立。

---

## 8. ELF 元数据（J 段，U4-17 / U4-23）

| 库 | 大小 | `sha256`（前 16） | dynsym 行 | GLOBAL DEFAULT FUNC | defined |
| --- | ---: | --- | ---: | ---: | ---: |
| `/vendor/lib64/hw/mt6991/vulkan.mali.so` | 133,416 | `336acc0fe5d8e425` | 4 | 3 | **1** |
| `/vendor/lib64/hw/vulkan.mali.so` | 133,416（symlink→上一行） | 同上 | 4 | 3 | 1 |
| `/vendor/lib64/libgpud.so` | 395,856 | `de46f6ee565f4680` | 412 | 407 | **335** |
| `/system_ext/lib64/libgpud_sys.so` | 396,752 | `d52cf86c1faa08ac` | 497 | 482 | **372** |
| `/vendor/lib64/libged.so` | 101,944 | `ecdada971ce72e0d` | 199 | 179 | **100** |

**判读**：

1. **`vulkan.mali.so` 是桩**：唯一已定义函数 `mali_vk_vendor_stub`，**24 B**；`DT_NEEDED` 首项 `libGLES_mali.so`；`RUNPATH $ORIGIN/../egl`。→ **U4-17 维持 PARTIAL**，仍缺 `api_version` 来源；**REA 目标库确认为 `libGLES_mali.so`**。
2. **`libgpud.so` → `libgpud_sys.so`**：后者大 896 B，`defined` 多 **37** 个（372 vs 335），`GLOBAL DEFAULT FUNC` 多 75。样本中 `gpudVk*` / `gpudGl*` / `gpudEgl*` 系列在两者中同名出现（如 `gpudVkCreatePipelineLayout`、`gpudEglDumpChooseConfig`），方向上是 **`_sys` 为超集/扩展版**。→ **U4-23 仍 PARTIAL**：计数与样本已足够定性，但"逐符号 diff"需全量导出（一条只读命令）。
3. `libged.so` `defined = 100`，是三者中最小的对外面；`HWC`/`mapper` 的 `NEEDED libged` 与 6.1 节 kbase 的 84 条 MTK 侧导入共同支撑 **U4-22 子项 a**。

---

## 9. 属性与后端（K 段，U4-06 / U4-20 / U4-21）

| 读数 | 值 | 判读 |
| --- | --- | --- |
| `ro.hardware.egl` | `mali` | EGL 走 Mali |
| `ro.hardware.vulkan` | `mali` | Vulkan 走 Mali |
| `ro.opengles.version` | `196610` = `0x30002` | GLES **3.2** |
| `ro.hwui.use_vulkan` | `true` | App 层 HWUI 优先 Vulkan（**≠ SF 后端**，N-10） |
| `RE GLES (Ganesh)` | 命中 | **SF RenderEngine = GLES(Ganesh)**，U4-20 维持 CLOSED |
| SF 自报 GL 串 | `GLES: ARM, Mali-G925-Immortalis MC12, OpenGL ES 3.2 v1.r49p1-03bet0.4505ac1771886c7c25f13653ad4cdff7` | 与 kbase `version` 前缀一致 |
| `/linkerconfig/ld.config.txt` | `namespace.sphal.search.paths += /vendor/${LIB}/egl`；`namespace.default.search.paths += /vendor/${LIB}/egl` | EGL 搜索路径两条都在 |
| `/dev/mali0` | `crw-rw-rw- system graphics u:object_r:gpu_device:s0 10,282` | 节点属性不变 |
| holders | **23** 个进程 | 见下 |

holders 样本（23 个）：`surfaceflinger`、`mediaserver`、`camerahalserver`、`systemui`、`com.miui.home`、`com.tencent.mm`、`com.miui.securitycenter`、`com.google.android.gms`、`bin.mt.plus`、`com.iflytek.inputmethod`、`com.miui.miwallpaper` 等。

**判读**：`U4-21` 维持 PARTIAL——**持有 fd ≠ 不可降级**，仍需故障注入才能定"硬依赖等级"。数量由上轮 25 降到 23，是进程生命周期差异，非系统变化（`surfaceflinger`、`camerahalserver` 等关键持有者仍在）。

`U4-06` 维持 PARTIAL：`ld.config` 路径已两次确认，但仍缺 `/vendor/lib64/egl/` **目录清单**与 `ro.egl.additional_libraries`——一条 `ls` 即可补，本轮脚本未覆盖。

---

## 10. 本轮**不采用**的读数

| 读数 | 位置 | 不采用理由 |
| --- | --- | --- |
| `H-4` 段末尾孤立的 `0` | H-4 之后 | 是 `grep -c` 的二次输出，非独立数据；以 `COUNT: 0` 为准 |
| `OUTPUT_SIZE: 57602 bytes` 与回传文件 58,428 B 的差 | Z 段 | 前者是**写入时刻**的大小，后者含 Z 段自身追加内容，属正常偏差；以文件实际大小为准 |
| `GLOBAL DEFAULT OBJ: 0`（vulkan） | J 段 | 该库只有 1 个已定义函数、0 个数据对象，读数正确但**不构成"无数据导出"的结论**，仅说明它是纯函数桩 |
| `deps` 列直接读成"依赖谁" | E 段 | 方向错误，见 README N-9；以 `__versions` 为准 |
