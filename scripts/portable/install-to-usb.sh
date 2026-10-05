#!/bin/bash
set -euo pipefail

# Destructive installer foundation for a prepared Debian root filesystem.
# Usage: install-to-usb.sh /dev/sdX /path/to/rootfs
#
# The caller must explicitly identify the removable target. The script refuses
# mounted targets and requires PORTABLE_LINUX_CONFIRM_TARGET to match exactly.

dev="${1:-}"
rootfs="${2:-}"
confirm="${PORTABLE_LINUX_CONFIRM_TARGET:-}"

[[ $EUID -eq 0 ]] || { echo "Run as root." >&2; exit 2; }
[[ -b "$dev" ]] || { echo "Target must be a block device." >&2; exit 2; }
[[ -d "$rootfs" ]] || { echo "Rootfs directory not found." >&2; exit 2; }
[[ "$confirm" == "$dev" ]] || {
  echo "Refusing destructive install. Set PORTABLE_LINUX_CONFIRM_TARGET=$dev" >&2
  exit 3
}

if lsblk -nrpo MOUNTPOINT "$dev" | grep -qE '^/.+'; then
  echo "Refusing: target or one of its partitions is mounted." >&2
  exit 4
fi

transport=$(lsblk -ndo TRAN "$dev")
case "$transport" in
  usb|mmc) ;;
  *)
    echo "Refusing non-removable transport '$transport'. USB/mmc target required." >&2
    exit 5
    ;;
esac

echo "WARNING: $dev will be erased."
lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,MOUNTPOINT "$dev"
read -r -p "Type the exact device path to continue: " typed
[[ "$typed" == "$dev" ]] || { echo "Target confirmation failed." >&2; exit 6; }

wipefs -a "$dev"
sgdisk --zap-all "$dev"
sgdisk -n 1:1MiB:+512MiB -t 1:ef00 -c 1:EFI "$dev"
sgdisk -n 2:0:0 -t 2:8300 -c 2:ROOT "$dev"
partprobe "$dev"
udevadm settle

case "$dev" in
  /dev/nvme*|/dev/mmcblk*) efi="${dev}p1"; root="${dev}p2" ;;
  *) efi="${dev}1"; root="${dev}2" ;;
esac

mkfs.fat -F32 -n PORTABLE-EFI "$efi"
mkfs.ext4 -F -L PORTABLE-ROOT "$root"

tmp=$(mktemp -d)
trap 'umount -R "$tmp" 2>/dev/null || true; rmdir "$tmp" 2>/dev/null || true' EXIT
mkdir -p "$tmp/efi" "$tmp/root"
mount "$root" "$tmp/root"
mkdir -p "$tmp/root/boot/efi"
mount "$efi" "$tmp/root/boot/efi"

cp -a "$rootfs"/. "$tmp/root"/

cat > "$tmp/root/etc/fstab" <<EOF
LABEL=PORTABLE-ROOT / ext4 defaults,noatime,errors=remount-ro 0 1
LABEL=PORTABLE-EFI /boot/efi vfat umask=0077 0 1
/swapfile none swap sw,pri=5 0 0
EOF

mkdir -p "$tmp/root/swap"
if [[ -x "$tmp/root/usr/sbin/grub-install" ]]; then
  mount --rbind /dev "$tmp/root/dev"
  mount --make-rslave "$tmp/root/dev"
  mount --rbind /proc "$tmp/root/proc"
  mount --make-rslave "$tmp/root/proc"
  mount --rbind /sys "$tmp/root/sys"
  mount --make-rslave "$tmp/root/sys"
  chroot "$tmp/root" /usr/sbin/grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=PortableLinux --removable --recheck
  chroot "$tmp/root" update-grub || true
  umount -R "$tmp/root/dev" 2>/dev/null || true
  umount -R "$tmp/root/proc" 2>/dev/null || true
  umount -R "$tmp/root/sys" 2>/dev/null || true
else
  echo "Rootfs does not contain grub-install; bootloader installation deferred." >&2
fi

sync
echo "Portable-Linux installation completed on $dev."
