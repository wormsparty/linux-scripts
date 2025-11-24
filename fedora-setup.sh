#!/bin/sh

###############################################
# This is the part that is specific to Debian #
###############################################

cd "`dirname $0`"

# 0. Check we are not admin
if [ "`id -u`" -eq 0 ]; then
	echo "Do NOT run this script as root. It will call 'sudo' as needed."
	exit 1
fi

# 1. Install signal
FEDORA_VERSION=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
dnf config-manager addrepo --from-repofile=https://download.opensuse.org/repositories/network:im:signal/Fedora_$FEDORA_VERSION/network:im:signal.repo
dnf install signal-desktop

# 2. Install package
sudo dnf install rclone krita vlc transmission-gtk blender gnome-music vim-enhanced gnome-shell-extension-dash-to-dock gnome-shell-extension-appindicator

# 3. Call the common script for non-specific configuration
sh ./common-setup.sh
