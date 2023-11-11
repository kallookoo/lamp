#
# PHP Installer
#

function get_php_available_versions() {
  LANG="" apt-cache policy php*-fpm |
    grep -P -A 2 'php[^\-]+\-fpm' |
    grep -P -B 2 'Candidate: [^\(]+' |
    grep -oP 'php[^\-]+\-fpm' |
    sort |
    grep -oP '[0-9\.]+' |
    xargs -r printf '%s '
}

make_array LAMP_PHP_AVAILABLE_VERSIONS "$(get_php_available_versions)"

function get_php_versions() {
  LANG="" apt-cache policy php*-fpm |
    grep -oP 'php[^\-]+\-fpm' |
    sort |
    grep -oP '[0-9\.]+' |
    xargs -r printf '%s '
}

make_array LAMP_PHP_ALL_VERSIONS "$(get_php_versions)"

LAMP_PHP_VERSION="${LAMP_CONFIG_PHP_VERSION:-}"
if ! in_array "$LAMP_PHP_VERSION" "${LAMP_PHP_AVAILABLE_VERSIONS[@]}"; then
  LAMP_PHP_VERSION="$(apt-cache show php-fpm | grep -m1 -oEw 'php[0-9].*' | sed -E 's/[^0-9\.]+//g')"
  console_log "$LAMP_INCLUDE_NAME" "There is no PHP version, the system default version will be used."
fi

LAMP_PHP_PACKAGES_TEMPLATE=(
  "php__VERSION__-fpm"
  # EXTENSIONS
  "php__VERSION__-bz2"
  "php__VERSION__-curl"
  "php__VERSION__-gd"
  "php__VERSION__-igbinary"
  "php__VERSION__-imagick"
  "php__VERSION__-intl"
  "php__VERSION__-mbstring"
  "php__VERSION__-memcache"
  "php__VERSION__-memcached"
  "php__VERSION__-msgpack"
  "php__VERSION__-mysql"
  "php__VERSION__-soap"
  "php__VERSION__-xdebug"
  "php__VERSION__-xml"
  "php__VERSION__-zip"
)
LAMP_PHP_PACKAGES=()

