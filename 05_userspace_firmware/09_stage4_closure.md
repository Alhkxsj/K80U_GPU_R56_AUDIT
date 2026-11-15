# 09 — Stage 4 收尾核验：四处更正与剩余缺口

> **本文件做什么**：对 Stage 4 尚未闭环的 U4-04 / U4-10 / U4-12 / U4-24b / U4-25 / U4-26 / U4-27 做**独立复核**——不重跑任何设备采集，而是回源码、回构建记录，检验"现有结论是否站得住"。
>
> **结果**：查出**四处结论层面的错误**，其中一处（`same_magic` 语义）推翻了上一轮的核心发现；一处（padding 门槛）把风险从"tiler 不可用"升级为"GPU 完全不可用"。三项因此**无法闭合**，原因已精确到"缺哪一份实体、用哪一条命令能补"。
>
> **本文件不做**：不修改驱动源码，不编译，不刷机，不进入 Stage 5A。
>
> 证据等级沿用 `08` §0.1：**[D·A]/[D·B]/[D·C]** 设备实测三分 · **[B]** 可核验构建记录 · **[P]** 用户声明 · **[E1]** 源码/二进制直接证据 · **[E2]** 交叉推导 · **[E3]** 惯例推断 · **[U]** UNKNOWN

---

## 0. 一句话结论

> **Stage 4 的结论面是对的，机制面错了四处。**"组合 B 不可行""最小替换范围 = kbase + 固件""用户态契约层可保留"三条不受影响；但**"运行内核绕过了 vermagic 校验"是错的**（那是 6.6 的**原生语义**），**"padding 只有两处检查"也是错的**（实际 15 处强制，覆盖 CS 主链路与 CSG 注册热路径）。

---

## 1. 本轮复核范围（只读，零新增设备采集）

| # | 复核对象 | 方法 | 结果 |
| ---: | --- | --- | --- |
| 1 | "15 个模块 vermagic 不符仍装载 → 内核绕过 `same_magic()`" | 读 Linux v6.6 `kernel/module/version.c`、`main.c` | ❌ **结论错误**，§2 |
| 2 | 该内核是否还有别的版本校验绕过 | 读第三方内核**构建工作流与 action 原文**（公开仓库） | ⚠️ **存在开关，但默认关闭，且有门控 bug**，§3 |
| 3 | 设备 `uname -v` 的 `Mon Oct 5 04:20:00 UTC 2026` 能否判定构建时间 | 读工作流时间戳步骤 + GKI `_setup_env.sh` | ❌ **不能**，该串是补丁月派生的常量，§4 |
| 4 | "padding 只有两个真正检查" | 全量解析 `mali_kbase_ioctl_helpers.h` 的 48 个 `check_padding_*` | ❌ **严重低估**，实际 15 强制，§5 |
| 5 | props 是否构成硬门槛 | 读 `kbase_api_get_gpuprops` | ✅ 机制确认：两阶段协商，`size < prop_buffer_size` 才 `-EINVAL`，§5.4 |
| 6 | R56 交付包内是否有 CSF 固件 / DDK | 解析 `02_r56_source/_arm_listing/*.json`（23 个条目） | ❌ **0 命中**，U4-12 的阻断原因被确认为"商业交付物不在源码包内"，§6 |
| 7 | 模块是否曾被强制装载 | 读已采集的 `/proc/modules` taint 列 | ✅ 仅 `(O)`，**无 `F`** → 从未走 `try_to_force_load()`，§2.3 |

> 以上全部**只读**：读源码、读公开构建记录、重算已采集文本里的字段。**没有**新增设备命令，**没有**上传或下载任何二进制。

---

## 2. 更正一：`same_magic()` 在 `CONFIG_MODVERSIONS` 下**本来就忽略 release 串**

### 2.1 源码依据

```c
/* linux v6.6 kernel/module/version.c:88-96
 * https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/kernel/module/version.c?h=v6.6
 */
/* First part is kernel version, which we ignore if module has crcs. */
int same_magic(const char *amagic, const char *bmagic,
	       bool has_crcs)
{
	if (has_crcs) {
		amagic += strcspn(amagic, " ");      /* 跳过第一个空格之前的一切 */
		bmagic += strcspn(bmagic, " ");
	}
	return strcmp(amagic, bmagic) == 0;
}
```

调用点：

```c
/* linux v6.6 kernel/module/main.c:2089 */
} else if (!same_magic(modmagic, vermagic, info->index.vers)) {
	pr_err("%s: version magic '%s' should be '%s'\n", ...);
	return -ENOEXEC;
}
```

`has_crcs = info->index.vers`，即**模块是否带 `__versions` 节**。本机 18 个 GPU `.ko` **全部带**（`ged` 的 `__versions` = `0x3c40`，见采集 §4.4），内核侧 `CONFIG_MODVERSIONS=y`（vermagic 尾含 `modversions`）。

