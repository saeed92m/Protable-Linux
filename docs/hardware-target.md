# Hardware Target

## Initial reference device
- USB device: HP v150w
- Advertised capacity: 64 GB
- Observed capacity: approximately 58.5 GiB
- Media type: USB flash drive, not SSD

## Portability target
The installed system should boot on compatible x86-64 PCs without relying on the hardware configuration of the development machine.

Hardware-specific proprietary drivers must not be baked into the base image unless required. The base system should prefer broadly supported kernel/firmware packages and detect hardware at boot.

USB flash performance and write endurance are constraints; the system should minimize unnecessary disk writes.
