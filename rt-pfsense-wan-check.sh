#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0
# WAN interface health & recovery (igc0) - Disaster Recovery Watchdog
# Trigger: Services Cron: */5 * * * * root /root/rt-pfsense-wan-check.sh

DNL='/dev/null'
LCK="/var/run/wan-check.lck"
LOG="/root/wan-check.log"
WAN="igc0"
DN4="8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112 208.67.222.222 208.67.220.220"
DN6="2001:4860:4860::8888 2001:4860:4860::8844 2606:4700:4700::1111 2606:4700:4700::1001 2620:fe::fe 2620:fe::9 2a13:1001::86:54:11:1 2a13:1001::86:54:11:201"

if [ -z "$WCL" ]; then export WCL=1;exec lockf -s -k -t 0 "$LCK" "$0" "$@";fi
IP4=$(/root/rt-pfsense-ip.sh ip4) # 82.155.244.204
IP6=$(/root/rt-pfsense-ip.sh ipd) # 2001:8a0:fcef:ac00
lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "$LOG" 2>&1; }
pig() { ping -c $2 -o -W 1000 $1 > $DNL 2>&1; }
gr4() { set -- $DN4; eval "echo \${$(jot -r 1 1 $#)}"; }
gr6() { set -- $DN6; eval "echo \${$(jot -r 1 1 $#)}"; }
pi4() { pig $(gr4) 5 || pig $(gr4) 6 || pig $(gr4) 7 || pig $(gr4) 8 || pig $(gr4) 9 || pig $(gr4) 10; }
pi6() { pig $(gr6) 3 || pig $(gr6) 5 || pig $(gr6) 7; }
pit() { pi4 && pi6; }
sfc() { local i;/root/rt-pfsense-igc-fc.sh 0 > $DNL 2>&1;i=$?;[ $i -ne 0 ] && lgm "Failed to reset flow control."             ;return $i; }
ifu() { local i;ifconfig $WAN up             > $DNL 2>&1;i=$?;[ $i -ne 0 ] && lgm "Failed to bring $WAN up.";sfc;i=$((i + $?));return $i; }
ifd() { local i;ifconfig $WAN down           > $DNL 2>&1;i=$?;[ $i -ne 0 ] && lgm "Failed to bring $WAN down."                ;return $i; }  
sd6() { local f d;f='/root/rt-pfsense-dhcp6c.conf';d='/var/etc/dhcp6c.conf';[ -f "$f" ] && cp "$f" "$d" > $DNL 2>&1;dhcp6c -D -n -c "$d" -p /var/run/dhcp6c.pid "$WAN" > $DNL 2>&1; }
qd4() { pgrep -qx dhclient; }
qd6() { pgrep -qx dhcp6c  ; }
q46() { qd4 ||   qd6; }
qn6() { qd4 && ! qd6; }
t46() { qd4 &&   qd6; }
kd6() { local w=0;while   qd6 && [ "$w" -lt $1 ];do sleep 0.2;w=$((w + 1));done; }
k46() { local w=0;while   q46 && [ "$w" -lt $1 ];do sleep 0.2;w=$((w + 1));done; }
wd4() { local w=0;while ! qd4 && [ "$w" -lt $1 ];do sleep 1  ;w=$((w + 1));done; }
wd6() { local w=0;while   qn6 && [ "$w" -lt $1 ];do sleep 1  ;w=$((w + 1));done; }
ks6() { [ -n "$IP6" ] || return 0;pfctl -i "$WAN" -k "$IP6::/56" > $DNL 2>&1;pfctl -i "$WAN" -k ::/0 -k "$IP6::/56" > $DNL 2>&1; }
r6o() { killall -15 dhcp6c > $DNL 2>&1;kd6 15;qd6 && killall -9 dhcp6c > $DNL 2>&1;rm -f /var/run/dhcp6c*.pid > $DNL 2>&1;ks6;sd6; }
dtn() {
    local j
    killall -15 dhclient dhcp6c > $DNL 2>&1;k46 20;q46 && killall -9 dhclient dhcp6c > $DNL 2>&1
    rm -f /var/run/dhclient*.pid /var/run/dhcp6c*.pid > $DNL 2>&1
    arp -d -i "$WAN" -a > $DNL 2>&1
    if [ -n "$IP4" ]; then
        pfctl -i "$WAN"              -k "$IP4" > $DNL 2>&1
        pfctl -i "$WAN" -k 0.0.0.0/0 -k "$IP4" > $DNL 2>&1
    fi
    ks6
    pfSctl -c "interface reload wan" > $DNL 2>&1
    wd4 10;wd6 5;if qn6;then sd6;fi
    if t46;then sfc;j=$?;else j=1;lgm "[ERROR] Failed to start WAN daemons (dhclient/dhcp6c) on $WAN within 15s.";fi
    return "$j"
}
mer() {
    local p k
    read -r p < /root/.meo 2>$DNL
    (
        echo "meo"              ;sleep 2
        echo "$p"               ;sleep 3
        echo "management/reboot";sleep 3
        echo "Y"                ;sleep 2
    ) | nc -N -w 20 192.168.1.254 23 > $DNL 2>&1
    k=$?;[ "$k" -ne 0 ] && lgm "Failed to reboot GR241AG."
    return "$k"
}

if pi4;then pi6 && exit 0;r6o;sleep 30;if pit;then lgm "WAN IPv6 recovered after dhcp6c reset.";exit 0;elif pi4;then lgm "[WARN] WAN IPv6 unreachable (IPv4 OK).";exit 1;fi;fi
ifd;sleep 5;ifu;sleep 45
if pit;then lgm "WAN recovered after physical bounce.";exit 0;elif pi4;then r6o;sleep 30;if pit;then lgm "WAN recovered after physical bounce."     ;exit 0;elif pi4;then lgm "[WARN] WAN IPv4 recovered after physical bounce (IPv6 unreachable).";exit 1;fi;fi
dtn;sleep 35
if pit;then lgm "WAN recovered after daemon reset."   ;exit 0;elif pi4;then lgm "[WARN] WAN IPv4 recovered after daemon reset (IPv6 unreachable)."  ;exit 1;fi
mer;sleep 180;dtn;sleep 35
if pit;then lgm "WAN recovered after GR241AG reboot." ;exit 0;elif pi4;then lgm "[WARN] WAN IPv4 recovered after GR241AG reboot (IPv6 unreachable).";exit 1;fi
lgm "[CRITICAL] Upstream MEO FTTH outage confirmed."  ;exit 1
