#
# Global Functions
#

# Usage: in_array string ${array[@]}
function in_array() {
  if [ $# -gt 2 ] && [ "$(printf '%s\n' "${@}" | grep -cx -- "$1")" -gt "1" ]
  then
    return 0
  fi
  return 1
}

function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function github_download_url() {
  wget -q -O- "https://api.github.com/repos/$1/releases/latest" | grep -m 1 "browser_download_url.*$2" | cut -d '"' -f 4
}

function include() {
  local name="$1"

  if [ -f "$LAMP_DISTRO_PATH/$name.sh" ]
  then
    source "$LAMP_DISTRO_PATH/$name.sh"
  elif [ -f "$LAMP_DISTRO_PATH/$name/install.sh" ]
  then
    source "$LAMP_DISTRO_PATH/$name/install.sh"
  elif [ "repositories" != "$name" ]
  then
    if [ "$LAMP_DISTRO" == "ubuntu" ]
    then
      LAMP_DISTRO="debian"
      LAMP_DISTRO_PATH="$LAMP_PATH/$LAMP_DISTRO"

      include "$name"

      LAMP_DISTRO="ubuntu"
      LAMP_DISTRO_PATH="$LAMP_PATH/$LAMP_DISTRO"
    fi
  fi
}

function get_distro() {
  awk -F'=' '/^ID/{print $2}' /etc/os-release 2>/dev/null
}

function get_distro_id() {
  awk -F'=' '/VERSION_ID/{gsub("\"","",$2);print $2}' /etc/os-release 2>/dev/null
}

function get_distro_codename() {
  awk -F'=' '/VERSION_CODENAME/{print $2}' /etc/os-release 2>/dev/null
}

function boolval() {
  echo "$1" | grep -qiP '^(0|y(es)?|on|true)$'
}

LAMP_HEADER=""
function console_log() {
  if [[ $# -gt 1 ]]
  then
    local header="$1"
    shift
    header="[ $( echo "$header" | tr '[:lower:]' '[:upper:]' ) ]"

    if [ "$LAMP_HEADER" == "$header" ]
    then
      printf "* %s\n" "${@}"
    else
      LAMP_HEADER="$header"
      printf "\n%s\n* %s\n" "$header" "${@}"
    fi
  fi
}
