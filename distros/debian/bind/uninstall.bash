#
# MailHog Uninstaller
#

console_log "As it is abandoned, any reference to it is eliminated."
if [[ -f /etc/bind/lamp.conf ]]; then
  apt_remove bind9
  rm -rf /etc/bind
fi
