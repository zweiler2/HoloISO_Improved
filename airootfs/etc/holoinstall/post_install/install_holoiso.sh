#!/bin/bash
# HoloISO Installer v2
# This defines all of the current variables.
HOLO_INSTALL_DIR="${HOLO_INSTALL_DIR:-/mnt}"
IS_WIN600=$(grep </sys/devices/virtual/dmi/id/product_name Win600)
IS_STEAMDECK=$(grep </sys/devices/virtual/dmi/id/product_name Jupiter)
IS_OXP2=$(grep </sys/devices/virtual/dmi/id/product_name "OneXPlayer 2")

if [ -n "${IS_WIN600}" ]; then
	IS_WIN600=true
else
	IS_WIN600=false
fi

if [ -n "${IS_STEAMDECK}" ]; then
	IS_STEAMDECK=true
else
	IS_STEAMDECK=false
fi

if [ -n "${IS_OXP2}" ]; then
	IS_OXP2=true
else
	IS_OXP2=false
fi

check_mount() {
	if [ "$1" != 0 ]; then
		printf "\nError: Something went wrong when mounting %s partitions. Please try again! \n" "$2"
		echo "Press any key to exit..."
		read -n 1 -s -r
		exit 1
	fi
}

information_gathering() {
	if grep -x "en_US.UTF-8 UTF-8  " /etc/locale.gen >/dev/null; then
		sudo sed -i 's/en_US.UTF-8 UTF-8/#en_US.UTF-8 UTF-8/' /etc/locale.gen
	fi
	# Ask for temp keyboard layout
	while true; do
		if TEMP_LANG=$(localectl list-x11-keymap-layouts --no-pager | awk '{ printf "FALSE""\0"$0"\0" }' | zenity --list --radiolist --width=450 --height=700 --title="Keyboard layout" --text="Select a keyboard layout to use while using the installer" --multiple --column '' --column 'Keyboard layouts' 2>/dev/null); then
			if [ -n "$TEMP_LANG" ]; then
				break
			else
				zenity --info --title="Keyboard layout" --text='Please select a keyboard layout!' 2>/dev/null
			fi
		else
			exit 1
		fi
	done
	setxkbmap "$TEMP_LANG"

	# Ask for the timezone
	while true; do
		if TIMEZONE=$(timedatectl list-timezones --no-pager | awk '{ printf "FALSE""\0"$0"\0" }' | zenity --list --radiolist --width=450 --height=700 --title="Timezone" --text="Select your timezone below:\n " --multiple --column '' --column 'Timezones' 2>/dev/null); then
			if [ -n "$TIMEZONE" ]; then
				break
			else
				zenity --info --title="Timezone" --text='Please select a timezone!' 2>/dev/null
			fi
		else
			exit 1
		fi
	done

	# Ask for languages
	while true; do
		if LANGUAGES_ALL=$(cut </etc/locale.gen -c2- | tail -n +18 | awk '{ printf "FALSE""\0"$0"\0" }' | zenity --list --width=450 --height=700 --title="Select Languages" --text="Select your desired languages below:\n(UTF-8 is preferred)" --checklist --multiple --column '' --column 'Languages' 2>/dev/null); then
			if [ -n "$LANGUAGES_ALL" ]; then
				break
			else
				zenity --info --title="Select Languages" --text='Please select at least one language!' 2>/dev/null
			fi
		else
			exit 1
		fi
	done

	# Ask for main language
	while true; do
		if MAIN_LANGUAGE=$(echo "$LANGUAGES_ALL" | tr "|" "\n" | awk '{ printf "FALSE""\0"$0"\0" }' | zenity --list --radiolist --width=450 --height=700 --title="Select Language" --text="Select your desired main language below:" --multiple --column '' --column 'Language' 2>/dev/null); then
			if [ -n "$MAIN_LANGUAGE" ]; then
				break
			else
				zenity --info --title="Select Language" --text='Please select a language!' 2>/dev/null
			fi
		else
			exit 1
		fi
	done

	# Ask for keyboard layouts
	while true; do
		if KEYBOARD_LAYOUT=$(localectl list-keymaps --no-pager | awk '{ printf "FALSE""\0"$0"\0" }' | zenity --list --radiolist --width=450 --height=700 --title="Keyboard layout" --text="Select your desired keyboard layout below:" --multiple --column '' --column 'Keyboard layouts' 2>/dev/null); then
			if [ -n "$KEYBOARD_LAYOUT" ]; then
				break
			else
				zenity --info --title="Keyboard layout" --text='Please select a keyboard layout!' 2>/dev/null
			fi
		else
			exit 1
		fi
	done
	while true; do
		if KEYBOARD_LAYOUT_X11=$(localectl list-x11-keymap-layouts --no-pager | awk '{ printf "FALSE""\0"$0"\0" }' | zenity --list --radiolist --width=450 --height=700 --title="X11 Keyboard layout" --text="Select your desired X11 keyboard layout below:" --multiple --column '' --column 'X11 Keyboard layouts' 2>/dev/null); then
			if [ -n "$KEYBOARD_LAYOUT_X11" ]; then
				break
			else
				zenity --info --title="Keyboard layout" --text='Please select a keyboard layout!' 2>/dev/null
			fi
		else
			exit 1
		fi
	done

	# Ask for swapfile size
	while true; do
		if SWAPSIZE=$(printf "1GB\n2GB\n4GB\n8GB\n16GB" | awk '{ printf "FALSE""\0"$0"\0" }' | zenity --list --radiolist --title="SWAP" --text="How big do you want your swapfile?\n(8GB is recommended)" --multiple --column '' --column '' --width=275 --height=438 2>/dev/null); then
			if [ -n "$SWAPSIZE" ]; then
				break
			else
				zenity --info --title="SWAP" --text='Please select a size!' 2>/dev/null
			fi
		else
			exit 1
		fi
	done
	case $SWAPSIZE in
	1GB) SWAPSIZE=1024 ;;
	2GB) SWAPSIZE=2048 ;;
	4GB) SWAPSIZE=4096 ;;
	8GB) SWAPSIZE=8192 ;;
	16GB) SWAPSIZE=16384 ;;
	esac

	# Ask for xone-dkms-git driver
	if zenity --question --title="Xbox One gamepad driver" --text='Do you want to install the Xbox One gamepad driver?\n\nThe firmware for the wireless dongle is subject to Microsofts Terms of Use:\n<a href="https://www.microsoft.com/en-us/legal/terms-of-use">Microsofts Terms of Use</a>\n\nDo you agree to Microsofts Terms of Use and want to install the driver?\n\nNote: This requires an internet connection.' --width=514 2>/dev/null; then
		INSTALL_XONE_DRIVER=true
	else
		INSTALL_XONE_DRIVER=false
	fi

	# Ask for 8bitdo-ultimate-controller-udev rules
	if zenity --question --title="8bitdo ultimate controller" --text='Do you want to install the udev rules for the 8bitdo ultimate controller?' --width=487 2>/dev/null; then
		INSTALL_8BITDO_UDEV_RULES=true
	else
		INSTALL_8BITDO_UDEV_RULES=false
	fi

	# Ask for decky loader
	if zenity --question --title="Decky loader" --text='Do you want to install decky loader?\n(This requires an internet connection)' --width=256 2>/dev/null; then
		INSTALL_DECKY_LOADER=true
	else
		INSTALL_DECKY_LOADER=false
	fi

	# Ask for emudeck
	if zenity --question --title="EmuDeck" --text='Do you want to install EmuDeck?\n(This requires an internet connection)' --width=256 2>/dev/null; then
		INSTALL_EMUDECK=true
	else
		INSTALL_EMUDECK=false
	fi

	# Ask for Steam Patch
	if zenity --question --title="Steam Patch" --text='Do you want to install <a href="https://github.com/corando98/steam-patch">steam-patch</a> by corando98?\nThis integrates some fixes for the ASUS ROG Ally, OneXPlayer 2 and Legion Go.\n(This requires an internet connection)' --width=342 2>/dev/null; then
		INSTALL_STEAM_PATCH=true
	else
		INSTALL_STEAM_PATCH=false
	fi

	# Ask for laptop
	if zenity --question --title="Laptop" --text='Is this system a laptop?' 2>/dev/null; then
		IS_LAPTOP=true
	else
		IS_LAPTOP=false
	fi
}

