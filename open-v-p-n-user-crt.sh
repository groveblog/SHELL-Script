#!/bin/bash
#
#********************************************************************
#Author:            zhaoshulin
#QQ:                483607723
#Date:              2023-03-25
#FileName：         open-v-p-n-user-crt.sh
#URL:               https://zhaoshulin.top
#Description：      The test script
#Copyright (C):     2023 All rights reserved
#********************************************************************


OPENVPN_SERVER=openvpn.zhaoshulin.com
PASS=123456


remove_cert () {
    rm -rf /etc/openvpn/client/${NAME} 
    find /etc/openvpn/ -name "$NAME.*" -delete
}

create_cert () {
    cd /etc/openvpn/easy-rsa
    ./easyrsa  gen-req ${NAME} nopass <<EOF

EOF

    cd /etc/openvpn/easy-rsa
    ./easyrsa import-req /etc/openvpn/easy-rsa/pki/reqs/${NAME}.req ${NAME}


    ./easyrsa sign client ${NAME} <<EOF
yes
EOF

    mkdir  /etc/openvpn/client/${NAME}
    cp /etc/openvpn/easy-rsa/pki/issued/${NAME}.crt /etc/openvpn/client/${NAME}
    cp /etc/openvpn/easy-rsa/pki/private/${NAME}.key  /etc/openvpn/client/${NAME}
    cp /etc/openvpn/server/{ca.crt,ta.key} /etc/openvpn/client/${NAME}
    cat >  /etc/openvpn/client/${NAME}/client.ovpn <<EOF
client
dev tun
proto tcp
remote $OPENVPN_SERVER 1194
resolv-retry infinite
nobind
#persist-key
#persist-tun
ca ca.crt
cert $NAME.crt
key $NAME.key
remote-cert-tls server
tls-auth ta.key 1
cipher AES-256-CBC
verb 3
compress lz4-v2
EOF

    echo "证书存放路径:/etc/openvpn/client/${NAME},证书文件如下:"
    echo -e "\E[1;32m******************************************************************\E[0m"
    ls -l /etc/openvpn/client/${NAME}
    echo -e "\E[1;32m******************************************************************\E[0m"
    cd /etc/openvpn/client/${NAME} 
    zip -qP "$PASS" /root/${NAME}.zip * 
    echo "证书的打包文件已生成: /root/${NAME}.zip"
}


read -p "请输入用户的姓名拼音(如:zhaoshulin): " NAME

remove_cert
create_cert
