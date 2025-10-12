#!/bin/sh
# 15,35,55 * * * * root /root/rt-pfsense-wan-check.sh

WAN="re1"
PGT="8.8.8.8"
LOG="/root/rt-pfsense-wan-check.log"

lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> $LOG 2>&1; }
pig() { /sbin/ping -c 3 -W 1 $PGT > /dev/null 2>&1; }

if pig; then exit 0;fi
/sbin/dhclient -r $WAN   > /dev/null 2>&1;sleep 5;/sbin/dhclient $WAN    > /dev/null 2>&1;sleep 20;if pig;then lgm "WAN recovered after DHCP renewal.";exit 0;fi
/sbin/ifconfig $WAN down > /dev/null 2>&1;sleep 5;/sbin/ifconfig $WAN up > /dev/null 2>&1;sleep 30;if pig;then lgm "WAN recovered after bounce."      ;exit 0;fi
lgm "Performing pfSense reboot as last resort.";/etc/rc.reboot           > /dev/null 2>&1;exit 1
