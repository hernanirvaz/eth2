#!/bin/sh
# 15,35,55 * * * * root /root/rt-pfsense-wan-check.sh

WAN="re1"
PG1="8.8.8.8"
PG2="1.1.1.1"
LOG="/root/rt-pfsense-wan-check.log"
LCK="/root/rt-pfsense-wan-check.lock"

lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> $LOG 2>&1; }
pig() { /sbin/ping -c 3 -W 1 $1 > /dev/null 2>&1;local e=$?;[ $e -ne 0 ] && lgm "Server $1 unreachable ($e).";return $e; }
pit() { pig $PG1 || pig $PG2;return $?; }

if [ -f $LCK ];then
    PID=$(cat $LCK);if ps -p $PID > /dev/null 2>&1;then lgm "Another instance is running ($PID). Exiting.";exit 0;else rm -f $LCK;fi
fi
echo $$ > $LCK;trap "rm -f $LCK" EXIT

pit && exit 0
/sbin/dhclient -r $WAN   > /dev/null 2>&1;sleep 5;/sbin/dhclient $WAN    > /dev/null 2>&1;sleep 30;if pit;then lgm "WAN recovered after DHCP renewal.";exit 0;fi
/sbin/ifconfig $WAN down > /dev/null 2>&1;sleep 5;/sbin/ifconfig $WAN up > /dev/null 2>&1;sleep 30;if pit;then lgm "WAN recovered after bounce."      ;exit 0;fi
lgm "Performing pfSense reboot as last resort.";/etc/rc.reboot           > /dev/null 2>&1;exit 1
