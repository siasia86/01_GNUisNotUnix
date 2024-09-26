#!/bin/bash

dump_date=$(date +%Y%m%d-%H);
# ... ....
dump_dir="/sj_dir_ldf/backup";
DB_list=("account_db");
DB_user="backup";
DB_pass="Backup";
DB_remote="localhost";

DB_optimize_switch=0;

for database in `/usr/bin/mysqlshow -u ${DB_user} -p${DB_pass} -h${DB_remote} | awk -F" " '{ print $2 }' | grep -v "^$" | grep -Ev "Databases|information_schema|performance_schema|sys"`
do

        echo "*------------------------------------------------------ *";
        echo "* ${database} START";
        echo "*------------------------------------------------------ *";


        if [ ! -d "${dump_dir}/${dump_date}" ]

        then

                mkdir -p ${dump_dir}/${dump_date};

        fi

        mysqldump -u ${DB_user} -p${DB_pass} --quick --single-transaction --routines --triggers --events "${database}" > ${dump_dir}/${dump_date}/${database}_${dump_date}.mysqldump

        sleep 1;

        echo "mysql -u ${DB_user} -p"${DB_pass}" ${database} < ${dump_dir}/${dump_date}/${database}_${dump_date}.mysqldump" >> ${dump_dir}/${dump_date}/restore.sh
done

