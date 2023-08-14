#! /bin/bash

name=$1
proxy_host=$2
ss_ip=$3
ss_port=$4
local_port=$5
trojan_password=$6

cat > /etc/systemd/system/trojan-forward-${name}.service << EOF
[Unit]
Description=Trojan-go Service
After=network.target nss-lookup.target
[Service]
#User=nobody
User=root
#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
#Environment=V2RAY_LOCATION_ASSET=/usr/local/share/v2ray/
ExecStart=/usr/local/bin/trojan-go -config /usr/local/etc/trojan-go/forward-${name}.json
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

mkdir -p /usr/local/etc/trojan-go

cat > /usr/local/etc/trojan-go/forward-${name}.json << EOF
{
    "run_type": "forward",
    "local_addr": "0.0.0.0",
    "local_port": ${local_port},
    "remote_addr": "${proxy_host}",
    "remote_port": 443,
    "target_addr": "${ss_ip}",
	  "target_port": ${ss_port},
    "password": [
        "${trojan_password}"
    ]
}
EOF

sleep 1
systemctl enable trojan-forward-${name}
systemctl restart trojan-forward-${name}

echo "done"
