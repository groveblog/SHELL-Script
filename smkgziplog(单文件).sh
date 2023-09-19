#!/bin/bash
starttime=`date +'%Y-%m-%d %H:%M:%S'`
FILE_PATH=/home/smkapp/nginx/log/
LOG_PATH=/root/gzip_nginx/upload.log
LOG_DATE=$(date -d "36 day ago" +"%Y%m%d")
LOCAL_DATE=`date +'%Y-%m-%d %H:%M:%S'`
TMP_DIR=/root/gzip_nginx/tmplog
MD5_LOCALFILE=/root/gzip_nginx/tmplog/md5_local.txt
MD5_FTPFILE=/root/gzip_nginx/tmplog/md5_ftp.txt

echo "脚本运行开始=======================" >> ${LOG_PATH}
echo ${starttime} >> ${LOG_PATH}  #echo开始时间到日志脚本
cd  ${FILE_PATH}
if [ $? -eq 0 ];then
    echo "进入[${FILE_PATH}]目录">> ${LOG_PATH}
    if [[ -f ${FILE_PATH}/access.log-${LOG_DATE}.gz ]]; then
        echo ${FILE_PATH}/access.log-${LOG_DATE}.gz"日志文件存在" >> ${LOG_PATH}
        # /bin/tar -czvf default.${LOG_DATE}.tar.gz default.${LOG_DATE}*.log --remove-files
        # if [ $? -eq 0 ];then
        #     echo ${FILE_PATH}/${LOG_DATE}"压缩完成" >> ${LOG_PATH}
        # else
        #     echo ${FILE_PATH}/${LOG_DATE}"压缩失败或已压缩!" >> ${LOG_PATH}
        #     exit
        # fi
    else
        echo ${FILE_PATH}/access.log-${LOG_DATE}.gz"日志文件不存在!" >> ${LOG_PATH}
        exit
    fi
else
    echo "[$LOCAL_DATE]:文件不存在!">>${LOG_PATH}
    exit
fi

# 日志上传
if [ -f  ${FILE_PATH}/access.log-${LOG_DATE}.gz ]; then
    echo "开始上传${FILE_PATH}/access.log-${LOG_DATE}.gz 文件" >> ${LOG_PATH}
ftp -i  -n 10.101.249.97 <<-EOF
        user netpay smk_netpay99
        prompt off
        cd /netpay/172.16.2.112/nginx/
        lcd ${FILE_PATH}
        put access.log-${LOG_DATE}.gz
        close
        bye
EOF
    if [ $? -eq 0 ];then   #如果上条脚本返回不是0
        echo "${FILE_PATH}/access.log-${LOG_DATE}.gz日志上传成功">> ${LOG_PATH}
    else
        echo "${FILE_PATH}/access.log-${LOG_DATE}.gz日志上传失败">> ${LOG_PATH}
        exit
    fi
else 
    echo "${FILE_PATH}/access.log-${LOG_DATE}.gz 文件不存在！请检查文件！">> ${LOG_PATH}
    exit
fi


sleep 1
# 日志下载验证
ftp -i  -n 10.101.249.97 <<-EOF
        user netpay smk_netpay99
        binary
        prompt off
        cd /netpay/172.16.2.112/nginx/
        lcd ${TMP_DIR}
        get access.log-${LOG_DATE}.gz
        close
        bye
EOF
if [ -f ${TMP_DIR}/access.log-${LOG_DATE}.gz ];then
    echo "[${TMP_DIR}/access.log-${LOG_DATE}.gz]ftp日志下载成功!">> ${LOG_PATH}
    md5sum ${TMP_DIR}/access.log-${LOG_DATE}.gz|awk -F " " '{print $1}' > ${MD5_FTPFILE}
    if [ $? -eq 0 ];then
        echo "${TMP_DIR}/access.log-${LOG_DATE}.gz文件md5值生成成功!">> ${LOG_PATH}
    else
        echo "${TMP_DIR}/access.log-${LOG_DATE}.gz文件md5值生成失败!">> ${LOG_PATH}
        exit
    fi
    md5sum ${FILE_PATH}/access.log-${LOG_DATE}.gz|awk -F " " '{print $1}'> ${MD5_LOCALFILE}
    if [ $? -eq 0 ];then
        echo "${FILE_PATH}/access.log-${LOG_DATE}.gz文件md5值生成成功!">> ${LOG_PATH}
    else
        echo "${FILE_PATH}/access.log-${LOG_DATE}.gz文件md5值生成失败!">> ${LOG_PATH}
        exit
    fi
    yy=`cat ${MD5_LOCALFILE}`
    echo "本地日志md5值为:[${yy}]">> ${LOG_PATH}
    tt=`cat ${MD5_FTPFILE}`
    echo "ftp日志md5值为:[${tt}]">> ${LOG_PATH}
    if [ $tt == $yy ] && [ -n $tt ] && [ -n $yy ] ;then
        echo "md5值相同">>${LOG_PATH}
        rm -f ${TMP_DIR}/access.log-${LOG_DATE}.gz
            if [[ $? -eq 0 ]];then
                echo "ftp临时下载文件 ${TMP_DIR}/access.log-${LOG_DATE}.gz 已删除" >> ${LOG_PATH}
            else
                echo "ftp临时下载文件 ${TMP_DIR}/access.log-${LOG_DATE}.gz 删除失败!" >> ${LOG_PATH}
                exit
            fi    
        rm -f ${FILE_PATH}/access.log-${LOG_DATE}.gz
            if [[ $? -eq 0 ]];then
                echo "本地文件[${FILE_PATH}/access.log-${LOG_DATE}.gz]已删除" >> ${LOG_PATH}
            else
                echo "本地文件[${FILE_PATH}/access.log-${LOG_DATE}.gz]删除失败!" >> ${LOG_PATH}
                exit
            fi
    else
        echo "本地文件[${FILE_PATH}/access.log-${LOG_DATE}.gz] 和 ftp临时下载文件 ${TMP_DIR}/access.log-${LOG_DATE}.gz的MD5值不同，请检查文件!" >> ${LOG_PATH}
        exit
    fi
else 
    echo "[${TMP_DIR}/access.log-${LOG_DATE}.gz]ftp日志下载失败!">> ${LOG_PATH}
    exit
fi
endtime=`date +'%Y-%m-%d %H:%M:%S'`
start_seconds=$(date --date="$starttime" +%s)
end_seconds=$(date --date="$endtime" +%s)
echo ${endtime}" :本次日志压缩上传脚本运行时间： "$((end_seconds-start_seconds))"s" >>${LOG_PATH}
echo "脚本运行结束=======================" >>${LOG_PATH}