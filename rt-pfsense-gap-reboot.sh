#!/bin/sh

{ date +'%Y-%m-%d %H:%M:%S';/etc/rc.reboot; } >> /root/rt-pfsense-gap-reboot.log 2>&1