partitioning() {
	echo "Select your drive in popup:"
	while true; do
		DRIVEDEVICE=$(lsblk -d -o NAME | sed "1d" | sed '/sr/d' | sed '/loop/d' | awk '{ printf "FALSE""\0"$0"\0" }' |
			xargs -0 zenity --list --width=600 --height=512 --title="Select disk" --text="Select your disk to install HoloISO in below:\n\n $(lsblk -d -o NAME,MAJ:MIN,RM,SIZE,RO,TYPE,VENDOR,MODEL,SERIAL,MOUNTPOINT | sed '/sr/d' | sed '/loop/d')" --radiolist --multiple --column ' ' --column 'Disks' --height=700 2>/dev/null)
		DEVICE="/dev/${DRIVEDEVICE}"
		INSTALLDEVICE="${DEVICE}"
		if [ -b "$DEVICE" ] && lsblk "$DEVICE" | head -n2 | tail -n1 | grep disk >/dev/null 2>&1; then
			echo "$DEVICE found and is of type disk. Continuing installation..."
			break
		elif [ ! -b "$DEVICE" ]; then
			echo "$DEVICE not found! Please try again"
		elif lsblk "$DEVICE" | head -n2 | tail -n1 | grep disk >/dev/null 2>&1; then
			echo "$DEVICE is not of type disk!"
		fi
	done

	echo "Choose your installation type:"
	while true; do
		install=$(zenity --list --title="Choose your installation type:" --column="Type" --column="Name" 1 "Use entire drive/option to reuse home partition if found" 2 "Install alongside existing OS/Partition (Requires at least 50 GB of free unformatted space at the end of the drive)" --width=880 --height=281 2>/dev/null)
		if [ -z "$install" ]; then
			exit 0
		else
			break
		fi
	done
	HOME_REUSE=false
	HOME_PART_EXISTS=false
	tmp_home_part=$(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)
	if [[ -n "$tmp_home_part" && $tmp_home_part =~ $INSTALLDEVICE ]]; then
		HOME_PART_EXISTS=true
		HOME_REUSE_TYPE=$(zenity --list --title="Warning" --text="A HoloISO home partition was detected at $(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1).\nPlease select an appropriate action below:" --column="Type" --column="Name" 1 "Format it and start over" 2 "Reuse partition" --width=450 --height=302 2>/dev/null)
		if [[ "${HOME_REUSE_TYPE}" == "2" ]]; then
			HOME_REUSE=true
			mkdir -p /tmp/home
			mount "$(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)" /tmp/home
			mkdir -p /tmp/rootpart
			mount "$(sudo blkid | grep holo-root | cut -d ':' -f 1 | head -n 1)" /tmp/rootpart
			HOLOUSER=$(grep home </tmp/rootpart/etc/passwd | cut -d ':' -f 1)
			if [[ -d "/tmp/home/.steamos" ]]; then
				echo "Migration data found. Proceeding"
			else
				zenity --progress --title="Preparing to reuse home at $(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)" --text="Your installation will reuse following user: ${HOLOUSER} \n\nStarting to move following directories to target offload ():\
					\n\n- /opt\n- /root\n- /srv\n- /usr/lib/debug\n- /usr/local\n- /var/cache/pacman\n- /var/lib/docker\n- /var/lib/systemd/coredump\n- /var/log\n- /var/tmp\n" --width=500 --no-cancel --percentage=0 --auto-close 2>/dev/null \
					< <(
						echo "10"
						sleep 1
						mkdir -p /tmp/home/.steamos/ /tmp/home/.steamos/offload/opt /tmp/home/.steamos/offload/root /tmp/home/.steamos/offload/srv /tmp/home/.steamos/offload/usr/lib/debug /tmp/home/.steamos/offload/usr/local /tmp/home/.steamos/offload/var/lib/flatpak /tmp/home/.steamos/offload/var/cache/pacman /tmp/home/.steamos/offload/var/lib/docker /tmp/home/.steamos/offload/var/lib/systemd/coredump /tmp/home/.steamos/offload/var/log /tmp/home/.steamos/offload/var/tmp
						echo "15"
						sleep 1
						mv /tmp/rootpart/opt/* /tmp/home/.steamos/offload/opt
						mv /tmp/rootpart/root/* /tmp/home/.steamos/offload/root
						mv /tmp/rootpart/srv/* /tmp/home/.steamos/offload/srv
						mv /tmp/rootpart/usr/lib/debug/* /tmp/home/.steamos/offload/usr/lib/debug
						mv /tmp/rootpart/usr/local/* /tmp/home/.steamos/offload/usr/local
						mv /tmp/rootpart/var/cache/pacman/* /tmp/home/.steamos/offload/var/cache/pacman
						mv /tmp/rootpart/var/lib/docker/* /tmp/home/.steamos/offload/var/lib/docker
						mv /tmp/rootpart/var/lib/systemd/coredump/* /tmp/home/.steamos/offload/var/lib/systemd/coredump
						mv /tmp/rootpart/var/log/* /tmp/home/.steamos/offload/var/log
						mv /tmp/rootpart/var/tmp/* /tmp/home/.steamos/offload/var/tmp
						echo "System directory moving complete. Preparing to move flatpak content."
						echo "30"
						sleep 1
						printf "Starting flatpak data migration.\nThis may take 2-10 minutes to complete.\n"
						rsync -axHAWXS --numeric-ids --info=progress2 --no-inc-recursive /tmp/rootpart/var/lib/flatpak /tmp/home/.steamos/offload/var/lib/ | tr '\r' '\n' | awk '/^ / { print int(+$2) ; next } $0 { print "# " $0 }'
						echo "99"
						sleep 3
						echo "Finished."
					)
			fi
			umount "$(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)"
			umount "$(sudo blkid | grep holo-root | cut -d ':' -f 1 | head -n 1)"
		fi
	fi

	# Setup password for root
	while true; do
		ROOTPASS=$(kdialog --newpassword "Set root/system administrator password")
		if [ -z "$ROOTPASS" ]; then
			if zenity --question --text "No password was set for user \"root\"! \n(This is not recommended) \nAre you sure about that?" --width=258 2>/dev/null; then
				break
			fi
		else
			break
		fi
	done
	# Create user
	NAME_REGEX="^[a-z][-a-z0-9_]*\$"
	if ! $HOME_REUSE; then
		while true; do
			HOLOUSER=$(kdialog --title "Account creation" --inputbox "Enter username for this installation:\n(Tip: Use \"deck\" to increase decky loader plugin compatibility." "deck")
			if [ "$HOLOUSER" = "root" ]; then
				zenity --warning --text "User root already exists." --width=300 2>/dev/null
			elif [ -z "$HOLOUSER" ]; then
				zenity --warning --text "Please create a user!" --width=300 2>/dev/null
			elif [ ${#HOLOUSER} -gt 32 ]; then
				zenity --warning --text "Username length must not exceed 32 characters!" --width=400 2>/dev/null
			elif [[ ! $HOLOUSER =~ $NAME_REGEX ]]; then
				zenity --warning --text "Invalid username \"$HOLOUSER\"\nUsername needs to follow these rules:\n\n- Must start with a lowercase letter.\n- May only contain lowercase letters, digits, hyphens, and underscores." --width=500 2>/dev/null
			else
				break
			fi
		done
	fi
	# Setup password for user
	while true; do
		HOLOPASS=$(kdialog --newpassword "Set password for user $HOLOUSER")
		if [ -z "$HOLOPASS" ]; then
			zenity --warning --text "Please type password for user \"$HOLOUSER\"!" --width=300 2>/dev/null
		else
			break
		fi
	done
	case $install in
	1)
		# Umount twice to fully umount the broken install of steam os 3 before installing.
		swapoff "${HOLO_INSTALL_DIR}"/home/swapfile 2>/dev/null
		umount -R "${HOLO_INSTALL_DIR}" 2>/dev/null
		umount -R /tmp/mount_chroot 2>/dev/null
		if ! $HOME_REUSE; then
			if zenity --question --text "WARNING: The following drive is going to be fully erased. ALL DATA ON DRIVE ${DEVICE} WILL BE LOST! \n\n$(lsblk -o NAME,MAJ:MIN,RM,SIZE,RO,TYPE,VENDOR,MODEL,SERIAL,MOUNTPOINT "${DEVICE}" | sed "1d")\n\nErase ${DEVICE} and begin installation?" --width=700 2>/dev/null; then
				echo "Wiping partitions..."
				sfdisk --delete "${DEVICE}"
				wipefs -a "${DEVICE}"
				echo "Creating new gpt partitions..."
				parted "${DEVICE}" mklabel gpt
			else
				printf "\nNothing has been written.\nYou canceled the destructive install, please try again.\n"
				echo "Press any key to exit..."
				read -n 1 -s -r
				exit 1
			fi
		fi
		;;
	2)
		printf "\nHoloISO will be installed alongside existing OS/Partition.\nPlease make sure there are more than 24 GB on the >>END<< of free(unallocate) space available.\n"
		parted "$DEVICE" print free
		echo "HoloISO will be installed on the following free (unallocated) space."
		if ! parted "$DEVICE" print free | tail -n2 | grep "Free Space"; then
			printf "Error! No Free Space found on the end of the disk.\nNothing has been written.\nYou canceled the non-destructive install, please try again.\n"
			echo "Press any key to exit..."
			read -n 1 -s -r
			exit 1
		fi
		if zenity --question --text "HoloISO will be installed on the following free (unallocated) space.\nDoes this look reasonable?\nStart\tEnd\t\tSize\n$(sudo parted "${DEVICE}" print free | tail -n2 | grep "Free Space" | xargs | sed 's/ Free Space//' | tr ' ' '\t')" --width=500 2>/dev/null; then
			echo "Beginning installation..."
		else
			printf "\nNothing has been written.\nYou canceled the non-destructive install, please try again.\n"
			echo "Press any key to exit..."
			read -n 1 -s -r
			exit 1
		fi
		;;
	esac

	numPartitions=$(grep -c "${DRIVEDEVICE}"'[0-9]' /proc/partitions)

	if echo "${DEVICE}" | grep -q -P "^/dev/(nvme|loop|mmcblk)"; then
		INSTALLDEVICE="${DEVICE}"p
		numPartitions=$(grep -c "${DRIVEDEVICE}"p /proc/partitions)
	fi

	echo "Calculating start and end of free space..."
	diskSpace=$(awk '/'"${DRIVEDEVICE}"'/ {print $3; exit}' /proc/partitions)
	realDiskSpace=$(parted "${DEVICE}" unit MB print free | head -n2 | tail -n1 | grep -oh "\w*MB" | sed s/MB//)

	if $HOME_REUSE; then
		efi_partition=$(sudo blkid | grep HOLOEFI | cut -d ':' -f 1 | head -n 1)
		root_partition=$(sudo blkid | grep holo-root | cut -d ':' -f 1 | head -n 1)
		home_partition=$(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)
		efiPartNum=$(echo "$efi_partition" | tail -c2)
		rootPartNum=$(echo "$root_partition" | tail -c2)
		homePartNum=$(echo "$home_partition" | tail -c2)
	else
		efiPartNum=$((numPartitions + 1))
		rootPartNum=$((numPartitions + 2))
		homePartNum=$((numPartitions + 3))
		efi_partition=${INSTALLDEVICE}${efiPartNum}
		root_partition=${INSTALLDEVICE}${rootPartNum}
		home_partition=${INSTALLDEVICE}${homePartNum}
		case $install in
		1)
			efiStart=2
			;;
		2)
			efiStart=$(parted "${DEVICE}" unit MB print free | tail -n2 | awk '{$1=$1};1' | head -n1 | sed 's/\s.*$//' | sed s/MB//)
			;;
		esac
		efiEnd=$((efiStart + 256))
		rootStart=$efiEnd
		rootEnd=$((rootStart + 24000))

		if [ "$efiEnd" -gt "$realDiskSpace" ]; then
			echo "Not enough space available, please choose another disk and try again."
			echo "Press any key to exit..."
			read -n 1 -s -r
			exit 1
		fi

		echo "Creating partitions..."
		parted "${DEVICE}" mkpart primary fat32 "${efiStart}"M ${efiEnd}M
		parted "${DEVICE}" set ${efiPartNum} boot on
		parted "${DEVICE}" set ${efiPartNum} esp on
		echo "EFI partition created"
		# If the available storage is less than 64GB, don't create /home.
		# If the boot device is mmcblk0, don't create an ext4 partition or it will break steamOS versions
		# released after May 20.
		if [ "$diskSpace" -lt 64000000 ] || [[ "${DEVICE}" =~ mmcblk0 ]]; then
			home=false
			parted "${DEVICE}" mkpart primary btrfs ${rootStart}M 100%
			echo "Root partition created"
		else
			home=true
			parted "${DEVICE}" mkpart primary btrfs ${rootStart}M ${rootEnd}M
			echo "Root partition created"
			parted "${DEVICE}" mkpart primary ext4 ${rootEnd}M 100%
			echo "Home partition created"
		fi
	fi
	mkfs -t vfat "${efi_partition}"
	echo "EFI partition formatted"
	fatlabel "${INSTALLDEVICE}""${efiPartNum}" HOLOEFI
	mkfs -t btrfs -f "${root_partition}"
	echo "Root partition formatted"
	btrfs filesystem label "${root_partition}" holo-root
	if $home; then
		if $HOME_PART_EXISTS && $HOME_REUSE; then
			echo "Home partition will be reused at $(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)"
			home_partition="$(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)"
			echo "Home partition reused"
		else
			mkfs -t ext4 -F -O casefold "$home_partition"
			echo "Home partition formatted"
			e2label "$home_partition" holo-home
		fi
	fi
	echo "Partitioning complete, mounting and installing."
}

base_os_install() {
	sleep 1
	partitioning
	sleep 1
	mount -t btrfs -o subvol=/,compress-force=zstd:1,discard,noatime,nodiratime "${root_partition}" "${HOLO_INSTALL_DIR}"
	check_mount $? root
	if $home; then
		mkdir -p "${HOLO_INSTALL_DIR}"/home
		mount -t ext4 "${home_partition}" "${HOLO_INSTALL_DIR}"/home
		check_mount $? home
	fi
	rsync -axHAWXS --numeric-ids --info=progress2 --no-inc-recursive / "${HOLO_INSTALL_DIR}" | tr '\r' '\n' | awk '/^ / { print int(+$2) ; next } $0 { print "# " $0 }' | zenity --progress --title="Installing base OS..." --text="Bootstrapping root filesystem...\nThis may take more than 10 minutes.\n" --width=500 --no-cancel --auto-close 2>/dev/null
	while read -r input; do
		kernel=$(echo "$input" | cut -d ' ' -f 1)
		echo -e "PRESETS=('default' 'fallback')\n\nALL_kver='/boot/vmlinuz-${kernel}'\nALL_config='/etc/mkinitcpio.conf'\n\ndefault_image=\"/boot/initramfs-${kernel}.img\"\n\nfallback_image=\"/boot/initramfs-${kernel}-fallback.img\"\nfallback_options=\"-S autodetect\"" >"${HOLO_INSTALL_DIR}"/etc/mkinitcpio.d/"${kernel}".preset
		case $kernel in
		linux)
			arch-chroot "${HOLO_INSTALL_DIR}" install -Dm644 "$(arch-chroot "${HOLO_INSTALL_DIR}" find /usr/lib/modules | grep -w arch1 | grep vmlinuz)" \
				"/boot/vmlinuz-$(arch-chroot "${HOLO_INSTALL_DIR}" find /usr/lib/modules | grep -w arch1 | grep pkgbase | xargs arch-chroot "${HOLO_INSTALL_DIR}" cat)"
			;;
		linux-lts)
			arch-chroot "${HOLO_INSTALL_DIR}" install -Dm644 "$(arch-chroot "${HOLO_INSTALL_DIR}" find /usr/lib/modules | grep -w lts | grep vmlinuz)" \
				"/boot/vmlinuz-$(arch-chroot "${HOLO_INSTALL_DIR}" find /usr/lib/modules | grep -w lts | grep pkgbase | xargs arch-chroot "${HOLO_INSTALL_DIR}" cat)"
			;;
		linux-zen)
			arch-chroot "${HOLO_INSTALL_DIR}" install -Dm644 "$(arch-chroot "${HOLO_INSTALL_DIR}" find /usr/lib/modules | grep -w zen | grep vmlinuz)" \
				"/boot/vmlinuz-$(arch-chroot "${HOLO_INSTALL_DIR}" find /usr/lib/modules | grep -w zen | grep pkgbase | xargs arch-chroot "${HOLO_INSTALL_DIR}" cat)"
			;;
		linux-hardened)
			arch-chroot "${HOLO_INSTALL_DIR}" install -Dm644 "$(arch-chroot "${HOLO_INSTALL_DIR}" find /usr/lib/modules | grep -w hardened | grep vmlinuz)" \
				"/boot/vmlinuz-$(arch-chroot "${HOLO_INSTALL_DIR}" find /usr/lib/modules | grep -w hardened | grep pkgbase | xargs arch-chroot "${HOLO_INSTALL_DIR}" cat)"
			;;
		linux-neptune)
			arch-chroot "${HOLO_INSTALL_DIR}" install -Dm644 "$(arch-chroot "${HOLO_INSTALL_DIR}" find /usr/lib/modules | grep -w neptune | grep vmlinuz)" \
				"/boot/vmlinuz-$(arch-chroot "${HOLO_INSTALL_DIR}" find /usr/lib/modules | grep -w neptune | grep pkgbase | xargs arch-chroot "${HOLO_INSTALL_DIR}" cat)"
			;;
		linux-neptune-60)
			arch-chroot "${HOLO_INSTALL_DIR}" install -Dm644 "$(arch-chroot "${HOLO_INSTALL_DIR}" find /usr/lib/modules | grep -w neptune-60 | grep vmlinuz)" \
				"/boot/vmlinuz-$(arch-chroot "${HOLO_INSTALL_DIR}" find /usr/lib/modules | grep -w neptune-60 | grep pkgbase | xargs arch-chroot "${HOLO_INSTALL_DIR}" cat)"
			;;
		linux-neptune-61)
			arch-chroot "${HOLO_INSTALL_DIR}" install -Dm644 "$(arch-chroot "${HOLO_INSTALL_DIR}" find /usr/lib/modules | grep -w neptune-61 | grep vmlinuz)" \
				"/boot/vmlinuz-$(arch-chroot "${HOLO_INSTALL_DIR}" find /usr/lib/modules | grep -w neptune-61 | grep pkgbase | xargs arch-chroot "${HOLO_INSTALL_DIR}" cat)"
			;;
		esac
	done <"${HOLO_INSTALL_DIR}"/etc/holoinstall/post_install/kernel_list.bootstrap
	arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm "$(arch-chroot "${HOLO_INSTALL_DIR}" find /etc/holoinstall/post_install/pkgs | grep amd-ucode)"
	arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm "$(arch-chroot "${HOLO_INSTALL_DIR}" find /etc/holoinstall/post_install/pkgs | grep intel-ucode)"
	arch-chroot "${HOLO_INSTALL_DIR}" rm /etc/polkit-1/rules.d/99_holoiso_installuser.rules
	if $IS_STEAMDECK; then
		echo "You're running this on a Steam Deck. linux-neptune-61 will be installed to ensure maximum kernel-side compatibility."
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -Rdd --noconfirm linux-firmware
		cat </etc/holoinstall/post_install/kernel_list.bootstrap | xargs arch-chroot "${HOLO_INSTALL_DIR}" pacman -Rdd --noconfirm
		echo -e "PRESETS=('default' 'fallback')\n\nALL_kver='/boot/vmlinuz-linux-neptune-61'\nALL_config='/etc/mkinitcpio.conf'\n\ndefault_image=\"/boot/initramfs-linux-neptune-61.img\"\n\nfallback_image=\"/boot/initramfs-linux-neptune-61-fallback.img\"\nfallback_options=\"-S autodetect\"" >"${HOLO_INSTALL_DIR}"/etc/mkinitcpio.d/linux-neptune-61.preset
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm "$(arch-chroot "${HOLO_INSTALL_DIR}" find /etc/holoinstall/post_install/pkgs | grep linux-neptune-61-6)"
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm "$(arch-chroot "${HOLO_INSTALL_DIR}" find /etc/holoinstall/post_install/pkgs | grep linux-neptune-61-headers)"
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm "$(arch-chroot "${HOLO_INSTALL_DIR}" find /etc/holoinstall/post_install/pkgs | grep linux-firmware-neptune)"
	elif $IS_OXP2; then
		echo "You're running this on a OneXPlayer 2. linux-neptune-61 will be installed."
		cat </etc/holoinstall/post_install/kernel_list.bootstrap | xargs arch-chroot "${HOLO_INSTALL_DIR}" pacman -Rdd --noconfirm
		echo -e "PRESETS=('default' 'fallback')\n\nALL_kver='/boot/vmlinuz-linux-neptune-61'\nALL_config='/etc/mkinitcpio.conf'\n\ndefault_image=\"/boot/initramfs-linux-neptune-61.img\"\n\nfallback_image=\"/boot/initramfs-linux-neptune-61-fallback.img\"\nfallback_options=\"-S autodetect\"" >"${HOLO_INSTALL_DIR}"/etc/mkinitcpio.d/linux-neptune-61.preset
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm "$(arch-chroot "${HOLO_INSTALL_DIR}" find /etc/holoinstall/post_install/pkgs | grep linux-neptune-61-6)"
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm "$(arch-chroot "${HOLO_INSTALL_DIR}" find /etc/holoinstall/post_install/pkgs | grep linux-neptune-61-headers)"
		arch-chroot "${HOLO_INSTALL_DIR}" systemctl enable upower
		echo "blacklist sp5100_tco" >"${HOLO_INSTALL_DIR}"/etc/modprobe.d/disable-5100.conf
		{
			echo "export LIBVA_DRIVER_NAME=radeonsi"
			echo "export DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1=1"
			echo "export STEAM_FORCE_DESKTOPUI_SCALING=2.0"
		} >>"${HOLO_INSTALL_DIR}"/etc/environment
		sed -i 's/plymouth.nolog/plymouth.nolog fbcon=rotate:3 acpi.ec_no_wakeup=1 usbcore.autosuspend=-1 nowatchdog clearcpuid=514 /g' "${HOLO_INSTALL_DIR}"/etc/default/grub
	elif $IS_WIN600; then
		echo "You're running this on Anbernic Win600. A suitable gamepad driver will be installed."
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm "$(arch-chroot "${HOLO_INSTALL_DIR}" find /etc/holoinstall/post_install/pkgs | grep win600-xpad-dkms)"
	else
		arch-chroot "${HOLO_INSTALL_DIR}" systemctl enable acpid.service
		sed -i "s/logger 'PowerButton pressed'/systemctl suspend/" "${HOLO_INSTALL_DIR}"/etc/acpi/handler.sh
	fi
	arch-chroot "${HOLO_INSTALL_DIR}" pacman-key --init
	arch-chroot "${HOLO_INSTALL_DIR}" pacman-key --populate
	arch-chroot "${HOLO_INSTALL_DIR}" pacman -Rdd --noconfirm mkinitcpio-archiso

	if [[ "$(lspci -v | grep VGA | sed -nE "s/.*(NVIDIA) .*/\1/p")" = "NVIDIA" ]]; then
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm "$(arch-chroot "${HOLO_INSTALL_DIR}" find /etc/holoinstall/post_install/pkgs | grep nvidia-dkms)"
		echo "LIBVA_DRIVER_NAME=nvidia" >>"${HOLO_INSTALL_DIR}"/etc/environment
		echo "NVD_BACKEND=direct" >>"${HOLO_INSTALL_DIR}"/etc/environment
		sed -i 's/MODULES=(/&nvidia nvidia_modeset nvidia_uvm nvidia_drm /' "${HOLO_INSTALL_DIR}"/etc/mkinitcpio.conf
		sed -i 's/plymouth.nolog/plymouth.nolog nvidia-drm.modeset=1/g' "${HOLO_INSTALL_DIR}"/etc/default/grub
		if $IS_LAPTOP; then
			echo 'GAMEMODERUNEXEC="env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only"' >>"${HOLO_INSTALL_DIR}"/etc/environment
		else
			arch-chroot "${HOLO_INSTALL_DIR}" pacman -Rdd --noconfirm nvidia-prime
		fi
	else
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -Rdd --noconfirm nvidia-dkms-tkg nvidia-utils-tkg nvidia-egl-wayland-tkg nvidia-settings-tkg opencl-nvidia-tkg lib32-nvidia-utils-tkg lib32-opencl-nvidia-tkg libva-nvidia-driver-git nvidia-prime
	fi
	arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm "$(arch-chroot "${HOLO_INSTALL_DIR}" find /etc/holoinstall/post_install/pkgs | grep broadcom-wl-dkms)"
	arch-chroot "${HOLO_INSTALL_DIR}" mkinitcpio -P
	arch-chroot "${HOLO_INSTALL_DIR}" userdel -r liveuser
	sleep 2

	echo "Base system installation done, generating fstab..."
	mkdir -p "${HOLO_INSTALL_DIR}"/boot/efi
	mount -t vfat "${efi_partition}" "${HOLO_INSTALL_DIR}"/boot/efi
	genfstab -U -p "${HOLO_INSTALL_DIR}" >>"${HOLO_INSTALL_DIR}"/etc/fstab
	sleep 1

	# Set hwclock
	printf "\nSyncing HW clock\n\n"
	arch-chroot "${HOLO_INSTALL_DIR}" hwclock --systohc
	arch-chroot "${HOLO_INSTALL_DIR}" systemctl enable systemd-timesyncd

	# Set timezone
	rm "${HOLO_INSTALL_DIR}"/etc/localtime
	arch-chroot "${HOLO_INSTALL_DIR}" ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime

	# Set locales
	echo "$LANGUAGES_ALL" | tr "|" "\n" >>"${HOLO_INSTALL_DIR}"/etc/locale.gen
	sleep 3 && grep -x "en_US.UTF-8 UTF-8" "${HOLO_INSTALL_DIR}"/etc/locale.gen 1>/dev/null || echo "en_US.UTF-8 UTF-8" >>"${HOLO_INSTALL_DIR}"/etc/locale.gen
	arch-chroot "${HOLO_INSTALL_DIR}" locale-gen
	MAIN_LANGUAGE="$(echo "$MAIN_LANGUAGE" | cut -d' ' -f1)"
	echo "LANG=$MAIN_LANGUAGE" >"${HOLO_INSTALL_DIR}"/etc/locale.conf

	# Set keyboard layout
	echo "KEYMAP=$KEYBOARD_LAYOUT" >>"${HOLO_INSTALL_DIR}"/etc/vconsole.conf
	echo "XKBLAYOUT=$KEYBOARD_LAYOUT_X11" >>"${HOLO_INSTALL_DIR}"/etc/vconsole.conf
	cat <<EOF >"${HOLO_INSTALL_DIR}"/etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "$KEYBOARD_LAYOUT_X11"
