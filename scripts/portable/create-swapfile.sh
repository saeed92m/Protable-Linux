#!/bin/bash
set -euo pipefail

# Create/resize the persistent emergency swapfile on the Portable-Linux root.
# ZRAM remains the preferred fast swap layer; this file is the persistent fallback.

mountpoint="${1:-/}"
size_gib="${2:-4}"
swapfile="$mountpoint/swapfile"

if ! [[ "$size_gib" =~ ^[0-4]$ ]] || [[ "$size_gib" == "0" ]]; then
  echo "Usage: $0 [root-mountpoint] [1-4]" >&2
  exit 2
fi

if [[ "$mountpoint" != "/" ]]; then
  test -d "$mountpoint" || { echo "Root mountpoint does not exist." >&2; exit 1; }
fi

fallocate -l "${size_gib}G" "$swapfile"
chmod 600 "$swapfile"
mkswap -f "$swapfile" >/dev/null
swapon "$swapfile"
echo "Enabled $swapfile at ${size_gib} GiB."
