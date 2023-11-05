#
# REPOSITORIES
#

LAMP_MARIADB_VERSION="${LAMP_CONFIG_MARIADB_VERSION:-11.1}"
LAMP_MARIADB_REPO_URL="https://archive.mariadb.org/mariadb-${LAMP_MARIADB_VERSION}/repo/${LAMP_DISTRO}"
find /etc/apt/sources.list.d -type f -name "mariadb*" -delete
if [ ! -f "/etc/apt/sources.list.d/mariadb-${LAMP_MARIADB_VERSION}.list" ]
then
  if ! curl -sIL "${LAMP_MARIADB_REPO_URL}/dists/${LAMP_DISTRO_CODENAME}/" | grep -q "200 Found"
  then
    console_log "${LAMP_INCLUDE_NAME}" "Missing MariaDB ${LAMP_MARIADB_VERSION} version for \"${LAMP_DISTRO_CODENAME}\" in https://mariadb.org"
    console_log "${LAMP_INCLUDE_NAME}" "The OS version will be used"
  else
    find /etc/apt/sources.list.d -type f -name "mariadb*" -delete
    wget -q -O- https://mariadb.org/mariadb_release_signing_key.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/mariadb.gpg
    echo "deb ${LAMP_MARIADB_REPO_URL} $LAMP_DISTRO_CODENAME main" > "/etc/apt/sources.list.d/mariadb-${LAMP_MARIADB_VERSION}.list"
  fi
fi
