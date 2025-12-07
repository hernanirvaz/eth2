#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0-CURRENT

echo last reboot
last reboot|head -n5|sed "s%  *% %g"|sort -k5n

echo wan check log
tail -n15 /root/wan-check.log

echo last hours system log
HOURS=${1:-0}
i=$HOURS
while [ "$i" -ge 0 ]; do
    grep "$(date -v -${i}H '+%b %e %H')" /var/log/system.log | grep -Ev 'index.php|sshd'
    i=$((i - 1))
done

echo
date +"%Y-%m-%d %H:%M:%S"