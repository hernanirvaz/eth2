#!/bin/sh
# pfSense v2.8.1 IPv6 Rotation Script
# Updates local text files and triggers rc.update_urltables
# Cron: */5 * * * * root /root/rt-pfsense-ipv6-rotate.sh

# --- Configuration ---
LAN="re0"       # Your LAN Interface (Check ifconfig)
DIR="/root"    # Where we write the text files for the URL Table to read
FIL="$DIR/rt-pfsense-ipv6-rotate"

# Map Alias Name to Host Suffix
# Format: "AliasName:Suffix"
# The script will generate files named: rt-pfsense-ipv6-rotate-AliasName.txt
TRG="IPv6z2:1002 IPv6z3:1003 IPv6z5:1005 IPv6z6:1006"

# --- Functions ---
lgm() { echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> $FIL.log 2>&1; }

# Get current Global Unicast /64 prefix
get_pfx() {
    # Grabs the first inet6 address that isn't link-local (fe80)
    _ip=$(ifconfig $LAN | grep 'inet6 2' | head -n1 | awk '{print $2}')
    if [ -z "$_ip" ]; then return 1; fi
    echo $_ip | cut -d: -f1-4
}

# --- Logic ---

# Lock file check to prevent overlap
if [ -f $FIL.lck ]; then
    PID=$(cat $FIL.lck); rm -f $FIL.lck
    if ps -p $PID > /dev/null 2>&1; then lgm "Stuck process $PID."; exit 1; fi
fi
echo $$ > $FIL.lck; trap "rm -f $FIL.lck" EXIT

# 1. Get Current Prefix
CUR_PFX=$(get_pfx)
if [ -z "$CUR_PFX" ]; then exit 0; fi # No IPv6 connectivity, exit.

# 2. Check if changed
LAST_FILE="$FIL.last"
if [ -f $LAST_FILE ]; then
    LAST_PFX=$(cat $LAST_FILE)
else
    LAST_PFX="INIT"
fi

if [ "$CUR_PFX" = "$LAST_PFX" ]; then
    # No rotation detected.
    # Optional: Check if the source text files exist (in case they were deleted), if not, force recreate.
    MISSING=0
    for T in $TRG; do
        ALIAS_NAME="${T%%:*}"
        if [ ! -f "$DIR/rt-pfsense-ipv6-rotate-$ALIAS_NAME.txt" ]; then MISSING=1; fi
    done
    
    if [ $MISSING -eq 0 ]; then
        exit 0
    fi
    lgm "Prefix unchanged, but source files missing. Re-generating."
fi

# 3. Rotation Detected (or Init) - Update Text Files
if [ "$LAST_PFX" != "INIT" ]; then
    lgm "Rotation detected: $LAST_PFX -> $CUR_PFX"
else
    lgm "Initializing IPv6 Alias files with prefix: $CUR_PFX"
fi

for T in $TRG; do
    ALIAS_NAME="${T%%:*}"
    SUFFIX="${T##*:}"
    FULL_IP="${CUR_PFX}::${SUFFIX}"
    
    # Write the single IP to the text file in /root/
    echo "$FULL_IP" > "$DIR/rt-pfsense-ipv6-rotate-$ALIAS_NAME.txt"
    # lgm "Updated $ALIAS_NAME file to $FULL_IP"
done

# 4. Trigger rc.update_urltables
# We use 'now forceupdate' as seen in the source code you provided to bypass the random sleep and force refresh.
lgm "Triggering rc.update_urltables..."

# Validating the command based on your output
if [ -f /etc/rc.update_urltables ]; then
    /usr/local/bin/php-cgi -q /etc/rc.update_urltables now forceupdate >> $FIL.log 2>&1
else
    lgm "CRITICAL: /etc/rc.update_urltables not found!"
    exit 1
fi

# 5. Save state
echo "$CUR_PFX" > $LAST_FILE
lgm "Completed successfully."

exit 0