### 2.2 与实测的吻合

| 项 | 值 |
| --- | --- |
| 设备模块 vermagic | `6.6.118-android15-8-g54a15cf3acba-4k **SMP preempt mod_unload modversions aarch64**` |
| 运行内核 vermagic | `6.6.143-android15-8-gf9aa2fec23c3-4k **SMP preempt mod_unload modversions aarch64**` |
| 第一个空格之后的串 | **逐字符相同** |
| `same_magic()` 返回值 | **1（通过）** |

**结论**：这 15 个模块的装载**不需要任何补丁**，是 6.6 的**设计内行为**。[E1]

### 2.3 推翻了什么

| 上一轮表述（`08` §3.7.4、D-021） | 现状 |
| --- | --- |
| "该内核**必然**打了 vermagic 检查绕过补丁" | **撤回**。原生语义即可解释，无任何补丁证据 |
| "`VERMAGIC_MATCHES_UNAME_R: NO` → 环境被污染" | **撤回**。该字段本身就是**错误的判据**——它拿内核字符串直接比对，而内核并不这么比 |
| "Stage 5 的验证内核不可选在绕过 vermagic 的内核上" | **降级为条件约束**：只有当验证内核是"用 `allow_version_mismatch=true` 构建的"才成立，见 §3.4 |
| AGENTS.md §0.6 禁止表述第 11 条 | 表述错误，已改，见 §2.5 |

### 2.4 没有推翻什么

1. **"装载成功 ≠ 与 R56 兼容"** —— 仍然成立，且与本节无关：装载只说明**厂商模块 ↔ 运行内核**的符号 CRC 一致，与 R56 kbase 是否可用毫无关系。
2. **"设备 `.ko` ≠ 仓库 `.ko`"** —— vermagic 串与 SHA256 都不同，仍然成立。
3. **"组合 A 的 [D] 只代表'在第三方内核上可用'"** —— 仍然成立。

**但有一条被加强了**：

> 若 `check_version()` 未被打补丁（§3 判定），则 15/15 装载成功**等价于**"厂商模块导入的每个符号，在运行内核上 CRC 逐一致"。这是一条此前被我们**误判为不成立**的 [D·C]+[E1] 证据。它对"6.6.118 与 6.6.143 之间导出符号签名是否稳定"给出了**肯定**回答（覆盖被 import 的符号集合，不覆盖全集）。

### 2.5 连带更正

- `AGENTS.md` §0.6 第 11 条：由"内核接受不匹配模块 → 该内核绕过 `same_magic()`"改为"vermagic 串不符在 `CONFIG_MODVERSIONS` 下是**正常**的，release 串被忽略；不可据此推断任何补丁"。
- `08` §3.7.4 整节重写为"更正版 + 新证据"。
- `PROJECT_STATE` §3.4、§4 第 5 条、§6 第 12 条同步。

---

## 3. 更正二：真正的版本绕过开关存在，但**默认关闭**，且当时有一个门控 bug

### 3.1 机制（这才是唯一会"掩盖 CRC 错误"的东西）

第三方内核的构建仓库 `JiangXue5/GKI_KernelSU_SUSFS` 有一个独立 action：

```yaml
# .github/actions/bypass-kernel/action.yml（main-chandr1000）
- name: Activate Bypass
  if: ${{ inputs.allow_version_mismatch == true }}
  run: |
    TARGET_FILE=".../kernel/common/kernel/module/version.c"
    sed -i '/bad_version:/{:a;n;/return 0;/{s/return 0;/return 1;/;b};ba}' "$TARGET_FILE"
```

它把 `check_version()` 的 `bad_version:` 分支从 `return 0`（**失败**）改成 `return 1`（**放行**）：

```c
/* 原生 v6.6 kernel/module/version.c:53-55 */
bad_version:
	pr_warn("%s: disagrees about version of symbol %s\n", info->name, symname);
	return 0;        /* ← 被打成 return 1 */
```

**这是我们此前应当找、但没有找的那道关卡**：它只影响**符号 CRC**，与 vermagic 无关。工作流输入描述写得很直白：`"Force-load modules with mismatched symbol versions ( force check_version() to pass )"`，`default: false`。

### 3.2 门控 bug 的时间窗（决定设备内核是否被打过）

| 时间 | 提交 | 门控写法 | 实际效果 |
| --- | --- | --- | --- |
| 2026-08-29 | `32ba07352` | `inputs.allow_version_mismatch == 'true'` | 输入是 `type: boolean`，布尔与字符串比较恒为 false → **永不执行** |
| 2026-09-14 | `02b1ae742` | 同上（仅重命名输入） | 同上 |
| 2026-10-30 | `a60756073` | 改为 `== true` | 修好后**才**能按用户选择生效 |

