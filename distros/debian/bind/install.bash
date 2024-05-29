#
# Bind9 Installer
#

if [[ "$LAMP_TLD" == "localhost" ]]; then
  apt_install libnss-myhostname
else
  apt_install bind9
  rsync -azh --exclude="install.bash" "$LAMP_DISTRO_PATH/bind/" /etc/bind/
  sed -i "s/__TLD__/$LAMP_TLD/g" /etc/bind/lamp.conf /etc/bind/lamp.conf.zone
  sed -i "s/__LAMP_DNS_SERIAL__/$(date +'%s')/g" /etc/bind/lamp.conf.zone
  sed -i "s/__LAMP_IP_ADDRESS__/$LAMP_IP_ADDRESS/g" /etc/bind/lamp.conf.zone
  if [[ ${#LAMP_CONFIG_BIND_FORWARDERS} -gt 0 ]]; then
    LAMP_BIND_FORWARDERS=""
    for LAMP_BIND_FORWARDER in "${LAMP_CONFIG_BIND_FORWARDERS[@]}"; do
      if echo "$LAMP_BIND_FORWARDER" | grep -qP '^([0-9]{1,3}\.){3}([0-9]{1,3};?)$'; then
        LAMP_BIND_FORWARDERS+="${LAMP_BIND_FORWARDER/;//}; "
      fi
    done
    if [[ -n "$LAMP_BIND_FORWARDERS" ]]; then
      sed -i "s/# __LAMP_BIND_FORWARDERS__/forwarders { $LAMP_BIND_FORWARDERS };/" /etc/bind/named.conf.options
    else
      console_log "The forwarders was not enabled as it did not have a correct format."
    fi
  fi

  if ! grep -q "$LAMP_IP_ADDRESS" /etc/dhcp/dhclient.conf; then
    echo "prepend domain-name-servers $LAMP_IP_ADDRESS;" >>/etc/dhcp/dhclient.conf
  fi

  systemctl restart named
  add_firewall_rule 53
fi
