#!/usr/bin/env bash

if wget -q https://raw.githubusercontent.com/phpmyadmin/phpmyadmin/STABLE/ChangeLog -O /tmp/phpMyAdmin-changelog
then
  PHPMYADMIN_VERSION="$(grep -m1 -oE '[0-9\.]+ \([0-9]{4}' /tmp/phpMyAdmin-changelog | awk '{print $1}')"
  if [[ "${PHPMYADMIN_VERSION}" =~ ^[0-9] ]] && [[ ! -f "/var/www/html/phpmyadmin/RELEASE-DATE-${PHPMYADMIN_VERSION}" ]]
  then
    PHPMYADMIN_TAR_NAME="phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages"
    if wget -q "https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/${PHPMYADMIN_TAR_NAME}.tar.xz" -O "/tmp/${PHPMYADMIN_TAR_NAME}.tar.xz"
    then
      tar -xf "/tmp/${PHPMYADMIN_TAR_NAME}.tar.xz" --directory /tmp/ && \
        rsync -aqz --delete --exclude 'config.inc.php' --exclude 'config.inc.lamp.php' "/tmp/${PHPMYADMIN_TAR_NAME}/" /var/www/html/phpmyadmin/
    fi
  fi
fi
find /tmp -maxdepth 1 -iname "phpmyadmin-*" -exec rm -rf {} \;
exit 0