`build.yml:499-504`（2026-09-30 版本）与 `build.yml:66-69`（`allow_version_mismatch: type: boolean, default: false`）可核验。

> **推论 [E1]**：**2026-08-29 至 2026-10-30 之间**由该工作流产出的任何内核，无论用户勾选什么，`check_version()` 都是**原生**的。
>
> 设备内核的构建时间不可知（§4），所以这条推论**不能**直接套到本机——但它把"是否被打补丁"从"完全不可知"变成了"取决于构建日期是否晚于 2026-10-30，以及那次输入是否为 true"。

### 3.3 对 U4-25 的裁定

| 子项 | 内容 | 裁定 |
| --- | --- | --- |
| **25a** | 是否"绕过了 vermagic 强校验" | ✅ **闭合**：[E1] 原生语义即可，**不存在也不需要**该绕过。原结论撤回 |
| **25b** | 是否"绕过了 `check_version()`" | ⚠️ **开放，但已给出可判条件**：见 §3.4。补丁在 CRC **匹配**时无行为差异，故**无法从运行态观测**，只能查构建输入或比对内核二进制 |
| **25c** | 其它运行时差异面（导出符号集、CFI、调度/调频策略） | ⚠️ **开放**，本轮未展开；与 GPU 驱动兼容性的关联为间接 |

### 3.4 判别矩阵：什么时候"装载成功"仍然算证据

| 验证内核的来源 | `check_version` 状态 | "模块装载成功"能否作为 CRC 一致性证据 |
| --- | --- | --- |
| 原厂 boot（`6.6.118-g54a15cf3acba`） | 原生 | ✅ 能 |
| 本工作流构建、**2026-10-30 之前** | 原生（门控恒 false） | ✅ 能 |
| 本工作流构建、2026-10-30 之后、输入 `false` | 原生 | ✅ 能 |
| 本工作流构建、2026-10-30 之后、输入 `true` | **被打补丁** | ❌ 不能（静默放行） |
| 其它第三方内核 | 未知 | ❌ 不能，须先核 |

> **对 Stage 5 的意义**：上一轮写的"验证内核不可选在绕过 vermagic 的内核上"这个**绝对禁令**不成立（那种内核不存在）；应改为**清单式前置**：验证内核必须能证明 `kernel/module/version.c` 的 `bad_version:` 为 `return 0`。这一条比原禁令更严、也更可执行。

### 3.5 一个已采集但此前被忽略的字段

`/proc/modules` 的最后一列是 taint，采集原文 15 个模块全为 **`(O)`**（`TAINT_OUT_OF_TREE`），**没有 `F`**（`TAINT_FORCED_MODULE`）。

`try_to_force_load()` 会 `add_taint_module(mod, TAINT_FORCED_MODULE)`，必然在 `/proc/modules` 留下 `F`。**无 `F` ⇒ 从未走 `modprobe --force` / "无 vermagic" 路径**。[D·C]

> 注意边界：`bad_version → return 1` 的补丁**不**打 taint，所以"无 `F`"**不能**用来排除 §3.1 的补丁。它能排除的只是"强制装载"这一类。

---

## 4. 更正三：`uname -v` 的日期**不是**构建时间

### 4.1 证据链

| 步 | 证据 |
| ---: | --- |
| 1 | 设备 `uname -v` = `#1 SMP PREEMPT **Mon Oct  5 04:20:00 UTC 2026**`[D·B] |
| 2 | 工作流步骤 `Set Build Timestamp from Kernel Commit`：`FIXED_BUILD_DATE="${OS_PATCH_LEVEL_YM}-05 04:20:00 UTC"`，再 `SOURCE_DATE_EPOCH=$(date -u -d "$FIXED_BUILD_DATE" +%s)`；注释原文："Hardcode the build timestamp to the 5th day of the patch level at 04:20 UTC" |
| 3 | GKI `build/_setup_env.sh:107-123`：`export TZ=UTC; export LC_ALL=C; ... export KBUILD_BUILD_TIMESTAMP="$(date -d @${SOURCE_DATE_EPOCH})"` |
| 4 | 因此内核里嵌的是 `date -d @<epoch>` 的**默认格式**输出（日不补零，`%e`），而非工作流里 `%d` 的 `Oct 05` |

四步合起来，设备串的 **日=05、时=04、分=20、秒=00** 与 `os_patch_level=2026-10` 派生的常量**逐字段相等**，且"`Oct  5` 双空格"恰好是第 3 步重格式化的痕迹。**这不是构建时间。** [E1]+[E2]

### 4.2 对 U4-26 的裁定

