#
# APT Repository Funcion
#

apt_install software-properties-common

function add_ppa_repository() {
  if [[ -n "$1" ]] && ! grep -q "^deb.*$1" /etc/apt/sources.list.d/*.list >/dev/null 2>&1
  then
    add-apt-repository -y --no-update "ppa:$1" >/dev/null 2>&1
  fi
}
