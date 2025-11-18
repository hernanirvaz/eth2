#!/bin/sh
# */5 * * * * root /root/rt-pfsense-wan-check.sh

WAN="re1"
LOG="/root/rt-pfsense-wan-check.log"
LCK="/root/rt-pfsense-wan-check.lock"
DNS="8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112 208.67.222.222 208.67.220.220 64.6.64.6 64.6.65.6 209.244.0.3 209.244.0.4 84.200.69.80 84.200.70.40 94.140.14.140 94.140.14.141 8.26.56.26 8.20.247.20 185.228.168.9"

grn() { set -- $DNS;r=$(/usr/bin/awk -v m=1 -v x=$# -v s=$(/bin/date +%s%N) "BEGIN{srand(s);print int(m+rand()*(x-m+1))}");c=1;for s in $DNS;do if [ $c -eq $r ];then echo $s;return;fi;c=$((c+1));done;echo "8.8.8.8"; }
lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> $LOG 2>&1; }
pig() { /sbin/ping -c 2 -W 1 $1 > /dev/null 2>&1;e=$?;[ $e -ne 0 ] && lgm "Server $1 unreachable ($e)";return $e; }
pit() { pig $(grn) || pig $(grn); }
dhr() { /sbin/dhclient -r $WAN           > /dev/null 2>&1;f=$?;[ $f -ne 0 ] && lgm "Failed release DHCP $WAN." ;return $f; }
dhn() { /sbin/dhclient    $WAN           > /dev/null 2>&1;g=$?;[ $g -ne 0 ] && lgm "Failed renew DHCP $WAN."   ;return $g; }
ifd() { /sbin/ifconfig    $WAN down      > /dev/null 2>&1;h=$?;[ $h -ne 0 ] && lgm "Failed to bring $WAN down.";return $h; }  
ifu() { /sbin/ifconfig    $WAN up        > /dev/null 2>&1;i=$?;[ $i -ne 0 ] && lgm "Failed to bring $WAN up."  ;return $i; }  

if [ -f $LCK ];then PID=$(cat $LCK);if ps -p $PID > /dev/null 2>&1;then lgm "Another instance is running ($PID). Exiting.";exit 0;else rm -f $LCK;fi;fi
echo $$ > $LCK;trap "rm -f $LCK" EXIT

                         if pit;then                                         exit 0;fi
dhr;sleep 5;dhn;sleep 30;if pit;then lgm "WAN recovered after DHCP renewal.";exit 0;fi
ifd;sleep 5;ifu;sleep 30;if pit;then lgm "WAN recovered after bounce."      ;exit 0;fi
lgm "Performing pfSense reboot as last resort.";/etc/rc.reboot > /dev/null 2>&1;exit 1
