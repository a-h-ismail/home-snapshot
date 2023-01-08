#!/bin/bash
mkdir ~/.config/systemd
mkdir ~/.config/systemd/user
cp home-snapshot.timer home-snapshot.service ~/.config/systemd/user
cp home-snapshot.sh ~/.local/bin
#cp home-snapshot.conf ~/.config
read -p "Press enter to edit your configuration file."
nano ~/.config/home-snapshot.conf
chmod +x ~/.local/bin/home-snapshot.sh
systemctl --user daemon-reload
systemctl --user enable --now home-snapshot.timer