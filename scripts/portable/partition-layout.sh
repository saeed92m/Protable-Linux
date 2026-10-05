#!/bin/bash
set -euo pipefail

# Print the canonical Portable-Linux storage contract for a target block device.
# This script is intentionally read-only: it never partitions or formats anything.

dev="${1:-}"
if [[ -z "$dev" || ! -b "$dev" ]]; then
  echo "Usage: $0 /dev/sdX|/dev/nvmeXn1" >&2
  exit 2
fi

size_bytes=$(blockdev --getsize64 "$dev")
efi_bytes=$((512 * 1024 * 1024))
if (( size_bytes <= efi_bytes )); then
  echo "Target is too small for the Portable-Linux layout." >&2
  exit 1
fi

root_bytes=$((size_bytes - efi_bytes))
printf 'Target: %s\nEFI:   512 MiB FAT32\nRoot:  %s bytes (remaining capacity) ext4\nSwap:  swapfile inside root, max 4 GiB\n' "$dev" "$root_bytes"
