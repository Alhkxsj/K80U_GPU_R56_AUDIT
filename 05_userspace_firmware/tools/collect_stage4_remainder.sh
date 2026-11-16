#!/system/bin/sh
# =============================================================================
# collect_stage4_remainder.sh — v1.1  Stage 4 剩余缺口的最小化只读采集（合并版）
#
# v1.1 修复（2026-11-16）：
#   v1.0 的 say() 会写文件，但 43 处原始命令管道只写 stdout，
#   导致回传的 .txt 只有标题、没有数据。v1.1 把**所有输出**收进单一通道：
#   整个主体在子 shell 里跑，stdout 统一经 tee 落盘，文件内容 ≡ 终端内容。
#
# 覆盖：
#   A 环境与指纹
#   B CSF 固件 header / entry_end_offset / 尾部                      → U4-11 / U4-13
#   C mount / overlay / KSU 痕迹                                     → U4-27
#   D 内核 build-id / 模块 build-id                                   → U4-26
#   E GPU 产品识别                                                    → U4-12 / U4-04
#   F 模块 __versions（ged 抽样 + kbase 全量，落独立文件）            → U4-24b
#   G OEM kbase 是否编入 MTK 私有扩展                                 → U4-14
#   H dmesg 线索                                                      → U4-02 / U4-11 / U4-25b
#   I mali debugfs 枚举                                               → U4-02 / U4-15
#   J Vulkan 薄壳 / gpud / ged 的 ELF 元数据                          → U4-17 / U4-23
#   K 属性面、EGL 路径、后端线索、/dev/mali0 holders                   → U4-06 / U4-20 / U4-21
#
# 严格约束（红线）：
#   * 只读。不复制、不导出、不压缩、不上传任何 .so / .ko / .bin 本体。
#   * 不装载/卸载/替换模块或固件；不写任何分区；不重启；不做故障注入。
#   * 任一工具或路径缺失 → 打印 NOT_AVAILABLE / NOT_FOUND 并继续，不中断。
#   * 所有输出有界（head/tail/grep -m），dmesg 只取片段，不整份落盘。
#
# 用法：
#   sh collect_stage4_remainder.sh
#   OUTDIR=/data/local/tmp/GPU_AUDIT_STAGE4 sh collect_stage4_remainder.sh
# =============================================================================

set -u

OUTDIR="${OUTDIR:-/sdcard/GPU_AUDIT_STAGE4}"
if ! mkdir -p "$OUTDIR" 2>/dev/null; then
    OUTDIR="/data/local/tmp/GPU_AUDIT_STAGE4"
    mkdir -p "$OUTDIR" 2>/dev/null || OUTDIR=""
fi
if [ -z "$OUTDIR" ]; then
    echo "FATAL: no writable output directory" >&2
    exit 1
fi

TS_TAG="$(date '+%Y%m%d_%H%M%S' 2>/dev/null || echo run)"
MAIN="$OUTDIR/stage4_remainder_${TS_TAG}.txt"
: > "$MAIN" 2>/dev/null || { echo "FATAL: cannot write $MAIN" >&2; exit 1; }

# ---------------------------------------------------------------- 基础工具 ----
have() { command -v "$1" >/dev/null 2>&1; }

say() { printf '%s\n' "$*"; }

sec() {
    say ""
    say "=================================================================="
    say "## $*"
    say "=================================================================="
}

# need <cmd> <what>  -> 打印一次 NOT_AVAILABLE 并返回 1
need() {
    if ! have "$1"; then
        say "NOT_AVAILABLE: tool '$1' not found ($2)"
        return 1
    fi
    return 0
}

# sub <标题> —— 小标题
sub() { say ""; say "[$*]"; }

# rd <path> —— 读文本文件
rd() {
    if [ -r "$1" ]; then
        cat "$1" 2>/dev/null
    elif [ -e "$1" ]; then
        say "NOT_READABLE: $1"
    else
        say "NOT_FOUND: $1"
    fi
}

