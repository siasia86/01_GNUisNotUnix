#!/bin/bash

echo "Start.	`date +%Y%m%d-%H:%M:%S`		sjyun" >> Install2.log


gitlab-backup create	>> Install2.log



echo "End.	`date +%Y%m%d-%H:%M:%S`		sjyun" >> Install2.log


exit;
