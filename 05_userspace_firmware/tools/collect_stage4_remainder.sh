#!/system/bin/sh
# =============================================================================
# collect_stage4_remainder.sh — Stage 4 剩余缺口的最小化只读采集（合并版）
#
# 目的：一次运行，覆盖 Stage 4 台账里仍然 OPEN / PARTIAL 的只读可查项目。
#
#   A 环境与指纹（所有结论的锚点）
#   B 固件：header offset 0x10（entry_end_offset）+ 尾部 32 字节        → U4-11 / U4-13
#   C mount / overlay / KSU 痕迹                                        → U4-27
#   D 内核 build-id + 版本                                              → U4-26
#   E GPU 产品识别（gpuinfo sysfs）                                     → U4-12 / U4-04
#   F 模块 __versions（ged 抽样 + kbase 全量）                          → U4-24b
#   G OEM kbase 的 MTK 扩展开关（ioctl 55 / 80 是否编进设备构建）       → U4-14
#   H dmesg 中的 GPU / 固件 / GLB 线索                                  → U4-02 / U4-11
#   I mali debugfs 枚举                                                 → U4-02 / U4-15
#   J Vulkan 薄壳与 gpud / ged 的 ELF 元数据                            → U4-17 / U4-23
#   K 属性面（EGL / Vulkan / gralloc / 后端选择线索）                   → U4-06 / U4-20
#
# 严格约束：
#   * 只读。不复制、不导出、不生成任何二进制副本；不修改任何设备文件。
#   * 不装载 / 不卸载 / 不替换任何模块；不触发 GPU 故障注入。
#   * 工具缺失时输出 NOT_AVAILABLE，**不中断脚本**。
#   * 不采 strace（见 README §6：单列、可选、且有明确局限）。
#   * 不重采已完成的三份 Stage 4 基线 + 两批补充采集。
#
# 用法（aShell You，已 root）：
#   su -c 'sh /sdcard/GPU_AUDIT_STAGE4/collect_stage4_remainder.sh'
#
# 退出码：0 = 脚本跑完（不代表证据已闭合）；1 = 输出目录不可用
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
say() {
    printf '%s\n' "$*"
    printf '%s\n' "$*" >> "$MAIN" 2>/dev/null
}

sec() {
    say ""
    say "=================================================================="
    say "## $*"
    say "=================================================================="
}

# have <cmd>  -> 0 if usable
have() { command -v "$1" >/dev/null 2>&1; }

# need <cmd> <what>  -> echoes NOT_AVAILABLE once and returns 1
need() {
    if ! have "$1"; then
        say "NOT_AVAILABLE: tool '$1' not found ($2)"
        return 1
    fi
    return 0
}

# rd <path>  -> cat a text file if readable, else NOT_AVAILABLE / NOT_FOUND
rd() {
    if [ -r "$1" ]; then
        cat "$1" 2>/dev/null
    elif [ -e "$1" ]; then
        echo "NOT_READABLE: $1"
    else
        echo "NOT_FOUND: $1"
    fi
}

DEVINFO="$(getprop ro.product.device 2>/dev/null || echo NOT_AVAILABLE)"

# =============================================================== A 环境 ======
sec "A. 环境与指纹"
say "COLLECT_TIME   : $(date '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || echo NOT_AVAILABLE)"
say "SCRIPT_VERSION : stage4-remainder v1.0"
say "OUTPUT_DIR     : $OUTDIR"
say "UID            : $(id -u 2>/dev/null || echo NOT_AVAILABLE)"
say "SELINUX_CTX    : $(id -Z 2>/dev/null || echo NOT_AVAILABLE)"
say "MODEL          : $(getprop ro.product.model 2>/dev/null || echo NOT_AVAILABLE)"
say "DEVICE         : $DEVINFO"
say "FINGERPRINT    : $(getprop ro.build.fingerprint 2>/dev/null || echo NOT_AVAILABLE)"
say "SDK            : $(getprop ro.build.version.sdk 2>/dev/null || echo NOT_AVAILABLE)"
say "KERNEL_UNAME_R : $(uname -r 2>/dev/null || echo NOT_AVAILABLE)"
say "KERNEL_UNAME_V : $(uname -v 2>/dev/null || echo NOT_AVAILABLE)"
say "KERNEL_UNAME_A : $(uname -a 2>/dev/null || echo NOT_AVAILABLE)"
say ""
say "-- tool availability --"
for t in od xxd strings readelf sha256sum stat ls grep awk sed dmesg mount getprop dumpsys; do
    if have "$t"; then say "TOOL $t: OK"; else say "TOOL $t: NOT_AVAILABLE"; fi
