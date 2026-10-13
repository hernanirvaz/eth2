#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0-CURRENT
# Auxiliary script to obtain pfSense network information 

DNL='/dev/null'
WAN="igc0"
LOG="$(ls -tr /var/log/dhcpd.log* 2>$DNL)"

ifo() { ifconfig $1 2>$DNL | sed -E 's/^[ \t]+/  * /;s/^i/* i/'; }
nst() { netstat -rn 2>$DNL | sed -E 's%^ *([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) *%\1 | \2 | \3 | \4%'; }
ip4() { local i;i=$(ifconfig $WAN inet 2>$DNL | awk '/inet +/ {print $2}');if [ -n "$i" ]; then echo $i;else grep -hE 'bound +to' $LOG 2>$DNL | tail -1 | awk '{print $8}'; fi; }

p=${1:-nada}
if   [ $p = ip4 ];then ip4
elif [ $p = ip6 ];then grep -hE '(create|update) +a +prefix' $LOG 2>$DNL | tail -1 | awk '{sub(/::.*/, "", $9); print $9}'
elif [ $p = ipc ];then ifo igc0;ifo igc1;ifo igc2
elif [ $p = ipr ];then nst
elif [ $p = ipa ];then ifo igc0;ifo igc1;ifo igc2;nst
elif [ $p = ipd ];then ndp -an
else echo "Usage: rt-pfsense-ip.sh {ip4|ip6|ipc|ipr|ipa|ipd}"
fi
