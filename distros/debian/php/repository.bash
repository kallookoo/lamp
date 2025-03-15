#
# Declare the PHP Repository
#

if ! package_exists debsuryorg-archive-keyring; then
  download https://packages.sury.org/debsuryorg-archive-keyring.deb /tmp/debsuryorg-archive-keyring.deb &&
    dpkg -i /tmp/debsuryorg-archive-keyring.deb
fi

echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ $LAMP_DISTRO_CODENAME main" >/etc/apt/sources.list.d/php.list
