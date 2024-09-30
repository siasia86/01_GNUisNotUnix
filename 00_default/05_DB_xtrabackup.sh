#!/bin/bash
## This script was created by sjyun on 2023-12-26. version 0.26. Modified by sjyun on 2023-12-26.
dump_date=$(date '+%Y%m%d-%H')
dump_date2=$(date '+%Y%m%d-%H' -d '1 day ago')
log_date=$(date '+%Y-%m-%d-%H:%M:%S')
## backup time date, [0=0h] [12=0h,12h] [6=0,6,12,18h] [4=0h,4h,8h,12h,16h,20h] .. ... added by sjyun-2023-12-13
full_date=$(date '+%H')
inc1_date=$(date '+%Y%m%d')
backuptime_date="02"
dump_dir="/sjdir_ldf/Backup"
DB_user="backup"
DB_pass="Backup123!@#"

## incremental = inc1 // == differential
if [ ! -d "${dump_dir}/full" ]; then mkdir -p ${dump_dir}/full ;fi
if [ ! -d "${dump_dir}/inc1" ]; then mkdir -p ${dump_dir}/inc1 ;fi

if [ -d "${dump_dir}/inc1/${dump_date}" ] ; then mv -b ${dump_dir}/inc1/${dump_date} ${dump_dir}/inc1/${dump_date}_ORG ; fi
if (( "$(df -h | grep -i "/sjdir_ldf" | awk '{print $(NF-1)}'  | sed 's/%//g')" >= "90" )) ; then exit 1 ; fi

if [ "${backuptime_date}" == "${full_date}" ]; then

## full
if [ ! -d ${dump_dir}/full/${dump_date} ]; then
		echo "[${log_date}]_info_sjdir xtrabackup -u ${DB_user} -p --backup  --target-dir=${dump_dir}/full/${dump_date}"	>> /var/log/xtrabackup-full.log
		xtrabackup -u ${DB_user} -p${DB_pass} --backup  --target-dir=${dump_dir}/full/${dump_date}	>> /var/log/xtrabackup-full.log 2>&1
	if [ -d ${dump_dir}/full/${dump_date2} ]; then
		tar zcvfh ${dump_dir}/full/${dump_date2}.tar.gz --backup=numbered -C ${dump_dir}/full/ ./${dump_date2} ./14_DB_xtrabackup-restore-${dump_date2}.sh --remove-files
	fi;
		echo "$?" > /var/log/mysql-dump.status
		echo "============================================="	>> /var/log/xtrabackup-full.log
else
		echo "[${log_date}]_error_sjdir There is already a ${dump_dir}/full/${dump_date} directory."	>> /var/log/xtrabackup-full.log
fi
## full

else
## inc1
if [ ! -d ${dump_dir}/inc1/${dump_date} ]; then
		echo "[${log_date}]_info_sjdir xtrabackup -u ${DB_user} -p --backup  --target-dir=${dump_dir}/inc1/${dump_date} --incremental-basedir=${dump_date}/full/${inc1_date}-00 " >> /var/log/xtrabackup-inc1.log
		xtrabackup -u ${DB_user} -p${DB_pass} --backup  --target-dir=${dump_dir}/inc1/${dump_date} --incremental-basedir=${dump_dir}/full/${inc1_date}-00 >> /var/log/xtrabackup-inc1.log 2>&1
		echo "$?" > /var/log/mysql-dump.status
		echo "============================================="	>> /var/log/xtrabackup-inc1.log
else
		echo "[${log_date}]_error_sjdir There is already a ${dump_dir}/inc1/${dump_date} directory."	>> /var/log/xtrabackup-inc1.log
fi
## inc1

fi;

cat | sudo tee ${dump_dir}/full/14_DB_xtrabackup-restore-${dump_date}.sh > /dev/null  << EOF
#!/bin/bash
## This script was created by sjyun on 2023-12-22. version 0.22
restore_date=$(date '+%Y%m%d-%H')
restore_full_date=$(date '+%Y%m%d-00')
log_date=\$(date '+%Y-%m-%d-%H:%M:%S')
bk_log_date=\$(date '+%Y%m%d-%H%M')
restore_dir="/sjdir_ldf/Backup"
DB_user="backup"
DB_pass="Backup123!@#"

