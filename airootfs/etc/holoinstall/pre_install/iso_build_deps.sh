#!/bin/bash
# Prepares ISO for packaging

# Remove useless shortcuts for now
mkdir /etc/holoinstall/post_install_shortcuts
mv /etc/skel/Desktop/Return.desktop /etc/holoinstall/post_install_shortcuts

# Prepare thyself
chmod +x /etc/holoinstall/post_install/install_holoiso.sh
chmod +x /etc/holoinstall/post_install/chroot_holoiso.sh
chmod +x /etc/skel/Desktop/install.desktop
chmod 755 /etc/skel/Desktop/install.desktop

# Remove steam shortcut on ISO
rm /home/"${LIVEOSUSER}"/steam.desktop

# Add a liveOS user
ROOTPASS="holoiso"
LIVEOSUSER="liveuser"

echo -e "${ROOTPASS}\n${ROOTPASS}" | passwd root
useradd --create-home ${LIVEOSUSER}
echo -e "${ROOTPASS}\n${ROOTPASS}" | passwd ${LIVEOSUSER}
echo "${LIVEOSUSER} ALL=(root) NOPASSWD:ALL" >/etc/sudoers.d/${LIVEOSUSER}
chmod 0440 /etc/sudoers.d/${LIVEOSUSER}
usermod -a -G rfkill ${LIVEOSUSER}
usermod -a -G wheel ${LIVEOSUSER}
# Begin coreOS bootstrapping below:

# Init pacman keys
pacman-key --init
pacman -Sy

# Install desktop suite
pacman -Rcns --noconfirm pulseaudio xfce4-pulseaudio-plugin pulseaudio-alsa
pacman -Rdd --noconfirm sddm linux syslinux
rm -r /usr/lib/modules/6.0.2-arch1-1
pacman --overwrite="*" --noconfirm -S holoiso-main
rm /etc/pacman.d/holo_mirrorlist
cp /etc/holoinstall/post_install/holo_mirrorlist /etc/pacman.d/holo_mirrorlist
pacman -Rdd --noconfirm rz608-fix-git
mv /etc/pacman.conf /etc/pacold
cp /etc/holoinstall/post_install/pacman.conf /etc/pacman.conf
pacman --overwrite="*" --noconfirm -S holoiso-updateclient wireplumber flatpak packagekit-qt5 rsync unzip sddm-wayland dkms steam-im-modules systemd-swap ttf-twemoji-default ttf-hack ttf-dejavu pkgconf pavucontrol partitionmanager gamemode lib32-gamemode cpupower bluez-plugins bluez-utils
mv /etc/xdg/autostart/steam.desktop /etc/xdg/autostart/desktopshortcuts.desktop /etc/skel/Desktop/steamos-gamemode.desktop /etc/holoinstall/post_install_shortcuts
pacman --noconfirm -S base-devel

# Enable stuff
systemctl enable sddm NetworkManager systemd-timesyncd cups bluetooth sshd

# Remove old Kernel
pacman -Rdd --noconfirm linux-neptune linux-neptune-headers

# Download Archs linux 6.3 kernel
mkdir -p /etc/holoinstall/post_install/pkgs/Archs_Kernel
wget https://archive.archlinux.org/packages/l/linux/linux-6.3.9.arch1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Archs_Kernel
wget https://archive.archlinux.org/packages/l/linux-headers/linux-headers-6.3.9.arch1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Archs_Kernel

# Download Valves linux 6.1 kernel with HDR patch
mkdir -p /etc/holoinstall/post_install/pkgs/Valves_Kernel
wget https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-main/os/x86_64/linux-neptune-61-6.1.21.joshcolor2-3-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Valves_Kernel
wget https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-main/os/x86_64/linux-neptune-61-headers-6.1.21.joshcolor2-3-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Valves_Kernel

# Download openssl
mkdir -p /etc/holoinstall/post_install/pkgs/OpenSSL
wget https://archive.archlinux.org/packages/o/openssl/openssl-3.1.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/OpenSSL
wget https://archive.archlinux.org/packages/o/openssl-1.1/openssl-1.1-1.1.1.u-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/OpenSSL

# Update Ucodes
mkdir -p /etc/holoinstall/post_install/pkgs/Ucodes
wget https://archive.archlinux.org/packages/a/amd-ucode/amd-ucode-20230625.ee91452d-4-any.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Ucodes
wget https://archive.archlinux.org/packages/i/intel-ucode/intel-ucode-20230613-1-any.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Ucodes

