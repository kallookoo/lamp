#
#
#

mkdir -p /usr/local/bin
cp -f "$LAMP_DISTRO_PATH/bin/lamp" /usr/local/bin/lamp
chmod +x /usr/local/bin/lamp

sed -i "s@VIRTUALHOSTS_DIR@$LAMP_VIRTUALHOSTS_DIRECTORY@" /usr/local/bin/lamp
sed -i "s@LAMP_TLD@$LAMP_TLD@g" /usr/local/bin/lamp
sed -i "s@PHP_VERSION@$LAMP_PHP_VERSION@" /usr/local/bin/lamp