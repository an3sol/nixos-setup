#!/usr/bin/env bash

set -euo pipefail

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "\n${GREEN}==>${NC} $1"
}

error() {
    echo -e "\n${RED}ERROR:${NC} $1" >&2
    exit 1
}

# Disk selection with improved error handling
select_disk() {
    log "Available Disks:"
    readarray -t DISKS < <(lsblk -d -o NAME,SIZE,TYPE | grep 'disk' | awk '{print $1}')
    
    if [ ${#DISKS[@]} -eq 0 ]; then
        error "No suitable disks found"
    fi

    for i in "${!DISKS[@]}"; do
        # Get full disk info
        DISK_INFO=$(lsblk -d -o NAME,SIZE,TYPE,MODEL "/dev/${DISKS[i]}")
        echo "$((i+1))) $DISK_INFO"
    done

    read -p "Select disk number: " disk_choice
    
    # Enhanced input validation
    if [[ ! "$disk_choice" =~ ^[0-9]+$ ]] || 
       [[ "$disk_choice" -lt 1 ]] || 
       [[ "$disk_choice" -gt "${#DISKS[@]}" ]]; then
        error "Invalid disk selection"
    fi

    SELECTED_DISK="/dev/${DISKS[$((disk_choice-1))]}"
    DISK_NAME="${DISKS[$((disk_choice-1))]}"
    
    # Get total disk size using lsblk
    DISK_SIZE=$(lsblk -b -n -o SIZE "$SELECTED_DISK" | awk '{print $1}')
    RESERVE_SIZE=$((DISK_SIZE * 20 / 100))
    
    log "Selected Disk: $DISK_NAME"
    log "Total Disk Size: $((DISK_SIZE / 1024 / 1024 / 1024)) GB"
    log "Reserve Size (20%): $((RESERVE_SIZE / 1024 / 1024 / 1024)) GB"
}

# Confirm disk wipe with additional safety
confirm_wipe() {
    read -p "WARNING: This will ERASE ALL DATA on $DISK_NAME. Type 'YES' to confirm: " confirm
    [[ "$confirm" == "YES" ]] || error "Installation cancelled"
}

# Modify partition_disk() function
partition_disk() {
    log "Clearing existing partition table"
    wipefs -af "$SELECTED_DISK"
    sgdisk -Zo "$SELECTED_DISK"

    log "Creating EFI partition (512MB)"
    sgdisk -n1:1M:+512M -t1:EF00 "$SELECTED_DISK"
    EFI_PART="${SELECTED_DISK}1"

    log "Creating ZFS partition (remaining space)"
    sgdisk -n2:0:0 -t2:bf01 "$SELECTED_DISK"
    ZFS_PART="${SELECTED_DISK}2"

    # Robust kernel partition table update
    partprobe "$SELECTED_DISK"
    udevadm settle
    sleep 3
}

# ZFS Cleanup function
zfs_cleanup() {
    log "Cleaning up ZFS mounts and exporting pool"
    
    # Unmount all ZFS filesystems
    zfs umount -a
    
    # Export the pool
    zpool export zroot
}

# Create encrypted ZFS pool with advanced settings
create_zpool() {
    log "Creating Encrypted ZFS Pool with NVMe Optimizations"
    
    # Encryption setup
    read -sp "Enter encryption passphrase: " ENCRYPTION_PASSPHRASE
    echo

    # Advanced ZFS pool creation
    zpool create -f \
        -O acltype=posixacl \
        -O xattr=sa \
        -o ashift=12 \
        -o autoexpand=on \
        -o autotrim=on \
        -R /mnt \
        -O atime=off \
        -O sync=standard \
        -O compression=zstd-3 \
        -O encryption=on \
        -O keylocation=prompt \
        -O keyformat=passphrase \
        -O mountpoint=none \
        -o recordsize=128k \
        -o relatime=on \
        zroot "$ZFS_PART"

    # Create encrypted root dataset
    zfs create \
        -o encryption=on \
        -o keylocation=prompt \
        -o keyformat=passphrase \
        -o mountpoint=/ \
        zroot/root

    # Create additional datasets with reserve space
    local DATASET_RESERVE=$((RESERVE_SIZE / 5))
    
    zfs create -o mountpoint=/nix zroot/nix
    zfs set reservation="$DATASET_RESERVE" zroot/nix

    zfs create -o mountpoint=/var zroot/var
    zfs set reservation="$DATASET_RESERVE" zroot/var

    zfs create -o mountpoint=/home zroot/home
    zfs set reservation="$DATASET_RESERVE" zroot/home
}

# Format EFI partition
format_efi() {
    log "Formatting EFI partition"
    mkfs.vfat -F 32 "$EFI_PART"
}

# Mount filesystems
mount_filesystems() {
    log "Mounting Filesystems"
    
    # Mount root
    zfs mount zroot/root
    
    # Create and mount boot
    mkdir -p /mnt/boot
    mount "$EFI_PART" /mnt/boot
    
    # Mount other datasets
    zfs mount zroot/nix
    zfs mount zroot/var
    zfs mount zroot/home
}

# Prepare for NixOS installation
prepare_nixos() {
    log "Preparing NixOS Installation"
    
    # Generate hardware configuration
    nixos-generate-config --root /mnt
    
    log "Hardware configuration generated"
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Edit /mnt/etc/nixos/configuration.nix"
    echo "2. Customize ZFS and encryption settings"
    echo "3. Install NixOS: nixos-install"
}

# Main installation script
main() {
    # Root check
    [[ "$(id -u)" -eq 0 ]] || error "Must be run as root"

    # Dependency check
    local REQUIRED_TOOLS=(zpool zfs sgdisk wipefs mkfs.vfat nixos-generate-config)
    for cmd in "${REQUIRED_TOOLS[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || error "Missing $cmd command"
    done

    # Catch any unexpected errors
    trap 'error "Script failed at line $LINENO"' ERR

    # Installation steps
    select_disk
    confirm_wipe
    partition_disk
    format_efi
    create_zpool
    mount_filesystems
    
    # Clean up ZFS mounts and export pool
    zfs_cleanup
    
    # Prepare for NixOS installation
    prepare_nixos

    echo -e "\n${GREEN}ZFS NixOS Installation Preparation Complete!${NC}"
}

# Execute main script
main
