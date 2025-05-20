#
# Declare the MariaDB Repository
#
LAMP_MARIADB_VERSION="${LAMP_CONFIG_MARIADB_VERSION:-11}"
if [[ "$LAMP_MARIADB_VERSION" =~ ^[0-9]+$ ]]; then
  LAMP_MARIADB_VERSION="${LAMP_MARIADB_VERSION}.rolling"
fi

# Remove the old keyring
rm -f /etc/apt/trusted.gpg.d/mariadb.gpg
if [[ "${LAMP_MARIADB_VERSION}" =~ ^[0-9]+(\.rolling|[0-9\.]+)$ ]]; then
  mkdir -p /etc/apt/keyrings
  if download https://mariadb.org/mariadb_release_signing_key.pgp /etc/apt/keyrings/mariadb-keyring.pgp; then
    LAMP_MARIADB_REPO_URL="https://mirror.mariadb.org/repo/$LAMP_MARIADB_VERSION/$LAMP_DISTRO"
    if [[ "$(curl -sI "$LAMP_MARIADB_REPO_URL/dists/$LAMP_DISTRO_CODENAME/" | awk '/^HTTP/{print $2}')" -eq "200" ]]; then
      find /etc/apt/sources.list.d -type f -name "mariadb*" -delete
      echo "deb [signed-by=/etc/apt/keyrings/mariadb-keyring.pgp] https://deb.mariadb.org/$LAMP_MARIADB_VERSION/$LAMP_DISTRO $LAMP_DISTRO_CODENAME main" >"/etc/apt/sources.list.d/mariadb-$LAMP_MARIADB_VERSION.list"
    else
      console_log "Missing MariaDB $LAMP_MARIADB_VERSION version for \"$LAMP_DISTRO_CODENAME\" in https://mariadb.org"
      console_log "The OS or current version will be used"
    fi
  else
    console_log "Could not obtain keyring"
  fi
else
  console_log "The defined version not is numeric"
fi
