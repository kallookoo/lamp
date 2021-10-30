#
#
#

LAMP_PMA_LANG="${LAMP_CONFIG_PMA_LANG:-}"
[ -z "$LAMP_PMA_LANG" ] && LAMP_PMA_LANG=`echo $LANG | awk -F'_' '{print $1}'`
[ -z "$LAMP_PMA_LANG" ] && LAMP_PMA_LANG=en

cp -f "${LAMP_DISTRO_PATH}/phpmyadmin/phpmyadmin.sh" /etc/cron.monthly/phpmyadmin.sh
sed -i "s/PMA_LANG/${LAMP_PMA_LANG}/" /etc/cron.monthly/phpmyadmin.sh
chmod +x /etc/cron.monthly/phpmyadmin.sh
if [[ ! -d /var/www/html/phpmyadmin ]]; then
  echo "Installing phpMyAdmin"
  PMA_PASSWORD=`pwgen -svB 16 1`
  bash /etc/cron.monthly/phpmyadmin.sh
  (
    echo "CREATE DATABASE IF NOT EXISTS phpmyadmin DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;"
    echo "DROP USER IF EXISTS 'pma'@'localhost';"
    echo -n "GRANT SELECT, INSERT, UPDATE, DELETE, ALTER ON phpmyadmin.* TO 'pma'@'localhost'"
    echo " IDENTIFIED VIA mysql_native_password USING PASSWORD('${PMA_PASSWORD}');"
    echo "FLUSH PRIVILEGES;"
  ) | mysql
  mysql < /var/www/html/phpmyadmin/sql/create_tables.sql
  rm -rf /var/www/html/phpmyadmin/sql
  cp -f "${LAMP_DISTRO_PATH}/phpmyadmin/config.inc.php" /var/www/html/phpmyadmin/config.inc.php
  sed -i "s/PMA_PASSWORD/${PMA_PASSWORD}/" /var/www/html/phpmyadmin/config.inc.php
else
  echo "Updating phpMyAdmin"
  bash /etc/cron.monthly/phpmyadmin.sh
fi