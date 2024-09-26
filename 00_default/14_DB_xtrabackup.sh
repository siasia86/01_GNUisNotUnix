#!/bin/bash
## This script performs MySQL backup using xtrabackup.
## Created by sjyun on 2023-12-22. Version 4.1.11 Modified by sjyun on 2024-01.11.

dump_date=$(date '+%Y%m%d-%H')
dump_date2=$(date '+%Y%m%d-%H' -d '1 day ago')
## backup time date, [0=0h] [12=0h,12h] [6=0,6,12,18h] [4=0h,4h,8h,12h,16h,20h] .. ... added by sjyun-2023-12-13
full_date=$(date '+%H')
inc1_date=$(date '+%Y%m%d')
log_date=$(date '+%Y-%m-%dT%H:%M:%S')
log_date2=$(date '+%Y%m%d-%H%M%S')
backuptime_date="00"
dump_dir="/sj_dir_ldf/Backup"
DB_user="backup"
DB_pass="Backup"


# Function to initialize backup directories
initialize_backup_directories() {
	if [ ! -d "${dump_dir}/full" ]; then mkdir -p ${dump_dir}/full ;fi
	if [ ! -d "${dump_dir}/inc1" ]; then mkdir -p ${dump_dir}/inc1 ;fi
	if [ ! -d "${dump_dir}/restore" ]; then mkdir -p ${dump_dir}/restore ;fi
}

# Function to move existing incremental backup directory
move_existing_incremental_backup() {
	if [ -d "${dump_dir}/inc1/${dump_date}" ]; then
    	mv -b ${dump_dir}/inc1/${dump_date} ${dump_dir}/inc1/${dump_date}_ORG_${log_date2}
	fi
}

# Function to check disk space
check_disk_space() {
	if (( $(df -h | sed 's/%//g' | awk '/\/sj_dir_ldf/ { print $(NF-1) >= 90 }') )); then
    	echo "/sj_dir_ldf directory 90% up."
    	exit 1
	fi
}

# Function to perform full backup
perform_full_backup() {
	if [ ! -d ${dump_dir}/full/${dump_date} ]; then
    	echo "[${log_date}]_info_sj_dir xtrabackup -u ${DB_user} -p --backup  --target-dir=${dump_dir}/full/${dump_date}" >> /var/log/xtrabackup-full.log
    	xtrabackup -u ${DB_user} -p${DB_pass} --backup --target-dir=${dump_dir}/full/${dump_date} >> /var/log/xtrabackup-full.log 2>&1

    	echo "$?" > /var/log/mysql-dump.status
    	if [ -d ${dump_dir}/full/${dump_date2} ]; then
        	rsync -av /etc/my.cnf ${dump_dir}/full/my.cnf_ORG
        	tar zcvfh ${dump_dir}/full/${dump_date2}.tar.gz --backup=numbered -C ${dump_dir}/full/ ./${dump_date2} \
        	-C ${dump_dir}/restore/ ./14_DB_xtrabackup-restore-${dump_date2}.sh \
        	-C ${dump_dir}/full/ ./my.cnf_ORG --remove-files
    	fi;
    	echo "=============================================" >> /var/log/xtrabackup-full.log
	else
    	echo "[${log_date}]_error_sj_dir There is already a ${dump_dir}/full/${dump_date} directory." >> /var/log/xtrabackup-full.log
	fi
}

# Function to perform incremental backup
perform_incremental_backup() {
	if [ ! -d ${dump_dir}/inc1/${dump_date} ]; then
    	echo "[${log_date}]_info_sj_dir xtrabackup -u ${DB_user} -p --backup  --target-dir=${dump_dir}/inc1/${dump_date} --incremental-basedir=${dump_dir}/full/${inc1_date}-00 " >> /var/log/xtrabackup-inc1.log
    	xtrabackup -u ${DB_user} -p${DB_pass} --backup --target-dir=${dump_dir}/inc1/${dump_date} --incremental-basedir=${dump_dir}/full/${inc1_date}-00 >> /var/log/xtrabackup-inc1.log 2>&1

    	echo "$?" > /var/log/mysql-dump.status
    	echo "=============================================" >> /var/log/xtrabackup-inc1.log
	else
    	echo "[${log_date}]_error_sj_dir There is already a ${dump_dir}/inc1/${dump_date} directory." >> /var/log/xtrabackup-inc1.log
	fi
}

# Main script starts here

# Initialize backup directories
initialize_backup_directories

# Move existing incremental backup directory
move_existing_incremental_backup

# Check disk space
check_disk_space

# Perform full or incremental backup based on the backup schedule
if [ "${backuptime_date}" == "${full_date}" ]; then
	perform_full_backup
else
	perform_incremental_backup
fi


## sjyun01
cat | sudo tee ${dump_dir}/restore/14_DB_xtrabackup-restore-${dump_date}.sh > /dev/null  << EOF
#!/bin/bash
## This script performs MySQL backup using xtrabackup.
## Created by sjyun on 2023-12-22. Version 4.1.11 Modified by sjyun on 2024-01-11.

