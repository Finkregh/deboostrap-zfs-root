#!/usr/bin/env bash

declare -r DEST_DISK_ID="__DEST_DISK_ID__"
declare -r DEST_DISK_PATH="/dev/disk/by-id/${DEST_DISK_ID}"
# <http://list.zfsonlinux.org/pipermail/zfs-discuss/2016-June/025765.html>
# zpool now report full paths, rather than relative /dev paths to the disks which may or may not work properly with zfs. Grub utilities check zpool status for zfs pools to find the disks that contain them. Therefore changing the output of zpool status fixes grub.
declare -x -r ZPOOL_VDEV_NAME_PATH=YES

export PATH=/usr/sbin:/sbin:$PATH

grub-probe /boot

echo "Was that 'zfs'? If not the following will now work..."
read

update-initramfs -u -k all

update-grub
grub-install ${DEST_DISK_PATH}

echo "ZFS installed?"
ls /boot/grub/*/zfs.mod
