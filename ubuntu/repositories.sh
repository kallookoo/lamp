#
#
#

apt_install software-properties-common

PPA_REPOSITORIES=( "ondrej/apache2" "ondrej/php" )
for x in "${PPA_REPOSITORIES[@]}"; do
  if ! grep -q "^deb.*${x}" /etc/apt/sources.list.d/*.list &>/dev/null; then
    add-apt-repository -y --no-update "ppa:${x}" &>/dev/null
  fi
done; unset x

if [ ! -f /etc/apt/sources.list.d/mariadb.list ]; then
  wget -q -O- https://mariadb.org/mariadb_release_signing_key.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/mariadb.gpg
  (
    echo "deb [arch=amd64,i386] http://ams2.mirrors.digitalocean.com/mariadb/repo/10.6/ubuntu $LAMP_CODENAME main"
  ) | tee /etc/apt/sources.list.d/mariadb.list &>/dev/null
fi

echo "Check and upgrade packages"
LANG= apt update 2>&1 | grep -q "packages can be upgraded" && apt -y full-upgrade