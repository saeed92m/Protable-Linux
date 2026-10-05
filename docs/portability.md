# Portability

## Boot target
The project targets compatible x86-64 systems with:
- UEFI firmware
- Legacy BIOS where practical
- USB boot support

## Portability principles
1. Keep the base image hardware-neutral.
2. Use a generic kernel and broad Debian firmware support.
3. Avoid machine-specific configuration in the image.
4. Detect graphics, network, storage and input hardware during boot.
5. Test both UEFI and Legacy BIOS paths.
6. Validate persistence after reboot on the USB device.

## Known constraint
A USB flash drive can be moved between machines, but firmware, Wi-Fi, GPU and proprietary-driver compatibility cannot be guaranteed for every PC.
