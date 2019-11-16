#!/usr/bin/env bash

declare -r DEST_DISK_ID="__DEST_DISK_ID__"
declare -r DEST_DISK_PATH="/dev/disk/by-id/${DEST_DISK_ID}"
# <http://list.zfsonlinux.org/pipermail/zfs-discuss/2016-June/025765.html>
# zpool now report full paths, rather than relative /dev paths to the disks which may or may not work properly with zfs. Grub utilities check zpool status for zfs pools to find the disks that contain them. Therefore changing the output of zpool status fixes grub.
declare -r ZPOOL_VDEV_NAME_PATH=YES

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
