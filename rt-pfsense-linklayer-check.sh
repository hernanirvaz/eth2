#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0
# Link-Layer Static Binding Enforcer
# Triggers:
#   - afterfilterchangeshellcmd: /root/rt-pfsense-linklayer-check.sh
#   - Services Cron: */30 * * * * root /root/rt-pfsense-linklayer-check.sh

DNL='/dev/null'
FIL="/var/run/linklayer-check"

if [ -z "$LLL" ]; then export LLL=1;exec lockf -s -k -t 0 "${FIL}.lck" "$0" "$@";fi
ARP="$(arp -an 2>$DNL)"
NDP="$(ndp -an 2>$DNL)"
MPD=$(/root/rt-pfsense-ip.sh ipd) # 2001:8a0:fcef:ac00

lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "${FIL}.log" 2>&1; }
far() { if ! echo "$ARP" | grep -q "^?[[:space:]]($1)[[:space:]].*igc1[[:space:]][[:space:]]*permanent";then arp -S "$1" "$2" > $DNL 2>&1 || lgm "[ERROR] Failed to set IPv4 ARP for $3: $1 -> $2";fi; }
fnd() { if ! echo "$NDP" | grep -q "^$1[[:space:]].*igc1[[:space:]][[:space:]]*permanent"              ;then ndp -s "$1" "$2" > $DNL 2>&1 || lgm "[ERROR] Failed to set IPv6 NDP for $3: $1 -> $2";fi; }

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