| 上一轮 | 现在 |
| --- | --- |
| "构建时间戳（10-05）与 run 时间（11-14）不可互判" | **原因更正**：10-05 不是构建时间，是**补丁月常量**。两者本来就不该互判 |
| 状态 | 仍 **开放**。`uname -v` 对该问题**零信息量** |

### 4.3 副产物：一条**正向**核对

`2026-10-05 04:20:00` ⇒ `os_patch_level = 2026-10` ⇒ 与 `08` §1.1 记录的矩阵参数 `2026-10` **一致**；再叠加 `uname -r` 的 `6.6.143`（矩阵 `143`）、`gf9aa2fec23c3`（矩阵标签内的内核提交）、`chandr1000@SukiSU-Ultra-v41181`（产物 `SukiSU_v4.3.0-r2_41181`）——**四项参数全部吻合**。

这不证明"设备 boot = run #11 的产物"（同参数重复构建会得到同样的串），但把"设备跑的是这个工作流、这组参数"从 [P] 提升到 **[B]+[D·B] 四元一致**。[E2]

---

## 5. 更正四：padding 门槛被低估了一个数量级

### 5.1 全量统计（`mali_kbase_ioctl_helpers.h`，48 个 `check_padding_*` 定义）

| 类别 | 数量 | 行为 |
| --- | ---: | --- |
| 空实现 `return 0;` | **28** | 不校验、不清零 |
| **替用户态清零** | **5** | `MEM_SYNC`、`CS_QUEUE_BIND`、`KCPU_QUEUE_DELETE`、`KCPU_QUEUE_ENQUEUE`、`QUEUE_GROUP_CLEAR_FAULTS` |
| **强制校验（非零 → `-EINVAL`）** | **12** | 见 §5.2 |

`03_gles_egl_abi.md` §9.2 原文"**只有两个真正检查**"，依据的行号范围是 `99-215`——那只覆盖了前 20 个定义，**后 28 个（含全部 CS/CSG 相关）没看**。这是本轮查出的第 4 处错误。

### 5.2 强制校验集（15 个，逐函数机器分类，`28 + 5 + 15 = 48`）

| # | ioctl（`check_padding_` 后缀） | 实现 | 行号 |
| ---: | --- | --- | --- |
| 1 | `GET_DDK_VERSION` | `return p->padding;` | 137 |
| 2 | `MEM_JIT_INIT` | 逐字节判零 | 140-150 |
| 3 | `MEM_PROFILE_ADD` | `return p->padding;` | 210-213 |
| 4 | `GET_CPU_GPU_TIMEINFO` | `in.paddings` 逐字节 | 239-250 |
| 5 | **`CS_QUEUE_REGISTER`** | 逐字节 | 273-283 |
| 6 | **`CS_QUEUE_REGISTER_EX`** | `padding` + `ex_padding` | 308-324 |
| 7 | **`CS_QUEUE_GROUP_CREATE_1_6`** | `in.padding` | 332-342 |
| 8 | **`CS_QUEUE_GROUP_CREATE_1_18`** | 同上 | 344-355 |
| 9 | **`CS_QUEUE_GROUP_CREATE_1_35`** | 同上 | 357-369 |
| 10 | **`CS_QUEUE_GROUP_CREATE`**（分派用联合体版本） | `in.padding` | 371-382 |
| 11 | **`CS_QUEUE_GROUP_TERMINATE`** | 逐字节 | 384-395 |
| 12 | **`CS_TILER_HEAP_INIT`** | `return p->in.padding;` | 433-437 |
| 13 | **`CS_TILER_HEAP_INIT_1_13`** | 同上 | 439-443 |
| 14 | `MEM_ALLOC_EX` | `in.extra` 逐字节 | 461-471 |
| 15 | `READ_USER_PAGE` | `return p->in.padding;` | 473-477 |

分派宏无条件调用（`KBASE_HANDLE_IOCTL_IN` / `_INOUT`，`mali_kbase_core_linux.c:1808` 等），**没有按 UK 版本放宽的分支**。

> **一处自我更正（留痕）**：本节初稿写"12 个强制"，是因为把 5 个 `CS_QUEUE_GROUP_CREATE_*` 变体与 2 个 `CS_TILER_HEAP_INIT` 变体各自并为一行、又漏了 `CS_QUEUE_GROUP_CREATE`（联合体分派版本）。上表由脚本对 48 个定义逐个分类生成（`28 + 5 + 15 = 48` 校验通过）。**这正是本节要批评的同一个毛病：手工数数而不全量枚举。**

### 5.3 影响面重估

| 上一轮（`06` §2.3.2 R-C2） | 现在 |
| --- | --- |
| "若 DDK 未清零 padding → **tiler heap 不可用** → 渲染**可能**失败" | "若 DDK 未清零 padding → `CS_QUEUE_REGISTER` / `CS_QUEUE_GROUP_CREATE` 直接 `-EINVAL` → **CS 队列注册失败 → GPU 完全不可用**" |
| 风险定位 | 从"局部功能失效"上调为**组合 C 的单点致命风险** |

