#!/system/bin/sh
# =============================================================================
#  collect_device.sh — GPU 用户态 / 固件 只读证据采集
#
#  设计原则：
#    1. 只读      —— 仅 ls / cat / sha256sum / getprop / readelf / strings
#    2. 不落地二进制 —— 不 pull 任何 .so / .bin，只输出元数据
#    3. 可核对    —— 输出与 05_userspace_firmware/*.md 的表格逐行对应
#
#  用法：
#    adb push collect_device.sh /data/local/tmp/
#    adb shell sh /data/local/tmp/collect_device.sh > evidence.txt
#
#  注意：本脚本在设备上运行，需 root 或至少可读 /vendor（多数项 root 才可读）
# =============================================================================

set -u
OUT=${1:-/dev/stdout}

say() { echo "$@" ; }
hdr() { echo "" ; echo "===== $* =====" ; }

hdr "0. 设备标识"
getprop ro.product.model           2>/dev/null
getprop ro.product.device          2>/dev/null
getprop ro.build.version.release   2>/dev/null
getprop ro.build.version.sdk       2>/dev/null
getprop ro.board.platform          2>/dev/null
getprop ro.hardware               2>/dev/null
getprop ro.hardware.egl           2>/dev/null
getprop ro.hardware.vulkan        2>/dev/null
uname -a                           2>/dev/null

hdr "1. GPU 相关系统属性"
for p in $(getprop 2>/dev/null | grep -iE "gpu|mali|gralloc|vulkan|egl" | sed 's/^\[//;s/\].*//'); do
    printf '%-48s = %s\n' "$p" "$(getprop "$p" 2>/dev/null)"
done

hdr "2. 固件"
for d in /vendor/firmware /vendor/firmware_mnt /odm/firmware /vendor_dlkm; do
    [ -d "$d" ] && { echo "-- $d --"; ls -la "$d" 2>/dev/null | grep -iE "mali|csf|gpu|\.bin"; }
done
FW=/vendor/firmware/mali_csffw.bin
if [ -f "$FW" ]; then
    echo "-- mali_csffw.bin --"
    ls -l "$FW"
    sha256sum "$FW" 2>/dev/null
    # 固件头前 24 字节：magic(4) + minor(1) + major(1) + 2 + hash(4) + 4 + entry_end(4)
    echo "header hexdump (前 32 字节):"
    od -A x -t x1 -N 32 "$FW" 2>/dev/null
    echo "offset 4 (minor) / 5 (major):"
    od -A d -t u1 -j 4 -N 2 "$FW" 2>/dev/null
    echo "注意: minor 应为 3 (r49p1) 或 4 (r56p0)"
else
    echo "NOT FOUND: $FW"
fi

hdr "3. 用户态 DDK"
for d in /vendor/lib64/egl /vendor/lib64 /vendor/lib64/hw /system/lib64/egl /system/lib64; do
    [ -d "$d" ] && { echo "-- $d --"; ls -la "$d" 2>/dev/null | grep -iE "mali|vulkan|GLES|EGL"; }
done

hdr "4. Vulkan ICD"
for d in /vendor/lib64/vulkan /vendor/etc/vulkan /vendor/etc/vulkan/icd.d /system/etc/vulkan/icd.d; do
    [ -e "$d" ] && { echo "-- $d --"; ls -la "$d" 2>/dev/null; }
done
for f in /vendor/etc/vulkan/icd.d/*.json /vendor/etc/egl/*.json /vendor/etc/egl.cfg; do
    [ -f "$f" ] && { echo "-- $f --"; cat "$f" 2>/dev/null; }
done

hdr "5. 图形 HAL"
ls -la /vendor/lib64/hw/ 2>/dev/null | grep -iE "gralloc|mapper|composer|hwcomposer|memtrack|allocator"

hdr "6. VINTF / init"
[ -f /vendor/etc/vintf/manifest.xml ] && grep -iE -A2 "graphics|gralloc|composer|allocator" /vendor/etc/vintf/manifest.xml 2>/dev/null | head -50
ls /vendor/etc/init/ 2>/dev/null | grep -iE "gpu|mali|graphics"

hdr "7. dma-buf heap（判断 gralloc 后端）"
ls -la /dev/dma_heap/ 2>/dev/null || echo "no /dev/dma_heap (可能仍用 ion)"
ls -la /dev/ion 2>/dev/null

hdr "8. GPU 设备节点"
ls -la /dev/mali* 2>/dev/null || echo "no /dev/mali*"

hdr "9. 内核日志中的固件与 GPU 信息"
dmesg 2>/dev/null | grep -iE "mali|csffw|kbase|gpu" | tail -60

hdr "10. 已加载模块"
lsmod 2>/dev/null | grep -iE "mali|gpu|ged|gpueb|gpufreq"

echo ""
echo "===== END ====="
echo "# 说明：本脚本不导出任何二进制。如需 blob 本体，需另行决定并评估合规风险。"