# fsize <path> -> 字节数或 NOT_AVAILABLE
fsize() {
    stat -c %s "$1" 2>/dev/null || echo NOT_AVAILABLE
}

# =============================================================================
# 主体：所有输出走 stdout，外层统一 tee 进文件
# =============================================================================
main() {

sec "A. 环境与指纹"
say "COLLECT_TIME   : $(date '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || echo NOT_AVAILABLE)"
say "SCRIPT_VERSION : stage4-remainder v1.1"
say "OUTPUT_DIR     : $OUTDIR"
say "UID            : $(id -u 2>/dev/null || echo NOT_AVAILABLE)"
say "SELINUX_CTX    : $(id -Z 2>/dev/null || echo NOT_AVAILABLE)"
say "MODEL          : $(getprop ro.product.model 2>/dev/null || echo NOT_AVAILABLE)"
say "DEVICE         : $(getprop ro.product.device 2>/dev/null || echo NOT_AVAILABLE)"
say "FINGERPRINT    : $(getprop ro.build.fingerprint 2>/dev/null || echo NOT_AVAILABLE)"
say "SDK            : $(getprop ro.build.version.sdk 2>/dev/null || echo NOT_AVAILABLE)"
say "KERNEL_UNAME_R : $(uname -r 2>/dev/null || echo NOT_AVAILABLE)"
say "KERNEL_UNAME_V : $(uname -v 2>/dev/null || echo NOT_AVAILABLE)"
say "KERNEL_UNAME_A : $(uname -a 2>/dev/null || echo NOT_AVAILABLE)"

sub "工具可用性"
for t in od xxd strings readelf sha256sum stat ls grep awk sed dmesg mount getprop dumpsys tee; do
    if have "$t"; then say "TOOL $t: OK"; else say "TOOL $t: NOT_AVAILABLE"; fi
done

sub "自检：写文件能力"
PROBE="$OUTDIR/.write_probe_$$"
if ( printf 'x\n' > "$PROBE" ) 2>/dev/null; then
    say "WRITE_TEST: OK ($OUTDIR)"
    rm -f "$PROBE" 2>/dev/null
else
    say "WRITE_TEST: FAILED"
fi

# =============================================================== B 固件 ======
sec "B. CSF 固件：header / entry_end_offset / 尾部（只读）"
FW="${FW:-/vendor/firmware/mali_csffw.bin}"
if [ -r "$FW" ]; then
    say "PATH: $FW"
    say "SIZE: $(fsize "$FW") bytes"

    sub "B-1 header 前 24 字节（hex）"
    say "  offset 0x00 magic | 0x04 version_minor | 0x05 version_major"
    say "  offset 0x08 version_hash (u32) | 0x10 entry_end_offset (u32)"
    if need od "firmware header"; then
        od -An -tx1 -N 24 "$FW" 2>/dev/null | sed 's/^ */  /'
        say "  --- 单字节读数 ---"
        say "  byte[0x04] = $(od -An -tu1 -j 4 -N 1 "$FW" 2>/dev/null | tr -d ' ')   <-- version_minor"
        say "  byte[0x05] = $(od -An -tu1 -j 5 -N 1 "$FW" 2>/dev/null | tr -d ' ')   <-- version_major"
        say "  u32[0x08]  = $(od -An -tu4 -j 8 -N 4 "$FW" 2>/dev/null | tr -d ' ')   (version_hash, 仅锚点)"
        say "  u32[0x10]  = $(od -An -tu4 -j 16 -N 4 "$FW" 2>/dev/null | tr -d ' ')   <-- entry_end_offset"
    fi

    FSZ="$(fsize "$FW")"
    case "$FSZ" in
        ''|*[!0-9]*) say "TAIL_SKIP: size unknown" ;;
        *)
            if [ "$FSZ" -gt 64 ]; then
                OFF=$((FSZ - 32))
                sub "B-2 最后 32 字节（offset $OFF .. $((FSZ-1)))"
                if need od "firmware tail"; then
                    od -An -tx1 -j "$OFF" -N 32 "$FW" 2>/dev/null | sed 's/^ */  /'
                fi

                sub "B-3 尾部 4096 字节内的可打印串（≤40 条）"
                if need strings "firmware strings"; then
                    tail -c 4096 "$FW" 2>/dev/null | strings -n 4 2>/dev/null | tail -40
                fi
            else
                say "TAIL_SKIP: file too small ($FSZ)"
            fi
            ;;
    esac
