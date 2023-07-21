#!/bin/bash
# HoloISO Installer v2
# This defines all of the current variables.
HOLO_INSTALL_DIR="${HOLO_INSTALL_DIR:-/mnt}"
IS_WIN600=$(grep </sys/devices/virtual/dmi/id/product_name Win600)
IS_STEAMDECK=$(grep </sys/devices/virtual/dmi/id/product_name Jupiter)

if [ -n "${IS_WIN600}" ]; then
	GAMEPAD_DRV=true
else
	GAMEPAD_DRV=false
fi

if [ -n "${IS_STEAMDECK}" ]; then
	FIRMWARE_INSTALL=true
else
	FIRMWARE_INSTALL=false
fi

check_mount() {
	if [ "$1" != 0 ]; then
		printf "\nError: Something went wrong when mounting %s partitions. Please try again! \n" "$2"
		echo 'Press any key to exit...'
		read -r -k1 -s
		exit 1
	fi
}

information_gathering() {
	sudo sed -i 's/en_US.UTF-8 UTF-8/#en_US.UTF-8 UTF-8/' /etc/locale.gen
	TEMP_LANG=$(localectl list-x11-keymap-layouts --no-pager | awk '{ printf "FALSE""\0"$0"\0" }' | zenity --list --radiolist --width=600 --height=512 --title="Keyboard layout" --text="Select a keyboard layout to use while using the installer" --multiple --column '' --column 'Keyboard layouts' 2>/dev/null)
	setxkbmap "$TEMP_LANG"

	# Ask for the timezone
	TIMEZONE=$(timedatectl list-timezones --no-pager | awk '{ printf "FALSE""\0"$0"\0" }' | zenity --list --radiolist --width=600 --height=512 --title="Timezone" --text="Select your timezone below:\n " --multiple --column '' --column 'Timezones' 2>/dev/null)

	# Ask for languages
	LANGUAGES_ALL=$(cut </etc/locale.gen -c2- | tail -n +18 | awk '{ printf "FALSE""\0"$0"\0" }' | zenity --list --width=600 --height=512 --title="Select Languages" --text="Select your desired languages below:\n(UTF-8 is preferred)" --checklist --multiple --column '' --column 'Languages' 2>/dev/null)

	# Ask for main language
	MAIN_LANGUAGE=$(echo "$LANGUAGES_ALL" | tr "|" "\n" | awk '{ printf "FALSE""\0"$0"\0" }' | zenity --list --radiolist --width=600 --height=512 --title="Select Language" --text="Select your desired main language below:" --multiple --column '' --column 'Language' 2>/dev/null)

	# Ask for keyboard layouts
	KEYBOARD_LAYOUT=$(localectl list-keymaps --no-pager | awk '{ printf "FALSE""\0"$0"\0" }' | zenity --list --radiolist --width=600 --height=512 --title="Keyboard layout" --text="Select your desired keyboard layout below:" --multiple --column '' --column 'Keyboard layouts' 2>/dev/null)
	KEYBOARD_LAYOUT_X11=$(localectl list-x11-keymap-layouts --no-pager | awk '{ printf "FALSE""\0"$0"\0" }' | zenity --list --radiolist --width=600 --height=512 --title="X11 Keyboard layout" --text="Select your desired X11 keyboard layout below:" --multiple --column '' --column 'X11 Keyboard layouts' 2>/dev/null)

	# Ask for swapfile size
	SWAPSIZE=$(printf "1GB\n2GB\n4GB\n8GB\n16GB\n32GB" | awk '{ printf "FALSE""\0"$0"\0" }' | zenity --list --radiolist --title="SWAP" --text="How big do you want your swapfile?\n(8GB is recommended)" --multiple --column '' --column '' --width=275 --height=285 2>/dev/null)
	case $SWAPSIZE in
	1GB) SWAPSIZE=1024 ;;
	2GB) SWAPSIZE=2048 ;;
	4GB) SWAPSIZE=4096 ;;
	8GB) SWAPSIZE=8192 ;;
	16GB) SWAPSIZE=16384 ;;
	32GB) SWAPSIZE=32768 ;;
	esac

	# Ask for xone-dkms-git driver
	if zenity --question --title="Xbox One gamepad driver" --text='Do you want to install the Xbox One gamepad driver?\n\nThe firmware for the wireless dongle is subject to Microsofts Terms of Use:\n<a href="https://www.microsoft.com/en-us/legal/terms-of-use">Microsofts Terms of Use</a>\n\nDo you agree to Microsofts Terms of Use and want to install the driver?\n\nNote: This requires an internet connection.' --width=500 2>/dev/null; then
		INSTALL_XONE_DRIVER=true
	else
		INSTALL_XONE_DRIVER=false
	fi

	# Ask for decky loader
	if zenity --question --title="Decky loader" --text='Do you want to install decky loader?\n(This requires an internet connection)' 2>/dev/null; then
		INSTALL_DECKY_LOADER=true
	else
		INSTALL_DECKY_LOADER=false
	fi

	# Ask for emudeck
	if zenity --question --title="EmuDeck" --text='Do you want to install EmuDeck?\n(This requires an internet connection)' 2>/dev/null; then
		INSTALL_EMUDECK=true
	else
		INSTALL_EMUDECK=false
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
			xargs -0 zenity --list --width=600 --height=512 --title="Select disk" --text="Select your disk to install HoloISO in below:\n\n $(lsblk -d -o NAME,MAJ:MIN,RM,SIZE,RO,TYPE,VENDOR,MODEL,SERIAL,MOUNTPOINT | sed '/sr/d' | sed '/loop/d')" --radiolist --multiple --column ' ' --column 'Disks' 2>/dev/null)
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

	echo "Choose your partitioning type:"
	install=$(zenity --list --title="Choose your installation type:" --column="Type" --column="Name" 1 "Use entire drive" 2 "Install alongside existing OS/Partition (Requires at least 50 GB of free unformatted space from the end)" --width=820 --height=220 2>/dev/null)
	if [[ -n "$(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)" ]]; then
		HOME_REUSE_TYPE=$(zenity --list --title="Warning" --text="A HoloISO home partition was detected at $(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1).\nPlease select an appropriate action below:" --column="Type" --column="Name" 1 "Format it and start over" 2 "Reuse partition" --width=400 --height=220 2>/dev/null)
		mkdir -p /tmp/home
		mount "$(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)" /tmp/home
		if [[ -d "/tmp/home/.steamos" ]]; then
			echo "Migration data found. Proceeding"
			umount -l "$(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)"
		else
			(
				sleep 2
				echo "10"
				mkdir -p /tmp/rootpart
				mount "$(sudo blkid | grep holo-root | cut -d ':' -f 1 | head -n 1)" /tmp/rootpart
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
				printf "Starting flatpak data migration.\nThis may take 2 to 10 minutes to complete.\n"
				rsync -axHAWXS --numeric-ids --info=progress2 --no-inc-recursive /tmp/rootpart/var/lib/flatpak /tmp/home/.steamos/offload/var/lib/ | tr '\r' '\n' | awk '/^ / { print int(+$2) ; next } $0 { print "# " $0 }'
				echo "Finished."
			) |
				zenity --progress --title="Preparing to reuse home at $(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)" --text="Starting to move following directories to target offload:\n\n- /opt\n- /root\n- /srv\n- /usr/lib/debug\n- /usr/local\n- /var/cache/pacman\n- /var/lib/docker\n- /var/lib/systemd/coredump\n- /var/log\n- /var/tmp\n" --width=500 --no-cancel --percentage=0 --auto-close 2>/dev/null
			umount -l "$(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)"
			umount -l "$(sudo blkid | grep holo-root | cut -d ':' -f 1 | head -n 1)"
		fi
	fi
	# Setup password for root
	while true; do
		ROOTPASS=$(zenity --forms --title="Account configuration" --text="Set root/system administrator password" --add-password="Password for user root" 2>/dev/null)
		if [ -z "$ROOTPASS" ]; then
			zenity --warning --text "No password was set for user \"root\"!" --width=300 2>/dev/null
			break
		fi
		echo
		ROOTPASS_CONF=$(zenity --forms --title="Account configuration" --text="Confirm your root password" --add-password="Password for user root" 2>/dev/null)
		echo
		if [ "$ROOTPASS" = "$ROOTPASS_CONF" ]; then
			break
		fi
		zenity --warning --text "Passwords not match." --width=300 2>/dev/null
	done
	# Create user
	NAME_REGEX="^[a-z][-a-z0-9_]*\$"
	while true; do
		HOLOUSER=$(zenity --entry --title="Account creation" --text "Enter username for this installation:\n(Tip: Use \"deck\" to increase decky loader plugin compatibility.)" 2>/dev/null)
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
	# Setup password for user
	while true; do
		HOLOPASS=$(zenity --forms --title="Account configuration" --text="Set password for $HOLOUSER" --add-password="Password for user $HOLOUSER" 2>/dev/null)
		echo
		HOLOPASS_CONF=$(zenity --forms --title="Account configuration" --text="Confirm password for $HOLOUSER" --add-password="Password for user $HOLOUSER" 2>/dev/null)
		echo
		if [ -z "$HOLOPASS" ]; then
			zenity --warning --text "Please type password for user \"$HOLOUSER\"!" --width=300 2>/dev/null
			HOLOPASS_CONF=unmatched
		fi
		if [ "$HOLOPASS" = "$HOLOPASS_CONF" ]; then
			break
		fi
		zenity --warning --text "Passwords do not match." --width=300 2>/dev/null
	done
	case $install in
	1)
		destructive=true
		# Umount twice to fully umount the broken install of steam os 3 before installing.
		umount "$INSTALLDEVICE"* >/dev/null 2>&1
		umount "$INSTALLDEVICE"* >/dev/null 2>&1
		if zenity --question --text "WARNING: The following drive is going to be fully erased. ALL DATA ON DRIVE ${DEVICE} WILL BE LOST! \n\n$(lsblk -o NAME,MAJ:MIN,RM,SIZE,RO,TYPE,VENDOR,MODEL,SERIAL,MOUNTPOINT "${DEVICE}" | sed "1d")\n\nErase ${DEVICE} and begin installation?" --width=700 2>/dev/null; then
			echo "Wiping partitions..."
			sfdisk --delete "${DEVICE}"
			wipefs -a "${DEVICE}"
			echo "Creating new gpt partitions..."
			parted "${DEVICE}" mklabel gpt
		else
			printf "\nNothing has been written.\nYou canceled the destructive install, please try again.\n"
			echo 'Press any key to exit...'
			read -r -k1 -s
			exit 1
		fi
		;;
	2)
		printf "\nHoloISO will be installed alongside existing OS/Partition.\nPlease make sure there are more than 24 GB on the >>END<< of free(unallocate) space available.\n"
		parted "$DEVICE" print free
		echo "HoloISO will be installed on the following free (unallocated) space."
		if ! parted "$DEVICE" print free | tail -n2 | grep "Free Space"; then
			printf "Error! No Free Space found on the end of the disk.\nNothing has been written.\nYou canceled the non-destructive install, please try again.\n"
			echo 'Press any key to exit...'
			read -r -k1 -s
			exit 1
		fi
		if zenity --question --text "HoloISO will be installed on the following free (unallocated) space.\nDoes this look reasonable?\n$(sudo parted "${DEVICE}" print free | tail -n2 | grep "Free Space")" --width=500 2>/dev/null; then
			echo "Beginning installation..."
		else
			printf "\nNothing has been written.\nYou canceled the non-destructive install, please try again.\n"
			echo 'Press any key to exit...'
			read -r -k1 -s
			exit 1
		fi
		;;
	esac

	numPartitions=$(grep -c "${DRIVEDEVICE}"'[0-9]' /proc/partitions)

	if echo "${DEVICE}" | grep -q -P "^/dev/(nvme|loop|mmcblk)"; then
		INSTALLDEVICE="${DEVICE}"p
		numPartitions=$(grep -c "${DRIVEDEVICE}"p /proc/partitions)
	fi

	efiPartNum=$((numPartitions + 1))
	rootPartNum=$((numPartitions + 2))
	homePartNum=$((numPartitions + 3))

	echo "Calculating start and end of free space..."
	diskSpace=$(awk '/'"${DRIVEDEVICE}"'/ {print $3; exit}' /proc/partitions)
	realDiskSpace=$(parted "${DEVICE}" unit MB print free | head -n2 | tail -n1 | grep -oh "\w*MB" | sed s/MB//)

	if [ "$destructive" ]; then
		efiStart=2
	else
		efiStart=$(parted "${DEVICE}" unit MB print free | tail -n2 | awk '{$1=$1};1' | head -n1 | sed 's/\s.*$//' | sed s/MB//)
	fi
	efiEnd=$((efiStart + 256))
	rootStart=$efiEnd
	rootEnd=$((rootStart + 24000))

	if [ $efiEnd -gt "$realDiskSpace" ]; then
		echo "Not enough space available, please choose another disk and try again."
		echo 'Press any key to exit...'
		read -r -k1 -s
		exit 1
	fi

	echo "Creating partitions..."
	parted "${DEVICE}" mkpart primary fat32 "${efiStart}"M ${efiEnd}M
	parted "${DEVICE}" set ${efiPartNum} boot on
	parted "${DEVICE}" set ${efiPartNum} esp on
	# If the available storage is less than 64GB, don't create /home.
	# If the boot device is mmcblk0, don't create an ext4 partition or it will break steamOS versions
	# released after May 20.
	if [ "$diskSpace" -lt 64000000 ] || [[ "${DEVICE}" =~ mmcblk0 ]]; then
		parted "${DEVICE}" mkpart primary btrfs ${rootStart}M 100%
	else
		parted "${DEVICE}" mkpart primary btrfs ${rootStart}M ${rootEnd}M
		parted "${DEVICE}" mkpart primary ext4 ${rootEnd}M 100%
		home=true
	fi
	root_partition=${INSTALLDEVICE}${rootPartNum}
	mkfs -t vfat "${INSTALLDEVICE}"${efiPartNum}
	efi_partition="${INSTALLDEVICE}${efiPartNum}"
	fatlabel "${INSTALLDEVICE}"${efiPartNum} HOLOEFI
	mkfs -t btrfs -f "${root_partition}"
	btrfs filesystem label "${root_partition}" holo-root
	if [ "$home" ]; then
		if [[ -n "$(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)" ]]; then
			if [[ "${HOME_REUSE_TYPE}" == "1" ]]; then
				mkfs -t ext4 -F -O casefold "${INSTALLDEVICE}"${homePartNum}
				home_partition="${INSTALLDEVICE}${homePartNum}"
				e2label "${INSTALLDEVICE}${homePartNum}" holo-home
			elif [[ "${HOME_REUSE_TYPE}" == "2" ]]; then
				echo "Home partition will be reused at $(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)"
				home_partition="$(sudo blkid | grep holo-home | cut -d ':' -f 1 | head -n 1)"
			fi
		else
			mkfs -t ext4 -F -O casefold "${INSTALLDEVICE}"${homePartNum}
			home_partition="${INSTALLDEVICE}${homePartNum}"
			e2label "${INSTALLDEVICE}${homePartNum}" holo-home
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
	${CMD_MOUNT_BOOT}
	check_mount $? boot
	if [ "$home" ]; then
		mkdir -p "${HOLO_INSTALL_DIR}"/home
		mount -t ext4 "${home_partition}" "${HOLO_INSTALL_DIR}"/home
		check_mount $? home
	fi
	rsync -axHAWXS --numeric-ids --info=progress2 --no-inc-recursive / "${HOLO_INSTALL_DIR}" | tr '\r' '\n' | awk '/^ / { print int(+$2) ; next } $0 { print "# " $0 }' | zenity --progress --title="Installing base OS..." --text="Bootstrapping root filesystem...\nThis may take more than 10 minutes.\n" --width=500 --no-cancel --auto-close 2>/dev/null
	arch-chroot "${HOLO_INSTALL_DIR}" install -Dm644 "$(find /usr/lib | grep vmlinuz | grep neptune)" "/boot/vmlinuz-$(cat /usr/lib/modules/*neptune*/pkgbase)"
	arch-chroot "${HOLO_INSTALL_DIR}" install -Dm644 "$(find /usr/lib | grep vmlinuz | grep arch)" "/boot/vmlinuz-$(cat /usr/lib/modules/*arch*/pkgbase)"
	arch-chroot "${HOLO_INSTALL_DIR}" rm /etc/polkit-1/rules.d/99_holoiso_installuser.rules
	cp -r /etc/holoinstall/post_install/pacman.conf "${HOLO_INSTALL_DIR}"/etc/pacman.conf
	arch-chroot "${HOLO_INSTALL_DIR}" pacman-key --init
	arch-chroot "${HOLO_INSTALL_DIR}" pacman -Rdd --noconfirm mkinitcpio-archiso

	rm "${HOLO_INSTALL_DIR}"/usr/bin/gamescope-session
	mv /etc/holoinstall/post_install/gamescope-session "${HOLO_INSTALL_DIR}"/usr/bin/gamescope-session
	chmod +x "${HOLO_INSTALL_DIR}"/usr/bin/gamescope-session

	mv /etc/holoinstall/post_install/amd-perf-fix.service "${HOLO_INSTALL_DIR}"/etc/systemd/system/multi-user.target.wants
	mv /etc/holoinstall/post_install/amd-perf-fix "${HOLO_INSTALL_DIR}"/usr/bin/amd-perf-fix
	chmod +x "${HOLO_INSTALL_DIR}"/usr/bin/amd-perf-fix
	
	if [[ "$(lspci -v | grep VGA | sed -nE "s/.*(NVIDIA) .*/\1/p")" = "NVIDIA" ]]; then
		echo "LIBVA_DRIVER_NAME=nvidia" >>"${HOLO_INSTALL_DIR}"/etc/environment
		sed -i 's/MODULES=(/&nvidia nvidia_modeset nvidia_uvm nvidia_drm/' "${HOLO_INSTALL_DIR}"/etc/mkinitcpio.conf
		if $IS_LAPTOP; then
			echo 'GAMEMODERUNEXEC="env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only"' >>"${HOLO_INSTALL_DIR}"/etc/environment
		fi
	else
		pacman -Rdd --noconfirm nvidia-dkms-tkg nvidia-utils-tkg nvidia-egl-wayland-tkg nvidia-settings-tkg opencl-nvidia-tkg lib32-nvidia-utils-tkg lib32-opencl-nvidia-tkg libva-nvidia-driver-git
	fi
	arch-chroot "${HOLO_INSTALL_DIR}" mkinitcpio -P
	arch-chroot "${HOLO_INSTALL_DIR}" userdel -r liveuser
	sleep 2

	echo "Base system installation done, generating fstab..."
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
	arch-chroot "${HOLO_INSTALL_DIR}" locale-gen
	MAIN_LANGUAGE="$(echo "$MAIN_LANGUAGE" | cut -d' ' -f1)"
	echo "LANG=$MAIN_LANGUAGE" >"${HOLO_INSTALL_DIR}"/etc/locale.conf

	# Set keyboard layout
	echo "KEYMAP=$KEYBOARD_LAYOUT" >"${HOLO_INSTALL_DIR}"/etc/vconsole.conf
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
	mv /etc/holoinstall/post_install_shortcuts/steam.desktop /etc/holoinstall/post_install_shortcuts/desktopshortcuts.desktop "${HOLO_INSTALL_DIR}"/etc/xdg/autostart
	mv /etc/holoinstall/post_install_shortcuts/steamos-gamemode.desktop "${HOLO_INSTALL_DIR}"/etc/skel/Desktop
	echo "Creating user ${HOLOUSER}..."
	echo -e "${ROOTPASS}\n${ROOTPASS}" | arch-chroot "${HOLO_INSTALL_DIR}" passwd root
	arch-chroot "${HOLO_INSTALL_DIR}" useradd --create-home "${HOLOUSER}"
	echo -e "${HOLOPASS}\n${HOLOPASS}" | arch-chroot "${HOLO_INSTALL_DIR}" passwd "${HOLOUSER}"
	echo "${HOLOUSER} ALL=(root) NOPASSWD:ALL" >"${HOLO_INSTALL_DIR}"/etc/sudoers.d/"${HOLOUSER}"
	chmod 0440 "${HOLO_INSTALL_DIR}"/etc/sudoers.d/"${HOLOUSER}"
	sleep 1

	if $INSTALL_XONE_DRIVER; then
		# Install xone-dongle-firmware
		echo The firmware for the wireless dongle is subject to Microsofts Terms of Use:
		echo https://www.microsoft.com/en-us/legal/terms-of-use
		mkdir "${HOLO_INSTALL_DIR}"/etc/xone
		wget https://aur.archlinux.org/cgit/aur.git/snapshot/xone-dongle-firmware.tar.gz -P "${HOLO_INSTALL_DIR}"/etc/xone
		cd "${HOLO_INSTALL_DIR}"/etc/xone && tar -xf "${HOLO_INSTALL_DIR}"/etc/xone/xone-dongle-firmware.tar.gz
		arch-chroot "${HOLO_INSTALL_DIR}" chown -hR "${HOLOUSER}" /etc/xone/xone-dongle-firmware
		arch-chroot "${HOLO_INSTALL_DIR}" su "${HOLOUSER}" -c "cd /etc/xone/xone-dongle-firmware && makepkg -si --noconfirm"

		# Install xone-dkms-git driver
		wget https://aur.archlinux.org/cgit/aur.git/snapshot/xone-dkms-git.tar.gz -P "${HOLO_INSTALL_DIR}"/etc/xone
		cd "${HOLO_INSTALL_DIR}"/etc/xone && tar -xf "${HOLO_INSTALL_DIR}"/etc/xone/xone-dkms-git.tar.gz
		arch-chroot "${HOLO_INSTALL_DIR}" chown -hR "${HOLOUSER}" /etc/xone/xone-dkms-git
		arch-chroot "${HOLO_INSTALL_DIR}" su "${HOLOUSER}" -c "cd /etc/xone/xone-dkms-git && makepkg -si --noconfirm"
		rm -r "${HOLO_INSTALL_DIR}"/etc/xone
	fi

	if $INSTALL_DECKY_LOADER; then
		arch-chroot "${HOLO_INSTALL_DIR}" su "$HOLOUSER" -c "curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh"
	fi

	if $INSTALL_EMUDECK; then
		arch-chroot "${HOLO_INSTALL_DIR}" su "$HOLOUSER" -c "curl -L https://raw.githubusercontent.com/dragoonDorise/EmuDeck/main/install.sh | sh"
		chmod +x "${HOLO_INSTALL_DIR}"/home/"${HOLOUSER}"/Applications/EmuDeck.AppImage
		HOME=${HOLO_INSTALL_DIR}/home/${HOLOUSER} "${HOLO_INSTALL_DIR}"/home/"${HOLOUSER}"/Applications/EmuDeck.AppImage
	fi

	echo "Installing bootloader..."
	mkdir -p "${HOLO_INSTALL_DIR}"/boot/efi
	mount -t vfat "${efi_partition}" "${HOLO_INSTALL_DIR}"/boot/efi
	rm "${HOLO_INSTALL_DIR}"/etc/default/grub
	mv /etc/holoinstall/post_install/grub "${HOLO_INSTALL_DIR}"/etc/default/grub
	arch-chroot "${HOLO_INSTALL_DIR}" holoiso-grub-update
	sleep 1

	arch-chroot "${HOLO_INSTALL_DIR}" pacman -Syyu --noconfirm
}

full_install() {
	if $GAMEPAD_DRV; then
		echo "You're running this on Anbernic Win600. A suitable gamepad driver will be installed."
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm /etc/holoinstall/post_install/pkgs_addon/win600-xpad-dkms*.pkg.tar.zst
	fi
	if $FIRMWARE_INSTALL; then
		echo "You're running this on a Steam Deck. linux-firmware-neptune will be installed to ensure maximum kernel-side compatibility."
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -Rdd --noconfirm linux-firmware
		arch-chroot "${HOLO_INSTALL_DIR}" pacman -U --noconfirm /etc/holoinstall/post_install/pkgs_addon/linux-firmware-neptune*.pkg.tar.zst
		arch-chroot "${HOLO_INSTALL_DIR}" mkinitcpio -P
	else
		sed -i 's!/usr/lib/hwsupport/power-button-handler.py!/usr/lib/holoiso-hwsupport/power-button-handler.py!' "${HOLO_INSTALL_DIR}"/usr/bin/gamescope-session
	fi
	echo "Configuring Steam Deck UI by default..."
	ln -s /usr/share/applications/steam.desktop "${HOLO_INSTALL_DIR}"/etc/skel/Desktop/steam.desktop
	echo -e "[General]\nDisplayServer=wayland\n\n[Autologin]\nUser=${HOLOUSER}\nSession=gamescope-wayland.desktop\nRelogin=true\n\n[X11]\n# Janky workaround for wayland sessions not stopping in sddm, kills\n# all active sddm-helper sessions on teardown\nDisplayStopCommand=/usr/bin/gamescope-wayland-teardown-workaround" >>"${HOLO_INSTALL_DIR}"/etc/sddm.conf.d/autologin.conf
	arch-chroot "${HOLO_INSTALL_DIR}" usermod -a -G rfkill "${HOLOUSER}"
	arch-chroot "${HOLO_INSTALL_DIR}" usermod -a -G wheel "${HOLOUSER}"
	echo "Preparing Steam OOBE..."
	arch-chroot "${HOLO_INSTALL_DIR}" touch /etc/holoiso-oobe
	echo "Cleaning up..."
	cp /etc/skel/.bashrc "${HOLO_INSTALL_DIR}"/home/"${HOLOUSER}"
	arch-chroot "${HOLO_INSTALL_DIR}" rm -rf /etc/holoinstall
	sleep 1
}

# The installer itself. Good wuck.
echo "SteamOS 3 Installer"
echo "Start time: $(date)"
echo "Please choose installation type:"
HOLO_INSTALL_TYPE=$(zenity --list --title="Choose your installation type:" --column="Type" --column="Name" 1 "Install HoloISO, version $(grep </etc/os-release VARIANT_ID | cut -d "=" -f 2 | sed 's/"//g') " 2 "Exit installer" --width=700 --height=220 2>/dev/null)
if [[ "${HOLO_INSTALL_TYPE}" == "1" ]] || [[ "${HOLO_INSTALL_TYPE}" == "barebones" ]]; then
	echo "Installing SteamOS, barebones configuration..."
	information_gathering
	base_os_install
	full_install
	zenity --info --text="Installation finished! You may reboot now, or type arch-chroot /mnt to make further changes" --width=700 --height=50 2>/dev/null
else
	zenity --info --text="Exiting installer..." --width=120 --height=50 2>/dev/null
fi

echo "End time: $(date)"
