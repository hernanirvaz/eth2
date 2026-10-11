#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0-CURRENT

ifo() { ifconfig $1|sed -E 's/^[ \t]+/  * /;s/^i/* i/';sleep 1; }
nst() { netstat -rn | sed -E 's%^ *([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) *%\1 | \2 | \3 | \4%';sleep 1; }

if   [ $1 = ip4 ];then grep -E "bound +to"         /var/log/dhcpd.log* | cut -d: -f2- | sort -k1,1M -k2,2n -k3,3 | tail -1 | awk '{print $8}'
elif [ $1 = ip6 ];then grep -E 'create +a +prefix' /var/log/dhcpd.log* | cut -d: -f2- | sort -k1,1M -k2,2n -k3,3 | tail -1 | awk '{sub(/::.*/, "", $9); print $9}'
elif [ $1 = ipc ];then ifo igc0;ifo igc1;ifo igc2
elif [ $1 = ipr ];then nst
elif [ $1 = ipa ];then ifo igc0;ifo igc1;ifo igc2;nst
elif [ $1 = ipd ];then ndp -an
else echo "Usage: rt-pfsense-ip.sh {ip4|ip6|ipc|ipr|ipd}"
fi
