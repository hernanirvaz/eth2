#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0-CURRENT

flg() {
    local m d t r i
    while read -r m d t r; do
    # Use FreeBSD date -j (don't set) -f (input format) to parse and reformat
    # If the input year is missing, BSD date assumes the current year.
    i=$(date -j -f "%b %d %T" "$m $d $t" "+%Y-%m-%d %T" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "$i $r"
    else
        echo "$m $d $t $r"
    fi
done
}
lsw() { 
    local n=$1 f="$2";shift 2;[ -s "$1" ] || return 0
    echo "$(date -v -${n}H "+$f %H")":00:00 $(basename $1) from $n hours ago
    while [ "$n" -ge 0 ]; do
        grep "$(date -v -${n}H "+$f %H")" -h $@ 
        n=$((n - 1))
    done;echo    
 }

case "$1" in
    *[!0-9]*) f="$1"    ;i=${2:-0};g='' ;;               
    *)        f="system";i=${1:-0};g='logged|login|sshd' ;;
esac

lsw $((i * 2)) '%Y-%m-%d' /root/wan-check.log
if [ "$1" = "logs" ]; then
    (
      lsw $((i + 0)) '%b %e' /var/log/dhcpd.log* 
      lsw $((i + 0)) '%b %e' /var/log/system.log*
    ) | grep -Ev 'logged|login|sshd' | flg | sort
else
    lsw $((i + 0)) '%b %e'   /var/log/$f.log* | if [ -z "$g" ]; then cat;else grep -Ev "$g";fi | flg
fi

b=$(sysctl -n kern.boottime | cut -d" " -f4 | cut -d"," -f1)
d=$(($(date +%s) - b))
h=$((d / 3600))
m=$(((d % 3600) / 60))
echo $(date +"%Y-%m-%d %H:%M:%S") uptime: $h hours $m minutes
