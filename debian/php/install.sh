# shellcheck disable=SC2148

#
#
#

LAMP_PHP_VERSION="${LAMP_CONFIG_PHP_VERSION:-}"
if ! echo "$LAMP_PHP_VERSION" | grep -qwE '[0-9\.]+'; then
  LAMP_PHP_VERSION=$(apt-cache show php-fpm | grep -m1 -oEw 'php[0-9\.]+' | sed 's/php//')
fi

LAMP_PHP_PACKAGES=(
  "php${LAMP_PHP_VERSION}-fpm"

  "php${LAMP_PHP_VERSION}-bz2"
  "php${LAMP_PHP_VERSION}-curl"
  "php${LAMP_PHP_VERSION}-gd"
  "php${LAMP_PHP_VERSION}-igbinary"
  "php${LAMP_PHP_VERSION}-imagick"
  "php${LAMP_PHP_VERSION}-intl"
  "php${LAMP_PHP_VERSION}-mbstring"
  "php${LAMP_PHP_VERSION}-memcache"
  "php${LAMP_PHP_VERSION}-memcached"
  "php${LAMP_PHP_VERSION}-msgpack"
  "php${LAMP_PHP_VERSION}-mysql"
  "php${LAMP_PHP_VERSION}-soap"
  "php${LAMP_PHP_VERSION}-xdebug"
  "php${LAMP_PHP_VERSION}-xml"
  "php${LAMP_PHP_VERSION}-zip"
)

LAMP_PHP_VERSIONS=(
  "8.1"
  "8.0"
  "7.4"
)

for PHP_VERSION in "${LAMP_PHP_VERSIONS[@]}"; do
  if echo "$PHP_VERSION" | grep -qwE '[0-9\.]+'; then
    for PHP_PACKAGE in "${LAMP_PHP_PACKAGES[@]}"; do
      PHP_PACKAGE="${PHP_PACKAGE//$LAMP_PHP_VERSION/$PHP_VERSION}"
      if ! in_array "$PHP_PACKAGE" "${LAMP_PHP_PACKAGES[@]}"; then
        LAMP_PHP_PACKAGES+=("$PHP_PACKAGE")
      fi
    done
  fi
done

apt_install php-pear "${LAMP_PHP_PACKAGES[@]}"

phpdismod -s cli xdebug

mkdir -p /etc/ssl
curl -s https://curl.se/ca/cacert.pem -o /etc/ssl/cacert.pem
find /etc/ssl/certs/ -name "*mkcert*" -exec cat {} \; >> /etc/ssl/cacert.pem

TIME_ZONE=$(timedatectl | awk -F: '/zone/{print $2}' | awk '{print $1}')
for PHP_VERSION in /etc/php/*; do
  PHP_VERSION="${PHP_VERSION:9}"
    if [[ -d "/etc/php/${PHP_VERSION}/fpm" ]]; then
      rsync -azh "${LAMP_DISTRO_PATH}/php/fpm/" "/etc/php/${PHP_VERSION}/fpm/"
      if [[ -f "/usr/lib/php/${PHP_VERSION}/php.ini-development" ]]; then
        cp -f "/usr/lib/php/${PHP_VERSION}/php.ini-development" "/etc/php/${PHP_VERSION}/fpm/php.ini"
      fi
      if [[ -f "/etc/php/${PHP_VERSION}/fpm/conf.d/95-php.ini" ]]; then
        sed -i "s@TIME_ZONE@${TIME_ZONE}@" "/etc/php/${PHP_VERSION}/fpm/conf.d/95-php.ini"
      fi

      if [[ -f "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf" ]]; then
        cp -f "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf" "/etc/php/${PHP_VERSION}/fpm/pool.d/user.conf"
        sed -i "s@\[www@[user@" "/etc/php/${PHP_VERSION}/fpm/pool.d/user.conf"
        sed -i "s@^user.*@user = $SUDO_USER@" "/etc/php/${PHP_VERSION}/fpm/pool.d/user.conf"
        sed -i "s@^group@; group@" "/etc/php/${PHP_VERSION}/fpm/pool.d/user.conf"
        sed -i 's@fpm.sock@fpm-user.sock@' "/etc/php/${PHP_VERSION}/fpm/pool.d/user.conf"
      fi
      if [[ -f "/etc/php/${PHP_VERSION}/fpm/php-fpm.conf" ]]; then
        sed -i 's@^error_log.*@error_log = /var/log/php-fpm.log@' "/etc/php/${PHP_VERSION}/fpm/php-fpm.conf"
      fi
    fi
done

find /lib/systemd/system/ -name "php*-fpm*" -exec sh -c 'basename "$1" | xargs -r systemctl restart' \;
mkdir -p /var/www/html
echo "<?php phpinfo();" > /var/www/html/info.php
