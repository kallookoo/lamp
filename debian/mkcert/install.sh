#
# mkcert Installer
#

cp -f "$LAMP_PATH/$LAMP_DISTRO/mkcert/mkcert" /usr/local/bin/mkcert
chmod +x /usr/local/bin/mkcert
console_log "${LAMP_INCLUDE_NAME}" "$(mkcert upgrade)"
console_log "${LAMP_INCLUDE_NAME}" "$(mkcert create "$LAMP_FQDN")"
