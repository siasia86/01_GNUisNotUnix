#!/usr/bin/bash
#### This script was created by ..?? on 20??-??-??. version 24.8.25. Modified by sjyun on 2024-08-25.
#### /root/02_DB_backup.sh: Automated MySQL backup or dump script for Redhat and Debian.
#### URL : gnuisnotunix.??
#### crontab -l
#### 30 01 * * *  /usr/bin/bash /root/02_DB_backup.sh
#### 30 01 * * 6  /usr/bin/bash /root/02_DB_backup.sh 

dump_date=$(date +%Y%m%d-%H);
# ... ....
dump_dir="/backup/db";
DB_user="root";
DB_pass="glglghgh";

DB_optimize_switch=0;


#for database in $(/usr/bin/mysqlshow -u ${DB_user} -p${DB_pass} | awk -F" " '{ print $2 }' | grep -v "^$" |grep -Ev "Databases|information_schema|performance_schema")
for database in $(/usr/bin/mysqlshow -u ${DB_user} -p${DB_pass} | awk -F" " '{ print $2 }' | grep -v "^$" |grep -Ev "Databases|performance_schema")
do
	echo "+ --------------------------------------------- +";
	echo "+	${database} START															|";
	echo "+ --------------------------------------------- +";

	if [ ! -d "${dump_dir}/""${dump_date}""/""${database}""" ]
	then
		mkdir -p ${dump_dir}/"${dump_date}"/"${database}";
	fi

	for table in $(mysql -u ${DB_user} -p"${DB_pass}" -e"show tables" "${database}" | grep -v "Tables_in_${database}" | grep -v "^$")
	do
		if [ ${DB_optimize_switch} = "1" ]
		then
			mysql -u ${DB_user} -p${DB_pass} -e"optimize table ${table}" "${database}"
		fi

		mysqldump -u ${DB_user} -p${DB_pass} --quick --single-transaction "${database}" "${table}" > "${dump_dir}"/"${dump_date}"/"${database}"/"${table}.sql"
		echo "mysql -u ${DB_user} -p'${DB_pass}' ${database} < $table.sql" >> "${dump_dir}"/"${dump_date}"/"${database}"/"restore.sh"
		echo "${table}";
	done

	sleep 1;
done

#echo "======== ======== 7 DAY DELETE ======== ========";
Old_Date=$(/bin/date -d "10 day ago" +"%Y%m%d-%H");
rm -rf "${dump_dir}"/"${Old_Date:?}";

#tar cvfz /backups/"${dump_date}".tar "${dump_dir}"/"${dump_date}";

echo "+ ------------------------------------------------------ +";
echo "|	BACKUP PATH : ${dump_dir}/${dump_date}								 |";
echo "+ ------------------------------------------------------ +";
ls -asl "${dump_dir}"/"${dump_date}";
exit 0;
