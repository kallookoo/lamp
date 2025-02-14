#
# phpMyAdmin Installer
#

LAMP_PMA_LANG="${LAMP_CONFIG_PMA_LANG:-}"
if [[ -z "$LAMP_PMA_LANG" ]]; then
  LAMP_PMA_LANG="$(echo "$LANG" | awk -F'_' '{print $1}')"
fi
if [[ -z "$LAMP_PMA_LANG" ]]; then
  LAMP_PMA_LANG="en"
fi

LAMP_PMA_CRON_UPGRADE="${LAMP_CONFIG_PMA_CRON_UPGRADE:-monthly}"

rm -f /etc/cron.{hourly,daily,weekly,monthly}/phpmyadmin{.sh,}
if [ "$LAMP_PMA_CRON_UPGRADE" != "disabled" ]; then
  if ! in_array "$LAMP_PMA_CRON_UPGRADE" hourly daily weekly monthly; then
    LAMP_PMA_CRON_UPGRADE=monthly
  fi
  cp -f "$LAMP_DISTRO_PATH/phpmyadmin/phpmyadmin" "/etc/cron.$LAMP_PMA_CRON_UPGRADE/phpmyadmin"
  chmod +x "/etc/cron.$LAMP_PMA_CRON_UPGRADE/phpmyadmin"
fi

chmod +x "$LAMP_DISTRO_PATH/phpmyadmin/phpmyadmin"
if [[ ! -d /var/www/html/phpmyadmin ]]; then
  console_log "Installing phpMyAdmin"
else
  console_log "Upgrading phpMyAdmin"
fi

# Always create the tables to avoid missing.
PMA_PASSWORD="$(tr -dc "A-Za-z0-9" </dev/urandom | head -c 16)"
bash "$LAMP_DISTRO_PATH/phpmyadmin/phpmyadmin"
mariadb </var/www/html/phpmyadmin/sql/create_tables.sql
(
  echo "DROP USER IF EXISTS 'pma'@'localhost';"
  echo -n "GRANT SELECT, INSERT, UPDATE, DELETE, ALTER ON phpmyadmin.* TO 'pma'@'localhost'"
  echo " IDENTIFIED VIA mysql_native_password USING PASSWORD('${PMA_PASSWORD}');"
  echo "FLUSH PRIVILEGES;"
) | mariadb

# Always create the config.inc.php to ensure updates are applied.
cp -f "$LAMP_DISTRO_PATH/phpmyadmin/config.inc.php" /var/www/html/phpmyadmin/config.inc.php
sed -i "s/__PMA_PASSWORD__/$PMA_PASSWORD/" /var/www/html/phpmyadmin/config.inc.php
sed -i "s/__PMA_LANG__/$LAMP_PMA_LANG/" /var/www/html/phpmyadmin/config.inc.php

if ! boolval "${LAMP_CONFIG_PMA_ENABLE_CONFIGURATIONS:-yes}"; then
  rm -f /var/www/html/phpmyadmin/config.inc.lamp.php
elif [[ -f "$LAMP_PATH/config/config.inc.lamp.php" ]]; then
  # Always create the config.inc.lamp.php to ensure updates are applied.
  cp -f "$LAMP_PATH/config/config.inc.lamp.php" /var/www/html/phpmyadmin/config.inc.lamp.php
fi