# Update linux-firmware
mkdir /etc/holoinstall/post_install/pkgs/Firmware
wget https://archive.archlinux.org/packages/l/linux-firmware/linux-firmware-20230404.2e92a49f-1-any.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Firmware

wget https://archive.archlinux.org/packages/l/linux-firmware-qlogic/linux-firmware-qlogic-20230404.2e92a49f-1-any.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Firmware
wget https://archive.archlinux.org/packages/l/linux-firmware-bnx2x/linux-firmware-bnx2x-20230404.2e92a49f-1-any.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Firmware
wget https://archive.archlinux.org/packages/l/linux-firmware-liquidio/linux-firmware-liquidio-20230404.2e92a49f-1-any.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Firmware
wget https://archive.archlinux.org/packages/l/linux-firmware-mellanox/linux-firmware-mellanox-20230404.2e92a49f-1-any.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Firmware
wget https://archive.archlinux.org/packages/l/linux-firmware-nfp/linux-firmware-nfp-20230404.2e92a49f-1-any.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Firmware

wget https://aur.archlinux.org/cgit/aur.git/snapshot/aic94xx-firmware.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/aic94xx-firmware.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/aic94xx-firmware
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/aic94xx-firmware && makepkg -s"
mv /etc/holoinstall/post_install/pkgs/aic94xx-firmware/aic94xx-firmware*.pkg.tar.zst /etc/holoinstall/post_install/pkgs/Firmware

wget https://aur.archlinux.org/cgit/aur.git/snapshot/ast-firmware.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/ast-firmware.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/ast-firmware
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/ast-firmware && makepkg -s"
mv /etc/holoinstall/post_install/pkgs/ast-firmware/ast-firmware*.pkg.tar.zst /etc/holoinstall/post_install/pkgs/Firmware

wget https://aur.archlinux.org/cgit/aur.git/snapshot/wd719x-firmware.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/wd719x-firmware.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/wd719x-firmware
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/wd719x-firmware && makepkg -s --noconfirm"
mv /etc/holoinstall/post_install/pkgs/wd719x-firmware/wd719x-firmware*.pkg.tar.zst /etc/holoinstall/post_install/pkgs/Firmware

wget https://aur.archlinux.org/cgit/aur.git/snapshot/upd72020x-fw.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/upd72020x-fw.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/upd72020x-fw
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/upd72020x-fw && makepkg -s"
mv /etc/holoinstall/post_install/pkgs/upd72020x-fw/upd72020x-fw*.pkg.tar.zst /etc/holoinstall/post_install/pkgs/Firmware

# Download sof-firmware
wget https://archive.archlinux.org/packages/s/sof-firmware/sof-firmware-2.2.5-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Firmware

# Download Mesa 23.1.3
mkdir -p /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/m/mesa/mesa-23.1.3-2-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/v/vulkan-radeon/vulkan-radeon-23.1.3-2-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/v/vulkan-mesa-layers/vulkan-mesa-layers-23.1.3-2-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/m/mesa-vdpau/mesa-vdpau-23.1.3-2-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/libva/libva-2.19.0-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/libva-utils/libva-utils-2.18.2-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/libva-mesa-driver/libva-mesa-driver-23.1.3-2-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/llvm/llvm-15.0.7-3-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/llvm-libs/llvm-libs-15.0.7-3-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/v/vulkan-intel/vulkan-intel-23.1.3-2-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/i/intel-media-driver/intel-media-driver-23.3.0-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/libva-intel-driver/libva-intel-driver-2.4.1-2-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/i/intel-gmmlib/intel-gmmlib-22.3.3-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa

wget https://archive.archlinux.org/packages/l/lib32-mesa/lib32-mesa-23.1.3-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-vulkan-radeon/lib32-vulkan-radeon-23.1.3-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-vulkan-mesa-layers/lib32-vulkan-mesa-layers-23.1.3-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-mesa-vdpau/lib32-mesa-vdpau-23.1.3-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-libva/lib32-libva-2.18.0-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-libva-mesa-driver/lib32-libva-mesa-driver-23.1.3-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-llvm/lib32-llvm-15.0.7-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-llvm-libs/lib32-llvm-libs-15.0.7-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-vulkan-intel/lib32-vulkan-intel-23.1.3-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-libva-intel-driver/lib32-libva-intel-driver-2.4.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa

wget https://archive.archlinux.org/packages/x/xf86-video-amdgpu/xf86-video-amdgpu-23.0.0-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa

