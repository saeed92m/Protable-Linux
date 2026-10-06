#!/bin/bash
set -euo pipefail

# Destructive integration test against an isolated sparse loop device.
# This must never be pointed at a physical disk.
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

lsblk -nrpo FSTYPE,LABEL,PARTTYPE "$LOOP" | grep -q 'vfat PORT-EFI c12a7328-f81f-11d2-ba4b-00a0c93ec93b'
lsblk -nrpo FSTYPE,LABEL,PARTTYPE "$LOOP" | grep -q 'ext4 PORT-ROOT 0fc63daf-8483-4772-8e79-3d69d8477de4'

efi_size=$(blockdev --getsize64 "${LOOP}p1")
root_size=$(blockdev --getsize64 "${LOOP}p2")
(( efi_size >= 510*1024*1024 && efi_size <= 514*1024*1024 ))
(( root_size > 7*1024*1024*1024 ))

mkdir -p /tmp/portable-linux-test-mount
mount "${LOOP}p2" /tmp/portable-linux-test-mount
grep -q '^LABEL=PORT-ROOT / ext4 ' /tmp/portable-linux-test-mount/etc/fstab
grep -q '^LABEL=PORT-EFI /boot/efi ' /tmp/portable-linux-test-mount/etc/fstab
grep -q '^/swapfile none swap ' /tmp/portable-linux-test-mount/etc/fstab
[[ -d /tmp/portable-linux-test-mount/boot/efi/EFI/PortableLinux ]]
[[ -f /tmp/portable-linux-test-mount/etc/portable-linux-release ]]
[[ -f /tmp/portable-linux-test-mount/usr/local/bin/portable-install ]]
! lsblk -nrpo NAME,MOUNTPOINT "$LOOP" | grep -q '/home'
echo "Loopback installer integration test: PASS"
