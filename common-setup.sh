#!/bin/sh

#############################################################################
# This is the part that is not specific to a particular Linux distribution. #
#############################################################################

cd "$(dirname "$0")"

# 1. rclone service for Google Drive
mkdir -p ~/GdriveSync

mkdir -p "${HOME}/.config/rclone"
touch "${HOME}/.config/rclone/rclone.conf"

if ! grep -q '\[gdrive\]' "${HOME}/.config/rclone/rclone.conf"; then
	echo "Please add your Google Drive account and name it 'gdrive'"
	rclone config

	if ! grep -q '\[gdrive\]' "${HOME}/.config/rclone/rclone.conf"; then
		echo "'gdrive' doesn't seem to be configured. Please configure it and re-run this script"
		#exit 1
	fi
fi

if [ ! -d ~/.local/bin ]; then
	ln -s "$PWD/bin" ~/.local/bin
fi

# 2. Disable wifi & bluetooth
if [ ! -f /etc/modprobe.d/rtw88_8821ce.conf ]; then
	# To find your wifi kernel module: lspci -v, and the driver name is the last line

	# Wifi drivers for various desktop / laptops I've had, mostly Dells & a Macbook
	for module in rtw88_8821ce mt7921e mwifiex_pcie iwlwifi bcma; do
		sudo tee "/etc/modprobe.d/$module.conf" > /dev/null << EOF
blacklist $module
install $module /bin/true
EOF
	done

	# All bluetooth drivers I could find
	sudo tee /etc/modprobe.d/bluetooth.conf > /dev/null << 'EOF'
blacklist bluetooth
install bluetooth /bin/true
blacklist btrtl
blacklist btmtk
blacklist btintel
blacklist btbcm
blacklist btusb
EOF

	if which dracut; then
		# OpenSUSE, Fedora, etc.
		sudo dracut -f --regenerate-all
   	
		if which mkinitrd; then
    			# OpenSUSE version
    			sudo mkinitrd
      		fi
	elif which mkinitcpio; then
		# Archlinux, CachyOS, etc.
		sudo mkinitcpio -P
	else
		# Debian version
		sudo depmod -ae
		sudo update-initramfs -u
  	fi
	

	sudo modprobe -r rtw88_8821ce
	sudo modprobe -r mwifiex_pcie
	sudo modprobe -r bluetooth
	sudo modprobe -r iwlwifi
	sudo modprobe -r bcma
	
	#sudo bash -c "echo 'iface wlp2s0 inet manual' > /etc/network/interfaces.d/no-wifi" 
	sudo systemctl disable bluetooth.service
	sudo sed -i 's/AutoEnable=true/AutoEnable=false/' /etc/bluetooth/main.conf
	sudo sed -i 's/#AutoEnable=true/AutoEnable=false/' /etc/bluetooth/main.conf
else
	echo "Ignoring blacklist and bluetooth, looks already done."
fi

# 3. Various config

# Prevent oversized journal files
sudo sed -i 's/#SystemMaxUse=/SystemMaxUse=50M/' /etc/systemd/journald.conf

if ! grep -q "XDG_SESSION_TYPE" ~/.profile; then
	cat << EOT | tee -a ~/.profile
if [ "\$XDG_SESSION_TYPE" == "wayland" ]; then
  export MOZ_ENABLE_WAYLAND=1
fi
EOT
fi

gsettings set org.gnome.desktop.privacy remember-recent-files false

# 4. Raspberry
if ! grep -q rpi /etc/hosts; then
	echo "192.168.1.153   rpi" | sudo tee -a /etc/hosts
else
	echo "Ignoring modifying hosts, looks already done."
fi

SSH_KEY=$(find ~/.ssh -name \*.pub)

if [ -z "${SSH_KEY}" ]; then
	ssh-keygen -t ed25519 -C "wormsparty@gmail.com"
	SSH_KEY=$(find ~/.ssh -name \*.pub)

	if [ -z "${SSH_KEY}" ]; then
		echo "Failed to find SSH key."
		exit 1
	fi

	cat "$SSH_KEY" | ssh rpi "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
fi

if [ ! -f ./unison-hourly.cron ]; then
	cat << EOT > ./unison-hourly.cron
SHELL=/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=""
HOME=/home/$USER/

# For details see man 4 crontabs

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * command to be executed
  0  *  *  *  * /usr/local/bin/rpi-sync
EOT
else
	echo "Ignoring unison config, looks already done."
fi

echo "Manual steps:"
echo " 1. Install Gnome Shell extensions (Dash to Dock + Tray Icon Reloaded)"
echo " 2. Run 'rpi-sync' and check that everything looks good. If it does, enable crontab with 'crontab ./unison-hourly.cron'."
echo "That's it !"

