#!/usr/bin/env bash

SRC_PATH="$(cd `dirname -- $0` && pwd)"

USER_BIN_DIR="${HOME}/.local/bin"

DEFAULT_DOMAIN="ubuntu.localhost"
USER_APACHE_DIR="${HOME}/Developer/www"

PMA_LANG=es

MARIADB_VERSION="10.5"

INSTALL_PACKAGES=(
  imagemagick
  libnss3-tools # mkcert

  # server
  apache2
  mariadb-server
  postfix

  php8.0-fpm
  php8.0-bz2 # PHAR
  php8.0-curl # phpMyAdmin
  php8.0-gd # phpMyAdmin
  php8.0-mbstring # phpMyAdmin
  php8.0-mysql # phpMyAdmin
  php8.0-zip # phpMyAdmin
  php8.0-xml # WordPress
  php8.0-imagick # WordPress
  php8.0-xdebug

  php7.4-fpm
  php7.4-bz2
  php7.4-curl
  php7.4-gd
  php7.4-mbstring
  php7.4-mysql
  php7.4-zip
  php7.4-xml
  php7.4-imagick
  php7.4-xdebug

  php-pear
  ghostscript # Ghostscript is required for rendering PDF previews (WordPress)
  libnss-myhostname # Add support for domain like *.localhost
)

#
# FUNCTIONS
#

function github_download_url() {
  curl -sN "https://api.github.com/repos/${1}/releases/latest" | grep -m 1 "browser_download_url.*${2}" | cut -d '"' -f 4
}

function cmd_exists() {
  command -v $1 >/dev/null 2>&1
  return $?
}

