#
# MailHog Uninstaller
#

console_log "$LAMP_INCLUDE_NAME" "As it is abandoned, any reference to it is eliminated."
systemctl stop mailhog &>/dev/null
rm -f /lib/systemd/system/mailhog.service
rm -f /usr/local/bin/{mailhog,MailHog,mhsendmail}
find /etc/php -type f -iname "*mailhog*" -delete

if question "Uninstall the extra packages?"; then
  apt_remove postfix golang-go
fi
