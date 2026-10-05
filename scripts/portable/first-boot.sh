#!/bin/bash
set -euo pipefail

# First-boot memory/storage policy. Safe to run repeatedly.
swapfile=/swapfile
max_bytes=$((4 * 1024 * 1024 * 1024))

if [[ ! -e "$swapfile" ]]; then
  # Keep the default conservative: ZRAM should normally be the primary layer.
  if command -v swapon >/dev/null && awk 'NR>1 {exit 0}' /proc/swaps; then
    :
  fi
  if command -v fallocate >/dev/null; then
    fallocate -l "$max_bytes" "$swapfile"
  else
    dd if=/dev/zero of="$swapfile" bs=1M count=4096 status=none
  fi
  chmod 600 "$swapfile"
  mkswap "$swapfile" >/dev/null
fi

grep -qF "$swapfile none swap sw,pri=5 0 0" /etc/fstab ||   printf '%s\n' "$swapfile none swap sw,pri=5 0 0" >> /etc/fstab

swapon "$swapfile" 2>/dev/null || true
