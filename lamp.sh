#!/usr/bin/env bash

if [ "$(id -u)" -ne "0" ]; then
  echo "This script must be run as root, please run this script again with the root user or sudo."
  exit 1
fi

LAMP_PATH="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

. "${LAMP_PATH}/functions.sh"

LAMP_DISTRO="$(get_distro)"
if [ -z "$LAMP_DISTRO" ] || [ ! -d "$LAMP_PATH/$LAMP_DISTRO" ]; then
  echo "Unsupported distro"
  exit 1
fi

LAMP_CODENAME="$(get_codename)"
LAMP_DISTRO_PATH="$LAMP_PATH/$LAMP_DISTRO"

if [ -f "$LAMP_PATH/config.sh" ]; then
  . "$LAMP_PATH/config.sh"
fi

LAMP_FQDN="$(hostname -f)"
[ -n "$LAMP_CONFIG_FQDN" ] && LAMP_FQDN="$LAMP_CONFIG_FQDN"

IFS=" " read -r -a LAMP_FQDN_EXPANDED <<< "$(echo "$LAMP_FQDN" | tr '.' ' ')"
if [[ ${#LAMP_FQDN_EXPANDED[@]} -gt 2 ]]; then
  console_log lamp "The FQDN is a subdomain and you are not allowed to use it."
  console_log lamp "It will be subtracted to continue with the installation."
  LAMP_FQDN="$(echo "${LAMP_FQDN_EXPANDED[@]}" | awk '{print $(NF-1),$NF}' | tr ' ' '.')"
  console_log lamp "Now the FQDN for lamp is: $LAMP_FQDN"

elif [[ ${#LAMP_FQDN_EXPANDED[@]} -lt 2 ]]; then
  console_log lamp "Invalid FQDN, declare the LAMP_CONFIG_FQDN option with the valid domain or configure the valid FQDN in the OS."
  exit 1
fi

LAMP_TLD="$(echo "$LAMP_FQDN" | awk -F'.' '{print $2}')"
if [[ -n "${LAMP_CONFIG_TLD:-}" ]] && [[ "$LAMP_TLD" != "$LAMP_CONFIG_TLD" ]]; then
  console_log lamp  "The LAMP_CONFIG_TLD and the current TLD they do not match, the one defined in the LAM_CONFIG_TLD option will be used"
  LAMP_TLD="$LAMP_CONFIG_TLD"
  LAMP_FQDN="$(echo "$LAMP_FQDN" | awk -F'.' '{print $1}').$LAMP_TLD"
  console_log lamp  "Now the FQDN for lamp only is: $LAMP_FQDN"
fi

console_log lamp "The FQDN for lamp is: $LAMP_FQDN"

if [[ "$LAMP_TLD" == "localhost" ]]; then
  console_log lamp "The IP for lamp is: 127.0.0.1"
else
  if [[ -n "$LAMP_CONFIG_IP_ADDRESS" ]]; then
    LAMP_IP_ADDRESSES=( "$LAMP_CONFIG_IP_ADDRESS" )
  else
    IFS=" " read -r -a LAMP_IP_ADDRESSES <<< "$(hostname -I)"
  fi
  if [[ "${#LAMP_IP_ADDRESSES[@]}" -lt 1 ]]; then
    console_log lamp  "Missing IP, declare the LAMP_CONFIG_IP_ADDRESS option to select the correct IP"
    exit 1
  elif [[ ${#LAMP_IP_ADDRESSES[@]} -ne 1 ]]; then
    console_log lamp "Multiples IP's detected, declare the LAMP_CONFIG_IP_ADDRESS option to select the correct IP"
    console_log lamp "$(printf "Use one of the following ips: %s\n" "${LAMP_IP_ADDRESSES[@]}")"
    exit 1
  fi
  LAMP_IP_ADDRESS="${LAMP_IP_ADDRESSES[0]}"
  if ! echo "${LAMP_IP_ADDRESS}" | grep -Eq '^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})$'; then
    console_log lamp  "Invalid IP Address, only support IP v4"
		exit 1
	fi

  console_log lamp "The IP for lamp is: $LAMP_IP_ADDRESS"
fi

console_log lamp "The Public IP for lamp is: $(wget -q -O - ipinfo.io/ip)"

LAMP_INCLUDE_NAMES=(
  system
  mkcert
  repositories
  memcached
  php
  apache
  mariadb
  phpmyadmin
  mailhog
  bind
  bin
)

for LAMP_INCLUDE_NAME in "${LAMP_INCLUDE_NAMES[@]}"; do
  include "${LAMP_INCLUDE_NAME}"
done
