#! /bin/bash
file="/root/ip.txt"
ADDR=$1
TMPSTR=`ping ${ADDR} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
SERVER_PORT=18388
addRule(){
   echo "addRule"
   firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=${TMPSTR} masquerade"
   firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address=${TMPSTR} port protocol="tcp" port=${SERVER_PORT} accept"
   firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address=${TMPSTR} port protocol="udp" port=${SERVER_PORT} accept"
   sleep 1
   firewall-cmd --reload
   firewall-cmd --list-all
}
rmRule(){
   echo "deleteRule"
   firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=${TMPSTR} masquerade"
   firewall-cmd --permanent --remove-rich-rule="rule family="ipv4" source address=${TMPSTR} port protocol="tcp" port=${SERVER_PORT} accept"
   firewall-cmd --permanent --remove-rich-rule="rule family="ipv4" source address=${TMPSTR} port protocol="udp" port=${SERVER_PORT} accept"
   sleep 1
   firewall-cmd --reload
   firewall-cmd --list-all
}
changeRule(){
    echo "changeRule"
    rmRule
    echo $2 > $3
    sleep 1
    addRule
    sleep 1
}
echo ${TMPSTR}
if [ -f "$file" ]; then
  old=$(cat $file)
  if [ "$old" = "${TMPSTR}" ]; then
    echo "do nothing"
  else
    changeRule $old ${TMPSTR} $file
  fi
else
  echo ${TMPSTR} > $file
  addRule ${TMPSTR}
fi
