#! /bin/bash


sudo apt-get update -y

sudo apt-get install shadowsocks-libev -y

sudo apt-get install simple-obfs -y


ss_port=18388
home_domain=$1
ss_password=$2
ip_addr=`ping ${home_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`

cat > /etc/shadowsocks-libev/config.json<<EOF
{
    "server":["0.0.0.0"],
    "mode":"tcp_and_udp",
    "server_port":${ss_port},
    "local_port":1080,
    "password":"${ss_password}",
    "timeout":600,
    "method":"chacha20-ietf-poly1305",
    "plugin":"obfs-server",
    "plugin_opts":"obfs=http;obfs-host=www.bing.com;failover=127.0.0.1:8081",
    "workers":8
}
EOF

sleep 1

systemctl enable shadowsocks-libev
systemctl restart shadowsocks-libev

sleep 1

# 设置防火墙
sudo apt-get install firewalld -y
systemctl enable firewalld
systemctl start firewalld

# 开放22端口
firewall-cmd --permanent --zone=public --add-port=22/tcp

# 指定IP开放18388端口
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address=${ip_addr} port protocol="tcp" port=${ss_port} 
accept"
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address=${ip_addr} port protocol="udp" port=${ss_port} 
accept"

firewall-cmd --reload


# 开启定时刷新IP, 相应的开启防火墙
cat > test.cron<<EOF
*/1 * * * * curl -s https://raw.githubusercontent.com/Jackchen0514/bash_collection/master/test.sh | bash -s ${home_domain}
EOF
crontab test.cron

# nginx 8081
apt-get install nginx -y
sed -i 's/80/8081/g' /etc/nginx/sites-enabled/default
nginx -s reload
