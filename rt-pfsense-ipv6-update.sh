#!/bin/sh
# pfSense IPv6 Prefix Updater
# Usage: ./update.ipv6.sh <old_prefix> <new_prefix>

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <old_prefix> <new_prefix>"
    echo "Example: $0 2001:8a0:fcf2:dc00 2001:db8:aaaa:bbbb"
    exit 1
fi

# Define the PHP logic as a variable to keep the shell script clean
PHP_CMD=$(cat <<EOF
require_once("config.inc");
require_once("filter.inc");
require_once("util.inc");

\$old = rtrim(\$argv[1], ":");
\$new = rtrim(\$argv[2], ":");
\$found = false;

// Get the aliases section
\$aliases = &config_get_path('aliases/alias');

if (is_array(\$aliases)) {
    foreach (\$aliases as &\$alias) {
        // Aliases can have multiple IPs separated by spaces
        \$addrs = explode(" ", \$alias['address']);
        \$changed = false;
        
        foreach (\$addrs as &\$a) {
            // Match addresses starting with the old prefix
            if (strpos(\$a, \$old) === 0) {
                \$test_addr = str_replace(\$old, \$new, \$a);
                // Only replace if the result is a valid IPv6
                if (is_ipaddrv6(\$test_addr) || is_subnetv6(\$test_addr)) {
                    \$a = \$test_addr;
                    \$changed = true;
                    \$found = true;
                }
            }
        }
        
        if (\$changed) {
            \$alias['address'] = implode(" ", \$addrs);
        }
    }
}

if (\$found) {
    write_config("Bulk updated IPv6 prefix from \$old to \$new via CLI");
    echo "SUCCESS";
} else {
    echo "NO_MATCH";
}
EOF
)

# Run the PHP logic
RESULT=$(/usr/local/bin/php -r "$PHP_CMD" "$1" "$2")

if [ "$RESULT" = "SUCCESS" ]; then
    echo "Configuration updated. Applying firewall rules..."
    # Call the internal pfSense rc script to reload the filter
    /etc/rc.filter_configure
    echo "Done. Changes are now live."
elif [ "$RESULT" = "NO_MATCH" ]; then
    echo "Error: No aliases matched prefix $1."
    exit 1
else
    echo "An unexpected error occurred: $RESULT"
    exit 1
fi