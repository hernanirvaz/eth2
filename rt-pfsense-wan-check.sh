#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0-CURRENT
# */5 * * * * root /root/rt-pfsense-wan-check.sh

WAN="re1"
FIL="/root/wan-check"
DNS="8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112 208.67.222.222 208.67.220.220 64.6.64.6 64.6.65.6 209.244.0.3 209.244.0.4 84.200.69.80 84.200.70.40 94.140.14.140 94.140.14.141 8.26.56.26 8.20.247.20 185.228.168.9"

grn() { set -- $DNS;n=$(date +%s%N);r=$(awk -v m=1 -v x=$# -v s=$n "BEGIN{srand(s);print int(m+rand()*(x-m+1))}");c=1;for s in $DNS;do if [ $c -eq $r ];then echo $s;return;fi;c=$((c+1));done;echo 8.8.8.8; }
lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> $FIL.log 2>&1; }
pig() { ping -c $2 -W 2 $1         > /dev/null 2>&1;e=$?;[ $e -ne 0 ] && lgm "ping -c$2 -W2 $1 erro ($e)";return $e; }
dhr() { dhclient -r $WAN           > /dev/null 2>&1;f=$?;[ $f -ne 0 ] && lgm "Failed release DHCP $WAN." ;return $f; }
dhn() { dhclient    $WAN           > /dev/null 2>&1;g=$?;[ $g -ne 0 ] && lgm "Failed renew DHCP $WAN."   ;return $g; }
ifd() { ifconfig    $WAN down      > /dev/null 2>&1;h=$?;[ $h -ne 0 ] && lgm "Failed to bring $WAN down.";return $h; }  
ifu() { ifconfig    $WAN up        > /dev/null 2>&1;i=$?;[ $i -ne 0 ] && lgm "Failed to bring $WAN up."  ;return $i; }
rex() { lgm "$1";/etc/rc.reboot    > /dev/null 2>&1;exit 1; }  
pit() { pig $(grn) 3 || pig $(grn) 4; }

if [ -f $FIL.lck ];then
    PID=$(cat $FIL.lck);rm -f $FIL.lck
    if ps -p $PID > /dev/null 2>&1;then
        rex "Another instance is stuck ($PID), reboot as last resort."
    fi
fi
echo $$ > $FIL.lck;trap "rm -f $FIL.lck" EXIT

                         if pit;then                                   exit 0;fi
# dhr failed & dhn got stuck, so skip DHCP step
# dhr;sleep 5;dhn;sleep 30;if pit;then lgm "WAN recovered after DHCP."  ;exit 0;fi
ifd;sleep 5;ifu;sleep 30;if pit;then lgm "WAN recovered after bounce.";exit 0;fi
rex "Performing pfSense reboot as last resort."
