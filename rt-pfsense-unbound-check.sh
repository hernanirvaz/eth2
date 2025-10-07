#!/bin/sh

DHCP6_HOSTS_FILE="/root/dhcp6_hosts.txt"
DNS_RESOLVER_CONFIG="/var/unbound/unbound.conf" # Actual Unbound conf file path
LAN_INTERFACE="re0" # The interface name for your LAN (e.g., 'lan', 'igb0', 'em0')

# 1. Get the current IPv6 delegated prefix for the LAN interface
#    We'll look for an address on the LAN interface that's not link-local (fe80::)
#    and is part of a /64 or similar global prefix.
#    This might need adjustment based on your 'ifconfig lan' output
CURRENT_PREFIX=$(ifconfig "$LAN_INTERFACE" inet6 | grep inet6| grep -v fe80::|awk '{print $2}'|cut -d'/' -f1|head -n1|awk -F':' '{print $1":"$2":"$3":"$4"::"}')
if [ -z "$CURRENT_PREFIX" ]; then
    lgm "ERROR: Could not parse current IPv6 prefix Exiting."
    exit 1
fi

# 2. Clear existing dynamic DHCPv6 related host-overrides from Unbound's configuration
#    We'll remove lines that look like:
#    local-data: "hrv-zotac3.home.arpa AAAA 2001:8a0:fcc9:de00::1003"
#    This prevents duplicates if the script runs multiple times and ensures old prefixes are removed.
#    This step is critical to ensure clean updates.
#    We will remove any 'local-data' entries for our managed hosts.
lgm "Removing old IPv6 DNS entries for managed hosts from Unbound config."
TEMP_UNBOUND_CONF=$(mktemp)
grep -v -E "local-data: \"(hrv-lenovo|hrv-zotac3|lgwebostv|pixel-9-pro-xl)\.home\.arpa AAAA" "$DNS_RESOLVER_CONFIG" > "$TEMP_UNBOUND_CONF"
mv "$TEMP_UNBOUND_CONF" "$DNS_RESOLVER_CONFIG"

# 3. Add/Update Host Overrides in Unbound's configuration file
#    We'll append these directly to the unbound configuration that pfSense generates.
#    This is a bit aggressive, but for `local-data` entries, it's generally safe.
lgm "Adding new IPv6 DNS entries with prefix $CURRENT_PREFIX"
while IFS=' ' read -r hostname suffix; do
    if [ -n "$hostname" ] && [ -n "$suffix" ]; then
        FULL_IPV6="${CURRENT_PREFIX}${suffix}"
        lgm "  - Adding: $hostname.home.arpa -> $FULL_IPV6"
        echo "local-data: \"$hostname.home.arpa AAAA $FULL_IPV6\"" >> "$DNS_RESOLVER_CONFIG"
    fi
done < "$DHCP6_HOSTS_FILE"

# 4. Restart Unbound DNS Resolver
lgm "Restarting Unbound DNS Resolver to apply changes."
/usr/local/sbin/pfSsh.php playback svc restart unbound
# Check if restart was successful (optional, but good practice)
if [ $? -eq 0 ]; then
    lgm "Unbound DNS Resolver restarted successfully."
else
    lgm "ERROR: Failed to restart Unbound DNS Resolver."
fi

lgm "IPv6 DNS update script finished."
