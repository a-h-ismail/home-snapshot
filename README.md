# Purpose
Simple systemd service to take daily snapshots for a specific directory (using rsync).

# Notes
- The timer triggers 5 minutes after boot, then once every 12 hours
- The script will create a link named `latest` pointing to the most recent snapshot. It is used for convenience and to make incremental snapshots possible, do not delete it.
- Main configuration file is stored at `~/.config/home-snapshot.conf`, exclusions file is at `~/.config/home-snapshot-excl.conf`

# Installation
Binaries required: `git bash notify-send rsync`
## Ubuntu/Debian
Run:<br>
`sudo apt update && sudo apt install git rsync libnotify-bin bash`

## Fedora
Run:<br>
`sudo dnf install git rsync libnotify bash`

Clone the repository and run the install script:<br>
```
git clone --depth 1 https://gitlab.com/a-h-ismail/home-snapshot
cd home-snapshot
chmod +x install.sh
./install.sh
```

# Uninstallation
Run the `remove.sh` script.