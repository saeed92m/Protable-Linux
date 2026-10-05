# Protable-Linux

Ultra-lightweight, portable Debian-based Linux designed to run as a complete personal operating system directly from USB.

## Project goals

- Full installed system on removable USB storage, not live-only media.
- Persistent OS, files and settings.
- Single ext4 root filesystem containing `/home`.
- ZRAM-first memory management.
- Conservative emergency disk swap.
- UEFI support and Legacy BIOS support where practical.
- Broad x86-64 hardware portability.
- Minimal desktop footprint and low unnecessary disk writes.

## Initial target

**HP v150w 64 GB USB flash drive** (~58.5 GiB observed capacity).

See [docs](docs/README.md) for the architecture, storage model, portability requirements and roadmap.

> Protable-Linux is intentionally independent from Alpha-Linux and ztf-classifier.
