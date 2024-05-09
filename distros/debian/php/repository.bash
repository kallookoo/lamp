#
# Declare the PHP Repository
#

if ! package_exists debsuryorg-archive-keyring; then
  curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
  dpkg -i /tmp/debsuryorg-archive-keyring.deb
fi

if [[ ! -f /etc/apt/sources.list.d/php.list ]]; then
  echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $LAMP_DISTRO_CODENAME main" >/etc/apt/sources.list.d/php.list
fi
