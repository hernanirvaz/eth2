#!/bin/sh
# 15,35,55 * * * * root /root/rt-pfsense-wan-check.sh

WAN="re1"
PG1="8.8.8.8"  # Google DNS
PG2="1.1.1.1"  # Cloudflare DNS
PG3="208.67.222.222" # OpenDNS resolver by IP
LOG="/root/rt-pfsense-wan-check.log"
LCK="/root/rt-pfsense-wan-check.lock"

lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> $LOG 2>&1; }
pig() { /sbin/ping -c 5 -W 2 $1 > /dev/null 2>&1;local e=$?;[ $e -ne 0 ] && lgm "Server $1 unreachable (ping exit status: $e).";return $e; }
pit() { pig $PG1 || pig $PG2 || pig $PG3;return $?; }
dhr() { /sbin/dhclient -r $WAN   > /dev/null 2>&1 || lgm "Failed release DHCP $WAN." ;return $?; }
dhn() { /sbin/dhclient    $WAN   > /dev/null 2>&1 || lgm "Failed renew DHCP $WAN."   ;return $?; }
ifd() { /sbin/ifconfig $WAN down > /dev/null 2>&1 || lgm "Failed to bring $WAN down.";return $?; }  
ifu() { /sbin/ifconfig $WAN up   > /dev/null 2>&1 || lgm "Failed to bring $WAN up."  ;return $?; }  

if [ -f $LCK ];then PID=$(cat $LCK);if ps -p $PID > /dev/null 2>&1;then lgm "Another instance is running ($PID). Exiting.";exit 0;else rm -f $LCK;fi;fi;echo $$ > $LCK;trap "rm -f $LCK" EXIT

pit && exit 0
dhr;sleep 5;dhn;sleep 30;if pit;then lgm "WAN recovered after DHCP renewal.";exit 0;fi
ifd;sleep 5;ifu;sleep 30;if pit;then lgm "WAN recovered after bounce."      ;exit 0;fi
lgm "Performing pfSense reboot as last resort.";/etc/rc.reboot > /dev/null 2>&1;exit 1
