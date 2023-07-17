#
#
#

function package_exists() {
  [ "$(dpkg --dry-run -l "$1" 2>/dev/null | grep -Ec '^ii')" -gt "0" ] && return 0
  return 1
}

function apt_install() {
  console_log "${LAMP_INCLUDE_NAME}" "Installing packages"
  while [[ $# -gt 0 ]]; do package_exists "$1" || apt install -y "$1"; shift; done
}

function apt_remove() {
  console_log "${LAMP_INCLUDE_NAME}" "Uninstalling packages"
  while [[ $# -gt 0 ]]; do package_exists "$1" && apt purge --autoremove -y "$1"; shift; done
}

function add_firewall_rule() {
  if command_exists ufw && ! ufw status verbose | grep -qw "$1"; then
    ufw allow "$1"
  fi
}

console_log "${LAMP_INCLUDE_NAME}" "Installing basic packages"
apt_install curl wget pwgen apt-transport-https rsync ca-certificates libnss3-tools ghostscript dirmngr

include "repositories"
for package in "${LAMP_DISTRO_PATH}/"*
do
  [ -f "$package/repository.sh" ] && include "$(basename "$package")/repository"
done

console_log "${LAMP_INCLUDE_NAME}" "Upgrading system"
( LANG=; apt update 2>&1 | grep -q "packages can be upgraded" && apt -y full-upgrade )
