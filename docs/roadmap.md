# Roadmap

## Phase 0 — Project foundation
- [x] Define portable installed-USB architecture
- [x] Define single-root storage model
- [x] Define ZRAM-first memory policy
- [x] Define emergency disk-swap policy
- [x] Define UEFI/Legacy portability target
- [x] Record HP v150w 64 GB reference device

## Phase 1 — Minimal base
- [ ] Select exact antiX/Debian release
- [ ] Build reproducible installation procedure
- [ ] Create USB partitioning and boot setup
- [ ] Configure ZRAM
- [ ] Configure conservative emergency swap
- [ ] Configure lightweight desktop
- [ ] Validate persistence

## Phase 2 — Portability validation
- [ ] UEFI boot test
- [ ] Legacy BIOS boot test
- [ ] Hardware detection test
- [ ] Network/Wi-Fi test
- [ ] Graphics/session test
- [ ] Suspend/resume test where supported
- [ ] Reboot persistence test

## Phase 3 — Release
- [ ] Document installation/recovery
- [ ] Produce checksummed release image or installer
- [ ] Define versioning and release contract
- [ ] Publish first portable base release
