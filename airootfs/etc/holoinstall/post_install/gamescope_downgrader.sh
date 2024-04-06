#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 0
fi

# Define mountpoint
MOUNT_DIR=/tmp/mount_chroot

# Detect holo partitions
ROOTPART=$(blkid | grep holo-root | cut -d ':' -f 1 | head -n 1)
if [ -n "${ROOTPART}" ]; then
    echo "Valid HoloISO Installation found"
else
    echo "HoloISO Installation wasn't found on this device"
    echo "Exiting..."
    sleep 5
    exit 1
fi

HOMEPART=$(blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)
EFIPART=$(blkid | grep HOLOEFI | cut -d ':' -f 1 | head -n 1)

# Unmount partitions before proceeding
CHK_MNT=$(lsblk | grep -e ${MOUNT_DIR} -e /mnt)
if [ -n "${CHK_MNT}" ]; then
    swapoff /mnt/home/swapfile 2>/dev/null
    umount -R /mnt
    umount -R $MOUNT_DIR
fi

# Create an mountpoint
if [ ! -d $MOUNT_DIR ]; then
    mkdir -p $MOUNT_DIR
fi

# Inform user about partition location
echo "Your HoloISO EFI Partition is located in ${EFIPART} partition."
echo "Your HoloISO Root Partition is located in ${ROOTPART} partition."
if [ -n "${HOMEPART}" ]; then
    echo "Your HoloISO Home Partition is located in ${HOMEPART} partition."
fi

# Mount partitions
mount "$ROOTPART" ${MOUNT_DIR}
if [ -n "${HOMEPART}" ]; then
    mount "$HOMEPART" ${MOUNT_DIR}/home
fi
mount "$EFIPART" ${MOUNT_DIR}/boot/efi

# Add env var to fix garphical corruptions
echo "INTEL_DEBUG=noccs" >>${MOUNT_DIR}/etc/environment

mkdir ${MOUNT_DIR}/pkgs
cp -r /etc/holoinstall/post_install/pkgs/* ${MOUNT_DIR}/pkgs

if arch-chroot ${MOUNT_DIR} pacman -Rdd --noconfirm gamescope-holoiso && arch-chroot ${MOUNT_DIR} pacman -U --noconfirm "$(arch-chroot "${MOUNT_DIR}" find /pkgs | grep gamescope-holoiso)"; then
    echo "Gamescope downgraded successfully."
    zenity --info --text="Gamescope downgraded successfully." --width=262 --height=1 2>/dev/null
else
    zenity --info --text="Gamescope downgrade failed." --width=210 --height=1 2>/dev/null
fi

rm -r ${MOUNT_DIR}/pkgs
