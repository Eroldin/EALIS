#!/bin/zsh
set -e

: <<-'#END_COMMENT'
	!!!WARNING!!! Run this script only after you've ran part1 and rebooted in your new system!
	This script works with a plugin system. This means a few programs won't get installed if you run it as is.
	An example is the NVidia driver. To install it (and other programs) copy the correspondencing plugin to the main folder (where the system.sh script is located):
	$ cp -v /ealis/Plugins/nvidia.plugin /ealis/
	Examine this script to see what each plugin does.
#END_COMMENT

clear
echo "Running the second part of the script." && sleep 2
# Setting the current dir in a variable and turning on numlock
CURRENTDIR="$(pwd)"
setleds +num

# If plugin files are copied to the root folder of this script (/ealis) then said programs will be installed with the graphical environment.
# The snapper packages (if enabled) will be installed at the last moment.
if [[ -f /ealis/gamer.plugin ]]; then
	GAMER=(wine wine_gecko wine-mono winetricks lib32-pipewire lib32-alsa-lib lib32-alsa-plugins steam lutris protontricks protonup-qt)
	GAMERFLAT=discord
fi
if [[ -f /ealis/nvidia-old.plugin ]]; then
	sudo sed -i 's/splash/splash\ ibt=off/' /etc/default/grub
 	sudo grub-mkconfig -o /boot/grub/grub.cfg
 	NVIDIA=(nvidia-470xx-dkms nvidia-470xx-utils lib32-nvidia-470xx-utils opencl-nvidia-470xx lib32-opencl-nvidia-470xx)
fi
if [[ -f /ealis/kernel-hardened.plugin || -f /ealis/kernel-zen.plugin ]]; then
	if [[ -f /ealis/nvidia.plugin ]]; then
		NVIDIA=(nvidia-dkms nvidia-utils cuda lib32-nvidia-utils lib32-opencl-nvidia)
	fi
	if [[ -f /ealis/intel-nvidia-hybrid.plugin ]]; then
		NVIDIA=(nvidia-dkms nvidia-utils cuda lib32-nvidia-utils lib32-opencl-nvidia)
		HYBRID=(xf86-video-intel lib32-vulkan-intel vulkan-intel optimus-manager)
	elif [[ -f /ealis/amd-nvidia-hybrid.plugin ]]; then
		NVIDIA=(nvidia-dkms nvidia-utils cuda lib32-nvidia-utils lib32-opencl-nvidia)
		HYBRID=(xf86-video-amdgpu lib32-amdvlk amdvlk optimus-manager)
	fi
elif [[ -f /ealis/kernel-lts.plugin ]]; then
	if [[ -f /ealis/nvidia.plugin ]]; then
	NVIDIA=(nvidia-lts nvidia-utils cuda lib32-nvidia-utils)
	fi
	if [[ -f /ealis/intel-nvidia-hybrid.plugin ]]; then
		NVIDIA=(nvidia-lts nvidia-utils cuda lib32-nvidia-utils)
		HYBRID=(xf86-video-intel lib32-vulkan-intel vulkan-intel optimus-manager)
	elif [[ -f /ealis/amd-nvidia-hybrid.plugin ]]; then
		NVIDIA=(nvidia-lts nvidia-utils cuda lib32-nvidia-utils)
		HYBRID=(xf86-video-amdgpu lib32-amdvlk amdvlk optimus-manager)
	fi
else
	if [[ -f /ealis/nvidia.plugin ]]; then
	NVIDIA=(nvidia nvidia-utils cuda lib32-nvidia-utils)
	fi
	if [[ -f /ealis/intel-nvidia-hybrid.plugin ]]; then
		NVIDIA=(nvidia nvidia-utils cuda lib32-nvidia-utils)
		HYBRID=(xf86-video-intel lib32-vulkan-intel vulkan-intel optimus-manager)
	elif [[ -f /ealis/amd-nvidia-hybrid.plugin ]]; then
		NVIDIA=(nvidia nvidia-utils cuda lib32-nvidia-utils)
		HYBRID=(xf86-video-amdgpu lib32-amdvlk amdvlk optimus-manager)
	fi
fi
if [[ -f /ealis/brave.plugin ]]; then
	BROWSER=($BROWSER brave-bin)
fi
if [[ -f /ealis/chrome.plugin ]]; then
	BROWSER=($BROWSER google-chrome)
fi
if [[ -f /ealis/chromium.plugin ]]; then
	BROWSER=($BROWSER chromium)
fi
if [[ -f /ealis/firefox.plugin ]]; then
	BROWSER=($BROWSER firefox)
fi
if [[ -f /ealis/brave.plugin || -f /ealis/chrome.plugin || -f /ealis/chromium.plugin || -f /ealis/firefox.plugin ]]; then
	:
else
	BROWSER=firefox
