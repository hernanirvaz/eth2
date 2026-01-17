#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0-CURRENT

if ifconfig igc0.12 2>/dev/null | grep -q "status: active";then
    WAN="igc0.12"
else
    WAN="igc0"
fi 
ifconfig $WAN|grep inet|grep -v inet6|awk '{print $2}'
