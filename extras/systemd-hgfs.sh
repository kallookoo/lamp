#!/usr/bin/env bash

# Configure and enable the mounting of VMware shared folders on a Linux system using systemd.
# Requirements: open-vm-tools
#
# Usage:
# - bash vm-customize.sh
# - wget https://raw.githubusercontent.com/kallookoo/lamp/refs/heads/main/extras/systemd-hgfs.sh && bash vm-customize.sh
#
# Info: https://knowledge.broadcom.com/external/article/316336/enabling-hgfs-shared-folders-on-fusion-o.html

if [[ "$(id -u)" -ne "0" ]]; then
  echo "This script must be run as root, please run this script again with the root user or sudo."
  exit 1
fi

# Creating the fuse (open-vm-tools) configuration.
if ! grep -qE '^fuse' /etc/modules-load.d/open-vm-tools.conf 2>/dev/null; then
  echo "fuse" | tee -a /etc/modules-load.d/open-vm-tools.conf
fi

# Creating the default mount point.
mkdir -p /mnt/hgfs

# Disable the mount service if exists.
[ -f /etc/systemd/system/mnt-hgfs.mount ] && systemctl disable mnt-hgfs.mount --now

# Creating the mount service.
# NOTE: This service set the default user/group in 1000 (DEBIAN and Derivatives)
cat <<EOF >/etc/systemd/system/mnt-hgfs.mount
[Unit]
Description=VMware automount shared folders
DefaultDependencies=no
Before=umount.target
ConditionVirtualization=vmware
After=sys-fs-fuse-connections.mount

[Mount]
What=vmhgfs-fuse
Where=/mnt/hgfs
Type=fuse
Options=default_permissions,allow_other,uid=1000,gid=1000

[Install]
WantedBy=multi-user.target
EOF

# Make sure the 'fuse' module is loaded
modprobe -v fuse

# Enable the mount service
systemctl daemon-reload
systemctl enable mnt-hgfs.mount --now
