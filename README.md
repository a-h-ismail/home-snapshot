# Purpose
Simple systemd service to take daily snapshots for a specific directory (using rsync).

# Notes
- The timer triggers once per day.
- The script will create a link named `latest` pointing to the most recent snapshot. It is used for convenience and to make incremental snapshots possible, do not delete it.
- Main configuration file is stored at `~/.config/home-snapshot.conf`, exclusions file is at `~/.config/home-snapshot-excl.conf`

# Installation
The following binaries are needed, install them using your package manager: `rsync git bash notify-send`<br>

Clone the repository and run the install script:<br>
```
git clone --depth 1 https://gitlab.com/a-h-ismail/home-snapshot
cd home-snapshot
chmod +x install.sh
./install.sh
```

# Uninstallation
Run the `remove.sh` script.