> **仍未变的事实**：这不代表一定发生。1.30 DDK 是否清零 padding，取决于它自己的实现（常见做法是 `struct x = {0}`），而**这条证据必须来自 `libGLES_mali.so`**——53 MB 二进制，仓库内无任何分析（`/workspace/_rea_analysis` 只有 12 个 `.ko`，无 DDK）。**U4-04 因此不能闭合。**

### 5.4 props 门槛的机制（这一条反而**不再**是硬阻断）

```c
/* r56p0 mali_kbase_core_linux.c:870-891 */
if (get_props->flags != 0) return -EINVAL;
if (get_props->size == 0) return (int)kprops->prop_buffer_size;   /* ← 两阶段协商 */
if (get_props->size < kprops->prop_buffer_size) return -EINVAL;   /* ← 唯一的硬门槛 */
copy_to_user(...)
```

- DDK 只要**先问一次 `size=0`**，就能拿到 592 并开对缓冲 → 不触发门槛。
- 只有 DDK **写死 568** 才会 `-EINVAL`。

所以 R-C3 的成立条件被精确化为："DDK 是否做 `size=0` 探测"。**这是反编译能一眼看出的事**（一次 `ioctl(fd, GET_GPUPROPS, {size:0})`），成本远低于 §5.3。

---

## 6. U4-12：现在闭不了，原因已精确

### 6.1 交付包里**没有**固件，也没有 DDK

`02_r56_source/_arm_listing/arm_5thgen_package_listing_20261115.json` 共 **23 个条目**，按关键词检索命中数：

| 关键词 | 命中 |
| --- | ---: |
| `firmware` | **0** |
| `.bin` | **0** |
| `ddk` | **0** |
| `libGLES` | **0** |
| `vulkan` | **0** |
| `csffw` | **0** |

> 结论：`AX504X08X-SW-99002-r56p0-18eac0.tar.gz` 是**内核驱动源码交付物**，`mali_csffw.bin` 与用户态 DDK 属**另外的商业授权件**。U4-12 的阻断性质因此是"**资产不在手**"，不是"没找对地方"。[E1]

### 6.2 一旦拿到 R56 固件，验收判据（预先写死，避免临时找理由）

| # | 检查 | 通过条件 |
| ---: | --- | --- |
| 1 | header 前 8 字节 | `offset 4 = 0x04`、`offset 5 = 0x00`（r56p0 加载器 `!=` 严格） |
| 2 | GPU 型号 / core mask | 与 `Immortalis-G925 MC12`（12 核）一致，非 MP/其它 SKU |
| 3 | `GLB` 接口版本 | 与 r56p0 kbase 期望的 glb 版本区间相容 |
| 4 | 与 DDK 的配套性 | 同一 release（`r56p0-18eac0`）交付 |

> 第 2 项是本项目最容易"以为对上、其实没对"的地方：**G925 支持 ≠ MT6991 平台支持**，同一 SKU 还有 MC9/MC10/MC12 之分。

---

## 7. 仍开放项与最小动作

| ID | 内容 | 为什么现在闭不了 | 最小动作 | 成本 |
| --- | --- | --- | --- | --- |
| **U4-04** | DDK 是否清零 padding / 是否做 props 协商 | 需 `libGLES_mali.so` 内部证据；该文件 53 MB，不可上传，仓库内无分析 | ① 只读：`strace -f -e trace=ioctl` 抓一次 `eglInitialize`，**只能确认这些 ioctl 被调用过、以及请求号里的 `size` 字段**（`strace` 不解码私有结构体，**看不到 padding 字节**）；② **真正能定性的只有反汇编或取得 R49 DDK 源码** | 低（①）/ 高（②） |
| **U4-24b** | 设备构建的 `__versions` CRC | 需设备侧 `readelf -x` 文本 | `readelf -x __versions /vendor_dlkm/lib/modules/ged.ko` | 极低 |
| **U4-25b** | 运行内核 `check_version` 是否被打补丁 | 补丁在 CRC 匹配时**无行为差异**，运行态不可观测 | 查构建输入（需仓库权限）或比对内核二进制 | 低—中 |
| **U4-26** | 设备 boot 是否为 run #11 产物 | `uname -v` 零信息量（§4）；缺内核镜像哈希 | 采 `/sys/kernel/notes` 的 build-id，与产物内 `Image` 比对 | 低 |
| **U4-27** | `/vendor` 是否被 overlay | 未采 mount 表 | `cat /proc/self/mountinfo \| grep -E "vendor\|overlay"` | 极低 |
| **U4-10** | 失败后是否 bootloop | 需故障注入，须可回滚环境 | 不在只读范围内 | 高 |
| **U4-12** | R56 固件匹配 G925 MC12 | 资产不在手（§6） | 需取得商业交付件 | 阻断 |

