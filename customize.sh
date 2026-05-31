#!/system/bin/sh
# =============================================================================
# MTK Extreme Bandwidth Mod v1.2 — customize.sh
# Universal installer — all MediaTek devices
# =============================================================================

SKIPUNZIP=1

DEVICE=$(getprop ro.product.device)
MODEL=$(getprop ro.product.model)
BRAND=$(getprop ro.product.brand)
PLATFORM=$(getprop ro.board.platform)
VENDOR_PLATFORM=$(getprop ro.vendor.mediatek.platform)
SOC=$(getprop ro.soc.model 2>/dev/null)
HARDWARE=$(getprop ro.hardware)
ANDROID=$(getprop ro.build.version.release)
ARCH=$(getprop ro.product.cpu.abi)
CPUS=$(nproc --all 2>/dev/null || grep -c ^processor /proc/cpuinfo)
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_GB=$(( RAM_KB / 1024 / 1024 ))

ui_print ""
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "   MTK Extreme Bandwidth Mod v1.2"
ui_print "   Universal · Helio · Dimensity · MT"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print ""
ui_print "  Device   : $BRAND $MODEL"
ui_print "  Codename : $DEVICE"
ui_print "  Android  : $ANDROID  |  $ARCH"
ui_print "  Platform : ${PLATFORM:-unknown}"
ui_print "  SoC      : ${VENDOR_PLATFORM:-${SOC:-unknown}}"
ui_print "  RAM      : ${RAM_GB}GB  |  CPUs: $CPUS"
ui_print ""
ui_print "  Detecting MediaTek hardware..."

# 9-method MTK detection
IS_MTK=0
MTK_REASON=""
echo "$PLATFORM"        | grep -qi "^mt"       && IS_MTK=1 && MTK_REASON="ro.board.platform=$PLATFORM"
echo "$VENDOR_PLATFORM" | grep -qi "^mt"       && IS_MTK=1 && MTK_REASON="ro.vendor.mediatek.platform=$VENDOR_PLATFORM"
echo "$HARDWARE"        | grep -qi "^mt"       && IS_MTK=1 && MTK_REASON="ro.hardware=$HARDWARE"
echo "$SOC"             | grep -qi "^mt"       && IS_MTK=1 && MTK_REASON="ro.soc.model=$SOC"
echo "$SOC"             | grep -qi "dimensity" && IS_MTK=1 && MTK_REASON="Dimensity=$SOC"
[ -f /proc/mtk_battery_cmd ]                   && IS_MTK=1 && MTK_REASON="/proc/mtk_battery_cmd"
[ -d /sys/devices/platform/mediatek ]          && IS_MTK=1 && MTK_REASON="/sys/devices/platform/mediatek"
[ -f /sys/kernel/debug/mtk_btcvsd ]            && IS_MTK=1 && MTK_REASON="MTK BT CVSD node"
getprop | grep -q "\.mtk\." 2>/dev/null        && IS_MTK=1 && MTK_REASON="MTK props namespace"

if [ "$IS_MTK" != "1" ]; then
    ui_print ""
    ui_print "  ✗  Non-MediaTek device!"
    ui_print "     Platform : ${PLATFORM:-unknown}"
    ui_print "     SoC      : ${SOC:-unknown}"
    ui_print "     Hardware : ${HARDWARE:-unknown}"
    ui_print ""
    ui_print "  Module is MTK-only. Aborted."
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    abort
fi

ui_print "  ✓  MediaTek confirmed"
ui_print "     $MTK_REASON"
ui_print ""

unzip -o "$ZIPFILE" 'system.prop' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'module.prop' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'service.sh'  -d "$MODPATH" >&2

set_perm_recursive "$MODPATH"       root root 0755 0644
set_perm "$MODPATH/service.sh"      root root 0755

PROP_COUNT=$(grep -c "=" "$MODPATH/system.prop" 2>/dev/null || echo 0)
ui_print "  ✓  system.prop  ($PROP_COUNT props, 17 sections)"
ui_print "  ✓  service.sh   (13 sections, runs on boot)"
ui_print ""
ui_print "  system.prop sections:"
ui_print "   [01] LTE Carrier Aggregation & RIL"
ui_print "   [02] MTK Baseband & RIL Optimization"
ui_print "   [03] Fast Dormancy Disabled"
ui_print "   [04] WiFi PowerSave Off + Band Agg + WiFi6 + Low-Lat"
ui_print "   [05] TCP Buffer Sizes (NR: 64MB)"
ui_print "   [06] HW Offloading + Network Logging Off"
ui_print "   [07] DNS Cloudflare 1.1.1.1"
ui_print "   [08] Network Hints & QoS"
ui_print "   [09] NR/5G SA+NSA All Bands"
ui_print "   [10] MTK ConnSys / Radio / IMS / DSDS"
ui_print "   [11] LTE-A + NR Extended EN-DC MIMO"
ui_print "   [12] VoLTE / VoNR"
ui_print "   [13] Network Connectivity & Data Stall"
ui_print "   [14] Mobile Data Optimization"
ui_print "   [15] MTK Modem Scheduler & Radio QoS"
ui_print "   [16] IPv6 Dual-Stack (MTK modem props)"
ui_print "   [17] Hotspot & Tethering Offload"
ui_print ""
ui_print "  service.sh sections:"
ui_print "   [01] Radio + Modem QoS re-apply after modem init"
ui_print "   [02] IMS / VoLTE / VoNR / WFC"
ui_print "   [03] TCP / BBR congestion control"
ui_print "   [04] UDP / QUIC buffers"
ui_print "   [05] WiFi runtime (incl. low-latency / DTIM)"
ui_print "   [06] DNS override on all interfaces"
ui_print "   [07] Network IRQ → big CPU cores"
ui_print "   [08] Data stall recovery"
ui_print "   [09] txqueuelen=3000 + RPS on rmnet"
ui_print "   [10] Adaptive IRQ rebalance (thermal-aware)"
ui_print "   [11] fq_codel per-interface (bufferbloat)"
ui_print "   [12] TCP hardening — ECN / DSACK / early retransmit"
ui_print "   [13] NAT conntrack expand + tethering offload"
ui_print ""
ui_print "  Log: /data/local/tmp/mtk_bwmod.log"
ui_print ""
ui_print "  ✓  Done — reboot to apply"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
