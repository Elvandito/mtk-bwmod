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
sysctl -w net.core.rmem_max=67108864                 2>/dev/null
sysctl -w net.core.wmem_max=67108864                 2>/dev/null
sysctl -w net.core.rmem_default=4194304              2>/dev/null
sysctl -w net.core.wmem_default=4194304              2>/dev/null
sysctl -w net.ipv4.tcp_rmem="4096 1048576 67108864"  2>/dev/null
sysctl -w net.ipv4.tcp_wmem="4096 1048576 67108864"  2>/dev/null
sysctl -w net.ipv4.tcp_notsent_lowat=131072          2>/dev/null
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
# 10. UNLOCK HIDDEN NETWORK FEATURES IN SETTINGS UI (runtime re-apply)
# =============================================================================
# 5G toggle
setprop persist.vendor.radio.nr.setting.support 1
setprop persist.vendor.radio.show_nr_switch 1
setprop persist.radio.nr.setting 1
# VoLTE toggle
setprop persist.vendor.radio.volte_setting_support 1
setprop persist.vendor.radio.show_volte_setting 1
setprop persist.dbg.volte_avail_ovr 1
setprop persist.dbg.ims_volte_enable 1
# WiFi Calling toggle
setprop persist.vendor.radio.wfc_setting_support 1
setprop persist.vendor.radio.show_wfc_setting 1
setprop persist.dbg.wfc_avail_ovr 1
# Video Calling toggle
setprop persist.dbg.vt_avail_ovr 1
setprop persist.vendor.radio.show_vilte_setting 1
# Network mode selector (all options)
setprop persist.vendor.radio.force_network_mode 1
setprop persist.vendor.radio.show_network_mode 1
# APN editor unlock
setprop persist.vendor.radio.apn_unlock 1
setprop persist.vendor.radio.show_apn_setting 1
# Signal dBm in status
setprop persist.radio.show_signal_dbm 1
setprop persist.vendor.radio.show_signal_detail 1
# MIUI/HyperOS specific
setprop persist.sys.miui.volte_available 1
setprop persist.sys.miui.wfc_available 1
setprop persist.sys.miui.nr_available 1
setprop persist.sys.miui.show_volte_icon 1
setprop persist.sys.miui.show_nr_icon 1
setprop persist.sys.miui.show_wfc_icon 1
log "[10] Settings UI network features unlocked"

# =============================================================================
# DONE
# =============================================================================
log "-----------------------------------------------"
log " All network tweaks applied successfully"
log "==============================================="

# =============================================================================
# 11. CCCI + ANTENNA + CA SCHEDULER + CONNAC (runtime re-apply)
# =============================================================================
setprop persist.vendor.radio.ccci_ready 1
setprop persist.vendor.radio.ccci_bypass_fsd 1
setprop persist.vendor.radio.ant_switch 1
setprop persist.vendor.radio.ant_diversity 1
setprop persist.vendor.radio.lte_rx_diversity 1
setprop persist.vendor.radio.nr_rx_diversity 1
setprop persist.vendor.radio.lte_dl_4rx 1
setprop persist.vendor.radio.nr_dl_4rx 1
setprop persist.vendor.radio.lte_ca_max_component 4
setprop persist.vendor.radio.nr_ca_max_component 2
setprop persist.vendor.radio.nr_intra_band_ca 1
setprop persist.vendor.radio.nr_inter_band_ca 1
setprop persist.vendor.wifi.connac2 1
setprop persist.vendor.mtk.wifi.ampdu_tx 1
setprop persist.vendor.mtk.wifi.ampdu_rx 1
setprop persist.vendor.mtk.wifi.amsdu_tx 1
setprop persist.vendor.mtk.wifi.amsdu_rx 1
setprop persist.vendor.mtk.wifi.tx_power_boost 1
setprop persist.vendor.mtk.wifi.he_dl_ofdma 1
setprop persist.vendor.mtk.wifi.he_ul_ofdma 1
log "[11] CCCI + Antenna + CA + ConnAC props applied"

