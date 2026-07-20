#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0-CURRENT

CFG='/conf/config.xml'
[ -f $CFG  ] || exit 1;[ -d /root ] || exit 1
DNL='/dev/null'
WAN=$(awk -F'[<>]' '/<wan>/{in_wan=1} in_wan && /<if>/{print $3; exit}' $CFG 2>$DNL)

ifo() { echo ifconfig $1;ifconfig $1;sleep 1;echo; }

if   [ $1 = ip4 ];then ifconfig $WAN  |grep inet |grep -v inet6|awk '{print $2}'
elif [ $1 = ip6 ];then ifconfig igc1  |grep inet6|grep -v fe80 |awk '{print $2}'
elif [ $1 = ipc ];then ifo igc0;ifo igc0.12;ifo igc1
elif [ $1 = ipr ];then /usr/bin/netstat -rn
elif [ $1 = ipd ];then ndp -an
else echo "Usage: rt-pfsense-ip.sh {ip4|ip6|ipc|ipr|ipd}"
fi
