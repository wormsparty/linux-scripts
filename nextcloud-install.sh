#!/bin/sh


# See: https://linux.how2shout.com/step-by-step-guide-installing-nextcloud-on-debian-12/

echo "Your hostname is: $(hostname)"

DOMAIN=$(hostname)
APACHE_DIR=/var/www
DB_NAME=
DB_USERNAME=
DB_PASSWORD=

echo "Choose the database name (nextcloud):"
printf "> "
read DB_NAME
DB_NAME="${DB_NAME:-nextcloud}"

echo "Choose the database username (nextcloud):"
printf "> "
read DB_USERNAME
DB_USERNAME="${DB_USERNAME:-nextcloud}"

stty -echo
while [ -z "$DB_PASSWORD" ]; do
	echo "Choose the database password:"
	printf "> "
	read DB_PASSWORD
	echo
done
stty echo

echo "Are the above information correct? Press enter to continue, or Ctrl+C to abort."
read ans

sudo apt install apache2 php libapache2-mod-php php-mysql php-common php-gd php-xml php-mbstring php-zip php-curl mariadb-server

cat << EOT | sudo tee /etc/apache2/sites-available/${DOMAIN}.conf
<VirtualHost *:80>
    ServerAdmin admin@${DOMAIN}
    DocumentRoot ${APACHE_DIR}/html/${DOMAIN}/
    ServerName ${DOMAIN}

    <Directory ${APACHE_DIR}/html/${DOMAIN}/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
        SetEnv HOME ${APACHE_DIR}/html/${DOMAIN}
        SetEnv HTTP_HOME ${APACHE_DIR}/html/${DOMAIN}
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOT

sudo ln -s /etc/apache2/sites-available/${DOMAIN}.conf /etc/apache2/sites-enabled/
sudo a2enmod headers rewrite env dir mime
sudo systemctl restart apache2

sudo mysql_secure_installation

cat << EOT | sudo mysql
CREATE DATABASE ${DB_NAME};
GRANT ALL ON ${DB_NAME}.* TO ${DB_USERNAME}@localhost IDENTIFIED BY '${DB_PASSWORD}';
FLUSH PRIVILEGES;
\q;
EOT

sudo mkdir -p ${APACHE_DIR}/html/${DOMAIN}
cd ${APACHE_DIR}/html/${DOMAIN}

if [ ! -f latest.tar.bz2 ]; then
	sudo wget https://download.nextcloud.com/server/releases/latest.tar.bz2
fi

if [ ! -f index.html ]; then
	echo "Extracting..."
	sudo tar xf latest.tar.bz2 --strip-components 1
fi

sudo mkdir -p ${APACHE_DIR}/html/${DOMAIN}/data
sudo chown -R www-data:www-data ${APACHE_DIR}/html/${DOMAIN}/
sudo chmod -R 755 ${APACHE_DIR}/html/${DOMAIN}/

xdg-open "http://${DOMAIN}" 2>/dev/null || echo "Visit http://${DOMAIN}"
