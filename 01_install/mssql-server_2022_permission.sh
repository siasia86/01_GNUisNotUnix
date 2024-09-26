#!/bin/bash

install_date="$(date -d  "$(tune2fs -l $(df / | tail -1 | awk '{print $1}' ) | grep -i 'filesystem created' | awk -F "d:" '{print $2}')" +"%s")"
daily01=$(expr \( $(date +%s) - ${install_date} \) / 86400)

if (( "${daily01}" <= "3" )); then
        echo "The server is installed within 3 days and can be proceeded to the next step."
else
        echo -e "It has been more than \033[01;31m"${daily01}"\033[00m days since the server was installed."
        echo "Please contact the administrator or infra team."
    exit 0;
fi;



for i in m l b s ; do 
	rm -rf /sj_dir_${i}df
	if [ ! -d "/sj_dir_${i}df" ];then mkdir -p /sj_dir_${i}df ; fi
	chown mssql.mssql -R /sj_dir_${i}df
done

exit


if [ ! -d "/sj_dir_mdf" ] ; mkdir -p /sj_dir_mdf ; fi 
if [ ! -d "/sj_dir_ldf" ] ; mkdir -p /sj_dir_ldf ; fi 
if [ ! -d "/sj_dir_bdf" ] ; mkdir -p /sj_dir_bdf ; fi 
if [ ! -d "/sj_dir_sdf" ] ; mkdir -p /sj_dir_sdf ; fi 

chown mssql.mssql -R /sj_dir_mdf
chown mssql.mssql -R /sj_dir_ldf
chown mssql.mssql -R /sj_dir_bdf
chown mssql.mssql -R /sj_dir_sdf

#chmod 700 -R /sj_dir_mdf
#chmod 700 -R /sj_dir_ldf
#chmod 700 -R /sj_dir_bdf