fi
if [[ -f /ealis/kvm.plugin ]]; then
	VMTOOLS=(spice spice-gtk spice-protocol spice-vdagent qemu-guest-agent) # For QEMU, GNOME Boxes, etc.
fi
if [[ -f /ealis/vboxguest.plugin ]]; then
	VMTOOLS=(virtualbox-guest-utils xf86-video-vmware) # For VirtualBox virtualisation
fi
if [[ -f /ealis/vmtools.plugin ]]; then
	VMTOOLS=(open-vm-tools xf86-video-vmware) # For VMware virtualisation
fi
if [[ -f /ealis/onlyoffice.plugin ]]; then
	OFFICEFLAT=onlyoffice
else
	OFFICE=libreoffice-still
fi
if [[ -f /ealis/videowallpaper.plugin ]]; then
	VIDEOWALLPAPER=(ghostlexly-gpu-video-wallpaper xwinwrap-0.9-bin)
fi
if [[ -f /ealis/spotify.plugin ]]; then
	SPOTIFYFLAT=spotify
fi

DESKTOP=$(echo $DESKTOP | tr '[:upper:]' '[:lower:]')
desktop=$(echo $desktop | tr '[:upper:]' '[:lower:]')
Desktop=$(echo $Desktop | tr '[:upper:]' '[:lower:]')
if [[ $DESKTOP = cinnamon || $Desktop = cinnamon || $desktop = cinnamon ]]; then
	GTK=yes
	DESKTOP=(cinnamon nemo-engrampa nemo-preview gnome-screenshot gedit gnome-terminal-transparency gnome-control-center gnome-system-monitor gnome-power-manager mintlocale gnome-themes-extra candy-icons-git gtk-theme-bubble-dark-git)
elif [[ $DESKTOP = xfce || $DESKTOP = xfce4 || $Desktop = xfce || $Desktop = xfce4 || $desktop = xfce || $desktop = xfce4 ]]; then
	GTK=yes
	DESKTOP=(xfce4 xfce4-goodies candy-icons-git gtk-theme-bubble-dark-git)
elif [[ $DESKTOP = awesomewm || $Desktop = awesomewm || $desktop = awesomewm || $DESKTOP = awesome || $Desktop = awesome || $desktop = awesome ]]; then
	GTK=yes
	DESKTOP=(awesome rofi picom i3lock-fancy xclip ttf-roboto polkit-gnome materia-theme lxappearance flameshot pnmixer network-manager-applet xfce4-power-manager qt5-styleplugins papirus-icon-theme)
elif [[ -z $DESKTOP ]]; then
	echo -e "You need to fill the DESKTOP variable with a supported Desktop Environt (i.e. \DESKTOP=cinnamon zsh /ealis/part2.sh)"
	exit
else
	echo -e "You entered an unsupported Desktop Environment. You need to fill the DESKTOP variable with a supported Desktop Environment (i.e. DESKTOP=cinnamon zsh /ealis/part2.sh)"
	exit
fi

# Configuring the Network Manager
NETWORKMANAGER=$(systemctl is-active NetworkManager.service || true)
if [[ $NETWORKMANAGER = inactive ]]; then
	echo "Activating Network Manager..."
	sudo systemctl enable --now NetworkManager.service &>/dev/null && sleep 2
fi
while true; do
	read -r yn"?Do you wish to select or edit an internet connection? (y/N): "
	case $yn in
		[yY] ) nmtui; break;;
		[nN] ) break ;;
		"" ) break ;;
		*) echo "Please chose either Yes (y/Y) or no (n/N). You can leave it empty for the default option (no)." >&2
	esac
done
# Updating the system before starting the installation
sudo pacman -Syu --noconfirm

# You may want to enable this plugin to use the chaotic aur mirror to install precompiled aur packages. Keep in mind that this can be a security risk.
if [[ -f /ealis/chaotic.plugin ]]; then
	if ! grep -Fqm1 chaotic /etc/pacman.conf; then
		sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
		sudo pacman-key --lsign-key 3056513887B78AEB
		sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --needed --noconfirm
		sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --needed --noconfirm
sudo zsh -c 'cat >> /etc/pacman.conf' <<-'EOF'
	[chaotic-aur]
	Include = /etc/pacman.d/chaotic-mirrorlist