done
say ""
say "-- item coverage --"
say "A 环境........: covered"
say "B 固件头/尾...: U4-11, U4-13"
say "C mount.......: U4-27"
say "D build-id....: U4-26"
say "E gpuinfo.....: U4-12, U4-04"
say "F __versions..: U4-24b"
say "G MTK 扩展....: U4-14"
say "H dmesg.......: U4-02, U4-11"
say "I debugfs.....: U4-02, U4-15"
say "J ELF 元数据..: U4-17, U4-23"
say "K 属性面......: U4-06, U4-20"

# =============================================================== B 固件 ======
sec "B. CSF 固件：header 0x10 起 + 尾部 32 字节（只读）"
FW="${FW:-/vendor/firmware/mali_csffw.bin}"
if [ -r "$FW" ]; then
    say "PATH: $FW"
    say "SIZE: $(stat -c %s "$FW" 2>/dev/null || echo NOT_AVAILABLE) bytes"
    if need od "firmware header"; then
        say ""
        say "[B-1] header bytes 0x00-0x17 (24 bytes)"
        say "  offset 0x04 = version_minor, 0x05 = version_major"
        say "  offset 0x08 = version_hash (u32), 0x10 = entry_end_offset (u32)"
        od -An -tx1 -N 24 "$FW" 2>/dev/null | sed 's/^/  /'
        say ""
        say "[B-2] entry_end_offset (offset 0x10, 4 bytes LE)"
        od -An -tu4 -j 16 -N 4 "$FW" 2>/dev/null | sed 's/^/  DEC: /'
        od -An -tx1 -j 16 -N 4 "$FW" 2>/dev/null | sed 's/^/  HEX: /'
        FSZ="$(stat -c %s "$FW" 2>/dev/null || echo 0)"
        case "$FSZ" in
            ''|*[!0-9]*) say "TAIL_SKIP: size unknown" ;;
            *)
                if [ "$FSZ" -gt 32 ]; then
                    OFF=$((FSZ - 32))
                    say ""
                    say "[B-3] last 32 bytes (offset $OFF .. $((FSZ-1)))"
                    od -An -tx1 -j "$OFF" -N 32 "$FW" 2>/dev/null | sed 's/^/  /'
                else
                    say "TAIL_SKIP: file too small"
                fi
                ;;
        esac
    fi
    if need strings "firmware tail strings"; then
        FSZ2="$(stat -c %s "$FW" 2>/dev/null || echo 0)"
        case "$FSZ2" in
            ''|*[!0-9]*) : ;;
            *)
                if [ "$FSZ2" -gt 4096 ]; then
                    say ""
                    say "[B-4] printable strings in last 4096 bytes (max 40)"
                    strings -a -n 6 "$FW" 2>/dev/null | tail -40 | sed 's/^/  /'
                fi
                ;;
        esac
    fi
else
    say "NOT_READABLE: $FW (root required?)"
fi

# =============================================================== C mount =====
sec "C. mount / overlay / KSU 痕迹（只读）"
if need grep "mountinfo"; then
    say "[C-1] /proc/self/mountinfo — vendor / overlay / KSU 相关行"
    cat /proc/self/mountinfo 2>/dev/null \
        | grep -Ei "vendor|overlay|magisk|ksu|susfs|apatch|worker" \
        | sed 's/^/  /' | head -80
    say ""
    say "[C-2] 计数"
    say "  vendor_lines : $(cat /proc/self/mountinfo 2>/dev/null | grep -ci vendor)"
    say "  overlay_lines: $(cat /proc/self/mountinfo 2>/dev/null | grep -ci overlay)"
    say "  OverlayFS 类型行: $(cat /proc/self/mountinfo 2>/dev/null | grep -ci ' - overlay ')"
