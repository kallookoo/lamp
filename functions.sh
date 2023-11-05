#
#
#

# Usage: in_array string ${array[@]}
function in_array() {
  [ "$(printf '%s\n' "${@}" | grep -cx -- "${1}")" -gt "1" ] && return 0
  return 1
}

function command_exists() {
  command -v "${1}" >/dev/null 2>&1
  return $?
}

function github_download_url() {
  wget -q -O- "https://api.github.com/repos/${1}/releases/latest" | grep -m 1 "browser_download_url.*${2}" | cut -d '"' -f 4
}

function include() {
  local name="${1}"

  if [ -f "${LAMP_DISTRO_PATH}/${name}.sh" ]
  then
    source "${LAMP_DISTRO_PATH}/${name}.sh"
  elif [ -f "${LAMP_DISTRO_PATH}/${name}/install.sh" ]
  then
    source "${LAMP_DISTRO_PATH}/${name}/install.sh"
  elif [ "repositories" != "${name}" ]
  then
    if [ "$LAMP_DISTRO" == "ubuntu" ]
    then
      LAMP_DISTRO="debian"
      LAMP_DISTRO_PATH="${LAMP_PATH}/${LAMP_DISTRO}"

      include "${name}"

      LAMP_DISTRO="ubuntu"
      LAMP_DISTRO_PATH="${LAMP_PATH}/${LAMP_DISTRO}"
    fi
  fi
}

function get_distro() {
  [ -f /etc/os-release ] && awk -F'=' '/^ID/{print $2}' /etc/os-release
}

function get_distro_id() {
  [ -f /etc/os-release ] && awk -F'=' '/VERSION_ID/{gsub("\"","",$2);print $2}' /etc/os-release
}

function get_distro_codename() {
  [ -f /etc/os-release ] && awk -F'=' '/VERSION_CODENAME/{print $2}' /etc/os-release
}

function is_true() {
  echo "X${1:-}X" | grep -qiP '^X(0|y(es)?)X$' && return 0
  return 1
}

LAMP_HEADER=""
function console_log() {
  if [[ $# -gt 1 ]]
  then
    local header="${1}"
    shift
    header="[ $( echo "${header}" | tr '[:lower:]' '[:upper:]' ) ]"

    if [ "${LAMP_HEADER}" == "${header}" ]
    then
      printf "* %s\n" "${@}"
    else
      LAMP_HEADER="${header}"
      printf "\n%s\n* %s\n" "${header}" "${@}"
    fi
  fi
}
