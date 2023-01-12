#!/bin/bash
mkdir -p ~/.config/systemd/user ~/.local/bin
cp home-snapshot.timer home-snapshot.service ~/.config/systemd/user
cp home-snapshot.sh ~/.local/bin
cp home-snapshot.conf home-snapshot-excl.conf ~/.config
read -p "Press enter to edit your configuration and exclusion files."
nano ~/.config/home-snapshot.conf ~/.config/home-snapshot-excl.conf
chmod +x ~/.local/bin/home-snapshot.sh
systemctl --user daemon-reload
systemctl --user enable --now home-snapshot.timer