#!/bin/sh
# pfSense CE 2.8.1 - OpenSSH Post-Quantum KEX Enabler
DNL='/dev/null'
SRC='/etc/sshd'
OLD='diffie-hellman-group-exchange-sha256'
NET='sntrup761x25519-sha512@openssh.com'
NEW="$OLD,$NET"

grep -q "$NET" "$SRC" && exit 0
[ ! -f "${SRC}.orig" ] && cp "$SRC" "${SRC}.orig";sed -i '' "s/${OLD}/${NEW}/" "$SRC"
if grep -q "$NET" "$SRC"; then
    pfSsh.php playback svc restart sshd > $DNL 2>&1;rm -f "${SRC}.orig"
else
    [ -f "${SRC}.orig" ] && mv -f "${SRC}.orig" "$SRC";exit 1
fi