EndSection
EOF

	# Create swapfile
	echo "Creating swapfile..."
	dd if=/dev/zero of="${HOLO_INSTALL_DIR}"/home/swapfile bs=1M count="$SWAPSIZE" status=progress
	chmod 0600 "${HOLO_INSTALL_DIR}"/home/swapfile
	mkswap -U clear "${HOLO_INSTALL_DIR}"/home/swapfile
	swapon "${HOLO_INSTALL_DIR}"/home/swapfile
	echo /home/swapfile none swap defaults 0 0 >>"${HOLO_INSTALL_DIR}"/etc/fstab

	echo "Configuring first boot user accounts..."
	rm "${HOLO_INSTALL_DIR}"/etc/skel/Desktop/*
	arch-chroot "${HOLO_INSTALL_DIR}" rm /etc/sddm.conf.d/*
	cp /etc/holoinstall/post_install_shortcuts/steam.desktop "${HOLO_INSTALL_DIR}"/etc/xdg/autostart
	echo -e "[Desktop Entry]\nName=Steam\nExec=steam steam://open/games\nIcon=steam\nType=Application" >"${HOLO_INSTALL_DIR}"/etc/skel/Desktop/steam.desktop
	chmod +x "${HOLO_INSTALL_DIR}"/etc/skel/Desktop/steam.desktop
	cp /etc/holoinstall/post_install_shortcuts/steamos-gamemode.desktop "${HOLO_INSTALL_DIR}"/etc/skel/Desktop
	echo "Creating user ${HOLOUSER}..."
	echo -e "${ROOTPASS}\n${ROOTPASS}" | arch-chroot "${HOLO_INSTALL_DIR}" passwd root
	arch-chroot "${HOLO_INSTALL_DIR}" useradd --create-home "${HOLOUSER}"
	echo -e "${HOLOPASS}\n${HOLOPASS}" | arch-chroot "${HOLO_INSTALL_DIR}" passwd "${HOLOUSER}"
	echo "${HOLOUSER} ALL=(ALL) ALL" >"${HOLO_INSTALL_DIR}"/etc/sudoers.d/"${HOLOUSER}"
	chmod 0440 "${HOLO_INSTALL_DIR}"/etc/sudoers.d/"${HOLOUSER}"
	sleep 1

	if $INSTALL_XONE_DRIVER; then
		echo "Installing XBox One Controller driver..."
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -Syu --noconfirm
		# Install xone-dongle-firmware
		echo The firmware for the wireless dongle is subject to Microsofts Terms of Use:
		echo https://www.microsoft.com/en-us/legal/terms-of-use
		mkdir "${HOLO_INSTALL_DIR}"/etc/xone
		wget https://aur.archlinux.org/cgit/aur.git/snapshot/xone-dongle-firmware.tar.gz -P "${HOLO_INSTALL_DIR}"/etc/xone
		cd "${HOLO_INSTALL_DIR}"/etc/xone && tar -xf "${HOLO_INSTALL_DIR}"/etc/xone/xone-dongle-firmware.tar.gz
		arch-chroot "${HOLO_INSTALL_DIR}" chown -hR "${HOLOUSER}" /etc/xone/xone-dongle-firmware
		arch-chroot "${HOLO_INSTALL_DIR}" su "${HOLOUSER}" -c "cd /etc/xone/xone-dongle-firmware && makepkg"
		XONE_DONGLE_FW=$(find "${HOLO_INSTALL_DIR}"/etc/xone/xone-dongle-firmware -name 'xone-dongle-firmware*.pkg.tar.zst')
		XONE_DONGLE_FW=${XONE_DONGLE_FW//$HOLO_INSTALL_DIR/}
		echo "$XONE_DONGLE_FW" | xargs arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm

		# Install xone-dkms-git driver
		wget https://aur.archlinux.org/cgit/aur.git/snapshot/xone-dkms-git.tar.gz -P "${HOLO_INSTALL_DIR}"/etc/xone
		cd "${HOLO_INSTALL_DIR}"/etc/xone && tar -xf "${HOLO_INSTALL_DIR}"/etc/xone/xone-dkms-git.tar.gz
		arch-chroot "${HOLO_INSTALL_DIR}" chown -hR "${HOLOUSER}" /etc/xone/xone-dkms-git
		arch-chroot "${HOLO_INSTALL_DIR}" su "${HOLOUSER}" -c "cd /etc/xone/xone-dkms-git && makepkg"
		XONE_DKMS=$(find "${HOLO_INSTALL_DIR}"/etc/xone/xone-dkms-git -name 'xone-dkms-git*.pkg.tar.zst')
		XONE_DKMS=${XONE_DKMS//$HOLO_INSTALL_DIR/}
		echo "$XONE_DKMS" | xargs arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm
		rm -r "${HOLO_INSTALL_DIR}"/etc/xone
	fi

	if $INSTALL_DECKY_LOADER; then
		echo "Installing DeckyLoader..."
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -Syu --noconfirm
		# shellcheck disable=SC2034
		SUDO_USER=$HOLOUSER
		curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | arch-chroot "${HOLO_INSTALL_DIR}" bash
	fi

	if $INSTALL_EMUDECK; then
		echo "Installing EmuDeck..."
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -Syu --noconfirm
		mkdir -p "${HOLO_INSTALL_DIR}"/home/"${HOLOUSER}"/Applications
		curl -L "$(curl -s https://api.github.com/repos/EmuDeck/emudeck-electron/releases/latest | grep -E 'browser_download_url.*AppImage' | cut -d '"' -f 4)" -o "${HOLO_INSTALL_DIR}"/home/"${HOLOUSER}"/Applications/EmuDeck.AppImage
		chown -hR liveuser:liveuser "${HOLO_INSTALL_DIR}"/home/"${HOLOUSER}"/Applications/EmuDeck.AppImage
		chmod +x "${HOLO_INSTALL_DIR}"/home/"${HOLOUSER}"/Applications/EmuDeck.AppImage
		HOME=${HOLO_INSTALL_DIR}/home/${HOLOUSER}
		su -p liveuser -c "${HOLO_INSTALL_DIR}/home/${HOLOUSER}/Applications/EmuDeck.AppImage"
		wait
	fi

	if $INSTALL_STEAM_PATCH; then
		echo "Installing steam-patch..."
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -Syu --noconfirm
		steam_patch_path="${HOLO_INSTALL_DIR}/home/${HOLOUSER}/steam-patch"
		pacman -Syu --noconfirm --needed cargo gcc
		rm -rf "$steam_patch_path"
		cd "${HOLO_INSTALL_DIR}/home/${HOLOUSER}" && su liveuser -c "git clone https://github.com/corando98/steam-patch $steam_patch_path"
		cd "$steam_patch_path" && su liveuser -c "cargo build -r"
		sed -i 's/mapper = true/mapper = false/' ./config.toml
		chmod +x "$steam_patch_path/target/release/steam-patch"
		cp "$steam_patch_path/target/release/steam-patch" "${HOLO_INSTALL_DIR}/usr/bin/steam-patch"
		sed -i "s@\$USER@$HOLOUSER@g" "$steam_patch_path/steam-patch.service"
		# Move services in place
		cp "$steam_patch_path/steam-patch.service" "${HOLO_INSTALL_DIR}/etc/systemd/system/"
		cp "$steam_patch_path/restart-steam-patch-on-boot.service" "${HOLO_INSTALL_DIR}/etc/systemd/system/"
		cp "${HOLO_INSTALL_DIR}/usr/bin/steamos-polkit-helpers/steamos-priv-write" "${HOLO_INSTALL_DIR}/usr/bin/steamos-polkit-helpers/steamos-priv-write-bkp"
		cp "$steam_patch_path/steamos-priv-write-updated" "${HOLO_INSTALL_DIR}/usr/bin/steamos-polkit-helpers/steamos-priv-write"

		# Enable services
		arch-chroot "${HOLO_INSTALL_DIR}" systemctl disable handycon
		arch-chroot "${HOLO_INSTALL_DIR}" systemctl enable steam-patch.service
		arch-chroot "${HOLO_INSTALL_DIR}" systemctl enable restart-steam-patch-on-boot.service
	fi

	if $INSTALL_8BITDO_UDEV_RULES; then
		# Install xboxdrv-stable-git
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm "$(arch-chroot "${HOLO_INSTALL_DIR}" find /etc/holoinstall/post_install/pkgs/ | grep "dbus-glib")"
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm "$(arch-chroot "${HOLO_INSTALL_DIR}" find /etc/holoinstall/post_install/pkgs/ | grep "xboxdrv")"
		arch-chroot "${HOLO_INSTALL_DIR}" systemctl enable xboxdrv
		# Install 8bitdo-ultimate-controller-udev rules
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm "$(arch-chroot "${HOLO_INSTALL_DIR}" find /etc/holoinstall/post_install/pkgs/ | grep "8bitdo-ultimate-controller-udev")"
	fi

	echo "Installing bootloader..."
	echo "GRUB_DISABLE_OS_PROBER=false" >>"${HOLO_INSTALL_DIR}"/etc/default/grub
	sed -i 's/plymouth.nolog/plymouth.nolog usbcore.autosuspend=-1/g' "${HOLO_INSTALL_DIR}"/etc/default/grub
	arch-chroot "${HOLO_INSTALL_DIR}" holoiso-grub-update
	mount -o remount,rw -t efivarfs efivarfs /sys/firmware/efi/efivars
	HOLOISO_EFI_ENTRY=$(efibootmgr | grep HoloISO | head -c8 | tail -c4)
	if [ -n "$HOLOISO_EFI_ENTRY" ]; then
		echo "Old HoloISO EFI entry found. Deleting now..."
		arch-chroot "${HOLO_INSTALL_DIR}" efibootmgr -b "$HOLOISO_EFI_ENTRY" -B
	fi
	arch-chroot "${HOLO_INSTALL_DIR}" efibootmgr -c -d "${DEVICE}" -p "${efiPartNum}" -L "HoloISO" -l '\EFI\BOOT\BOOTX64.EFI'
	sleep 1
}

full_install() {
	cp /etc/holoinstall/post_install/amd-perf-fix "${HOLO_INSTALL_DIR}"/usr/bin/amd-perf-fix
	chmod +x "${HOLO_INSTALL_DIR}"/usr/bin/amd-perf-fix

	echo "Configuring Steam Deck UI by default..."
	echo -e "[General]\nDisplayServer=wayland\n\n[Autologin]\nUser=${HOLOUSER}\nSession=gamescope-wayland.desktop\nRelogin=true\n\n[X11]\n# Janky workaround for wayland sessions not stopping in sddm, kills\n# all active sddm-helper sessions on teardown\nDisplayStopCommand=/usr/bin/gamescope-wayland-teardown-workaround" >>"${HOLO_INSTALL_DIR}"/etc/sddm.conf.d/autologin.conf
	arch-chroot "${HOLO_INSTALL_DIR}" usermod -a -G rfkill "${HOLOUSER}"
	arch-chroot "${HOLO_INSTALL_DIR}" usermod -a -G wheel "${HOLOUSER}"
	arch-chroot "${HOLO_INSTALL_DIR}" usermod -a -G realtime "${HOLOUSER}"
	arch-chroot "${HOLO_INSTALL_DIR}" usermod -a -G gamemode "${HOLOUSER}"
	echo "Preparing Steam OOBE..."
	arch-chroot "${HOLO_INSTALL_DIR}" su "${HOLOUSER}" -c "mkdir -p ~/.local/share/Steam"
	arch-chroot "${HOLO_INSTALL_DIR}" su "${HOLOUSER}" -c "tar xf /usr/lib/steam/bootstraplinux_ubuntu12_32.tar.xz -C ~/.local/share/Steam"
	if $INSTALL_DECKY_LOADER || $INSTALL_STEAM_PATCH; then
		arch-chroot "${HOLO_INSTALL_DIR}" su "${HOLOUSER}" -c "touch ~/.local/share/Steam/.cef-enable-remote-debugging"
	fi
	cp /etc/holoinstall/post_install/99-steamos-automount.rules "${HOLO_INSTALL_DIR}"/usr/lib/udev/rules.d/99-steamos-automount.rules
	rm "${HOLO_INSTALL_DIR}"/usr/lib/hwsupport/steamos-automount.sh
	cp /etc/holoinstall/post_install/steamos-automount.sh "${HOLO_INSTALL_DIR}"/usr/lib/hwsupport/steamos-automount.sh
	chmod +x "${HOLO_INSTALL_DIR}"/usr/lib/hwsupport/steamos-automount.sh
	$HOME_REUSE || touch "${HOLO_INSTALL_DIR}"/etc/holoiso-oobe
	$HOME_REUSE && grep -q '"CompletedOOBE"		"1"' "${HOLO_INSTALL_DIR}/home/${HOLOUSER}/.steam/registry.vdf" && rm "${HOLO_INSTALL_DIR}"/etc/holoiso-oobe
	$HOME_REUSE || arch-chroot "${HOLO_INSTALL_DIR}" su "${HOLOUSER}" -c "mkdir ~/.steam && cp /etc/holoinstall/post_install/registry.vdf ~/.steam/registry.vdf"
	if [[ "$(lspci -v | grep VGA | sed -nE "s/.*(NVIDIA) .*/\1/p")" == "NVIDIA" ]]; then
		sed -i 's/"GPUAccelWebViewsV3"		"1"/"GPUAccelWebViewsV3"		"0"/' "${HOLO_INSTALL_DIR}/home/${HOLOUSER}/.steam/registry.vdf"
	fi
	echo "Cleaning up..."
	cp /etc/skel/.bashrc "${HOLO_INSTALL_DIR}"/home/"${HOLOUSER}"
	arch-chroot "${HOLO_INSTALL_DIR}" rm -rf /etc/holoinstall
	[[ $(lspci -vnn | grep VGA | grep -o "\[[0-9a-f]\{4\}:[0-9a-f]\{4\}\]" | tr -d '[]') =~ 1002:* ]] && arch-chroot "${HOLO_INSTALL_DIR}" systemctl enable amd-perf-fix
	arch-chroot "${HOLO_INSTALL_DIR}" systemctl enable power-readout-fix
	sudo rm -rf "${HOLO_INSTALL_DIR}"/etc/sudoers.d/g_wheel
	sudo rm -rf "${HOLO_INSTALL_DIR}"/etc/sudoers.d/liveuser
	sleep 1
}

# The installer itself. Good wuck.
echo "SteamOS 3 Installer"
echo "Start time: $(date)"
echo "Please choose installation type:"
HOLO_INSTALL_TYPE=$(zenity --list --title="Choose your installation type:" --column="Type" --column="Name" 1 "Install HoloISO, version $(grep </etc/os-release VARIANT_ID | cut -d "=" -f 2 | sed 's/"//g') " 2 "Exit installer" --width=450 --height=281 2>/dev/null)
if [[ "${HOLO_INSTALL_TYPE}" == "1" ]] || [[ "${HOLO_INSTALL_TYPE}" == "barebones" ]]; then
	echo "Installing SteamOS, barebones configuration..."
	information_gathering
	base_os_install
	full_install
	zenity --info --text="Installation finished! \nYou may reboot now, or type \"sudo arch-chroot /mnt\"\nto make further changes." --width=400 2>/dev/null
else
	zenity --info --text="Exiting installer..." --width=120 --height=50 2>/dev/null
fi

echo "End time: $(date)"
