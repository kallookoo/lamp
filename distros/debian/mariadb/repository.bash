#
# Declare the MariaDB Repository
#

LAMP_MARIADB_VERSION="${LAMP_CONFIG_MARIADB_VERSION:-11.4}"
if [[ "${LAMP_MARIADB_VERSION}" =~ ^[0-9\.]+$ ]]; then
  LAMP_MARIADB_REPO_URL="https://mirror.mariadb.org/repo/$LAMP_MARIADB_VERSION/$LAMP_DISTRO"
  rm -rf /etc/apt/trusted.gpg.d/mariadb.gpg
  mkdir -p /etc/apt/keyrings
  if download https://mariadb.org/mariadb_release_signing_key.pgp /etc/apt/keyrings/mariadb-keyring.pgp; then
    if [ ! -f "/etc/apt/sources.list.d/mariadb-$LAMP_MARIADB_VERSION.list" ]; then
      if download "$LAMP_MARIADB_REPO_URL/dists/$LAMP_DISTRO_CODENAME/" /dev/null; then
        find /etc/apt/sources.list.d -type f -name "mariadb*" -delete
        echo "deb [signed-by=/etc/apt/keyrings/mariadb-keyring.pgp] https://deb.mariadb.org/$LAMP_MARIADB_VERSION/$LAMP_DISTRO $LAMP_DISTRO_CODENAME main" >"/etc/apt/sources.list.d/mariadb-$LAMP_MARIADB_VERSION.list"
      else
        console_log "Missing MariaDB $LAMP_MARIADB_VERSION version for \"$LAMP_DISTRO_CODENAME\" in https://mariadb.org"
        console_log "The OS version will be used"
      fi
    fi
  else
    console_log "Could not obtain keyring"
  fi
else
  console_log "The defined version not is numeric"
fi
