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
    readarray -t DISKS < <(lsblk -d -o NAME,SIZE,TYPE,MODEL | grep 'disk' | grep -v 'loop')

    if [ ${#DISKS[@]} -eq 0 ]; then
        error "No suitable disks found."
    fi

    for i in "${!DISKS[@]}"; do
        echo "$((i+1))) ${DISKS[i]}"
    done

    read -p "Select disk number: " disk_choice

    # Enhanced input validation
    if [[ ! "$disk_choice" =~ ^[0-9]+$ ]] || [[ "$disk_choice" -lt 1 ]] || [[ "$disk_choice" -gt "${#DISKS[@]}" ]]; then
        error "Invalid disk selection."
    fi

    DISK_NAME=$(echo "${DISKS[$((disk_choice-1))]}" | awk '{print $1}')
    SELECTED_DISK="/dev/$DISK_NAME"

    log "Selected Disk: $SELECTED_DISK"
}

# Confirm disk wipe with additional safety
confirm_wipe() {
    read -p "WARNING: This will ERASE ALL DATA on $SELECTED_DISK. Type 'yes' to confirm: " confirm
    [[ "$confirm" == "yes" ]] || error "Installation cancelled."
}

# Partition disk with robust partitioning
partition_disk() {
    log "Clearing existing partition table..."
    wipefs -af "$SELECTED_DISK"
    sgdisk -Zo "$SELECTED_DISK"

    log "Creating EFI partition (512MB)..."
    sgdisk -n1:1M:+512M -t1:EF00 "$SELECTED_DISK"
    EFI_PART="${SELECTED_DISK}1"

    log "Creating ZFS partition (remaining space)..."
    sgdisk -n2:0:0 -t2:bf01 "$SELECTED_DISK"
    ZFS_PART="${SELECTED_DISK}2"

    # Update the kernel partition table
    partprobe "$SELECTED_DISK"
    udevadm settle
    sleep 3
}

# Create encrypted ZFS pool with advanced settings
create_zpool() {
    log "Creating encrypted ZFS pool..."
    zpool create -f \
        -O acltype=posixacl \
        -O xattr=sa \
        -o ashift=12 \
        -o autoexpand=on \
        -o autotrim=on \
        -R /mnt \
        -O atime=off \
        -O sync=standard \
        -O compression=zstd \
        -O encryption=aes-256-gcm \
        -O keylocation=prompt \
        -O keyformat=passphrase \
        zpool "$ZFS_PART"
}

# Format EFI partition
format_efi() {
    log "Formatting EFI partition..."
    mkfs.vfat -F 32 "$EFI_PART"
}

# Create datasets and set reservations
create_datasets_and_mount() {
    log "Creating ZFS datasets and setting reservations..."

    # Create datasets with 'legacy' mountpoint
    zfs create -o mountpoint=legacy zpool/root
    zfs create -o mountpoint=legacy zpool/nix
    zfs create -o mountpoint=legacy zpool/var
    zfs create -o mountpoint=legacy zpool/home

    # Set reservations
    zfs set reservation=10G zpool/root
    zfs set reservation=20G zpool/nix
    zfs set reservation=10G zpool/var
    zfs set reservation=20G zpool/home

    # Mount filesystems manually
    mkdir -p /mnt
    mount -t zfs zpool/root /mnt
    mkdir /mnt/{nix,var,home}
    mount -t zfs zpool/nix /mnt/nix
    mount -t zfs zpool/var /mnt/var
    mount -t zfs zpool/home /mnt/home
}


# Prepare for NixOS installation
prepare_nixos() {
    log "Generating NixOS configuration..."
    mkdir -p /mnt/boot
    mount "$EFI_PART" /mnt/boot

    nixos-generate-config --root /mnt

    log "Configuration generated."
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Edit /mnt/etc/nixos/configuration.nix"
    echo "2. Customize ZFS and encryption settings"
    echo "3. Run 'nixos-install'"
}

# Main installation script
main() {
    [[ "$(id -u)" -eq 0 ]] || error "Must be run as root."

    local REQUIRED_TOOLS=(zpool zfs sgdisk wipefs mkfs.vfat nixos-generate-config lsblk)
    for cmd in "${REQUIRED_TOOLS[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || error "Missing $cmd command."
    done

    trap 'error "Script failed at line $LINENO."' ERR

    select_disk
    confirm_wipe
    partition_disk
    format_efi
    create_zpool
    create_datasets_and_mount
    prepare_nixos

    log "ZFS NixOS installation setup complete!"
}

main

#echo "# the zfsutil option is needed when mounting zfs datasets without "legacy" mountpoints"
#echo "Now check the hardware-configuration.nix in /mnt/etc/nixos/hardware-configuration.nix"
#echo " add options = [ "zfsutil" ];"
