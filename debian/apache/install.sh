#
#
#

apt_install apache2
systemctl stop apache2

LAMP_VIRTUALHOSTS_DIRECTORY="${LAMP_VIRTUALHOSTS_DIRECTORY:-}"
[ -z "$LAMP_VIRTUALHOSTS_DIRECTORY" ] && LAMP_VIRTUALHOSTS_DIRECTORY="/home/${SUDO_USER}/www/"
LAMP_VIRTUALHOSTS_DIRECTORY="$(echo "$LAMP_VIRTUALHOSTS_DIRECTORY" | sed -e 's@^/@@' -e 's@/$@@')"
if [ ! -d "$LAMP_VIRTUALHOSTS_DIRECTORY" ]; then
  mkdir -p "$LAMP_VIRTUALHOSTS_DIRECTORY"
  chown -R "$SUDO_USER:$SUDO_USER" "$LAMP_VIRTUALHOSTS_DIRECTORY"
fi

LAMP_APACHE_MODULES=(
  deflate
  expires
  filter
  headers
  http2
  include
  proxy_fcgi
  proxy_http
  proxy_wstunnel
  rewrite
  setenvif
  ssl
)
a2enmod -q ${LAMP_APACHE_MODULES[@]}


find /var/log/apache2 /etc/apache2/conf-enabled -mindepth 1 -delete
find /etc/apache2/sites-enabled /etc/apache2/sites-available -mindepth 1 -name "*default*" -delete
rsync -azh --exclude="install.sh"  "${LAMP_DISTRO_PATH}/apache/" /etc/apache2/
sed -i "s@VIRTUALHOSTS_DIR@$LAMP_VIRTUALHOSTS_DIRECTORY@" /etc/apache2/apache2.conf
sed -i "s/PHP_VERSION/$LAMP_PHP_VERSION/" /etc/apache2/apache2.conf
sed -i "s/DEFAULT_DOMAIN/$LAMP_FQDN/" /etc/apache2/apache2.conf

systemctl restart apache2

add_firewall_rule 80/tcp
add_firewall_rule 443/tcp