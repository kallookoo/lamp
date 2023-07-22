#
#
#

LAMP_PHP_VERSION="${LAMP_CONFIG_PHP_VERSION:-}"
if ! [[ $LAMP_PHP_VERSION =~ ^[0-9]\.[0-9]$ ]]
then
  LAMP_PHP_VERSION="$(apt-cache show php-fpm | grep -m1 -oEw 'php[0-9].*' | sed -E 's/[^0-9\.]+//g')"
fi

LAMP_PHP_PACKAGES=(
  "php${LAMP_PHP_VERSION}-fpm"
  # EXTENSIONS
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

if [[ ${#LAMP_CONFIG_PHP_EXTENSIONS} -gt 0 ]]
then
  for PHP_PACKAGE in "${LAMP_CONFIG_PHP_EXTENSIONS[@]}"
  do
    PHP_PACKAGE="$(echo "${PHP_PACKAGE}" | sed -E 's/^php([0-9\.]+)-//')"
    if ! [[ "$PHP_PACKAGE" =~ ^php- ]]
    then
      PHP_PACKAGE="php${LAMP_PHP_VERSION}-${PHP_PACKAGE}"
    fi

    if ! in_array "$PHP_PACKAGE" "${LAMP_PHP_PACKAGES[@]}"
    then
      LAMP_PHP_PACKAGES+=("$PHP_PACKAGE")
    fi
  done
fi

for PHP_VERSION in "7.4" "8.0" "8.1" "8.2"
do
  for PHP_PACKAGE in "${LAMP_PHP_PACKAGES[@]}"
  do
    PHP_PACKAGE="${PHP_PACKAGE/$LAMP_PHP_VERSION/$PHP_VERSION}"
    if ! in_array "$PHP_PACKAGE" "${LAMP_PHP_PACKAGES[@]}"
    then
      LAMP_PHP_PACKAGES+=("$PHP_PACKAGE")
    fi
  done
done

apt_install php-pear "${LAMP_PHP_PACKAGES[@]}"

phpdismod -s cli xdebug

mkdir -p /etc/ssl
curl -s https://curl.se/ca/cacert.pem -o /etc/ssl/cacert.pem
find /etc/ssl/certs/ -name "*mkcert*" -exec cat {} \; >> /etc/ssl/cacert.pem

TIME_ZONE=$(timedatectl | awk -F: '/zone/{print $2}' | awk '{print $1}')
for PHP_VERSION in /etc/php/*
do
  PHP_VERSION="$(basename "${PHP_VERSION}")"
  if [[ -d "/etc/php/${PHP_VERSION}/fpm" ]]
  then
    rsync -azh "${LAMP_DISTRO_PATH}/php/fpm/" "/etc/php/${PHP_VERSION}/fpm/"
    if [[ -f "/usr/lib/php/${PHP_VERSION}/php.ini-development" ]]
    then
      cp -f "/usr/lib/php/${PHP_VERSION}/php.ini-development" "/etc/php/${PHP_VERSION}/fpm/php.ini"
    fi
    if [[ -f "/etc/php/${PHP_VERSION}/fpm/conf.d/95-php.ini" ]]
    then
      sed -i "s@TIME_ZONE@${TIME_ZONE}@" "/etc/php/${PHP_VERSION}/fpm/conf.d/95-php.ini"
    fi

    if [[ -f "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf" ]]
    then
      cp -f "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf" "/etc/php/${PHP_VERSION}/fpm/pool.d/user.conf"
      sed -i "s@\[www@[user@" "/etc/php/${PHP_VERSION}/fpm/pool.d/user.conf"
      sed -i "s@^user.*@user = $SUDO_USER@" "/etc/php/${PHP_VERSION}/fpm/pool.d/user.conf"
      sed -i "s@^group@; group@" "/etc/php/${PHP_VERSION}/fpm/pool.d/user.conf"
      sed -i 's@fpm.sock@fpm-user.sock@' "/etc/php/${PHP_VERSION}/fpm/pool.d/user.conf"
    fi
    if [[ -f "/etc/php/${PHP_VERSION}/fpm/php-fpm.conf" ]]
    then
      sed -i 's@^error_log.*@error_log = /var/log/php-fpm.log@' "/etc/php/${PHP_VERSION}/fpm/php-fpm.conf"
    fi
  fi
done

find /lib/systemd/system/ -name "php*-fpm*" -exec sh -c 'basename "$1" | xargs -r systemctl restart' \;
mkdir -p /var/www/html
cp -f "${LAMP_DISTRO_PATH}/php/info.php" /var/www/html/info.php
