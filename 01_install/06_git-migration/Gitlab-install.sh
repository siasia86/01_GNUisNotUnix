#!/bin/bash

PORT1=`netstat -nlpt | grep -i "0.0.0.0:80 " | awk '{print $4}'`
install1=`dpkg -l | grep -i gitlab | awk '{print $1}'`
FILE_1="install"
var1="ii"

echo "$install1"

	for var in `cat /root/sj_del/gitlab01.conf | grep -v "^#\|^$"` ; do


		if [ "${install1}" == "${var1}" ]; then

				echo "===========  `date +%Y%m%d-%H:%M:%S`  ============"
				echo "==== apt install -y gitlab-ee=${var} install ===="		   >> /root/sj_del/${FILE_1}.log
				echo "==== apt install -y gitlab-ee=${var} install ===="
				echo `apt-get install -y gitlab-ee=${var}				   >> /root/sj_del/${FILE_1}.log`

				echo "==== gitlab-ctl restart ===="	 >> /root/sj_del/${FILE_1}.log
				echo "`gitlab-ctl restart`"
				sleep 60
				echo `gitlab-ctl reconfigure						>> /root/sj_del/${FILE_1}.log`
				sleep 10

				PORT2=`netstat -nlpt | grep -i "0.0.0.0:80 " | awk '{print $4}'`
				if [ "${PORT2}" == "0.0.0.0:80" ] ; then
					echo "==== gitlab-rake gitlab:check ====" >> /root/sj_del/${FILE_1}.log
					echo `gitlab-rake gitlab:check					  >> /root/sj_del/${FILE_1}.log`

					echo "==== gitlab-rake gitlab:env:info ====" >> /root/sj_del/${FILE_1}.log
					echo `gitlab-rake gitlab:env:info					   >> /root/sj_del/${FILE_1}.log`
				else
					echo "==== gitlab-ee service status confirm.1111111 ====";
				fi
				install1=`dpkg -l | grep -i gitlab | awk '{print $1}'`

		else
				echo "version confirm."

		fi
			echo "${install1}"					  >> /root/sj_del/${FILE_1}.log

	 j=$((j+1))
		echo "$j"
		echo "==================================================${j} " >> /root/sj_del/${FILE_1}.log
		echo "===========  `date +%Y%m%d-%H:%M:%S`  ============" >> /root/sj_del/${FILE_1}.log
	done
echo " End Scripts. `date +%Y%m%d-%H:%M:%S` "
