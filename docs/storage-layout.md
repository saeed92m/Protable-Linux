# Storage Layout

The initial 64 GB USB target uses a simple single-root layout.

| Partition | Target | Filesystem | Purpose |
|---|---:|---|---|
| EFI System Partition | ~512 MiB | FAT32 | UEFI boot |
| Root | ~53–54 GiB | ext4 | OS and /home |
| Emergency swap | ~4 GiB | swap | Last-resort fallback |

A small amount of remaining capacity may be left unused/reserved if required by the final installer.

## Root policy
There is intentionally no separate /home partition. /home is a directory inside the root filesystem.

## Memory policy
ZRAM is not a disk partition. It is the preferred compressed swap layer in RAM.

Disk swap exists only as a fallback. The final configuration should give ZRAM higher priority and keep disk swapping conservative because the target medium is USB flash storage.

## Boot partitioning
GPT is preferred. A small BIOS Boot partition may be added if required for reliable GRUB Legacy BIOS boot on GPT media.
