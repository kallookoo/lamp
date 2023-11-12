#
# Global Functions for debian base systems and install requeriments.
#

function package_exists() {
  if [[ "$(dpkg --dry-run -l "$1" 2>/dev/null | grep -Ec '^ii')" -gt "0" ]]; then
    return 0
  fi
  return 1
}

function apt_install() {
  console_log "$LAMP_INCLUDE_NAME" "Checking and Installing dependencies if not already installed"
  while [[ $# -gt 0 ]]; do
    if ! package_exists "$1"; then
      apt install -y "$1"
    fi
    shift
  done
}

function apt_remove() {
  console_log "$LAMP_INCLUDE_NAME" "Checking and Uninstalling dependencies if already installed"
  while [[ $# -gt 0 ]]; do
    if package_exists "$1"; then
      apt purge --autoremove -y "$1"
    fi
    shift
  done
}

function apt_cache() {
  LANG="" apt-cache "$@"
}

function add_firewall_rule() {
  if command_exists ufw && ! ufw status verbose | grep -qw "$1"; then
    ufw allow "$1"
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

console_log "$LAMP_INCLUDE_NAME" "Checking and Full Upgrading system after including the new repositories"

(
  LANG=
  if apt-get update | grep -q "packages can be upgraded"; then
    apt -y full-upgrade
  fi
)