---

## 8. Stage 4 最终裁定

### 8.1 27 项状态（本轮后）

> **注（2026-11-16 第二轮）**：下表是**第一轮**的计数（PARTIAL 5），保留作历史。该轮增量为：**U4-04b 闭合**、**U4-10 转 PARTIAL**、**U4-12 单列 BLOCKED** → 五态 **5 / 6 / 1 / 15**（§11）。
>
> **注（2026-11-16 第三轮，TASK-STAGE4-REMAINDER）**：计数再变为 **CLOSED 5 / PARTIAL 8 / BLOCKED 1 / OPEN 13**（`D-033`：U4-14、U4-15 由 OPEN 转 PARTIAL）。**现行权威台账**改为 [`../06_porting_design/STAGE4_REMAINING_AUDIT.md`](../06_porting_design/STAGE4_REMAINING_AUDIT.md)；`06/STAGE4_FINAL_REPORT.md` 保留为时点快照。本轮另更正本文一处**方法学错误**：§7 的 U4-04 行曾把「`strace` 抓 padding 字节」列为可行闭合手段，实际 `strace` 只能解出 `_IOC` 请求号，**看不到结构体内容**（`D-031` 后 U4-04c 的闭合手段改为 R49 DDK 源码或反汇编）。

| 状态 | 数量 | 明细 |
| --- | ---: | --- |
| ✅ 已闭合 | **5** | U4-01 / U4-03 / U4-05 / U4-08 / U4-09 |
| ⚠️ 部分闭合 | **5** | U4-04（版本代次 ✅、padding/props ❌）/ U4-06 / U4-07 / U4-24（a ✅、b ❌）/ **U4-25（a ✅、b/c ❌）** |
| **[U] 开放** | **17** | 含 P0 三项：U4-04 行为子项 / U4-10 / U4-12 |
| **P0 数量** | **3** | 不变 |

> **本轮计数变化**：部分闭合 4 → 5（新增 U4-25，其 a 子项闭合、原"绕过 vermagic"结论撤回）。P0 仍 3 项，但 **U4-04 的风险等级上调为"单点致命"**（§5.3）。

### 8.2 结论：**B — 有条件可行，存在明确阻断项**

| 判定对象 | 结论 | 依据 |
| --- | --- | --- |
| 组合 A/B 的裁定 | **不变**，仍然成立 | 与本节全部更正经纬正交 |
| 最小替换范围 = kbase + 固件 | **不变** | 同上 |
| 用户态契约层可保留 | **不变**（实现层仍 [U]） | 同上 |
| Stage 4 是否可以宣布"证据闭环" | **不可以** | U4-04 / U4-12 两项 P0 未闭；U4-24b 未闭 |
| 是否可进入 Stage 5A（设计） | **可以**（需用户授权） | 设计所需的架构证据已足；三处机制错误已在本轮清除，不会把错误假设带进设计 |
| 是否可进入 Stage 5B（实施） | **不可以** | 见 §9 |

> **为什么"机制错了"仍不推翻结论面**：`same_magic` 的语义不改变"原厂固件 header 0.3 vs r56p0 要求 0.4"这条硬判据，也不改变 UAPI 逐字相同的事实。但它改变了**验证策略**（§3.4）与**风险排序**（§5.3）——这两样恰恰是 Stage 5A 的输入。

---

## 9. 进入 Stage 5A 前必须补的三件事

1. **U4-04c 的 padding 子项**（现在是最贵的风险）：**只能靠 R49 DDK 源码或反汇编定性**（`strace` 看不到结构体内容，见 `06/STAGE4_DEVICE_COLLECTION_PLAN.md` §6）。已知 R49 kbase 自身内联校验 9 处（`D-031`），未知面已收窄到 4 条（`CS_QUEUE_REGISTER` 为致命位）。若 R49 DDK 清零 → 风险清零；若不清零 → 组合 C 直接判死。
2. **U4-12 的固件资产**：没有 `mali_csffw.bin 0.4`，组合 D 无法评估，Stage 5A 只能做"条件式设计"。
3. **U4-24b 的单样本 CRC**：一条 `readelf -x`，把"14 个模块可沿用"从推断变实测。

> 三项都是**只读文本操作**，不需要镜像、不需要编译、不需要上传二进制。

---

## 10. 本轮引用的外部证据（可核验）

