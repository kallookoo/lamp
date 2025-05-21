#
# Global Functions for debian base systems and install requeriments.
#

function package_exists() {
  if apt_cache policy "$1" | grep -q 'Installed: (none)'; then
    return 1
  fi
  return 0
}

function apt_install() {
  console_log "Checking and Installing dependencies if not already installed"
  while [[ $# -gt 0 ]]; do
    if ! package_exists "$1"; then
      apt install -y "$1"
    fi
    shift
  done
  # Always run the fix broken.
  apt install -f >/dev/null 2>&1
}

function apt_remove() {
  console_log "Checking and Uninstalling dependencies if already installed"
  while [[ $# -gt 0 ]]; do
    if package_exists "$1"; then
      apt purge --autoremove -y "$1"
    fi
    shift
  done
}

function apt_cache() {
  LC_MESSAGES=C apt-cache "$@"
}

function debsuryorg_config() {
  local keyring pkg="$1"
  # Check download the debsuryorg-archive-keyring.deb package
  if [[ ! -f /tmp/debsuryorg-archive-keyring.deb || $(($(date +%s) - $(stat -c %Y /tmp/debsuryorg-archive-keyring.deb))) -gt 3600 ]]; then
    rm -f /tmp/debsuryorg-archive-keyring.deb
    if ! download https://packages.sury.org/debsuryorg-archive-keyring.deb /tmp/debsuryorg-archive-keyring.deb; then
      console_log "Failed to download debsuryorg-archive-keyring.deb"
      return 1
    fi
    if ! dpkg -i /tmp/debsuryorg-archive-keyring.deb; then
      console_log "Failed to install debsuryorg-archive-keyring.deb"
      return 1
    fi
  fi

  keyring="$(find / -type f -name debsuryorg-archive-keyring.gpg -print -quit)"
  if [[ -z "$keyring" ]]; then
    console_log "Failed to find debsuryorg-archive-keyring.gpg"
    return 1
  fi
  echo "deb [signed-by=$keyring] https://packages.sury.org/$pkg/ $LAMP_DISTRO_CODENAME main" >"/etc/apt/sources.list.d/$pkg.list"
  return 0
}

function add_firewall_rule() {
  if ! command_exists ufw; then
    console_log "Skipping adding rules, because not exits the ufw command"
  elif ufw status | grep -q 'inactive'; then
    console_log "Skipping adding rules, because the ufw is disabled"
  elif ! ufw status verbose | grep -qw "$1"; then
    ufw allow "$1" 2>&1 | while read -r line; do
      console_log "$line"
    done
    unset line
  fi
}

apt_install \
  curl \
  wget \
  apt-transport-https \
  rsync \
  ca-certificates \
  libnss3-tools \
  ghostscript \
  dirmngr

include "repositories"
for package in "$LAMP_DISTRO_PATH/"*; do
  if [[ -f "$package/repository.bash" ]]; then
    include "$(basename "$package")/repository"
  fi
done

console_log "Checking and Full Upgrading system after including the new repositories"

if LC_MESSAGES=C apt update 2>&1 | grep -q "upgradable"; then
  apt -y full-upgrade
fi
