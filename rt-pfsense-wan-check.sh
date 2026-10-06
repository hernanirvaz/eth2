#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0
# Target: WAN interface health & recovery (igc0)
# Schedule: */5 * * * * root /root/rt-pfsense-wan-check.sh

DNL='/dev/null'
FIL="/root/wan-check"
WAN="igc0"
DNS="8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112 208.67.222.222 208.67.220.220 64.6.64.6 209.244.0.3 209.244.0.4 84.200.69.80 84.200.70.40 94.140.14.140 94.140.14.141 8.26.56.26 8.20.247.20 185.228.168.9"

if [ -z "$WCL" ]; then export WCL=1;exec /usr/bin/lockf -s -k -t 0 "${FIL}.lck" "$0" "$@";fi
grn() { set -- $DNS; eval "echo \${$(jot -r 1 1 $#)}"; }
lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "${FIL}.log" 2>&1; }
pig() { ping -c $2 -W 4 $1         > $DNL 2>&1;local e=$?;[ $e -ne 0 ] && lgm "ping -c$2 -W4 $1 erro ($e)";return $e; }
ifd() { ifconfig    $WAN down      > $DNL 2>&1;local h=$?;[ $h -ne 0 ] && lgm "Failed to bring $WAN down.";return $h; }  
ifu() { ifconfig    $WAN up        > $DNL 2>&1;local i=$?;[ $i -ne 0 ] && lgm "Failed to bring $WAN up."  ;return $i; }
rex() { lgm "$1";/etc/rc.reboot    > $DNL 2>&1;exit 1; }  
pit() { pig $(grn) 5 || pig $(grn) 6 || pig $(grn) 7 || pig $(grn) 8 || pig $(grn) 9 || pig $(grn) 10; }

if pit;then exit 0;fi
ifd;sleep 5;ifu;sleep 45
if pit;then lgm "WAN recovered after bounce.";exit 0;fi
rex "Performing reboot as last resort."