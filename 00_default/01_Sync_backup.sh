#!/usr/bin/bash
#### 30 00 * * *  /usr/bin/bash /root/01_Sync_backup.sh
#### 30 00 * * 6  /usr/bin/bash /root/01_Sync_backup.sh

## sj_del added
  export LANG=en
  dayno="`date '+%j'`"
  daybak="`expr $dayno % 4`"
  backup_dir="/backup/sync/sync_$daybak"


function sync_bak {
  from=$1
  to=$2
  if [ ! -d "$to" ] ; then mkdir -p $to ; fi
        rsync -av --delete --exclude=log --exclude=lib/mysql $from $to

}

rm -f /backup/sync/today
ln -s $backup_dir /backup/sync/today

sync_bak /usr/local/ $backup_dir/usr-local/
sync_bak /etc/ $backup_dir/etc/
sync_bak /root/ $backup_dir/root/
sync_bak /var/ $backup_dir/var/
sync_bak /home/ $backup_dir/home/

## restore list : /etc/elasticsearch/ /etc/graylog/ /etc/nginx/

touch $backup_dir
