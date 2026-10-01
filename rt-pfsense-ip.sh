#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0-CURRENT

CFG='/conf/config.xml'
[ -f $CFG  ] || exit 1;[ -d /root ] || exit 1
DNL='/dev/null'
WAN=$(awk -F'[<>]' '/<wan>/{in_wan=1} in_wan && /<if>/{print $3; exit}' $CFG 2>$DNL)

ifo() { ifconfig $1|sed -E 's/^[ \t]+/  * /;s/^i/* i/';sleep 1; }
nst() { netstat -rn | sed -E 's%^ *([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) *%\1 | \2 | \3 | \4%';sleep 1; }

if   [ $1 = ip4 ];then ifconfig $WAN  |grep inet |grep -v inet6|awk '{print $2}'
#elif [ $1 = ip6 ];then ifconfig igc1  |grep inet6|grep -v fe80 |awk '{print $2}' # igc1.inet6 is now static, so we use dhcp6c log to get the current PD/address
elif [ $1 = ip6 ];then grep -E 'dhcp6c.+ add an address' /var/log/dhcpd.log.? | cut -d: -f2- | sort -k1,1M -k2,2n -k3,3 | tail -1 | awk '{print $9}'
elif [ $1 = ipc ];then ifo igc0;ifo igc1;ifo igc2
elif [ $1 = ipr ];then nst
elif [ $1 = ipa ];then ifo igc0;ifo igc1;ifo igc2;nst
elif [ $1 = ipd ];then ndp -an
else echo "Usage: rt-pfsense-ip.sh {ip4|ip6|ipc|ipr|ipd}"
fi
