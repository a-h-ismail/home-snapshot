# home-snapshot

## Purpose

This repository hosts `home-snapshot`, a simple service to take incremental snapshots for any directory.

## About filesystem compatibility

The backup script uses `rsync` with hard linking to save storage space and prevent unnecessary copying. To accomplish this, `rsync` compares the timestamps, permissions (and other data) of source files with the previous snapshot files to hardlink identical files instead of copying them. If your destination filesystem does not support Linux permissions, hard linking may never occur (because permissions are not the same as the original) which leads to unnecessary copying of already existing files, and causes the source permissions to be lost in case of restoring from a snapshot. <br>

- If you are using a Linux filesystem (ext4, btrfs, ...) everything should work as expected.
- For filesystems like NTFS, permissions are not preserved by default. You could add permissions support following [this guide](https://askubuntu.com/a/887502/1386657) for NTFS, or you could set NO_PERMS to 1 in the configuration file, which excludes permissions from comparison of source/destination.
<br>
<br>
tldr: If you don't want problems with snapshots, use a Linux filesystem for the destination.

## Checksums as comparison criteria

The service supports periodically running `rsync` with checksums as the file transfer criteria. This ensures that stale data is not getting silently corrupted. When `rsync` runs with checksums enabled, it will take significally longer to complete a run and take up a lot of disk I/O due to every single file that is in the source and destination being fully read.

An untested backup is not really a backup, so by default the service will run in checksum mode once every 30 times, tune this to your liking in the configuration.

## Other notes

- The timer triggers the service 5 minutes after boot, then once every 12 hours of runtime (PC sleep mode pauses the timer).
- On failure, the service will retry after 10 minutes.
- The script will create a link named `latest` pointing to the most recent snapshot. It is used for convenience and to make incremental snapshots possible, do not delete it.
- Main configuration file is stored at `~/.config/home-snapshot.conf`, exclusions file is at `~/.config/home-snapshot-excl.conf`

## Installation

Binaries required: `git notify-send rsync`.

---

### Ubuntu/Debian

`sudo apt update && sudo apt install git rsync libnotify-bin`

### Fedora

`sudo dnf install git rsync libnotify`

---
Clone the repository and run the install script:<br>

```bash
git clone --depth 1 https://gitlab.com/a-h-ismail/home-snapshot
cd home-snapshot
chmod +x install.sh
./install.sh
```

## Uninstallation

Run the `remove.sh` script.
