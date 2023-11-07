#
# MailHog Installer
#

echo "postfix postfix/main_mailer_type select Internet Site" | sudo debconf-set-selections
echo "postfix postfix/mailname string $LAMP_FQDN" | sudo debconf-set-selections
apt_install postfix golang-go
if ! grep -q "postmaster@$LAMP_FQDN" /etc/aliases
then
  echo "root: postmaster@$LAMP_FQDN" >> /etc/aliases
  newaliases
  systemctl restart postfix
fi

if [[ -f /lib/systemd/system/mailhog.service ]]
then
  systemctl stop mailhog
fi

console_log "$LAMP_INCLUDE_NAME" "Building the latest binaries"

# Build and Install with custom GO enviroment to clean after is installed
(
  export GOPATH="/tmp/lamp-go"
  export GOCACHE="$GOPATH/lamp-go/go-cache"
  export GOBIN=/usr/local/bin
  GOVERSION="$(go version | grep -oP '[0-9]\.[0-9]{2}')"
  if [[ "${GOVERSION/./}" -lt "117" ]]
  then
    go get github.com/mailhog/MailHog
    go get github.com/mailhog/mhsendmail
  else
    go install github.com/mailhog/MailHog@latest
    go install github.com/mailhog/mhsendmail@latest
  fi

  # Delete go files and deprecated mailhog binary
  rm -rf "$GOPATH" "$GOBIN/mailhog"
  ln -s "$GOBIN/MailHog" "$GOBIN/mailhog"
) >/dev/null 2>&1

cp -f "$LAMP_DISTRO_PATH/mailhog/mailhog.service" /lib/systemd/system/mailhog.service
systemctl daemon-reload
systemctl enable mailhog --now
