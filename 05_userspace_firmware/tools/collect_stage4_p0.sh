#!/system/bin/sh
# =============================================================================
# collect_stage4_p0.sh — Stage 4 两个 P0 缺口的最小化只读采集
#
# 目的：
#   [U4-01] 读 /vendor/firmware/mali_csffw.bin 的前 8 字节（只读，不复制）
#   [U4-04] 从 /vendor/lib64/egl/mt6991/libGLES_mali.so 提取可打印版本串
#
# 严格约束：
#   * 只读。不复制、不 pull、不生成二进制副本、不修改任何设备文件。
#   * 不依赖 adb、不依赖 Termux、不要求安装任何额外工具。
#   * 无写权限时不伪造结果，明确输出失败原因。
#   * 版本串未找到时输出 NOT_FOUND，绝不输出 INCOMPATIBLE。
#
# 字段判据来自源码（不是预期值）：
#   r49p1 csf/mali_kbase_csf_firmware.c:107-109, 2770-2774
#   r56p0 csf/mali_kbase_csf_firmware.c:84-86,  2695-2699
#     #define FIRMWARE_HEADER_MAGIC       (0xC3F13A6Eul)
#     #define FIRMWARE_HEADER_VERSION_MAJOR (0ul)
#     #define FIRMWARE_HEADER_VERSION_MINOR (3ul)  /* r56p0 为 4ul */
#     memcmp(mcu_fw->data, &magic, sizeof(magic)) != 0  -> "Incorrect firmware magic"
#     version_minor = mcu_fw->data[4];
#     version_major = mcu_fw->data[5];
#   => 小端 ARM64 上 magic 的内存字节为 6e 3a f1 c3
#      offset 0-3 = magic, offset 4 = minor(u8), offset 5 = major(u8)
#      offset 6-7 = 源码未读取（保留）
#      offset 8-11 = version_hash(u32), offset 0x10 = entry_end_offset(u32)
#      头长 FIRMWARE_HEADER_LENGTH = 0x14 = 20 字节
#
# 用法（手机 aShell You / 任意 root shell）：
#   su -c 'sh /sdcard/Download/collect_stage4_p0.sh'
#
# 退出码：0 = 脚本正常执行完（不代表证据已闭合）；1 = 环境不可用
# =============================================================================

set -u

FW="${FW:-/vendor/firmware/mali_csffw.bin}"
DDK="${DDK:-/vendor/lib64/egl/mt6991/libGLES_mali.so}"

# 输出目录：优先 /data/local/tmp（root 下最可靠），退回 /sdcard/Download
OUTDIR="${OUTDIR:-/data/local/tmp/gpu_audit_p0}"
if ! mkdir -p "$OUTDIR" 2>/dev/null; then
    OUTDIR="/sdcard/Download/gpu_audit_p0"
    mkdir -p "$OUTDIR" 2>/dev/null || OUTDIR=""
fi

TS="$(date '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || date)"
OUT=""
if [ -n "$OUTDIR" ]; then
    OUT="$OUTDIR/stage4_p0_$(date '+%Y%m%d_%H%M%S' 2>/dev/null || echo run).txt"
    : > "$OUT" 2>/dev/null || OUT=""
fi

say() {
    printf '%s\n' "$*"
    if [ -n "$OUT" ]; then printf '%s\n' "$*" >> "$OUT" 2>/dev/null; fi
}

sec() {
    say ""
    say "--- $* ---"
}

have() { command -v "$1" >/dev/null 2>&1; }

