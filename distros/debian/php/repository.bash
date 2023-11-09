#
# Declare the PHP Repository
#

if [[ ! -f /etc/apt/sources.list.d/php.list ]]; then
  wget -q https://packages.sury.org/php/apt.gpg -O /etc/apt/trusted.gpg.d/php.gpg
  echo "deb https://packages.sury.org/php/ $LAMP_DISTRO_CODENAME main" >/etc/apt/sources.list.d/php.list
fi