else
    say "NOT_READABLE: $FW"
    say "  备选路径探测："
    for p in /vendor/firmware/mali_csffw.bin /vendor/firmware/mali/mali_csffw.bin \
             /odm/firmware/mali_csffw.bin /vendor/etc/firmware/mali_csffw.bin; do
        if [ -e "$p" ]; then say "  EXISTS: $p ($(fsize "$p") bytes)"; else say "  ABSENT: $p"; fi
    done
fi

# =============================================================== C mount =====
sec "C. mount / overlay / KSU 痕迹（只读）"
sub "C-1 mountinfo 中 vendor / overlay / erofs 相关行（≤50 行）"
if [ -r /proc/self/mountinfo ]; then
    grep -Ei 'vendor|overlay|erofs|/system_ext|/product' /proc/self/mountinfo 2>/dev/null | head -50
else
    say "NOT_READABLE: /proc/self/mountinfo"
fi

sub "C-2 计数"
say "  vendor_lines  : $(grep -c 'vendor' /proc/self/mountinfo 2>/dev/null || echo 0)"
say "  overlay_lines : $(grep -c 'overlay' /proc/self/mountinfo 2>/dev/null || echo 0)"
say "  erofs_lines   : $(grep -c 'erofs' /proc/self/mountinfo 2>/dev/null || echo 0)"

sub "C-3 mount | grep overlay / vendor（≤30 行）"
if need mount "mount table"; then
    mount 2>/dev/null | grep -Ei 'overlay|vendor' | head -30
fi

sub "C-4 overlay 上层目录（是否存在，不读内容）"
for d in /data/adb/modules /data/adb/ksu /data/adb/susfs /sbin/.magisk /debug_ramdisk; do
    if [ -d "$d" ]; then say "  EXISTS: $d"; else say "  ABSENT: $d"; fi
done
say "  说明：目录存在 ≠ /vendor 正在被覆盖；判定以 C-1 的 mount 行为准。"

# =============================================================== D build-id ==
sec "D. 内核 build-id 与版本（U4-26）"
sub "D-1 /sys/kernel/notes 原始字节（前 96 字节）"
if [ -r /sys/kernel/notes ]; then
    say "  SIZE: $(fsize /sys/kernel/notes) bytes"
    if need od "kernel notes"; then
        od -An -tx1 -N 96 /sys/kernel/notes 2>/dev/null | sed 's/^ */  /'
    fi
    sub "D-2 readelf -n /sys/kernel/notes（可能因非 ELF 头而失败，属正常）"
    if need readelf "kernel notes"; then
        readelf -n /sys/kernel/notes 2>&1 | head -20 | sed 's/^/  /'
    fi
else
    say "NOT_READABLE: /sys/kernel/notes"
fi

sub "D-3 /proc/version"
rd /proc/version

