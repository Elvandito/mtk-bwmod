#!/system/bin/sh
# =============================================================================
# MTK Extreme Bandwidth Mod v1.8 — post-fs-data.sh
# Runs at post-fs-data stage — VERY early boot, before modem/WiFi init
# Purpose: set kernel net params before any network interface comes up
#          so values are in effect from first packet, not retrofitted
# =============================================================================

# Wait for basic fs mount — no sleep needed, this IS post-fs-data
LOG="/cache/mtk_bwmod_early.log"
log() { echo "[$(date '+%H:%M:%S')] [EARLY] $*" >> "$LOG" 2>/dev/null; }
log "post-fs-data started"

# ── 1. NET CORE TUNABLES (early, before interfaces exist) ──────────────────────
# These must be set before interfaces up — kernel uses them at interface creation

# Increase default socket buffer (applied to ALL new sockets from boot)
echo 4194304   > /proc/sys/net/core/rmem_default
echo 4194304   > /proc/sys/net/core/wmem_default
echo 67108864  > /proc/sys/net/core/rmem_max
echo 67108864  > /proc/sys/net/core/wmem_max

# Increase global socket memory (sum across all sockets)
# mem = min / pressure / max in pages (4096 bytes/page)
echo "4096 1048576 33554432" > /proc/sys/net/ipv4/tcp_mem
echo "4096 1048576 33554432" > /proc/sys/net/ipv4/udp_mem

# Optimal initial TCP window (10 segments = ~14KB, RFC 6928 compliant)
echo 10 > /proc/sys/net/ipv4/tcp_init_cwnd         2>/dev/null
echo 10 > /proc/sys/net/ipv4/tcp_default_init_rwnd  2>/dev/null

# ── 2. ARP TUNING (reduces ARP table thrash on mobile — IP changes often) ──────
echo 1024 > /proc/sys/net/ipv4/neigh/default/gc_thresh1
echo 2048 > /proc/sys/net/ipv4/neigh/default/gc_thresh2
echo 4096 > /proc/sys/net/ipv4/neigh/default/gc_thresh3
echo 30   > /proc/sys/net/ipv4/neigh/default/gc_stale_time

# ── 3. SOURCE ROUTING & SECURITY (safe network hardening) ─────────────────────
echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
echo 0 > /proc/sys/net/ipv4/conf/default/accept_source_route
echo 1 > /proc/sys/net/ipv4/conf/all/arp_announce
echo 2 > /proc/sys/net/ipv4/conf/all/arp_filter    2>/dev/null

# ── 4. IPV6 OPTIMIZATION ──────────────────────────────────────────────────────
# Increase IPv6 neighbor table (critical for IPv6-only LTE/5G APNs)
echo 1024 > /proc/sys/net/ipv6/neigh/default/gc_thresh1  2>/dev/null
echo 2048 > /proc/sys/net/ipv6/neigh/default/gc_thresh2  2>/dev/null
echo 4096 > /proc/sys/net/ipv6/neigh/default/gc_thresh3  2>/dev/null
# Accelerate IPv6 temp address rotation (privacy)
echo 3600 > /proc/sys/net/ipv6/conf/all/temp_preferred_lft 2>/dev/null

# ── 5. TCP EARLY PARAMS (set before stack handles first connection) ───────────
echo 1    > /proc/sys/net/ipv4/tcp_syn_cookies
echo 1    > /proc/sys/net/ipv4/tcp_window_scaling
echo 1    > /proc/sys/net/ipv4/tcp_sack
echo 1    > /proc/sys/net/ipv4/tcp_fack
echo 1    > /proc/sys/net/ipv4/tcp_ecn
echo 1    > /proc/sys/net/ipv4/tcp_ecn_fallback
echo 3    > /proc/sys/net/ipv4/tcp_fastopen
echo 0    > /proc/sys/net/ipv4/tcp_slow_start_after_idle

# ── 6. RMNET SOCKET MARKS (MTK modem uses socket marks for routing) ──────────
# Ensure SO_MARK-based routing works for rmnet0/1 interfaces
echo 1 > /proc/sys/net/ipv4/conf/all/mc_forwarding     2>/dev/null
echo 1 > /proc/sys/net/ipv4/ip_nonlocal_bind            2>/dev/null

# ── 7. KERNEL MEMORY / NAPI EARLY SETUP ──────────────────────────────────────
echo 600   > /proc/sys/net/core/netdev_budget
echo 4000  > /proc/sys/net/core/netdev_budget_usecs   2>/dev/null
echo 32768 > /proc/sys/net/core/netdev_max_backlog
echo 32768 > /proc/sys/net/core/rps_sock_flow_entries  2>/dev/null

# ── 8. MTK CCCI / MODEM INTERFACE HINTS ──────────────────────────────────────
# Prefer full fragmentation on rmnet (modem handles reassembly in hardware)
echo 1 > /proc/sys/net/ipv4/ip_no_pmtu_disc 2>/dev/null

log "post-fs-data complete — $(date '+%H:%M:%S')"
