#!/bin/sh
# pfSense CE 2.8.1 / FreeBSD 15 – LEOX soft recovery (non-power-cycle)
# Monitors ONT Ethernet PHY health via 192.168.100.1 and soft-reboots LEOX via telnet - when the LAN side is dead.
# */5 * * * * root /root/rt-leox-phy-check.sh

CFG='/conf/config.xml'
[ -f "$CFG" ] || exit 1
[ -d /root ] || exit 1

DNL='/dev/null'
FIL='/root/leox-phy-check'
LEOX_IP='192.168.100.1'
ONT_IF='igc0'          # parent of WAN (igc0.12)
USER='leox'
PASS='leolabs_7'
LOG="$FIL.log"
LCK="$FIL.lck"

lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "$LOG" 2>&1; }

# Simple lock
if [ -f "$LCK" ]; then
    PID=$(cat "$LCK" 2>$DNL)
    if ps -p "$PID" >$DNL 2>&1; then
        lgm "Another instance running ($PID) – exit"
        exit 0
    else
        rm -f "$LCK"
    fi
fi
echo $$ > "$LCK"
trap 'rm -f "$LCK"' EXIT

# 1. Is the ONT management interface even up?
if ! ifconfig "$ONT_IF" 2>$DNL | grep -q 'status: active'; then
    lgm "ONT parent $ONT_IF has no carrier – skipping LEOX recovery (physical cable / power issue)"
    exit 0
fi

# 2. Can we reach the LEOX management IP?
if ping -c 2 -W 2 "$LEOX_IP" >$DNL 2>&1; then
    # Link is alive – nothing to do
    exit 0
fi

# 3. Management IP unreachable but parent has carrier → classic PHY death pattern
lgm "LEOX management IP $LEOX_IP unreachable while $ONT_IF is active – attempting soft reboot"

# Non-interactive telnet reboot (works on the stock LEOX BusyBox telnetd)
(
    sleep 1
    printf '%s\r\n' "$USER"
    sleep 1
    printf '%s\r\n' "$PASS"
    sleep 1
    printf 'reboot\r\n'
    sleep 2
) | telnet "$LEOX_IP" >$DNL 2>&1

# Give the LEOX time to restart its Ethernet PHY
sleep 45

# 4. Verify recovery
if ping -c 3 -W 3 "$LEOX_IP" >$DNL 2>&1; then
    lgm "LEOX soft reboot succeeded – management IP reachable again"
    # Optional: gentle WAN bounce so dhcp6c / igc0.12 re-acquire cleanly
    ifconfig igc0.12 down 2>$DNL
    sleep 3
    ifconfig igc0.12 up 2>$DNL
    exit 0
else
    lgm "LEOX soft reboot failed – management IP still unreachable. Manual intervention required."
    # Do NOT power-cycle or reboot the whole pfSense box here.
    exit 1
fi