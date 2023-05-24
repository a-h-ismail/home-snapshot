#!/bin/bash
# A script to perform incremental backups using rsync
# Get configuration file content
config=`cat ~/.config/home-snapshot.conf`

source_dir=`echo "$config" | grep 'SOURCE_DIR=' | cut -d = -f 2`
if [ -z "$source_dir" ]; then
	notify-send -a "home-snapshot" -u critical 'Source directory is not specified' "Fix your configuration at $HOME/.config/home-snapshot.conf"
	exit 1
fi
destination_dir=`echo "$config" | grep 'DESTINATION_DIR=' | cut -d = -f 2`
if [ -z "$destination_dir" ]; then
	notify-send -a "home-snapshot" -u critical 'Destination directory is not specified' "Fix your configuration at $HOME/.config/home-snapshot.conf"
	exit 1
fi
max_snapshots=`echo "$config" | grep 'MAX_SNAPSHOTS=' | cut -d = -f 2`
if [ -z "$max_snapshots" ]; then
	notify-send -a "home-snapshot" -u critical 'Max snapshots is not specified' "Fix your configuration at $HOME/.config/home-snapshot.conf"
	exit 1
fi

today_date="$(date '+%d-%m-%Y')"
# Full backup path
backup_path="$destination_dir/$today_date"
#latest link is used for hard linking snapshots to reduce used space
latest_link="$destination_dir/latest"
# Use to add the --no-perms as workaround for filesystems not supporting Linux permissions
no_perms=`echo "$config" | grep 'NO_PERMS=' | cut -d = -f 2`
if [ $no_perms = "1" ]
then
    no_perms="--no-perms"
else
    no_perms=""
fi

log_location='/tmp/home_snapshot.log'

#If a backup was taken today, don't take another one
if [ -z `ls "$destination_dir" | grep $today_date` ]
    then
    mkdir -p "$backup_path"
    rsync -aXh --stats --delete $no_perms "$source_dir/" --link-dest "$latest_link" --exclude-from="$HOME/.config/home-snapshot-excl.conf" "$backup_path" 2> $log_location
else
    echo "Snapshot was already taken: $today_date"
fi

# Act dependig on rsync exit
rsync_exit=$?
if [ $rsync_exit -ne "0" ] && [ $rsync_exit -ne "24" ]
then
    notify-send -a "rsync" -u critical 'Home snapshot possibly failed' "Check the log at $log_location, the service will retry in 10 minutes."
    rm -rf "$backup_path"
    exit 1
fi
rm -rf "$latest_link"
ln -rs "$backup_path" "$latest_link"


#Cleanup old backups (keep only $max_snapshots)
backups=$(ls -rt "$destination_dir")
oldest_backup=$(echo "$backups" | awk 'NR==1{print $1}')
let backup_count=$(echo "$backups" | wc -w)-1
if [ $backup_count -gt $max_snapshots ] && [ -n $oldest_backup ]
then
    echo "Deleting snapshot directory $destination_dir/$oldest_backup"
    rm -rf "$destination_dir/$oldest_backup"
fi
