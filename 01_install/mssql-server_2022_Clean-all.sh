#!/bin/bash

exit 0;

UPTIME_01=$(uptime | awk '{print $3}')
install_date="$(date -d  "$(tune2fs -l $(df / | tail -1 | awk '{print $1}' ) | grep -i 'filesystem created' | awk -F "d:" '{print $2}')" +"%s")"
daily01=$(expr \( $(date +%s) - ${install_date} \) / 86400)

if (( "${daily01}" <= "3" )); then
        echo "The server is installed within 3 days and can be proceeded to the next step."
else
        echo -e "It has been more than \033[01;31m"${daily01}"\033[00m days since the server was installed."
        echo "Please contact the administrator or infra team."
    exit 0;
fi;

apt remove mssql-server -y && dpkg -P mssql-server

rm -rf /var/opt/mssql
rm -rf /var/opt/mssql_ORG
rm -rf /opt/mssql

rm -rf /sj_dir_mdf/MSSQL
rm -rf /sj_dir_ldf/MSSQL
rm -rf /sj_dir_bdf/MSSQL

