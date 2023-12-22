#
# Apache Installer
#

apt_install apache2
systemctl stop apache2

a2enmod -q \
  deflate \
  expires \
  filter \
  headers \
  http2 \
  include \
  proxy_fcgi \
  proxy_http \
  proxy_wstunnel \
  rewrite \
  setenvif \
  ssl

cp -f "$LAMP_DISTRO_PATH/apache/apache2.conf" /etc/apache2/apache2.conf
find /var/log/apache2 /etc/apache2/conf-enabled -mindepth 1 -delete
find /etc/apache2/sites-enabled /etc/apache2/sites-available -mindepth 1 -name "*default*" -delete
sed -i "s@__VIRTUALHOSTS_DIRECTORY__@$LAMP_VIRTUALHOSTS_DIRECTORY@g" /etc/apache2/apache2.conf
sed -i "s/__PHP_VERSION__/$LAMP_PHP_VERSION/g" /etc/apache2/apache2.conf
sed -i "s/__DEFAULT_DOMAIN__/$LAMP_FQDN/g" /etc/apache2/apache2.conf

LAMP_APACHE_ENABLE_MMAP="Off"
if boolval "${LAMP_CONFIG_APACHE_ENABLE_MMAP:-no}"; then
  LAMP_APACHE_ENABLE_MMAP="On"
fi
sed -i "s/^EnableMMAP.*/EnableMMAP $LAMP_APACHE_ENABLE_MMAP/" /etc/apache2/apache2.conf

LAMP_APACHE_ENABLE_SENDFILE="Off"
if boolval "${LAMP_CONFIG_APACHE_ENABLE_SENDFILE:-no}"; then
  LAMP_APACHE_ENABLE_SENDFILE="On"
fi
sed -i "s/^EnableSendfile.*/EnableSendfile $LAMP_APACHE_ENABLE_SENDFILE/" /etc/apache2/apache2.conf

if boolval "${LAMP_CONFIG_APACHE_ENABLE_H5BP:-yes}"; then
  bash "$LAMP_PATH/extras/h5bp-update" >/dev/null 2>&1
  cp -f "$LAMP_DISTRO_PATH/apache/h5bp.conf" /etc/apache2/h5bp.conf
  rsync -azh --delete "$LAMP_DISTRO_PATH/apache/h5bp/" /etc/apache2/h5bp/
else
  rm -rf /etc/apache2/h5bp.conf /etc/apache2/h5bp
fi

systemctl start apache2

add_firewall_rule 80/tcp
add_firewall_rule 443/tcp
