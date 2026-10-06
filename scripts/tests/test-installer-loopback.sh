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

# The installer owns its temporary mount tree. Ensure no mount leaked from
# the installer before mounting the target for post-install validation.
for _ in {1..10}; do
  if ! findmnt -rn -S "$root" >/dev/null 2>&1 && ! findmnt -rn -S "$efi" >/dev/null 2>&1; then
    break
  fi
  umount "$efi" 2>/dev/null || true
  umount "$root" 2>/dev/null || true
  sleep 0.2
done
if findmnt -rn -S "$root" >/dev/null 2>&1 || findmnt -rn -S "$efi" >/dev/null 2>&1; then
  echo "Installer leaked a target mount; refusing to continue." >&2
  findmnt -rn -S "$root" || true
  findmnt -rn -S "$efi" || true
  exit 17
fi

mkdir -p /tmp/portable-linux-test-mount
mount "$root" /tmp/portable-linux-test-mount
grep -q '^LABEL=PORT-ROOT / ext4 ' /tmp/portable-linux-test-mount/etc/fstab
grep -q '^LABEL=PORT-EFI /boot/efi ' /tmp/portable-linux-test-mount/etc/fstab
grep -q '^/swapfile none swap ' /tmp/portable-linux-test-mount/etc/fstab
[[ -d /tmp/portable-linux-test-mount/boot/efi/EFI/PortableLinux ]]
[[ -f /tmp/portable-linux-test-mount/etc/portable-linux-release ]]
[[ -f /tmp/portable-linux-test-mount/usr/local/bin/portable-install ]]
! lsblk -nrpo NAME,MOUNTPOINT "$LOOP" | grep -q '/home'

echo "Loopback installer integration test: PASS"
