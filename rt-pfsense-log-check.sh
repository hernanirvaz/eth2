#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0-CURRENT

case "$1" in
    *[!0-9]*) f="$1"    ;i=${2:-0};g='' ;;               
    *)        f="system";i=${1:-0};g='logged|login|sshd' ;;
esac

echo $(date -v -${i}H '+%Y-%m-%d %H'):00:00 $f log from $i hours ago
while [ "$i" -ge 0 ]; do
    grep "$(date -v -${i}H '+%b %e %H')" /var/log/$f.log* | if [ -z "$g" ]; then cat;else grep -Ev "$g";fi
    i=$((i - 1))
done;echo

b=$(sysctl -n kern.boottime | cut -d" " -f4 | cut -d"," -f1)
d=$(($(date +%s) - b))
h=$((d / 3600))
m=$(((d % 3600) / 60))
echo $(date +"%Y-%m-%d %H:%M:%S") uptime: $h hours $m minutes
