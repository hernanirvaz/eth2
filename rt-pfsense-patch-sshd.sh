#!/bin/sh
# pfSense v2.8.1-RELEASE (amd64) FreeBSD 15.0
# OpenSSH Post-Quantum KEX Enabler
# Trigger: shellcmd /root/rt-pfsense-patch-sshd.sh
# Note: The OpenSSH binary compiled within this version of pfSense base userland does not support the mlkem768x25519-sha256 key exchange identifier

DNL='/dev/null'
SRC='sshd'
OLD='diffie-hellman-group-exchange-sha256'
NET='sntrup761x25519-sha512@openssh.com'
NEW="$OLD,$NET"

grep -q "$NET" "/etc/$SRC" && exit 0
[ -f "/root/${SRC}.org" ] || cp "/etc/$SRC" "/root/${SRC}.org";sed -i '' "s/${OLD}/${NEW}/" "/etc/$SRC"
if grep -q "$NET" "/etc/$SRC"; then
    pfSsh.php playback svc restart sshd > $DNL 2>&1
else
    [ -f "/root/${SRC}.org" ] && cp -f "/root/${SRC}.org" "/etc/$SRC";exit 1
fi
