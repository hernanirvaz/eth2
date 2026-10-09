#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0
# Target: WAN interface health & recovery (igc0)
# Schedule: */5 * * * * root /root/rt-pfsense-wan-check.sh

DNL='/dev/null'
FIL="/root/wan-check"
WAN="igc0"
ONT="192.168.1.254"
DNS="8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112 208.67.222.222 208.67.220.220 64.6.64.6 209.244.0.3 209.244.0.4 84.200.69.80 84.200.70.40 94.140.14.140 94.140.14.141 8.26.56.26 8.20.247.20 185.228.168.9"

if [ -z "$WCL" ]; then export WCL=1;exec /usr/bin/lockf -s -k -t 0 "${FIL}.lck" "$0" "$@";fi
read -r MEP < /root/.meo 2>$DNL
grn() { set -- $DNS; eval "echo \${$(jot -r 1 1 $#)}"; }
lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "${FIL}.log" 2>&1; }
pig() { ping -c $2 -W 1000 $1      > $DNL 2>&1;local e=$?;[ $e -ne 0 ] && lgm "ping -c$2 -W1000 $1 erro($e)";return $e; }
ifd() { ifconfig    $WAN down      > $DNL 2>&1;local h=$?;[ $h -ne 0 ] && lgm "Failed to bring $WAN down."  ;return $h; }  
ifu() { ifconfig    $WAN up        > $DNL 2>&1;local i=$?;[ $i -ne 0 ] && lgm "Failed to bring $WAN up."    ;return $i; }
dtr() { killall -9 dhclient dhcp6c > $DNL 2>&1;arp -d -i $WAN -a > $DNL 2>&1;pfctl -i $WAN -F state > $DNL 2>&1;pfSctl -c "interface reload wan" > $DNL 2>&1;local j=$?;[ $j -ne 0 ] && lgm "Failed to reload $WAN interface.";return $j; }
mer() { ( echo "meo";sleep 2;echo "$MEP";sleep 3;echo "management/reboot";sleep 3;echo "Y";sleep 6 ) | nc -N -w 15 $ONT 23 > $DNL 2>&1;local k=$?;[ $k -ne 0 ] && lgm "Failed to reboot GR241AG.";return $k; } 
pit() { pig $(grn) 5 || pig $(grn) 6 || pig $(grn) 7; }

if pit;then exit 0;fi
ifd;sleep 5;ifu;sleep 45
if pit;then lgm "WAN recovered after physical bounce.";exit 0;fi
dtr;sleep 45
if pit;then lgm "WAN recovered after daemon/state reset.";exit 0;fi
mer;sleep 180;dtr;sleep 45
if pit;then lgm "WAN recovered after GR241AG reboot.";exit 0;fi
lgm "[CRITICAL] Upstream MEO FTTH outage confirmed.";exit 1
