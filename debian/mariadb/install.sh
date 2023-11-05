#
#
#

apt_install mariadb-server
cp -f "${LAMP_DISTRO_PATH}/mariadb/90-custom.cnf" /etc/mysql/mariadb.conf.d/90-custom.cnf
systemctl restart mariadb
(
  echo "DROP DATABASE IF EXISTS test;"
  echo "DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
  echo "DELETE FROM mysql.global_priv WHERE User='';"
  echo "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
  echo -n "UPDATE mysql.global_priv SET priv=json_set(priv, '$.plugin', 'mysql_native_password', '$.authentication_string', PASSWORD('root'),"
  echo " '$.auth_or', json_array(json_object(), json_object('plugin', 'unix_socket'))) WHERE User='root';"
  echo " FLUSH PRIVILEGES;"
) | mariadb
