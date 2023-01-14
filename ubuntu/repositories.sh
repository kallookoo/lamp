#
#
#

LAMP_CODENAME="$(get_codename)"

apt_install software-properties-common

PPA_REPOSITORIES=( "ondrej/apache2" "ondrej/php" )
for PPA_REPOSITORY in "${PPA_REPOSITORIES[@]}"; do
  if ! grep -q "^deb.*${PPA_REPOSITORY}" /etc/apt/sources.list.d/*.list &>/dev/null; then
    add-apt-repository -y --no-update "ppa:${PPA_REPOSITORY}" &>/dev/null
  fi
done

LAMP_MARIADB_VERSION="${LAMP_CONFIG_MARIADB_VERSION:-10.10}"
if [ ! -f "/etc/apt/sources.list.d/mariadb-${LAMP_MARIADB_VERSION}.list" ]; then
  curl -sI "https://archive.mariadb.org/mariadb-${LAMP_MARIADB_VERSION}" | grep -q "200 Found"
  if [[ $? -eq 0 ]]; then
    echo "Invalid MariaDB ${LAMP_MARIADB_VERSION} version"
    exit 1
  fi

  find /etc/apt/sources.list.d -type f -name "mariadb*" -delete
  wget -q -O- https://mariadb.org/mariadb_release_signing_key.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/mariadb.gpg
  (
    echo "deb https://archive.mariadb.org/mariadb-${LAMP_MARIADB_VERSION}/repo/ubuntu $LAMP_CODENAME main"
  ) | tee "/etc/apt/sources.list.d/mariadb-${LAMP_MARIADB_VERSION}.list" &>/dev/null
fi

#shellcheck disable=SC2154
console_log "${LAMP_INCLUDE_NAME}" "Check and upgrade packages"
LANG=; apt update 2>&1 | grep -q "packages can be upgraded" && apt -y full-upgrade