sub "D-4 kbase 模块自身 version / srcversion / build-id"
MODKB="/sys/module/mali_kbase_mt6991_r49"
if [ -d "$MODKB" ]; then
    say "  version     : $(cat "$MODKB/version" 2>/dev/null || echo NOT_AVAILABLE)"
    say "  srcversion  : $(cat "$MODKB/srcversion" 2>/dev/null || echo NOT_AVAILABLE)"
    say "  vermagic    : $(cat "$MODKB/vermagic" 2>/dev/null || echo NOT_AVAILABLE)"
    HOLD="$(ls -1 "$MODKB/holders" 2>/dev/null | tr '\n' ' ')"
    say "  holders     : ${HOLD:-NONE}"
    if [ -r "$MODKB/notes/.note.gnu.build-id" ]; then
        say "  build-id    : $(od -An -tx1 -j 12 -N 20 "$MODKB/notes/.note.gnu.build-id" 2>/dev/null | tr -d ' \n')"
    else
        say "  build-id    : section file absent"
    fi
else
    say "NOT_FOUND: $MODKB"
fi

# =============================================================== E gpuinfo ===
sec "E. GPU 产品识别（U4-12 / U4-04）"
for p in /sys/class/misc/mali0/device/gpuinfo /sys/devices/platform/soc/48000000.mali/gpuinfo; do
    if [ -r "$p" ]; then
        say "PATH : $p"
        say "VALUE: $(cat "$p" 2>/dev/null)"
    else
        say "NOT_FOUND: $p"
    fi
done
sub "E-2 兜底：其它 gpuinfo"
find /sys -maxdepth 6 -name gpuinfo -type f 2>/dev/null | head -5 | while read -r q; do
    say "  $q -> $(cat "$q" 2>/dev/null)"
done
say "  读法：期望 \"Mali-G925-Immortalis 12 cores r0pX 0x........\"。"
say "        若为 G725 或核数≠12，说明 MC12 识别不符，需重核。"

sub "E-3 GPU 链路模块的 taint 列（排除强制装载 F）"
if [ -r /proc/modules ]; then
    grep -Ei '^(ged|mali|gpufreq|mtk_)?.*(mali|ged|gpueb|gpufreq)' /proc/modules 2>/dev/null | head -20 | \
        awk '{printf "  %-34s size=%-9s refs=%-3s state=%-8s taint=%s\n", $1,$2,$3,$5,$6}'
    say "  --- 含 taint 标记的行 ---"
    grep -E ' (Live|Loading) ' /proc/modules 2>/dev/null | awk '$6!="-" {printf "  %-34s taint=%s\n",$1,$6}' | head -20
else
    say "NOT_READABLE: /proc/modules"
fi

# =============================================================== F versions ==
sec "F. 模块 __versions 节（U4-24b；落独立文件，只读）"
if need readelf "section dump"; then
    MODDIR="${MODDIR:-/vendor_dlkm/lib/modules}"
    if [ ! -d "$MODDIR" ]; then
        for cand in /vendor/lib/modules /vendor_dlkm/lib/modules /system/lib/modules /odm/lib/modules; do
            if [ -d "$cand" ]; then MODDIR="$cand"; break; fi
        done
    fi
    say "MODDIR: $MODDIR"
    say "  目的：取设备构建的 __ksymtab 期望 CRC。ged 作 14 个结构一致模块的抽样；kbase 单独取。"

    for ko in ged.ko mali_kbase_mt6991_r49.ko mali_kbase.ko; do
        kp="$MODDIR/$ko"
        [ -e "$kp" ] || continue
        base="$(basename "$ko" .ko)"
        outf="$OUTDIR/F_${base}_versions.txt"
        say ""
        say "  [F] $kp"
        say "      size   : $(fsize "$kp")"
        if need sha256sum "hash"; then
            say "      sha256 : $(sha256sum "$kp" 2>/dev/null | awk '{print $1}')"
        fi
        readelf -x __versions "$kp" > "$outf" 2>/dev/null
        if [ -s "$outf" ]; then
            say "      __versions -> $(basename "$outf")  ($(fsize "$outf") bytes)"
            say "      dump sha256: $(sha256sum "$outf" 2>/dev/null | awk '{print $1}')"
            say "      前 12 行预览："
            head -12 "$outf" 2>/dev/null | sed 's/^/        /'
            say "      条目数（每行 16 字节 → 记录数估算）："
            say "        $(grep -c '^  0x' "$outf" 2>/dev/null || echo NOT_AVAILABLE) 行"
        else
            say "      __versions: DUMP_FAILED（节可能不存在或被裁剪）"
            rm -f "$outf" 2>/dev/null
        fi
    done