EOF
sudo zsh -c 'cat > /etc/pacman.d/chaotic-mirrorlist' <<-'EOF'
	## Special CDN mirror (delayed syncing, expect some (safe to ignore) amount of 404s)
	# Globally
	# * By: Garuda Linux donators, hosted on Cloudflare R2
	# Server = https://cdn-mirror.chaotic.cx/$repo/$arch

	# Automatic per-country routing of the mirrors below.
	Server = https://geo-mirror.chaotic.cx/$repo/$arch

	## Regular Syncthing mirrors (close to instant syncing)
	# Brazil
	# * By: Universidade Federal de São Carlos (São Carlos)
	Server = https://br-mirror.chaotic.cx/$repo/$arch

	# Bulgaria
	# * By: Sudo Man <github.com/sakrayaami>
	Server = https://bg-mirror.chaotic.cx/$repo/$arch

	# Canada
	# * By freebird54 (Toronto)
	Server = https://ca-mirror.chaotic.cx/$repo/$arch

	# Chile
	# * By makzk (Santiago)
	Server = https://cl-mirror.chaotic.cx/$repo/$arch

	# Germany (de-1 ceased to exist)
	# * By: ParanoidBangL
	Server = https://de-2-mirror.chaotic.cx/$repo/$arch
	# * By: itsTyrion
	Server = https://de-3-mirror.chaotic.cx/$repo/$arch
	# * By: redgloboli
	Server = https://de-4-mirror.chaotic.cx/$repo/$arch

	# France
	# * By Yael (Marseille)
	Server = https://fr-mirror.chaotic.cx/$repo/$arch

	# Greece
	# * By: vmmaniac <github.com/vmmaniac>
	Server = https://gr-mirror.chaotic.cx/$repo/$arch

	# India
	# * By Naman (Kaithal)
	Server = https://in-mirror.chaotic.cx/$repo/$arch
	# * By Albony <https://albony.xyz/>
	Server = https://in-2-mirror.chaotic.cx/$repo/$arch
	# * By: BRAVO68DEV <https://www.itsmebravo.dev/>
	Server = https://in-3-mirror.chaotic.cx/$repo/$arch
	# * By Albony (Chennai)
	Server = https://in-4-mirror.chaotic.cx/$repo/$arch

	# Korea
	# * By: <t.me/silent_heigou> (Seoul)
	Server = https://kr-mirror.chaotic.cx/$repo/$arch

	# Spain
	# * By: JKANetwork
	Server = https://es-mirror.chaotic.cx/$repo/$arch
	# * By: Ícar <t.me/IcarNS>
	Server = https://es-2-mirror.chaotic.cx/$repo/$arch

	# United States
	# * By: Technetium1 <github.com/Technetium1>
	Server = https://us-mi-mirror.chaotic.cx/$repo/$arch
	# New York
	# * By: xstefen <t.me/xstefen>
	Server = https://us-tx-mirror.chaotic.cx/$repo/$arch
	# Utah
	# * By: ash <t.me/the_ashh>
	Server = https://us-ut-mirror.chaotic.cx/$repo/$arch


	# IPFS mirror - for instructions on how to use it consult the projects repo (https://github.com/RubenKelevra/pacman.store)
	# * By: RubenKelevra / pacman.store
	# Server = http://chaotic-aur.pkg.pacman.store.ipns.localhost:8080/$arch
EOF
		# Installing yay for AUR support
		sudo pacman -Sy yay --needed --noconfirm
	fi
else
	# Installing yay for AUR support
	cd /tmp
	git clone https://aur.archlinux.org/yay-bin.git
	cd yay-bin
	makepkg -si --needed --noconfirm
	cd "$CURRENTDIR"
fi

