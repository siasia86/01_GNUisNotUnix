#!/bin/bash

apt install make wget gcc -y

wget -O /usr/local/src/softether-vpnserver-v4.43-9799-beta-2023.08.31-linux-x64-64bit.tar.gz https://www.softether-download.com/files/softether/v4.43-9799-beta-2023.08.31-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.43-9799-beta-2023.08.31-linux-x64-64bit.tar.gz

tar zxvf /usr/local/src/softether-vpnserver-v4.43-9799-beta-2023.08.31-linux-x64-64bit.tar.gz -C /usr/local/

cd /usr/local/vpnserver/ && make

if [ ${?} -eq 0 ]; then
	echo "Make completed successfully."
else
	echo "Make failed."
	exit 1
fi;

/usr/bin/bash /usr/local/vpnserver/.install.sh

chmod -R 644 /usr/local/vpnserver
chmod 700 /usr/local/vpnserver/vpncmd
chmod 700 /usr/local/vpnserver/vpnserver

echo " ############## choose 3 ##############"
echo "3. Use of VPN Tools (certificate creation and Network Traffic Speed Test Tool)"
echo "and"
echo "check"
sleep 3
echo "##########################################"
/usr/local/vpnserver/vpncmd  << EOF | grep  "The command completed successfully." --color=auto
3
check
EOF
echo "##########################################"
sleep 5

cat << EOF > /etc/init.d/vpnserver
#!/bin/sh
### BEGIN INIT INFO
# Provides:		  vpnserver
# Required-Start:	\$network \$remote_fs
# Required-Stop:	 \$network \$remote_fs
# Default-Start:	 2 3 4 5
# Default-Stop:	  0 1 6
# Short-Description: SoftEther VPN Server
# Description:	   Starts the SoftEther VPN Server daemon
### END INIT INFO
# description: SoftEther VPN Server
DAEMON=/usr/local/vpnserver/vpnserver
LOCK=/var/lock/subsys/vpnserver
test -x \$DAEMON || exit 0
case "\$1" in
start)
\$DAEMON start
touch \$LOCK
;;
stop)
\$DAEMON stop
rm \$LOCK
;;
restart)
\$DAEMON stop
sleep 3
\$DAEMON start
;;
*)
echo "Usage: \$0 {start|stop|restart}"
exit 1
esac
exit 0
EOF

chmod 755 /etc/init.d/vpnserver

cat << EOF > /etc/systemd/system/vpnserver.service
[Unit]
Description=SoftEther VPN Server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/vpnserver/vpnserver start
ExecStop=/usr/local/vpnserver/vpnserver stop
ExecReload=/usr/local/vpnserver/vpnserver restart
WorkingDirectory=/usr/local/vpnserver
User=root
Group=root
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl enable vpnserver