# Install downloaded packages
pacman -U --noconfirm \
    /etc/holoinstall/post_install/pkgs/Archs_Kernel/*x86_64.pkg.tar.zst \
    /etc/holoinstall/post_install/pkgs/Valves_Kernel/*x86_64.pkg.tar.zst \
    /etc/holoinstall/post_install/pkgs/OpenSSL/*x86_64.pkg.tar.zst \
    /etc/holoinstall/post_install/pkgs/Ucodes/*.pkg.tar.zst \
    /etc/holoinstall/post_install/pkgs/Firmware/*.pkg.tar.zst \
    /etc/holoinstall/post_install/pkgs/Mesa/*x86_64.pkg.tar.zst

wget https://aur.archlinux.org/cgit/aur.git/snapshot/mkinitcpio-firmware.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/mkinitcpio-firmware.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/mkinitcpio-firmware
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/mkinitcpio-firmware && makepkg -si --noconfirm"

# Install broadcom-wl-dkms
mkdir -p /etc/holoinstall/post_install/pkgs/Broadcom
wget https://archive.archlinux.org/packages/b/broadcom-wl-dkms/broadcom-wl-dkms-6.30.223.271-36-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Broadcom
pacman -Rdd --noconfirm broadcom-wl &&
    pacman -U --noconfirm /etc/holoinstall/post_install/pkgs/Broadcom/*x86_64.pkg.tar.zst

# Install steam_notif_daemon
mkdir -p /etc/holoinstall/post_install/pkgs/Other
wget https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-main/os/x86_64/steam_notif_daemon-v1.0.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Other

# Update gamescope and mangohud
wget https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-main/os/x86_64/gamescope-3.11.51-4-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Other
wget https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-main/os/x86_64/mangohud-0.6.9.1.r22.g1d8f9f6-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Other
wget https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-main/os/x86_64/lib32-mangohud-0.6.9.1.r22.g1d8f9f6-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Other
pacman -U --noconfirm /etc/holoinstall/post_install/pkgs/Other/*x86_64.pkg.tar.zst

# Install xpad-noone-dkms driver
wget https://aur.archlinux.org/cgit/aur.git/snapshot/xpad-noone-dkms.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/xpad-noone-dkms.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/xpad-noone-dkms
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/xpad-noone-dkms && makepkg -si --noconfirm"

# Install xboxdrv
wget https://aur.archlinux.org/cgit/aur.git/snapshot/xboxdrv.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/xboxdrv.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/xboxdrv
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/xboxdrv && makepkg -si --noconfirm"

# Install 8bitdo-ultimate-controller-udev rules
wget https://aur.archlinux.org/cgit/aur.git/snapshot/8bitdo-ultimate-controller-udev.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/8bitdo-ultimate-controller-udev.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/8bitdo-ultimate-controller-udev
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/8bitdo-ultimate-controller-udev && makepkg -si --noconfirm"

# Install Nvidia driver
cd /etc/holoinstall/post_install/pkgs && git clone https://github.com/Frogging-Family/nvidia-all.git
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/nvidia-all
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/nvidia-all && echo -e '5\n1\n1\nN\n\n\n' | makepkg -si --noconfirm"

# Install Nvidia vaapi driver
wget https://aur.archlinux.org/cgit/aur.git/snapshot/libva-nvidia-driver-git.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/libva-nvidia-driver-git.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/libva-nvidia-driver-git
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/libva-nvidia-driver-git && makepkg -si --noconfirm"

# Install Nvidia prime
pacman -Syyu --noconfirm nvidia-prime

# Update and install os-prober
pacman -Syyu --noconfirm os-prober

# Remove packages from ISO
rm -r /etc/holoinstall/post_install/pkgs

# Download extra stuff
wget "$(pacman -Sp win600-xpad-dkms)" -P /etc/holoinstall/post_install/pkgs_addon
wget "$(pacman -Sp linux-firmware-neptune)" -P /etc/holoinstall/post_install/pkgs_addon

# Workaround mkinitcpio stuff so that i don't KMS after rebuilding ISO each time and having users reinstalling their OS everytime.
rm /etc/mkinitcpio.conf
mv /etc/mkinitcpio.conf.pacnew /etc/mkinitcpio.conf
rm /etc/mkinitcpio.d/*
cp /etc/holoinstall/post_install/mkinitcpio_presets/linux-neptune-61.preset /etc/mkinitcpio.d/
cp /etc/holoinstall/post_install/mkinitcpio_presets/linux.preset /etc/mkinitcpio.d/

# Remove this script from ISO
rm /etc/pacman.conf
mv /etc/pacold /etc/pacman.conf
rm /home/.steamos/offload/var/cache/pacman/pkg/*
rm -rf /etc/holoinstall/pre_install
