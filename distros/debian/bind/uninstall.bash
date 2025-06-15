#
# MailHog Uninstaller
#

console_log "Remplaced by CoreDNS, any reference to it is eliminated."
if [[ -f /etc/bind/lamp.conf ]]; then
  apt_remove bind9
  rm -rf /etc/bind
fi
