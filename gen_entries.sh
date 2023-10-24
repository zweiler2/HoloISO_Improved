#!/bin/bash

PROFILEDIR=$1
count=1
find "${PROFILEDIR}"/efiboot/loader/entries -type f -delete
find "${PROFILEDIR}"/airootfs/etc/mkinitcpio.d -type f -delete
sed -i '/# Kernels/q' "${PROFILEDIR}"/packages.x86_64

while read -r input; do
	echo "$input" | tr ' ' '\n' >>"${PROFILEDIR}"/packages.x86_64
	kernel=$(echo "$input" | cut -d ' ' -f 1)
	if [[ "$kernel" = linux-neptune* ]]; then
		echo -e "title   HoloISO installer (${kernel}, Deck kernel, Copy to RAM)\nlinux   /%INSTALL_DIR%/boot/x86_64/vmlinuz-${kernel}\ninitrd  /%INSTALL_DIR%/boot/intel-ucode.img\ninitrd  /%INSTALL_DIR%/boot/amd-ucode.img\ninitrd  /%INSTALL_DIR%/boot/x86_64/initramfs-${kernel}.img\noptions splash plymouth.nolog archisobasedir=%INSTALL_DIR% archisolabel=%ARCHISO_LABEL% cow_spacesize=10G copytoram" >"${PROFILEDIR}"/efiboot/loader/entries/$count-"$kernel"-copytoram.conf
		count=$((count + 1))
		echo -e "title   HoloISO installer (${kernel}, Deck kernel)\nlinux   /%INSTALL_DIR%/boot/x86_64/vmlinuz-${kernel}\ninitrd  /%INSTALL_DIR%/boot/intel-ucode.img\ninitrd  /%INSTALL_DIR%/boot/amd-ucode.img\ninitrd  /%INSTALL_DIR%/boot/x86_64/initramfs-${kernel}.img\noptions splash plymouth.nolog archisobasedir=%INSTALL_DIR% archisolabel=%ARCHISO_LABEL%" >"${PROFILEDIR}"/efiboot/loader/entries/$count-"$kernel".conf
		count=$((count + 1))
	else
		echo -e "title   HoloISO installer (${kernel}, Copy to RAM)\nlinux   /%INSTALL_DIR%/boot/x86_64/vmlinuz-${kernel}\ninitrd  /%INSTALL_DIR%/boot/intel-ucode.img\ninitrd  /%INSTALL_DIR%/boot/amd-ucode.img\ninitrd  /%INSTALL_DIR%/boot/x86_64/initramfs-${kernel}.img\noptions splash plymouth.nolog archisobasedir=%INSTALL_DIR% archisolabel=%ARCHISO_LABEL% cow_spacesize=10G copytoram" >"${PROFILEDIR}"/efiboot/loader/entries/$count-"$kernel"-copytoram.conf
		count=$((count + 1))
		echo -e "title   HoloISO installer (${kernel})\nlinux   /%INSTALL_DIR%/boot/x86_64/vmlinuz-${kernel}\ninitrd  /%INSTALL_DIR%/boot/intel-ucode.img\ninitrd  /%INSTALL_DIR%/boot/amd-ucode.img\ninitrd  /%INSTALL_DIR%/boot/x86_64/initramfs-${kernel}.img\noptions splash plymouth.nolog archisobasedir=%INSTALL_DIR% archisolabel=%ARCHISO_LABEL%" >"${PROFILEDIR}"/efiboot/loader/entries/$count-"$kernel".conf
		count=$((count + 1))
	fi
	echo -e "PRESETS=('archiso')\n\nALL_kver='/boot/vmlinuz-${kernel}'\nALL_config='/etc/mkinitcpio.conf'\n\narchiso_image=\"/boot/initramfs-${kernel}.img\"" >"${PROFILEDIR}"/airootfs/etc/mkinitcpio.d/"${kernel}".preset
done <"${PROFILEDIR}"/kernel_list.bootstrap
