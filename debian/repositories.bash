#
# Enabled the non-free and contrib repositories
#

if ! grep 'non-free' /etc/apt/sources.list | grep -qv 'cdrom'; then
  sudo sed -i 's/ main/ main non-free/' /etc/apt/sources.list
  if [[ "$LAMP_DISTRO_ID" -gt "11" ]]; then
    sudo sed -i 's/ non-free/ non-free non-free-firmware/' /etc/apt/sources.list
  fi
fi

if ! grep 'contrib' /etc/apt/sources.list | grep -qv 'cdrom'; then
  sudo sed -i 's/ main/ main contrib/' /etc/apt/sources.list
fi
