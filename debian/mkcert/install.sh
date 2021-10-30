#
#
#

cp -f "$LAMP_PATH/$LAMP_DISTRO/mkcert/mkcert" /usr/local/bin/mkcert
chmod +x /usr/local/bin/mkcert
mkcert upgrade
mkcert create $LAMP_FQDN