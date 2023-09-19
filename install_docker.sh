#!/bin/bash
#
#********************************************************************
#Author:            zhaoshulin
#QQ:                29308620
#Date:              2023-02-26
#FileName:          install_docker.sh
#URL:               https://www.zhaoshulin.top
#Description:       The test script
#Copyright (C):     2023 All rights reserved
#********************************************************************

DOCKER_VERSION="20.10.10"
UBUNTU_DOCKER_VERSION="5:${DOCKER_VERSION}~3-0~`lsb_release -si`-`lsb_release -cs`"
#UBUNTU_DOCKER_VERSION="5:20.10.9~3-0~`lsb_release -si`-`lsb_release -cs`"
#UBUNTU_DOCKER_VERSION="5:19.03.14~3-0~lsb_release -si-`lsb_release -cs`"

COLOR_SUCCESS="echo -e \\033[1;32m"
COLOR_FAILURE="echo -e \\033[1;31m"
END="\033[m"

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


install_docker(){
    if [ $ID = "centos" -o $ID = "rocky" ];then
        if [ $VERSION_ID = "7" ];then
            cat >  /etc/yum.repos.d/docker.repo  <<EOF
[docker]
name=docker
gpgcheck=0
#baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable/
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/7/x86_64/stable/
EOF
        else     
            cat >  /etc/yum.repos.d/docker.repo  <<EOF
[docker]
name=docker
gpgcheck=0
#baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/8/x86_64/stable/
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/8/x86_64/stable/
EOF
        fi
	    yum clean all 
        ${COLOR_FAILURE} "Docker有以下版本"${END}
        yum list docker-ce --showduplicates
        ${COLOR_FAILURE}"5秒后即将安装: docker-"${DOCKER_VERSION}" 版本....."${END}
        ${COLOR_FAILURE}"如果想安装其它Docker版本，请按ctrl+c键退出，修改版本再执行"${END}
        sleep 5
        yum -y install docker-ce-$DOCKER_VERSION docker-ce-cli-$DOCKER_VERSION  \
            || { color "Base,Extras的yum源失败,请检查yum源配置" 1;exit; }
    else
	    dpkg -s docker-ce &> /dev/null && $COLOR"Docker已安装，退出" 1 && exit
        apt update || { color "更新包索引失败" 1 ; exit 1; }  
        apt  -y install apt-transport-https ca-certificates curl software-properties-common || \
            { color "安装相关包失败" 1 ; exit 2;  }  
        curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
        add-apt-repository "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
        apt update
        ${COLOR_FAILURE} "Docker有以下版本"${END}
        apt-cache madison docker-ce
        ${COLOR_FAILURE}"5秒后即将安装: docker-"${UBUNTU_DOCKER_VERSION}" 版本....."${END}
        ${COLOR_FAILURE}"如果想安装其它Docker版本，请按ctrl+c键退出，修改版本再执行"${END}
        sleep 5
        apt -y  install docker-ce=${UBUNTU_DOCKER_VERSION} docker-ce-cli=${UBUNTU_DOCKER_VERSION}
    fi
    if [ $? -eq 0 ];then
        color "安装软件包成功"  0
    else
        color "安装软件包失败，请检查网络配置" 1
        exit
    fi
        
}

config_docker (){
    mkdir -p /etc/docker
    tee /etc/docker/daemon.json <<-'EOF'
{
	  "registry-mirrors": ["https://si7y70hh.mirror.aliyuncs.com"],
	  "insecure-registries":["harbor.magedu.org:80"]
}
EOF
    systemctl daemon-reload
    systemctl enable docker
    systemctl restart docker
    docker version && color "Docker 安装成功" 0 ||  color "Docker 安装失败" 1
}


set_alias (){
	echo 'alias rmi="docker images -qa|xargs docker rmi -f"' >> ~/.bashrc
	echo 'alias rmc="docker ps -qa|xargs docker rm -f"' >> ~/.bashrc
}


install_docker
config_docker 
set_alias
