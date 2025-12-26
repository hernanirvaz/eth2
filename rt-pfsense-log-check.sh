#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0-CURRENT

echo last reboot
last reboot|head -n5|sed "s%  *% %g"|sort -k5n

echo wan check log
tail -n15 /root/wan-check.log

case "$1" in
    *[!0-9]*) f="$1"    ;i=${2:-0};g=''               ;;
    *)        f="system";i=${1:-0};g='index.php|sshd' ;;
esac

echo $(date -v -${i}H '+%b %e %H'):??:?? init grep $f log
while [ "$i" -ge 0 ]; do
    grep "$(date -v -${i}H '+%b %e %H')" "/var/log/$f.log" | if [ -z "$g" ]; then cat;else grep -Ev "$g";fi
    i=$((i - 1))
done

echo
date +"%Y-%m-%d %H:%M:%S"