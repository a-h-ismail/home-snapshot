#!/bin/bash
mkdir -p ~/.config/systemd/user ~/.local/bin
cp home-snapshot.timer home-snapshot.service ~/.config/systemd/user
cp home-snapshot.sh ~/.local/bin
if [[ -f ~/.config/home-snapshot.conf ]]; then
    while true; do
    read -p "You already have a configuration file, overwrite? [Y/n]: "
    if [[ $REPLY == 'Y' ]] || [[ $REPLY == 'y' ]] || [[ -z $REPLY ]]; then
        cp home-snapshot.conf ~/.config
        break;
    elif [[ $REPLY == 'N' ]] || [[ $REPLY == 'n' ]]; then
        break;
    fi
    done
fi
cp -n home-snapshot-excl.conf ~/.config
read -p "Press enter to edit your configuration and exclusion files."
nano ~/.config/home-snapshot.conf ~/.config/home-snapshot-excl.conf
chmod +x ~/.local/bin/home-snapshot.sh
systemctl --user daemon-reload
systemctl --user enable --now home-snapshot.timer
echo "Executing the snapshot tool for the first time..."
~/.local/bin/home-snapshot.sh
