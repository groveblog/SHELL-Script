#!/bin/bash
starttime=`date +'%Y-%m-%d %H:%M:%S'`
FILE_PATH=/httx/log/showcase/
LOG_PATH=/httx/log/showcase/upload.txt
LOG_DATE=$(date -d "5 day ago" +"%Y%m%d")
LOCAL_DATE=`date +'%Y-%m-%d %H:%M:%S'`
OSS_PATH=oss://jtsk-application-log-storage/showcase/10.123.110.112

echo "脚本运行开始=======================" >> ${LOG_PATH}
echo ${starttime} >> ${LOG_PATH}  #echo开始时间到日志脚本
cd  ${FILE_PATH}
if [ $? -eq 0 ];then
    echo "进入[${FILE_PATH}]目录">> ${LOG_PATH}
    if [[ -f ${FILE_PATH}/${LOG_DATE} ]]; then
        echo ${FILE_PATH}/${LOG_DATE}"日志文件存在" >> ${LOG_PATH}
    else
        echo ${FILE_PATH}/${LOG_DATE}"日志文件不存在!" >> ${LOG_PATH}
        exit
    fi
else
    echo "[$LOCAL_DATE]:文件不存在!">>${LOG_PATH}
    exit
fi

# 日志上传
if [ -f  ${FILE_PATH}/${LOG_DATE} ]; then
    echo "开始上传${FILE_PATH}/${LOG_DATE} 文件" >> ${LOG_PATH}
    /usr/bin/ossutil64 cp -f -u ${FILE_PATH} ${OSS_PATH} --include "*log.gz" -r

    if [ $? -eq 0 ];then   #如果上条脚本返回不是0
        echo "${FILE_PATH}/${LOG_DATE}日志上传成功">> ${LOG_PATH}
    else
        echo "${FILE_PATH}/${LOG_DATE}日志上传失败">> ${LOG_PATH}
        exit
    fi
else 
    echo "${FILE_PATH}/${LOG_DATE} 文件不存在！请检查文件！">> ${LOG_PATH}
    exit
fi
endtime=`date +'%Y-%m-%d %H:%M:%S'`
start_seconds=$(date --date="$starttime" +%s);
end_seconds=$(date --date="$endtime" +%s);
echo ${LOG_DATE}" :本次运行时间： "$((end_seconds-start_seconds))"s" >>${LOG_PATH}