#!/system/bin/sh
# =============================================================================
# MTK Extreme Bandwidth Mod v1.0 — service.sh
# Runs via Magisk late_start service after boot_completed
# Universal — All MediaTek Devices
# Focus: Network / WiFi / Mobile Data runtime tweaks
# =============================================================================

LOG="/data/local/tmp/mtk_bwmod.log"
log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }

SOC=$(getprop ro.vendor.mediatek.platform 2>/dev/null)
[ -z "$SOC" ] && SOC=$(getprop ro.soc.model 2>/dev/null)
[ -z "$SOC" ] && SOC=$(getprop ro.board.platform 2>/dev/null)
CPUS=$(nproc --all 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 8)

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
sleep 6

log "================================================"
log " MTK EXTREME BANDWIDTH MOD v1.0 — BOOT SERVICE"
log " SoC: ${SOC}  |  CPUs: ${CPUS}"
log "================================================"

# =============================================================================
# 1. RADIO / RIL PROPS (re-applied after modem init)
# =============================================================================
setprop persist.vendor.radio.nr.enabled 1
setprop persist.vendor.radio.force_nr true
setprop persist.vendor.radio.nr_sa_mode 1
setprop persist.vendor.radio.nr_nsa_mode 1
setprop persist.vendor.radio.endc_enabled 1
setprop persist.vendor.radio.lte_ul_ca 1
setprop persist.vendor.radio.lte_dl_ca 1
setprop persist.vendor.radio.lte_mimo_mode 2
setprop persist.vendor.radio.nr_256qam 1
setprop persist.vendor.radio.lte_256qam 1
setprop persist.vendor.radio.force_lte_ca true
setprop persist.vendor.radio.lte.lteca.cap 2
setprop persist.vendor.radio.smart.data.switch 1
setprop persist.vendor.radio.nr_endc_support 1
setprop persist.vendor.radio.mtk_nr_support 1
setprop persist.vendor.radio.psm.disabled 1
setprop persist.vendor.radio.network.always_connected 1
log "[1] Radio + NR props re-applied"

# =============================================================================
# 2. IMS / VoLTE / VoNR / WFC
# =============================================================================
setprop persist.vendor.ims_support 1
setprop persist.vendor.mtk_ims_support 1
setprop persist.vendor.volte_support 1
setprop persist.vendor.mtk_volte_support 1
setprop persist.vendor.wfc_support 1
setprop persist.vendor.mtk_wfc_support 1
setprop persist.vendor.vilte_support 1
setprop persist.vendor.radio.volte_enabled 1
setprop persist.vendor.radio.vonr_enabled 1
setprop persist.dbg.volte_avail_ovr 1
setprop persist.dbg.ims_volte_enable 1
log "[2] IMS/VoLTE/VoNR/WFC applied"

# =============================================================================
# 3. TCP KERNEL TUNING (BBR + buffers)
# =============================================================================
sysctl -w net.ipv4.tcp_window_scaling=1              2>/dev/null
sysctl -w net.core.rmem_max=33554432                 2>/dev/null
sysctl -w net.core.wmem_max=33554432                 2>/dev/null
sysctl -w net.core.rmem_default=4194304              2>/dev/null
sysctl -w net.core.wmem_default=4194304              2>/dev/null
sysctl -w net.ipv4.tcp_rmem="4096 1048576 33554432"  2>/dev/null
sysctl -w net.ipv4.tcp_wmem="4096 1048576 33554432"  2>/dev/null
sysctl -w net.ipv4.tcp_retries2=8                   2>/dev/null
sysctl -w net.ipv4.tcp_syn_retries=3                2>/dev/null
sysctl -w net.ipv4.tcp_keepalive_time=30            2>/dev/null
sysctl -w net.ipv4.tcp_keepalive_intvl=10           2>/dev/null
sysctl -w net.ipv4.tcp_keepalive_probes=3           2>/dev/null
sysctl -w net.ipv4.tcp_fastopen=3                   2>/dev/null
sysctl -w net.ipv4.tcp_no_metrics_save=1            2>/dev/null
sysctl -w net.ipv4.tcp_timestamps=1                 2>/dev/null
sysctl -w net.ipv4.tcp_sack=1                       2>/dev/null
sysctl -w net.ipv4.tcp_fack=1                       2>/dev/null
sysctl -w net.ipv4.tcp_mtu_probing=1                2>/dev/null
sysctl -w net.ipv4.tcp_slow_start_after_idle=0      2>/dev/null
sysctl -w net.ipv4.tcp_fin_timeout=15               2>/dev/null
sysctl -w net.ipv4.ip_local_port_range="1024 65535" 2>/dev/null
sysctl -w net.core.netdev_max_backlog=16384          2>/dev/null
sysctl -w net.core.somaxconn=8192                   2>/dev/null
sysctl -w net.ipv4.tcp_congestion_control=bbr       2>/dev/null \
  || sysctl -w net.ipv4.tcp_congestion_control=cubic 2>/dev/null
