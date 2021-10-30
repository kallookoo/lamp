#
#
#

function pkg_exists() {
  [ `dpkg --dry-run -l $1 2>/dev/null | egrep '^ii' | wc -l` -gt 0 ] && return 0
  return 1
}

function apt_install() {
  echo "Check and install packages"
  while [[ $# -gt 0 ]]; do pkg_exists $1 || apt install -y $1; shift; done
}

function apt_remove() {
  echo "Check and uninstall packages"
  while [[ $# -gt 0 ]]; do pkg_exists $1 && apt purge --autoremove -y $1; shift; done
}

function add_firewall_rule() {
  cmd_exists ufw || return 1
  if ! ufw status verbose | grep -qw "$1"; then
    ufw allow $1
  fi
}

echo "Installing basic packages"
apt_install curl wget pwgen apt-transport-https rsync ca-certificates libnss3-tools ghostscript dirmngr
