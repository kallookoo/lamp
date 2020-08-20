#!/usr/bin/env bash

SETUP_PATH="$(cd `dirname -- $0` && pwd)"
SRC_PATH="${SETUP_PATH}/src"

USER_BIN_DIR="${HOME}/.local/bin"

DEFAULT_DOMAIN="ubuntu.localhost"
USER_APACHE_DIR="${HOME}/Developer/www"
USER_MYSQL_AUTOBACKUP_DIR="${HOME}/Developer/databases"

PMA_LANG=es

MARIADB_VERSION="10.5"

INSTALL_PACKAGES=(
  git
  git-extras
  git-lfs
  subversion
  nodejs
  yarn
  imagemagick
  libnss3-tools # mkcert

  # server
  apache2
  mariadb-server
  postfix
  php7.4-fpm
  php7.4-bz2 # PHAR

  php7.4-curl # phpMyAdmin
  php7.4-gd # phpMyAdmin
  php7.4-mbstring # phpMyAdmin
  php7.4-mysql # phpMyAdmin
  php7.4-zip # phpMyAdmin

  php7.4-xml # PHP_CodeSniffer and WordPress

  php-imagick
  php-pear
  php-php-gettext
  php-xdebug
  ghostscript # Ghostscript is required for rendering PDF previews (WordPress)
)

NODE_LTS="12"

YARN_GLOBAL_PACKAGES_LIST=(
  clean-css-cli
  html-minifier
  js-beautify
  minjson
  svgo
  uglify-js
  uglifycss
)

#
# FUNCTIONS
#

