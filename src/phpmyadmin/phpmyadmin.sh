#!/bin/bash

(
  VERSION="$(curl -sSL https://raw.githubusercontent.com/phpmyadmin/phpmyadmin/STABLE/ChangeLog | grep -oE '[0-9.]+ \([0-9]+' | grep -oE '[0-9.]+' | head -1)"
  NAME="phpMyAdmin-${VERSION}-all-languages"
  TO_CLEAN=1; [ -d "/var/www/html/phpmyadmin" ] && TO_CLEAN=0
  if [[ ! -f "/var/www/html/phpmyadmin/RELEASE-DATE-${VERSION}" ]]; then
    (
      curl -sSL "https://files.phpmyadmin.net/phpMyAdmin/${VERSION}/${NAME}.tar.xz" -o "/tmp/${NAME}.tar.xz"
      tar -xf "/tmp/${NAME}.tar.xz" --directory /tmp/
      rsync -aqz --delete --exclude 'config.inc.php' "/tmp/${NAME}/" /var/www/html/phpmyadmin/
      rm -rf /tmp/php*
      rm -rf /var/www/html/phpmyadmin/{doc,setup,examples}
      rm -rf /var/www/html/phpmyadmin/themes/{metro,original}
      find /var/www/html/phpmyadmin/locale/ -mindepth 1 -maxdepth 1 -type d ! -name PMA_LANG -exec rm -rf {} \;
      [ $TO_CLEAN -eq 0 ] && rm -rf /var/www/html/phpmyadmin/sql
    ) || exit 1
  fi
) || exit 1
exit 0