# This installs both xorg, wayland and basic programs for full desktop experience.
yay -S --needed --noconfirm bc upd72020x-fw rsync mlocate bash-completion xorg-xlsfonts pkgstats zip unzip unrar p7zip lzop cpio avahi nss-mdns alsa-utils alsa-plugins dosfstools exfat-utils f2fs-tools fuse fuse-exfat mtpfs xorg-server xorg-apps xorg-xinit xorg-xkill xorg-xinput xf86-input-libinput mesa weston xorg-server-xwayland
if [[ $GTK = yes ]]; then
	sudo -v
	yay -S --needed --noconfirm $NVIDIA $HYBRID $GAMER $VMTOOLS $OFFICE $VIDEOWALLPAPER $BROWSER $DESKTOP dmidecode gvfs gvfs-mtp gvfs-smb unarchiver ttf-sourcecodepro-nerd opensiddur-hebrew-fonts oh-my-posh-bin inotify-tools yad cups cups-pdf system-config-printer gutenprint watchdog breeze xdg-desktop-portal-gtk noto-fonts-emoji xdg-user-dirs-gtk ghostscript gsfonts foomatic-db foomatic-db-engine foomatic-db-nonfree foomatic-db-ppds foomatic-db-nonfree-ppds foomatic-db-gutenprint-ppds sddm sddm-kcm pipewire pipewire-alsa pipewire-pulse archlinux-artwork archlinux-wallpaper keepassxc xviewer flatpak pamac-flatpak gnome-calculator yt-dlp masterpdfeditor-free dnsmasq networkmanager-openconnect networkmanager-openvpn networkmanager-pptp networkmanager-vpnc network-manager-applet nm-connection-editor gnome-keyring bluez bluez-utils gparted ufw gufw icoutils gimp simple-scan transmission-gtk thunderbird easytag mpv vlc handbrake gst-plugins-base gst-plugins-base-libs gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav libdvdnav libdvdcss cdrdao cdrtools ffmpeg ffmpegthumbnailer ffmpegthumbs ttf-ms-fonts noto-fonts-cjk
	yay -D --asdeps cairo fontconfig freetype2 >/dev/null
	if [[ $DESKTOP =~ awesome ]]; then
		yay -D --asexplicit $NVIDIA $HYBRID $GAMER $VMTOOLS $OFFICE $VIDEOWALLPAPER $BROWSER dmidecode gvfs gvfs-mtp gvfs-smb unarchiver ttf-sourcecodepro-nerd opensiddur-hebrew-fonts oh-my-posh-bin inotify-tools yad cups cups-pdf system-config-printer gutenprint watchdog breeze xdg-desktop-portal-gtk noto-fonts-emoji xdg-user-dirs-gtk ghostscript gsfonts foomatic-db foomatic-db-engine foomatic-db-nonfree foomatic-db-ppds foomatic-db-nonfree-ppds foomatic-db-gutenprint-ppds sddm sddm-kcm pipewire pipewire-alsa pipewire-pulse archlinux-artwork archlinux-wallpaper keepassxc xviewer flatpak pamac-flatpak gnome-calculator yt-dlp masterpdfeditor-free dnsmasq networkmanager-openconnect networkmanager-openvpn networkmanager-pptp networkmanager-vpnc network-manager-applet nm-connection-editor gnome-keyring bluez bluez-utils gparted ufw gufw icoutils gimp simple-scan transmission-gtk thunderbird easytag mpv vlc handbrake gst-plugins-base gst-plugins-base-libs gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav libdvdnav libdvdcss cdrdao cdrtools ffmpeg ffmpegthumbnailer ffmpegthumbs ttf-ms-fonts noto-fonts-cjk >/dev/null
	else
		yay -D --asexplicit $NVIDIA $HYBRID $GAMER $VMTOOLS $OFFICE $VIDEOWALLPAPER $BROWSER $DESKTOP dmidecode gvfs gvfs-mtp gvfs-smb unarchiver ttf-sourcecodepro-nerd opensiddur-hebrew-fonts oh-my-posh-bin inotify-tools yad cups cups-pdf system-config-printer gutenprint watchdog breeze xdg-desktop-portal-gtk noto-fonts-emoji xdg-user-dirs-gtk ghostscript gsfonts foomatic-db foomatic-db-engine foomatic-db-nonfree foomatic-db-ppds foomatic-db-nonfree-ppds foomatic-db-gutenprint-ppds sddm sddm-kcm pipewire pipewire-alsa pipewire-pulse archlinux-artwork archlinux-wallpaper keepassxc xviewer flatpak pamac-flatpak gnome-calculator yt-dlp masterpdfeditor-free dnsmasq networkmanager-openconnect networkmanager-openvpn networkmanager-pptp networkmanager-vpnc network-manager-applet nm-connection-editor gnome-keyring bluez bluez-utils gparted ufw gufw icoutils gimp simple-scan transmission-gtk thunderbird easytag mpv vlc handbrake gst-plugins-base gst-plugins-base-libs gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav libdvdnav libdvdcss cdrdao cdrtools ffmpeg ffmpegthumbnailer ffmpegthumbs ttf-ms-fonts noto-fonts-cjk >/dev/null
	fi
fi
if [[ $DESKTOP =~ cinnamon ]]; then
	VERSION=$(cinnamon --version)
	if [[ $VERSION =~ 6.2.2 ]]; then
 		yay -S devtools --needed --noconfirm
		mkdir /tmp/makepkg >/dev/null 2>&1 || true
		cd /tmp/makepkg
		pkgctl repo clone --protocol=https cinnamon-session
		cd cinnamon-session
		sed "/build()/ased '/maybe_restart_user_bus (manager);/d' -i \${pkgname}-\${pkgver}/cinnamon-session/csm-manager.c" -i PKGBUILD
		makepkg -cirs --noconfirm
		cd $CURRENTDIR
  		yay -Rns devtools --noconfirm
	fi
fi

# Thanks to ChrisTitusTech for this beautiful AwesomeWM configuration.
if [[ $DESKTOP =~ awesomewm ]]; then
	sudo mkdir -p /etc/skel/.config >/dev/null 2>&1 || true
	sudo git clone https://github.com/ChrisTitusTech/titus-awesome /etc/skel/.config/awesome
	sudo mkdir ~/.config/rofi
	sudo cp /etc/skel/.config/awesome/theme/config.rasi /etc/skel/.config/rofi/config.rasi
	sudo sed -i '/@import/c\@import "'$HOME'/.config/awesome/theme/sidebar.rasi"' /etc/skel/.config/rofi/config.rasi
	mkdir -p ~/.config/rofi
	cp $HOME/.config/awesome/theme/config.rasi $HOME/.config/rofi/config.rasi
	sed -i '/@import/c\@import "'$HOME'/.config/awesome/theme/sidebar.rasi"' ~/.config/rofi/config.rasi
	sudo zsh -c "cat >> /etc/environment" <<-'EOF'
	XDG_CURRENT_DESKTOP=Unity
	QT_QPA_PLATFORMTHEME=gtk2
