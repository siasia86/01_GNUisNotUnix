#!/bin/bash

echo "Start.	`date +%Y%m%d-%H:%M:%S`		sjyun" >> Install.log


sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq

yes yes | gitlab-rake gitlab:backup:restore BACKUP=1681684940_2023_04_16_11.9.0-ee >> Install.log


echo "End.	`date +%Y%m%d-%H:%M:%S`		sjyun" >> Install.log


exit;
