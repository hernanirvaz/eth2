#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0
# Cycles each port igc[0123] (or specified port index) to shows CTRL.RFCE and CTRL.TFCE

for n in 0 1 2 3; do
    c=$(sysctl -n "dev.igc.${n}.reg_dump" | grep -Eo 'CTRL[[:space:]]+[0-9a-fA-F]+' | head -1 | awk '{print $2}');v=$((0x$c))
    echo "igc${n} CTRL=0x${c} RFCE=$(( (v & 0x08000000) != 0 )) TFCE=$(( (v & 0x10000000) != 0 ))"
done
exit 0
