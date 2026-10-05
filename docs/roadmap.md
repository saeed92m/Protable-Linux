# Roadmap

## Phase 0 — Project foundation
- [x] Define portable installed-USB architecture
- [x] Define single-root storage model
- [x] Define ZRAM-first memory policy
- [x] Define emergency disk-swap policy
- [x] Define UEFI/Legacy portability target
- [x] Record HP v150w 64 GB reference device

## Phase 1 — Persistent USB implementation
- [x] Define 512 MiB EFI + single ext4 Root contract
- [x] Define in-root swapfile contract (0–4 GiB)
- [x] Add non-destructive target validation
- [x] Add guarded USB installer foundation
- [x] Add first-boot swap policy
- [x] Add CI shell/contract checks
- [ ] Select exact Debian base release
- [ ] Build reproducible minimal root filesystem
- [ ] Integrate GRUB and removable UEFI boot
- [ ] Configure ZRAM
- [ ] Configure lightweight desktop/session
- [ ] Produce first bootable image

## Phase 2 — Hardware and persistence validation
- [ ] UEFI boot test on HP v150w
- [ ] Reboot persistence test
- [ ] Install/update application and verify persistence
- [ ] File/settings persistence test
- [ ] Boot on a second compatible x86-64 machine
- [ ] Network/Wi-Fi validation
- [ ] Intel/AMD/NVIDIA graphics validation
- [ ] Legacy BIOS validation

## Phase 3 — Safety, recovery and release
- [ ] Recovery environment
- [ ] Optional full-root encryption
- [ ] Integrity/recovery checks
- [ ] Deterministic release image
- [ ] SHA-256 checksums and release manifest
- [ ] Installation/recovery documentation
- [ ] First public portable release
