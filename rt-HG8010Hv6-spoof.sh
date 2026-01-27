#!/bin/bash

echo "=== Huawei Spoofing Calculator ==="

for p in "$@"; do
    HEX=$(echo -n "$p" | xxd -p | tr 'a-f' 'A-F')
    if [[ "$p" =~ ^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$ ]]; then # MAC Address
        HEX=$(echo "$p" | tr -d ':-')
    fi
    printf "In: %-20s Hex: %s\n" "$p" "$HEX"
done