LAMP_PHP_VERSIONS=()
if [[ ${#LAMP_CONFIG_PHP_VERSIONS[@]} -gt 0 ]]; then
  make_array LAMP_PHP_VERSIONS "${LAMP_CONFIG_PHP_VERSIONS[@]}"
  for i in "${!LAMP_PHP_VERSIONS[@]}"; do
    if ! in_array "${LAMP_PHP_VERSIONS[i]}" "${LAMP_PHP_AVAILABLE_VERSIONS[@]}"; then
      console_log "$LAMP_INCLUDE_NAME" "The ${LAMP_PHP_VERSIONS[i]} not is available."
      unset 'LAMP_PHP_VERSIONS[i]'
    fi
  done
fi
LAMP_PHP_VERSIONS+=("$LAMP_PHP_VERSION")

for PHP_VERSION in "${LAMP_PHP_VERSIONS[@]}"; do
  for PHP_PACKAGE in "${LAMP_PHP_PACKAGES_TEMPLATE[@]}"; do
    PHP_PACKAGE="${PHP_PACKAGE/__VERSION__/$PHP_VERSION}"
    if ! in_array "$PHP_PACKAGE" "${LAMP_PHP_PACKAGES[@]}"; then
      LAMP_PHP_PACKAGES+=("$PHP_PACKAGE")
    fi
  done

  for PHP_PACKAGE in "${LAMP_CONFIG_PHP_EXTENSIONS[@]}"; do
    PHP_PACKAGE="$(sed -E 's/^php([0-9\.]+)-//' <<<"$PHP_PACKAGE")"
    if ! [[ "$PHP_PACKAGE" =~ ^php- ]]; then
      PHP_PACKAGE="php$PHP_VERSION-$PHP_PACKAGE"
    fi
    if ! in_array "$PHP_PACKAGE" "${LAMP_PHP_PACKAGES[@]}"; then
      LAMP_PHP_PACKAGES+=("$PHP_PACKAGE")
    fi
  done

  for i in "${!LAMP_PHP_ALL_VERSIONS[@]}"; do
    if [[ "$PHP_VERSION" == "${LAMP_PHP_ALL_VERSIONS[i]}" ]]; then
      unset 'LAMP_PHP_ALL_VERSIONS[i]'
    fi
  done
done

if boolval "${LAM_CONFIG_PHP_UNINSTALL:-no}"; then
  LAMP_PHP_UNINSTALL_PACKAGES=()
  for PHP_VERSION in "${LAMP_PHP_ALL_VERSIONS[@]}"; do
    for PHP_PACKAGE in "${LAMP_PHP_PACKAGES_TEMPLATE[@]}"; do
      LAMP_PHP_UNINSTALL_PACKAGES+=("${PHP_PACKAGE/__VERSION__/$PHP_VERSION}")
    done
  done

  if [[ ${#LAMP_PHP_UNINSTALL_PACKAGES[@]} -gt 0 ]]; then
    apt_remove "${LAMP_PHP_UNINSTALL_PACKAGES[@]}"
  fi
fi

apt_install php-pear "${LAMP_PHP_PACKAGES[@]}"

phpdismod -s cli xdebug

mkdir -p /etc/ssl
curl -s https://curl.se/ca/cacert.pem -o /etc/ssl/cacert.pem
find /etc/ssl/certs/ -name "*mkcert*" -exec cat {} \; >>/etc/ssl/cacert.pem

TIME_ZONE="$(cat /etc/timezone)"
for PHP_VERSION in "${LAMP_PHP_VERSIONS[@]}"; do
  if [[ -d "/etc/php/$PHP_VERSION/fpm" ]]; then
    rsync -azh "$LAMP_DISTRO_PATH/php/fpm/" "/etc/php/$PHP_VERSION/fpm/"
    if [[ -f "/usr/lib/php/$PHP_VERSION/php.ini-development" ]]; then
      cp -f "/usr/lib/php/$PHP_VERSION/php.ini-development" "/etc/php/$PHP_VERSION/fpm/php.ini"
    fi
    if [[ -f "/etc/php/$PHP_VERSION/fpm/conf.d/95-php.ini" ]]; then
      sed -i "s@__PHP_VERSION__@$PHP_VERSION@" "/etc/php/$PHP_VERSION/fpm/conf.d/95-php.ini"
      sed -i "s@__TIME_ZONE__@$TIME_ZONE@" "/etc/php/$PHP_VERSION/fpm/conf.d/95-php.ini"
    fi

    find "/etc/php/$PHP_VERSION/fpm/conf.d" -name "99XX-php*" -delete
    if [[ -f "$LAMP_PATH/config/99XX-php$PHP_VERSION.ini" ]]; then
      cp -f "$LAMP_PATH/config/99XX-php$PHP_VERSION.ini" "/etc/php/$PHP_VERSION/fpm/conf.d/99XX-php$PHP_VERSION.ini"
    elif [[ -f "$LAMP_PATH/config/99XX-php.ini" ]]; then
      cp -f "$LAMP_PATH/config/99XX-php.ini" "/etc/php/$PHP_VERSION/fpm/conf.d/99XX-php.ini"
    fi

    if [[ -f "/etc/php/$PHP_VERSION/fpm/pool.d/www.conf" ]]; then
      cp -f "/etc/php/$PHP_VERSION/fpm/pool.d/www.conf" "/etc/php/$PHP_VERSION/fpm/pool.d/user.conf"
      sed -i "s@\[www@[user@" "/etc/php/$PHP_VERSION/fpm/pool.d/user.conf"
      sed -i "s@^user.*@user = $SUDO_USER@" "/etc/php/$PHP_VERSION/fpm/pool.d/user.conf"
      sed -i "s@^group@; group@" "/etc/php/$PHP_VERSION/fpm/pool.d/user.conf"
      sed -i 's@fpm.sock@fpm-user.sock@' "/etc/php/$PHP_VERSION/fpm/pool.d/user.conf"
    fi
    if [[ -f "/etc/php/$PHP_VERSION/fpm/php-fpm.conf" ]]; then
      sed -i "s@^error_log.*@error_log = /var/log/php$PHP_VERSION-fpm.log@" "/etc/php/$PHP_VERSION/fpm/php-fpm.conf"
    fi
  fi
done

find /lib/systemd/system/ -name "php*-fpm*" -exec sh -c 'basename "$1" | xargs -r systemctl restart' \;
mkdir -p /var/www/html
cp -f "$LAMP_DISTRO_PATH/php/info.php" /var/www/html/info.php
