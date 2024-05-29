#
# Declare the MariaDB Repository
#

LAMP_MARIADB_VERSION="${LAMP_CONFIG_MARIADB_VERSION:-11.3}"
if [[ "${LAMP_MARIADB_VERSION}" =~ ^[0-9\.]+$ ]]; then
  LAMP_MARIADB_REPO_URL="https://mirror.mariadb.org/repo/$LAMP_MARIADB_VERSION/$LAMP_DISTRO"
  if [[ -f /etc/apt/trusted.gpg.d/mariadb.gpg ]]; then
    rm -rf /etc/apt/trusted.gpg.d/mariadb.gpg
    mkdir -p /etc/apt/keyrings
    curl -s -o /etc/apt/keyrings/mariadb-keyring.pgp 'https://mariadb.org/mariadb_release_signing_key.pgp'
  fi
  if [ ! -f "/etc/apt/sources.list.d/mariadb-$LAMP_MARIADB_VERSION.list" ]; then
    if curl -sIL --fail "$LAMP_MARIADB_REPO_URL/dists/$LAMP_DISTRO_CODENAME/" >/dev/null 2>&1; then
      find /etc/apt/sources.list.d -type f -name "mariadb*" -delete
      echo "deb [signed-by=/etc/apt/keyrings/mariadb-keyring.pgp] https://deb.mariadb.org/$LAMP_MARIADB_VERSION/$LAMP_DISTRO $LAMP_DISTRO_CODENAME main" >"/etc/apt/sources.list.d/mariadb-$LAMP_MARIADB_VERSION.list"
    else
      console_log "Missing MariaDB $LAMP_MARIADB_VERSION version for \"$LAMP_DISTRO_CODENAME\" in https://mariadb.org"
      console_log "The OS version will be used"
    fi
  fi
else
  console_log "The defined version not is numeric"
fi
