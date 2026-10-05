#!/bin/bash
set -euo pipefail
ROOT="build/rootfs"
if [[ $# -ge 1 ]]; then ROOT="$1"; fi
source config/debian-release.env
[[ $EUID -eq 0 ]] || { echo "Run as root." >&2; exit 2; }
rm -rf "$ROOT"
mkdir -p "$ROOT"
debootstrap --arch="$DEBIAN_ARCH" --variant=minbase "$DEBIAN_CODENAME" "$ROOT" "$DEBIAN_MIRROR"
mount --bind /dev "$ROOT/dev"
mount -t proc proc "$ROOT/proc"
mount -t sysfs sys "$ROOT/sys"
trap 'umount -lf "$ROOT/dev" "$ROOT/proc" "$ROOT/sys" 2>/dev/null || true' EXIT
cat > "$ROOT/etc/apt/sources.list.d/debian.sources" <<EOF
Types: deb
URIs: $DEBIAN_MIRROR
Suites: $DEBIAN_CODENAME $DEBIAN_CODENAME-updates
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: $DEBIAN_SECURITY_MIRROR
Suites: $DEBIAN_CODENAME-security
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
chroot "$ROOT" /bin/bash -eux <<'CHROOT'
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends linux-image-amd64 systemd-sysv grub-efi-amd64-signed shim-signed live-boot live-config network-manager sudo ca-certificates xfce4 xfce4-terminal lightdm dbus-x11 zram-tools firmware-linux-free rsync curl wget nano less bash-completion
apt-get clean
rm -rf /var/lib/apt/lists/*
echo portable > /etc/hostname
systemctl enable NetworkManager
systemctl enable lightdm
useradd -m -s /bin/bash portable
usermod -aG sudo portable
echo 'portable:portable' | chpasswd
printf 'portable ALL=(ALL) NOPASSWD:ALL
' > /etc/sudoers.d/portable
chmod 440 /etc/sudoers.d/portable
printf 'GRUB_TIMEOUT=3
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
' > /etc/default/grub
mkdir -p /etc/skel/Documents /etc/skel/Projects /etc/skel/data
CHROOT
rm -f "$ROOT/etc/machine-id"
mkdir -p "$ROOT/etc/machine-id"
mkdir -p "$ROOT/usr/local/libexec/portable-linux" "$ROOT/etc/systemd/system"
cp scripts/portable/first-boot.sh "$ROOT/usr/local/libexec/portable-linux/first-boot"
cp scripts/portable/portable-swap.service "$ROOT/etc/systemd/system/portable-swap.service"
chmod 0755 "$ROOT/usr/local/libexec/portable-linux/first-boot"
ln -sf /etc/systemd/system/portable-swap.service "$ROOT/etc/systemd/system/multi-user.target.wants/portable-swap.service"
printf 'Portable-Linux target rootfs built from Debian %s (%s).
' "$DEBIAN_VERSION" "$DEBIAN_CODENAME" > "$ROOT/etc/portable-linux-release"
