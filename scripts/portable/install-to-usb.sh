#!/bin/bash
set -euo pipefail

# Destructive installer foundation for a prepared Debian root filesystem.
# Usage: install-to-usb.sh /dev/sdX /path/to/rootfs
#
# Production safety: only USB/MMC transports are accepted and an exact
# device-path confirmation is required. CI may use an explicit loop-device
# test mode; it is never enabled implicitly.

dev="${1:-}"
rootfs="${2:-}"
confirm="${PORTABLE_LINUX_CONFIRM_TARGET:-}"
test_mode="${PORTABLE_LINUX_TEST_MODE:-0}"

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

transport=$(lsblk -ndo TRAN "$dev" || true)
if [[ "$test_mode" == "1" ]]; then
  [[ "$dev" == /dev/loop* ]] || { echo "Test mode only permits /dev/loop* targets." >&2; exit 5; }
else
  case "$transport" in
    usb|mmc) ;;
    *)
      echo "Refusing non-removable transport '$transport'. USB/mmc target required." >&2
      exit 5
      ;;
  esac
fi

echo "WARNING: $dev will be erased."
lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,MOUNTPOINT "$dev"
if [[ "$test_mode" == "1" ]]; then
  typed="$dev"
else
  read -r -p "Type the exact device path to continue: " typed
fi
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

# Some CI kernels do not materialize loop partitions immediately after
# partprobe. Explicitly add the partition mappings and wait for the exact
# expected nodes instead of racing udev.
partx --add "$dev" 2>/dev/null || true
udevadm settle

# GitHub-hosted CI runners can expose loop partitions through the kernel/lsblk
# while udev has not created the corresponding /dev nodes. In the explicit
# loopback test mode only, materialize those nodes from the kernel major:minor
# mappings. Never do this for physical USB/MMC installation targets.
materialize_loop_partition_nodes() {
  [[ "$test_mode" == "1" && "$dev" == /dev/loop* ]] || return 0
  for part in "$efi" "$root"; do
    if [[ ! -b "$part" ]]; then
      sysfs_dev="/sys/class/block/$(basename "$part")/dev"
      mm=""
      if [[ -r "$sysfs_dev" ]]; then
        mm=$(cat "$sysfs_dev")
      fi
      if [[ ! "$mm" =~ ^[0-9]+:[0-9]+$ ]]; then
        mm=$(lsblk -nrpo NAME,MAJ:MIN "$dev" 2>/dev/null | awk -v wanted="$part" '$1 == wanted {print $2; exit}')
      fi
      if [[ "$mm" =~ ^[0-9]+:[0-9]+$ ]]; then
        rm -f "$part"
        mknod "$part" b "${mm%%:*}" "${mm##*:}"
        chmod 660 "$part"
      fi
    fi
  done
}

materialize_loop_partition_nodes

for _ in {1..20}; do
  [[ -b "$efi" && -b "$root" ]] && break
  partprobe "$dev" 2>/dev/null || true
  partx --add "$dev" 2>/dev/null || true
  udevadm settle
  sleep 0.5
  materialize_loop_partition_nodes
done
[[ -b "$efi" && -b "$root" ]] || {
  echo "Partition device nodes did not appear for $dev." >&2
  lsblk -o NAME,SIZE,TYPE,PKNAME "$dev" >&2 || true
  exit 7
}

mkfs.fat -F32 -n PORTABLE-EFI "$efi"
mkfs.ext4 -F -L PORTABLE-ROOT "$root"

tmp=$(mktemp -d)
cleanup() {
  umount -R "$tmp" 2>/dev/null || true
  rmdir "$tmp" 2>/dev/null || true
}
trap cleanup EXIT
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

if [[ -x "$tmp/root/usr/sbin/grub-install" ]]; then
  mount --rbind /dev "$tmp/root/dev"
  mount --make-rslave "$tmp/root/dev"
  mount --rbind /proc "$tmp/root/proc"
  mount --make-rslave "$tmp/root/proc"
  mount --rbind /sys "$tmp/root/sys"
  mount --make-rslave "$tmp/root/sys"
  if [[ "$test_mode" == "1" ]]; then
    chroot "$tmp/root" /usr/sbin/grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=PortableLinux --removable --no-nvram --recheck
  else
    chroot "$tmp/root" /usr/sbin/grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=PortableLinux --removable --recheck
  fi
  chroot "$tmp/root" update-grub || true
  umount -R "$tmp/root/dev" 2>/dev/null || true
  umount -R "$tmp/root/proc" 2>/dev/null || true
  umount -R "$tmp/root/sys" 2>/dev/null || true
else
  echo "Rootfs does not contain grub-install; bootloader installation deferred." >&2
fi

sync
echo "Portable-Linux installation completed on $dev."
