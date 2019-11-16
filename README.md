deboostrap debian to ZFS
=========================

This
* uses BIOS instead of UEFI (patches welcome)
* formats the target drive with ZFS
* adds two pools (boot+rest)
* add datasets for various directories
* deboostraps debian sid

You can verify the installation wih e.g. qemu (eventually change the path of
`/dev/sda` to wherever you installed to:

```
qemu-system-x86_64 -snapshot -m 3G -enable-kvm -drive file=/dev/sda,if=virtio -net none -boot c -monitor stdio -netdev user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9 -device e1000,netdev=mynet0
# you can send keypresses via e.g. `sendkey ctrl-alt-f9`
```

This has been built with the help of this great howto: <https://github.com/zfsonlinux/zfs/wiki/Debian-Stretch-Root-on-ZFS>

adding swap
------------
```shell
zfs create -V 4G -b $(getconf PAGESIZE) -o compression=zle \
      -o logbias=throughput -o sync=always \
      -o primarycache=metadata -o secondarycache=none \
      -o com.sun:auto-snapshot=false rpool/swap

mkswap -f /dev/zvol/rpool/swap
echo /dev/zvol/rpool/swap none swap defaults 0 0 >> /etc/fstab
```
