# Architecture

Protable-Linux is a lightweight, portable Linux system intended to run as a complete persistent operating system from removable USB storage.

## Core contract

The USB is the system. Bootloader, operating system, applications, configuration, user accounts, projects and files are stored on the removable device. The destination computer's internal storage is not an installation dependency.

## Storage

- 512 MiB FAT32 EFI System Partition.
- One ext4 Root partition using all remaining capacity.
- `/home` is a directory inside Root.
- No separate data or swap partition.
- Persistent `/swapfile` is optional and capped at 4 GiB.
- ZRAM is preferred over disk swap.

## Portability

At boot, the installed Linux stack discovers the destination machine's CPU, GPU, display, network, audio and other hardware. The system must not assume a specific internal disk, GPU, NIC or monitor.

## Safety

The installer is fail-closed around target selection. It must require an explicit removable-device target, reject mounted targets and never silently install a bootloader on an internal disk.

## Operating modes

The primary product is a persistent installed USB system. Live/recovery media and optional encryption are secondary capabilities, not substitutes for persistence.

## Non-goals

- This project is not Alpha-Linux.
- This project is not the ZTF astronomy project.
- Specialized application bundles are out of scope for the initial base release.