fi
if need mount "mount table"; then
    say ""
    say "[C-3] mount | grep -Ei 'overlay|vendor'（前 30 行）"
    mount 2>/dev/null | grep -Ei "overlay|vendor" | head -30 | sed 's/^/  /'
fi
say ""
say "[C-4] 已知的 KSU / NoMount 位置是否存在（只列目录，不读内容）"
for p in /data/adb/modules /data/adb/ksu /data/adb/susfs /sbin/.magisk; do
    if [ -e "$p" ]; then say "  EXISTS: $p"; else say "  ABSENT: $p"; fi
done
say "  说明：上述目录存在 ≠ overlay 正在覆盖 /vendor；判定以 C-1 的 mount 行为准。"

# ============================================================= D build-id ===
sec "D. 内核 build-id 与版本（U4-26）"
KB_NOTES="/sys/kernel/notes"
if [ -r "$KB_NOTES" ]; then
    say "PATH: $KB_NOTES"
    say "SIZE: $(stat -c %s "$KB_NOTES" 2>/dev/null || echo NOT_AVAILABLE) bytes"
    if need od "kernel notes"; then
        say "[D-1] notes 原始字节（前 128 字节）"
        od -An -tx1 -N 128 "$KB_NOTES" 2>/dev/null | sed 's/^/  /'
    fi
    if need readelf "kernel notes"; then
        say ""
        say "[D-2] readelf -n /sys/kernel/notes"
        readelf -n "$KB_NOTES" 2>/dev/null | head -40 | sed 's/^/  /'
    fi
else
    say "NOT_READABLE: $KB_NOTES"
fi
say ""
say "[D-3] /proc/version"
rd /proc/version | sed 's/^/  /'
say ""
say "[D-4] /sys/module/mali_kbase_mt6991_r49/ 下的 notes 与 version（模块自身 build-id）"
KB=/sys/module/mali_kbase_mt6991_r49
if [ -d "$KB" ]; then
    say "  version: $(rd $KB/version | head -1)"
    if [ -r "$KB/notes/.note.gnu.build-id" ] && need od "module build-id"; then
        say "  module build-id bytes:"
        od -An -tx1 "$KB/notes/.note.gnu.build-id" 2>/dev/null | sed 's/^/    /'
    else
        say "  module build-id: NOT_AVAILABLE"
    fi
else
    say "  NOT_FOUND: $KB"
fi

