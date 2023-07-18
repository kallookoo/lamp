#
#
#

apt_install software-properties-common

function add_ppa_repository() {
  local repo="${1}"
  if ! grep -q "^deb.*${repo}" /etc/apt/sources.list.d/*.list >/dev/null 2>&1; then
    add-apt-repository -y --no-update "ppa:${repo}" >/dev/null 2>&1
  fi
}
