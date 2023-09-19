#!/bin/bash
#
#********************************************************************
#Author:            zhaoshulin
#QQ:                483607723
#Date:              2022-12-19
#FileName：         install_tomcat.sh
#URL:               https://zhaoshulin.top
#Description：      The test script
#Copyright (C):     2023 All rights reserved
#********************************************************************

JDK_FILE="jdk-11.0.15.1_linux-x64_bin.tar.gz"
TOMCAT_FILE="apache-tomcat-9.0.64.tar.gz"
JDK_DIR="/usr/local"
TOMCAT_DIR="/usr/local"
DIR=`pwd`

color () {
    RES_COL=60
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    SETCOLOR_WARNING="echo -en \\033[1;33m"
    SETCOLOR_NORMAL="echo -en \E[0m"
    echo -n "$2" && $MOVE_TO_COL
    echo -n "["
    if [ $1 = "success" -o $1 = "0" ] ;then
        ${SETCOLOR_SUCCESS}
        echo -n $"  OK  "    
    elif [ $1 = "failure" -o $1 = "1"  ] ;then
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



install_jdk(){
if !  [  -f "$DIR/$JDK_FILE" ];then
    color 1 "$JDK_FILE 文件不存在" 
    exit; 
elif [ -d $JDK_DIR/jdk ];then
    color 1  "JDK 已经安装" 
    exit
else 
    [ -d "$JDK_DIR" ] || mkdir -pv $JDK_DIR
fi
tar xvf $DIR/$JDK_FILE  -C $JDK_DIR
cd  $JDK_DIR && ln -s jdk* jdk 

cat >  /etc/profile.d/jdk.sh <<EOF
export JAVA_HOME=$JDK_DIR/jdk
export PATH=\$PATH:\$JAVA_HOME/bin
#export JRE_HOME=\$JAVA_HOME/jre
#export CLASSPATH=.:\$JAVA_HOME/lib/:\$JRE_HOME/lib/
EOF
.  /etc/profile.d/jdk.sh
java -version && color 0 "JDK 安装完成" || { color 1  "JDK 安装失败" ; exit; }

}

install_tomcat(){
if ! [ -f "$DIR/$TOMCAT_FILE" ];then
    color 1 "$TOMCAT_FILE 文件不存在" 
    exit; 
elif [ -d $TOMCAT_DIR/tomcat ];then
    color 1 "TOMCAT 已经安装" 
    exit
else 
    [ -d "$TOMCAT_DIR" ] || mkdir -pv $TOMCAT_DIR
fi
tar xf $DIR/$TOMCAT_FILE -C $TOMCAT_DIR
cd  $TOMCAT_DIR && ln -s apache-tomcat-*/  tomcat
echo "PATH=$TOMCAT_DIR/tomcat/bin:"'$PATH' > /etc/profile.d/tomcat.sh
id tomcat &> /dev/null || useradd -r -s /sbin/nologin tomcat

cat > $TOMCAT_DIR/tomcat/conf/tomcat.conf <<EOF
JAVA_HOME=$JDK_DIR/jdk
EOF

chown -R tomcat.tomcat $TOMCAT_DIR/tomcat/

cat > /lib/systemd/system/tomcat.service  <<EOF
[Unit]
Description=Tomcat
#After=syslog.target network.target remote-fs.target nss-lookup.target
After=syslog.target network.target 

[Service]
Type=forking
EnvironmentFile=$TOMCAT_DIR/tomcat/conf/tomcat.conf
ExecStart=$TOMCAT_DIR/tomcat/bin/startup.sh
ExecStop=$TOMCAT_DIR/tomcat/bin/shutdown.sh
RestartSec=3
PrivateTmp=true
User=tomcat
Group=tomcat

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now tomcat.service &> /dev/null
systemctl is-active tomcat.service &> /dev/null &&  color 0 "TOMCAT 安装完成" || { color 1 "TOMCAT 安装失败" ; exit; }

}

install_jdk 
install_tomcat