#
# REPOSITORIES
#

if [ ! -f /etc/apt/sources.list.d/php.list ]; then
  wget -q https://packages.sury.org/php/apt.gpg -O /etc/apt/trusted.gpg.d/php.gpg
  echo "deb https://packages.sury.org/php/ $LAMP_CODENAME main" | tee /etc/apt/sources.list.d/php.list &>/dev/null
fi

if [ ! -f /etc/apt/sources.list.d/apache2.list ]; then
  wget -q https://packages.sury.org/apache2/apt.gpg -O /etc/apt/trusted.gpg.d/apache2.gpg
  echo "deb https://packages.sury.org/apache2/ $LAMP_CODENAME main" | tee /etc/apt/sources.list.d/apache2.list &>/dev/null
fi

if [ ! -f /etc/apt/sources.list.d/mariadb.list ]; then
  wget -q -O- https://mariadb.org/mariadb_release_signing_key.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/mariadb.gpg
  (
    echo "deb [arch=amd64,i386] http://ams2.mirrors.digitalocean.com/mariadb/repo/10.6/debian $LAMP_CODENAME main"
  ) | tee /etc/apt/sources.list.d/mariadb.list &>/dev/null
fi

if [[ -z "$(grep 'non-free' /etc/apt/sources.list | grep -v 'cdrom')" ]]; then
  sed -i 's/main/main non-free/' /etc/apt/sources.list
fi

if [[ -z "$(grep 'contrib' /etc/apt/sources.list | grep -v 'cdrom')" ]]; then
  sed -i 's/main/main contrib/' /etc/apt/sources.list
fi

echo "Check and upgrade packages"
LANG= apt update 2>&1 | grep -q "packages can be upgraded" && apt -y full-upgrade