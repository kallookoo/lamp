#shellcheck disable=SC2154

#
#
#

function pkg_exists() {
  [ `dpkg --dry-run -l $1 2>/dev/null | egrep '^ii' | wc -l` -gt 0 ] && return 0
  return 1
}

function apt_install() {
  console_log "${LAMP_INCLUDE_NAME}" "Check and install packages"
  while [[ $# -gt 0 ]]; do pkg_exists $1 || apt install -y $1; shift; done
}

function apt_remove() {
  console_log "${LAMP_INCLUDE_NAME}" "Check and uninstall packages"
  while [[ $# -gt 0 ]]; do pkg_exists $1 && apt purge --autoremove -y $1; shift; done
}

function add_firewall_rule() {
  command_exists ufw || return 1
  if ! ufw status verbose | grep -qw "$1"; then
    ufw allow "$1"
  fi
}

console_log "${LAMP_INCLUDE_NAME}" "Installing basic packages"
apt_install curl wget pwgen apt-transport-https rsync ca-certificates libnss3-tools ghostscript dirmngr
