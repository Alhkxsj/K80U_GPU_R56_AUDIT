#!/system/bin/sh
# =============================================================================
# collect_gpu_module_identity.sh — [U4-24] 设备侧 GPU 内核模块身份核验
#
# 目的：回答「设备上真正装载的 GPU 内核模块是哪一份构建」。
#       采集每个模块的：实际路径 / 文件大小 / SHA256 / vermagic / version /
#       srcversion / sysfs 运行时视图 / ELF Build ID / 关键节大小。
#
# 为什么不能沿用已有采集：
#   三份 Stage 4 采集（inventory / file_metadata / elf_analysis）只包含
#   `lsmod` 输出（模块名、内存尺寸、refcount、used-by），**没有**：
#     - 模块文件的真实路径
#     - 文件大小 / SHA256
#     - vermagic（这是判定"是否同一构建"的决定性判据）
#   因此 U4-24 无法离线闭合，必须补一次设备侧只读采集。
#
# 严格约束（逐条对应任务书）：
#   * 只读。不复制、不导出、不 pull、不压缩打包任何 .ko。
#   * 不依赖 adb、不依赖 Termux、不要求安装任何新工具。
#   * 工具缺失输出 NOT_AVAILABLE，不让整个脚本失败。
#   * 路径不可访问输出 NOT_READABLE / NOT_FOUND，不伪造。
#   * 只产生一份纯文本；不修改系统属性、内核参数、模块状态、分区。
#   * 不判定兼容性：本脚本只出证据，结论由仓库文档给出。
#
# 字段判据来自源码/内核约定（不是预期值）：
#   - vermagic 是 struct module 的字符串字段，modpost 生成，形如
#     "6.6.143-android15-8-gf9aa2fec23c3-4k SMP preempt mod_unload modversions aarch64"
#     位于 .modinfo 段，故 `strings <ko> | grep '^vermagic='` 可取。
#   - CONFIG_MODVERSIONS=y 时内核按 **逐字符相等** 比较 vermagic 与
#     VERMAGIC_STRING（UTS_RELEASE + 编译期配置串），不符即 refuse to load。
#     => 能装载成功的 .ko，其 vermagic 必与 uname -r 完全一致。
#     该推论用于把"设备 .ko 必然是另一次构建"从推理升级为实测。
#   - /proc/modules 第 2 字段是 mod->core_layout.size（内存占用，页对齐），
#     **不是文件大小**。两者不可直接相减，本脚本分开记录并标注。
#   - /sys/module/<name>/version 是 MODULE_VERSION() 的展开值，缺失时该文件不存在。
#   - /sys/module/<name>/notes/.note.gnu.build-id 是内核导出的 ELF note
#     （namesz/descsz/type/"GNU\0"/20 字节 sha1），只读即可得 Build ID。
#
# 用法（手机 aShell You，已 root）：
#   su -c 'sh /data/local/tmp/c.sh'
# 或直接：
#   su
#   sh /data/local/tmp/c.sh
#
# 退出码：0 = 脚本正常跑完（不代表任何结论闭合）；1 = 环境不可用（无 shell 工具）
# =============================================================================

set -u

VER="1.0"

# ---- 输出位置：优先 /data/local/tmp，退回 /sdcard/Download -------------------
OUTDIR="${OUTDIR:-/data/local/tmp/gpu_audit_mod}"
if ! mkdir -p "$OUTDIR" 2>/dev/null; then
    OUTDIR="/sdcard/Download/gpu_audit_mod"
    mkdir -p "$OUTDIR" 2>/dev/null || OUTDIR=""
fi
TS_H="$(date '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || echo unknown)"
TS_F="$(date '+%Y%m%d_%H%M%S' 2>/dev/null || echo run)"
OUT=""
if [ -n "$OUTDIR" ]; then
    OUT="$OUTDIR/stage4_mod_$TS_F.txt"
    : > "$OUT" 2>/dev/null || OUT=""
fi

say() {
    printf '%s\n' "$*"
    if [ -n "$OUT" ]; then printf '%s\n' "$*" >> "$OUT" 2>/dev/null; fi
}
sec() {
    say ""
    say "================================================================"
    say "$*"
    say "================================================================"
}
sub() {
    say ""
    say "--- $* ---"
}
have() { command -v "$1" >/dev/null 2>&1; }
oneline() { printf '%s' "${1:-}" | tr '\n' ';' | tr -s ';' ';' | sed 's/;;*/;/g; s/^;//; s/;$//'; }

