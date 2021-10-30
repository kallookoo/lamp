#
#
#

LAMP_PHP_VERSION="${LAMP_CONFIG_PHP_VERSION:-}"
if ! echo "$LAMP_PHP_VERSION" | grep -qwE '[0-9\.]+'; then
  LAMP_PHP_VERSION=`apt-cache show php-fpm | grep -m1 -oEw 'php[0-9\.]+' | sed 's/php//'`
fi

LAMP_PHP_PACKAGES=(
  "php${LAMP_PHP_VERSION}-fpm"
  "php${LAMP_PHP_VERSION}-bz2"
  "php${LAMP_PHP_VERSION}-curl"
  "php${LAMP_PHP_VERSION}-gd"
  "php${LAMP_PHP_VERSION}-mbstring"
  "php${LAMP_PHP_VERSION}-mysql"
  "php${LAMP_PHP_VERSION}-zip"
  "php${LAMP_PHP_VERSION}-xml"
  "php${LAMP_PHP_VERSION}-imagick"
  "php${LAMP_PHP_VERSION}-xdebug"
)

LAMP_PHP_VERSIONS=(
  8.0
  7.4
)

for PHP_VERSION in "${LAMP_PHP_VERSIONS[@]}"; do
  if echo "$PHP_VERSION" | grep -qwE '[0-9\.]+'; then
    for PHP_PACKAGE in "${LAMP_PHP_PACKAGES[@]}"; do
      PHP_PACKAGE=`echo $PHP_PACKAGE | sed "s/php$LAMP_PHP_VERSION\-/php$PHP_VERSION-/"`
      if ! in_array "$PHP_PACKAGE" ${LAMP_PHP_PACKAGES[@]}; then
        LAMP_PHP_PACKAGES+=("$PHP_PACKAGE")
      fi
    done
  fi
done; unset PHP_VERSION PHP_PACKAGE

apt_install php-pear ${LAMP_PHP_PACKAGES[@]}

phpdismod -s cli xdebug
PHP_CURL_CERT="$(ls /etc/ssl/certs/ | grep -m1 mkcert)"
TIME_ZONE=`timedatectl | awk -F: '/zone/{print $2}' | awk '{print $1}'`
for PHP_VERSION in $(ls /etc/php); do
    if [[ -d "/etc/php/$PHP_VERSION/fpm" ]]; then
      rsync -azh "${LAMP_DISTRO_PATH}/php/fpm/" "/etc/php/$PHP_VERSION/fpm/"
      if [[ -f "/usr/lib/php/$PHP_VERSION/php.ini-development" ]]; then
        cp -f "/usr/lib/php/$PHP_VERSION/php.ini-development" "/etc/php/$PHP_VERSION/fpm/php.ini"
      fi
      if [[ -f "/etc/php/$PHP_VERSION/fpm/conf.d/95-php.ini" ]]; then
        # sed -i "s@mkcert.*@${PHP_CURL_CERT}@" "/etc/php/$PHP_VERSION/fpm/conf.d/95-php.ini"
        sed -i "s@TIME_ZONE@${TIME_ZONE}@" "/etc/php/$PHP_VERSION/fpm/conf.d/95-php.ini"
      fi

      if [[ -f "/etc/php/$PHP_VERSION/fpm/pool.d/www.conf" ]]; then
        cp -f "/etc/php/$PHP_VERSION/fpm/pool.d/www.conf" "/etc/php/$PHP_VERSION/fpm/pool.d/user.conf"
        sed -i "s@\[www@[user@" "/etc/php/$PHP_VERSION/fpm/pool.d/user.conf"
        sed -i "s@^user.*@user = $SUDO_USER@" "/etc/php/$PHP_VERSION/fpm/pool.d/user.conf"
        sed -i "s@^group@; group@" "/etc/php/$PHP_VERSION/fpm/pool.d/user.conf"
        sed -i 's@fpm.sock@fpm-user.sock@' "/etc/php/$PHP_VERSION/fpm/pool.d/user.conf"
      fi
      if [[ -f "/etc/php/$PHP_VERSION/fpm/php-fpm.conf" ]]; then
        sed -i 's@^error_log.*@error_log = /var/log/php-fpm.log@' "/etc/php/$PHP_VERSION/fpm/php-fpm.conf"
      fi
    fi
done; unset PHP_VERSION PHP_CURL_CERT

find /lib/systemd/system/ -name "php*-fpm*" -exec basename {} \; | xargs systemctl restart
mkdir -p /var/www/html
echo "<?php phpinfo();" > /var/www/html/info.php