#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0-CURRENT

DNL='/dev/null'
LOG="$(ls -tr /var/log/dhcpd.log* 2>$DNL)"

ifo() { ifconfig $1|sed -E 's/^[ \t]+/  * /;s/^i/* i/'; }
nst() { netstat -rn | sed -E 's%^ *([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) *%\1 | \2 | \3 | \4%'; }

p=${1:-nada}
if   [ $p = ip4 ];then grep -hE "bound +to"                  $LOG | tail -1 | awk '{print $8}'
elif [ $p = ip6 ];then grep -hE '(create|update) +a +prefix' $LOG | tail -1 | awk '{sub(/::.*/, "", $9); print $9}'
elif [ $p = ipc ];then ifo igc0;ifo igc1;ifo igc2
elif [ $p = ipr ];then nst
elif [ $p = ipa ];then ifo igc0;ifo igc1;ifo igc2;nst
elif [ $p = ipd ];then ndp -an
else echo "Usage: rt-pfsense-ip.sh {ip4|ip6|ipc|ipr|ipa|ipd}"
fi