# 读一个文件的文本内容；不可读则输出标记
rd() {
    if [ -r "$1" ]; then
        _v="$(cat "$1" 2>/dev/null)"
        if [ -z "$_v" ]; then printf 'EMPTY'; else printf '%s' "$_v"; fi
    else
        printf 'NOT_READABLE'
    fi
}

# 文件大小（字节）；失败输出空
fsize() {
    _s="$(wc -c < "$1" 2>/dev/null | tr -d ' ')"
    if [ -z "$_s" ] && have stat; then
        _s="$(stat -c %s "$1" 2>/dev/null)"
    fi
    printf '%s' "${_s:-}"
}

# =============================================================================
sec "STAGE 4 / U4-24 — GPU KERNEL MODULE IDENTITY (READ-ONLY)"
say "SCRIPT_VERSION: $VER"
say "COLLECT_TIME:   $TS_H"
say "SCOPE:          read-only metadata only; no .ko is copied, compressed or uploaded"
say "OUTPUT_FILE:    ${OUT:-<stdout only>}"

# =============================================================================
sec "0. ENVIRONMENT"
say "DEVICE_MODEL:  $(getprop ro.product.model 2>/dev/null || echo NOT_AVAILABLE)"
say "DEVICE_CODE:   $(getprop ro.product.device 2>/dev/null || echo NOT_AVAILABLE)"
say "FINGERPRINT:   $(getprop ro.build.fingerprint 2>/dev/null || echo NOT_AVAILABLE)"
say "BUILD_RELEASE: $(getprop ro.build.version.release 2>/dev/null || echo NOT_AVAILABLE) / SDK $(getprop ro.build.version.sdk 2>/dev/null || echo NOT_AVAILABLE)"
say "SELINUX:       $(id 2>/dev/null || echo NOT_AVAILABLE)"
say "UID:           $(id -u 2>/dev/null || echo NOT_AVAILABLE)"
say "KERNEL_ALL:    $(uname -a 2>/dev/null || echo NOT_AVAILABLE)"
KREL="${KREL:-$(uname -r 2>/dev/null || echo unknown)}"
say "KERNEL_RELEASE: $KREL"
say "KERNEL_VERSION: $(uname -v 2>/dev/null || echo NOT_AVAILABLE)"
say "PROC_VERSION:  $(rd /proc/version)"

sub "TOOL AVAILABILITY"
for t in sha256sum od xxd strings readelf modinfo lsmod grep awk sed find readlink wc stat sort head; do
    _p="$(command -v "$t" 2>/dev/null)"
    if [ -n "$_p" ]; then say "$(printf '%-10s %s' "$t" "$_p")"; else say "$(printf '%-10s NOT_AVAILABLE' "$t")"; fi
done

# =============================================================================
sec "1. /proc/modules — GPU 链路模块（动态发现）"
# 名字白名单：mali 系 / ged / MTK GPU 系 / MET GPU 系
RE='^(mali_|ged$|mtk_gpu|mtk_gpufreq|mtk_ghpm|mtk_cg_peak|met_gpu|met_gpueb)'
# 以下三项可在测试时用环境变量覆盖（真机不需要设置）
PROCMOD="${PROCMOD:-/proc/modules}"
SYSFS_ROOT="${SYSFS_ROOT:-/sys/module}"
if [ -z "${ROOTS:-}" ]; then
    ROOTS="/vendor_dlkm/lib/modules /vendor/lib/modules /vendor/lib64/modules /system_dlkm/lib/modules /odm/lib/modules /lib/modules /vendor_dlkm"
fi
if [ -r "$PROCMOD" ]; then
    sub "RAW LINES (name size refcnt usedby state addr taint)"
    grep -E "$RE" "$PROCMOD" 2>/dev/null | while read -r _l; do say "$_l"; done
    _n="$(grep -cE "$RE" "$PROCMOD" 2>/dev/null)"
    say ""
    say "MATCHED_COUNT: ${_n:-0}"
    say "TOTAL_MODULES_IN_PROC: $(grep -c '' "$PROCMOD" 2>/dev/null)"
else
    say "PROC_MODULES: NOT_READABLE ($PROCMOD)"
fi

# =============================================================================
sec "2. 模块文件搜索根目录"
# ROOTS 已在 §1 定义（可被环境变量覆盖）
for r in $ROOTS; do
    if [ -d "$r" ]; then
        say "$(printf '%-34s EXISTS' "$r")"
    else
        say "$(printf '%-34s NOT_FOUND' "$r")"
    fi
