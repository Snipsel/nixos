DISK=/dev/sda
SWAP=/dev/sdb

set -euxo pipefail

swaplabel --label swap $SWAP
swapon /dev/disk/by-label/swap

blkdiscard -f $DISK
parted --script --align=optimal $DISK -- \
  mklabel msdos                          \
  mkpart primary   1MB 256MB             \
  mkpart primary 256MB 100%              \
  set 1 boot on

zpool create -f          \
  -o ashift=12           \
  -o autotrim=on         \
  -R /mnt                \
  -O checksum=on         \
  -O atime=off           \
  -O acltype=posix       \
  -O canmount=off        \
  -O dnodesize=auto      \
  -O normalization=formD \
  -O xattr=sa            \
  -O mountpoint=none     \
  -O compression=on      \
  zpool "$DISK"2

zfs create -p -o mountpoint=legacy zpool/root
zfs create -p -o mountpoint=legacy zpool/nix
zfs create -p -o mountpoint=legacy zpool/persist
zfs create -p -o mountpoint=legacy zpool/home

zfs snapshot zpool/root@blank
mkdir /mnt/{boot,nix,home,persist}

mkfs.ext2 -L boot "$DISK"1
mount "$DISK"1 /mnt/boot

mount -t zfs {zpool,/mnt}/nix
mount -t zfs {zpool,/mnt}/home
mount -t zfs {zpool,/mnt}/persist

mkdir -p /mnt/etc /mnt/persist/etc/nixos
ln -s /mnt{/persist,}/etc/nixos
nixos-generate-config --no-filesystems --root /mnt

cp *.nix /mnt/etc/nixos/
nixos-install --no-root-passwd
