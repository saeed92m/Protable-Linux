# Storage Layout

Portable-Linux deliberately uses the simplest persistent USB layout.

| Partition / file | Size policy | Filesystem | Purpose |
|---|---:|---|---|
| EFI System Partition | 512 MiB | FAT32 | UEFI boot |
| Root | All remaining capacity | ext4 | OS, /home, applications, projects and user data |
| /swapfile | 0–4 GiB | swapfile | Emergency disk swap inside root |

There is **no separate /home partition** and no separate swap partition.

## Capacity policy

The installer calculates target capacity at installation time. EFI is fixed at 512 MiB and Root receives everything else. The swapfile is created inside Root and therefore does not fragment the partition layout.

The persistent disk-swap ceiling is 4 GiB. ZRAM is the preferred primary swap mechanism.

## Boot policy

GPT + UEFI is the first implementation target. The EFI bootloader is installed in removable-media mode so the USB does not depend on an internal disk's EFI entry. A Legacy BIOS compatibility path is planned as a subsequent validation milestone.

## Data safety

All persistent user data lives inside Root. Removing the USB from a running system is unsafe; users must shut down or unmount it normally before removal.
