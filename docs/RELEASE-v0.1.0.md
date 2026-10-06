# Protable-Linux v0.1.0

**Your Linux system. Your USB. Your workspace — portable.**

Protable-Linux v0.1.0 is the first public installer milestone of a persistent, USB-native Linux system. It installs a complete Debian-based desktop environment onto a USB drive so applications, settings, files, and projects can travel with the drive.

## ✨ Highlights

- Debian 13 (trixie) amd64 base
- Lightweight XFCE desktop with LightDM
- Persistent USB installation — not just a live session
- UEFI removable boot support
- Automatic root partition sizing
- One ext4 root filesystem with no separate /home partition
- ZRAM support with a persistent swapfile fallback
- Safety checks designed to prevent accidental internal-disk installation
- Hardware discovery at boot for use across compatible PCs
- Verified bootable ISO, checksum, and release manifest

## 💾 Recommended hardware

A 64 GB USB drive is a practical reference target for this release. The installer uses approximately 512 MiB for the EFI System Partition and assigns the remaining capacity to the root filesystem.

## 🚀 Quick start

1. Download the ISO below.
2. Verify its SHA-256 checksum.
3. Write the ISO to temporary installer media with a trusted ISO-writing tool.
4. Boot that media in UEFI mode.
5. Select the intended USB target carefully.
6. Run the Portable-Linux installer.
7. Boot from the newly installed USB and verify persistence.

> ⚠️ **WARNING:** Installing Portable-Linux erases the selected target USB drive. Never select an internal SSD/HDD.

## 📚 Installation guide

For a beginner-friendly, step-by-step installation procedure, read:

**docs/HELP-v0.1.0-INSTALL.txt**

## 📦 Release assets

- ISO: protable-linux-installer-amd64.iso
- Checksum: protable-linux-installer-amd64.iso.sha256
- Manifest: protable-linux-installer-amd64.manifest.txt

## 🔐 Verification

ISO SHA-256:

ad729eb14d74ec422b6439d539f7915a48866a2eeb0b78fcec046a2db8cf75ec

## ⚠️ v0.1.0 scope

This is the first installer milestone. UEFI is the primary supported boot path. BIOS/Legacy compatibility, full-root encryption, recovery tooling, and broader hardware validation are planned for subsequent releases.

Before using the system as your primary portable environment, test it on the target hardware and confirm boot, persistence, networking, storage, display, audio, and shutdown/reboot behavior.

**Have fun building a Linux system that actually travels with you.**
