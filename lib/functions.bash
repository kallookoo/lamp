#
# Global Functions
#

function in_array() {
  if [[ $# -gt 2 ]] && [[ "$(printf '%s\n' "$@" | grep -cx -- "$1")" -gt "1" ]]; then
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
  local distro="$LAMP_DISTRO"

  if [ -f "$LAMP_DISTRO_PATH/$name.bash" ]; then
    source "$LAMP_DISTRO_PATH/$name.bash"
  elif [ -f "$LAMP_DISTRO_PATH/$name/uninstall.bash" ]; then
    source "$LAMP_DISTRO_PATH/$name/uninstall.bash"
  elif [ -f "$LAMP_DISTRO_PATH/$name/install.bash" ]; then
    source "$LAMP_DISTRO_PATH/$name/install.bash"
  elif [ "repositories" != "$name" ]; then
    case "$LAMP_DISTRO" in
    ubuntu)
      LAMP_DISTRO="debian"
      LAMP_DISTRO_PATH="$LAMP_PATH/distros/$LAMP_DISTRO"
      ;;
    esac

    if [[ "$distro" != "$LAMP_DISTRO" ]]; then
      include "$name"
      LAMP_DISTRO="$distro"
      LAMP_DISTRO_PATH="$LAMP_PATH/distros/$LAMP_DISTRO"
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
  if [[ $# -gt 1 ]]; then
    local header="${1^^}"
    shift
    if [ "$LAMP_HEADER" != "$header" ]; then
      LAMP_HEADER="$header"
      printf "\n[ %s ]\n" "$LAMP_HEADER"
    fi
    printf "* %s\n" "$@"
  fi
}

function make_array() {
  local name="$1"
  shift
  # shellcheck disable=SC2229
  IFS=" " read -r -a "$name" <<<"$(printf '%s\n' "$@" | awk '!u[$0]++' | xargs -r printf '%s ')"
}

function question() {
  if boolval "${LAMP_CONFIG_AUTO_UNINSTALL:-no}"; then
    return 0
  fi
  while [[ -z "$LAMP_CONFIG_AUTO_UNINSTALL" ]]; do
    read -r -p "$(console_log "$LAMP_INCLUDE_NAME" "$@") [y/n]: " answer
    case $answer in
    [Yy]*)
      return 0
      ;;
    [Nn]*)
      return 1
      ;;
    esac
  done
  return 1
}
