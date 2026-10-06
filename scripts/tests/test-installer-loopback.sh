#!/bin/bash
set -euo pipefail
ROOTFS="${1:-build/rootfs}"
DISK_IMAGE="${RUNNER_TEMP:-/tmp}/portable-linux-test.img"
LOOP=""
mount_dir=/tmp/portable-linux-test-mount
cleanup() {
  umount -R "$mount_dir/boot/efi" 2>/dev/null || true
  umount -R "$mount_dir" 2>/dev/null || true
  if [[ -n "$LOOP" ]]; then losetup -d "$LOOP" 2>/dev/null || true; fi
  rm -f "$DISK_IMAGE"
  rmdir "$mount_dir" 2>/dev/null || true
}
trap cleanup EXIT
[[ -d "$ROOTFS" ]] || { echo "Missing rootfs: $ROOTFS" >&2; exit 2; }
truncate -s 8G "$DISK_IMAGE"
LOOP=$(losetup --find --show --partscan "$DISK_IMAGE")
export PORTABLE_LINUX_CONFIRM_TARGET="$LOOP"
export PORTABLE_LINUX_TEST_MODE=1
bash scripts/portable/install-to-usb.sh "$LOOP" "$ROOTFS"
efi="${LOOP}p1"; root="${LOOP}p2"
echo "Validating loopback partition layout:"
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,PARTTYPE,MOUNTPOINT "$LOOP"
[[ -b "$efi" && -b "$root" ]] || { echo "Expected partition nodes are missing." >&2; exit 10; }
efi_type=$(blkid -o value -s TYPE "$efi"); efi_label=$(blkid -o value -s LABEL "$efi")
root_type=$(blkid -o value -s TYPE "$root"); root_label=$(blkid -o value -s LABEL "$root")
echo "EFI: type=$efi_type label=$efi_label"
echo "ROOT: type=$root_type label=$root_label"
[[ "$efi_type" == "vfat" ]] || exit 11
[[ "$efi_label" == "PORT-EFI" ]] || exit 12
[[ "$root_type" == "ext4" ]] || exit 13
[[ "$root_label" == "PORT-ROOT" ]] || exit 14
efi_size=$(blockdev --getsize64 "$efi"); root_size=$(blockdev --getsize64 "$root")
(( efi_size >= 510*1024*1024 && efi_size <= 514*1024*1024 )) || exit 15
(( root_size > 7*1024*1024*1024 )) || exit 16
if findmnt -rn -S "$root" >/dev/null 2>&1 || findmnt -rn -S "$efi" >/dev/null 2>&1; then
  echo "Installer leaked a target mount:" >&2
  findmnt -rn -S "$root" || true; findmnt -rn -S "$efi" || true
  exit 17
fi
mkdir -p "$mount_dir/boot/efi"
mount "$root" "$mount_dir"
mount "$efi" "$mount_dir/boot/efi"
fstab="$mount_dir/etc/fstab"
echo "Validating installed root filesystem at $mount_dir"
cat "$fstab"
grep -q '^LABEL=PORT-ROOT / ext4 ' "$fstab" || { echo "Missing root fstab entry" >&2; exit 20; }
grep -q '^LABEL=PORT-EFI /boot/efi ' "$fstab" || { echo "Missing EFI fstab entry" >&2; exit 21; }
grep -q '^/swapfile none swap ' "$fstab" || { echo "Missing swapfile fstab entry" >&2; exit 22; }
[[ -f "$mount_dir/boot/efi/EFI/BOOT/BOOTX64.EFI" ]] || {
  echo "Missing removable UEFI bootloader" >&2
  find "$mount_dir/boot/efi/EFI" -maxdepth 2 -type f -print 2>/dev/null || true
  exit 23
}
[[ -f "$mount_dir/etc/portable-linux-release" ]] || exit 24
[[ -f "$mount_dir/usr/local/bin/portable-install" ]] || exit 25
if lsblk -nrpo NAME,MOUNTPOINT "$LOOP" | grep -q '/home'; then
  echo "Unexpected /home mount detected." >&2; exit 26
fi
echo "Loopback installer integration test: PASS"
