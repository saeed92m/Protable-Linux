#!/bin/bash
set -euo pipefail

# Non-destructive target validation. The installer must call this before any
# destructive operation and require an explicit target-device confirmation.

dev="${1:-}"
[[ -n "$dev" && -b "$dev" ]] || { echo "Invalid block device." >&2; exit 2; }

rootdev=$(lsblk -no PKNAME "$dev" 2>/dev/null || true)
if [[ -n "$rootdev" ]]; then
  rootdev="/dev/$rootdev"
else
  rootdev="$dev"
fi

echo "TARGET=$dev"
echo "PARENT=$rootdev"
echo "MODEL=$(lsblk -ndo MODEL "$dev" | xargs)"
echo "SIZE=$(lsblk -ndo SIZE "$dev")"
echo "TRANSPORT=$(lsblk -ndo TRAN "$dev")"
echo "READ_ONLY=$(lsblk -ndo RO "$dev")"

if [[ "$rootdev" == /dev/nvme* || "$rootdev" == /dev/sd* || "$rootdev" == /dev/mmcblk* ]]; then
  :
else
  echo "Unsupported target device class." >&2
  exit 1
fi
