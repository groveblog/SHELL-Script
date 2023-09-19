#!/bin/bash
#
#********************************************************************
#Author:            zhaoshulin
#QQ:                483607723
#Date:              2023-03-08
#FileName：         install_dns.sh
#URL:               https://zhaoshulin.top
#Description：      The test script
#Copyright (C):     2023 All rights reserved
#********************************************************************


DOMAIN=zhao.org
HOST=www
HOST_IP=10.0.0.100
LOCALHOST=`hostname -I | awk '{print $1}'`

. /etc/os-release


color () {
    RES_COL=60
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    SETCOLOR_WARNING="echo -en \\033[1;33m"
    SETCOLOR_NORMAL="echo -en \E[0m"
    echo -n "$1" && $MOVE_TO_COL
    echo -n "["
    if [ $2 = "success" -o $2 = "0" ] ;then
        ${SETCOLOR_SUCCESS}
        echo -n $"  OK  "    
    elif [ $2 = "failure" -o $2 = "1"  ] ;then 
        ${SETCOLOR_FAILURE}
        echo -n $"FAILED"
    else
        ${SETCOLOR_WARNING}
        echo -n $"WARNING"
    fi
    ${SETCOLOR_NORMAL}
    echo -n "]"
    echo 
}


install_dns () {
    if [ $ID = 'centos' -o $ID = 'rocky' ];then
	    yum install -y  bind bind-utils
	elif [ $ID = 'ubuntu' ];then
        apt update
        apt install -y bind9 bind9-utils bind9-host
	else
	    color "不支持此操作系统，退出!" 1
	    exit
	fi
    
}

config_dns () {
    if [ $ID = 'centos' -o $ID = 'rocky' ];then
	    sed -i -e '/listen-on/s/127.0.0.1/localhost/' -e '/allow-query/s/localhost/any/' -e 's/dnssec-enable yes/dnssec-enable no/' -e 's/dnssec-validation yes/dnssec-validation no/'  /etc/named.conf
        cat >> 	/etc/named.rfc1912.zones <<EOF
zone "$DOMAIN" IN {
    type master;
    file  "$DOMAIN.zone";
};
EOF
        cat > /var/named/$DOMAIN.zone <<EOF
\$TTL 1D
@	IN SOA	master admin (
					1	; serial
					1D	; refresh
					1H	; retry
					1W	; expire
					3H )	; minimum
	        NS	 master
master      A    ${LOCALHOST}         
$HOST     	A    $HOST_IP
EOF
        chmod 640 /var/named/$DOMAIN.zone
        chgrp named /var/named/$DOMAIN.zone
	elif [ $ID = 'ubuntu' ];then
        sed -i 's/dnssec-validation auto/dnssec-validation no/' /etc/bind/named.conf.options
        cat >> 	/etc/bind/named.conf.default-zones <<EOF
zone "$DOMAIN" IN {
    type master;
    file  "/etc/bind/$DOMAIN.zone";
};
EOF
        cat > /etc/bind/$DOMAIN.zone <<EOF
\$TTL 1D
@	IN SOA	master admin (
					1	; serial
					1D	; refresh
					1H	; retry
					1W	; expire
					3H )	; minimum
	        NS	 master
master      A    ${LOCALHOST}         
$HOST     	A    $HOST_IP
EOF
        chgrp bind  /etc/bind/$DOMAIN.zone
	else
	    color "不支持此操作系统，退出!" 1
	    exit
	fi
    
    

}

start_service () {
    systemctl enable named
    systemctl restart named
	systemctl is-active named.service
	if [ $? -eq 0 ] ;then 
        color "DNS 服务安装成功!" 0  
    else 
        color "DNS 服务安装失败!" 1
        exit 1
    fi   
}

install_dns
config_dns
start_service