# 把多行匹配压成一行，避免输出块被撑乱
oneline() { printf '%s' "${1:-}" | tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//'; }

# 从偏移 _skip 读取 _n 字节，输出为 "xx xx ..."；失败返回空
read_hex_at() {
    _f="$1"; _skip="$2"; _n="$3"; _raw=""
    if have od; then
        _raw="$(od -An -tx1 -j "$_skip" -N "$_n" "$_f" 2>/dev/null)" || _raw=""
        if [ -z "$_raw" ]; then
            _raw="$(od -A n -t x1 -j "$_skip" -N "$_n" "$_f" 2>/dev/null)" || _raw=""
        fi
    fi
    if [ -z "$_raw" ] && have xxd; then
        _raw="$(xxd -s "$_skip" -l "$_n" "$_f" 2>/dev/null)" || _raw=""
        # xxd 输出形如 "00000000: 6e3a f1c3 0300 0000"
        _raw="$(printf '%s\n' "$_raw" | sed 's/^[0-9a-fA-F]*: *//' | tr -d ' ' | sed 's/../& /g')"
    fi
    if [ -z "$_raw" ] && have hexdump; then
        _raw="$(hexdump -C -s "$_skip" -n "$_n" "$_f" 2>/dev/null)" || _raw=""
        # 取偏移后的十六进制列，丢弃 ASCII 列
        _raw="$(printf '%s\n' "$_raw" | sed 's/^[0-9a-fA-F]* *//' | cut -d'|' -f1)"
    fi
    printf '%s' "$_raw" | tr -s ' \t\n' ' ' | sed 's/^ *//; s/ *$//'
}

# 从文件头读取 _n 字节
read_hex() { read_hex_at "$1" 0 "$2"; }

file_size() {
    _f="$1"
    if have stat; then
        stat -c %s "$_f" 2>/dev/null && return 0
    fi
    wc -c < "$_f" 2>/dev/null | tr -d ' '
}

# -----------------------------------------------------------------------------
say "=============================================================="
say " Stage 4 P0 minimal read-only collector"
say "=============================================================="
say "COLLECTED_AT: $TS"
say "SCRIPT_VER:   1.0"
say "MODE:         READ-ONLY (no copy, no pull, no write to device files)"
say "OUTPUT_FILE:  ${OUT:-<stdout only>}"

sec "0. Environment (context marker)"
MODEL="$(getprop ro.product.model 2>/dev/null)"
DEVICE="$(getprop ro.product.device 2>/dev/null)"
REL="$(getprop ro.build.version.release 2>/dev/null)"
SDK="$(getprop ro.build.version.sdk 2>/dev/null)"
say "DEVICE_MODEL:  ${MODEL:-UNKNOWN}"
say "DEVICE_CODE:   ${DEVICE:-UNKNOWN}"
say "ANDROID:       ${REL:-UNKNOWN} (SDK ${SDK:-UNKNOWN})"
say "KERNEL:        $(uname -r 2>/dev/null || echo UNKNOWN)"
say "KERNEL_NOTE:   third-party GKI build, NOT stock boot (see docs/PROJECT_STATE.md)"
CTX="$(id -Z 2>/dev/null)"
if [ -n "${CTX:-}" ]; then say "SELINUX_CTX:   $CTX"; else say "SELINUX_CTX:   UNAVAILABLE"; fi
if [ "$(id -u 2>/dev/null)" = "0" ]; then say "UID:           0 (root)"; else say "UID:           $(id -u 2>/dev/null) (not root)"; fi

sec "1. Tool availability"
for t in od hexdump xxd strings grep stat sha256sum readelf; do
    if have "$t"; then say "  $t: YES"; else say "  $t: NO"; fi
done

# =============================================================================
sec "[U4-01] CSF firmware header (first 8 bytes)"
say "PATH: $FW"

if [ ! -e "$FW" ]; then
    say "STATUS: FILE_NOT_FOUND"
    say "REASON: path does not exist"
    say "FIRMWARE_HEADER: UNKNOWN"
else
    if [ ! -r "$FW" ]; then
        say "STATUS: FILE_NOT_READABLE"
        say "REASON: permission denied for uid $(id -u 2>/dev/null); try root shell"
        say "FIRMWARE_HEADER: UNKNOWN"
    else
        SZ="$(file_size "$FW")"
        say "SIZE:   ${SZ:-UNKNOWN} bytes"
        if have stat; then
            PERM="$(stat -c '%a %U:%G' "$FW" 2>/dev/null)"
            say "PERM:   ${PERM:-UNKNOWN}"
        fi

        HEX="$(read_hex "$FW" 8)"
        if [ -z "$HEX" ]; then
            say "STATUS: READ_FAILED"
            say "REASON: no usable tool (od/xxd/hexdump all failed or absent)"
            say "FIRMWARE_HEADER: UNKNOWN"
        else
            say "HEADER_HEX: $HEX"
            set -- $HEX
            if [ $# -lt 6 ]; then
                say "STATUS: PARTIAL_READ (got $# bytes, need >=6)"
                say "FIRMWARE_HEADER: UNKNOWN"
            else
                B0="$1"; B1="$2"; B2="$3"; B3="$4"; MINOR="$5"; MAJOR="$6"
                MAGIC_OK=0
                if [ "$B0$B1$B2$B3" = "6e3af1c3" ]; then
                    MAGIC_OK=1
                    say "MAGIC:      OK (0xC3F13A6E little-endian)"
                else
                    say "MAGIC:      MISMATCH (got $B0 $B1 $B2 $B3, expect 6e 3a f1 c3)"
                    say "NOTE:       file may not be a CSF firmware image, or is encrypted/packed"
                fi
                say "OFFSET4_MINOR: 0x$MINOR"
                say "OFFSET5_MAJOR: 0x$MAJOR"
                # 源码常量（不是实测）：r49p1=0.3 / r56p0=0.4
                if [ "$MAGIC_OK" != "1" ]; then
                    say "FIRMWARE_HEADER: 0x${MAJOR}.0x${MINOR} (UNRELIABLE: magic mismatch)"
                    say "SOURCE_CHECK:   not applicable; file does not look like a CSF firmware image"
                elif [ "$MAJOR" = "00" ] && [ "$MINOR" = "03" ]; then
                    say "FIRMWARE_HEADER: 0.3"
                    say "SOURCE_CHECK:   matches r49p1 requirement (0.3); r56p0 requires 0.4"
                elif [ "$MAJOR" = "00" ] && [ "$MINOR" = "04" ]; then
                    say "FIRMWARE_HEADER: 0.4"
                    say "SOURCE_CHECK:   matches r56p0 requirement (0.4); contradicts r49p1 (0.3)"
                else
                    say "FIRMWARE_HEADER: 0x${MAJOR}.0x${MINOR} (neither 0.3 nor 0.4)"
                    say "SOURCE_CHECK:   r49p1=0.3 / r56p0=0.4 (source constants)"
                fi
            fi
        fi

        # 附加：offset 8-15（version_hash + entry_end_offset），仅用于交叉校验
        HEX2="$(read_hex_at "$FW" 8 8)"
        if [ -n "$HEX2" ]; then
            say "EXTRA_8_15:  $HEX2"
            say "EXTRA_NOTE:  offset 8-11=version_hash (dmesg 'Loading Mali firmware 0x..'), 12-15=unused, 0x10=entry_end_offset"
        fi
    fi
fi

# =============================================================================
sec "[U4-04] Userspace DDK version strings"
say "PATH: $DDK"

if [ ! -e "$DDK" ]; then
    say "STATUS: FILE_NOT_FOUND"
    say "DDK_UK_VERSION: NOT_FOUND"
else
    if [ ! -r "$DDK" ]; then
        say "STATUS: FILE_NOT_READABLE"
        say "REASON: permission denied; try root shell"
        say "DDK_UK_VERSION: NOT_FOUND"
    else
        SZ="$(file_size "$DDK")"
        say "SIZE:   ${SZ:-UNKNOWN} bytes"

        # 1) UK version 串
        V=""
        if have grep; then
            V="$(grep -a -o -m 3 -E 'UK version [0-9]+\.[0-9]+' "$DDK" 2>/dev/null)"
            if [ -z "$V" ] && have strings; then
                V="$(strings -a "$DDK" 2>/dev/null | grep -m 3 -E 'UK version [0-9]+\.[0-9]+')"
            fi
        elif have strings; then
            V="$(strings -a "$DDK" 2>/dev/null | grep -m 3 -E 'UK version [0-9]+\.[0-9]+')"
        fi
        if [ -n "${V:-}" ]; then
            say "DDK_UK_VERSION: $(oneline "$V")"
        else
            say "DDK_UK_VERSION: NOT_FOUND"
            say "  (NOT_FOUND means 'not observed by this method', NOT 'incompatible')"
        fi

        # 2) DDK 发布版本串（如 r49p1-03bet0）
        R=""
        if have grep; then
            R="$(grep -a -o -m 5 -E 'r[0-9]{2}p[0-9]-[0-9a-z]{3,}' "$DDK" 2>/dev/null)"
        fi
        if [ -n "${R:-}" ]; then
            say "DDK_RELEASE:    $(oneline "$R")"
        else
            say "DDK_RELEASE:    NOT_FOUND"
        fi

        # 3) GPU 型号串
        G=""
        if have grep; then
            G="$(grep -a -o -m 5 -E 'Mali-[A-Za-z0-9]+' "$DDK" 2>/dev/null)"
        fi
        if [ -n "${G:-}" ]; then
            say "DDK_GPU_MODEL:  $(oneline "$G")"
        else
            say "DDK_GPU_MODEL:  NOT_FOUND"
        fi

        # 4) ELF Build ID（仅当 readelf 可用；多数手机无此工具）
        if have readelf; then
            BID="$(readelf -n "$DDK" 2>/dev/null | grep -m 1 -i 'Build ID' | tr -s ' ' ' ')"
            if [ -n "$BID" ]; then say "DDK_BUILD_ID:   $BID"; else say "DDK_BUILD_ID:   NOT_FOUND"; fi
        else
            say "DDK_BUILD_ID:   NOT_AVAILABLE (no readelf on device; see 07_device_evidence.md for the value already captured)"
        fi

        say ""
        say "DDK_NOTE_1: UK version above is the string the DDK *contains*, not proof of runtime behaviour."
        say "DDK_NOTE_2: ioctl 使用情况 / padding 清零 / props 严格校验 仍需 strace 或反编译（U4-14/15/16）。"
        say "DDK_NOTE_3: /sys/module/mali_kbase_mt6991_r49/version is the KERNEL module version, not the DDK version."
    fi
fi

# =============================================================================
sec "2. Summary (copy this block back to the agent)"
say "U4_01_FIRMWARE_HEADER: see [U4-01] FIRMWARE_HEADER line above"
say "U4_04_DDK_UK_VERSION:  see [U4-04] DDK_UK_VERSION line above"
say ""
say "=== END ==="
if [ -n "$OUT" ]; then
    say "Saved to: $OUT"
    say "Read it with:  cat $OUT"
else
    say "Not saved to a file (no writable directory). Copy the text above."
fi

exit 0
