#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0-CURRENT
# Auxiliary script to obtain pfSense network information 

DNL='/dev/null'
WAN="igc0"
LAN="igc1"
LOG="$(ls -tr /var/log/dhcpd.log* 2>$DNL)"

ifo() { ifconfig $1 2>$DNL | sed -E 's/^[ \t]+/  * /;s/^i/* i/'; }
nst() { netstat -rn 2>$DNL | sed -E 's%^ *([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) *%\1 | \2 | \3 | \4%'; }
i4c() { ifconfig $WAN inet 2>$DNL | awk '/inet +/ {print $2}'; }
i4l() { grep -hiE 'bound +to' $LOG 2>$DNL | tail -1 | awk '{print $8}'; }
i6c() { ifconfig $LAN inet6 2>$DNL | awk '/inet6 +[^f]/ {print $2}'; }
i6e() { ifconfig $LAN inet6 2>$DNL | awk '/inet6 +fe80/ {sub(/fe80::/,"",$2);sub(/%igc1/,"",$2);print $2}'; }
i6l() { grep -hiE '(create|update) +a +prefix' $LOG 2>$DNL | tail -1 | awk '{sub(/::.*/,"",$9);print $9}'; }
ip4() { local i;i=$(i4c);if [ -n "$i" ];then echo $i;else i4l;fi; }
ipg() { 
    local n a b c d e f g
    e='\033[0;32m'
    f='\033[1;5;31m'
    g='\033[0m'
    n=$(netstat -rn 2>$DNL)
    a=$(echo "$n" | awk '/0\.0\.0\.0  *.*igc0/ {print $2}')
    b=$(echo "$n" | awk '/::\/0  *.*igc0/      {sub(/%igc0/, "", $2);print $2}')
    c=$(grep -hiE 'New +Routers +\(igc0\):'      $LOG 2>$DNL | tail -1 | awk '{print $9}')
    d=$(grep -hiE 'receive +reply +from +.*igc0' $LOG 2>$DNL | tail -1 | awk '{sub(/%igc0/,"",$9);print $9}')
    printf 'Gateways netstat\tIPv4:\t%s\tIPv6:\t%s\nGateways logs\t\tLGv4:\t%s\tLGv6:\t%s ' "$a" "$b" "$c" "$d"
    if [ "$a" = "$c" ] && [ "$b" = "$d" ]; then printf "%bOK%b\n" "$e" "$g"; else printf "%bMismatch found%b\n" "$f" "$g"; fi
    a=$(i4c)
    b=$(i6c)
    c=$(i4l)
    d=$(i6l):$(i6e)
    printf 'IPs ifconfig\t\tIPv4:\t%s\tIPv6:\t%s\nIPs logs\t\tLGv4:\t%s\tLGv6:\t%s ' "$a" "$b" "$c" "$d"
    if [ "$a" = "$c" ] && [ "$b" = "$d" ]; then printf "%bOK%b\n" "$e" "$g"; else printf "%bMismatch found%b\n" "$f" "$g"; fi
}

p=${1:-nada}
if   [ $p = ip4 ];then ip4
elif [ $p = ip6 ];then i6l
elif [ $p = ipc ];then ifo igc0;ifo igc1;ifo igc2
elif [ $p = ipr ];then nst
elif [ $p = ipd ];then ndp -an
elif [ $p = ipg ];then ipg
elif [ $p = ipa ];then ifo igc0;ifo igc1;ifo igc2;nst
else echo "Usage: rt-pfsense-ip.sh {ip4|ip6|ipc|ipr|ipd|ipg|ipa}";
fi
