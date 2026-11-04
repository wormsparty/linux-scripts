#!/bin/sh

################################################
# This is the part that is specific to CachyOS #
################################################

cd "$(dirname "$0")"

# 0. Check we are not admin
if [ "$(id -u)" -eq 0 ]; then
	echo "Do NOT run this script as root. It will call 'sudo' as needed."
	exit 1
fi

# 1. Enable multilib repository (needed for steam)
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
	sudo sed -i '/^#\[multilib\]$/{s/^#//;n;s/^#//}' /etc/pacman.conf
else
	echo "Ignoring multilib, looks already done."
fi

# 2. Install packages (signal-desktop is in the official repositories)
sudo pacman -Syu --needed curl rclone vlc transmission-gtk blender signal-desktop vim unison openai-codex steam gnome-shell-extension-dash-to-dock gnome-shell-extension-appindicator fuse2

sudo timedatectl set-ntp true

# 3. Call the common script for non-specific configuration
sh ./common-setup.sh