restore_date=$(date '+%Y%m%d-%H')
restore_full_date=$(date '+%Y%m%d-00')
log_date=\$(date '+%Y-%m-%d-%H:%M:%S')
bk_log_date=\$(date '+%Y%m%d-%H%M')
restore_dir="${dump_dir}"
DB_user="backup"
DB_pass="Backup123!@#"

# Function to perform pre-restore operations
for i in {01..10}; do
	echo "\${i}"
	sleep 1
done
echo "restore job start!!!!!"
##############
exit 0
##############

# Function to check disk space
check_disk_space() {
	if (( \$(df -h | sed 's/%//g' | awk '/\/sj_dir_mdf/ { print \$(NF-1) >= 90 }') )); then
    	echo "/sj_dir_mdf directory 90% up."
    	exit 1
	fi

	if (( \$(df -h | sed 's/%//g' | awk '/\/sj_dir_ldf/ { print \$(NF-1) >= 90 }') )); then
    	echo "/sj_dir_ldf directory 90% up."
    	exit 2
	fi

	if [ ! "\$(cat \${restore_dir}/full/\${restore_full_date}/xtrabackup_checkpoints  | grep -i "from_lsn" | awk '{print \$NF}')" == "0" ] ; then exit 3; fi

	if systemctl stop mysqld ; then pgrep mysql ; else echo "mysql stop failed." ;fi
}

check_lsn() {
# Check LSN values
	if [ "\$(cat "\${restore_dir}/inc1/\${restore_date}/xtrabackup_checkpoints" | awk '/from_lsn/ {print \$NF}')" != \\
    	"\$(cat "\${restore_dir}/full/\${restore_full_date}/xtrabackup_checkpoints" | awk '/to_lsn/ {print \$NF}')" ]; then
    	echo "inc1 : \$(cat \${restore_dir}/inc1/\${restore_date}/xtrabackup_checkpoints | grep -i "from_lsn")";
    	echo "full : \$(cat \${restore_dir}/full/\${restore_full_date}/xtrabackup_checkpoints | grep -i "to_lsn")";
	exit 4
fi
}

# Function to create a directory if it does not exist
create_directory() {
	if [ ! -d "\${restore_dir}/binlog_\${bk_log_date}" ]; then
    	mkdir -p "\${restore_dir}/binlog_\${bk_log_date}"
	fi

	if [ ! -d "/sj_dir_ldf/infra" ]; then
    	mkdir -p /sj_dir_ldf/infra
	fi
}

# Function to move an existing directory
move_existing_directory() {
	if [ -d "/sj_dir_mdf/MySQL/" ]; then
    	if [ -n "\$(lsof +D /sj_dir_mdf/MySQL)" ]; then
        	lsof +D /sj_dir_mdf/MySQL
        	exit 5
    	fi
    	mv -b /sj_dir_mdf/MySQL/ /sj_dir_mdf/MySQL_XtraBK_\${bk_log_date}
	else
    	echo "The directory /sj_dir_mdf/MySQL/ does not exist."
	fi

	if [ -d "\${restore_dir}/binlog_\${bk_log_date}" ] ; then
    	for var1 in \$(find /sj_dir_ldf/MySQL/ -type f -name "binlog.*") ; do
        	echo "mv -b \${var1} \${restore_dir}/binlog_\${bk_log_date}/"
        	mv -b \${var1} \${restore_dir}/binlog_\${bk_log_date}/
    	done
	fi
}

# Function to perform rsync operation
perform_rsync() {
	local source_dir=\$1
	local backup_date=\$2
	rsync -av "\${source_dir}/\${backup_date}/" "/sj_dir_ldf/infra/\${backup_date}_ORG_\${bk_log_date}/" || { echo "\$?" ; exit 6; }
}

# Function to perform xtrabackup restore
perform_xtrabackup_restore() {
	xtrabackup -u "\${DB_user}" -p"\${DB_pass}" --prepare --apply-log-only --target-dir=\${restore_dir}/full/\${restore_full_date} || { echo "\$?" ; exit 7; }
	xtrabackup -u "\${DB_user}" -p"\${DB_pass}" --prepare --target-dir="\${restore_dir}/full/\${restore_full_date}" \\
    	--incremental-dir="\${restore_dir}/inc1/\${restore_date}" || { echo "\$?" ; exit 8; }
	xtrabackup -u "\${DB_user}" -p"\${DB_pass}" --copy-back --target-dir="\${restore_dir}/full/\${restore_full_date}" || { echo "\$?" ; exit 9; }

	if [ "\$?" -eq "0" ]; then
    	chown -R mysql.mysql /sj_dir_mdf/MySQL
    	chown -R mysql.mysql /sj_dir_ldf/MySQL
	fi
	echo "xtrabackup restore Success!"
}

###### Main script starts here

# Check disk space
check_disk_space

# Check LSN values
check_lsn

# Create necessary directories
create_directory

# Move existing MySQL directory
move_existing_directory

# Perform rsync operations
perform_rsync "\${restore_dir}/full" "\${restore_full_date}"
perform_rsync "\${restore_dir}/inc1" "\${restore_date}"


# Perform xtrabackup restore
perform_xtrabackup_restore
EOF
echo "$?"
