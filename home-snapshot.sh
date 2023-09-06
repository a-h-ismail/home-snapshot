#!/bin/bash
# A script to perform incremental backups using rsync
# Get configuration file content
config=$(cat ~/.config/home-snapshot.conf)

# Get and validate source directory
source_dir=$(echo "$config" | grep '^SOURCE_DIR=' | cut -d = -f 2-)
if [[ -z "$source_dir" ]]; then
	notify-send -a "home-snapshot" -u critical 'Source directory is not specified' "Fix your configuration at $HOME/.config/home-snapshot.conf"
	exit 1
elif [[ ! -d "$source_dir" ]]; then
    notify-send -a "home-snapshot" -u critical 'Source directory inaccessible' "Fix your configuration at $HOME/.config/home-snapshot.conf"
    exit 1
fi

# Get and validate destination directory
destination_dir=$(echo "$config" | grep '^DESTINATION_DIR=' | cut -d = -f 2-)
if [[ -z "$destination_dir" ]]; then
	notify-send -a "home-snapshot" -u critical 'Destination directory is not specified' "Fix your configuration at $HOME/.config/home-snapshot.conf"
	exit 2
elif [[ ! -d "$destination_dir" ]]; then
    notify-send -a "home-snapshot" -u critical 'Destination directory inaccessible' "Fix your configuration at $HOME/.config/home-snapshot.conf"
    exit 2
fi

# Get number of snapshots to keep
max_snapshots=$(echo "$config" | grep '^MAX_SNAPSHOTS=' | cut -d = -f 2)
if [[ -z "$max_snapshots" ]]; then
	notify-send -a "home-snapshot" -u critical 'Max snapshots is not specified' "Fix your configuration at $HOME/.config/home-snapshot.conf"
	exit 3
elif ! [[ $max_snapshots =~ [[:digit:]] ]]; then
    notify-send -a "home-snapshot" -u critical 'Invalid max snapshots value' "Fix your configuration at $HOME/.config/home-snapshot.conf"
    exit 3
fi

# Get number of snapshots to run before running one with checksums
checksum_interval=$(echo "$config" | grep '^CHECKSUM_INTERVAL=' | cut -d = -f 2)
if [[ -z "$checksum_interval" ]]; then
    notify-send -a "home-snapshot" -u critical 'Checksum interval is not specified' "Fix your configuration at $HOME/.config/home-snapshot.conf"
    exit 4
elif ! [[ $checksum_interval =~ [[:digit:]] ]]; then
    notify-send -a "home-snapshot" -u critical 'Invalid checksum interval' "Fix your configuration at $HOME/.config/home-snapshot.conf"
    exit 4
fi

remote_fs=$(echo "$config" | grep '^REMOTE_FILESYSTEM' | cut -d = -f 2)

if [ ! -f "$HOME/.local/share/home-snapshot-state" ]; then
    echo "$checksum_interval" > "$HOME/.local/share/home-snapshot-state"
else
    rounds_until_checksum=$(cat "$HOME/.local/share/home-snapshot-state")
fi

# Use to add the --no-perms as workaround for filesystems not supporting Linux permissions
no_perms=$(echo "$config" | grep '^NO_PERMS=' | cut -d = -f 2)

today_date="$(date '+%d-%m-%Y')"
# Full backup path
backup_path="$destination_dir/$today_date"
# latest link is used for hard linking snapshots to reduce used space
latest_link="$destination_dir/latest"
# For rsync stderr
log_location='/tmp/home_snapshot.log'

rsync_options=(-aXh --stats --delete)

# Disable rsync delta algorithm for remote filesystems
if [[ $remote_fs == 'Y' ]]; then
    rsync_options+=(-W)
fi

if [[ $no_perms -eq 1 ]]; then
    rsync_options+=(--no-perms)
fi

if [[ $rounds_until_checksum -eq 0 ]]; then
    rsync_options+=(--checksum)
fi

# Detect destination within the source tree to exclude it from rsync
dst_to_src=`realpath --relative-to="$source_dir" "$destination_dir"`

if [[ -z $(echo "$dst_to_src" | grep "^\.\./") ]]; then
    rsync_options+=(--exclude="$dst_to_src")
fi

if [[ -L $latest_link ]]; then
    rsync_options+=(--link-dest "$latest_link")
fi

rsync_options+=(--exclude-from="$HOME/.config/home-snapshot-excl.conf" --delete "$source_dir/" "$backup_path")

cd "$destination_dir"
# If a backup was taken today, don't take another one
if [ -z "$(echo * | grep "$today_date")" ]; then
    mkdir -p "$backup_path"
    rsync "${rsync_options[@]}" 2> $log_location
    # Act depending on rsync exit
    rsync_exit=$?

    if [[ $rsync_exit -ne 0 ]] && [[ $rsync_exit -ne 24 ]]; then
        notify-send -a "rsync" -u critical 'Home snapshot possibly failed' "Check the log at $log_location, the service will retry in 10 minutes."
        rm -rf "$backup_path"
        exit 1
    else
        rm "$latest_link"
        ln -rs "$backup_path" "$latest_link"
    fi

    if [[ $rounds_until_checksum -gt 0 ]]; then
        rounds_until_checksum=$((rounds_until_checksum-1))
    else
        rounds_until_checksum="$checksum_interval"
    fi

    if [[ $checksum_interval -ge 0 ]]; then
        echo "$rounds_until_checksum" > "$HOME/.local/share/home-snapshot-state"
    fi
else
    echo "Snapshot was already taken: $today_date"
fi

# Cleanup old backups (keep only $max_snapshots)
backups=$(ls -rt "$destination_dir")
oldest_backup=$(echo "$backups" | awk 'NR==1 {print $0; exit}')
backup_count=$((`echo "$backups" | wc -w`-1))
if [ "$backup_count" -gt "$max_snapshots" ] && [ -n "$oldest_backup" ]; then
    echo "Deleting snapshot directory $destination_dir/$oldest_backup"
    # Block the command if destination_dir is not set somehow
    rm -rf "${destination_dir:?}/$oldest_backup"
fi
