#!/bin/bash
# --------------------------------------------------------------
# Create Bootable Windows 10/11 USB on Linux
# Version: 1.0
# Author: Arint.ai
# Date: 10-05-2024
# License: GPL-3.0
# --------------------------------------------------------------

# Constants
ISO_MOUNT=$(mktemp -d)
VFAT_MOUNT=$(mktemp -d)
NTFS_MOUNT=$(mktemp -d)
BOOT_LABEL="BOOT"
INSTALL_LABEL="INSTALL"

# Error checking function
check_error() {
    if [ $? -ne 0 ]; then
        echo "Error occurred. Exiting..."
        cleanup
        exit 1
    fi
}

# Logging function
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Check for required commands
REQUIRED_COMMANDS=("rsync" "parted" "wipefs" "mkfs.vfat" "mkfs.ntfs" "udisksctl" "sha256sum" "mount" "umount" "mkdir" "cp" "sync" "mktemp")

log "Checking for required commands..."
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "Missing command $cmd. Please install the corresponding package and rerun this script."
        exit 1
    fi
done
log "All required commands are available."

# Input parameters: Path to the ISO file and USB block device location
ISO_PATH="$1"
USB_BLOCK="$2"

log "ISO Path is: $ISO_PATH"
log "USB block device is: $USB_BLOCK"

# Check if ISO path and USB block device are provided
if [ -z "$ISO_PATH" ] || [ -z "$USB_BLOCK" ]; then
    log "ISO path and USB block device are required."
    exit 1
fi

# Check if ISO file exists
if [ ! -f "$ISO_PATH" ]; then
    log "ISO file not found at $ISO_PATH."
    exit 1
fi

# Calculate ISO file checksum
log "Calculating ISO file checksum..."
ISO_CHECKSUM=$(sha256sum "$ISO_PATH")
log "Checksum is: $ISO_CHECKSUM"

# Warning about formatting and data loss
log "WARNING: All data on $USB_BLOCK will be lost!"
read -p "Are you sure you want to continue? [y/N]: " confirm
confirm=${confirm:-N}
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    log "Aborted by user."
    exit 1
fi

# Formatting the USB drive
log "Formatting USB drive..."
wipefs -a "$USB_BLOCK"

parted "$USB_BLOCK" mklabel gpt
parted "$USB_BLOCK" mkpart "$BOOT_LABEL" fat32 0% 1GiB
parted "$USB_BLOCK" mkpart "$INSTALL_LABEL" ntfs 1GiB 100%
parted "$USB_BLOCK" unit B print
check_error

# Mounting the ISO
log "Mounting ISO..."
udisksctl loop-setup -f "$ISO_PATH"
loop_device=$(lsblk -lno NAME,TYPE | awk '$2=="loop" {print $1}')
mount "/dev/$loop_device" "$ISO_MOUNT"
check_error

# Copying to USB
log "Copying to USB..."
mkfs.vfat -F32 -n "$BOOT_LABEL" "${USB_BLOCK}1"
mount "${USB_BLOCK}1" "$VFAT_MOUNT"
check_error

rsync -aHAX --info=progress2 --exclude='/$RECYCLE.BIN' --exclude='/System Volume Information' "$ISO_MOUNT/" "$VFAT_MOUNT/"
check_error

mkdir -p "$VFAT_MOUNT/sources"
cp "$ISO_MOUNT/sources/boot.wim" "$VFAT_MOUNT/sources/"
check_error

mkfs.ntfs --quick -L "$INSTALL_LABEL" "${USB_BLOCK}2"
mount "${USB_BLOCK}2" "$NTFS_MOUNT"
check_error

rsync -aHAX --info=progress2 --exclude='/$RECYCLE.BIN' --exclude='/System Volume Information' "$ISO_MOUNT/" "$NTFS_MOUNT/"
check_error

# Unmounting and power off
log "Unmounting drives and syncing data... This may take a while, do not disconnect your USB drive."
umount "$NTFS_MOUNT"
umount "$VFAT_MOUNT"
umount "$ISO_MOUNT"
sync

# Remove temporary mount directories
rmdir "$ISO_MOUNT" "$VFAT_MOUNT" "$NTFS_MOUNT"
check_error

udisksctl loop-delete -b "$loop_device"

udisksctl power-off -b "$USB_BLOCK"
check_error

log "Done! You can now safely disconnect your USB drive."
