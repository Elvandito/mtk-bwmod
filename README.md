# MTK Extreme Bandwidth Mod

> Universal Magisk module for **all MediaTek devices**  
> Helio G / P / X · Dimensity · MT6xxx · MT8xxx

Pure network optimization — WiFi, LTE, NR/5G, TCP, VoLTE, data connectivity.  
No GPU/audio/memory tweaks. Network only.

---

## Features

### `system.prop` — 14 Sections (~270 props)

| # | Section | What it does |
|---|---------|-------------|
| 01 | LTE Carrier Aggregation | Forces CA on uplink + downlink, increases LTE.lteca cap |
| 02 | MTK Baseband & RIL | Baseband optimization, AMR wideband, HSDPA cat 24 |
| 03 | Fast Dormancy Disabled | Disables modem sleep for lower latency/ping |
| 04 | WiFi Power Save Off | Disables all WiFi power limits, 2.4+5GHz aggregation, WiFi 6/6E (HE/TWT/MBO/OCE/SAE) |
| 05 | TCP Buffer Sizes | Buffers up to 64MB for NR, 32MB for WiFi |
| 06 | HW Offloading | GRO hardware offload, disables modem/WiFi debug logging |
| 07 | DNS Cloudflare | Forces 1.1.1.1 on rmnet0, rmnet1, and base |
| 08 | Network Hints & QoS | iWLAN, QoS, high-bandwidth preference, netmgrd |
| 09 | NR/5G Force | SA + NSA, all global bands, default network mode 26 |
| 10 | MTK Universal Stack | ConnSys auto-detect, multi-RAT, IMS/VoLTE/WFC/ViLTE full stack, DSDS |
| 11 | LTE-A + NR Extended | EN-DC, MIMO, 256QAM, HARQ, beam management, PDCP ROHC, BWP timer |
| 12 | VoLTE / VoNR | HD Voice + 5G calling, WFC, debug override |
| 13 | Connectivity & Stall Recovery | Data stall detection, PDCP/RLC aggregation, RRC timers, keepalive |
| 14 | Mobile Data Optimization | MTU 1500, DL/UL batch 64/32 packets, packet scheduler, signal threshold |

### `service.sh` — 9 Sections (runs every boot)

| # | Section | What it does |
|---|---------|-------------|
| 1 | Radio props | Re-applies NR/CA/MIMO/EN-DC after modem init |
| 2 | IMS/VoLTE/WFC | Re-applies full IMS stack props after boot |
| 3 | TCP/BBR | BBR congestion control, 32MB buffers, fastopen, keepalive |
| 4 | UDP/QUIC | UDP buffer 64K min, QUIC-ready |
| 5 | WiFi runtime | Power save off, 5GHz preferred, roaming trigger -75dBm |
| 6 | DNS override | Cloudflare 1.1.1.1 on all active interfaces (overrides DHCP) |
| 7 | Network IRQ affinity | Binds wlan/modem IRQs to big CPU cores (adaptive mask per core count) |
| 8 | Data stall recovery | Runtime keepalive + PSM disabled |
| 9 | txqueuelen + RPS | Sets txqueuelen=3000 on all interfaces, RPS on rmnet |

---

## Device Support

Automatically detected at install. **Aborts on non-MTK hardware.**

| Detection Method | Property / Path |
|-----------------|-----------------|
| Platform string | `ro.board.platform` starts with `mt` |
| Vendor platform | `ro.vendor.mediatek.platform` starts with `mt` |
| Hardware | `ro.hardware` starts with `mt` |
| SoC model | `ro.soc.model` starts with `MT` |
| Dimensity | `ro.soc.model` contains `Dimensity` |
| MTK battery | `/proc/mtk_battery_cmd` exists |
| MTK sysfs | `/sys/devices/platform/mediatek` exists |
| BT debug node | `/sys/kernel/debug/mtk_btcvsd` exists |
| MTK namespace | Any prop matching `*.mtk.*` |

Any **one** match → installation proceeds.

---

## Requirements

| | |
|---|---|
| **SoC** | Any MediaTek (Helio, Dimensity, MT-series) |
| **Root** | Magisk v24+ or KernelSU |
| **Android** | 10 and above |
| **ROM** | Any — AOSP, MIUI, HyperOS, ColorOS, custom |

---

## Installation

1. Download `mtk_bwmod.zip`
2. Magisk → Modules → Install from storage
3. Select the zip
4. Installer checks your SoC — aborts if not MTK
5. Reboot

---

## File Structure

```
mtk_bwmod/
├── META-INF/
│   └── com/google/android/
│       ├── update-binary
│       └── updater-script
├── module.prop
├── system.prop       ← 14 sections, ~270 props
├── customize.sh      ← 9-method MTK detection + install
├── service.sh        ← 9-section runtime boot service
└── README.md
```

---

## Log

```bash
adb shell cat /data/local/tmp/mtk_bwmod.log
```

---

## Disclaimer

These props and sysctl tweaks target MTK-specific modem/radio/WiFi firmware interfaces. Results vary by carrier, ROM, and chipset generation. No hardware is modified. Safe to remove by disabling/deleting the module.

---

## License

MIT — free to use, modify, and redistribute.
