#!/usr/bin/env bash
set -euo pipefail

declare -r DEST_DISK_ID="ata-ST1000LM024_HN-M101MBB_S314JB0FA42608"
declare -r DEST_DISK_PATH="/dev/disk/by-id/${DEST_DISK_ID}"
declare -r PACKAGELIST="sudo,popularity-contest"
declare -r DEST_CHROOT_DIR="/mnt/tmp"

mkdir -p "${DEST_CHROOT_DIR}"

zpool export bpool || true
zpool export rpool || true
zpool labelclear -f ${DEST_DISK_PATH}-part3 || true
zpool labelclear -f ${DEST_DISK_PATH}-part4 || true

# clear partition table
sgdisk --zap-all "${DEST_DISK_PATH}"

# BIOS
sgdisk -a1 -n1:24K:+1000K -t1:EF02 "${DEST_DISK_PATH}"
# or UEFI
#sgdisk     -n2:1M:+512M   -t2:EF00 "${DEST_DISK_PATH}"

# boot-pool
sgdisk -n3:0:+1G -t3:BF01 "${DEST_DISK_PATH}"
# root-pool
sgdisk -n4:0:0 -t4:BF01 "${DEST_DISK_PATH}"

partprobe
sleep 5

# create boot-pool
zpool create -o ashift=12 -d \
    -o feature@async_destroy=enabled \
    -o feature@bookmarks=enabled \
    -o feature@embedded_data=enabled \
    -o feature@empty_bpobj=enabled \
    -o feature@enabled_txg=enabled \
    -o feature@extensible_dataset=enabled \
    -o feature@filesystem_limits=enabled \
    -o feature@hole_birth=enabled \
    -o feature@large_blocks=enabled \
    -o feature@lz4_compress=enabled \
    -o feature@spacemap_histogram=enabled \
    -o feature@userobj_accounting=enabled \
    -O acltype=posixacl -O canmount=off -O compression=lz4 -O devices=off \
    -O normalization=formD -O relatime=on -O xattr=sa \
    -O mountpoint=/ -R "${DEST_CHROOT_DIR}" \
    bpool "${DEST_DISK_PATH}-part3"

# create root-pool
zpool create -o ashift=12 \
    -o feature@log_spacemap=disabled \
    -O acltype=posixacl -O canmount=off -O compression=lz4 \
    -O dnodesize=auto -O normalization=formD -O relatime=on -O xattr=sa \
    -O mountpoint=/ -R "${DEST_CHROOT_DIR}" \
    rpool "${DEST_DISK_PATH}-part4"

# create containers
zfs create -o canmount=off -o mountpoint=none rpool/ROOT
zfs create -o canmount=off -o mountpoint=none bpool/BOOT

# create datasets
zfs create -o canmount=noauto -o mountpoint=/ rpool/ROOT/debian
zfs mount rpool/ROOT/debian

zfs create -o canmount=noauto -o mountpoint=/boot bpool/BOOT/debian
zfs mount bpool/BOOT/debian

zfs create rpool/home
# zfs create -o mountpoint=/root             rpool/home/root
zfs create -o canmount=off rpool/var
# zfs create -o canmount=off                 rpool/var/lib
zfs create rpool/var/log
zfs create rpool/var/spool

#The datasets below are optional, depending on your preferences and/or software choices:

# If you wish to exclude these from snapshots:
zfs create -o com.sun:auto-snapshot=false rpool/var/cache
zfs create -o com.sun:auto-snapshot=false rpool/var/tmp
chmod 1777 "${DEST_CHROOT_DIR}"/var/tmp

# If you use /opt on this system:
#zfs create                                 rpool/opt

# If you use /srv on this system:
#zfs create                                 rpool/srv

# If you use /usr/local on this system:
#zfs create -o canmount=off                 rpool/usr
#zfs create                                 rpool/usr/local

# If this system will store local email in /var/mail:
#zfs create                                 rpool/var/mail

# If you use /var/www on this system:
#zfs create                                 rpool/var/www

zfs create -o canmount=off rpool/var/lib
# If this system will use Docker (which manages its own datasets & snapshots):
zfs create -o com.sun:auto-snapshot=false rpool/var/lib/docker

# A tmpfs is recommended later, but if you want a separate dataset for /tmp:
#zfs create -o com.sun:auto-snapshot=false  rpool/tmp
#chmod 1777 "${DEST_CHROOT_DIR}"/tmp

# finally debootstrap
debootstrap --cache-dir=/var/cache/debootstrap --components=main,contrib,non-free --variant=buildd --include=${PACKAGELIST} sid "${DEST_CHROOT_DIR}" https://deb.debian.org/debian/

# ?
zfs set devices=off rpool

# mount stuff into chroot
mount --rbind /dev "${DEST_CHROOT_DIR}"/dev
mount --rbind /proc "${DEST_CHROOT_DIR}"/proc
mount --rbind /sys "${DEST_CHROOT_DIR}"/sys

rsync -rlv seed-root/ "${DEST_CHROOT_DIR}/"
sed -i "s,__DEST_DISK_ID__,${DEST_DISK_ID},g" "${DEST_CHROOT_DIR}/var/tmp/installscript.sh"

chroot "${DEST_CHROOT_DIR}" /bin/bash -x /var/tmp/installscript.sh
