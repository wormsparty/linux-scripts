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
#if [ ! -f /etc/modprobe.d/rtw88_8821ce.conf ]; then
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
#else
#	echo "Ignoring blacklist and bluetooth, looks already done."
#fi

# 3. ArtCraft launcher + Craft apps (replaces Krita and LibreOffice)
# Installs the official .deb/.rpm/.pkg.tar.zst of each app from its latest GitHub release,
# exactly like the launcher does, so the launcher picks them up and updates them.
craft_install() {
	repo="$1"   # e.g. craft-launcher, photocraft
	pkg="$2"    # installed package name, e.g. artcraft-launcher, photocraft

	if command -v apt >/dev/null 2>&1; then
		ext=deb
		installed() { dpkg -s "$pkg" >/dev/null 2>&1; }
		install_file() { sudo apt install -y "$1"; }
	elif command -v dnf >/dev/null 2>&1; then
		ext=rpm
		installed() { rpm -q "$pkg" >/dev/null 2>&1; }
		install_file() { sudo dnf install -y "$1"; }
	elif command -v pacman >/dev/null 2>&1; then
		# Arch / CachyOS: the package is named ai.storyteller.<app> inside the archive
		ext=pkg.tar.zst
		installed() { pacman -Q "ai.storyteller.$pkg" >/dev/null 2>&1; }
		install_file() { sudo pacman -U --needed --noconfirm "$1"; }
	else
		echo "Unsupported package manager, skipping $repo."
		return 1
	fi

	if installed; then
		echo "Ignoring $pkg, already installed (update it from the ArtCraft launcher)."
		return 0
	fi

	arch=$(uname -m)
	url=$(curl -fsSL "https://api.github.com/repos/storytold/$repo/releases/latest" \
		| grep -o '"browser_download_url": *"[^"]*"' | cut -d'"' -f4 \
		| grep -E "/${pkg}-[0-9.]+-linux-${arch}\.${ext}\$" | head -n 1)

	if [ -z "$url" ]; then
		echo "No $ext package found for $repo ($arch), skipping."
		return 1
	fi

	tmp=$(mktemp -d)
	file="$tmp/$(basename "$url")"
	if curl -fL -o "$file" "$url" \
		&& curl -fsSL -o "$tmp/SHA256SUMS.txt" "$(dirname "$url")/SHA256SUMS.txt" \
		&& (cd "$tmp" && grep " \*\?$(basename "$file")\$" SHA256SUMS.txt | sha256sum -c -); then
		install_file "$file"
	else
		echo "Download or checksum verification failed for $repo."
	fi
	rm -rf "$tmp"
}

craft_install craft-launcher artcraft-launcher
craft_install photocraft photocraft
craft_install wordcraft wordcraft
craft_install pdfcraft pdfcraft

# Tidal HiFi (AppImage, latest GitHub release)
TIDAL_APPIMAGE="${HOME}/Applications/tidal-hifi.AppImage"
if [ ! -f "$TIDAL_APPIMAGE" ]; then
	mkdir -p "${HOME}/Applications" "${HOME}/.local/share/applications" "${HOME}/.local/share/icons"

	if [ "$(uname -m)" = "aarch64" ]; then
		TIDAL_PATTERN='tidal-hifi-[0-9.]*-arm64\.AppImage'
	else
		TIDAL_PATTERN='tidal-hifi-[0-9.]*\.AppImage'
	fi

	TIDAL_URL=$(curl -fsSL https://api.github.com/repos/Mastermindzh/tidal-hifi/releases/latest \
		| grep -o "https://[^\"]*/${TIDAL_PATTERN}" | head -n 1)

	if [ -z "$TIDAL_URL" ]; then
		echo "Could not find latest Tidal HiFi release, falling back to 9.0.1."
		TIDAL_URL="https://github.com/Mastermindzh/tidal-hifi/releases/download/9.0.1/tidal-hifi-9.0.1.AppImage"
	fi

	if curl -fL -o "$TIDAL_APPIMAGE" "$TIDAL_URL"; then
		chmod +x "$TIDAL_APPIMAGE"

		# Extract the icon from the AppImage
		TIDAL_TMP=$(mktemp -d)
		(cd "$TIDAL_TMP" && "$TIDAL_APPIMAGE" --appimage-extract 'usr/share/icons/*' > /dev/null 2>&1)
		TIDAL_ICON=$(find "$TIDAL_TMP/squashfs-root/usr/share/icons" -path '*256x256*' -name '*.png' 2> /dev/null | head -n 1)
		if [ -n "$TIDAL_ICON" ]; then
			cp -L "$TIDAL_ICON" "${HOME}/.local/share/icons/tidal-hifi.png"
		fi
		rm -rf "$TIDAL_TMP"

		cat << EOT > "${HOME}/.local/share/applications/tidal-hifi.desktop"
[Desktop Entry]
Type=Application
Name=TIDAL Hi-Fi
Comment=Tidal music client
Exec=${TIDAL_APPIMAGE} %U
Icon=${HOME}/.local/share/icons/tidal-hifi.png
Categories=Audio;Music;Player;AudioVideo;
Terminal=false
StartupWMClass=tidal-hifi
EOT
	else
		echo "Failed to download Tidal HiFi."
		rm -f "$TIDAL_APPIMAGE"
	fi
else
	echo "Ignoring Tidal HiFi, looks already installed."
fi

# 4. Various config

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

# 5. Raspberry
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

