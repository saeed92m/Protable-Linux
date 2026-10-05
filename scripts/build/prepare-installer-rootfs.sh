#!/bin/bash
set -euo pipefail
ROOT="build/rootfs"
if [[ $# -ge 1 ]]; then ROOT="$1"; fi
mkdir -p "$ROOT/usr/local/libexec/portable-linux"
install -m 0755 scripts/portable/install-to-usb.sh "$ROOT/usr/local/libexec/portable-linux/install-to-usb"
cat > "$ROOT/usr/local/bin/portable-install" <<'EOF'
#!/bin/bash
exec sudo /usr/local/libexec/portable-linux/install-to-usb "$@"
EOF
chmod 0755 "$ROOT/usr/local/bin/portable-install"