# ============================================================= E gpuinfo =====
sec "E. GPU 产品识别（U4-12 / U4-04）"
FOUND_GPUINFO=0
for p in \
    /sys/class/misc/mali0/device/gpuinfo \
    /sys/devices/platform/soc/48000000.mali/gpuinfo \
    /sys/devices/platform/*.mali/gpuinfo
do
    if [ -r "$p" ]; then
        say "[E] PATH: $p"
        say "    VALUE: $(cat "$p" 2>/dev/null | tr -d '\n')"
        FOUND_GPUINFO=1
    fi
done
if [ "$FOUND_GPUINFO" = "0" ]; then
    say "NOT_AVAILABLE: gpuinfo sysfs 未找到（可能路径不同，见 E-2 的 find）"
fi
say ""
say "[E-2] 兜底：在 /sys 下找 gpuinfo（限时/限量）"
if have find; then
    find /sys/devices -maxdepth 6 -name gpuinfo 2>/dev/null | head -5 | sed 's/^/  /'
else
    say "NOT_AVAILABLE: find"
fi
say ""
say "  读法：期望形如 \"Mali-G925-Immortalis 12 cores r0p0 0x....\"。"
say "        若显示 Mali-G725 或其它核数，说明产品识别与预期不符，需重新核对 MC12。"
say ""
say "[E-3] /proc/modules 中 GPU 链路的 taint 列（排除强制装载）"
if [ -r /proc/modules ]; then
    grep -E "^(mali_kbase|mali_mgm|mali_prot_alloc|ged|mtk_gpu|mtk_gpufreq|mtk_gpueb|mtk_ghpm|mtk_smmu_qos|mtk_cg_peak)" /proc/modules 2>/dev/null \
        | awk '{print "  "$1"  size="$2"  refcnt="$3"  taint="$7}' | head -30
else
    say "  NOT_READABLE: /proc/modules"
fi

# =========================================================== F __versions ===
sec "F. 模块 __versions 节（U4-24b；只读，输出到独立文件）"
MODDIR="${MODDIR:-/vendor_dlkm/lib/modules}"
if [ ! -d "$MODDIR" ]; then
    for cand in /vendor/lib/modules /vendor_dlkm/lib/modules /system/lib/modules; do
        if [ -d "$cand" ]; then MODDIR="$cand"; break; fi
    done
fi
say "MODDIR: $MODDIR"
say "  目的：取设备构建的 __ksymtab 期望 CRC。"
say "  ged 用作 14 个结构一致模块的抽样；kbase 必须单独取（源码已变）。"
if need readelf "modules"; then
    for m in ged mali_kbase_mt6991_r49; do
        F="$MODDIR/$m.ko"
        OF="$OUTDIR/F_${m}_versions.txt"
        if [ -r "$F" ]; then
            say ""
            say "[F] $F"
            say "    size   : $(stat -c %s "$F" 2>/dev/null || echo NOT_AVAILABLE)"
            say "    sha256 : $(sha256sum "$F" 2>/dev/null | awk '{print $1}')"
            readelf -x __versions "$F" > "$OF" 2>/dev/null
            if [ -s "$OF" ]; then
                say "    __versions dump -> $(basename "$OF")"
                say "    dump size      : $(stat -c %s "$OF" 2>/dev/null || echo NOT_AVAILABLE) bytes"
                say "    dump sha256    : $(sha256sum "$OF" 2>/dev/null | awk '{print $1}')"
                say "    (回传时只需回传这两个 dump 文件，或它们的 sha256 + 前 40 行)"
            else
                say "    __versions dump: NOT_AVAILABLE (readelf 未产出内容)"
                rm -f "$OF" 2>/dev/null
            fi
        else
            say ""
            say "[F] NOT_READABLE: $F"
        fi
    done
else
    say "NOT_AVAILABLE: readelf —— 无法取 __versions"
fi

# ======================================================= G MTK 扩展开关 ====
sec "G. OEM kbase 是否编入 MTK 私有扩展（U4-14）"
say "  原理：CONFIG_MALI_MTK_FENCE_DEBUG 内的字符串只在该宏开启时编入 .rodata。"
say "        串在 => ioctl 80 在设备构建上可达。"
KBKO="$MODDIR/mali_kbase_mt6991_r49.ko"
if [ -r "$KBKO" ] && need strings "kbase strings"; then
    say ""
    say "  [G-1] 'Internal fence wait' 命中数（>0 => CONFIG_MALI_MTK_FENCE_DEBUG 开）"
    say "        COUNT: $(strings -a "$KBKO" 2>/dev/null | grep -c 'Internal fence wait')"
    say "  [G-2] 'Internal fence timeouts' 命中数（>0 => FENCE_TIMEOUT_RESET / 跨队列恢复路径在）"
    say "        COUNT: $(strings -a "$KBKO" 2>/dev/null | grep -c 'Internal fence timeouts')"
    say "  [G-3] 'ged_mali_event_notify_fence_timeout_event' 命中数（>0 => MBRAIN 通道也在）"
    say "        COUNT: $(strings -a "$KBKO" 2>/dev/null | grep -c 'ged_mali_event_notify_fence_timeout_event')"
    say "  [G-4] 有限核数相关字符串（ioctl 55 的日志面）"
    strings -a "$KBKO" 2>/dev/null | grep -i "limited core\|max_core_count" | head -5 | sed 's/^/        /'
    say "  [G-5] 队列组 create 的 reserved 校验日志（R49 内联 padding 校验的证据）"
    strings -a "$KBKO" 2>/dev/null | grep -i "Invalid reserved field not 0" | head -3 | sed 's/^/        /'
else
    say "NOT_AVAILABLE: 无法读取 $KBKO 或缺少 strings"
fi

# ============================================================= H dmesg ======
sec "H. dmesg 中的 GPU / 固件 / GLB 线索（U4-02 / U4-11）"
if need dmesg "kernel log"; then
    DN="$(dmesg 2>/dev/null | wc -l | tr -d ' ')"
    say "  dmesg lines: ${DN:-NOT_AVAILABLE}"
    case "${DN:-0}" in
        ''|*[!0-9]*) DN=0 ;;
    esac
    if [ "$DN" -gt 0 ]; then
        say ""
        say "  [H-1] mali / csf / firmware 相关（前 60 行）"
        dmesg 2>/dev/null | grep -iE "mali|csf|gpu" | head -60 | sed 's/^/    /'
        say ""
        say "  [H-2] 'Loading Mali firmware'（version_hash，仅作锚点，不是 GLB 版本）"
        dmesg 2>/dev/null | grep -i "Loading Mali firmware" | head -5 | sed 's/^/    /'
        say "  [H-3] 'Version check failed' / 'firmware may have failed'"
        dmesg 2>/dev/null | grep -iE "Version check failed|firmware may have failed" | head -5 | sed 's/^/    /'
        say "  [H-4] 'disagrees about version of symbol'（U4-25b 的唯一运行态判据）"
        say "        COUNT: $(dmesg 2>/dev/null | grep -c 'disagrees about version of symbol')"
        say "  [H-5] 'git_sha'（固件构建标识）"
        dmesg 2>/dev/null | grep -i "firmware git_sha" | head -3 | sed 's/^/    /'
    else
        say "  NOT_AVAILABLE: dmesg 返回空（Android 上可能被 dmesg_restrict 限制）"
    fi
fi

# =========================================================== I debugfs ======
sec "I. mali debugfs 枚举（U4-02 / U4-15）"
DBG=/sys/kernel/debug/mali0
if [ -d "$DBG" ]; then
    say "PATH: $DBG"
    if have ls; then
        say "[I-1] 顶层条目"
        ls -1 "$DBG" 2>/dev/null | head -60 | sed 's/^/  /'
        say ""
        say "[I-2] 二级条目（device / csf 子目录，若存在）"
        for d in device csf; do
            if [ -d "$DBG/$d" ]; then
                say "  -- $d --"
                ls -1 "$DBG/$d" 2>/dev/null | head -60 | sed 's/^/    /'
            fi
        done
    fi
    say ""
    say "  说明：R49/R56 kbase 均未直接暴露 GLB 版本 debugfs 节点（源码已核）。"
    say "        若 I-1/I-2 中出现 fw_* 版本类文件，再单独 cat（本脚本不自动读，避免副作用）。"
else
    say "NOT_AVAILABLE: $DBG 不存在（debugfs 未挂载或路径不同）"
    say "  备选：ls /sys/kernel/debug 2>/dev/null | head -30"
    ls -1 /sys/kernel/debug 2>/dev/null | head -30 | sed 's/^/    /'
fi

# ========================================================== J ELF 元数据 ====
sec "J. Vulkan 薄壳与 gpud / ged 的 ELF 元数据（U4-17 / U4-23）"
say "  说明：只读 ELF 头/动态段/动态符号，不复制文件本体。"
for f in \
    /vendor/lib64/hw/mt6991/vulkan.mali.so \
    /vendor/lib64/libgpud.so \
    /system_ext/lib64/libgpud_sys.so \
    /vendor/lib64/libged.so
do
    say ""
    if [ -r "$f" ]; then
        say "[J] $f"
        say "    size  : $(stat -c %s "$f" 2>/dev/null || echo NOT_AVAILABLE)"
        say "    sha256: $(sha256sum "$f" 2>/dev/null | awk '{print $1}')"
        if need readelf "ELF metadata"; then
            say "    -- DT_NEEDED --"
            readelf -d "$f" 2>/dev/null | grep -E "NEEDED|SONAME" | head -25 | sed 's/^/      /'
            say "    -- 导出符号数 --"
            say "      dynsym exported: $(readelf --dyn-syms "$f" 2>/dev/null | grep -c 'FUNC.*DEFAULT.*[0-9]\+$')"
            case "$f" in
                *vulkan.mali.so)
                    say "    -- vk / api_version 相关字符串 --"
                    if need strings "vulkan strings"; then
                        strings -a -n 6 "$f" 2>/dev/null | grep -iE "vk_icd|api_version|vulkan|1\.[0-9]" | head -15 | sed 's/^/      /'
                    fi
                    ;;
                *libgpud*)
                    say "    -- gpud 符号样本（前 15 个）--"
                    readelf --dyn-syms "$f" 2>/dev/null | awk '$4=="FUNC" && $7!="UND" {print $8}' | head -15 | sed 's/^/      /'
                    ;;
                *libged.so)
                    say "    -- ged 符号样本（前 15 个）--"
                    readelf --dyn-syms "$f" 2>/dev/null | awk '$4=="FUNC" && $7!="UND" {print $8}' | head -15 | sed 's/^/      /'
                    ;;
            esac
        fi
    else
        say "[J] NOT_READABLE: $f"
    fi
done
say ""
say "[J-5] U4-23 的判据：若 libgpud.so 与 libgpud_sys.so 的导出 FUNC 符号集高度重合，"
say "      则二者是同 API 的 vendor / system 两份拷贝；否则是不同实现。"
say "      本脚本只给样本，完整对照需对两份 dynsym 排序后 diff（文本操作，可离线做）。"

# ============================================================= K 属性面 ====
sec "K. 属性面与后端选择线索（U4-06 / U4-20）"
if need getprop "props"; then
    say "[K-1] 图形相关属性"
    getprop 2>/dev/null | grep -iE "egl|vulkan|gles|gpu|gralloc|hwui|composer|renderengine" | head -50 | sed 's/^/  /'
fi
say ""
say "[K-2] linker 配置中的 EGL 搜索路径（U4-06）"
if [ -r /linkerconfig/ld.config.txt ]; then
    grep -n -iE "egl|mali|mt6991" /linkerconfig/ld.config.txt 2>/dev/null | head -30 | sed 's/^/  /'
else
    say "  NOT_READABLE: /linkerconfig/ld.config.txt"
fi
say ""
say "[K-3] SurfaceFlinger 后端线索（U4-20；有界输出）"
if need dumpsys "SurfaceFlinger"; then
    dumpsys SurfaceFlinger 2>/dev/null | grep -iE "GLES|skiagl|RenderEngine|Vulkan|backend" | head -20 | sed 's/^/  /'
fi
say ""
say "[K-4] /dev/mali0 与 mali0 相关 fd（U4-21）"
ls -l /dev/mali0 2>/dev/null | sed 's/^/  /' || say "  NOT_FOUND: /dev/mali0"
if need ls "proc fd"; then
    say "  -- 打开 /dev/mali0 的进程（需要 root；可能为空）--"
    for pid in /proc/[0-9]*; do
        if ls -l "$pid/fd" 2>/dev/null | grep -q mali0; then
            say "    PID ${pid#/proc/} : $(cat $pid/comm 2>/dev/null || echo NOT_AVAILABLE)"
        fi
    done | head -20
fi

# ================================================================ 收尾 =====
sec "Z. 结束"
say "OUTPUT_FILE: $MAIN"
say "OUTPUT_SIZE: $(stat -c %s "$MAIN" 2>/dev/null || echo NOT_AVAILABLE) bytes"
say "EXTRA_FILES:"
ls -1 "$OUTDIR" 2>/dev/null | sed 's/^/  /'
say ""
say "NO_BINARY 声明：本脚本未复制、未压缩、未导出、未上传任何 .so / .ko / .bin。"
say "未装载 / 未卸载 / 未替换任何模块或固件；未修改任何系统分区。"
say ""
say "结果不代表任何项目已闭合；判读请对照"
say "  06_porting_design/STAGE4_DEVICE_COLLECTION_PLAN.md"

exit 0
