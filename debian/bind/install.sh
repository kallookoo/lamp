#
#
#

if [[ "$LAMP_TLD" == "localhost" ]]; then
  apt_install libnss-myhostname
else
  LAMP_DNS_SERIAL="$( date +'%s' )"

  apt_install bind9
  rsync -azh --exclude="install.sh" "$LAMP_DISTRO_PATH/bind/" /etc/bind/
  sed -i "s/LAMP_TLD/$LAMP_TLD/g" /etc/bind/lamp.conf /etc/bind/lamp.conf.zone
  sed -i "s/LAMP_DNS_SERIAL/$LAMP_DNS_SERIAL/g" /etc/bind/lamp.conf.zone
  sed -i "s/LAMP_IP_ADDRESS/$LAMP_IP_ADDRESS/g" /etc/bind/lamp.conf.zone

  if ! grep -q "$LAMP_IP_ADDRESS" /etc/dhcp/dhclient.conf; then
    echo "prepend domain-name-servers $LAMP_IP_ADDRESS;" >> /etc/dhcp/dhclient.conf
  fi

  systemctl restart named
  add_firewall_rule 53
fi
