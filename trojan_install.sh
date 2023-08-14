#! /bin/bash

#install nginx
sudo apt-get install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx


wget https://github.com/ChunibyouH/GuoKer/archive/refs/heads/master.zip
// nginx static address
unzip -d　/var/www/html master.zip

domain=$1

cat > /etc/nginx/conf.d/${domain}.conf << EOF
server {
    listen 80;
    listen [::]:80;
    listen 81 http2;
    server_name ${domain};
    root /var/www/html/GuoKer-master;
}
EOF

nginx -s reload


#install trojan
wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip

unzip -d /usr/share/trojan-go trojan-go-linux-amd64.zip

cp /usr/share/trojan-go/trojan-go /usr/local/bin

cp ${domain}.key /usr/share/trojan-go/${domain}.key
cp ${domain}.pem /usr/share/trojan-go/${domain}.pem

cat > /usr/share/trojan-go/config.json << EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "Carlosx0514!"
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

