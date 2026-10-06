#!/bin/bash
set -euo pipefail

ROOTFS="${1:-build/rootfs}"
DISK_IMAGE="${RUNNER_TEMP:-/tmp}/portable-linux-test.img"
LOOP=""

cleanup() {
  if [[ -n "$LOOP" ]]; then
    umount -R /tmp/portable-linux-test-mount 2>/dev/null || true
    losetup -d "$LOOP" 2>/dev/null || true
  fi
  rm -f "$DISK_IMAGE"
  rmdir /tmp/portable-linux-test-mount 2>/dev/null || true
}
trap cleanup EXIT

[[ -d "$ROOTFS" ]] || { echo "Missing rootfs: $ROOTFS" >&2; exit 2; }
truncate -s 8G "$DISK_IMAGE"
LOOP=$(losetup --find --show --partscan "$DISK_IMAGE")
export PORTABLE_LINUX_CONFIRM_TARGET="$LOOP"
export PORTABLE_LINUX_TEST_MODE=1

bash scripts/portable/install-to-usb.sh "$LOOP" "$ROOTFS"

efi="${LOOP}p1"
root="${LOOP}p2"

echo "Validating loopback partition layout:"
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,PARTTYPE,MOUNTPOINT "$LOOP"

[[ -b "$efi" && -b "$root" ]] || {
  echo "Expected partition nodes are missing after installation." >&2
  exit 10
}

efi_type=$(blkid -o value -s TYPE "$efi")
efi_label=$(blkid -o value -s LABEL "$efi")
root_type=$(blkid -o value -s TYPE "$root")
root_label=$(blkid -o value -s LABEL "$root")
echo "EFI: type=$efi_type label=$efi_label"
echo "ROOT: type=$root_type label=$root_label"

[[ "$efi_type" == "vfat" ]] || { echo "Unexpected EFI filesystem: $efi_type" >&2; exit 11; }
[[ "$efi_label" == "PORT-EFI" ]] || { echo "Unexpected EFI label: $efi_label" >&2; exit 12; }
[[ "$root_type" == "ext4" ]] || { echo "Unexpected root filesystem: $root_type" >&2; exit 13; }
[[ "$root_label" == "PORT-ROOT" ]] || { echo "Unexpected root label: $root_label" >&2; exit 14; }

efi_size=$(blockdev --getsize64 "$efi")
root_size=$(blockdev --getsize64 "$root")
(( efi_size >= 510*1024*1024 && efi_size <= 514*1024*1024 )) || {
  echo "Unexpected EFI size: $efi_size bytes" >&2
  exit 15
}
(( root_size > 7*1024*1024*1024 )) || {
  echo "Unexpected root size: $root_size bytes" >&2
  exit 16
}

if findmnt -rn -S "$root" >/dev/null 2>&1 || findmnt -rn -S "$efi" >/dev/null 2>&1; then
  echo "Installer leaked a target mount:" >&2
  findmnt -rn -S "$root" || true
  findmnt -rn -S "$efi" || true
  exit 17
fi

mount_dir=/tmp/portable-linux-test-mount
mkdir -p "$mount_dir"
mount "$root" "$mount_dir"

fstab="$mount_dir/etc/fstab"
echo "Validating installed root filesystem at $mount_dir"
echo "--- /etc/fstab ---"
cat "$fstab"
echo "--- required paths ---"
ls -ld "$mount_dir/boot/efi" "$mount_dir/boot/efi/EFI/PortableLinux" "$mount_dir/usr/local/bin/portable-install" "$mount_dir/etc/portable-linux-release"

grep -q '^LABEL=PORT-ROOT / ext4 ' "$fstab" || { echo "Missing root fstab entry" >&2; exit 20; }
grep -q '^LABEL=PORT-EFI /boot/efi ' "$fstab" || { echo "Missing EFI fstab entry" >&2; exit 21; }
grep -q '^/swapfile none swap ' "$fstab" || { echo "Missing swapfile fstab entry" >&2; exit 22; }
[[ -d "$mount_dir/boot/efi/EFI/PortableLinux" ]] || { echo "Missing PortableLinux EFI loader directory" >&2; exit 23; }
[[ -f "$mount_dir/etc/portable-linux-release" ]] || { echo "Missing release metadata" >&2; exit 24; }
[[ -f "$mount_dir/usr/local/bin/portable-install" ]] || { echo "Missing installer entrypoint" >&2; exit 25; }

if lsblk -nrpo NAME,MOUNTPOINT "$LOOP" | grep -q '/home'; then
  echo "Unexpected /home mount detected." >&2
  exit 26
fi

echo "Loopback installer integration test: PASS"