EOF
fi

sudo flatpak remote-delete flathub-beta >/dev/null 2>&1 || true
flatpak install --system --assumeyes kdenlive $GAMERFLAT $OFFICEFLAT $SPOTIFYFLAT
if [[ $DESKTOP =~ cinnamon || $DESKTOP =~ xfce4 ]]; then
	echo "GTK_THEME=Adwaita-dark" | sudo tee -a /etc/environment >/dev/null
fi

# This sets the keyboard layout to English (US, Intl., with dead keys). Change or remove this if needed.
sudo localectl set-x11-keymap us pc105 intl

# If you are using a hybrid video card, optimus will be cofigured for you.
if [[ -f /ealis/intel-nvidia-hybrid.plugin || -f /ealis/amd-nvidia-hybrid.plugin ]]; then
	sudo systemctl enable optimus-manager.service
	sudo mkdir -p /etc/optimus-manager || true
	sudo wget -qO /usr/share/optimus-manager.conf "https://raw.githubusercontent.com/Askannz/optimus-manager/master/optimus-manager.conf"
sudo zsh -c 'cat > /etc/optimus-manager/optimus-manager.conf' <<-'EOF'
	[optimus]

	# This parameter defines the method used to power switch the Nvidia card. See the documentation
	# for a complete description of what each value does. Possible values :
	#
	# - nouveau : load the nouveau module on the Nvidia card.
	# - bbswitch : power off the card using the bbswitch module (requires the bbswitch dependency).
	# - acpi_call : try various ACPI method calls to power the card on and off (requires the acpi_call dependency)
	# - custom: use custom scripts at /etc/optimus-manager/nvidia-enable.sh and /etc/optimus-manager/nvidia-disable.sh
	# - none : do not use an external module for power management. For some laptop models it's preferable to
	#     use this option in combination with pci_power_control (see below).
	switching=none

	# Enable PCI power management in "integrated" mode.
	# This option is incompatible with acpi_call and bbswitch, so it will be ignored in those cases.
	pci_power_control=no

	# Remove the Nvidia card from the PCI bus.
	# May prevent crashes caused by power switching.
	# Ignored if switching=nouveau or switching=bbswitch.
	pci_remove=no

	# Reset the Nvidia card at the PCI level before reloading the nvidia module.
	# Ensures the card is in a fresh state before reloading the nvidia module.
	# May fix some switching issues. Possible values :
	#
	# - no : does not perform any reset
	# - function_level : perform a light "function-level" reset
	# - hot_reset : perform a "hot reset" of the PCI bridge. ATTENTION : this method messes with the hardware
	#     directly, please read the online documentation of optimus-manager before using it.
	#     Also, it will perform a PCI remove even if pci_remove=no.
	#
	pci_reset=no

	# Automatically log out the current desktop session when switching GPUs.
	# This feature is currently supported for the following DE/WM :
	# GNOME, KDE Plasma, LXDE, Deepin, Xfce, i3, Openbox, AwesomeWM, bspwm, dwm, Xmonad, herbstluftwm
	# If this option is disabled or you use a different desktop environment,
	# GPU switching only becomes effective at the next graphical session login.
	auto_logout=yes

	# GPU mode to use at computer startup.
	# Possible values: nvidia, integrated, hybrid, auto, auto_nvdisplay, intel (deprecated, equivalent to integrated)
	# "auto" is a special mode that auto-detects if the computer is running on battery
	# and selects a proper GPU mode.
	# "auto_nvdisplay" sets the GPU mode based on whether a display is connected directly to the nvidia GPU,
	# which can be useful if any display output works only in a specific mode.
	# See the other options below.
	startup_mode=hybrid
	# GPU mode to select when startup_mode=auto and the computer is running on battery.
	# Possible values: nvidia, integrated, hybrid, intel (deprecated, equivalent to integrated)
	startup_auto_battery_mode=hybrid
	# GPU mode to select when startup_mode=auto and the computer is running on external power.
	# Possible values: nvidia, integrated, hybrid, intel (deprecated, equivalent to integrated)
	startup_auto_extpower_mode=hybrid
	# GPU mode to select when startup_mode=auto_nvdisplay and no display is connected directly to the nvidia GPU.
	# Possible values: nvidia, integrated, hybrid
	startup_auto_nvdisplay_off_mode=hybrid
	# GPU mode to select when startup_mode=auto_nvdisplay and a display is connected directly to the nvidia GPU.
	# Possible values: nvidia, integrated, hybrid
	startup_auto_nvdisplay_on_mode=hybrid


	[intel]

	# Driver to use for the Intel GPU. Possible values : modesetting, intel
	# To use the intel driver, you need to install the package "xf86-video-intel".
	driver=modesetting

	# Acceleration method (corresponds to AccelMethod in the Xorg configuration).
	# Only applies to the intel driver.
	# Possible values : sna, xna, uxa
	# Leave blank for the default (no option specified)
	accel=

	# Enable TearFree option in the Xorg configuration.
	# Only applies to the intel driver.
	# Possible values : yes, no
	# Leave blank for the default (no option specified)
	tearfree=

	# DRI version. Possible values : 2, 3
	DRI=3

	# Whether or not to enable modesetting for the nouveau driver.
	# Does not affect modesetting for the Intel GPU driver !
	# This option only matters if you use nouveau as the switching backend.
	modeset=yes


	[amd]

	# Driver to use for the AMD GPU. Possible values : modesetting, amdgpu
	# To use the amdgpu driver, you need to install the package "xf86-video-amdgpu".
	driver=modesetting

	# Enable TearFree option in the Xorg configuration.
	# Only applies to the amdgpu driver.
	# Possible values : yes, no
	# Leave blank for the default (no option specified)
	tearfree=

	# DRI version. Possible values : 2, 3
	DRI=3


	[nvidia]

	# Whether or not to enable modesetting. Required for PRIME Synchronization (which prevents tearing).
	modeset=yes

	# Whether or not to enable the NVreg_UsePageAttributeTable option in the Nvidia driver.
	# Recommended, can cause poor CPU performance otherwise.
	PAT=yes

	# DPI value. This will be set using the Xsetup script passed to your login manager.
	# It will run the command
	# xrandr --dpi <DPI>
	# Leave blank for the default (the above command will not be run).
	DPI=96

	# If you're running an updated version of xorg-server (let's say to get PRIME Render offload enabled),
	# the nvidia driver may not load because of an ABI version mismatch. Setting this flag to "yes"
	# will allow the loading of the nvidia driver.
	ignore_abi=no

	# Set to yes if you want to use optimus-manager with external Nvidia GPUs (experimental)
	allow_external_gpus=no

	# Comma-separated list of Nvidia-specific options to apply.
	# Available options :
	# - overclocking : enable CoolBits in the Xorg configuration, which unlocks clocking options
	#  in the Nvidia control panel. Note: does not work in hybrid mode.
	# - triple_buffer : enable triple buffering.
	options=overclocking


	# Enable Runtime D3 (RTD3) Power Management in the Nvidia driver. While in hybrid mode,
	# this feature allows the Nvidia card to go into a low-power mode if it's not in use.
	#
	# IMPORTANT NOTES:
	# - The feature is still experimental
	# - It's only supported on laptops with a Turing GPU or above, and an Intel Coffee Lake CPU
	# or above (not sure about the state of support for AMD CPUs).
	# - if your Nvidia card also has an audio chip (for HDMI) or a USB port wired to it, they may not
	# function properly while in low-power mode
	#
	# For more details, see
	# https://download.nvidia.com/XFree86/Linux-x86_64/460.39/README/dynamicpowermanagement.html
	#
	# Available options:
	# - no (the default): RTD3 power management is disabled.
	# - coarse: the card only goes to low-power if no application is using it.
	# - fine: the card is also allowed to go to low-power if applications are using it but have not
	# actively submitted GPU work in some amount of time.
	dynamic_power_management=no

	# The Nvidia driver handles power to the video memory separately from the rest of GPU.
	# When dynamic_power_management=fine, this options controls the threshold of memory utilization
	# (in Megabytes) under which the memory is put in a low-power state.
	# Values over 200MB are ignored. Leave blank for the default (200MB).
	# Setting this value to 0 keeps the memory powered at all times.
	dynamic_power_management_memory_threshold=

