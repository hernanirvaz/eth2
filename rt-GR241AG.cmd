
nat/virtual-servers/remove --ext-port-start=2021  --int-port-start=2021  --protocol=TCP     --server-ip=192.168.1.25
nat/virtual-servers/remove --ext-port-start=2022  --int-port-start=2022  --protocol=TCP     --server-ip=192.168.1.28
nat/virtual-servers/remove --ext-port-start=2023  --int-port-start=2023  --protocol=TCP     --server-ip=192.168.1.31
nat/virtual-servers/remove --ext-port-start=2024  --int-port-start=2024  --protocol=TCP     --server-ip=192.168.1.34
nat/virtual-servers/remove --ext-port-start=2025  --int-port-start=2025  --protocol=TCP     --server-ip=192.168.1.37
nat/virtual-servers/remove --ext-port-start=2026  --int-port-start=2026  --protocol=TCP     --server-ip=192.168.1.40
nat/virtual-servers/remove --ext-port-start=30303 --int-port-start=30303 --protocol=TCP/UDP --server-ip=192.168.1.37
nat/virtual-servers/remove --ext-port-start=9004  --int-port-start=9004  --protocol=TCP/UDP --server-ip=192.168.1.37
nat/virtual-servers/remove --ext-port-start=9005  --int-port-start=9005  --protocol=UDP     --server-ip=192.168.1.37
nat/virtual-servers/remove --ext-port-start=30304 --int-port-start=30304 --protocol=TCP/UDP --server-ip=192.168.1.40
nat/virtual-servers/remove --ext-port-start=9000  --int-port-start=9000  --protocol=TCP/UDP --server-ip=192.168.1.40
nat/virtual-servers/remove --ext-port-start=9001  --int-port-start=9001  --protocol=UDP     --server-ip=192.168.1.40

nat/virtual-servers/create --ext-port-start=2021  --int-port-start=2021  --protocol=TCP     --server-ip=192.168.1.25 --server-name=ssh   --wan-intf=veip0.1
nat/virtual-servers/create --ext-port-start=2022  --int-port-start=2022  --protocol=TCP     --server-ip=192.168.1.28 --server-name=ssh   --wan-intf=veip0.1
nat/virtual-servers/create --ext-port-start=2023  --int-port-start=2023  --protocol=TCP     --server-ip=192.168.1.31 --server-name=ssh   --wan-intf=veip0.1
nat/virtual-servers/create --ext-port-start=2024  --int-port-start=2024  --protocol=TCP     --server-ip=192.168.1.34 --server-name=ssh   --wan-intf=veip0.1
nat/virtual-servers/create --ext-port-start=2025  --int-port-start=2025  --protocol=TCP     --server-ip=192.168.1.37 --server-name=ssh   --wan-intf=veip0.1
nat/virtual-servers/create --ext-port-start=2026  --int-port-start=2026  --protocol=TCP     --server-ip=192.168.1.40 --server-name=ssh   --wan-intf=veip0.1
nat/virtual-servers/create --ext-port-start=30303 --int-port-start=30303 --protocol=TCP/UDP --server-ip=192.168.1.37 --server-name=elp2p --wan-intf=veip0.1
nat/virtual-servers/create --ext-port-start=9004  --int-port-start=9004  --protocol=TCP/UDP --server-ip=192.168.1.37 --server-name=clp2p --wan-intf=veip0.1
nat/virtual-servers/create --ext-port-start=9005  --int-port-start=9005  --protocol=UDP     --server-ip=192.168.1.37 --server-name=clquc --wan-intf=veip0.1
nat/virtual-servers/create --ext-port-start=30304 --int-port-start=30304 --protocol=TCP/UDP --server-ip=192.168.1.40 --server-name=elp2p --wan-intf=veip0.1
nat/virtual-servers/create --ext-port-start=9000  --int-port-start=9000  --protocol=TCP/UDP --server-ip=192.168.1.40 --server-name=clp2p --wan-intf=veip0.1
nat/virtual-servers/create --ext-port-start=9001  --int-port-start=9001  --protocol=UDP     --server-ip=192.168.1.40 --server-name=clquc --wan-intf=veip0.1
