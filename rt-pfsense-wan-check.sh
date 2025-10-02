#!/bin/sh

WAN="re1"
PGT="8.8.8.8"
LOG="/root/rt-pfsense-wan-check.log"

lgm() { echo "$(date): $1" >> "$LOG"; }
pig() { /sbin/ping -c 3 -W 1 "$PGT" > /dev/null 2>&1; }

if pig; then exit 0;fi

lgm "Attempting to renew DHCP lease on $WAN..."
/sbin/dhclient -r "$WAN"  ;sleep 5;/sbin/dhclient "$WAN"   ;sleep 15
if pig; then lgm "WAN recovered after DHCP renewal.";exit 0;fi

lgm "Attempting to bounce WAN interface $WAN..."
/sbin/ifconfig "$WAN" down;sleep 5;/sbin/ifconfig "$WAN" up;sleep 15
if pig; then lgm "WAN recovered after WAN bounce.  ";exit 0;fi

lgm "Performing system reboot as last resort."
/sbin/reboot
