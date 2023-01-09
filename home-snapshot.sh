#!/bin/bash
# A script to perform incremental backups using rsync
# Get configuration file content
config=`cat ~/.config/home-snapshot.conf`

source_dir=`echo "$config" | grep 'SOURCE_DIR=' | cut -d = -f 2`
destination_dir=`echo "$config" | grep 'DESTINATION_DIR=' | cut -d = -f 2`
max_snapshots=`echo "$config" | grep 'MAX_SNAPSHOTS=' | cut -d = -f 2`

today_date="$(date '+%d-%m-%Y')"
# Full backup path
backup_path="${destination_dir}/${today_date}"
#latest link is used for hard linking snapshots to reduce used space
latest_link="${destination_dir}/latest"

#If a backup was taken today, don't take another one
if [ -z $(ls "$destination_dir" | grep $today_date) ]
  then
  mkdir -p "${backup_path}"
  rsync -aX --delete "$source_dir/" --link-dest "$latest_link" --exclude-from="$HOME/.config/home-snapshot-excl.conf" "$backup_path" 2> /tmp/backup_error.log

  #If rsync doesn't exit with value 0 for any reason, notify the user
  rsync_exit=$?
  if [ $rsync_exit -ne "0" ]
  then
    notify-send -a "rsync" -u critical 'Home snapshot possibly failed' "Will retry on next run, rsync exit value $rsync_exit."
    rm -rf $backup_path
    exit 1
  fi
  rm -rf "${latest_link}"
  ln -rs "${backup_path}" "${latest_link}"
fi

#Cleanup old backups (keep only $max_snapshots)
backups=$(ls -rt "$destination_dir")
oldest_backup=$(echo "$backups" | awk 'NR==1{print $1}')
let backup_count=$(echo "$backups" | wc -w)-1
if [ $backup_count -gt $max_snapshots ] && [ -n $oldest_backup ]
then
  echo "Deleting snapshot folder $oldest_backup"
  echo "${destination_dir}/$oldest_backup"
  rm -rf "${destination_dir}/$oldest_backup"
fi
