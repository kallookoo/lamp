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

LAMP_MARIADB_VERSION="${LAMP_CONFIG_MARIADB_VERSION:-10.10}"
if [ ! -f "/etc/apt/sources.list.d/mariadb-${LAMP_MARIADB_VERSION}.list" ]; then
  if curl -sI "https://archive.mariadb.org/mariadb-${LAMP_MARIADB_VERSION}" | grep -q "200 Found"; then
    console_log "${LAMP_INCLUDE_NAME}" "Invalid MariaDB ${LAMP_MARIADB_VERSION} version"
    exit 1
  fi

  find /etc/apt/sources.list.d -type f -name "mariadb*" -delete
  wget -q -O- https://mariadb.org/mariadb_release_signing_key.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/mariadb.gpg
  (
    echo "deb https://archive.mariadb.org/mariadb-${LAMP_MARIADB_VERSION}/repo/debian $LAMP_CODENAME main"
  ) | tee "/etc/apt/sources.list.d/mariadb-${LAMP_MARIADB_VERSION}.list" &>/dev/null
fi

if grep 'non-free' /etc/apt/sources.list | grep -qv 'cdrom'; then
  sed -i 's/main/main non-free/' /etc/apt/sources.list
fi

if grep 'contrib' /etc/apt/sources.list | grep -qv 'cdrom'; then
  sed -i 's/main/main contrib/' /etc/apt/sources.list
fi

console_log "${LAMP_INCLUDE_NAME}" "Check and upgrade packages"
LANG=; apt update 2>&1 | grep -q "packages can be upgraded" && apt -y full-upgrade
