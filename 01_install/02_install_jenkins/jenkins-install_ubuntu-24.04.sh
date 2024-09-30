#!/bin/bash

sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
	https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
if [ ! -f "/usr/share/keyrings/jenkins-keyring.asc" ] ; then
	exit 0;
fi	


echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
	https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
	/etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install fontconfig openjdk-17-jre -y || { echo "#### filed error code : $? ####" ; exit 1; }
sudo apt-get install jenkins -y || { echo "#### filed error code : $? ####" ; exit 2; }

echo "#### sj Success!! install jenkins.!! sj #####"
