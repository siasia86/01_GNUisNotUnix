#!/usr/bin/bash
#### This script was created by	sj_scripts on 2024-09-09. version 24.09.25. Modified by	sj_scripts on 2024-09-25.
#### /root/backup_remote_auto.sh: Automated remote backup and local backup data delete script for Redhat and Debian.
#### URL : gnuisnotunix.??
#### crontab -l
#### 30 01 * * * /usr/bin/bash /masang_backup/bin/backup_remote_auto.sh >> /var/log/backup-log/backup_remote_auto_temp.log
#### 30 01 * * 6  /usr/bin/bash /root/backup_remote_auto.sh


LOG_DIR="/var/log/backup-log/remote-backup.log"
DELETE_LOG_DIR01="/var/log/backup-log/rsync-delete.log"
#MS_DIR_01="/masang_backup/MSSQL/data/auto"
set -xeu
exit 0;
## check 1 use 90% 
echo "0" > /var/log/backup-log/backup.status
if (( "$(df -h /masang_backup | awk 'NR>1 {gsub("%", "", $(NF-1)); print $(NF-1)}')" >= "90" )) ; then
	echo "1" > /var/log/backup-log/backup.status 
	echo "$(date +%Y%m%d-%H:%M:%S) 	sj_scripts [error]:1	df -h failed" > ${LOG_DIR} 
	exit 1;
fi

if [ -n "$(pgrep rsync)" ]; then echo "3" > /var/log/backup-log/backup.status ; echo "$(date +%Y%m%d-%H:%M:%S) 	sj_scripts [error]:3 rsync error" >> "${LOG_DIR}" ; exit 3; fi


## 최근 7일 이내에 데이터가 있으면 삭제, 백업 순으로 실행, 데이터가 없으면 error code 4 출력(zabbix 에 메일 알람 오도록 예정)
echo "$(date +%Y%m%d-%H:%M:%S)	sj_scripts [info]:	sj_scripts-start. check." >> "${LOG_DIR}"
if [ "$(find "/masang_backup/MSSQL/data/auto/" -maxdepth 2 -mindepth 2 -type d -name "202*" -mtime -8 -print -quit)" ] ; then
	echo "$(date +%Y%m%d-%H:%M:%S) 	sj_scripts [info]:	$(find "/masang_backup/MSSQL/data/auto/" -maxdepth 2 -mindepth 2 -type d -name "202*" -mtime -8 -print -quit)"  >> "${LOG_DIR}"
	echo "$(date +%Y%m%d-%H:%M:%S) 	sj_scripts [info]:	start. OK" >> "${LOG_DIR}"
else
	echo "$(date +%Y%m%d-%H:%M:%S) 	sj_scripts [error]:4	There are not found recent backup data. start failed." >> "${LOG_DIR}"
	echo "4" > /var/log/backup-log/backup.status
	exit 4
fi;
echo "$(date +%Y%m%d-%H:%M:%S)	sj_scripts [info]:	sj_scripts-end. check. ---- check success ----" >> "${LOG_DIR}"


PRODUCT_02=(ao dk gz nx pt)
IPADDR_02="10.11.32.243"
DELETE_DAY="12"

for ((i=0;i<=1;i++)); do
## 각 프로덕트 아래에 백업 날짜별 디렉토리가 존재 하면, 백업 진행 실패 하면 error code 5 출력 (zabbix 메일 예정)
echo "$(date +%Y%m%d-%H:%M:%S)	sj_scripts [info]:	sj_scripts-start. backup " >> ${LOG_DIR}
## backup start. (remote bakcup)
for var02 in "${PRODUCT_02[@]}"
do
echo "$(date +%Y%m%d-%H:%M:%S)	sj_scripts [info]:	backup. product ${var02}" >> ${LOG_DIR};
	if [ "$(find "/masang_backup/MSSQL/data/auto/${var02}" -maxdepth 1 -mindepth 1 -type d -name "202*" -print -quit)" ] ; then
		for var03 in $(find "/masang_backup/MSSQL/data/auto/${var02}" -maxdepth 1 -mindepth 1 -type d -name "202*" -print | awk -F "/" '{print $NF}'); do
			echo "$(date +%Y%m%d-%H:%M:%S) 	sj_scripts [info]:	rsync -av --bwlimit=20000 /masang_backup/MSSQL/data/auto/${var02}/${var03}/  ${IPADDR_02}::mssql_${var02}/${var03}/" >> "${LOG_DIR}"
			rsync -av --bwlimit=20000 /masang_backup/MSSQL/data/auto/${var02}/${var03}/  ${IPADDR_02}::mssql_${var02}/${var03}/ >> "${LOG_DIR}"
		done
	else
		echo "$(date +%Y%m%d-%H:%M:%S)	sj_scripts [error]:5	There are not found recent backup data. failed. " >> "${LOG_DIR}"
		echo "5" > /var/log/backup-log/backup.status
		exit 5
	fi;
