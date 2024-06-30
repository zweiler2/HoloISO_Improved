#!/bin/bash
# Prepares ISO for packaging

# Prepare thyself
chmod +x /etc/holoinstall/post_install/install_holoiso.sh
chmod +x /etc/holoinstall/post_install/chroot_holoiso.sh
chmod +x /etc/holoinstall/post_install/gamescope_downgrader.sh
chmod +x /etc/skel/Desktop/gamescope_downgrader.desktop
chmod 755 /etc/skel/Desktop/gamescope_downgrader.desktop
chmod +x /etc/skel/Desktop/install.desktop
chmod 755 /etc/skel/Desktop/install.desktop
# Begin coreOS bootstrapping below:

# Init pacman keys
pacman-key --init
pacman-key --populate
pacman -Sy

# Install desktop suite
pacman -Rdd --noconfirm syslinux
pacman --overwrite="*" --noconfirm -S holoiso-main holoiso-updateclient

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
echo "/usr/bin/bash" >>/etc/shells
mkdir -p /var/cache/pacman/
mv /home/.steamos/offload/var/cache/pacman/pkg /var/cache/pacman/
mv /etc/xdg/autostart/steam.desktop /etc/skel/Desktop/steamos-gamemode.desktop /etc/holoinstall/post_install_shortcuts
sed -i 's/base udev modconf/base udev plymouth modconf/g' /etc/mkinitcpio.conf
rm /usr/share/steamos/steamos.png
ln -s ../plymouth/themes/steamos/steamos-jupiter.png /usr/share/steamos/steamos.png
sed -i 's/steamos.png/steamos-jupiter.png/' /usr/share/plymouth/themes/steamos/steamos.script
echo "FONT=ter-132b" >>/etc/vconsole.conf
plymouth-set-default-theme -R steamos

# Enable stuff
systemctl enable sddm NetworkManager systemd-timesyncd cups bluetooth sshd

# Download extra stuff
mkdir /etc/holoinstall/post_install/pkgs
wget "$(pacman -Sp linux-firmware-neptune)" -P /etc/holoinstall/post_install/pkgs
wget "$(pacman -Sp linux-neptune-61)" -P /etc/holoinstall/post_install/pkgs
wget "$(pacman -Sp amd-ucode)" -P /etc/holoinstall/post_install/pkgs
wget "$(pacman -Sp intel-ucode)" -P /etc/holoinstall/post_install/pkgs
wget "$(pacman -Sp broadcom-wl-dkms)" -P /etc/holoinstall/post_install/pkgs
wget "$(pacman -Sp dbus-glib)" -P /etc/holoinstall/post_install/pkgs
wget "$(pacman -Spdd xboxdrv-stable-git)" -P /etc/holoinstall/post_install/pkgs
wget "$(pacman -Spdd 8bitdo-ultimate-controller-udev)" -P /etc/holoinstall/post_install/pkgs
wget "$(pacman -Sp nvidia-dkms-tkg)" -P /etc/holoinstall/post_install/pkgs
mv /etc/holoinstall/post_install/gamescope-holoiso-tweaked-3.11.48-4-x86_64.pkg.tar.zst /etc/holoinstall/post_install/pkgs/

# Workaround mkinitcpio stuff so that i don't KMS after rebuilding ISO each time and having users reinstalling their OS everytime.
rm /etc/mkinitcpio.conf
mv /etc/holoinstall/pre_install/mkinitcpio.conf /etc/mkinitcpio.conf
rm /etc/mkinitcpio.d/*
mkdir -p /etc/mkinitcpio.d

# Remove this script from ISO
rm -rf /etc/holoinstall/pre_install
rm -rf /home/.steamos/offload/var/cache/pacman/pkg/*
rm -rf /etc/xdg/powermanagementprofilesrc
rm -rf /home/"${LIVEOSUSER}"/Desktop/steamos-gamemode.desktop
rm -rf /home/"${LIVEOSUSER}"/Desktop/Return.desktop