done

sub "MODULE INDEX FILES（决定 insmod 实际取哪个路径）"
for r in $ROOTS; do
    [ -d "$r" ] || continue
    for f in modules.load modules.load.vendor modules.load.recovery modules.dep modules.order modules.builtin modules.alias; do
        [ -f "$r/$f" ] || continue
        say "$r/$f  SIZE=$(fsize "$r/$f")"
        grep -E "$RE" "$r/$f" 2>/dev/null | head -40 | while read -r _l; do say "    $_l"; done
    done
    # 版本子目录
    if [ -d "$r/$KREL" ]; then say "$r/$KREL  EXISTS"; else say "$(printf '%-46s NOT_FOUND' "$r/$KREL")"; fi
done

# =============================================================================
sec "3. 候选模块集合（任务书名单 ∪ /proc/modules 实际命中 ∪ 邻接模块）"
NAMES=""
add_name() {
    case " $NAMES " in
        *" $1 "*) : ;;
        *) NAMES="$NAMES $1" ;;
    esac
}
# (a) 任务书点名 + 实际存在的对应模块名（注意：任务书给的若干名字是"组件名"而非模块名）
for m in mali_kbase_mt6991 mali_kbase_mt6991_r49 ged gpufreq gpueb mtk_gpufreq_mt6991 mtk_gpufreq_wrapper mtk_gpueb \
         mali_kbase_mem_pool_group_manager mali_kbase_mem_pool_manager mali_kbase_mgm mali_kbase_pma \
         mali_mgm_mt6991_r49 mali_prot_alloc_mt6991_r49 \
         mtk_gpu_hal mtk_gpu_pdma_mt6991 mtk_gpu_qos mtk_gpu_iommu_mt6991 mtk_gpu_power_throttling mtk_ghpm \
         mtk_cg_peak_power_throttling mtk_smmu_qos \
         met_gpu_api met_gpu_adv_api met_gpueb_api; do
    add_name "$m"
done
# (b) 运行时实际命中的模块（防止名单遗漏）
if [ -r "$PROCMOD" ]; then
    for m in $(grep -E "$RE" "$PROCMOD" 2>/dev/null | awk '{print $1}'); do add_name "$m"; done
fi
# (c) 去重并排序
NAMES="$(printf '%s\n' $NAMES | sort -u)"
say "CANDIDATE_COUNT: $(printf '%s\n' $NAMES | grep -c '')"
for m in $NAMES; do say "  - $m"; done

# =============================================================================
sec "4. 逐模块身份（sysfs 运行时视图 与 磁盘文件 严格分开记录）"

FOUND=0; HASHED=0; NOTREAD=0; NOTFOUND=0; LOADED=0

