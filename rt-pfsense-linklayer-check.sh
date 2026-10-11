#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0 Link-Layer Static Binding Enforcer
# Target: LAN interface (igc1)
# Triggers:
#   - afterfilterchangeshellcmd: /root/rt-pfsense-linklayer-check.sh
#   - Services Cron: */30 * * * * root /root/rt-pfsense-linklayer-check.sh

DNL='/dev/null'
FIL="/root/linklayer-check"

if [ -z "$LLL" ]; then export LLL=1;exec /usr/bin/lockf -s -k -t 0 "${FIL}.lck" "$0" "$@";fi
# Under afterfilterchangeshellcmd early system boot, runs before dhcp6c on WAN completes
MPD=$(/root/rt-pfsense-ip.sh ip6) # 2001:8a0:fcef:ac00
[ -z "$MPD" ] && MPD="2001:8a0:fcef:ac00"
lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "${FIL}.log" 2>&1; }
far() { if ! arp -n "$1" 2>"$DNL" | grep -q "permanent"; then arp -S "$1" "$2" > "$DNL" 2>&1 || lgm "[ERROR] Failed to set IPv4 ARP for $3: $1 -> $2";fi; }
fnd() { if ! ndp -n "$1" 2>"$DNL" | grep -q "permanent"; then ndp -s "$1" "$2" > "$DNL" 2>&1 || lgm "[ERROR] Failed to set IPv6 NDP for $3: $1 -> $2";fi; }

far "192.168.8.37" "48:21:0b:55:40:76" "hrv-intel5"
fnd "$MPD::1005"   "48:21:0b:55:40:76" "hrv-intel5"
far "192.168.8.40" "48:21:0b:52:6c:5e" "hrv-intel6"
fnd "$MPD::1006"   "48:21:0b:52:6c:5e" "hrv-intel6"
far "192.168.8.34" "00:01:2e:a4:f0:4c" "hrv-zotac4"
fnd "$MPD::1004"   "00:01:2e:a4:f0:4c" "hrv-zotac4"
far "192.168.8.31" "00:01:2e:a0:88:ea" "hrv-zotac3"
fnd "$MPD::1003"   "00:01:2e:a0:88:ea" "hrv-zotac3"
far "192.168.8.28" "00:01:2e:a0:e0:6f" "hrv-zotac2"
fnd "$MPD::1002"   "00:01:2e:a0:e0:6f" "hrv-zotac2"
exit 0
