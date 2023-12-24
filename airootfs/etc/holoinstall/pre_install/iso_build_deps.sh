#!/bin/bash
# Prepares ISO for packaging

# Prepare thyself
chmod +x /etc/holoinstall/post_install/install_holoiso.sh
chmod +x /etc/holoinstall/post_install/chroot_holoiso.sh
chmod +x /etc/skel/Desktop/install.desktop
chmod 755 /etc/skel/Desktop/install.desktop
# Begin coreOS bootstrapping below:

# Init pacman keys
pacman-key --init
pacman -Sy

# Install desktop suite
pacman -Rcns --noconfirm pulseaudio xfce4-pulseaudio-plugin pulseaudio-alsa
pacman -Rdd --noconfirm sddm syslinux
pacman --overwrite="*" --noconfirm -S holoiso-main

# Remove useless shortcuts for now
mkdir /etc/holoinstall/post_install_shortcuts
mv /etc/skel/Desktop/Return.desktop /etc/holoinstall/post_install_shortcuts
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
mkdir -p /var/cache/pacman/
mv /.steamos/offload/var/cache/pacman/pkg /var/cache/pacman/
mv /etc/pacman.conf /etc/pacold
cp /etc/holoinstall/post_install/pacman.conf /etc/pacman.conf
pacman -Rdd --noconfirm sddm
pacman --overwrite="*" --noconfirm -S holoiso-updateclient wireplumber flatpak packagekit-qt5 rsync unzip sddm-wayland dkms steam-im-modules systemd-swap ttf-twemoji-default ttf-hack ttf-dejavu pkgconf pavucontrol partitionmanager gamemode lib32-gamemode cpupower bluez-plugins bluez-utils
mv /etc/xdg/autostart/steam.desktop /etc/skel/Desktop/steamos-gamemode.desktop /etc/holoinstall/post_install_shortcuts
pacman --noconfirm -S base-devel
sed -i 's/base udev modconf/base udev plymouth modconf/g' /etc/mkinitcpio.conf
pacman --overwrite="*" --noconfirm -S handygccs-git extra-main/mesa extra-main/vulkan-radeon extra-main/vulkan-intel multilib-main/lib32-mesa multilib-main/lib32-vulkan-radeon multilib-main/lib32-vulkan-intel
rm /usr/share/steamos/steamos.png
ln -s ../plymouth/themes/steamos/steamos-jupiter.png /usr/share/steamos/steamos.png
sed -i 's/steamos.png/steamos-jupiter.png/' /usr/share/plymouth/themes/steamos/steamos.script
echo "FONT=ter-132b" >>/etc/vconsole.conf
plymouth-set-default-theme -R steamos
mkinitcpio -P

# Enable stuff
systemctl enable sddm NetworkManager systemd-timesyncd cups bluetooth sshd

# Install Firmwares
wget https://aur.archlinux.org/cgit/aur.git/snapshot/aic94xx-firmware.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/aic94xx-firmware.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/aic94xx-firmware
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/aic94xx-firmware && makepkg -si --noconfirm"

wget https://aur.archlinux.org/cgit/aur.git/snapshot/ast-firmware.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/ast-firmware.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/ast-firmware
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/ast-firmware && makepkg -si --noconfirm"

wget https://aur.archlinux.org/cgit/aur.git/snapshot/wd719x-firmware.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/wd719x-firmware.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/wd719x-firmware
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/wd719x-firmware && makepkg -si --noconfirm"

wget https://aur.archlinux.org/cgit/aur.git/snapshot/upd72020x-fw.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/upd72020x-fw.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/upd72020x-fw
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/upd72020x-fw && makepkg -si --noconfirm"

wget https://aur.archlinux.org/cgit/aur.git/snapshot/mkinitcpio-firmware.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/mkinitcpio-firmware.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/mkinitcpio-firmware
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/mkinitcpio-firmware && makepkg -si --noconfirm"

# Build xboxdrv package
wget https://aur.archlinux.org/cgit/aur.git/snapshot/xboxdrv-stable-git.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/xboxdrv-stable-git.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/xboxdrv-stable-git
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/xboxdrv-stable-git && makepkg -si --noconfirm"
cp /etc/holoinstall/post_install/pkgs/xboxdrv-stable-git/xboxdrv-stable-git*.pkg.tar.zst /etc/holoinstall/post_install/

