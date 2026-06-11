#!/system/bin/sh
# =============================================================================
# MTK Extreme Bandwidth Mod v1.8 — action.sh
# Profile Switcher via Volume Keys
# Vol Up = Next | Vol Down = Prev | Power = Apply
# =============================================================================

PROFILE_FILE="/data/local/tmp/mtk_bwmod_profile"
LOG="/data/local/tmp/mtk_bwmod.log"
log() { echo "[$(date '+%H:%M:%S')] [PROFILE] $*" >> "$LOG"; }

CPUS=$(nproc --all 2>/dev/null || echo 8)
case "$CPUS" in
  10) BIG_MASK="3c0" ;;
   8) BIG_MASK="f0"  ;;
   6) BIG_MASK="38"  ;;
   *) BIG_MASK="06"  ;;
esac
HALF=$((CPUS / 2))

CURRENT=$(cat "$PROFILE_FILE" 2>/dev/null || echo "balanced")

# ── VOLUME KEY READER ─────────────────────────────────────────────────────────
# Read raw events from ALL /dev/input devices simultaneously (kernel-level)
# No device detection needed — getevent reads all at once
read_key() {
  getevent -l 2>/dev/null | while read -r LINE; do
    case "$LINE" in
      *KEY_VOLUMEUP*DOWN*)   echo "up";    break ;;
      *KEY_VOLUMEDOWN*DOWN*) echo "down";  break ;;
      *KEY_POWER*DOWN*)      echo "power"; break ;;
    esac
  done
}

# ── PROFILES ─────────────────────────────────────────────────────────────────
PROFILES="performance balanced battery"
IDX=0
for P in $PROFILES; do
  [ "$P" = "$CURRENT" ] && break
  IDX=$((IDX + 1))
done
ACTIVE_IDX=$IDX

label() {
  case "$1" in
    0) echo "⚡ Performance"  ;;
    1) echo "⚖️  Balanced"    ;;
    2) echo "🔋 Battery Saver" ;;
  esac
}

# ── PRINT MENU ────────────────────────────────────────────────────────────────
print_menu() {
  clear 2>/dev/null
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  MTK Extreme Bandwidth Mod v1.8"
  echo "  by Elvan"
  echo "  Universal MediaTek Network Mod"
  echo "  WiFi · LTE · NR/5G · TCP · VoLTE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  Active : $(label $ACTIVE_IDX)"
  echo ""
  echo "  ─────────────────────────────────"
  echo "  Select Profile"
  echo "  Vol↑=Next  Vol↓=Prev  Power=Apply"
  echo "  ─────────────────────────────────"
  echo ""
  for I in 0 1 2; do
    LBL=$(label $I)
    if [ "$I" = "$IDX" ] && [ "$I" = "$ACTIVE_IDX" ]; then
      echo "  ▶ $LBL  ← active"
    elif [ "$I" = "$IDX" ]; then
      echo "  ▶ $LBL"
    elif [ "$I" = "$ACTIVE_IDX" ]; then
      echo "    $LBL  ← active"
    else
      echo "    $LBL"
    fi
  done
  echo ""
}

# ── SELECTION LOOP ────────────────────────────────────────────────────────────
print_menu
RUNNING=1
while [ "$RUNNING" = "1" ]; do
  KEY=$(read_key)
  case "$KEY" in
    up)
      IDX=$(( (IDX + 1) % 3 ))
      print_menu
      ;;
    down)
      IDX=$(( (IDX + 2) % 3 ))
      print_menu
      ;;
    power)
      RUNNING=0
      ;;
  esac
done

# Resolve name from index
I=0
for P in $PROFILES; do
  [ "$I" = "$IDX" ] && SELECTED="$P" && break
  I=$((I + 1))
done

echo ""
echo "  Applying $(label $IDX)..."
echo ""

