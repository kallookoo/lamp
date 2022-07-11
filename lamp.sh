#!/usr/bin/env bash

if [ `id -u` -ne 0 ]; then
  echo "This script must be run as root, please run this script again with the root user or sudo."
  exit 1
fi

LAMP_PATH="$(cd -P -- `dirname -- $0` && pwd -P)"

if [ -f /etc/os-release ]; then
  LAMP_DISTRO=`awk -F'[= "]' '/^ID/{print $2}' /etc/os-release`
  LAMP_CODENAME=`awk -F'[= "]' '/VERSION_CODENAME/{print $2}' /etc/os-release`
fi

if [ -z "$LAMP_DISTRO" ] || [ ! -d "$LAMP_PATH/$LAMP_DISTRO" ]; then
  echo "Unsupported distro"
  exit 1
fi
LAMP_DISTRO_PATH="$LAMP_PATH/$LAMP_DISTRO"

# Usage: in_array string ${array[@]}
function in_array() {
  [ `printf '%s\n' "${@}" | grep -cx -- "${1}"` -gt 1 ] && return 0
  return 1
}

function is_true() {
  echo $1 | grep -qiE "^y(es)?|0|true" && return 0
  return 1
}

function cmd_exists() {
  command -v $1 >/dev/null 2>&1
  return $?
}

function github_download_url() {
  wget -q -O- "https://api.github.com/repos/${1}/releases/latest" | grep -m 1 "browser_download_url.*${2}" | cut -d '"' -f 4
}

function include() {
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

if [[ -f "$LAMP_PATH/config.sh" ]]; then
  . "$LAMP_PATH/config.sh"
fi

LAMP_FQDN=`hostname -f`
[ -n "$LAMP_CONFIG_FQDN" ] && LAMP_FQDN="$LAMP_CONFIG_FQDN"
LAMP_FQDN_EXPANDED=( $(echo $LAMP_FQDN | tr '.' ' ') )
if [[ ${#LAMP_FQDN_EXPANDED[@]} -lt 2 ]]; then
  echo "Invalid FQDN, declare the LAMP_CONFIG_FQDN option with the valid domain or configure the valid FQDN in the OS."
  exit 1
elif [[ ${#LAMP_FQDN_EXPANDED[@]} -gt 2 ]]; then
  echo "The FQDN is a subdomain and you are not allowed to use it."
  echo "It will be subtracted to continue with the installation."
  LAMP_FQDN=`echo ${LAMP_FQDN_EXPANDED[@]} | awk '{print $(NF-1),$NF}' | tr ' ' '.'`
  echo "Now the FQDN for lamp is: $LAMP_FQDN"
fi

LAMP_TLD=`echo $LAMP_FQDN | awk -F'.' '{print $2}'`
if [[ -n "${LAMP_CONFIG_TLD:-}" ]] && [[ "$LAMP_TLD" != "$LAMP_CONFIG_TLD" ]]; then
  echo "The LAMP_CONFIG_TLD and the current TLD they do not match, the one defined in the LAM_CONFIG_TLD option will be used"
  LAMP_TLD="$LAMP_CONFIG_TLD"
  LAMP_FQDN=`echo $LAMP_FQDN | awk -F'.' '{print $1}'`
  LAMP_FQDN="$LAMP_FQDN.$LAMP_TLD"
  echo "Now the FQDN for lamp only is: $LAMP_FQDN"
fi

if [[ "$LAMP_TLD" != "localhost" ]]; then
  LAMP_IP_ADDRESS=( $(hostname -I) )
  if [[ -n "$LAMP_CONFIG_IP_ADDRESS" ]]; then
    LAMP_IP_ADDRESS=( "$LAMP_CONFIG_IP_ADDRESS" )
  fi
  if [[ "${#LAMP_IP_ADDRESS[@]}" -lt 1 ]]; then
    echo "Missing IP, declare the LAMP_CONFIG_IP_ADDRESS option to select the correct IP"
    exit 1
  elif [[ ${#LAMP_IP_ADDRESS[@]} -ne 1 ]]; then
    echo "Multiples IP's detected, declare the LAMP_CONFIG_IP_ADDRESS option to select the correct IP"
    echo "Use one of the following ips: ${LAMP_IP_ADDRESS[@]}"
    exit 1
  fi
  LAMP_IP_ADDRESS="${LAMP_IP_ADDRESS[0]}"
  if ! echo "${LAMP_IP_ADDRESS}" | grep -Eq '^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})$'; then
    echo "Invalid IP Address, only support IP v4"
		exit 1
	fi
fi

# shellcheck disable=SC2034
LAMP_ARCH="$(uname -r | awk -F'-' '{print $(NF)}')"

include system
include mkcert
include repositories
include php
include apache
include mariadb
include phpmyadmin
include mailhog
include bind
include bin
