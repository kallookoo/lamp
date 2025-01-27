#!/usr/bin/env bash

# This script is used to customize a VM with the following configurations:
# - Ensure the sudo package is installed and add a user to the sudo group
# - Disable the GRUB timeout to boot the system faster
# - Configure a static IP address for a specific interface
#
# Usage: bash vm-customize.sh or curl -sL https://raw.githubusercontent.com/username/repo/main/extras/vm-customize.sh | bash

if [[ "$(id -u)" -ne "0" ]]; then
  echo "This script must be run as root, please run this script again with the root user."
  exit 1
fi

function ask_question() {
  local response
  read -rp "$1 (y/n): " response
  [[ "$response" =~ ^[Yy]$ ]]
}

function question() {
  local response
  read -rp "$1: " response
  echo "$response"
}

function validate_ip() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

function ensure_sudo_installed() {
  local username
  if ! command -v sudo >/dev/null 2>&1; then
    apt install -y sudo
    username="$(question "Enter the username to add to the sudo group")"
    usermod -aG sudo "$username"
  fi
}

function disable_grub_timeout() {
  grep -qE '^GRUB_TIMEOUT=0' /etc/default/grub || return 1

  if ask_question "Do you want to disable the GRUB timeout?"; then
    sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub && update-grub
  fi
}

function configure_static_ip() {
  local iface ip_address network_mask gateway

  if ! ask_question "Do you want to set a static IP?"; then
    echo "Skipping the static IP configuration."
    return 1
  fi

  iface="$(question "Enter the interface name")"
  if [[ ! "$iface" =~ ^[a-z0-9]+$ ]]; then
    echo "The interface name must be a string with lowercase letters and numbers."
    echo "Skipping the static IP configuration."
    return 1
  fi

  if grep -qE "^iface $iface inet static" /etc/network/interfaces; then
    echo "The interface $iface is already configured with a static IP."
    echo "Skipping the static IP configuration."
    return 1
  fi

  ip_address="$(question "Enter the IP address")"
  network_mask="$(question "Enter the network mask")"
  gateway="$(question "Enter the gateway")"

  if ! validate_ip "$ip_address" || ! validate_ip "$network_mask" || ! validate_ip "$gateway"; then
    echo "The IP address, network mask, and gateway must be in the format X.X.X.X."
    echo "Skipping the static IP configuration."
    return 1
  fi

  sed -i "s/^iface $iface inet dhcp/#iface $iface inet dhcp/" /etc/network/interfaces
  cat <<EOF >>/etc/network/interfaces
iface $iface inet static
  address $ip_address
  netmask $network_mask
  gateway $gateway
EOF

  echo "The static IP configuration has been applied."
}

ensure_sudo_installed
disable_grub_timeout
configure_static_ip

ask_question "Do you want to reboot now?" && reboot