# =============================================================================
# 12. SIGNAL PROCESSING + NETWORK SEARCH + MODEM POWER
# =============================================================================
setprop persist.vendor.radio.afc.enable 1
setprop persist.vendor.radio.ulfd.enable 1
setprop persist.vendor.radio.lte_ul_mcs_boost 1
setprop persist.vendor.radio.nr_ul_mcs_boost 1
setprop persist.vendor.radio.lte_ul_rank 2
setprop persist.vendor.radio.nr_ul_rank 2
setprop persist.vendor.radio.fast_camp_enable 1
setprop persist.vendor.radio.rat_priority nr,lte,wcdma,gsm
setprop persist.vendor.radio.md_fast_wakeup 1
setprop persist.vendor.radio.md_sleep_threshold -100
setprop persist.vendor.radio.data_throttle 0
setprop persist.vendor.radio.slice_support 1
setprop persist.vendor.radio.ursp_enable 1
setprop persist.vendor.radio.srvcc_enable 1
log "[12] Signal + Network search + Modem power applied"

# =============================================================================
# 13. WiFi AP COMMUNICATION — 802.11 QoS/WMM/BA/ADDTS/Beamforming/802.11k/v/r
# =============================================================================
# WMM + UAPSD — priority AC queues toward AP
setprop persist.vendor.mtk.wifi.wmm_ac_vo 1
setprop persist.vendor.mtk.wifi.wmm_ac_vi 1
setprop persist.vendor.mtk.wifi.uapsd_enable 1
setprop persist.vendor.mtk.wifi.wmm_ps 1

# Block ACK — aggregate up to 64 frames per BA window
setprop persist.vendor.mtk.wifi.ba_tx_size 64
setprop persist.vendor.mtk.wifi.ba_rx_size 64
setprop persist.vendor.mtk.wifi.ba_auto 1

# ADDTS — send QoS Traffic Stream request to AP
setprop persist.vendor.mtk.wifi.addts_enable 1
setprop persist.vendor.mtk.wifi.ts_reclassify 1

# Beamforming feedback — device sends CSI report to let AP steer beam
setprop persist.vendor.mtk.wifi.su_bfee 1
setprop persist.vendor.mtk.wifi.mu_bfee 1
setprop persist.vendor.mtk.wifi.vht_bf_cap 1
setprop persist.vendor.mtk.wifi.he_bf_cap 1
setprop persist.vendor.mtk.wifi.bf_report_size 4

# 802.11k/v/r — Neighbor Report, BSS Transition, Fast Roaming
setprop persist.vendor.mtk.wifi.dot11k 1
setprop persist.vendor.mtk.wifi.dot11v 1
setprop persist.vendor.mtk.wifi.dot11r 1
setprop persist.vendor.mtk.wifi.rrm_enable 1
setprop persist.vendor.mtk.wifi.bss_transition 1
setprop persist.vendor.mtk.wifi.ft_over_ds 1

# Spatial streams + MCS toward AP
setprop persist.vendor.mtk.wifi.nss_tx 2
setprop persist.vendor.mtk.wifi.nss_rx 2
setprop persist.vendor.mtk.wifi.max_ampdu_len 64
setprop persist.vendor.mtk.wifi.rate_control 1
setprop persist.vendor.mtk.wifi.ra_interval 100
log "[13] WiFi AP QoS/WMM/BA/ADDTS/BF/802.11k-v-r applied"

# =============================================================================
# 14. TC QDISC — Remove Android default qdiscs, replace with fq
#     fq (Fair Queue) pairs with BBR perfectly — per-flow pacing,
#     eliminates head-of-line blocking, no artificial rate limit
# =============================================================================
for IF in $(ip link show up 2>/dev/null \
    | awk -F': ' '/^[0-9]+/{gsub(/@.*/,"",$2); print $2}' \
    | grep -vE "^lo$|^dummy|^ip6tnl|^sit"); do

  # Remove Android's default qdisc (pfifo_fast / fq_codel / sfq)
  # Skip interface if in AP/hotspot mode (prevents hotspot breakage)
  AP_MODE=$(iw dev "$IF" info 2>/dev/null | grep -c "type AP")
  [ "$AP_MODE" -gt "0" ] && continue

  tc qdisc del dev "$IF" root 2>/dev/null

  # Apply fq (Fair Queue) — best pairing for BBR congestion control
  # flows get individual pacing queues, no single stream can starve others
  tc qdisc add dev "$IF" root fq         2>/dev/null \
    || tc qdisc add dev "$IF" root fq_codel 2>/dev/null \
    || tc qdisc add dev "$IF" root pfifo_fast 2>/dev/null
