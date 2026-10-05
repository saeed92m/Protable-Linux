# Architecture

Protable-Linux is a lightweight, portable Linux system intended to run as a complete installed operating system from removable USB storage.

## Design goals
- Debian-family base, initially targeting antiX/Debian.
- One root filesystem containing /home; no separate /home partition.
- UEFI boot support, with Legacy BIOS support where practical.
- Persistent storage and configuration.
- ZRAM as the preferred compressed-memory layer.
- Disk swap only as an emergency fallback.
- Hardware detection performed at boot by the underlying Linux/Debian stack.
- Minimal desktop environment with low idle resource usage.

## Non-goals
- This project is not a live-only distribution.
- This project is not Alpha-Linux.
- This project is not the ZTF astronomy project.
- Specialized application bundles are out of scope for the initial base release.
