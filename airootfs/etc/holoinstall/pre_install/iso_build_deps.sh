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

# Remove stupid stuff on build
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
pacman --overwrite="*" --noconfirm -S holoiso-main
mv /etc/pacman.conf /etc/pacold
cp /etc/holoinstall/post_install/pacman.conf /etc/pacman.conf
pacman --overwrite="*" --noconfirm -S holoiso-updateclient wireplumber flatpak packagekit-qt5 rsync unzip sddm-wayland dkms steam-im-modules systemd-swap ttf-twemoji-default ttf-hack ttf-dejavu pkgconf pavucontrol partitionmanager gamemode lib32-gamemode cpupower bluez-plugins bluez-utils
mv /etc/xdg/autostart/steam.desktop /etc/xdg/autostart/desktopshortcuts.desktop /etc/skel/Desktop/steamos-gamemode.desktop /etc/holoinstall/post_install_shortcuts
pacman --noconfirm -S base-devel

# Enable stuff
systemctl enable sddm NetworkManager systemd-timesyncd cups bluetooth sshd

# Remove old Kernel
pacman -Rdd --noconfirm linux-neptune linux-neptune-headers

# Download Valves linux 6.1 kernel
mkdir -p /etc/holoinstall/post_install/pkgs/Kernel_61
wget https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-main/os/x86_64/linux-neptune-61-6.1.21.valve1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Kernel_61
wget https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-main/os/x86_64/linux-neptune-61-headers-6.1.21.valve1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Kernel_61

# Download Mesa 23.1.1
mkdir -p /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/m/mesa/mesa-23.1.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/v/vulkan-radeon/vulkan-radeon-23.1.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/v/vulkan-mesa-layers/vulkan-mesa-layers-23.1.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/m/mesa-vdpau/mesa-vdpau-23.1.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/libva/libva-2.18.0-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/libva-utils/libva-utils-2.18.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/libva-mesa-driver/libva-mesa-driver-23.1.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/llvm/llvm-15.0.7-3-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/llvm-libs/llvm-libs-15.0.7-3-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/v/vulkan-intel/vulkan-intel-23.1.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/i/intel-media-driver/intel-media-driver-23.1.0-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/libva-intel-driver/libva-intel-driver-2.4.1-2-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa

wget https://archive.archlinux.org/packages/l/lib32-mesa/lib32-mesa-23.1.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-vulkan-radeon/lib32-vulkan-radeon-23.1.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-vulkan-mesa-layers/lib32-vulkan-mesa-layers-23.1.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-mesa-vdpau/lib32-mesa-vdpau-23.1.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-libva/lib32-libva-2.18.0-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-libva-mesa-driver/lib32-libva-mesa-driver-23.1.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-llvm/lib32-llvm-15.0.7-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-llvm-libs/lib32-llvm-libs-15.0.7-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-vulkan-intel/lib32-vulkan-intel-23.1.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa
wget https://archive.archlinux.org/packages/l/lib32-libva-intel-driver/lib32-libva-intel-driver-2.4.1-1-x86_64.pkg.tar.zst -P /etc/holoinstall/post_install/pkgs/Mesa

# Install downloaded packages
pacman -U --noconfirm /etc/holoinstall/post_install/pkgs/Kernel_61/*x86_64.pkg.tar.zst /etc/holoinstall/post_install/pkgs/Mesa/*x86_64.pkg.tar.zst

# Install Nvidia driver
cd /etc/holoinstall/post_install/pkgs && git clone https://github.com/Frogging-Family/nvidia-all.git
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/nvidia-all
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/nvidia-all && echo -e '4\n1\nN\n\n\n' | makepkg -si --noconfirm"

# Install Nvidia vaapi driver
wget https://aur.archlinux.org/cgit/aur.git/snapshot/libva-nvidia-driver-git.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/libva-nvidia-driver-git.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/libva-nvidia-driver-git
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/libva-nvidia-driver-git && makepkg -si --noconfirm"

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
rm /etc/mkinitcpio.d/*                                                                         # This removes unasked presets so that this thing can't overwrite it next time
cp /etc/holoinstall/post_install/mkinitcpio_presets/linux-neptune-61.preset /etc/mkinitcpio.d/ # Yes. I'm lazy to use mkinitcpio-install. Problems? *gigachad posture*

# Remove this script from ISO
rm /etc/pacman.conf
mv /etc/pacold /etc/pacman.conf
rm /home/.steamos/offload/var/cache/pacman/pkg/*
rm -rf /etc/holoinstall/pre_install