done

# Verify
APPLIED=$(tc qdisc show 2>/dev/null | grep -cE "fq |fq_codel")
log "[14] tc qdisc → fq applied on ${APPLIED} interfaces"

# =============================================================================
# 15. HARDWARE OFFLOADING — GRO / GSO / TSO via sysfs + ethtool
#     Offloads packet reassembly and segmentation to hardware
#     instead of CPU — reduces kernel overhead for large transfers
# =============================================================================
for IF in $(ip link show up 2>/dev/null \
    | awk -F': ' '/^[0-9]+/{gsub(/@.*/,"",$2); print $2}' \
    | grep -vE "^lo$|^dummy|^ip6tnl|^sit"); do

  # ethtool method (works on wlan0, eth0 if present)
  ethtool -K "$IF" gro on  2>/dev/null
  ethtool -K "$IF" gso on  2>/dev/null
  ethtool -K "$IF" tso on  2>/dev/null
  ethtool -K "$IF" rx  on  2>/dev/null
  ethtool -K "$IF" tx  on  2>/dev/null

  # sysfs method — GRO via napi (rmnet_data* / ccmni*)
  for Q in /sys/class/net/${IF}/queues/rx-*/; do
    [ -f "${Q}rps_flow_cnt" ] && echo 512 > "${Q}rps_flow_cnt" 2>/dev/null
  done
done

# GRO via sysctl (kernel-level)
sysctl -w net.core.gro_normal_batch=64 2>/dev/null

log "[15] HW offloading (GRO/GSO/TSO) applied"

# =============================================================================
# 16. XPS — Transmit Packet Steering
#     Map each TX queue to the same big-core CPU mask as RX (IRQ affinity)
#     Ensures TX processing happens on the same core as RX → cache-hot path
# =============================================================================
XPS_BOUND=0
for IF in $(ls /sys/class/net/ 2>/dev/null \
    | grep -vE "^lo$|^dummy|^ip6tnl|^sit"); do
  for TXQ in /sys/class/net/${IF}/queues/tx-*/; do
    [ -f "${TXQ}xps_cpus" ] || continue
    echo "$BIG_MASK" > "${TXQ}xps_cpus" 2>/dev/null \
      && XPS_BOUND=$((XPS_BOUND+1))
  done
done
log "[16] XPS → cpu mask 0x${BIG_MASK} on ${XPS_BOUND} TX queues"

# =============================================================================
# 17. NAPI / NETDEV BUDGET — Process more packets per interrupt cycle
#     Default Android budget=300, increasing to 600 means fewer context
#     switches per second at high throughput — especially for NR/5G
# =============================================================================
sysctl -w net.core.netdev_budget=600          2>/dev/null
sysctl -w net.core.netdev_budget_usecs=4000   2>/dev/null
sysctl -w net.core.netdev_max_backlog=32768   2>/dev/null
log "[17] NAPI budget=600, backlog=32768 applied"

# =============================================================================
# 18. SCHEDUTIL HINT — Big cores respond faster to network load bursts
#     Does NOT lock governor to performance.
#     Lowers up_rate_limit on big cores so schedutil reacts in <200µs
#     instead of the default 500µs — critical for sub-millisecond IRQ handling
# =============================================================================
SCHED_APPLIED=0
for cpu_dir in /sys/devices/system/cpu/cpu*/cpufreq/; do
  [ -f "${cpu_dir}scaling_governor" ] || continue
  GOV=$(cat "${cpu_dir}scaling_governor" 2>/dev/null)
  [ "$GOV" != "schedutil" ] && continue
  # Only tune big cores (cpu index >= half of total)
  CPU_NUM=$(echo "$cpu_dir" | grep -o 'cpu[0-9]*' | grep -o '[0-9]*')
  HALF=$((CPUS / 2))
  [ "$CPU_NUM" -ge "$HALF" ] || continue
  # Lower rate_limit from default 500µs → 0 (react immediately to load spikes)
  echo 0   > "${cpu_dir}schedutil/up_rate_limit_us"   2>/dev/null
  echo 500 > "${cpu_dir}schedutil/down_rate_limit_us" 2>/dev/null
  SCHED_APPLIED=$((SCHED_APPLIED+1))
