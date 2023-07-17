#shellcheck disable=SC2154

#
#
#

echo "postfix postfix/main_mailer_type select Internet Site" | sudo debconf-set-selections
echo "postfix postfix/mailname string ${LAMP_FQDN}" | sudo debconf-set-selections
apt_install postfix
if ! grep -q "postmaster@${LAMP_FQDN}" /etc/aliases; then
  echo "root: postmaster@${LAMP_FQDN}" >> /etc/aliases
  newaliases
  systemctl restart postfix
fi

if command_exists mhsendmail && command_exists MailHog; then
  console_log "${LAMP_INCLUDE_NAME}" "Updating binary"
else
  console_log "${LAMP_INCLUDE_NAME}" "Installing binary"
fi

systemctl stop mailhog &>/dev/null
apt_install golang-go &>/dev/null

# Build and Install with custom GO enviroment to clean after is installed
(
  export GOPATH="/tmp/lamp-go"
  export GOCACHE="${GOPATH}/lamp-go/go-cache"
  export GOBIN=/usr/local/bin

  if [[ "$(go version | grep -oP '[0-9]\.[0-9]{2}' | sed 's/\.//')" -lt "117" ]]
  then
    go get github.com/mailhog/MailHog
    go get github.com/mailhog/mhsendmail
  else
    go install github.com/mailhog/MailHog@latest
    go install github.com/mailhog/mhsendmail@latest
  fi

  # Delete deprecated executable and go files
  rm -rf /usr/local/bin/mailhog "${GOPATH}"
) &>/dev/null

cp -f "${LAMP_DISTRO_PATH}/mailhog/mailhog.service" /lib/systemd/system/mailhog.service
systemctl daemon-reload
systemctl enable mailhog --now