probe() {
    m="$1"
    say ""
    say "##############################################################"
    say "[MODULE] $m"
    say "##############################################################"

    # ---- 4.1 运行时（B 类：第三方内核视角） ----
    sub "4.1 RUNTIME (sysfs / proc)"
    _pl="$(grep -m1 "^$m " "$PROCMOD" 2>/dev/null)"
    if [ -n "$_pl" ]; then
        LOADED=$((LOADED+1))
        say "LOADED:            YES"
        say "LSMOD_SIZE_BYTES:  $(printf '%s' "$_pl" | awk '{print $2}')"
        say "LSMOD_REFCNT:      $(printf '%s' "$_pl" | awk '{print $3}')"
        say "LSMOD_USED_BY:     $(printf '%s' "$_pl" | awk '{print $4}')"
        say "LSMOD_TAINT_FLAGS: $(printf '%s' "$_pl" | awk '{for(i=6;i<=NF;i++) printf "%s ", $i}')"
        say "LSMOD_NOTE:        LSMOD_SIZE 是 core_layout.size（内存、页对齐），非文件大小"
    else
        say "LOADED:            NO"
        say "LSMOD_NOTE:        未出现在 /proc/modules（可能未装载 / 内建 / 本机型不存在）"
    fi
    S="$SYSFS_ROOT/$m"
    if [ -d "$S" ]; then
        say "SYSFS_VERSION:     $(rd "$S/version")"
        say "SYSFS_SRCVERSION:  $(rd "$S/srcversion")"
        say "SYSFS_TAINT:       $(rd "$S/taint")"
        say "SYSFS_INITSTATE:   $(rd "$S/initstate")"
        say "SYSFS_CORESIZE:    $(rd "$S/coresize")"
        say "SYSFS_INUSE:       $(rd "$S/inuse")"
        say "SYSFS_HOLDERS:     $(oneline "$(ls "$S/holders" 2>/dev/null)")"
        _bid_file="$S/notes/.note.gnu.build-id"
        if [ -r "$_bid_file" ] && have od; then
            say "SYSFS_BUILDID_HEX: $(od -An -tx1 "$_bid_file" 2>/dev/null | tr -d '\n' | tr -s ' ')"
            say "SYSFS_BUILDID_NOTE: 格式 = namesz(4) descsz(4) type(4) \"GNU\\0\"(4) sha1(20)，末尾 20 字节即 Build ID"
        else
            say "SYSFS_BUILDID_HEX: NOT_READABLE"
        fi
    else
        say "SYSFS_DIR:         NOT_FOUND ($S)"
    fi

    # ---- 4.2 磁盘文件（C 类：厂商分区文件） ----
    sub "4.2 ON-DISK FILE (vendor partition)"
    FP=""
    for r in $ROOTS; do
        for d in "$r" "$r/$KREL"; do
            [ -d "$d" ] || continue
            if [ -f "$d/$m.ko" ]; then FP="$d/$m.ko"; break; fi
        done
        [ -n "$FP" ] && break
    done
    if [ -n "$FP" ]; then
        FOUND=$((FOUND+1))
        say "FILE_PATH:         $FP"
        _rp=""
        if have readlink; then _rp="$(readlink -f "$FP" 2>/dev/null)"; fi
        say "FILE_REALPATH:     ${_rp:-NOT_AVAILABLE}"
        _sz="$(fsize "$FP")"
        say "FILE_SIZE_BYTES:   ${_sz:-NOT_READABLE}"
        if [ -r "$FP" ]; then
            say "FILE_MODE:         $(ls -l "$FP" 2>/dev/null | awk '{print $1, $2, $3, $4}')"
        else
            say "FILE_MODE:         NOT_READABLE"
        fi
        if [ -r "$FP" ] && have sha256sum; then
            _h="$(sha256sum "$FP" 2>/dev/null | awk '{print $1}')"
            if [ -n "$_h" ]; then
                HASHED=$((HASHED+1))
                say "FILE_SHA256:       $_h"
            else
                NOTREAD=$((NOTREAD+1))
                say "FILE_SHA256:       NOT_READABLE"
            fi
        else
            say "FILE_SHA256:       NOT_AVAILABLE (无 sha256sum 或不可读)"
        fi

        # modinfo 静态字段（从 .modinfo 段读字符串，不需要 modinfo 命令）
        sub "4.3 .modinfo (strings, 文件内静态字段)"
        if [ -r "$FP" ] && have strings; then
            _mi="$(strings -a "$FP" 2>/dev/null | grep -E '^(name|vermagic|srcversion|version|depends|retpoline|intree|license)=' | head -24)"
            if [ -n "$_mi" ]; then
                printf '%s\n' "$_mi" | while read -r _l; do say "$_l"; done
            else
                say "MODINFO_FIELDS: NOT_FOUND (该文件可能已被 strip 掉 .modinfo)"
            fi
            _vm="$(strings -a "$FP" 2>/dev/null | grep -m1 '^vermagic=')"
            if [ -n "$_vm" ]; then
                say "VERMAGIC_CHECK:    ${_vm#vermagic=}"
                case "$_vm" in
                    "vermagic=$KREL "*) say "VERMAGIC_MATCHES_UNAME_R: YES" ;;
                    *)                  say "VERMAGIC_MATCHES_UNAME_R: NO" ;;
                esac
            else
                say "VERMAGIC_CHECK:    NOT_FOUND"
            fi
        else
            say "MODINFO_FIELDS: NOT_AVAILABLE"
        fi

        # ELF 头 / Build ID / 关键节
        sub "4.4 ELF"
        if [ -r "$FP" ] && have readelf; then
            _eh="$(readelf -h "$FP" 2>/dev/null | awk -F: '/Class:|Type:|Machine:/{gsub(/^[ \t]+|[ \t]+$/,"",$2); printf "%s=%s;", $1, $2}')"
            say "ELF_HEAD:    ${_eh:-NOT_AVAILABLE}"
            _b="$(readelf -n "$FP" 2>/dev/null | grep -m1 -E 'Build ID:' | sed 's/^ *//')"
            say "ELF_BUILD_ID: ${_b:-NOT_FOUND}"
            # 宽模式一行一节；名字与大小（十六进制）成对输出
            _raw="$(readelf -SW "$FP" 2>/dev/null)"
            if [ -z "$_raw" ]; then _raw="$(readelf --wide -S "$FP" 2>/dev/null)"; fi
            if [ -n "$_raw" ]; then
                printf '%s\n' "$_raw" | sed -n 's/^ *\[ *[0-9]*\] *//p' \
                    | awk '$1==".text"||$1==".init.text"||$1==".rodata"||$1==".modinfo"||$1=="__versions"||$1=="__ksymtab"||$1=="__ksymtab_strings"{printf "SEC %-20s size=0x%s\n", $1, $5}' \
                    | while read -r _l; do say "$_l"; done
                say "SEC_NOTE: __versions 每条 12 字节（name ptr + crc + name）；__ksymtab 每条 12 字节（有 CRC 时每条 +4）"
            else
                say "SEC: NOT_FOUND (readelf -SW / --wide 均无输出)"
            fi
        else
            say "ELF: NOT_AVAILABLE"
        fi
    else
        NOTFOUND=$((NOTFOUND+1))
        say "FILE_PATH:         NOT_FOUND"
        # 压缩模块 / 内建模块的可能
        _hit=""
        for r in $ROOTS; do
            for d in "$r" "$r/$KREL"; do
                [ -d "$d" ] || continue
                for e in ko.gz ko.zst ko.xz; do
                    [ -f "$d/$m.$e" ] && _hit="$_hit $d/$m.$e"
                done
            done
        done
        if [ -n "$_hit" ]; then
            say "FILE_COMPRESSED_CANDIDATES:"
            for x in $_hit; do
                say "  $x  SIZE=$(fsize "$x")  SHA256=$(sha256sum "$x" 2>/dev/null | awk '{print $1}')"
            done
            say "FILE_COMPRESSED_NOTE: 压缩容器哈希 ≠ 解压后 .ko 哈希，不可与仓库基线直接比对"
        fi
        _bi=""
        for r in $ROOTS; do
            if [ -f "$r/modules.builtin" ]; then
                _bi="$(grep -m1 "/$m\.ko" "$r/modules.builtin" 2>/dev/null)"
            fi
            [ -n "$_bi" ] && { say "BUILTIN_HINT:      $_bi ($r/modules.builtin)"; break; }
        done
        [ -z "$_bi" ] && say "BUILTIN_HINT:      NOT_FOUND (modules.builtin 中无此模块)"
    fi
}

