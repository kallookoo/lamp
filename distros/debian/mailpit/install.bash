#
# MailPit Installer
#

if [[ -f /lib/systemd/system/mailpit.service ]]; then
  systemctl stop mailpit
fi

console_log "The installer will be executed"
bash < <(curl -sL https://raw.githubusercontent.com/axllent/mailpit/develop/install.sh) | while read -r line; do
  console_log "$line"
done
unset line

if ! grep -q 'mailpit' /etc/passwd; then
  adduser --system --group mailpit
fi
mkdir -p /etc/mailpit
chown "mailpit:mailpit" /etc/mailpit
cp -f "$LAMP_DISTRO_PATH/mailpit/mailpit.env" /etc/mailpit/mailpit.env
cp -f "$LAMP_DISTRO_PATH/mailpit/mailpit.service" /lib/systemd/system/mailpit.service
systemctl daemon-reload
systemctl enable mailpit --now
