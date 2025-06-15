#
# MailPit Installer
#

if [[ -f /usr/local/bin/mailpit ]]; then
  console_log "Upgrading MailPit binary"
else
  console_log "Installing MailPit binary"
  mkdir -p /usr/local/bin
fi
mkdir -p /tmp/lamp-mailpit/bin
systemctl stop mailpit >/dev/null 2>&1
if download https://raw.githubusercontent.com/axllent/mailpit/develop/install.sh "/tmp/lamp-mailpit/install.sh"; then
  sh "/tmp/lamp-mailpit/install.sh" --install-path "/tmp/lamp-mailpit/bin" --token "${LAMP_GITHUB_TOKEN:-}" 2>&1 | tee "/tmp/lamp-mailpit/install.log" >/dev/null
  if [[ -x "/tmp/lamp-mailpit/bin/mailpit" ]]; then
    cp -f "/tmp/lamp-mailpit/bin/mailpit" /usr/local/bin/mailpit
    chmod +x /usr/local/bin/mailpit
    if ! grep -q 'mailpit' /etc/passwd; then
      adduser --system --group mailpit
    fi
    mkdir -p /etc/mailpit
    chown "mailpit:mailpit" /etc/mailpit
    cp -f "$LAMP_DISTRO_PATH/mailpit/mailpit.env" /etc/mailpit/mailpit.env
    if [[ -f "$LAMP_PATH/config/mailpit.env" ]]; then
      cp -f "$LAMP_PATH/config/mailpit.env" /etc/mailpit/mailpit.env
    fi
    cp -f "$LAMP_DISTRO_PATH/mailpit/mailpit.service" /lib/systemd/system/mailpit.service
    systemctl daemon-reload
    systemctl enable mailpit --now
  else
    console_log "Install script failed"
    if [[ -f "/tmp/lamp-mailpit/install.log" ]]; then
      while read -r line; do
        console_log "$line"
      done <"/tmp/lamp-mailpit/install.log"
    fi
  fi
else
  console_log "Download failed"
fi
rm -rf "/tmp/lamp-mailpit"
