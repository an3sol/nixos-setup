# NixOS Installation Guide
Auto-deploy some open parts of my NixOS setup

## Prepare Bootable USB

### Copy Image to Flash Drive
Use `dd` to copy the image file to the flash drive:

```bash
sudo dd if=/path/to/your/image.iso of=/dev/sdX bs=4M status=progress && sync
```

**Important Notes:**
- Replace `/path/to/your/image.iso` with the actual path to your NixOS ISO
- Replace `/dev/sdX` with the correct device name for your flash drive (e.g., `/dev/sdb`)
- Be extremely careful to select the correct drive to avoid data loss

## Installation Process

### On Installation Machine

1. Set SSH Password (for remote install)
```bash
passwd
```

2. Connect via SSH (for remote install)
```bash
ssh nixos@10.1.2.34
```

3. Enter Root
```bash
sudo su
```

4. Load and Execute Install Script
```bash
curl git.raw > install.sh && chmod +x install.sh && ./install.sh
```

**Caution:** 
- Ensure you trust the source of the `install.sh` script
- Review the script contents before executing


## PRO tips
```bash
sudo dd if=/path/to/your/image.iso of=/dev/sdX bs=4M status=progress && sync
passwd
ssh nixos@10.1.2.34
sudo su 
curl git.raw > install.sh && ./install.sh
```
