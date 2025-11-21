#!/bin/sh

sudo apt-get install vim kodi kodi-peripheral-joystick openssh-server unison

if ! grep UTF-8 /etc/locale.gen; then
	cat << EOT | sudo tee /etc/locale.gen
en_GB.UTF-8 UTF-8
fr_CH.UTF-8 UTF-8
EOT
	
	sudo locale-gen
	sudo localectl set-locale LANG=en_GB.UTF-8
fi

if ! grep brcmfmac /etc/modprobe.d/raspi-blacklist.conf; then
	cat << EOT | sudo tee /etc/modprobe.d/raspi-blacklist.conf 
blacklist brcmfmac
blacklist brcmutil
blacklist bluetooth
EOT

	sudo modprobe -r brcmfmac
	sudo modprobe -r brcmutil
	sudo depmod -ae
	sudo update-initramfs -u
fi

sudo systemctl disable bluetooth
sudo systemctl enable ssh
sudo systemctl disable wpa_supplicant
sudo systemctl disable bluetooth

cat << EOT | sudo tee /etc/systemd/system/kodi.service
[Unit]
Description=Kodi Media Center
After=systemd-user-sessions.service network.target sound.target

[Service]
User=$USER
Group=$USER
PAMName=login
TTYPath=/dev/tty7
StandardInput=tty
StandardOutput=journal
ExecStart=/usr/bin/kodi --standalone
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOT

# Replace default green to orange prompt 
sed -i 's/\[\\033\[01;32m\\\]/\[\\033\[01;33m\\\]/g' ~/.bashrc

sudo cp config/rpi-wired.nmconnection "/etc/NetworkManager/system-connections/Wired connection 1.nmconnection"
sudo systemctl restart NetworkManager

sudo cp config/joystick.xml /usr/share/kodi/system/keymaps/joystick.xml

echo "Done!"
