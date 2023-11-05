#
# Lamp command Installer
#

mkdir -p /usr/local/bin
if [ -f /usr/local/bin/lamp ]; then
  console_log "${LAMP_INCLUDE_NAME}" "Upgrading lamp binary"
else
  console_log "${LAMP_INCLUDE_NAME}" "Installing lamp binary"
fi

cp -f "$LAMP_DISTRO_PATH/bin/lamp" /usr/local/bin/lamp
chmod +x /usr/local/bin/lamp

sed -i "s@VIRTUALHOSTS_DIR@$LAMP_VIRTUALHOSTS_DIRECTORY@" /usr/local/bin/lamp
sed -i "s@LAMP_TLD@$LAMP_TLD@g" /usr/local/bin/lamp
sed -i "s@PHP_VERSION@$LAMP_PHP_VERSION@" /usr/local/bin/lamp
