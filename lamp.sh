#!/usr/bin/env bash

if [[ $(id -u) -ne 0 ]]
then
  echo "This script must be run as root, please run this script again with the root user or sudo."
  exit 1
fi

LAMP_PATH="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

[ -f "$LAMP_PATH/config.sh" ] && source "$LAMP_PATH/config.sh"
source "${LAMP_PATH}/functions.sh"

LAMP_DISTRO="$(get_distro)"
if [ -z "$LAMP_DISTRO" ] || [ ! -d "$LAMP_PATH/$LAMP_DISTRO" ]
then
  echo "Unsupported distro"
  exit 1
fi

LAMP_DISTRO_CODENAME="$(get_distro_codename)"
if [ -z "$LAMP_DISTRO_CODENAME" ]
then
  echo "Missing distro codename"
  exit 1
fi

LAMP_DISTRO_ID="$(get_distro_id)"
if [ -z "$LAMP_DISTRO_ID" ]
then
  echo "Missing distro ID"
  exit 1
fi

LAMP_DISTRO_PATH="$LAMP_PATH/$LAMP_DISTRO"

if [[ -n "$LAMP_CONFIG_FQDN" ]]
then
  LAMP_FQDN="${LAMP_CONFIG_FQDN}"
else
  LAMP_FQDN="$(hostname -f)"
fi

IFS=" " read -r -a LAMP_FQDN_EXPANDED <<< "$(echo "$LAMP_FQDN" | tr '.' ' ')"
if [[ ${#LAMP_FQDN_EXPANDED[@]} -gt 2 ]]
then
  console_log lamp "The FQDN is a subdomain and you are not allowed to use it."
  console_log lamp "It will be subtracted to continue with the installation."
  LAMP_FQDN="$(echo "${LAMP_FQDN_EXPANDED[@]}" | awk '{print $(NF-1),$NF}' | tr ' ' '.')"
  console_log lamp "Now the FQDN for lamp is: $LAMP_FQDN"

elif [[ ${#LAMP_FQDN_EXPANDED[@]} -lt 2 ]]
then
  console_log lamp "Invalid FQDN, declare the LAMP_CONFIG_FQDN option with the valid domain or configure the valid FQDN in the OS."
  exit 1
fi

LAMP_TLD="$(echo "$LAMP_FQDN" | awk -F'.' '{print $2}')"
if [[ -n "$LAMP_CONFIG_FQDN" ]]
then
  console_log lamp "The FQDN for lamp is: $LAMP_FQDN"
elif [[ -n "${LAMP_CONFIG_TLD:-}" ]] && [[ "$LAMP_TLD" != "$LAMP_CONFIG_TLD" ]]
then
  console_log lamp  "The LAMP_CONFIG_TLD and the current TLD they do not match, the one defined in the LAM_CONFIG_TLD option will be used"
  LAMP_TLD="$LAMP_CONFIG_TLD"
  LAMP_FQDN="$(echo "$LAMP_FQDN" | awk -F'.' '{print $1}').$LAMP_TLD"
  console_log lamp "The FQDN for lamp is: $LAMP_FQDN"
else
  console_log lamp "The FQDN for lamp is: $LAMP_FQDN"
fi

if [[ "$LAMP_TLD" == "localhost" ]]
then
  console_log lamp "The IP for lamp is: 127.0.0.1"
else
  if [[ -n "$LAMP_CONFIG_IP_ADDRESS" ]]
  then
    LAMP_IP_ADDRESSES=( "$LAMP_CONFIG_IP_ADDRESS" )
  else
    IFS=" " read -r -a LAMP_IP_ADDRESSES <<< "$(hostname -I)"
  fi

  if [[ ${#LAMP_IP_ADDRESSES[@]} -gt 1 ]]
  then
    console_log lamp "Multiples IP's detected, find the valid IP"
    for i in "${!LAMP_IP_ADDRESSES[@]}"
    do
      if ! [[ "${LAMP_IP_ADDRESSES[i]}" =~ ^([0-9]{1,3}\.){3}([0-9]{1,3})$ ]]
      then
        unset 'LAMP_IP_ADDRESSES[i]'
      fi
    done
  fi

  if [[ ${#LAMP_IP_ADDRESSES[@]} -lt 1 ]]
  then
    console_log lamp  "Missing IP v4, declare the LAMP_CONFIG_IP_ADDRESS option to select the correct IP"
    exit 1
  fi

  LAMP_IP_ADDRESS="${LAMP_IP_ADDRESSES[0]}"
  console_log lamp "The IP for lamp is: $LAMP_IP_ADDRESS"
fi

console_log lamp "The Public IP for lamp is: $(wget -q -O - https://ipinfo.io/ip)"

LAMP_INCLUDE_NAMES=(
  system
  mkcert
  memcached
  php
  apache
  mariadb
  phpmyadmin
  mailhog
  bind
  bin
)

for LAMP_INCLUDE_NAME in "${LAMP_INCLUDE_NAMES[@]}"
do
  include "${LAMP_INCLUDE_NAME}"
done
