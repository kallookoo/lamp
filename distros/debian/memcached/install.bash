#
# Memcached Installer
#

apt_install memcached
cp -f "$LAMP_DISTRO_PATH/memcached/memcached.conf" /etc/memcached.conf
systemctl restart memcached