for m in $NAMES; do probe "$m"; done

# =============================================================================
sec "5. 目录扫描：白名单之外的 GPU 相关 .ko（防止名单遗漏）"
_scanned=0
for r in $ROOTS; do
    [ -d "$r" ] || continue
    if have find; then
        find "$r" -maxdepth 3 -name '*.ko*' 2>/dev/null | grep -Ei 'mali|gpu|ged|gpueb|gpufreq|met_|ghpm|smmu' | sort | head -80 | while read -r _l; do
            say "$(printf '%-72s %10s' "$_l" "$(fsize "$_l")")"
        done
        _scanned=1
    else
        say "FIND: NOT_AVAILABLE — 跳过深度扫描"
        ls -l "$r" 2>/dev/null | grep -Ei 'mali|gpu|ged|gpueb|gpufreq|met_|ghpm|smmu' | head -40 | while read -r _l; do say "$_l"; done
    fi
done
[ "$_scanned" = 0 ] && say "SCAN: no root scanned"

# =============================================================================
sec "6. 自检（不是结论，只是完整性）"
say "CANDIDATES:     $(printf '%s\n' $NAMES | grep -c '')"
say "LOADED:         $LOADED"
say "FILE_FOUND:     $FOUND"
say "HASHED:         $HASHED"
say "NOT_READABLE:   $NOTREAD"
say "NOT_FOUND:      $NOTFOUND"
say ""
say "EVIDENCE_ONLY:  本文件只登记观测值，**不含任何兼容性判定**。"
say "                判定规则见仓库 05_userspace_firmware/08_kernel_provenance_audit.md §3.6。"
say "NO_BINARY:      未复制、未压缩、未导出、未上传任何 .ko；本文件是唯一产物。"
say ""
say "END: $TS_H"
if [ -n "$OUT" ]; then
    say ""
    say "OUTPUT_WRITTEN: $OUT"
fi

exit 0
