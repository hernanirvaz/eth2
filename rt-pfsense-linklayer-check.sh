#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0 Link-Layer Static Binding Enforcer
# Target: LAN interface (igc1)
# Triggers:
#   - afterfilterchangeshellcmd: /root/rt-pfsense-linklayer-check.sh
#   - Services Cron: */30 * * * * root /root/rt-pfsense-linklayer-check.sh

DNL='/dev/null'
FIL="/root/linklayer-check"

if [ -z "$LLL" ]; then export LLL=1;exec /usr/bin/lockf -s -k -t 0 "${FIL}.lck" "$0" "$@";fi
lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "${FIL}.log" 2>&1; }
far() { local i m h e;i="$1";m="$2";h="$3";e=$(arp -n "$i" 2>"$DNL");if ! echo "$e" | grep -q "permanent"; then arp -S "$i" "$m" > "$DNL" 2>&1 || lgm "[ERROR] Failed to set IPv4 ARP for ${h}: ${i} -> ${m}";fi; }
fnd() { local i m h e;i="$1";m="$2";h="$3";e=$(ndp -n "$i" 2>"$DNL");if ! echo "$e" | grep -q "permanent"; then ndp -s "$i" "$m" > "$DNL" 2>&1 || lgm "[ERROR] Failed to set IPv6 NDP for ${h}: ${i} -> ${m}";fi; }

far "192.168.8.37"             "48:21:0b:55:40:76" "hrv-intel5"
fnd "2001:8a0:fcd9:4500::1005" "48:21:0b:55:40:76" "hrv-intel5"
far "192.168.8.40"             "48:21:0b:52:6c:5e" "hrv-intel6"
fnd "2001:8a0:fcd9:4500::1006" "48:21:0b:52:6c:5e" "hrv-intel6"
far "192.168.8.34"             "00:01:2e:a4:f0:4c" "hrv-zotac4"
fnd "2001:8a0:fcd9:4500::1004" "00:01:2e:a4:f0:4c" "hrv-zotac4"
far "192.168.8.31"             "00:01:2e:a0:88:ea" "hrv-zotac3"
fnd "2001:8a0:fcd9:4500::1003" "00:01:2e:a0:88:ea" "hrv-zotac3"
far "192.168.8.28"             "00:01:2e:a0:e0:6f" "hrv-zotac2"
fnd "2001:8a0:fcd9:4500::1002" "00:01:2e:a0:e0:6f" "hrv-zotac2"
exit 0