for i in {01..10}; do echo "\${i}" ; sleep 1; done
echo "restore job start!!!!!"
exit 0
if (( "\$(df -h | grep -i "/sjdir_mdf" | awk '{print \$(NF-1)}'  | sed 's/%//g')" >= "90" )) ; then echo "/sjdir_mdf directory 90% up!" ; fi
if [ ! -d "/sjdir_ldf/sjyun" ]; then mkdir -p /sjdir_ldf/sjyun ;fi
if [ ! "\$(cat \${restore_dir}/full/\${restore_full_date}/xtrabackup_checkpoints  | grep -i "from_lsn" | awk '{print \$NF}')" == "0" ] ; then exit 0; fi

if systemctl stop mysqld ; then pgrep mysql ; else echo "mysql stop failed." ;fi

if [ -d "/sjdir_mdf/MySQL" ]; then
		if [ -n "\$(lsof +D /sjdir_mdf/MySQL)" ]; then exit 1 ; lsof +D /sjdir_mdf/MySQL ; fi
fi;
if [ -d "/sjdir_mdf/MySQL" ]; then mv -b /sjdir_mdf/MySQL/ /sjdir_mdf/MySQL_XtraBK_\${bk_log_date}/ ; else echo "The directory /sjdir_mdf/MySQL does not exist." ;fi
if [ ! -d "\${restore_dir}/binlog_\${bk_log_date}" ] ; then mkdir -p \${restore_dir}/binlog_\${bk_log_date} ; fi
if [ -d "\${restore_dir}/binlog_\${bk_log_date}" ] ; then
		for var1 in \$(find /sjdir_ldf/MySQL/ -type f -name "binlog.*") ; do
				mv -b \${var1} \${restore_dir}/binlog_\${bk_log_date}/
				echo "mv -b \${var1} \${restore_dir}/binlog_\${bk_log_date}/"
		done
fi

if [ ! "\$(cat \${restore_dir}/inc1/\${restore_date}/xtrabackup_checkpoints | grep -i "from_lsn" | awk '{print \$NF}')" == "\$(cat \${restore_dir}/full/\${restore_full_date}/xtrabackup_checkpoints | grep -i "to_lsn" | awk '{print \$NF}')" ] ; then exit 2 ;
		echo "inc1 : \$(cat \${restore_dir}/inc1/\${restore_date}/xtrabackup_checkpoints | grep -i "from_lsn")";
		echo "full : \$(cat \${restore_dir}/full/\${restore_full_date}/xtrabackup_checkpoints | grep -i "to_lsn")";
fi
rsync -av \${restore_dir}/full/\${restore_full_date}/ /sjdir_ldf/sjyun/\${restore_full_date}_ORG_\${bk_log_date}/
rsync -av \${restore_dir}/inc1/\${restore_date}/ /sjdir_ldf/sjyun/\${restore_date}_ORG_\${bk_log_date}/
if [ ! "\$?" -eq "0" ] ; then exit 3; fi

xtrabackup -u \${DB_user} -p\${DB_pass} --prepare --apply-log-only  --target-dir=\${restore_dir}/full/\${restore_full_date}
if [ ! "\$?" -eq "0" ] ; then exit 4; fi
xtrabackup -u \${DB_user} -p\${DB_pass} --prepare --target-dir=\${restore_dir}/full/\${restore_full_date} --incremental-dir=\${restore_dir}/inc1/\${restore_date}
if [ ! "\$?" -eq "0" ] ; then exit 5; fi
xtrabackup -u \${DB_user} -p\${DB_pass} --copy-back  --target-dir=\${restore_dir}/full/\${restore_full_date}
if [ ! "\$?" -eq "0" ] ; then exit 6; fi

if [ "\$?" -eq "0" ] ; then chown -R mysql.mysql /sjdir_mdf/MySQL ; chown -R mysql.mysql /sjdir_ldf/MySQL ;fi

echo "xtrabackup restore Success!"
EOF
echo "$?"
