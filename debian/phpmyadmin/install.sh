#
#
#

LAMP_PMA_LANG="${LAMP_CONFIG_PMA_LANG:-}"
[ -z "$LAMP_PMA_LANG" ] && LAMP_PMA_LANG="$(echo "$LANG" | awk -F'_' '{print $1}')"
[ -z "$LAMP_PMA_LANG" ] && LAMP_PMA_LANG="en"

LAMP_PMA_CRON_UPGRADE="${LAMP_CONFIG_PMA_CRON_UPGRADE:-monthly}"

rm -f /etc/cron.{hourly,daily,weekly,monthly}/phpmyadmin.sh
if [ "${LAMP_PMA_CRON_UPGRADE}" != "disabled" ]
then
  if ! in_array "${LAMP_PMA_CRON_UPGRADE}" hourly daily weekly monthly; then
    LAMP_PMA_CRON_UPGRADE=monthly
  fi
  cp -f "${LAMP_DISTRO_PATH}/phpmyadmin/phpmyadmin.sh" "/etc/cron.${LAMP_PMA_CRON_UPGRADE}/phpmyadmin.sh"
  chmod +x "/etc/cron.${LAMP_PMA_CRON_UPGRADE}/phpmyadmin.sh"
fi

chmod +x "${LAMP_DISTRO_PATH}/phpmyadmin/phpmyadmin.sh"
if [[ ! -d /var/www/html/phpmyadmin ]]; then
  console_log "${LAMP_INCLUDE_NAME}" "Installing phpMyAdmin"
  PMA_PASSWORD="$(tr -dc "A-Za-z0-9" < /dev/urandom | head -c 16)"
  bash "${LAMP_DISTRO_PATH}/phpmyadmin/phpmyadmin.sh"
  (
    echo "CREATE DATABASE IF NOT EXISTS phpmyadmin DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;"
    echo "DROP USER IF EXISTS 'pma'@'localhost';"
    echo -n "GRANT SELECT, INSERT, UPDATE, DELETE, ALTER ON phpmyadmin.* TO 'pma'@'localhost'"
    echo " IDENTIFIED VIA mysql_native_password USING PASSWORD('${PMA_PASSWORD}');"
    echo "FLUSH PRIVILEGES;"
  ) | mariadb
  mariadb < /var/www/html/phpmyadmin/sql/create_tables.sql
  cp -f "${LAMP_DISTRO_PATH}/phpmyadmin/config.inc.php" /var/www/html/phpmyadmin/config.inc.php
  sed -i "s/PMA_PASSWORD/${PMA_PASSWORD}/" /var/www/html/phpmyadmin/config.inc.php
else
  console_log "${LAMP_INCLUDE_NAME}" "Upgrading phpMyAdmin"
  bash "${LAMP_DISTRO_PATH}/phpmyadmin/phpmyadmin.sh"
fi

sed -i "s/PMA_LANG/${LAMP_PMA_LANG}/" /var/www/html/phpmyadmin/config.inc.php
