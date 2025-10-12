#!/bin/sh

LOG="/root/rt-pfsense-gap-reboot.log"

{ date +'%Y-%m-%d %H:%M:%S';/etc/rc.reboot; } >> $LOG 2>&1
