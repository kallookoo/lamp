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
  run_in_c apt-cache "$@"
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

if apt update 2>&1 | grep -q "upgradable"; then
  apt -y full-upgrade
fi
