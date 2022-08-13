eth2rq () { echo -e "\nresolvectl query ${1:-pt.archive.ubuntu.com}";resolvectl query "${1:-pt.archive.ubuntu.com}"; }
eth2cp () { echo -e "\nscp $1 eth2/scripts";scp ~/eth2/t[1-9]* $1:~/eth2; }
eth2st () { export N="$1";echo -e "\nLOGIN $N"; }
eth2sl () { eth2st $1;ssh -l eth $N; }
eth2sr () { echo -e "ROUTE\t\t$(ip route show|grep 'default via'|cut -d' ' -f3)"; }
eth2sf () {
  m="$(netstat -i|grep -v '^lo\|Iface\|Kernel'|cut -d' ' -f1)"
  [ -f /etc/bind/named.conf.options ] && echo -e "FORWARDER\t$(grep 'forwarders {' /etc/bind/named.conf.options 2>/dev/null|cut -d' ' -f3)"
  echo -e "DNS\t\t$(resolvectl|grep 'Current DNS'|cut -d' ' -f6)"
  echo -e "$m\t\t$(resolvectl dns|grep $m|cut -d' ' -f4-6)"
}

alias v1='eth2sl "vpsl"'
alias v2='eth2sl "vpsm"'
alias v3='eth2sl "vpss"'
alias z1='eth2sl "ztc1"'
alias z2='eth2sl "ztc2"'
alias z3='eth2sl "ztc3"'
alias z4='eth2sl "ztc4"'
alias r1='eth2sl "ztc1.fruga.pt"'
alias r2='eth2sl "ztc2.fruga.pt"'
alias r3='eth2sl "ztc3.fruga.pt"'
alias r4='eth2sl "ztc4.fruga.pt"'
alias vp='eth2cp "vpsl";eth2cp "vpss"'
alias zp='eth2cp "ztc1"         ;eth2cp "ztc2"         ;eth2cp "ztc3"         ;eth2cp "ztc4"         '
alias rp='eth2cp "ztc3.fruga.pt";eth2cp "ztc4.fruga.pt";eth2cp "ztc1.fruga.pt";eth2cp "ztc2.fruga.pt"'

alias rq='eth2rq;eth2rq changelogs.ubuntu.com;eth2rq ppa.launchpad.net;eth2rq github.com;eth2rq meo.fruga.pt'
alias rs='sudo netplan apply;sudo systemctl restart systemd-resolved;rq'
alias sr='eth2sr;eth2sf;cat ${1:-/etc/netplan/01-network-manager-all.yaml}'
alias xx='exit'
