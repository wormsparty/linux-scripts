#!/bin/sh

echo "WARNING: THIS WILL DELETE ALL NEXTCLOUD DATA!"
echo "Are you sure? Type 'yes' to confirm."
printf "> "
read answer

if [ "$answer" != "yes" ]; then
	exit 1
fi

DOMAIN=$(hostname)
APACHE_DIR=/var/www

sudo apt purge apache2 php libapache2-mod-php php-mysql php-common php-gd php-xml php-mbstring php-zip php-curl mariadb-server

sudo rm -f "/etc/apache2/sites-available/${DOMAIN}.conf" "/etc/apache2/sites-enabled/${DOMAIN}.conf"
sudo rm -fr "${APACHE_DIR}/html/${DOMAIN}"

echo "Done!"