# ── PROFILE: PERFORMANCE ──────────────────────────────────────────────────────
apply_performance() {
  sysctl -w net.core.rmem_max=67108864                     2>/dev/null
  sysctl -w net.core.wmem_max=67108864                     2>/dev/null
  sysctl -w net.ipv4.tcp_rmem="4096 1048576 67108864"      2>/dev/null
  sysctl -w net.ipv4.tcp_wmem="4096 1048576 67108864"      2>/dev/null
  sysctl -w net.ipv4.tcp_congestion_control=bbr            2>/dev/null
  sysctl -w net.ipv4.tcp_fastopen=3                        2>/dev/null
  sysctl -w net.ipv4.tcp_timestamps=0                      2>/dev/null
  sysctl -w net.ipv4.tcp_mtu_probing=2                     2>/dev/null
  sysctl -w net.ipv4.tcp_slow_start_after_idle=0           2>/dev/null
  sysctl -w net.ipv4.tcp_notsent_lowat=131072              2>/dev/null
  sysctl -w net.core.netdev_budget=600                     2>/dev/null
  sysctl -w net.core.netdev_max_backlog=32768              2>/dev/null
  sysctl -w net.netfilter.nf_conntrack_max=2000000         2>/dev/null
  for IF in $(ip -o link show up 2>/dev/null | awk -F': ' '{gsub(/@.*/,"",$2);print $2}' | grep -vE "^lo$|^dummy|^ip6"); do
    [ "$(iw dev "$IF" info 2>/dev/null | grep -c "type AP")" -gt "0" ] && continue
    tc qdisc del dev "$IF" root 2>/dev/null
    tc qdisc add dev "$IF" root fq 2>/dev/null \
      || tc qdisc add dev "$IF" root fq_codel 2>/dev/null
    ethtool -C "$IF" rx-usecs 50 tx-usecs 50 rx-frames 32 2>/dev/null
  done
  for DIR in /sys/devices/system/cpu/cpu*/cpufreq/schedutil/; do
    N=$(echo "$DIR" | grep -o 'cpu[0-9]*' | tr -dc '0-9')
    [ "$N" -ge "$HALF" ] 2>/dev/null || continue
    echo 0   > "${DIR}up_rate_limit_us"   2>/dev/null
    echo 500 > "${DIR}down_rate_limit_us" 2>/dev/null
  done
  setprop persist.sys.wifi.power_save false
  setprop wifi.ps.mode 0
  setprop persist.env.fastdorm.enabled false
  setprop persist.vendor.radio.fd.disable 1
}

# ── PROFILE: BALANCED ─────────────────────────────────────────────────────────
apply_balanced() {
  sysctl -w net.core.rmem_max=33554432                     2>/dev/null
  sysctl -w net.core.wmem_max=33554432                     2>/dev/null
  sysctl -w net.ipv4.tcp_rmem="4096 524288 33554432"       2>/dev/null
  sysctl -w net.ipv4.tcp_wmem="4096 524288 33554432"       2>/dev/null
  sysctl -w net.ipv4.tcp_congestion_control=bbr            2>/dev/null
  sysctl -w net.ipv4.tcp_timestamps=1                      2>/dev/null
  sysctl -w net.ipv4.tcp_mtu_probing=1                     2>/dev/null
  sysctl -w net.ipv4.tcp_slow_start_after_idle=1           2>/dev/null
  sysctl -w net.core.netdev_budget=400                     2>/dev/null
  sysctl -w net.core.netdev_max_backlog=16384              2>/dev/null
  sysctl -w net.netfilter.nf_conntrack_max=500000          2>/dev/null
  for IF in $(ip -o link show up 2>/dev/null | awk -F': ' '{gsub(/@.*/,"",$2);print $2}' | grep -vE "^lo$|^dummy|^ip6"); do
    [ "$(iw dev "$IF" info 2>/dev/null | grep -c "type AP")" -gt "0" ] && continue
    tc qdisc del dev "$IF" root 2>/dev/null
    tc qdisc add dev "$IF" root fq_codel 2>/dev/null
    ethtool -C "$IF" rx-usecs 100 tx-usecs 100 rx-frames 16 2>/dev/null
  done
  for DIR in /sys/devices/system/cpu/cpu*/cpufreq/schedutil/; do
    N=$(echo "$DIR" | grep -o 'cpu[0-9]*' | tr -dc '0-9')
    [ "$N" -ge "$HALF" ] 2>/dev/null || continue
    echo 200  > "${DIR}up_rate_limit_us"   2>/dev/null
    echo 1000 > "${DIR}down_rate_limit_us" 2>/dev/null
  done
  setprop persist.sys.wifi.power_save false
  setprop wifi.ps.mode 0
  setprop persist.env.fastdorm.enabled false
  setprop persist.vendor.radio.fd.disable 0
}