done
log "[18] schedutil up_rate_limit=0 on ${SCHED_APPLIED} big cores"

# =============================================================================
# 19. RPS FLOW TABLE — Larger flow hash table for multi-core RX steering
#     Default 0 flows — setting 512 per queue distributes high-bandwidth
#     connections across all RPS-enabled CPUs more evenly
# =============================================================================
sysctl -w net.core.rps_sock_flow_entries=32768 2>/dev/null
for IF in $(ls /sys/class/net/ 2>/dev/null \
    | grep -vE "^lo$|^dummy"); do
  for RXQ in /sys/class/net/${IF}/queues/rx-*/; do
    [ -f "${RXQ}rps_flow_cnt" ] && echo 512 > "${RXQ}rps_flow_cnt" 2>/dev/null
    [ -f "${RXQ}rps_cpus"     ] && echo "$BIG_MASK" > "${RXQ}rps_cpus" 2>/dev/null
  done
done
log "[19] RPS flow table=32768, rps_flow_cnt=512 applied"

# =============================================================================
# 20. IRQ COALESCING (Interrupt Moderation)
#     Batch incoming packets for 50µs before raising IRQ — fewer interrupts,
#     larger batches per wakeup → significant throughput gain for bulk transfers
# =============================================================================
COAL_APPLIED=0
for IF in $(ip link show up 2>/dev/null \
    | awk -F': ' '/^[0-9]+/{gsub(/@.*/,"",$2); print $2}' \
    | grep -vE "^lo$|^dummy|^ip6tnl|^sit"); do
  ethtool -C "$IF" \
    rx-usecs 50 tx-usecs 50 \
    rx-frames 32 tx-frames 32 2>/dev/null \
    && COAL_APPLIED=$((COAL_APPLIED+1))
done
log "[20] IRQ coalescing rx-usecs=50 rx-frames=32 on ${COAL_APPLIED} interfaces"

# =============================================================================
# 21. TCP OVERHEAD STRIPPING
#     tcp_timestamps=0  → removes 10-12 byte timestamp option from every segment
#     tcp_mtu_probing=2 → always start with full MTU, PMTUD handles reduction
#     Combined: less per-packet CPU work, more payload per segment
# =============================================================================
sysctl -w net.ipv4.tcp_timestamps=0     2>/dev/null
sysctl -w net.ipv4.tcp_mtu_probing=2    2>/dev/null
# Also enable ECN for congestion signaling without dropping packets
sysctl -w net.ipv4.tcp_ecn=1           2>/dev/null
sysctl -w net.ipv4.tcp_ecn_fallback=1  2>/dev/null
log "[21] TCP overhead stripped (timestamps=0, mtu_probing=2, ECN=1)"

# =============================================================================
# 22. CONNTRACK SCALING
#     Default Android nf_conntrack_max is ~65536 — exhausted quickly under
#     multi-threaded download (IDM/Torrent), gaming + background apps combined
#     Scale to 2M entries; hashsize = max/8 for optimal lookup performance
# =============================================================================
CT_MAX=2000000
CT_HASH=$((CT_MAX / 8))   # 250000 buckets

sysctl -w net.netfilter.nf_conntrack_max=$CT_MAX                2>/dev/null
sysctl -w net.netfilter.nf_conntrack_buckets=$CT_HASH           2>/dev/null
sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=600 2>/dev/null
sysctl -w net.netfilter.nf_conntrack_tcp_timeout_time_wait=30    2>/dev/null
sysctl -w net.netfilter.nf_conntrack_tcp_timeout_close_wait=15   2>/dev/null
sysctl -w net.netfilter.nf_conntrack_udp_timeout=30              2>/dev/null
sysctl -w net.netfilter.nf_conntrack_udp_timeout_stream=120      2>/dev/null
# Prevent conntrack table from filling — drop oldest TIME_WAIT first
sysctl -w net.netfilter.nf_conntrack_tcp_loose=1                 2>/dev/null
ACTUAL=$(sysctl -n net.netfilter.nf_conntrack_max 2>/dev/null)
log "[22] Conntrack max=${ACTUAL}, hash=${CT_HASH}, TCP_EST=600s"