function apt_install() {
  local to_install=()
  echo "Checking if the packages is installed"
  for x in "${@}"; do
    if ! cmd_exists $x; then
      ( LANG= apt-cache policy "$x" | grep -q 'Installed: (none)' ) && to_install+=($x);
    fi
  done; unset x
  if [[ ${#to_install[@]} -gt 0 ]]; then
    echo "Installing packages"
    sudo apt install -y --no-install-recommends ${to_install[@]}
  fi
}

#
# SETUP
#

mkdir -p "${USER_BIN_DIR}"
if ! `echo $PATH | grep -q "$USER_BIN_DIR"`; then
  echo "Detected missing $USER_BIN_DIR inside PATH env"
  echo "Add the $USER_BIN_DIR to PATH"
fi

# REQUIRED PACKAGES
echo "Installing basic packages"
apt_install curl wget pwgen apt-transport-https gnupg rsync lsb-release

# REPOSITORIES SETUP
CODENAME="$(lsb_release -sc)"
REQUIRE_UPDATE=1

echo "Adding repositories"
PPA_REPOSITORIES=( "ondrej/apache2" "ondrej/php" )
for x in "${PPA_REPOSITORIES[@]}"; do
  grep -q "^deb.*${x}" /etc/apt/sources.list.d/*.list &>/dev/null || (
    sudo add-apt-repository -y --no-update "ppa:${x}" &>/dev/null
    REQUIRE_UPDATE=0
  )
done; unset x


if [[ ! -f "/etc/apt/sources.list.d/mariadb-${MARIADB_VERSION}.list" ]]; then
  sudo find /etc/apt/sources.list.d -name "mariadb*" -delete
  sudo apt-key adv --fetch-keys "https://mariadb.org/mariadb_release_signing_key.asc"
  (
    echo "deb [arch=amd64,arm64,ppc64el] http://ams2.mirrors.digitalocean.com/mariadb/repo/${MARIADB_VERSION}/ubuntu ${CODENAME} main"
    echo "# deb-src http://ams2.mirrors.digitalocean.com/mariadb/repo/${MARIADB_VERSION}/ubuntu ${CODENAME} main"
  ) | sudo tee "/etc/apt/sources.list.d/mariadb-${MARIADB_VERSION}.list" &>/dev/null
  REQUIRE_UPDATE=0
fi

[ $REQUIRE_UPDATE -eq 0 ] && (
  echo "Updating system"
  sudo apt update 2>&1 | grep -q "list-upgrade" && sudo apt -y upgrade
)

# INSTALL PACKAGES
echo "postfix postfix/main_mailer_type select Internet Site" | sudo debconf-set-selections
echo "postfix postfix/mailname string ${DEFAULT_DOMAIN}" | sudo debconf-set-selections
apt_install ${INSTALL_PACKAGES[@]}

# MKCERT SETUP
cmd_exists mkcert && echo -n "Updating" || echo -n "Installing"
echo " mkcert"
sudo wget -q `github_download_url "FiloSottile/mkcert" "linux-amd64"` -O /usr/local/bin/mkcert
sudo chmod +x /usr/local/bin/mkcert
[ -d "${HOME}/.local/share/mkcert" ] || mkcert -install

# APACHE SETUP
cmd_exists apache2ctl && echo -n "Updating" || echo -n "Installing"
echo " Apache"
MODULES=(
  headers
  rewrite
  ssl
  http2
  proxy_fcgi
  proxy_http
  proxy_wstunnel
)
MODS_ENABLED="$(ls /etc/apache2/mods-enabled)"
for x in "${MODULES[@]}"; do echo "${MODS_ENABLED}" | grep -q "${x}" || sudo a2enmod "${x}"; done; unset x
sudo rm -f /etc/apache2/mods-enabled/status.{conf,load}
sudo find /etc/apache2/conf-enabled -mindepth 1 -delete
sudo find /etc/apache2/sites-enabled /etc/apache2/sites-available -mindepth 1 -name "*default*" -delete
[ -f /etc/apache2/apache2.conf.original ] || sudo mv /etc/apache2/apache2.conf{,.original}
sudo cp -f "${SRC_PATH}/apache/apache2.conf" /etc/apache2/apache2.conf
sudo sed -i "s/DEFAULT_DOMAIN/${DEFAULT_DOMAIN}/g" /etc/apache2/apache2.conf
sudo sed -i "s@VIRTUALHOSTS_DIR@${USER_APACHE_DIR}@g" /etc/apache2/apache2.conf
rsync -az "${SRC_PATH}/apache/bin/" "${USER_BIN_DIR}/"
sed -i "s@DOCUMENTROOT@${USER_APACHE_DIR}@g" "${USER_BIN_DIR}/a2v"
chmod +x -R "${USER_BIN_DIR}/"
"${USER_BIN_DIR}/a2c" -c "${DEFAULT_DOMAIN}" &>/dev/null
[ -d "${USER_APACHE_DIR}" ] || mkdir -p "${USER_APACHE_DIR}"

# PHP SETUP
cmd_exists php && echo -n "Updating" || echo -n "Installing"
echo " PHP"
(
  echo "<?php phpinfo();"
) | sudo tee /var/www/html/info.php &>/dev/null
sudo phpdismod -s cli xdebug
PHP_CURL_CERT="$(ls /etc/ssl/certs/ | grep -m1 mkcert)"
for php_version in $(ls /etc/php); do
    sudo rsync -azh "${SRC_PATH}/php/8.0/" "/etc/php/$php_version/"
    if [[ -d "/etc/php/$php_version/fpm" ]]; then
      if [[ -f "/usr/lib/php/$php_version/php.ini-development" ]]; then
        sudo cp -f "/usr/lib/php/$php_version/php.ini-development" "/etc/php/$php_version/fpm/php.ini"
      fi
      if [[ -f "/etc/php/$php_version/fpm/conf.d/95-php.ini" ]]; then
        sudo sed -i "s@mkcert.*@${PHP_CURL_CERT}@" "/etc/php/$php_version/fpm/conf.d/95-php.ini"
      fi
      if [[ -f "/etc/php/$php_version/fpm/php-fpm.conf" ]]; then
        sudo sed -i 's@^error_log.*@error_log = /var/log/php-fpm.log@' "/etc/php/$php_version/fpm/php-fpm.conf"
      fi
      if [[ -f "/etc/php/$php_version/fpm/pool.d/www.conf" ]]; then
        sudo sed -i "s/PHP_VERSION/$php_version/" "/etc/php/$php_version/fpm/pool.d/www.conf"
      fi
      if [[ -f "/etc/php/$php_version/fpm/pool.d/user.conf" ]]; then
        sudo sed -i "s/CURRENT_USER/${USER}/" "/etc/php/$php_version/fpm/pool.d/user.conf"
        sudo sed -i "s/PHP_VERSION/$php_version/" "/etc/php/$php_version/fpm/pool.d/user.conf"
      fi
    fi
done
sudo cp -f "${SRC_PATH}/php/php-fpm.service" /lib/systemd/system/php-fpm.service

# MARIADB SETUP
cmd_exists mysql && echo -n "Updating" || echo -n "Installing"
echo " MariaDB"
sudo cp -f "${SRC_PATH}/mariadb/conf.d/90-custom.cnf" /etc/mysql/mariadb.conf.d/90-custom.cnf
sudo systemctl restart mariadb
(
  echo "DROP DATABASE IF EXISTS test;"
  echo "DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
  echo "DELETE FROM mysql.global_priv WHERE User='';"
  echo "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
  echo -n "UPDATE mysql.global_priv SET priv=json_set(priv, '$.plugin', 'mysql_native_password', '$.authentication_string', PASSWORD('root'),"
  echo " '$.auth_or', json_array(json_object(), json_object('plugin', 'unix_socket'))) WHERE User='root';"
  echo " FLUSH PRIVILEGES;"
) | sudo mysql


# PHPMYADMIN SETUP
sudo cp -f "${SRC_PATH}/phpmyadmin/phpmyadmin.sh" /etc/cron.monthly/phpmyadmin.sh
sudo sed -i "s/PMA_LANG/${PMA_LANG}/" /etc/cron.monthly/phpmyadmin.sh
sudo chmod +x /etc/cron.monthly/phpmyadmin.sh
if [[ ! -d /var/www/html/phpmyadmin ]]; then
  echo "Installing phpMyAdmin"
  PMA_PASSWORD=`pwgen -svB 16 1`
  sudo bash /etc/cron.monthly/phpmyadmin.sh
  (
    echo "CREATE DATABASE IF NOT EXISTS phpmyadmin DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;"
    echo "DROP USER IF EXISTS 'pma'@'localhost';"
    echo -n "GRANT SELECT, INSERT, UPDATE, DELETE, ALTER ON phpmyadmin.* TO 'pma'@'localhost'"
    echo " IDENTIFIED VIA mysql_native_password USING PASSWORD('${PMA_PASSWORD}');"
    echo "FLUSH PRIVILEGES;"
  ) | sudo mysql -uroot
  sudo mysql -uroot < /var/www/html/phpmyadmin/sql/create_tables.sql
  sudo rm -rf /var/www/html/phpmyadmin/sql
  sudo cp -f "${SRC_PATH}/phpmyadmin/config.inc.php" /var/www/html/phpmyadmin/config.inc.php
  sudo sed -i "s/pmapass/${PMA_PASSWORD}/" /var/www/html/phpmyadmin/config.inc.php
else
  echo "Updating phpMyAdmin"
  sudo bash /etc/cron.monthly/phpmyadmin.sh
fi

# MAILHOG
( cmd_exists mhsendmail && cmd_exists mailhog ) && echo -n "Updating" || echo -n "Installing"
echo " MailHog"
sudo systemctl stop mailhog &>/dev/null
sudo wget -q `github_download_url "mailhog/mhsendmail" "_linux_amd64"` -O /usr/local/bin/mhsendmail
sudo chmod +x /usr/local/bin/mhsendmail
sudo wget -q `github_download_url "mailhog/MailHog" "_linux_amd64"` -O /usr/local/bin/mailhog
sudo chmod +x /usr/local/bin/mailhog
sudo cp -f "${SRC_PATH}/mailhog/mailhog.service" /lib/systemd/system/mailhog.service
sudo sed -i "s/DEFAULT_DOMAIN/${DEFAULT_DOMAIN}/" /lib/systemd/system/mailhog.service

# SERVER SERVICES
echo "Tweaks for lamp services"
sudo cp -f "${SRC_PATH}/services/lamp.service" /lib/systemd/system/lamp.service

sudo systemctl daemon-reload
sudo systemctl disable apache2 php-fpm mariadb postfix mailhog lamp &>/dev/null
find /lib/systemd/system/ -name "php*-fpm*" -not -name "php-fpm*" -exec basename {} \; | xargs sudo systemctl disable &>/dev/null

echo "Creating the lamp command, shortcut for all lamp services"
rsync -az "${SRC_PATH}/bin/" "${USER_BIN_DIR}/"
chmod +x -R "${USER_BIN_DIR}/"

echo "Restating the lamp services using the lamp command"
"${USER_BIN_DIR}/lamp" restart
