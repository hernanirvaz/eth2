#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0
# Target: WAN interface health & recovery (igc0) - Disaster Recovery Watchdog
# Schedule: */5 * * * * root /root/rt-pfsense-wan-check.sh

DNL='/dev/null'
FIL="/root/wan-check"
WAN="igc0"
ONT="192.168.1.254"
DNS="8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112 208.67.222.222 208.67.220.220"

if [ -z "$WCL" ]; then export WCL=1;exec lockf -s -k -t 0 "${FIL}.lck" "$0" "$@";fi
WIP=$(/root/rt-pfsense-ip.sh ip4);[ -z "$WIP" ] && WIP="82.155.244.204"
read -r MEP < /root/.meo 2>$DNL
grn() { set -- $DNS; eval "echo \${$(jot -r 1 1 $#)}"; }
lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "${FIL}.log" 2>&1; }
pig() { ping -c $2 -o -W 1000 $1    > $DNL 2>&1;local e=$?;[ $e -ne 0 ] && lgm "ping -c$2 -o -W1000 $1 erro($e)";return $e; }
ifd() { ifconfig    $WAN down       > $DNL 2>&1;local h=$?;[ $h -ne 0 ] && lgm "Failed to bring $WAN down."     ;return $h; }  
ifu() { ifconfig    $WAN up         > $DNL 2>&1;local i=$?;[ $i -ne 0 ] && lgm "Failed to bring $WAN up."       ;return $i; }
dtn() { 
    local j w r
    # 1. Gracefully stop current daemons and wait for exit
    killall -15 dhclient dhcp6c > "$DNL" 2>&1
    w=0;while { pgrep -q dhclient || pgrep -q dhcp6c; } && [ "$w" -lt 15 ];do sleep 0.2;w=$((w + 1));done
    { pgrep -q dhclient || pgrep -q dhcp6c; } && killall -9 dhclient dhcp6c > "$DNL" 2>&1
    r=$(ls /var/run/dhc[lp][i6][ec]*.pid 2>$DNL);[ -n "$r" ] && rm -f $r > "$DNL" 2>&1
    arp -d -i "$WAN" -a > "$DNL" 2>&1
    if [ -n "$WIP" ]; then
        pfctl -k "$WIP"              > "$DNL" 2>&1
        pfctl -k 0.0.0.0/0 -k "$WIP" > "$DNL" 2>&1
    fi
    # 2. Reload WAN for IPv4 (dhclient) via native pfSense IPC & Explicitly start dhcp6c daemon (required because LAN is Static IPv6, bypassing pfSense track6)
    pfSctl -c "interface reload wan" > "$DNL" 2>&1
    w=0;while ! pgrep -q dhclient && [ "$w" -lt 10 ];do sleep 1;w=$((w + 1));done
    if ! pgrep -q dhcp6c; then dhcp6c -D -n -c /var/etc/dhcp6c.conf -p /var/run/dhcp6c.pid "$WAN" > "$DNL" 2>&1;fi
    w=0;while { ! pgrep -q dhclient || ! pgrep -q dhcp6c; } && [ "$w" -lt 15 ];do sleep 1;w=$((w + 1));done
    if pgrep -q dhclient && pgrep -q dhcp6c;then j=0;else j=1;lgm "[ERROR] Failed to start WAN daemons (dhclient/dhcp6c) on $WAN within 25s.";fi
    return "$j"
}
mer() { ( echo "meo";sleep 2;echo "$MEP";sleep 3;echo "management/reboot";sleep 3;echo "Y";sleep 6 ) | nc -N -w 15 $ONT 23 > $DNL 2>&1;local k=$?;[ $k -ne 0 ] && lgm "Failed to reboot GR241AG.";return $k; } 
pit() { pig $(grn) 5 || pig $(grn) 6 || pig $(grn) 7 || pig $(grn) 8 || pig $(grn) 9 || pig $(grn) 10; }

if pit;then exit 0;fi
ifd;sleep 5;ifu;sleep 45
if pit;then lgm "WAN recovered after physical bounce.";exit 0;fi
dtn;sleep 45
if pit;then lgm "WAN recovered after daemon/state reset.";exit 0;fi
mer;sleep 180;dtn;sleep 45
if pit;then lgm "WAN recovered after GR241AG reboot.";exit 0;fi
lgm "[CRITICAL] Upstream MEO FTTH outage confirmed.";exit 1
