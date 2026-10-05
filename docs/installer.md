# Portable-Linux Installer Contract

The installer creates a **real persistent operating system on the USB target**, not an ephemeral live session.

## Canonical layout

- EFI System Partition: 512 MiB, FAT32.
- One root partition: ext4, consuming all remaining capacity.
- No separate /home, /var, or data partitions.
- User data and configuration live under the root filesystem.
- Persistent emergency swap is a swapfile inside root, capped at 4 GiB.
- ZRAM is the preferred primary swap layer when enabled by the base system.

## Safety contract

1. The internal disks of the destination computer are not installation targets by default.
2. The installer must display the exact target model, transport, size, and device path before destructive operations.
3. Installation must fail closed when the target cannot be positively identified.
4. EFI and root must both be created on the selected USB target.
5. No bootloader components required for Portable-Linux may be written to an internal disk.
6. The installer must support both UEFI and a later BIOS/Legacy compatibility path; UEFI is the first implementation target.
7. Reboots and removal/reinsertion of the USB must preserve installed software, settings, users, projects, and files.

## Capacity behavior

Root receives all capacity left after the fixed EFI partition. Swap does not reserve a separate partition and therefore does not reduce the root partition size.

The 4 GiB swapfile is an upper bound, not a promise that 4 GiB is always allocated. The implementation may create a smaller file or omit it when RAM and policy do not require it.

## Hardware portability

The installed system must discover hardware at boot and use the target machine's available Linux drivers. The USB installation must not encode assumptions about one destination machine's internal storage, GPU, network interface, or display.

## Explicit non-goals for the first installer milestone

- No automatic repartitioning of internal disks.
- No separate /home partition.
- No fixed root size unrelated to the target capacity.
- No large bundled external datasets.
