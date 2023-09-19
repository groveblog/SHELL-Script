#!/bin/bash
starttime=`date +'%Y-%m-%d %H:%M:%S'`
FILE_PATH=/users/hsrecorder/output/recorder_file
LOG_PATH=/users/hsrecorder/output/recorder_file/gzip_call_center/upload.log
LOG_DATE=$(date -d "372 day ago" +"%Y-%m-%d")
LOCAL_DATE=`date +'%Y-%m-%d %H:%M:%S'`
TMP_DIR=/users/hsrecorder/output/recorder_file/gzip_call_center/tmplog
MD5_LOCALFILE=/users/hsrecorder/output/recorder_file/gzip_call_center/tmplog/md5_local.txt
MD5_FTPFILE=/users/hsrecorder/output/recorder_file/gzip_call_center/md5_ftp.txt

echo "脚本运行开始=======================" >> ${LOG_PATH}
echo ${starttime} >> ${LOG_PATH}  #echo开始时间到日志脚本
cd  ${FILE_PATH}
if [ $? -eq 0 ];then
    echo "进入[${FILE_PATH}]目录">> ${LOG_PATH}
    if [[ -d ${FILE_PATH}/${LOG_DATE} ]]; then
        echo ${FILE_PATH}/${LOG_DATE}"日志目录存在" >> ${LOG_PATH}
        /bin/tar -czvf ${LOG_DATE}.tar.gz ${LOG_DATE} --remove-files
        if [ $? -eq 0 ];then
            echo ${FILE_PATH}/${LOG_DATE}"压缩完成" >> ${LOG_PATH}
        else
            echo ${FILE_PATH}/${LOG_DATE}"压缩失败或已压缩!" >> ${LOG_PATH}
            exit
        fi
    else
        echo ${FILE_PATH}/${LOG_DATE}"日志目录不存在!" >> ${LOG_PATH}
        exit
    fi
else
    echo "[$LOCAL_DATE]:目录不存在!">>${LOG_PATH}
    exit
fi

# 日志上传
if [ -f  ${FILE_PATH}/${LOG_DATE}.tar.gz ]; then
    echo "开始上传${FILE_PATH}/${LOG_DATE}.tar.gz 文件" >> ${LOG_PATH}
ftp -i  -n 10.101.249.97 <<-EOF
        user call_center call_center0721
        prompt off
        cd /call_center/call_center/
        lcd ${FILE_PATH}
        put ${LOG_DATE}.tar.gz
        close
        bye
EOF
    if [ $? -eq 0 ];then   #如果上条脚本返回不是0
        echo "${FILE_PATH}/${LOG_DATE}.tar.gz日志上传成功">> ${LOG_PATH}
    else
        echo "${FILE_PATH}/${LOG_DATE}.tar.gz日志上传失败">> ${LOG_PATH}
        exit
    fi
else 
    echo "${FILE_PATH}/${LOG_DATE}.tar.gz 文件不存在！请检查文件！">> ${LOG_PATH}
    exit
fi


sleep 1
# 日志下载验证
ftp -i  -n 10.101.249.97 <<-EOF
        user call_center call_center0721
        binary
        prompt off
        cd /call_center/call_center/
        lcd ${TMP_DIR}
        get ${LOG_DATE}.tar.gz
        close
        bye
EOF
if [ -f ${TMP_DIR}/${LOG_DATE}.tar.gz ];then
    echo "[${TMP_DIR}/${LOG_DATE}.tar.gz]ftp日志下载成功!">> ${LOG_PATH}
    md5sum ${TMP_DIR}/${LOG_DATE}.tar.gz|awk -F " " '{print $1}' > ${MD5_FTPFILE}
    if [ $? -eq 0 ];then
        echo "${TMP_DIR}/${LOG_DATE}.tar.gz文件md5值生成成功!">> ${LOG_PATH}
    else
        echo "${TMP_DIR}/${LOG_DATE}.tar.gz文件md5值生成失败!">> ${LOG_PATH}
        exit
    fi
    md5sum ${FILE_PATH}/${LOG_DATE}.tar.gz|awk -F " " '{print $1}'> ${MD5_LOCALFILE}
    if [ $? -eq 0 ];then
        echo "${FILE_PATH}/${LOG_DATE}.tar.gz文件md5值生成成功!">> ${LOG_PATH}
    else
        echo "${FILE_PATH}/${LOG_DATE}.tar.gz文件md5值生成失败!">> ${LOG_PATH}
        exit
    fi
    yy=`cat ${MD5_LOCALFILE}`
    echo "本地日志md5值为:[${yy}]">> ${LOG_PATH}
    tt=`cat ${MD5_FTPFILE}`
    echo "ftp日志md5值为:[${tt}]">> ${LOG_PATH}
    if [ $tt == $yy ] && [ -n $tt ] && [ -n $yy ] ;then
        echo "md5值相同">>${LOG_PATH}
        rm -f ${TMP_DIR}/${LOG_DATE}.tar.gz
            if [[ $? -eq 0 ]];then
                echo "ftp临时下载文件 ${TMP_DIR}/${LOG_DATE}.tar.gz 已删除" >> ${LOG_PATH}
            else
                echo "ftp临时下载文件 ${TMP_DIR}/${LOG_DATE}.tar.gz 删除失败!" >> ${LOG_PATH}
                exit
            fi    
        rm -f ${FILE_PATH}/${LOG_DATE}.tar.gz
            if [[ $? -eq 0 ]];then
                echo "本地文件[${FILE_PATH}/${LOG_DATE}.tar.gz]已删除" >> ${LOG_PATH}
            else
                echo "本地文件[${FILE_PATH}/${LOG_DATE}.tar.gz]删除失败!" >> ${LOG_PATH}
                exit
            fi
    else
        echo "本地文件[${FILE_PATH}/${LOG_DATE}.tar.gz] 和 ftp临时下载文件 ${TMP_DIR}/${LOG_DATE}.tar.gz的MD5值不同，请检查文件!" >> ${LOG_PATH}
        exit
    fi
else 
    echo "[${TMP_DIR}/${LOG_DATE}.tar.gz]ftp日志下载失败!">> ${LOG_PATH}
    exit
fi
endtime=`date +'%Y-%m-%d %H:%M:%S'`
start_seconds=$(date --date="$starttime" +%s)
end_seconds=$(date --date="$endtime" +%s)
echo ${endtime}" :本次日志压缩上传脚本运行时间： "$((end_seconds-start_seconds))"s" >>${LOG_PATH}
echo "脚本运行结束=======================" >>${LOG_PATH}