done

PRODUCT_02=(ac cc fh sr)
IPADDR_02="10.11.32.244"
done;
echo "$(date +%Y%m%d-%H:%M:%S)	sj_scripts [info]:	sj_scripts-end. ---- backup success ----" >> ${LOG_DIR}



## backup start. (remote bakcup)

## 28일 이상 존재한 데이터가 있으면, 2차(remote) 서버와 local 서버의 파일 개수가 일치 하면 날짜 별 디렉토리를 삭제, 데이터가 없으면 code 12, 개수가 맞지 않으면 error code 11 출력
## error code 출력시 zabbix 알람 전송 
## delete backup. (local 127.0.0.1)


PRODUCT_02=(ao dk gz nx pt)
IPADDR_02="10.11.32.243"
DELETE_DAY="11"

for ((i=0;i<=1;i++)); do

echo "$(date +%Y%m%d-%H:%M:%S)	sj_scripts [info]:	sj_scripts-start. delete." >> ${DELETE_LOG_DIR01}
for delete02 in "${PRODUCT_02[@]}"
do
echo "$(date +%Y%m%d-%H:%M:%S)	sj_scripts [info]:	delete02-start." >> ${DELETE_LOG_DIR01}
	################################### ddddddddd ffff
	if [ "$(find "/masang_backup/MSSQL/data/auto/${delete02}" -maxdepth 1 -mindepth 1 -type d -name "202*" -mtime +${DELETE_DAY} -print -quit)" ] ; then
		for delete03 in $(find "/masang_backup/MSSQL/data/auto/${delete02}" -maxdepth 1 -mindepth 1 -type d -name "202*" -mtime +${DELETE_DAY} -print | awk -F "/" '{print $NF}'); do
		if [ "$( expr $(rsync --list-only ${IPADDR_02}::mssql_${delete02}/${delete03} | wc -l) - 1 )" == \
"$(find "/masang_backup/MSSQL/data/auto/${delete02}}/${delete03}/" -maxdepth 1 -mindepth 1 -type f -mtime +${DELETE_DAY} -print | wc -l)" ]; then

			echo "$( expr $(rsync --list-only ${IPADDR_02}::mssql_${delete02}/${delete03} | wc -l) - 1 )" == \
"$(find "/masang_backup/MSSQL/data/auto/${delete02}}/${delete03}/" -maxdepth 1 -mindepth 1 -type f -mtime +${DELETE_DAY} -print | wc -l)" >> ${DELETE_LOG_DIR01}
			echo "$(date +%Y%m%d-%H:%M:%S)	sj_scripts [info]:	" >> ${DELETE_LOG_DIR01}
			echo "find /masang_backup/MSSQL/data/auto/${delete02}/${delete03}/ -maxdepth 0 -mindepth 0 -type d -mtime +${DELETE_DAY} -print -exec rm -rfv {} \;" >> ${DELETE_LOG_DIR01}
			find /masang_backup/MSSQL/data/auto/${delete02}/${delete03}/ -maxdepth 0 -mindepth 0 -type d -mtime +${DELETE_DAY} -print -exec rm -rfv {} \; >> ${DELETE_LOG_DIR01}
		else
			echo "$( expr $(rsync --list-only ${IPADDR_02}::mssql_${delete02}/${delete03} | wc -l) - 1 )" == \
"$(find "/masang_backup/MSSQL/data/auto/${delete02}}/${delete03}/" -maxdepth 1 -mindepth 1 -type f -mtime +${DELETE_DAY} -print | wc -l)" >> ${DELETE_LOG_DIR01}
			echo "$(date +%Y%m%d-%H:%M:%S)	sj_scripts [error]11:	failed" >> ${DELETE_LOG_DIR01}
			echo "11" > /var/log/backup-log/backup.status
			exit 11
		fi
	
		done
	else
		echo "$(date +%Y%m%d-%H:%M:%S) 	sj_scripts [info]:12 There are not found delete data." >> ${DELETE_LOG_DIR01}
	fi

done
PRODUCT_02=(ac cc fh sr)
IPADDR_02="10.11.32.244"

done;

echo "$(date +%Y%m%d-%H:%M:%S) 	sj_scripts [info]:	sj_scripts-end. ---- delete old data success ----" >> ${DELETE_LOG_DIR01}

exit 0;
