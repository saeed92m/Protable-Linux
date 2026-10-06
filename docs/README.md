# Documentation

Protable-Linux documentation for the current project and v0.1.0 release.

## Start Here

- [v0.1.0 Installation Guide](HELP-v0.1.0-INSTALL.txt) — beginner-friendly installation, verification, first boot, persistence, and troubleshooting.
- [v0.1.0 Release Notes](RELEASE-v0.1.0.md) — release scope, highlights, limitations, and verification status.
- [Installer Guide](installer.md) — installer behavior, safety guards, target validation, partitioning, and boot installation.
- [Release Acceptance](release-acceptance.md) — acceptance criteria for a production release.

## System Design

- [Architecture](architecture.md) — system structure and major components.
- [Hardware Target](hardware-target.md) — supported hardware goals and validation priorities.
- [Storage Layout](storage-layout.md) — USB partition and filesystem contract.
- [Portability](portability.md) — portability model, hardware discovery, and cross-machine expectations.

## Project Direction

- [Roadmap](roadmap.md) — current milestones and future development direction.

## v0.1.0 Status

v0.1.0 is the first public installer milestone. It provides a Debian 13 (trixie) amd64 installer/live environment and installs a persistent XFCE-based Linux system to a USB drive.

The current release is **UEFI-first**. BIOS/Legacy boot, full-root encryption, recovery tooling, broader hardware validation, and additional persistence hardening remain roadmap items.

## Safety

The installer is destructive to the selected target device. Always identify the USB target by device path, model, size, transport, and mountpoints before installation. Never select an internal SSD/HDD.

For the actual installation procedure, start with the [v0.1.0 Installation Guide](HELP-v0.1.0-INSTALL.txt).
