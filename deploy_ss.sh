#! /bin/bash


sudo apt-get update -y

sudo apt-get install shadowsocks-libev -y

sudo apt-get install simple-obfs -y

ss_port=$1
ss_password=$2
proxy_host=$3

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
    "plugin_opts":"obfs=http;obfs-host=${proxy_host};failover=127.0.0.1:8081",
    "workers":8
}
EOF

#nginx 8081
cat > /etc/nginx/conf.d/${proxy_host}_nginx.conf << EOF
server {
      listen 8081;
      server_name _;
      location / {
        proxy_pass  http://${proxy_host}:80;
      }
}
EOF
nginx -s reload

systemctl enable shadowsocks-libev
systemctl restart shadowsocks-libev

echo "done"