EOF
fi

# Increases the max map count for gaming purposes and creates an autostart file for steam.
if [[ -f /ealis/gamer.plugin ]]; then
	echo "vm.max_map_count=2147483642" | sudo tee /etc/sysctl.d/98-mmc.conf >/dev/null
sudo zsh -c "cat /etc/xdg/autostart/steam.desktop" <<-'EOF'
	[Desktop Entry]
	Name=Steam (Runtime)
	Comment=Application for managing and playing games on Steam
	Comment[pt_BR]=Aplicativo para jogar e gerenciar jogos no Steam
	Comment[bg]=Приложение за ръководене и пускане на игри в Steam
	Comment[cs]=Aplikace pro spravování a hraní her ve službě Steam
	Comment[da]=Applikation til at håndtere og spille spil på Steam
	Comment[nl]=Applicatie voor het beheer en het spelen van games op Steam
	Comment[fi]=Steamin pelien hallintaan ja pelaamiseen tarkoitettu sovellus
	Comment[fr]=Application de gestion et d'utilisation des jeux sur Steam
	Comment[de]=Anwendung zum Verwalten und Spielen von Spielen auf Steam
	Comment[el]=Εφαρμογή διαχείρισης παιχνιδιών στο Steam
	Comment[hu]=Alkalmazás a Steames játékok futtatásához és kezeléséhez
	Comment[it]=Applicazione per la gestione e l'esecuzione di giochi su Steam
	Comment[ja]=Steam 上でゲームを管理＆プレイするためのアプリケーション
	Comment[ko]=Steam에 있는 게임을 관리하고 플레이할 수 있는 응용 프로그램
	Comment[no]=Program for å administrere og spille spill på Steam
	Comment[pt_PT]=Aplicação para organizar e executar jogos no Steam
	Comment[pl]=Aplikacja do zarządzania i uruchamiania gier na platformie Steam
	Comment[ro]=Aplicație pentru administrarea și jucatul jocurilor pe Steam
	Comment[ru]=Приложение для игр и управления играми в Steam
	Comment[es]=Aplicación para administrar y ejecutar juegos en Steam
	Comment[sv]=Ett program för att hantera samt spela spel på Steam
	Comment[zh_CN]=管理和进行 Steam 游戏的应用程序
	Comment[zh_TW]=管理並執行 Steam 遊戲的應用程式
	Comment[th]=โปรแกรมสำหรับจัดการและเล่นเกมบน Steam
	Comment[tr]=Steam üzerinden oyun oynama ve düzenleme uygulaması
	Comment[uk]=Програма для керування іграми та запуску ігор у Steam
	Comment[vi]=Ứng dụng để quản lý và chơi trò chơi trên Steam
	Exec=/usr/bin/steam-runtime -nochatui -nofriendsui -silent
	Icon=steam
	Terminal=false
	Type=Application
	Categories=Network;FileTransfer;Game;
	MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
	Actions=Store;Community;Library;Servers;Screenshots;News;Settings;BigPicture;Friends;
	PrefersNonDefaultGPU=true
	X-KDE-RunOnDiscreteGpu=true
