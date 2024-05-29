#
# Lamp command Installer
#

if [ -f /usr/local/bin/lamp ]; then
  console_log "Upgrading lamp binary"
else
  console_log "Installing lamp binary"
  mkdir -p /usr/local/bin
fi

cp -f "$LAMP_DISTRO_PATH/bin/lamp" /usr/local/bin/lamp
chmod +x /usr/local/bin/lamp

sed -i "s@__VIRTUALHOSTS_DIRECTORY__@$LAMP_VIRTUALHOSTS_DIRECTORY@g" /usr/local/bin/lamp
sed -i "s/__TLD__/$LAMP_TLD/g" /usr/local/bin/lamp
sed -i "s/__PHP_VERSION__/$LAMP_PHP_VERSION/g" /usr/local/bin/lamp