function github_download_url() {
  curl -s "https://api.github.com/repos/${1}/releases/latest" | grep "browser_download_url.*${2}" | cut -d '"' -f 4
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

sudo -p "Sudo session, enter password: " echo -n ""

# REQUIRED PACKAGES
echo "Installing basic packages"
apt_install curl wget pwgen apt-transport-https gnupg rsync lsb-release &>/dev/null

# REPOSITORIES SETUP
CODENAME="$(lsb_release -sc)"
REQUIRE_UPDATE=1

echo "Adding repositories"
PPA_REPOSITORIES=( "git-core/ppa" "ondrej/apache2" "ondrej/php" )
for x in "${PPA_REPOSITORIES[@]}"; do
  grep -q "^deb.*${x}" /etc/apt/sources.list.d/*.list || (
    sudo add-apt-repository -y --no-update "ppa:${x}" &>/dev/null
    REQUIRE_UPDATE=0
  )
done; unset x


if [[ ! -f "/etc/apt/sources.list.d/mariadb-${MARIADB_VERSION}.list" ]]; then
  sudo apt-key adv --fetch-keys "https://mariadb.org/mariadb_release_signing_key.asc"
  (
    echo "deb [arch=amd64,arm64,ppc64el] http://ams2.mirrors.digitalocean.com/mariadb/repo/${MARIADB_VERSION}/ubuntu ${CODENAME} main"
    echo "# deb-src http://ams2.mirrors.digitalocean.com/mariadb/repo/${MARIADB_VERSION}/ubuntu ${CODENAME} main"
  ) | sudo tee "/etc/apt/sources.list.d/mariadb-${MARIADB_VERSION}.list" &>/dev/null
  find /etc/apt/sources.list.d/ -iname "*mariadb*" -not -iname "*mariadb-${MARIADB_VERSION}*"
  REQUIRE_UPDATE=0
fi

if [[ ! -f "/etc/apt/sources.list.d/nodesource-${NODE_LTS}.list" ]]; then
  curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add - &>/dev/null
  (
    echo "deb https://deb.nodesource.com/node_${NODE_LTS}.x ${CODENAME} main"
    echo "# deb-src https://deb.nodesource.com/node_${NODE_LTS}.x ${CODENAME} main"
  ) | sudo tee "/etc/apt/sources.list.d/nodesource-${NODE_LTS}.list" &>/dev/null
  find /etc/apt/sources.list.d/ -iname "*nodesource*" -not -iname "*nodesource-${NODE_LTS}*"
  REQUIRE_UPDATE=0
fi
if [[ ! -f /etc/apt/sources.list.d/yarn.list ]]; then
  curl -s https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - &>/dev/null
  (
    echo "deb https://dl.yarnpkg.com/debian/ stable main"
  ) | sudo tee /etc/apt/sources.list.d/yarn.list &>/dev/null
  REQUIRE_UPDATE=0
fi

[ $REQUIRE_UPDATE -eq 0 ] && (
  echo "Updating system"
  sudo apt update 2>&1 | grep -q "list-upgrade" && sudo apt -y upgrade
)

# INSTALL PACKAGES
echo postfix postfix/main_mailer_type select Internet Site | sudo debconf-set-selections
echo postfix postfix/mailname string ${DEFAULT_DOMAIN} | sudo debconf-set-selections
apt_install ${INSTALL_PACKAGES[@]}

# MKCERT SETUP
echo "Installing mkcert"
if ! cmd_exists mkcert; then
  sudo wget -q `github_download_url "FiloSottile/mkcert" "linux-amd64"` -O "/usr/local/bin/mkcert"
  sudo chmod +x "/usr/local/bin/mkcert"
  mkcert -install
fi

# APACHE SETUP
echo "Installing Apache"
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
sudo find /etc/apache2/conf-enabled ! -type d -delete
sudo find /etc/apache2/sites-enabled ! -type d -name "*default*" -delete
sudo find /etc/apache2/sites-available ! -type d -name "*default*" -delete
[ -f /etc/apache2/apache2.conf.original ] || sudo mv /etc/apache2/apache2.conf{,.original}
sudo cp -f "${SRC_PATH}/apache/apache2.conf" /etc/apache2/apache2.conf
sudo sed -i "s/DEFAULT_DOMAIN/${DEFAULT_DOMAIN}/g" /etc/apache2/apache2.conf
sudo sed -i "s@VIRTUALHOSTS_DIR@${USER_APACHE_DIR}@g" /etc/apache2/apache2.conf
rsync -azh "${SRC_PATH}/apache/bin/" "${USER_BIN_DIR}/"
sed -i "s@DOCUMENTROOT@${USER_APACHE_DIR}@g" "${USER_BIN_DIR}/a2v"
chmod +x -R "${USER_BIN_DIR}/"
a2c -i "${DEFAULT_DOMAIN}"
[ -d "${USER_APACHE_DIR}" ] || mkdir -p "${USER_APACHE_DIR}"
sudo find "${USER_APACHE_DIR}" -type f -exec chmod 644 {} \;
sudo find "${USER_APACHE_DIR}" -type d -exec chmod 755 {} \;
sudo chown -R "$USER:www-data" "${USER_APACHE_DIR}"
sudo chmod g+s "${USER_APACHE_DIR}"

# PHP SETUP
echo "Installing PHP"
(
  echo "<?php phpinfo();"
) | sudo tee /var/www/html/info.php &>/dev/null
sudo phpdismod -s cli xdebug
sudo rsync -azh "${SRC_PATH}/php/7.4/" /etc/php/7.4/
PHP_CURL_CERT="$(ls /etc/ssl/certs/ | grep -m1 mkcert)"
for php_version in $(ls /etc/php); do
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
      if [[ -f "/etc/php/$php_version/fpm/pool.d/user.conf" ]]; then
        sudo sed -i "s/CURRENT_USER/${USER}/" "/etc/php/$php_version/fpm/pool.d/user.conf"
      fi
    fi
done

# MARIADB SETUP
echo "Installing MariaDB"
sudo systemctl restart mariadb
sudo cp -f "${SRC_PATH}/mariadb/conf.d/custom.cnf" /etc/mysql/conf.d/custom.cnf
(
  echo "DROP DATABASE IF EXISTS test;"
  echo "DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
  echo "DELETE FROM mysql.global_priv WHERE User='';"
  echo "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
  echo -n "UPDATE mysql.global_priv SET priv=json_set(priv, '$.plugin', 'mysql_native_password', '$.authentication_string', PASSWORD('root'),"
  echo " '$.auth_or', json_array(json_object(), json_object('plugin', 'unix_socket'))) WHERE User='root';"
  echo " FLUSH PRIVILEGES;"
) | sudo mysql
sudo cp -f "${SRC_PATH}/mariadb/bin/mysql-autobackup" /usr/local/bin/mysql-autobackup
sudo sed -i "s@USER_MYSQL_AUTOBACKUP_DIR@${USER_MYSQL_AUTOBACKUP_DIR}@" /usr/local/bin/mysql-autobackup
sudo chmod +x /usr/local/bin/mysql-autobackup
sudo cp -f "${SRC_PATH}/mariadb/services/mysql-autobackup.service" /lib/systemd/system/mysql-autobackup.service

# PHPMYADMINSETUP
echo "Installing phpMyAdmin"
if [[ ! -d /var/www/html/phpmyadmin ]]; then
  PMA_PASSWORD=`pwgen -svB 16 1`
  sudo cp -f "${SRC_PATH}/phpmyadmin/phpmyadmin.sh" /etc/cron.monthly/phpmyadmin.sh
  sudo sed -i "s/PMA_LANG/${PMA_LANG}/" /etc/cron.monthly/phpmyadmin.sh
  sudo chmod +x /etc/cron.monthly/phpmyadmin.sh
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
fi

# MAILHOG
echo "Installing MailHog"
if ! cmd_exists mhsendmail; then
  sudo wget -q https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64 -O /usr/local/bin/mhsendmail
  sudo chmod +x /usr/local/bin/mhsendmail
fi
if ! cmd_exists mailhog; then
  sudo wget -q https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64 -O /usr/local/bin/mailhog
  sudo chmod +x /usr/local/bin/mailhog
fi
sudo cp -f "${SRC_PATH}/mailhog/mailhog.service" /lib/systemd/system/mailhog.service
sudo sed -i "s/DEFAULT_DOMAIN/${DEFAULT_DOMAIN}/" /lib/systemd/system/mailhog.service

# COMPOSER SETUP
echo "Installing composer"
if ! cmd_exists composer; then
  wget -q `github_download_url "composer/composer" "composer.phar"` -O "${USER_BIN_DIR}/composer"
  chmod +x "${USER_BIN_DIR}/composer"
  if [[ -f "$HOME/.composer/composer.json" ]]; then
    composer global update
  fi
  grep -q "alias com=" "${HOME}/.bashrc" || echo 'alias com="composer"' >> "${HOME}/.bashrc"
fi

# WP CLI SETUP
echo "Installing WP CLI"
if ! cmd_exists wp; then
  wget -q https://raw.github.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O "${USER_BIN_DIR}/wp"
  chmod +x "${USER_BIN_DIR}/wp"
fi

# PHP_CODESNIFFER
echo "Installing PHP_CodeSniffer"
for x in phpcs phpcbf; do
  if ! cmd_exists "${x}"; then
    wget -q https://squizlabs.github.io/PHP_CodeSniffer/${x}.phar -O "${USER_BIN_DIR}/${x}"
    chmod +x "${USER_BIN_DIR}/${x}"
  fi
done; unset x

# PHPMD
echo "Installing PHPMD"
if ! cmd_exists phpmd; then
  wget -q https://phpmd.org/static/latest/phpmd.phar -O "${USER_BIN_DIR}/phpmd"
  chmod +x "${USER_BIN_DIR}/phpmd"
fi

# PHP-CS-FIXER
echo "Installing php-cs-fixer"
if ! cmd_exists php-cs-fixer; then
  wget -q https://cs.symfony.com/download/php-cs-fixer-v2.phar -O "${USER_BIN_DIR}/php-cs-fixer"
  chmod +x "${USER_BIN_DIR}/php-cs-fixer"
fi

# YARN SETUP
echo "Installing Yarn"
if [[ ! -f "$HOME/.yarnrc" ]]; then
  yarn config set prefix "$HOME/.local"
  yarn config set child-concurrency 1
  yarn config set yarn-offline-mirror-pruning true
fi

YARN_INSTALLED="$(yarn global list)"
for x in "${YARN_GLOBAL_PACKAGES_LIST[@]}"; do echo "${YARN_INSTALLED}" | grep -q "${x}" || yarn global add "${x}"; done; unset x

# LAMP SERVICE
echo "Lamp service"
sudo cp -f "${SRC_PATH}/services/lamp.service" /lib/systemd/system/lamp.service

# SERVER SERVICES
echo "Restarting server services"
sudo systemctl daemon-reload
sudo systemctl restart lamp
sudo systemctl disable apache2 mariadb php7.4-fpm postfix mailhog mysql-autobackup &>/dev/null

# APACHE USER
if ! groups | grep -q "www-data"; then
  sudo usermod -aG www-data "${USER}"
  echo "REQUIRED REBOOT THIS SYSTEM"
fi