EOF
	sudo chmod 755 /etc/xdg/autostart/steam.desktop
fi

# A sample live wallpaper will be downloaded and configured for you.
if [[ -f /ealis/videowallpaper.plugin ]]; then
	echo "Downloading a sample live wallpaper (originally uploaded on mylivewallpapers.com by 'imjustsaiyan'). This might take awhile..."
	sudo wget -q --no-check-certificate -O /usr/share/backgrounds/mylivewallpapers.com-Night-Elf-Warcraft-3-Reforged.mp4 "https://drive.google.com/uc?export=download&id=1K0sObATO32nfxTWAlgr9vxkQdJONTsTx"
	sudo chmod 644 /usr/share/backgrounds/mylivewallpapers.com-Night-Elf-Warcraft-3-Reforged.mp4
sudo zsh -c 'cat >> /etc/skel/.zshrc' <<-'EOF'
	alias livewallpaper="/opt/videowallpaper.sh"
	alias killlivewallpaper="killall mpv"
EOF
cat /etc/skel/.zshrc | tee $HOME/.zshrc >/dev/null
sudo zsh -c 'cat > /opt/videowallpaper.sh' <<-'EOF' 
	#!/bin/bash
	video-wallpaper.sh --start /usr/share/backgrounds/mylivewallpapers.com-Night-Elf-Warcraft-3-Reforged.mp4 >/dev/null 2>&1 & disown %1
EOF

sudo chmod 775 /opt/videowallpaper.sh
sudo chown :users /opt/videowallpaper.sh

mkdir -p "$HOME/.config/autostart/" 2>/dev/null || true
cat <<-'EOF' > "$HOME/.config/autostart/livewallpaper.desktop"
	[Desktop Entry]
	Type=Application
	Exec=/opt/videowallpaper.sh
	X-GNOME-Autostart-enabled=true
	NoDisplay=false
	Hidden=false
	Name[en_US]=Video Wallpaper
	Comment[en_US]=No description
	X-GNOME-Autostart-Delay=0
EOF
fi

# Snapper will be installed.
if [[ -f /ealis/snapshots.plugin ]]; then
	if [[ ! -d /.snapshots ]]; then
		sudo btrfs subvolume create /.snapshots
	fi
	yay -S --noconfirm --needed btrfs-assistant
	yay -S --noconfirm --needed grub-btrfs
	yay -S --noconfirm --needed snap-pac-git
	yay -S --noconfirm --needed snapper
	yay -S --noconfirm --needed snapper-tools-git
	yay -S --noconfirm --needed snapper-support
	yay -S --noconfirm --needed snapper-rollback
 	yay -D --asexplicit snapper >/dev/null
	sudo systemctl enable grub-btrfsd.service &>/dev/null
	sudo cp -d /etc/snapper/config-templates/snapper /etc/snapper/configs/root
