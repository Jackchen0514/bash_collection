#! /bin/bash
name=${1%%.*}
domain=$1

ss_port=$2
ss_password=$3

let local_port=ss_port+1
trojan_password=$3

sudo apt-get update -y

#install unzip && unzip cer
sudo apt-get install unzip
unzip *_${domain}_*.zip

##################################### trojan install
#install nginx
sudo apt-get install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx


wget https://github.com/ChunibyouH/GuoKer/archive/refs/heads/master.zip
// nginx static address
unzip -d /var/www/ master.zip;rm -rf master.zip


mv /etc/nginx/sites-enabled /etc/nginx/sites-enabled_bak
cat > /etc/nginx/conf.d/${domain}.conf << EOF
server {
    listen 80;
    listen [::]:80;
    listen 81 http2;
    server_name ${domain};
    root /var/www/GuoKer-master;
}
EOF

nginx -s reload


#install trojan
wget https://github.com/Jackchen0514/bash_collection/releases/download/v1.0/trojan-go-linux-$(dpkg --print-architecture).zip

unzip -d /usr/share/trojan-go trojan-go-linux-$(dpkg --print-architecture).zip;rm -rf trojan-go-linux-$(dpkg --print-architecture).zip

cp /usr/share/trojan-go/trojan-go /usr/local/bin

mv ${domain}.key /usr/share/trojan-go/${domain}.key
mv ${domain}.pem /usr/share/trojan-go/${domain}.pem

cat > /usr/share/trojan-go/config.json << EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "${trojan_password}"
    ],
    "ssl": {
        "cert": "/usr/share/trojan-go/${domain}.pem",
        "key": "/usr/share/trojan-go/${domain}.key",
        "sni": "${domain}"
    },
    "router": {
        "enabled": true,
        "block": [
            "geoip:private"
        ],
        "geoip": "/usr/share/trojan-go/geoip.dat",
        "geosite": "/usr/share/trojan-go/geosite.dat"
    }
}
EOF

cat > /etc/systemd/system/trojan-go.service << EOF
[Unit]
Description=Trojan-Go
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
User=root
ExecStart=/usr/share/trojan-go/trojan-go -config "/usr/share/trojan-go/config.json"
Restart=on-failure
RestartSec=15

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable trojan-go
systemctl start trojan-go

systemctl status trojan-go


################################### ss+obfs
sudo apt-get install shadowsocks-libev -y
sudo apt-get install simple-obfs -y

cat > /etc/shadowsocks-libev/config.json << EOF
{
    "server":["0.0.0.0"],
    "mode":"tcp_and_udp",
    "server_port":${ss_port},
    "local_port": 1080,
    "password":"${ss_password}",
    "timeout":600,
    "method":"chacha20-ietf-poly1305",
    "plugin":"obfs-server",
    "plugin_opts":"obfs=http;obfs-host=${domain};failover=127.0.0.1:8081",
    "workers":8
}
EOF

#nginx 8081
cat > /etc/nginx/conf.d/${proxy_host}_nginx.conf << EOF
server {
      listen 8081;
      server_name _;
      rewrite ^(.*) https://${proxy_host} permanent;
}
EOF
nginx -s reload

systemctl daemon-reload
systemctl enable shadowsocks-libev
systemctl restart shadowsocks-libev

systemctl status shadowsocks-libev
echo "done"

################################### trojan隧道

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
    "remote_addr": "${domain}",
    "remote_port": 443,
    "target_addr": "${domain}",
	  "target_port": ${ss_port},
    "password": [
        "${trojan_password}"
    ]
}
EOF

sleep 1
systemctl daemon-reload
systemctl enable trojan-forward-${name}
systemctl restart trojan-forward-${name}

systemctl status trojan-forward-${name}


####################gen uninstall.sh
cat > uninstall.sh << EOF
#! /bin/bash

rm -rf *.key *.pem

systemctl stop trojan-forward-${name}
rm -rf /usr/local/etc/trojan-go/forward-${name}.json
rm -rf /etc/systemd/system/trojan-forward-${name}.service


systemctl stop shadowsocks-libev
rm -rf /etc/nginx/conf.d/${proxy_host}_nginx.conf
rm -rf /etc/shadowsocks-libev/config.json

systemctl stop trojan-go
rm -rf /etc/systemd/system/trojan-go.service
rm -rf /usr/share/trojan-go/config.json
rm -rf /usr/share/trojan-go

systemctl stop nginx
rm -rf /etc/nginx/conf.d/${domain}.conf
rm -rf /var/www/GuoKer-master

sudo apt-get remove nginx -y
sudo apt-get remove shadowsocks-libev -y
sudo apt-get remove simple-obfs -y

systemctl daemon-reload
EOF

sleep 1
echo -e "trojan: \n${domain} \nport: 443 \npassword: ${trojan_password}\n"
echo -e "ss: \n${domain} \nport: ${local_port} \nmethod: chacha20-ietf-poly1305 \npassword: ${ss_password} \nobfs: http,host: ${domain}"
echo "done"
