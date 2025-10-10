#!/bin/sh

WAN="re1"
PGT="8.8.8.8"
LOG="/root/rt-pfsense-wan-check.log"

lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> $LOG; }
pig() { /sbin/ping -c 3 -W 1 $PGT > /dev/null 2>&1; }

if pig; then exit 0;fi
/sbin/dhclient -r $WAN  ;sleep 5;/sbin/dhclient $WAN   ;sleep 20;if pig;then lgm "WAN recovered after DHCP renewal.";exit 0;fi
/sbin/ifconfig $WAN down;sleep 5;/sbin/ifconfig $WAN up;sleep 30;if pig;then lgm "WAN recovered after bounce."      ;exit 0;fi
lgm "Performing pfSense reboot as last resort.";/sbin/reboot