sudo zsh -c 'cat > /etc/conf.d/snapper' <<-'EOF'
	## Path: System/Snapper

	## Type:    string
	## Default:   ""
	# List of snapper configurations.
	SNAPPER_CONFIGS="root"
EOF
	sudo chown :users /.snapshots
	sudo chmod a+x /.snapshots
	sudo mkinitcpio -P
	sudo grub-mkconfig -o /boot/grub/grub.cfg
	sudo systemctl restart snapperd
fi

yay -Rsc --noconfirm $(yay -Qdqt)
yes | sudo pacman -Scc

# This configures sddm and enables the necessary services.
sudo sddm --example-config | sudo tee /etc/sddm.conf >/dev/null
sudo sed -i 's/Current=/Current=breeze/' /etc/sddm.conf
sudo sed -i 's/CursorTheme=/CursorTheme=breeze_cursors/' /etc/sddm.conf
sudo sed -i 's/Numlock=none/Numlock=on/' /etc/sddm.conf
sudo systemctl enable --now watchdog &>/dev/null
sudo systemctl enable --now ufw &>/dev/null
sudo ufw enable &>/dev/null
sudo systemctl enable sddm &>/dev/null
sudo systemctl enable bluetooth.service &>/dev/null
sudo systemctl enable linux-modules-cleanup.service &>/dev/null
sudo systemctl set-default graphical.target &>/dev/null
sudo timedatectl set-ntp true &>/dev/null
sudo systemctl enable avahi-daemon.service &>/dev/null
sudo systemctl enable cups.service &>/dev/null
if [[ -f /ealis/vboxguest.plugin ]]; then
	sudo systemctl enable vboxservice.service &>/dev/null
	sudo usermod $USER -aG vboxsf
fi
if [[ -f /ealis/vmtools.plugin ]]; then
	sudo systemctl enable vmtoolsd.service &>/dev/null
	sudo systemctl enable vmware-vmblock-fuse.service >dev/null
fi

# A few optimalisations are being done to your system.
sudo cp /usr/share/pipewire/pipewire.conf /etc/pipewire/pipewire.conf
sudo sed -i 's/#default.clock.allowed-rates/default.clock.allowed-rates/' /etc/pipewire/pipewire.conf
sudo sed -i 's/\ 48000\ /\ 44100\ 48000\ /' /etc/pipewire/pipewire.conf
if [[ -f /ealis/no-ip6.plugin ]]; then
sudo zsh -c "cat > /etc/sysctl.d/99-noip6.conf" <<-'EOF'
	net.ipv6.conf.all.disable_ipv6=1
	net.ipv6.conf.default.disable_ipv6=1
	net.ipv6.conf.lo.disable_ipv6=1
EOF
sudo sed -i 's/yes/no/' /etc/default/ufw
fi
sudo zsh -c "cat > /etc/pamac.conf" <<-'EOF'
	### Pamac configuration file

	## When removing a package, also remove those dependencies
	## that are not required by other packages (recurse option):
	RemoveUnrequiredDeps

	## How often to check for updates, value in hours (0 to disable):
	RefreshPeriod = 6

	## When no update is available, hide the tray icon:
	NoUpdateHideIcon

	## When applying updates, enable packages downgrade:
	#EnableDowngrade

	## When installing packages, do not check for updates:
	#SimpleInstall

	## Allow Pamac to search and install packages from AUR:
	EnableAUR

	## Keep built packages from AUR in cache after installation:
	#KeepBuiltPkgs

	## When AUR support is enabled check for updates from AUR:
	CheckAURUpdates

	## When check updates from AUR support is enabled check for vcs updates:
	#CheckAURVCSUpdates

	## AUR build directory:
	BuildDirectory = /var/tmp

	## Number of versions of each package to keep when cleaning the packages cache:
	KeepNumPackages = 2

	## Remove only the versions of uninstalled packages when cleaning the packages cache:
	#OnlyRmUninstalled

	## Download updates in background:
	#DownloadUpdates

	## Offline upgrade:
	#OfflineUpgrade

	## Maximum Parallel Downloads:
	MaxParallelDownloads = 4

	CheckFlatpakUpdates

	#EnableSnap

	EnableFlatpak

EOF
sudo zsh -c "cat > /etc/sysctl.d/98-dirty.conf" <<-'EOF'
	vm.dirty_background_bytes=16777216
	vm.dirty_bytes=33554432
EOF
if [[ -f /ealis/snapshots.plugin ]]; then
	for i in `seq 1 5`; do sudo snapper delete $i 2>/dev/null || true; done
fi
clear
echo "This script has runned succesfully. Please reboot..."
if [[ -f /ealis/snapshots.plugin ]]; then
	echo "Don't forget to make your first snapshot!"
fi
