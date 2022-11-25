#
#
#

# Usage: in_array string ${array[@]}
function in_array() {
  [ "$(printf '%s\n' "${@}" | grep -cx -- "${1}")" -gt "1" ] && return 0
  return 1
}

function is_true() {
  echo "${1}" | grep -qiE "^y(es)?|0|true" && return 0
  return 1
}

function cmd_exists() {
  command -v "${1}" >/dev/null 2>&1
  return $?
}

function github_download_url() {
  wget -q -O- "https://api.github.com/repos/${1}/releases/latest" | grep -m 1 "browser_download_url.*${2}" | cut -d '"' -f 4
}

function include() {
  # shellcheck disable=SC1090
  if [ -f "$LAMP_DISTRO_PATH/$1/install.sh" ]; then
    . "$LAMP_DISTRO_PATH/$1/install.sh"
  elif [ -f "$LAMP_DISTRO_PATH/$1.sh" ]; then
    . "$LAMP_DISTRO_PATH/$1.sh"
  elif [ "repositories" != "$1" ]; then
    if [ "$LAMP_DISTRO" == "ubuntu" ]; then
      LAMP_DISTRO="debian"
      LAMP_DISTRO_PATH="$LAMP_PATH/$LAMP_DISTRO"

      include "$1"

      LAMP_DISTRO="ubuntu"
      LAMP_DISTRO_PATH="$LAMP_PATH/$LAMP_DISTRO"
    fi
  fi
}


function get_distro() {
  [ -f /etc/os-release ] && awk -F'[= "]' '/^ID/{print $2}' /etc/os-release
}


function get_codename() {
  [ -f /etc/os-release ] && awk -F'[= "]' '/VERSION_CODENAME/{print $2}' /etc/os-release
}

function get_arch() {
  uname -r | awk -F'-' '{print $(NF)}'
}

LAMP_HEADER=""
function console_log() {
  local header="${1}"
  shift
  #shellcheck disable=SC2124
  local msg="${@}"

  header="[ $( echo "${header}" | tr '[:lower:]' '[:upper:]' ) ]"

  if [ "${LAMP_HEADER}" != "${header}" ]; then
    LAMP_HEADER="${header}"
    printf "\n%s\n" "${header}"
  fi
  printf "* %s\n" "${msg}"
}