else
    say "SKIP: readelf 不可用，F 段无法进行"
fi

# =============================================================== G MTK 扩展 ==
sec "G. OEM kbase 是否编入 MTK 私有扩展（U4-14）"
say "  原理：CONFIG_MALI_MTK_FENCE_DEBUG 内的字符串只在该宏开启时编入 .rodata。"
say "        串在 => ioctl 80（INTERNAL_FENCE_WAIT）在设备构建上可达。"
GKO="${GKO:-/vendor_dlkm/lib/modules/mali_kbase_mt6991_r49.ko}"
if [ -r "$GKO" ] && need strings "kbase strings"; then
    cnt() { strings "$GKO" 2>/dev/null | grep -c -F "$1" 2>/dev/null || echo 0; }
    sub "G-1 'Internal fence wait'（>0 => MALI_MTK_FENCE_DEBUG 开）"
    say "  COUNT: $(cnt 'Internal fence wait')"
    sub "G-2 'Internal fence timeouts'（>0 => 超时/跨队列恢复路径在）"
    say "  COUNT: $(cnt 'Internal fence timeouts')"
    sub "G-3 'ged_mali_event_notify_fence_timeout_event'（>0 => MBRAIN 通道在）"
    say "  COUNT: $(cnt 'ged_mali_event_notify_fence_timeout_event')"
    sub "G-4 有限核数相关串（ioctl 55 的日志面，≤15 条）"
    strings "$GKO" 2>/dev/null | grep -iE 'limited.?core|core.?count|core_mask' | head -15 | sed 's/^/  /'
    sub "G-5 队列组 create 的 reserved 校验日志（R49 内联 padding 校验旁证）"
    strings "$GKO" 2>/dev/null | grep -iE 'reserved field not 0|padding' | head -10 | sed 's/^/  /'
    sub "G-6 CS_QUEUE_REGISTER / tiler heap 相关串"
    strings "$GKO" 2>/dev/null | grep -iE 'cs_queue_register|tiler_heap|queue_register' | head -10 | sed 's/^/  /'
else
    say "NOT_READABLE: $GKO"
fi

# =============================================================== H dmesg =====
sec "H. dmesg 线索（U4-02 / U4-11 / U4-25b）"
DN="$(dmesg 2>/dev/null | wc -l | tr -d ' ')"
case "${DN:-0}" in
    ''|*[!0-9]*) DN=0 ;;
esac
if [ "$DN" -gt 0 ]; then
    say "  dmesg lines: $DN（以下均为有界摘录，不整份落盘）"

    sub "H-1 mali / csf / firmware 相关（末尾 60 行）"
    dmesg 2>/dev/null | grep -Ei 'mali|csf|firmware|gpu' | tail -60 | sed 's/^/  /'

    sub "H-2 'Loading Mali firmware'（version_hash 锚点）"
    dmesg 2>/dev/null | grep -i 'Loading Mali firmware' | tail -5 | sed 's/^/  /'

    sub "H-3 'Version check failed' / 'firmware may have failed'"
    dmesg 2>/dev/null | grep -Ei 'Version check failed|firmware may have failed' | tail -5 | sed 's/^/  /'

    sub "H-4 'disagrees about version of symbol'（U4-25b 运行态判据）"
    say "  COUNT: $(dmesg 2>/dev/null | grep -c 'disagrees about version of symbol' 2>/dev/null || echo 0)"

    sub "H-5 'git_sha' / GLB 线索"
    dmesg 2>/dev/null | grep -Ei 'git_sha|GLB|glb_' | tail -10 | sed 's/^/  /'
else
    say "NOT_AVAILABLE: dmesg 无输出（可能被 restrict 或需 root）"
