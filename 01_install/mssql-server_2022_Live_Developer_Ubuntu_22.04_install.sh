#!/bin/bash
#### This script was created by sjyun on 2024-03-19. version 24.6.25. Modified by sjyun on 2024-06-25.
#### mssql-server_2022_Developer auto install in ubuntu 22.04

# version confirm :
#ii  mssql-server                           16.0.4115.5-2                           amd64        Microsoft SQL Server Relational Database Engine
#ii  mssql-tools18                          18.2.1.1-1                              amd64        Tools for Microsoft(R) SQL Server(R)

exit 0;
set -uxe

############################################################
#### If the newly installed server, the comments below  ####
#### Update to the last version of ubuntu 22.04.        ####
#### But if it's a newly installed server,              ####
#### it will be updated automatically.                  ####
#### sudo apt update -y && sudo apt upgrade -y          ####
#### sudo apt autoremove -y                             ####
############################################################

uptime=$(uptime | awk '{print $3}')
version_id=$(cat /etc/os-release  | grep -i version_ID | awk -F \" '{print $(NF-1)}')

if [ "$version_id" = "22.04" ]; then
        echo "22.04 OK"
else
        echo "failed"
        exit 1;
fi

if (( "$uptime" <= "5" )); then
        echo "apt update -y"; sudo apt update -y && echo "apt upgrade -y"; sudo apt upgrade -y;
        #echo "apt update -y"; sudo apt update -y && echo "apt upgrade -y"; sudo apt upgrade -y && echo "apt autoremove -y"; sudo apt autoremove -y
else
        echo "It has been more than 5 days since the server was installed."
        echo "Please contact the administrator or infra team."
fi

install_date="$(date -d  "$(tune2fs -l $(df / | tail -1 | awk '{print $1}' ) | grep -i 'filesystem created' | awk -F "d:" '{print $2}')" +"%s")"
daily01=$(expr \( $(date +%s) - ${install_date} \) / 86400)

if (( "${daily01}" <= "3" )); then
        echo "The server is installed within 3 days and can be proceeded to the next step."
else
        echo "It has been more than "${daily01}" days since the server was installed."
        echo "Please contact the administrator or infra team."
        exit 0;
fi;

#### pgp key
curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc

#### mssql-server repo
#sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list)"
curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list | sudo tee /etc/apt/sources.list.d/mssql-server-2022.list

#### SQL_cli install    ## mssql-tools18   ## sqlcmd
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list

sudo apt-get update -y
ACCEPT_EULA=Y sudo apt-get install mssql-tools18 unixodbc-dev mssql-server rsync language-pack-ko ethtool -y

if [ -f "${HOME}/.bash_aliases" ] || [ -n "grep mssql-tools18  ${HOME}/.bash_aliases "] ; then
	echo " \"${HOME}/.bash_aliases\" file is exist."
else
	echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ${HOME}/.bash_aliases
	source ${HOME}/.bash_aliases
fi

echo "$?"
# sudo /opt/mssql/bin/mssql-conf setup

locale-gen ko_KR.UTF-8
echo -e "export LANG=ko_KR.utf8\nexport PATH=\"\$PATH:/opt/mssql-tools18/bin\"\n\n#### Run the command. ####\nsudo /opt/mssql/bin/mssql-conf setup"