# Build 8bitdo-ultimate-controller-udev rules package
wget https://aur.archlinux.org/cgit/aur.git/snapshot/8bitdo-ultimate-controller-udev.tar.gz -P /etc/holoinstall/post_install/pkgs
cd /etc/holoinstall/post_install/pkgs && tar -xf /etc/holoinstall/post_install/pkgs/8bitdo-ultimate-controller-udev.tar.gz
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/8bitdo-ultimate-controller-udev
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/8bitdo-ultimate-controller-udev && makepkg -s --noconfirm"
cp /etc/holoinstall/post_install/pkgs/8bitdo-ultimate-controller-udev/8bitdo-ultimate-controller-udev*.pkg.tar.zst /etc/holoinstall/post_install/
pacman -Rdd --noconfirm xboxdrv-stable-git

# Install Nvidia driver
cd /etc/holoinstall/post_install/pkgs && git clone https://github.com/Frogging-Family/nvidia-all.git
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/nvidia-all
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/nvidia-all && echo -e '3\n1\nN\n' | makepkg -si --noconfirm"
cp /etc/holoinstall/post_install/pkgs/nvidia-all/nvidia-dkms*.pkg.tar.zst /etc/holoinstall/post_install/

# Install Nvidia vaapi driver
cd /etc/holoinstall/post_install/pkgs && git clone https://gitlab.archlinux.org/archlinux/packaging/packages/libva-nvidia-driver.git
chown -hR ${LIVEOSUSER} /etc/holoinstall/post_install/pkgs/libva-nvidia-driver
su ${LIVEOSUSER} -c "cd /etc/holoinstall/post_install/pkgs/libva-nvidia-driver && makepkg -si --noconfirm"

# Install Nvidia prime
pacman -Syyu --noconfirm nvidia-prime

# Remove packages from ISO
rm -r /etc/holoinstall/post_install/pkgs/*

# Download extra stuff
wget "$(pacman -Sp win600-xpad-dkms)" -P /etc/holoinstall/post_install/pkgs
wget "$(pacman -Sp linux-firmware-neptune)" -P /etc/holoinstall/post_install/pkgs
wget "$(pacman -Sp linux-neptune-61)" -P /etc/holoinstall/post_install/pkgs
wget "$(pacman -Sp amd-ucode)" -P /etc/holoinstall/post_install/pkgs
wget "$(pacman -Sp intel-ucode)" -P /etc/holoinstall/post_install/pkgs
wget "$(pacman -Sp xorg-xwayland-jupiter)" -P /etc/holoinstall/post_install/pkgs
wget "$(pacman -Sp broadcom-wl-dkms)" -P /etc/holoinstall/post_install/pkgs
mv /etc/holoinstall/post_install/nvidia-dkms*.pkg.tar.zst /etc/holoinstall/post_install/pkgs
mv /etc/holoinstall/post_install/xboxdrv-stable-git*.pkg.tar.zst /etc/holoinstall/post_install/pkgs/
mv /etc/holoinstall/post_install/8bitdo-ultimate-controller-udev*.pkg.tar.zst /etc/holoinstall/post_install/pkgs/

# Workaround mkinitcpio stuff so that i don't KMS after rebuilding ISO each time and having users reinstalling their OS everytime.
rm /etc/mkinitcpio.conf
mv /etc/holoinstall/pre_install/mkinitcpio.conf /etc/mkinitcpio.conf
rm /etc/mkinitcpio.d/*
mkdir -p /etc/mkinitcpio.d

pacman -Syu --noconfirm grub

# Remove this script from ISO
rm -rf /etc/holoinstall/pre_install
rm -rf /home/.steamos/offload/var/cache/pacman/pkg/*
rm /etc/pacman.conf
mv /etc/pacold /etc/pacman.conf
rm -rf /etc/xdg/powermanagementprofilesrc
rm -rf /home/"${LIVEOSUSER}"/Desktop/steamos-gamemode.desktop
rm -rf /home/"${LIVEOSUSER}"/Desktop/Return.desktop