fi

# =============================================================== I debugfs ===
sec "I. mali debugfs 枚举（U4-02 / U4-15）"
FOUND=0
for d in /sys/kernel/debug/mali0 /sys/kernel/debug/mali /d/mali0; do
    if [ -d "$d" ]; then
        FOUND=1
        say "FOUND: $d"
        ls -1 "$d" 2>/dev/null | head -40 | sed 's/^/  /'
    fi
done
if [ "$FOUND" -eq 0 ]; then
    say "NOT_AVAILABLE: 未找到 mali debugfs 目录（debugfs 可能未挂载）"
    sub "I-2 /sys/kernel/debug 顶层（≤20 项）"
    ls -1 /sys/kernel/debug 2>/dev/null | head -20 | sed 's/^/  /'
    sub "I-3 全局搜 mali 相关 debug 目录"
    find /sys/kernel/debug -maxdepth 2 -iname '*mali*' 2>/dev/null | head -10 | sed 's/^/  /'
fi

# =============================================================== J ELF =======
sec "J. Vulkan 薄壳 / gpud / ged 的 ELF 元数据（U4-17 / U4-23）"
say "  只读 ELF 头 / 动态段 / 动态符号；不复制文件本体。"
if need readelf "ELF metadata"; then
    for so in /vendor/lib64/hw/mt6991/vulkan.mali.so \
              /vendor/lib64/hw/vulkan.mali.so \
              /vendor/lib64/libgpud.so \
              /system_ext/lib64/libgpud_sys.so \
              /vendor/lib64/libged.so; do
        [ -e "$so" ] || continue
        say ""
        say "  [J] $so"
        say "      size  : $(fsize "$so")"
        if need sha256sum "hash"; then
            say "      sha256: $(sha256sum "$so" 2>/dev/null | awk '{print $1}')"
        fi
        say "      -- DT_NEEDED --"
        readelf -d "$so" 2>/dev/null | awk '/NEEDED/{print "        "$0}' | head -20
        say "      -- SONAME / RUNPATH --"
        readelf -d "$so" 2>/dev/null | grep -E 'SONAME|RPATH|RUNPATH' | head -10 | sed 's/^ */        /'
        say "      -- dynsym 统计 --"
        DS="$(readelf --dyn-syms -W "$so" 2>/dev/null || readelf -sW "$so" 2>/dev/null)"
        say "        total dynsym lines : $(printf '%s\n' "$DS" | grep -c '^ *[0-9]' 2>/dev/null || echo 0)"
        say "        GLOBAL DEFAULT FUNC: $(printf '%s\n' "$DS" | grep -c 'GLOBAL.*DEFAULT.*FUNC' 2>/dev/null || echo 0)"
        say "        GLOBAL DEFAULT OBJ : $(printf '%s\n' "$DS" | grep -c 'GLOBAL.*DEFAULT.*OBJECT' 2>/dev/null || echo 0)"
        say "      -- 导出符号样本（GLOBAL DEFAULT，≤20）--"
        printf '%s\n' "$DS" | grep 'GLOBAL.*DEFAULT' | head -20 | sed 's/^ */        /'
    done
else
    say "SKIP: readelf 不可用"
fi

# =============================================================== K 属性面 ====
sec "K. 属性面 / EGL 路径 / 后端线索 / /dev/mali0 holders（U4-06 / U4-20 / U4-21）"
sub "K-1 图形相关属性"
for k in ro.hardware.egl ro.hardware.vulkan ro.opengles.version \
         ro.hardware.gralloc ro.hardware.graphics composer.hardware \
         ro.surface_flinger.max_frame_buffer_acquired_buffers \
         debug.hwui.renderer debug.sf.hw ro.gfx.angle.supported \
         persist.sys.sf.native_mode ro.vendor.gpu.egl.lib; do
    v="$(getprop "$k" 2>/dev/null)"
    say "  $k = ${v:-NOT_FOUND}"
