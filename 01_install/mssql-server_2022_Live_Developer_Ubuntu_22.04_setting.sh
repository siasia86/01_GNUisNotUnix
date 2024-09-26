#!/bin/bash
#### This script was created by sjyun on 2024-03-19. version 24.6.25. Modified by sjyun on 2024-06-25.
#### mssql-server_2022_Developer auto install in ubuntu 22.04
echo "failed." ; exit 0;

if [ ! -d "/sj_dir_v1/sj_dir_mdf/MSSQL/data" ]; then mkdir -p /sj_dir_v1/sj_dir_mdf/MSSQL/data ; chown mssql.mssql -R /sj_dir_v1/ ;fi
if [ ! -d "/sj_dir_v1/sj_dir_ldf/MSSQL/data" ]; then mkdir -p /sj_dir_v1/sj_dir_ldf/MSSQL/data ; chown mssql.mssql -R /sj_dir_v1/ ;fi

if [ ! -d "/sj_dir_v2/sj_dir_mdf/MSSQL/data" ]; then mkdir -p /sj_dir_v2/sj_dir_mdf/MSSQL/data ; chown mssql.mssql -R /sj_dir_v2/ ;fi
if [ ! -d "/sj_dir_v2/sj_dir_ldf/MSSQL/data" ]; then mkdir -p /sj_dir_v2/sj_dir_ldf/MSSQL/data ; chown mssql.mssql -R /sj_dir_v2/ ;fi

if [ ! -d "/sj_dir_backup/MSSQL/data" ]; then mkdir -p /sj_dir_backup/MSSQL/data ; chown mssql.mssql -R /sj_dir_backup/ ;fi
if [ ! -d "/sj_dir_v2/sj_dir_ldf/MSSQL/masterdatabasedir" ]; then mkdir -p /sj_dir_v2/sj_dir_ldf/MSSQL/masterdatabasedir ; chown mssql.mssql -R /sj_dir_v2/ ;fi


if systemctl stop mssql-server ; then pgrep sqlservr ; else echo "mssql stop failed." ;fi

########################### edit !!!!!!!!!!!!!!!!!!!!!!!!!!
if [ -n "$(lsof +D /var/opt/mssql )" ]; then
        lsof +D /var/opt/mssql;
        exit 1;
else
        rsync -av /var/opt/mssql/mssql.conf /var/opt/mssql/mssql.conf_ORG
        rsync -av /var/opt/mssql /var/opt/mssql_ORG
        rsync -av /var/opt/mssql/data/ /sj_dir_v1/sj_dir_mdf/MSSQL/data/

fi

## configuration file
/opt/mssql/bin/mssql-conf set filelocation.defaultdatadir       /sj_dir_v1/sj_dir_mdf/MSSQL/data
/opt/mssql/bin/mssql-conf set filelocation.defaultlogdir        /sj_dir_v2/sj_dir_ldf/MSSQL/data
/opt/mssql/bin/mssql-conf set filelocation.defaultbackupdir     /sj_dir_backup/MSSQL/data
#/opt/mssql/bin/mssql-conf set memory.memorylimitmb 122880
/opt/mssql/bin/mssql-conf set memory.memorylimitmb 524288
/opt/mssql/bin/mssql-conf set sqlagent.enabled true

/opt/mssql/bin/mssql-conf set filelocation.masterdatafile      /sj_dir_v2/sj_dir_ldf/MSSQL/masterdatabasedir/master.mdf
/opt/mssql/bin/mssql-conf set filelocation.masterlogfile       /sj_dir_v2/sj_dir_ldf/MSSQL/masterdatabasedir/mastlog.ldf

/opt/mssql/bin/mssql-conf set network.tcpport 11433
echo "######################### $? #########################"
## lcid = 1042
## /opt/mssql/bin/mssql-conf set language.lcid 1042

echo "cat /var/opt/mssql/mssql.conf"
cat /var/opt/mssql/mssql.conf
echo "systemctl restart mssql-server.service"
