#
# mkcert Installer
#

cp -f "$LAMP_DISTRO_PATH/mkcert/mkcert" /usr/local/bin/mkcert
chmod +x /usr/local/bin/mkcert
console_log "$(mkcert upgrade)"
console_log "$(mkcert create "$LAMP_FQDN")"
