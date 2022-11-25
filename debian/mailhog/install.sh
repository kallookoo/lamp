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

if cmd_exists mhsendmail && cmd_exists mailhog; then
  console_log "${LAMP_INCLUDE_NAME}" "Updating binary"
else
  console_log "${LAMP_INCLUDE_NAME}" "Installing binary"
fi

systemctl stop mailhog &>/dev/null
apt_install golang-go

# Build and Install with custom GOPATH to clean after is installed
(
  export GOPATH="/tmp/lamp-go"
  go get github.com/mailhog/MailHog
  cp -f "${GOPATH}/bin/MailHog" /usr/local/bin/mailhog
  chmod +x /usr/local/bin/mailhog

  go get github.com/mailhog/mhsendmail
  cp -f "${GOPATH}/bin/mhsendmail" /usr/local/bin/mhsendmail
  chmod +x /usr/local/bin/mhsendmail
  rm -rf "${GOPATH}"
)

cp -f "${LAMP_DISTRO_PATH}/mailhog/mailhog.service" /lib/systemd/system/mailhog.service
systemctl daemon-reload
systemctl enable mailhog --now
