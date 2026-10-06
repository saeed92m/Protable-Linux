#!/bin/bash
set -euo pipefail
ROOT="build/rootfs"
OUT="dist/protable-linux-installer-amd64.iso"
if [[ $# -ge 1 ]]; then ROOT="$1"; fi
if [[ $# -ge 2 ]]; then OUT="$2"; fi
mkdir -p "$(dirname "$OUT")" build/iso/live
[[ -d "$ROOT" ]] || { echo "Rootfs missing: $ROOT" >&2; exit 2; }
rm -rf build/iso
mkdir -p build/iso/live build/iso/boot/grub
cp "$ROOT"/boot/vmlinuz-* build/iso/live/vmlinuz
cp "$ROOT"/boot/initrd.img-* build/iso/live/initrd.img
mksquashfs "$ROOT" build/iso/live/filesystem.squashfs -comp zstd -noappend
cat > build/iso/boot/grub/grub.cfg <<'EOF'
set timeout=5
set default=0
menuentry "Portable-Linux installer/live environment" {
  linux /live/vmlinuz boot=live components username=portable user-fullname=Portable-Linux console=ttyS0,115200n8 systemd.show_status=true
  initrd /live/initrd.img
}
EOF
grub-mkrescue -o "$OUT" build/iso >/dev/null
sha256sum "$OUT" > "$OUT.sha256"
