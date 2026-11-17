#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0
# Cycles each port igc[0123] (or specified port index) to clear CTRL.RFCE and CTRL.TFCE
# Triggers:
#   - shellcmd:                  /root/rt-pfsense-igc-fc.sh
#   - afterfilterchangeshellcmd: /root/rt-pfsense-igc-fc.sh
#   - inside                     /root/rt-pfsense-wan-check.sh

DNL='/dev/null'
LCK="/var/run/igc-fc.lck"

if [ -z "$IFL" ]; then export IFL=1;exec lockf -s -k -t 30 "$LCK" "$0" "$@";fi
[ "$#" -gt 0 ] && PTS="$@" || PTS="0 1 2 3"
e=0
for n in $PTS; do
    w=0
    while ! ifconfig "igc${n}" | grep -q "status: active" && [ "$w" -lt 15 ]; do
        sleep 1; w=$((w + 1))
    done
    sysctl "dev.igc.${n}.fc=3" > $DNL 2>&1 || e=1
    sysctl "dev.igc.${n}.fc=0" > $DNL 2>&1 || e=1
done
exit $e
