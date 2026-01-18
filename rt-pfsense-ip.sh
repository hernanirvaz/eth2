#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0-CURRENT

ifo() { echo ifconfig $1;ifconfig $1;sleep 1;echo; }
ift() { ifconfig igc0.12 2>/dev/null | grep -q "status: active"; }
ifw() { if ift;then echo igc0.12;else echo igc0;fi; }

if   [ $1 = ip4 ];then ifconfig $(ifw)|grep inet |grep -v inet6|awk '{print $2}'
elif [ $1 = ip6 ];then ifconfig igc1  |grep inet6|grep -v fe80 |awk '{print $2}'
elif [ $1 = ipc ];then ifo igc0;ifo igc0.12;ifo igc1
elif [ $1 = ipr ];then /usr/bin/netstat -rn
elif [ $1 = ipd ];then ndp -an
else echo "Usage: rt-pfsense-ip.sh {ip4|ip6|ipc|ipr|ipd}"
fi
