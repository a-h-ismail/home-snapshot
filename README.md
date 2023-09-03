# home-snapshot

## Purpose

This repository hosts `home-snapshot`, a simple service to take incremental snapshots for any directory.

## About filesystem compatibility

The backup script uses `rsync` with hard linking to save storage space and prevent unnecessary copying. To accomplish this, `rsync` compares the timestamps, permissions (and other data) of source files with the previous snapshot files to hardlink identical files instead of copying them. If your destination filesystem does not support Linux permissions, hard linking may never occur (because permissions are not the same as the original) which leads to unnecessary copying of already existing files, and causes the source permissions to be lost in case of restoring from a snapshot. <br>

- If you are using a Linux filesystem (ext4, btrfs, ...) everything should work as expected.
- For filesystems like NTFS, permissions are not preserved by default. You could add permissions support following [this guide](https://askubuntu.com/a/887502/1386657) for NTFS, or you could set NO_PERMS to 1 in the configuration file, which excludes permissions from comparison of source/destination.

tldr: If you don't want problems with snapshots, use a Linux filesystem for the destination.

## Checksums as comparison criteria

The service supports periodically running `rsync` with checksums as the file transfer criteria. Quoting `rsync` manual:

```
--checksum, -c
        This  changes the way rsync checks if the files have been changed and are in need of a transfer.  Without this option, rsync uses a "quick check" that (by default) checks
        if each file's size and time of last modification match between the sender and receiver.  This option changes this to compare a 128-bit checksum for each file that has  a
        matching  size.   Generating  the checksums means that both sides will expend a lot of disk I/O reading all the data in the files in the transfer, so this can slow things
        down significantly (and this is prior to any reading that will be done to transfer changed files)

        The sending side generates its checksums while it is doing the file-system scan that builds the list of the available files.  The receiver generates its checksums when it
        is  scanning for changed files, and will checksum any file that has the same size as the corresponding sender's file: files with either a changed size or a changed check‐
        sum are selected for transfer.

        Note that rsync always verifies that each transferred file was correctly reconstructed on the receiving side by checking a whole-file checksum that is  generated  as  the
        file  is  transferred,  but  that  automatic after-the-transfer verification has nothing to do with this option's before-the-transfer "Does this file need to be updated?"
        check.
```

If stale data gets silently corrupted (due to disk error, bit rot...) and doesn't change mod time or size, `rsync` will skip the file even through it should be copied again from the source. This service assumes that the source is the reference (of truth), so this won't save you from corrupted source files.

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