# ── PROFILE: BATTERY SAVER ────────────────────────────────────────────────────
apply_battery() {
  sysctl -w net.core.rmem_max=16777216                     2>/dev/null
  sysctl -w net.core.wmem_max=16777216                     2>/dev/null
  sysctl -w net.ipv4.tcp_rmem="4096 262144 16777216"       2>/dev/null
  sysctl -w net.ipv4.tcp_wmem="4096 262144 16777216"       2>/dev/null
  sysctl -w net.ipv4.tcp_congestion_control=cubic          2>/dev/null
  sysctl -w net.ipv4.tcp_timestamps=1                      2>/dev/null
  sysctl -w net.ipv4.tcp_mtu_probing=0                     2>/dev/null
  sysctl -w net.ipv4.tcp_slow_start_after_idle=1           2>/dev/null
  sysctl -w net.core.netdev_budget=300                     2>/dev/null
  sysctl -w net.core.netdev_max_backlog=8192               2>/dev/null
  sysctl -w net.netfilter.nf_conntrack_max=65536           2>/dev/null
  for IF in $(ip -o link show up 2>/dev/null | awk -F': ' '{gsub(/@.*/,"",$2);print $2}' | grep -vE "^lo$|^dummy|^ip6"); do
    [ "$(iw dev "$IF" info 2>/dev/null | grep -c "type AP")" -gt "0" ] && continue
    tc qdisc del dev "$IF" root 2>/dev/null
    tc qdisc add dev "$IF" root fq_codel 2>/dev/null
    ethtool -C "$IF" rx-usecs 200 tx-usecs 200 rx-frames 8 2>/dev/null
  done
  for DIR in /sys/devices/system/cpu/cpu*/cpufreq/schedutil/; do
    echo 500  > "${DIR}up_rate_limit_us"   2>/dev/null
    echo 2000 > "${DIR}down_rate_limit_us" 2>/dev/null
  done
  setprop persist.sys.wifi.power_save true
  setprop wifi.ps.mode 1
  setprop persist.env.fastdorm.enabled true
  setprop persist.vendor.radio.fd.disable 0
}

# ── EXECUTE ───────────────────────────────────────────────────────────────────
case "$SELECTED" in
  performance) apply_performance ;;
  balanced)    apply_balanced    ;;
  battery)     apply_battery     ;;
esac

echo "$SELECTED" > "$PROFILE_FILE"
ACTIVE_IDX=$IDX

# ── RESULT ────────────────────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ $(label $IDX) Applied"
echo ""
case "$SELECTED" in
  performance)
    echo "  Buffers    : 64MB      NAPI  : 600"
    echo "  CC         : BBR       qdisc : fq"
    echo "  IRQ        : 50µs/32f  CT    : 2M"
    echo "  Schedutil  : 0µs       WiFi  : OFF"
    echo "  Dormancy   : OFF"
    ;;
  balanced)
    echo "  Buffers    : 32MB      NAPI  : 400"
    echo "  CC         : BBR       qdisc : fq_codel"
    echo "  IRQ        : 100µs/16f CT    : 500K"
    echo "  Schedutil  : 200µs     WiFi  : Light"
    echo "  Dormancy   : Soft"
    ;;
  battery)
    echo "  Buffers    : 16MB      NAPI  : 300"
    echo "  CC         : Cubic     qdisc : fq_codel"
    echo "  IRQ        : 200µs/8f  CT    : 65K"
    echo "  Schedutil  : 500µs     WiFi  : ON"
    echo "  Dormancy   : ON"
    ;;
esac
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log "Profile → $SELECTED"
