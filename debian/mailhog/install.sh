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

( cmd_exists mhsendmail && cmd_exists mailhog ) && echo -n "Updating" || echo -n "Installing"
echo " MailHog"
systemctl stop mailhog &>/dev/null
wget -q `github_download_url "mailhog/mhsendmail" "_linux_amd64"` -O /usr/local/bin/mhsendmail
chmod +x /usr/local/bin/mhsendmail
wget -q `github_download_url "mailhog/MailHog" "_linux_amd64"` -O /usr/local/bin/mailhog
chmod +x /usr/local/bin/mailhog
cp -f "${LAMP_DISTRO_PATH}/mailhog/mailhog.service" /lib/systemd/system/mailhog.service
systemctl daemon-reload
systemctl enable mailhog --now