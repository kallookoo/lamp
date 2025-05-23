#
# coredns installer
#

if [[ "$LAMP_TLD" == "localhost" ]]; then
  apt_install libnss-myhostname
elif [[ ! -f /etc/coredns/Corefile && -n "$(ss -Htuln sport = :53)" ]]; then
  console_log "The port 53 is already in use, skipping the coredns installation."
else

  systemctl stop coredns >/dev/null 2>&1
  mkdir -p /etc/coredns
  if ! getent passwd coredns >/dev/null; then
    adduser --system --disabled-password --disabled-login \
      --home /var/lib/coredns --quiet --force-badname --group coredns
  fi

  if [[ ${#LAMP_CONFIG_DNS_FORWARDERS[@]} -eq 0 && ${#LAMP_CONFIG_BIND_FORWARDERS[@]} -gt 0 ]]; then
    console_log "The LAMP_CONFIG_BIND_FORWARDERS option is deprecated, use LAMP_CONFIG_DNS_FORWARDERS instead."
    LAMP_CONFIG_DNS_FORWARDERS=("${LAMP_CONFIG_BIND_FORWARDERS[@]}")
  fi

  if ! LAMP_COREDNS_API_DATA="$(fetch_github_api https://api.github.com/repos/coredns/coredns/releases/latest)"; then
    console_log "Failed to fetch coredns version"
  else

    if command -v jq >/dev/null 2>&1; then
      LAMP_COREDNS_VERSION=$(echo "$LAMP_COREDNS_API_DATA" | jq -r '.tag_name')
    elif command -v awk >/dev/null 2>&1; then
      LAMP_COREDNS_VERSION=$(echo "$LAMP_COREDNS_API_DATA" | awk -F: '$1 ~ /tag_name/ {gsub(/[^v0-9\.]+/, "", $2) ;print $2; exit}')
    elif command -v sed >/dev/null 2>&1; then
      LAMP_COREDNS_VERSION=$(echo "$LAMP_COREDNS_API_DATA" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
    fi

    if [[ -z "$LAMP_COREDNS_VERSION" ]]; then
      console_log "Failed to obtain coredns version"
    else
      LAMP_COREDNS_INSTALL=true
      if [[ -f /etc/coredns/Corefile ]]; then
        console_log "Updating coredns"
      else
        console_log "Installing coredns"
      fi
      if [ -f /etc/coredns/Corefile ] && grep -q "$LAMP_COREDNS_VERSION" /etc/coredns/Corefile; then
        console_log "Update only the coredns files, the version is already installed."
      else

        LAMP_COREDNS_DOWNLOAD="${LAMP_COREDNS_VERSION}/coredns_${LAMP_COREDNS_VERSION#v}_linux_${LAMP_OS_ARCH}.tgz"
        if ! download "https://github.com/coredns/coredns/releases/download/$LAMP_COREDNS_DOWNLOAD" /etc/coredns/coredns.tgz; then
          console_log "Failed to download coredns"
          LAMP_COREDNS_INSTALL=false
        elif ! tar -C /etc/coredns -xzf /etc/coredns/coredns.tgz; then
          console_log "Failed to extract coredns"
          LAMP_COREDNS_INSTALL=false
        else
          cp -f /etc/coredns/coredns /usr/local/bin/coredns
          chmod +x /usr/local/bin/coredns
        fi
      fi

      if [[ "$LAMP_COREDNS_INSTALL" == true ]]; then
        LAMP_COREDNS_SYSTEMD_FILES=(
          "coredns-log.conf|/etc/logrotate.d"
          "coredns-sysusers.conf|/usr/lib/sysusers.d"
          "coredns-tmpfiles.conf|/usr/lib/tmpfiles.d"
          "coredns.service|/lib/systemd/system"
          "Corefile|/etc/coredns"
        )

        printf "%s\n" "${LAMP_COREDNS_SYSTEMD_FILES[@]}" |
          awk -F'|' -v base_dir="$LAMP_DISTRO_PATH/coredns" '{ name = $1; src = base_dir "/" name; dest = $2 "/" name; system("cp -f " src " " dest) }'

        sed -i "s/# __VERSION__/# $LAMP_COREDNS_VERSION/g" /etc/coredns/Corefile
        sed -i "s/__TLD__/$LAMP_TLD/g" /etc/coredns/Corefile
        sed -i "s/__LAMP_IP_ADDRESS__/$LAMP_IP_ADDRESS/g" /etc/coredns/Corefile

        if [[ ${#LAMP_CONFIG_DNS_FORWARDERS} -gt 0 ]]; then
          LAMP_DNS_FORWARDERS=()
          for LAMP_DNS_FORWARDER in "${LAMP_CONFIG_DNS_FORWARDERS[@]}"; do
            if [[ "$LAMP_DNS_FORWARDER" =~ ^(([0-9]{1,3}\.){3}([0-9]{1,3}))$ ]]; then
              LAMP_DNS_FORWARDERS+=("${BASH_REMATCH[1]}")
            else
              console_log "The forwarder '$LAMP_DNS_FORWARDER' is not a valid IPv4 address."
            fi
          done
          if [[ "${#LAMP_DNS_FORWARDERS[@]}" -gt 0 ]]; then
            sed -i "s/# __LAMP_DNS_FORWARDERS__/forward . ${LAMP_DNS_FORWARDERS[*]}/g" /etc/coredns/Corefile
          else
            console_log "The forwarders was not enabled as it did not have a correct format."
          fi
        fi
        # Required for coredns to work in a OS.
        if ! grep -q "$LAMP_IP_ADDRESS" /etc/dhcp/dhclient.conf; then
          echo "prepend domain-name-servers $LAMP_IP_ADDRESS;" >>/etc/dhcp/dhclient.conf
          systemctl restart networking
        fi
        systemctl daemon-reload
        systemctl enable coredns --now
        add_firewall_rule 53

      fi
    fi
  fi

  # Cleaning files
  rm -f /etc/coredns/coredns.tgz
fi
