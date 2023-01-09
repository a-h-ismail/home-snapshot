#!/bin/bash
systemctl --user stop home-snapshot.timer
rm ~/.config/home-snapshot.conf ~/.config/home-snapshot-excl.conf \
~/.config/systemd/user/home-snapshot.*
echo "Uninstall completed."