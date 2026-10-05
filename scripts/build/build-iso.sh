#!/bin/bash
set -euo pipefail
ROOT="build/rootfs"
OUT="dist/protable-linux-installer-amd64.iso"
if [[ $# -ge 1 ]]; then ROOT="$1"; fi
if [[ $# -ge 2 ]]; then OUT="$2"; fi
mkdir -p "$(dirname "$OUT")" build/iso/live
[[ -d "$ROOT" ]] || { echo "Rootfs missing: $ROOT" >&2; exit 2; }
cp "$ROOT"/boot/vmlinuz-* build/iso/live/vmlinuz
cp "$ROOT"/boot/initrd.img-* build/iso/live/initrd.img
mksquashfs "$ROOT" build/iso/live/filesystem.squashfs -comp zstd -noappend
mkdir -p build/iso/boot/grub
cat > build/iso/boot/grub/grub.cfg <<'EOF'
set timeout=5
set default=0
menuentry "Portable-Linux installer/live environment" {
  linux /live/vmlinuz boot=live components quiet
  initrd /live/initrd.img
}
EOF
grub-mkrescue -o "$OUT" build/iso >/dev/null
sha256sum "$OUT" > "$OUT.sha256"
