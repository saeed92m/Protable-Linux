# Release Acceptance — Portable Persistent USB

A release candidate is not accepted until all of these are demonstrated:

- [ ] Boots from the USB target in UEFI mode.
- [ ] EFI and root partitions are both on the USB target.
- [ ] Root is ext4 and consumes all non-EFI capacity.
- [ ] No separate /home partition exists.
- [ ] Installed application survives reboot.
- [ ] User-created file survives reboot.
- [ ] User settings survive reboot.
- [ ] USB can boot on a second compatible machine without reinstalling.
- [ ] Internal destination disk remains unchanged.
- [ ] Swap policy works and never exceeds the 4 GiB persistent fallback limit.
- [ ] Installer refuses ambiguous or missing target devices.
- [ ] Integrity/recovery checks complete successfully.

Evidence must record target device identity, partition table, filesystem UUIDs, boot mode, and persistence checks without committing user data to the repository.
