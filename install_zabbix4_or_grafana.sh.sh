#!/bin/bash
#
#********************************************************************
#Author:            zhaoshulin
#QQ:                483607723
#Date:              2023-09-19
#FileName：         install_zabbix4_or_grafana.sh
#URL:               https://zhaoshulin.top
#Description：      The test script
#Copyright (C):     2023 All rights reserved
#********************************************************************
#此脚本用于RHEL7安装Zabbix4.4和Grafana7.2.2

cat << EOF
********请选择需要安装的组件：********
(1) Install Zabbix 4.4
(2) Install Grafana 7.2.2
EOF

read -p "请选择需要安装的组件：" digit

case $digit in
	"1" )
		echo "Install Zabbix 4.4"

		#关闭SELinux
		if [ $(getenforce) = "Enforcing" ]; then
		setenforce 0
		sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
		echo "Selinux已关闭!"
		fi

		#安装zabbix的repo源
		if [ $(curl -sL -w "%{http_code}" "https://mirror.tuna.tsinghua.edu.cn/" -o /dev/null) -eq 200 ];then
			echo "地址通畅，继续安装！！！"
			rpm -ivh https://mirror.tuna.tsinghua.edu.cn/zabbix/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
			sed -i -e 's/repo.zabbix.com/mirror.tuna.tsinghua.edu.cn\/zabbix/g' /etc/yum.repos.d/zabbix.repo
			yum clean all
		else
			echo "地址不通畅，请检查网络！！！"
			exit
		fi

		#安装zabbix和mariadb
		yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-agent mariadb mariadb-server
		systemctl start mariadb.service
		systemctl enable mariadb.service
		mysql -e "create database zabbix character set utf8 collate utf8_bin;"
		mysql -e "grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';"
		mysql -e "flush privileges;"
		zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -pzabbix zabbix

		#修改zabbix-server配置文件
		cp /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.bak
		sed -i 's/# DBHost=localhost/DBHost=localhost/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# DBPassword=/DBPassword=zabbix/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# StartPollers=5/StartPollers=40/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# StartPreprocessors=3/StartPreprocessors=20/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# StartPollersUnreachable=1/StartPollersUnreachable=10/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# StartTrappers=5/StartTrappers=15/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# StartPingers=1/StartPingers=15/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# StartDiscoverers=1/StartDiscoverers=5/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# StartVMwareCollectors=0/StartVMwareCollectors=10/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# VMwareFrequency=60/VMwareFrequency=10/' /etc/zabbix/zabbix_server.conf
		sed -i 's/^# \(VMwarePerfFrequency=60\)/\1/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# VMwareCacheSize=8M/VMwareCacheSize=160M/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# VMwareTimeout=10/VMwareTimeout=300/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# HousekeepingFrequency=1/HousekeepingFrequency=24/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# MaxHousekeeperDelete=5000/MaxHousekeeperDelete=10000/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# CacheSize=8M/CacheSize=4G/' /etc/zabbix/zabbix_server.conf
		sed -i 's/# ValueCacheSize=8M/ValueCacheSize=2G/' /etc/zabbix/zabbix_server.conf

		#修改zabbix-agentd配置文件
		sed -i 's/# Timeout=3/Timeout=30/' /etc/zabbix/zabbix_agentd.conf

		#修改zabbix-web配置文件
		cp /etc/httpd/conf.d/zabbix.conf /etc/httpd/conf.d/zabbix.conf.bak
		sed -i 's/memory_limit 128M/memory_limit 512M/' /etc/httpd/conf.d/zabbix.conf
		sed -i 's/# php_value date.timezone Europe\/Riga/php_value date.timezone Asia\/Shanghai/' /etc/httpd/conf.d/zabbix.conf
		systemctl restart zabbix-server zabbix-agent httpd
		systemctl enable zabbix-server zabbix-agent httpd
		
		#开放端口
		firewall-cmd --zone=public --add-port=10050/tcp --permanent
		firewall-cmd --zone=public --add-port=10051/tcp --permanent
		firewall-cmd --zone=public --add-port=80/tcp --permanent
		firewall-cmd --reload

		#判断zabbix网页是否正常打开
		if [ $(curl -sL -w "%{http_code}" "http://127.0.0.1/zabbix" -o /dev/null) -eq 200 ]; then
			echo "Zabbix安装成功！！！"
		else
			echo "Zabbix安装失败！！！"
		fi
		;;
	"2" )
		echo "Install Grafana 7.2.2"
		
		#判断wget是否安装
		command -v wget
		if [ $? -ne 0 ]; then
			yum -y install wget
			echo "wget安装成功！！！"
		else
			echo "wget已安装！！！"
		fi

		#判断地址是否通畅，通畅则下载rpm包
		if [ $(curl -sL -w "%{http_code}" "https://mirror.tuna.tsinghua.edu.cn/" -o /dev/null) -eq 200 ];then
			echo "地址通畅，继续安装！！！"
			wget https://mirror.tuna.tsinghua.edu.cn/grafana/yum/rpm/grafana-7.2.2-1.x86_64.rpm
		else
			echo "地址不通畅，请检查网络！！！"
			exit
		fi

		#安装Grafana
		yum -y install fontconfig freetype* urw-fonts
		rpm -ivh /root/grafana-7.2.2-1.x86_64.rpm
		grafana-cli plugins install alexanderzobnin-zabbix-app
		sed -i 's/;allow_loading_unsigned_plugins =/allow_loading_unsigned_plugins = alexanderzobnin-zabbix-datasource/' /etc/grafana/grafana.ini
		systemctl enable grafana-server
		systemctl start grafana-server

		#开放端口
		firewall-cmd --zone=public --add-port=3000/tcp --permanent
		firewall-cmd --reload

		#判断grafana网页是否正常打开
		if [ $(curl -sL -w "%{http_code}" "http://127.0.0.1:3000" -o /dev/null) -eq 200 ]; then
			echo "Grafana安装成功！！！"
		else
			echo "Grafana安装失败！！！"
		fi
		;;
	"*" )
		echo "Error"
		;;	
esac
