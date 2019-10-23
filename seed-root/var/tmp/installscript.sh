#!/usr/bin/env bash

DEST_DISK_ID="__DEST_DISK_ID__"
DEST_DISK_PATH="/dev/disk/by-id/${DEST_DISK_ID}"

ln -s /proc/self/mounts /etc/mtab
apt-get update

apt install --yes locales
dpkg-reconfigure locales

dpkg-reconfigure tzdata
apt install --yes dpkg-dev linux-headers-amd64 linux-image-amd64
apt install --yes zfs-initramfs zfsutils-linux zfs-zed firmware-linux firmware-linux-nonfree intel-microcode initramfs-tools systemd dialog moreutils aptitude

apt install --yes grub-pc

systemctl enable zfs-import-bpool.service
cp /usr/share/systemd/tmp.mount /etc/systemd/system/
systemctl enable tmp.mount

grub-probe /boot

echo "Was that 'zfs'?"
read

update-initramfs -u -k all

# vim /etc/default/grub
# GRUB_CMDLINE_LINUX="root=ZFS=rpool/ROOT/debian"
# Remove quiet from: GRUB_CMDLINE_LINUX_DEFAULT
# Uncomment: GRUB_TERMINAL=console

#update-grub

#grub-install  ${DEST_DISK_PATH}

echo "ZFS installed?"
ls /boot/grub/*/zfs.mod
