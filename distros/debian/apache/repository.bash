#
# Declare the Apache Repository
#

if ! package_exists debsuryorg-archive-keyring; then
  download https://packages.sury.org/debsuryorg-archive-keyring.deb /tmp/debsuryorg-archive-keyring.deb &&
    dpkg -i /tmp/debsuryorg-archive-keyring.deb
fi

echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-apache2.gpg] https://packages.sury.org/apache2/ $LAMP_DISTRO_CODENAME main" >/etc/apt/sources.list.d/apache2.list
