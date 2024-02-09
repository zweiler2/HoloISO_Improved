#!/bin/bash
# Simple chrooter for stuff

# Define mountpoint
MOUNT_DIR=/tmp/mount_chroot

# Detect holo partitions
ROOTPART=$(sudo blkid | grep holo-root | cut -d ':' -f 1 | head -n 1)
if [ -n "${ROOTPART}" ]; then
	echo "Valid HoloISO Installation found"
else
    echo "HoloISO Installation wasn't found on this device"
    echo "Exiting..."
    sleep 5
    exit 1
fi

HOMEPART=$(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)
EFIPART=$(sudo blkid | grep HOLOEFI | cut -d ':' -f 1 | head -n 1)

# Re-mount stuff before proceeding
CHK_MNT=$(lsblk | grep -e ${MOUNT_DIR} -e /mnt)
if [ -n "${CHK_MNT}" ]; then
    sudo swapoff /mnt/home/swapfile 2>/dev/null
    sudo umount -R /mnt
    sudo umount -R $MOUNT_DIR
fi

# Create an mountpoint
if [ ! -d $MOUNT_DIR ]; then
    sudo mkdir -p $MOUNT_DIR
fi

# Inform user about partition location
echo "Your HoloISO EFI Partition is located in ${EFIPART} partition."
echo "Your HoloISO Root Partition is located in ${ROOTPART} partition."
if [ -n "${HOMEPART}" ]; then
    echo "Your HoloISO Home Partition is located in ${HOMEPART} partition."
fi

# Mount partitions
sudo mount "$ROOTPART" ${MOUNT_DIR}
if [ -n "${HOMEPART}" ]; then
    sudo mount "$HOMEPART" ${MOUNT_DIR}/home
fi
sudo mount "$EFIPART" ${MOUNT_DIR}/boot/efi

# Check for version
echo "Your HoloISO Installation version: $(cat ${MOUNT_DIR}/etc/os-release | grep VARIANT_ID | cut -d '"' -f 2)"
echo "Currently installed kernel versions: $(cat ${MOUNT_DIR}/usr/src/linux*/version)"
echo "Most used commands:"
echo "steamos-update [check|now] -- Checks for OS updates and applies them"
echo "holoiso-[enable|disable]-sessions -- Disables session autologin"
echo "holoiso-grub-update -- Reinstalls and updates grub configuration"
echo 
echo "Commands available for logged-in user:"
echo "steamos-session-select [plasma|gamescope|plasma-x11-persistent] -- Select a session to boot into next time"

# Chroot!
sudo arch-chroot ${MOUNT_DIR}