CC=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
log "[3] TCP tuning applied (cc=${CC})"

# =============================================================================
# 4. UDP / QUIC BUFFERS
# =============================================================================
sysctl -w net.ipv4.udp_rmem_min=65536            2>/dev/null
sysctl -w net.ipv4.udp_wmem_min=65536            2>/dev/null
sysctl -w net.ipv4.udp_mem="65536 131072 262144" 2>/dev/null
log "[4] UDP/QUIC buffers applied"

# =============================================================================
# 5. WIFI RUNTIME PROPS
# =============================================================================
setprop persist.sys.wifi.power_save false
setprop wifi.ps.mode 0
setprop persist.wifi.powersave 0
setprop wifi.5ghz.preferred 1
setprop persist.vendor.wifi.band_steering 1
setprop persist.vendor.wifi.vht80.enable true
setprop persist.vendor.wifi.roaming_trigger -75
log "[5] WiFi runtime props applied"

# =============================================================================
# 6. DNS OVERRIDE — all active interfaces (overrides DHCP)
# =============================================================================
setprop net.dns1 1.1.1.1
setprop net.dns2 1.0.0.1
for IF in $(ip link show up 2>/dev/null \
    | awk -F': ' '/^[0-9]+/{gsub(/@.*/,"",$2); print $2}' \
    | grep -vE "^lo$|^dummy"); do
  setprop "net.${IF}.dns1" 1.1.1.1 2>/dev/null
  setprop "net.${IF}.dns2" 1.0.0.1 2>/dev/null
done
log "[6] DNS 1.1.1.1 applied on all interfaces"

# =============================================================================
# 7. NETWORK IRQ AFFINITY — bind to big cores for faster packet processing
# =============================================================================
case "$CPUS" in
  10) BIG_MASK="3c0" ;;   # Dimensity 10-core: cpu6-9
   8) BIG_MASK="f0"  ;;   # Octa-core: cpu4-7
   6) BIG_MASK="38"  ;;   # Hexa-core: cpu3-5
   *) BIG_MASK="06"  ;;   # Quad-core fallback: cpu1-2
esac

BOUND=0
for irq_dir in /proc/irq/*/; do
  name=$(cat "${irq_dir}actions" 2>/dev/null)
  case "$name" in
    *wlan*|*wifi*|*mt76*|*connsys*|*WIFI*|*WCN*|\
    *mtk_*net*|*rmnet*|*ccmni*|*modem*|*ccci*)
      echo "$BIG_MASK" > "${irq_dir}smp_affinity" 2>/dev/null \
        && BOUND=$((BOUND+1))
      ;;
  esac
done
log "[7] IRQ affinity: ${BOUND} network IRQs → cpu mask 0x${BIG_MASK}"

# =============================================================================
# 8. DATA STALL RECOVERY PROPS (runtime)
# =============================================================================
setprop persist.data.stall.recovery.action 2
setprop persist.vendor.radio.keepalive 1
setprop persist.vendor.radio.data_keepalive 1
setprop persist.vendor.radio.psm.disabled 1
log "[8] Data stall recovery props applied"

# =============================================================================
# 9. NETWORK INTERFACE QoS HINT
# =============================================================================
# Set transmit queue length on network interfaces
for IF in $(ip link show up 2>/dev/null \
    | awk -F': ' '/^[0-9]+/{gsub(/@.*/,"",$2); print $2}' \
    | grep -vE "^lo$|^dummy"); do
  ip link set "$IF" txqueuelen 3000 2>/dev/null
done
# Increase socket receive buffer for rmnet
for RMNET in /sys/class/net/rmnet*/; do
  [ -f "${RMNET}queues/rx-0/rps_cpus" ] && \
    echo "$BIG_MASK" > "${RMNET}queues/rx-0/rps_cpus" 2>/dev/null
done
log "[9] txqueuelen=3000 + RPS applied on network interfaces"

# =============================================================================
# DONE
# =============================================================================
log "-----------------------------------------------"
log " All network tweaks applied successfully"
log "==============================================="
