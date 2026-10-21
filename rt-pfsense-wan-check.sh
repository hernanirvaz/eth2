#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0
# Target: WAN interface health & recovery (igc0) - Disaster Recovery Watchdog
# Schedule: */5 * * * * root /root/rt-pfsense-wan-check.sh

DNL='/dev/null'
FIL="/var/run/wan-check"
WAN="igc0"
ONT="192.168.1.254"
DN4="8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112 208.67.222.222 208.67.220.220"
DN6="2001:4860:4860::8888 2606:4700:4700::1111"

if [ -z "$WCL" ]; then export WCL=1;exec lockf -s -k -t 0 "${FIL}.lck" "$0" "$@";fi
WIP=$(/root/rt-pfsense-ip.sh ip4)
read -r MEP < /root/.meo 2>$DNL
lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "${FIL}.log" 2>&1; }
pig() { ping -c $2 -o -W 1000 $1 > $DNL 2>&1; }
gr4() { set -- $DN4; eval "echo \${$(jot -r 1 1 $#)}"; }
gr6() { set -- $DN6; eval "echo \${$(jot -r 1 1 $#)}"; }
pi4() { pig $(gr4) 5 || pig $(gr4) 6 || pig $(gr4) 7 || pig $(gr4) 8 || pig $(gr4) 9 || pig $(gr4) 10; }
pi6() { pig $(gr6) 3 || pig $(gr6) 5 || pig $(gr6) 7; }
sfc() { local i;sysctl dev.igc.0.fc=0 > $DNL 2>&1;i=$?;[ $i -ne 0 ] && lgm "Failed to reset flow control.";return $i; }
ifu() { local i;ifconfig $WAN up      > $DNL 2>&1;i=$?;[ $i -ne 0 ] && lgm "Failed to bring $WAN up.";sfc;i=$((i + $?));return $i; }
ifd() { local i;ifconfig $WAN down    > $DNL 2>&1;i=$?;[ $i -ne 0 ] && lgm "Failed to bring $WAN down."                ;return $i; }  
sd6() { cp /root/rt-pfsense-dhcp6c.conf /var/etc/dhcp6c.conf > "$DNL" 2>&1;dhcp6c -D -n -c /var/etc/dhcp6c.conf -p /var/run/dhcp6c.pid "$WAN" > "$DNL" 2>&1; }
dtn() { 
    local j w r
    killall -15 dhclient dhcp6c > "$DNL" 2>&1
    w=0;while { pgrep -q dhclient || pgrep -q dhcp6c; } && [ "$w" -lt 15 ];do sleep 0.2;w=$((w + 1));done
    { pgrep -q dhclient || pgrep -q dhcp6c; } && killall -9 dhclient dhcp6c > "$DNL" 2>&1
    r=$(ls /var/run/dhc[lp][i6][ec]*.pid 2>$DNL);[ -n "$r" ] && rm -f $r > "$DNL" 2>&1
    arp -d -i "$WAN" -a > "$DNL" 2>&1
    if [ -n "$WIP" ]; then
        pfctl -k "$WIP"              > "$DNL" 2>&1
        pfctl -k 0.0.0.0/0 -k "$WIP" > "$DNL" 2>&1
    fi
    pfSctl -c "interface reload wan" > "$DNL" 2>&1
    w=0;while ! pgrep -q dhclient && [ "$w" -lt 10 ];do sleep 1;w=$((w + 1));done
    if pgrep -q dhclient && ! pgrep -q dhcp6c;then sd6;fi
    w=0;while pgrep -q dhclient && ! pgrep -q dhcp6c && [ "$w" -lt 15 ];do sleep 1;w=$((w + 1));done
    if pgrep -q dhclient && pgrep -q dhcp6c;then sfc;j=$?;else j=1;lgm "[ERROR] Failed to start WAN daemons (dhclient/dhcp6c) on $WAN within 25s.";fi
    return "$j"
}
mer() { ( echo "meo";sleep 2;echo "$MEP";sleep 3;echo "management/reboot";sleep 3;echo "Y";sleep 6 ) | nc -N -w 15 $ONT 23 > $DNL 2>&1;local k=$?;[ $k -ne 0 ] && lgm "Failed to reboot GR241AG.";return $k; } 
pit() { pi4 && pi6; }

if pit;then exit 0;else lgm "[ERROR] Probing failed across all 6 stages. Initiating Layer 1 recovery.";fi
ifd;sleep 5;ifu;sleep 45
if pit;then lgm "WAN recovered after physical bounce.";exit 0;fi
dtn;sleep 45
if pit;then lgm "WAN recovered after daemon/state reset.";exit 0;fi
mer;sleep 180;dtn;sleep 45
if pit;then lgm "WAN recovered after GR241AG reboot.";exit 0;fi
lgm "[CRITICAL] Upstream MEO FTTH outage confirmed.";exit 1
