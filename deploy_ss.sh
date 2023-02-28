#! /bin/bash


sudo apt-get update -y

sudo apt-get install shadowsocks-libev -y

sudo apt-get install simple-obfs -y


cat > /etc/shadowsocks-libev/config.json<<EOF
{
    "server":["0.0.0.0"],
    "mode":"tcp_and_udp",
    "server_port":12345,
    "local_port":1080,
    "password":"Qes34fd4d@$%dc",
    "timeout":600,
    "method":"chacha20-ietf-poly1305",
    "plugin":"obfs-server",
    "plugin_opts":"obfs=http;obfs-host=hk.xinsi.us;failover=127.0.0.1:8081",
    "workers":8
}
EOF

sleep 1

systemctl enable shadowsocks-libev
systemctl restart shadowsocks-libev

sleep 1

# nginx 8081
apt-get install nginx -y
# sed -i 's/80/8081/g' /etc/nginx/sites-enabled/default
cat > /etc/shadowsocks-libev/conf.d/hk.xinsi.us.conf << EOF
server {
      listen 8081;
      server_name _;
      location / {
        proxy_pass  http://hk.xinsi.us:80;
      }
}
EOF
nginx -s reload

echo "done"
