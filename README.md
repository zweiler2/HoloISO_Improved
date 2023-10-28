![image](https://user-images.githubusercontent.com/97450182/167457908-07be1a60-7e86-4bef-b7f0-6bd19efd8b24.png)
# HoloISO_Tweaked
First of all i want to credit [Adam Jafarov](https://github.com/theVakhovskeIsTaken) for creating the HoloISO project! So please go check him out.

Note: I am not in any way affiliated with [Adam Jafarov](https://github.com/theVakhovskeIsTaken).  
This is not a competition of "Who makes the better HoloISO?" or something like that.  
I just like the project he made and saw some things that didn't work for me or i'd like to see changed.  
So i changed some things and made them public, because it might help someone.  
There is no bad blood between us.

SteamOS 3 (Holo) archiso configuration.

***Yes, Gabe. SteamOS functions well on a toaster.***

This project attempts to bring the Steam Deck's SteamOS Holo redistribution into a generic, installable format, and provide a close-to-official SteamOS experience.
Main point of this project focuses in re-implementing proprietary (as in runs-only-on-deck) components that Steam client, OS itself, gamescope and user-created applications for Deck rely on and making me learn Linux in a fun and unique way.

Click [here](https://t.me/HoloISO) to join **HoloISO** Telegram update channel;

**Common Questions**

- Is this official?
> No, but it may as well be 99% of the way there. Most of the code and packages, are straight from Valve, with zero possible edits, and the ISO is being built same rootfs bootstrap as all HoloISO installations run
- I have an NVIDIA GPU
> It may not be perfect but it works. For a better experiece go to the desktop, then to the steam settings and under interface make sure you have GPU acceleration for web views and hardware video decoding set to enabled

Hardware Support:
-
**CPU:**
- Mostly all CPUs work fine. But people report inoperable experience on 7xxx series. (Should be working in later builds with linux-zen package included)

**WLAN/PCIe additional cards:**
- Any pre-2021 WLAN Card works fine on Valve's 5.13 Neptune kernel, but linux-zen provides support for ALL current cards

**Sound:**
- Everything mostly works fine(tm)

**GPU:**
- AMD GPUs with RADV support (Guaranteed to work fully stable. 7xxx requires testing)
- NVIDIA GPUs (900 series and above work. SteamUI lags, but games are fine)
- Intel GPUs (Random experience)

Progress:
-
**Working stuff:**
- Bootup
- SteamOS OOBE (Steam Deck UI First Boot Experience)
- Deck UI (separate session)
- Deck UI (-gamepadui)
- ~~TDP/FPS limiting~~ (*0)
- Global FSR
- Shader Pre-Caching
- Switch to Desktop from plasma/to plasma without user interference.
- Valve's exclusive *Vapor* appearance for KDE Plasma
- Steam Deck pacman mirrors
- Cool-looking neofetch?
- System updates

**Working stuff on Steam Deck compared to other distributions:**
- Dock Firmware updater (additionally installable in desktop by running sudo pacman -S jupiter-dock-updater-bin)
- Steam Deck BIOS, Controller firmware, OS firmware updater, support for thumbstick and haptic motor calibration, native amplifier (CS35L41) support
- New fan curve control
- TDP/Clock control

(*0) Disabled for ALL systems except for Steam Deck (Valve Jupiter 1) due to VERY LOW hardcoded TDP/Clock values, especially for dGPUs.

Installation process:
-
**Prerequistes:**
- 4GB flash drive
- More than 8 GB RAM if you plan to use "Copy-To-RAM" option to install
- A Vulkan capable GPU
- UEFI-enabled device
- Disabled secure boot

**Installation:**
- Flash the ISO from [releases](https://github.com/zweiler2/HoloISO_Tweaked/releases) using [BalenaEtcher](https://etcher.balena.io), [Rufus](https://rufus.ie) with DD mode, or by typing `sudo dd if=SteamOS.iso of=/dev/sd(your flash drive) bs=4M status=progress oflag=sync` in the terminal, or by simply throwing the ISO onto a [Ventoy](https://www.ventoy.net) drive
- Boot into ISO
- Click on "Install SteamOS on this device"
- Follow on-screen instructions
- Take your favourite hot beverage, and wait 'till it installs :3

Upon booting, you'll be greeted with Steam Deck's OOBE screen, from where you'll connect to your network, and login to your Steam account, from there, you can exit to KDE Plasma seamlessly by choosing *Switch to desktop* in the power menu, [like so](https://www.youtube.com/watch?v=smfwna2iHho).

**Updating:**
- For regular updates you would just hit the update button in gamemode or type `sudo steamos-update check && sudo steamos-update now` in the terminal
- For ISO updates you would just download the new ISO and install to the same disk HoloISO is already on. The installer will detect an existing installation and asks you if you want to keep/reuse your home partition (This is where all your games, steam, various configs and personal files are stored). No data loss occurs then. Only the packages you installed via "pacman" from the terminal or the discover store get lost (but not their configuration or user data).

Notes:
-

This configuration includes Valve's pacman.conf repositories, `holoinstall` script and `holoinstall` post-installation binaries.

This configuration builds a *releng-based ISO*, which is the default Arch Linux redistribution flavor.

Building the ISO:
-
Trigger the build by executing:
```
sudo pacman -S archiso
git clone https://github.com/zweiler2/HoloISO_Tweaked.git
sudo chmod +x ./HoloISO_Tweaked/mkarchiso-holoiso
sudo ./HoloISO_Tweaked/mkarchiso-holoiso -rv ./HoloISO_Tweaked
sudo chown -hR $USER:$USER ./out 
```
Once it finishes, your ISO will be available in the `out` folder.

Credits:
-
[Adam Jafarov](https://github.com/theVakhovskeIsTaken)  
[Ewan](https://github.com/Ew4n1011) for providing his build/fileserver  
[fewtarius](https://github.com/fewtarius)  
[LeddaZ](https://github.com/LeddaZ)  
[danyi](https://github.com/danyi)  
[mnixry](https://github.com/mnixry)  
[wynn1212](https://github.com/wynn1212)  
[TwinniDev](https://github.com/TwinniDev)  
[Pato05](https://github.com/Pato05)  
[maade93791](https://github.com/maade93791)  
[huangsijun17](https://github.com/huangsijun17)  
[cherinyy](https://github.com/cherinyy)  
[NightHammer1000](https://github.com/NightHammer1000)  
[kubo6472](https://github.com/kubo6472)  
[ItsVixano](https://github.com/ItsVixano)  
[pants4hire](https://github.com/pants4hire)  
[Lolihunter1337](https://github.com/Lolihunter1337)  
[cpyarger](https://github.com/cpyarger)  
[Etienne Juvigny](https://github.com/Tk-Glitch) and all contributors who made the [Nvidia driver AIO Installer](https://github.com/Frogging-Family/nvidia-all)  
[Stephen](https://github.com/elFarto) and all contributors who made the [Nvidia vaapi driver](https://github.com/elFarto/nvidia-vaapi-driver)  
[Severin](https://github.com/medusalix) and all contributors who made the [Xbox One and Xbox Series X|S accessories linux kernel driver](https://github.com/medusalix/xone)
[Ingo Ruhnke](https://github.com/Grumbel) and all contributors who made the [Xbox/Xbox360 Gamepad Driver](https://github.com/xboxdrv/xboxdrv)
[Joaquín Ignacio Aramendía](https://github.com/Samsagax), [Alesh Slovak](https://github.com/alkazar) and all contributors who made the [ChimeraOS gamescope-session](https://github.com/ChimeraOS/gamescope-session)

Screenshots:
-
![Screenshot_20220508_133916](https://user-images.githubusercontent.com/97450182/167292656-1679e007-4701-4a3c-89ee-2104b5eb12cd.png)
![Screenshot_20220508_133737](https://user-images.githubusercontent.com/97450182/167292672-8bc9032d-4a21-4528-ab7e-b9dbc25a0664.png)
![Screenshot_20220508_133746](https://user-images.githubusercontent.com/97450182/167292722-a68806c1-5768-4790-a8e7-108d7c72bb08.png)
![Screenshot_20220508_133822](https://user-images.githubusercontent.com/97450182/167292731-86fed590-0260-4c5e-ac13-05d284b5fd24.png)
![Screenshot_20220508_134038](https://user-images.githubusercontent.com/97450182/167292734-90036b5f-2571-438e-8951-8d731cd4ae93.png)
![Screenshot_20220508_134051](https://user-images.githubusercontent.com/97450182/167292738-a70d266f-814d-4352-8d38-b920ae3f3381.png)