| # | 来源 | 用途 |
| ---: | --- | --- |
| 1 | `https://git.kernel.org/.../plain/kernel/module/version.c?h=v6.6` | `same_magic()` 语义、`bad_version` 分支 |
| 2 | `https://git.kernel.org/.../plain/kernel/module/main.c?h=v6.6`（:2089） | `same_magic` 调用点、`check_modinfo` 失败路径 |
| 3 | `github.com/JiangXue5/GKI_KernelSU_SUSFS` → `.github/actions/bypass-kernel/action.yml` | 真正的绕过开关 |
| 4 | 同上 → `.github/workflows/build.yml`（`9f91301d3` / `02b1ae742` / `a60756073`） | 门控写法与时间窗、`allow_version_mismatch` 类型 |
| 5 | 同上 → 提交 `32ba07352`(08-29) / `02b1ae742`(09-14) / `a60756073`(10-30) | 门控 bug 的引入与修复时间 |
| 6 | `https://android.googlesource.com/kernel/build/+/refs/heads/main/_setup_env.sh`（:107-123） | `KBUILD_BUILD_TIMESTAMP` 由 `SOURCE_DATE_EPOCH` 重格式化 |
| 7 | 本地 `02_r56_source/mali_r56p0/.../mali_kbase_ioctl_helpers.h` | 48 个 `check_padding_*` 全量分类 |
| 8 | 本地 `02_r56_source/mali_r56p0/.../mali_kbase_core_linux.c:870-891` | props 两阶段协商 |
| 9 | 本地 `02_r56_source/_arm_listing/arm_5thgen_package_listing_20261115.json` | 23 条目、0 固件命中 |
| 10 | 设备采集 `stage4_mod_20261116_000412.txt`（已在库，未重跑） | taint 列、`__versions` 节大小、`uname -v` |

---

## 11. 追加核验（2026-11-16 第二轮，TASK-STAGE4-FINAL）

> 本节为 `09` 第一版之后新增的**独立复核**，不改动 §1–§10 的任何结论；只补三条新证据与一条对 `03` 的自我更正。

### 11.1 新证据一：R49 与 R56 的 UAPI 结构体布局差异只有 2 处（双向全量比对）

对两代 `include/uapi/gpu/arm/midgard/` 的 `mali_kbase_ioctl.h` 与 `csf/mali_kbase_csf_ioctl.h` 做去注释逐字段比对：

| 文件 | 共同结构体 | 字段有差异 | 仅 R49 有 | 仅 R56 有 |
| --- | ---: | ---: | ---: | ---: |
| `mali_kbase_ioctl.h` | 28 | 1 | 6 | 0 |
| `csf/mali_kbase_csf_ioctl.h` | 23 | 1 | 0 | 2 |

- 差异 1：`kbase_ioctl_mem_sync` 首字段 `__u64 handle` → `__u64 gpu_va`，**纯重命名**，布局不变。
- 差异 2：`kbase_ioctl_cs_queue_group_create` 由 112 B 扩为 120 B 且 ioctl 号 58→63；但 R56 保留 `_1_35` 变体（nr 58 / 112 B），并在 `mali_kbase_core_linux.c:1446-1472` 做**逐字段迁移**，`neural_max` / `fragment_endpoint_task_limit` / `reserved` 一律置 0。

**结论**：`03` §9 与 `06` §2.3 的"契约层 30/30 兼容"由此获得更强的支撑——不是"抽样看起来一样"，而是"51 个共同结构体、实质差异 0（唯一扩展被兼容变体吸收）"。[E1]

### 11.2 新证据二：R56 删除了 6 个 ioctl，其中 1 个是 MTK 私有

| ioctl | 号 | 说明 |
| --- | ---: | --- |
| `HWCNT_READER_SETUP` / `HWCNT_VALUES` | 8 | 旧 HWCNT 读取，R49 版本注释已标"Remove" |
| `DISJOINT_QUERY` | — | 已废弃 |
| `SET_LIMITED_CORE_COUNT` | 55 | R56 版本注释标 "Remove legacy IOCTLs … at 1.34" |
| **`INTERNAL_FENCE_WAIT`** | **80** | **MTK 私有**（`CONFIG_MALI_MTK_FENCE_DEBUG`）；R49 实现于 `mali_kbase_core_linux.c:2264`，R56 无 |
| `CINSTR_GWT_DUMP` | — | 调试用 |

ioctl 80 的用途是**internal fence 超时上报**（日志 + 可选 `mtk_common_debug` 转储 + `CONFIG_MALI_MTK_FENCE_TIMEOUT_RESET` 下的自动 reset），**不在渲染主路径**，但它是"超时自愈"链条上唯一的 MTK 入口。→ 归入 U4-14，并与 U4-10 的"reset 后恢复"关联。

### 11.3 新证据三：CSF 固件加载**不在 probe**，而在首次 `open()`