done
sub "K-1b 全量 gpu / egl / vulkan / gralloc 属性（≤40 条）"
getprop 2>/dev/null | grep -Ei 'gpu|egl|vulkan|gralloc|mali' | head -40 | sed 's/^/  /'

sub "K-2 linker 配置中的 EGL / Vulkan 搜索路径（U4-06）"
for f in /system/etc/ld.config.txt /vendor/etc/ld.config.txt \
         /system/etc/ld.config.37.txt /linkerconfig/ld.config.txt; do
    if [ -r "$f" ]; then
        say "  FILE: $f"
        grep -nEi 'egl|vulkan|mali|gpud|ged' "$f" 2>/dev/null | head -20 | sed 's/^/    /'
    else
        say "  NOT_FOUND: $f"
    fi
done

sub "K-3 SurfaceFlinger 后端线索（U4-20；有界）"
if need dumpsys "dumpsys"; then
    dumpsys SurfaceFlinger 2>/dev/null | grep -Ei 'GLES|skiagl|vulkan|RenderEngine|GPU' | head -20 | sed 's/^/  /'
fi

sub "K-4 打开 /dev/mali0 的进程（U4-21）"
if [ -r /dev/mali0 ]; then
    say "  /dev/mali0 exists: yes"
    if [ -d /proc ]; then
        HITS=0
        for pid in /proc/[0-9]*; do
            if ls -l "$pid/fd" 2>/dev/null | grep -q 'mali0'; then
                nm="$(cat "$pid/cmdline" 2>/dev/null | tr '\0' ' ' | cut -c1-48)"
                [ -z "$nm" ] && nm="(kernel thread)"
                say "    PID $(basename "$pid") : $nm"
                HITS=$((HITS+1))
                [ "$HITS" -ge 40 ] && { say "    ... (≥40，已截断)"; break; }
            fi
        done
        say "  TOTAL_HOLDERS: $HITS"
    fi
else
    say "  /dev/mali0 : ABSENT"
fi

sub "K-5 /dev/mali0 节点属性"
ls -lZ /dev/mali0 2>/dev/null | sed 's/^/  /' || say "  NOT_AVAILABLE"

}

# =============================================================================
# 输出通道：stdout 同时上屏 + 落盘。有 tee 用 tee，没有就内置实现。
# =============================================================================
tee_a() {
    while IFS= read -r line || [ -n "$line" ]; do
        printf '%s\n' "$line"
        printf '%s\n' "$line" >> "$MAIN"
    done
}

if have tee; then
    main 2>&1 | tee -a "$MAIN"
else
    main 2>&1 | tee_a
fi

# ---------------------------------------------------------------- 收尾 ------
{
    say ""
    say "=================================================================="
    say "## Z. 结束"
    say "=================================================================="
    say "OUTPUT_FILE: $MAIN"
    say "OUTPUT_SIZE: $(fsize "$MAIN") bytes"
    say "EXTRA_FILES:"
    ls -1 "$OUTDIR" 2>/dev/null | grep -v "^$(basename "$MAIN")$" | sed 's/^/  /'
    say ""
    DL="$(grep -v -e '^=' -e '^## ' -e '^$' "$MAIN" 2>/dev/null | wc -l | tr -d ' ')"
    say "SELFCHECK: 数据行数（不含标题与空行）＝ ${DL:-0}"
    say "           若该值 < 60，说明多数命令未产出，请把本文件原样回传以便定位。"
    say ""
    say "NO_BINARY 声明：本脚本未复制、未压缩、未导出、未上传任何 .so / .ko / .bin。"
    say "未装载 / 未卸载 / 未替换任何模块或固件；未修改任何系统分区。"
    say ""
    say "结果不代表任何项目已闭合；判读请对照"
    say "  06_porting_design/STAGE4_DEVICE_COLLECTION_PLAN.md"
} | tee_a
