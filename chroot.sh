#!/usr/bin/env bash
set -euo pipefail

# <http://list.zfsonlinux.org/pipermail/zfs-discuss/2016-June/025765.html>
# zpool now report full paths, rather than relative /dev paths to the disks which may or may not work properly with zfs. Grub utilities check zpool status for zfs pools to find the disks that contain them. Therefore changing the output of zpool status fixes grub.
declare -r ZPOOL_VDEV_NAME_PATH=YES
declare -r DEST_CHROOT_DIR="/mnt/tmp"

mkdir -p "${DEST_CHROOT_DIR}"

zpool import rpool -R "${DEST_CHROOT_DIR}" -N
zpool import bpool -R "${DEST_CHROOT_DIR}" -N

zfs mount rpool/ROOT/debian
zfs mount bpool/BOOT/debian

for z in rpool/home rpool/var/cache rpool/var/lib/docker rpool/var/log rpool/var/spool rpool/var/tmp; do zfs mount $z; done

systemd-nspawn -D "${DEST_CHROOT_DIR}" /bin/bash -x /var/tmp/installscript.sh