```c
/* r56p0 mali_kbase_core_linux.c:790-802 */
/* Device-wide firmware load is moved here from probing to comply with
 * Android GKI vendor guideline. */
ret = kbase_device_firmware_init_once(kbdev);
if (ret) goto out;
```

R49 同构（`device/backend/mali_kbase_device_csf.c:463-474` 同一注释）。推论：

| 命题 | 结论 |
| --- | --- |
| 固件失败是否导致 probe 失败 / bootloop | **否**（probe 不涉及固件；失败只让 `open()` 返回错误） |
| 失败后能否重试 | **能**（`firmware_inited` 未置位，下次 `open` 重新加载） |
| 后果性质 | **可用性丧失**（GPU 全栈不可用），不是**启动阻断** |

→ U4-10 由 OPEN 转 **PARTIAL**。

### 11.4 一条对 `03` 的自我更正

`03` §9.2 第一版写"只有两个真正检查"，`09` §5 已更正为 **15 处强制**。本轮补充其**后果边界**：R49 kbase **根本没有** `mali_kbase_ioctl_helpers.h`（该机制 R50+ 引入），所以 R49 环境下 padding **不被校验**——这既解释了"为什么 R49 DDK 可能不清零"，也说明"R49 上能跑"**不能**反推"清零"。

> ❌ **本段结论已被推翻（2026-11-16，`D-031`）**。前提「R49 kbase 没有 `mali_kbase_ioctl_helpers.h`」**正确**（该文件确实是 R50+ 的集中式 helper），但由此推出「R49 不校验 padding」**错误**。
>
> R49 kbase 把校验**内联**写在调用点，**9 处**（路径均已逐行复核）：
>
> | # | 文件:行 | 对象 |
> | ---: | --- | --- |
> | 1 | `mali_kbase_core_linux.c:1160-1166` | `MEM_JIT_INIT` 的 `padding[]` |
> | 2 | `mali_kbase_core_linux.c:1518-1521` | `CSG_CREATE_1_6` 的 `in.padding[]` |
> | 3 | `mali_kbase_core_linux.c:1550-1553` | `CSG_CREATE_1_18` 的 `in.padding[]` |
> | 4 | `csf/mali_kbase_csf.c:1367-1370` | **现版 `CSG_CREATE` 的 `in.padding[9]`（offset 40–111）** |
> | 5 | `mali_kbase_core_linux.c:1568-1571` | 现版 `CSG_CREATE` 的 `in.reserved` |
> | 6 | `mali_kbase_core_linux.c:1714-1716` | `READ_USER_PAGE` 的 `in.padding` |
> | 7 | `csf/mali_kbase_csf_kcpu.c:3059-3063` | KCPU 命令的 `command.padding[]` |
> | 8 | `mali_kbase_kinstr_jm.c:756-758` | `KINSTR_JM_FD` 的 `in.padding` |
> | 9 | `mali_kbase_softjobs.c:894-897` | `base_jit_alloc_info` 的 `info->padding`（`kbasep_jit_alloc_validate`） |
>
> **后果**：①「R49 上能跑」**仍然不能**反推「DDK 清零」这个结论**方向不变**，但理由不同——不是因为不校验，而是因为**只有部分结构体被校验**；②更重要的是，现版 CSG 校验的 `padding[9]`（offset 40–111）是 R56 所查 `padding[62]`（offset 50–111）的**超集**，加上「设备确实在渲染」这一 [D·B] 事实，可推出 **R56 这一关必过**（[E1]+[D·B] → [E2]，见 `06/STAGE4_REMAINING_AUDIT.md` §3.1）。
>
> **原文保留以留痕**，不删除（`AGENTS.md` §0.7）。

### 11.5 本轮引用的新增外部/本地证据

| # | 来源 | 用途 |
| ---: | --- | --- |
| 11 | `01_original_baseline/.../mali-r49p1/.../include/uapi/gpu/arm/midgard/{mali_kbase_ioctl.h, csf/mali_kbase_csf_ioctl.h}` | 51 个共同结构体的逐字段比对 |
| 12 | `02_r56_source/.../include/uapi/.../csf/mali_kbase_csf_ioctl.h:296-436, 767-796` | `_1_6` / `_1_18` / `_1_35` / 现版的 nr 与 size |
| 13 | `02_r56_source/.../mali_kbase_core_linux.c:1446-1472` | `_1_35` 逐字段迁移 |
| 14 | `02_r56_source/.../mali_kbase_ioctl_helpers.h:137-477` | 15 处强制校验的行号 |
| 15 | `02_r56_source/.../mali_kbase_hw.c:272`、`mali_kbase_core_linux.c:2512/2582` | `TKRX` 产品名与 `tKRx` workaround 表 |
| 16 | `01_original_baseline/.../mali-r49p1/.../mali_kbase_core_linux.c:1830-1880, 2264` | ioctl 80 的实际用途 |
