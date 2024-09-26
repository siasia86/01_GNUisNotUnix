#!/bin/bash
#### This script was created by sjyun on 2024-06-26. version 24.7.10. Modified by sjyun on 2024-07-10.
#### mssql-server_2022_Developer auto install in ubuntu 20.04
echo "failed." ; exit 0;

if [ ! -d "/sj_dir_vol1/mdf" ]; then mkdir -p /sj_dir_vol1/mdf ; chown mssql.mssql -R /sj_dir_vol1/ ;fi
if [ ! -d "/sj_dir_vol1/ldf" ]; then mkdir -p /sj_dir_vol1/ldf ; chown mssql.mssql -R /sj_dir_vol1/ ;fi

if [ ! -d "/sj_dir_vol2/mdf" ]; then mkdir -p /sj_dir_vol2/mdf ; chown mssql.mssql -R /sj_dir_vol2/ ;fi
if [ ! -d "/sj_dir_vol2/ldf" ]; then mkdir -p /sj_dir_vol2/ldf ; chown mssql.mssql -R /sj_dir_vol2/ ;fi

if [ ! -d "/sj_dir_vol3/mdf" ]; then mkdir -p /sj_dir_vol3/mdf ; chown mssql.mssql -R /sj_dir_vol3/ ;fi
if [ ! -d "/sj_dir_vol3/ldf" ]; then mkdir -p /sj_dir_vol3/ldf ; chown mssql.mssql -R /sj_dir_vol3/ ;fi

if [ ! -d "/sj_dir_vol4/mdf" ]; then mkdir -p /sj_dir_vol4/mdf ; chown mssql.mssql -R /sj_dir_vol4/ ;fi
if [ ! -d "/sj_dir_vol4/ldf" ]; then mkdir -p /sj_dir_vol4/ldf ; chown mssql.mssql -R /sj_dir_vol4/ ;fi

if [ ! -d "/sj_dir_backup/data" ]; then mkdir -p /sj_dir_backup/data ; chown mssql.mssql -R /sj_dir_backup/ ;fi

exit 0;

install_date="$(date -d  "$(tune2fs -l $(df / | tail -1 | awk '{print $1}' ) | grep -i 'filesystem created' | awk -F "d:" '{print $2}')" +"%s")"
daily01=$(expr \( $(date +%s) - ${install_date} \) / 86400)

if (( "${daily01}" <= "3" )); then
        echo "The server is installed within 3 days and can be proceeded to the next step."
else
        echo -e "It has been more than \033[01;31m"${daily01}"\033[00m days since the server was installed."
        echo "Please contact the administrator or infra team."
    exit 0;
fi;


if systemctl stop mssql-server ; then pgrep sqlservr ; else echo "mssql stop failed." ;fi

########################### edit !!!!!!!!!!!!!!!!!!!!!!!!!!
if [ -n "$(lsof +D /var/opt/mssql )" ]; then
	lsof +D /var/opt/mssql;
	exit 1;
else
	rsync -av /var/opt/mssql/mssql.conf /var/opt/mssql/mssql.conf_ORG
	tar zcvfP /var/opt/mssql_ORG.tar.gz /var/opt/mssql

fi

## configuration file
/opt/mssql/bin/mssql-conf set filelocation.defaultdatadir       /sj_dir_vol1/mdf
/opt/mssql/bin/mssql-conf set filelocation.defaultlogdir        /sj_dir_vol2/ldf
/opt/mssql/bin/mssql-conf set filelocation.defaultbackupdir     /sj_dir_backup/data
/opt/mssql/bin/mssql-conf set memory.memorylimitmb 491520
#/opt/mssql/bin/mssql-conf set memory.memorylimitmb 65536
/opt/mssql/bin/mssql-conf set sqlagent.enabled true

/opt/mssql/bin/mssql-conf set filelocation.masterdatafile      /sj_dir_vol3/mdf/master.mdf
/opt/mssql/bin/mssql-conf set filelocation.masterlogfile       /sj_dir_vol4/ldf/mastlog.ldf

/opt/mssql/bin/mssql-conf set network.tcpport 11433
echo "######################### $? #########################"
## lcid = 1042
## /opt/mssql/bin/mssql-conf set language.lcid 1042

echo "cat /var/opt/mssql/mssql.conf"
cat /var/opt/mssql/mssql.conf
echo "######################### $? #########################"
echo "systemctl restart mssql-server.service"

exit 0;
if [ -n "$(dpkg -l | grep mssql-server-is )" ] ; then
        echo "mssql-server-is is installed."
else
	apt install mssql-server-is -y ;
	sudo /opt/ssis/bin/ssis-conf setup
fi;
