#!/bin/zsh
set -e
: <<-'#END_COMMENT'
	Before running this script. Make sure everything is correctly mounted at "/mnt". Make sure this project is cloned on /mnt (your root) as well.
	The default kernel is the zen kernel. You can change that, by copying the corresponding plugins to the root folder of the script (/mnt/ealis)
	Keep in mind that this script is meant for systems with 8G ram or more. Less ram might work after you edit this script.
#END_COMMENT
mkdir -p /mnt/etc/mkinitcpio.d/
ENCUSED="$(lsblk -f | grep -o crypto | head -1 || true)"
LVMUSED="$(lsblk -f | grep -o LVM2_member | head -1 || true)"
VIRTMACH="$(dmesg | grep -i hypervisor || true)"
if [[ -z $VIRTMACH ]]; then
	MICROCODE="$(lscpu | grep -o GenuineIntel | head -1 || true)"
	if [[ -z $MICROCODE ]]; then
		MICROCODE="$(lscpu | grep -o AuthenticAMD | head -1 || true)"
	fi
fi
XFS="$(findmnt -n | grep -o xfs | head -1 || true)"
BTRFS="$(findmnt -n | grep -o btrfs | head -1 || true)"
if [[ -f /mnt/ealis/kernel.plugin ]]; then # The kernel.plugin is only necessary if you want this alongside another kernel.
	if [[ -f /mnt/ealis/kernel-hardened.plugin ]]; then
		KERNEL=(linux-hardened linux-headers-hardened bubblewrap-suid)
	else
		KERNEL=($KERNEL linux linux-headers)
	fi
fi
if [[ -f /mnt/ealis/kernel-lts.plugin ]]; then
	if [[ -f /mnt/ealis/kernel-hardened.plugin ]]; then
		KERNEL=(linux-hardened linux-headers-hardened bubblewrap-suid)
	else
		KERNEL=($KERNEL linux-lts linux-lts-headers)
	fi
fi
if [[ -f /mnt/ealis/kernel-hardened.plugin ]]; then
	KERNEL=(linux-hardened linux-headers-hardened bubblewrap-suid)
fi
if [[ -f /mnt/ealis/kernel-zen.plugin ]]; then
	if [[ -f /mnt/ealis/kernel-hardened.plugin ]]; then
		KERNEL=(linux-hardened linux-headers-hardened bubblewrap-suid)
	else
		KERNEL=($KERNEL linux-zen linux-zen-headers)
	fi
fi
if [[ -f /mnt/ealis/kernel-zen.plugin || -f /mnt/ealis/kernel-lts.plugin || -f /mnt/ealis/kernel-hardened.plugin ]]; then
	:
else
	KERNEL=(linux linux-headers)
fi

# Optimising your pacman configuration
cat <<-'EOF' > /etc/pacman.conf
	#
	# /etc/pacman.conf
	#
	# See the pacman.conf(5) manpage for option and repository directives
	
	#
	# GENERAL OPTIONS
	#
	[options]
	# The following paths are commented out with their default values listed.
	# If you wish to use different paths, uncomment and update the paths.
	#RootDir     = /
	#DBPath      = /var/lib/pacman/
	#CacheDir    = /var/cache/pacman/pkg/
	CacheDir    = /var/cache/pacman/pkg/
	CacheDir    = /var/cache/pacman/aur/
	#LogFile     = /var/log/pacman.log
	#GPGDir      = /etc/pacman.d/gnupg/
	#HookDir     = /etc/pacman.d/hooks/
	HoldPkg     = pacman glibc
	#XferCommand = /usr/bin/curl -L -C - -f -o %o %u
	#XferCommand = /usr/bin/wget --passive-ftp -c -O %o %u
	#CleanMethod = KeepInstalled
	Architecture = auto
	
	#IgnorePkg   =
	#IgnorePkg   =
	#IgnoreGroup =
	
	#NoUpgrade   =
	#NoExtract   =
	
	# Misc options
	#UseSyslog
	#Color
	#NoProgressBar
	CheckSpace
	#VerbosePkgLists
	ParallelDownloads = 4
	
	# By default, pacman accepts packages signed by keys that its local keyring
	# trusts (see pacman-key and its man page), as well as unsigned packages.
	SigLevel    = Required DatabaseOptional
	LocalFileSigLevel = Optional
	#RemoteFileSigLevel = Required
	
	# NOTE: You must run `pacman-key --init` before first using pacman; the local
	# keyring can then be populated with the keys of all official Arch Linux
	# packagers with `pacman-key --populate archlinux`.
	
	#
	# REPOSITORIES
	#   - can be defined here or included from another file
	#   - pacman will search repositories in the order defined here
	#   - local/custom mirrors can be added here or in separate files
	#   - repositories listed first will take precedence when packages
	#     have identical names, regardless of version number
	#   - URLs will have $repo replaced by the name of the current repo
	#   - URLs will have $arch replaced by the name of the architecture
	#
	# Repository entries are of the format:
	#       [repo-name]
	#       Server = ServerName
	#       Include = IncludePath
	#
	# The header [repo-name] is crucial - it must be present and
	# uncommented to enable the repo.
	#
	
	# The testing repositories are disabled by default. To enable, uncomment the
	# repo name header and Include lines. You can add preferred servers immediately
	# after the header, and they will be used before the default mirrors.
	
	#[core-testing]
	#Include = /etc/pacman.d/mirrorlist
	
	[core]
	Include = /etc/pacman.d/mirrorlist
	
	#[extra-testing]
	#Include = /etc/pacman.d/mirrorlist
	
	[extra]
	Include = /etc/pacman.d/mirrorlist
	
	# If you want to run 32 bit applications on your x86_64 system,
	# enable the multilib repositories as required here.
	
	#[multilib-testing]
	#Include = /etc/pacman.d/mirrorlist
	
	[multilib]
	Include = /etc/pacman.d/mirrorlist
	
	# An example of a custom package repository.  See the pacman manpage for
	# tips on creating your own repositories.
	#[custom]
	#SigLevel = Optional TrustAll
	#Server = file:///home/custompkgs
EOF

# No fallbackimages will be created if the LTS kernel installed alongside other kernels.
if [[ ! -f /mnt/ealis/kernel-hardened.plugin ]]; then
	if [[ -f /mnt/ealis/kernel.plugin && -f /mnt/ealis/kernel-lts.plugin ]]; then
	cat <<-'EOF' > /mnt/etc/mkinitcpio.d/linux.preset
		# mkinitcpio preset file for the 'linux' package
		
		#ALL_config="/etc/mkinitcpio.conf"
		ALL_kver="/boot/vmlinuz-linux"
		
		#PRESETS=('default' 'fallback')
		PRESETS=('default')
		
		#default_config="/etc/mkinitcpio.conf"
		default_image="/boot/initramfs-linux.img"
		#default_uki="/efi/EFI/Linux/arch-linux.efi"
		#default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"
		
		#fallback_config="/etc/mkinitcpio.conf"
		fallback_image="/boot/initramfs-linux-fallback.img"
		#fallback_uki="/efi/EFI/Linux/arch-linux-fallback.efi"
		fallback_options="-S autodetect"
EOF
	cat <<-'EOF' > /mnt/etc/mkinitcpio.d/linux-lts.preset
		# mkinitcpio preset file for the 'linux-lts' package
		
		#ALL_config="/etc/mkinitcpio.conf"
		ALL_kver="/boot/vmlinuz-linux-lts"
		
		#PRESETS=('default' 'fallback')
		PRESETS=('default')
		
		#default_config="/etc/mkinitcpio.conf"
		default_image="/boot/initramfs-linux-lts.img"
		#default_uki="/efi/EFI/Linux/arch-linux-lts.efi"
		#default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"
		
		#fallback_config="/etc/mkinitcpio.conf"
		fallback_image="/boot/initramfs-linux-lts-fallback.img"
		#fallback_uki="/efi/EFI/Linux/arch-linux-lts-fallback.efi"
		fallback_options="-S autodetect"
EOF
	fi
	if [[ -f /mnt/ealis/kernel-zen.plugin && -f /mnt/ealis/kernel-lts.plugin ]]; then
	cat <<-'EOF' > /mnt/etc/mkinitcpio.d/linux-zen.preset
		# mkinitcpio preset file for the 'linux-zen' package
		
		#ALL_config="/etc/mkinitcpio.conf"
		ALL_kver="/boot/vmlinuz-linux-zen"
		
		#PRESETS=('default' 'fallback')
		PRESETS=('default')
		
		#default_config="/etc/mkinitcpio.conf"
		default_image="/boot/initramfs-linux-zen.img"
		#default_uki="/efi/EFI/Linux/arch-linux-zen.efi"
		#default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"
		
		#fallback_config="/etc/mkinitcpio.conf"
		fallback_image="/boot/initramfs-linux-zen-fallback.img"
		#fallback_uki="/efi/EFI/Linux/arch-linux-zen-fallback.efi"
		fallback_options="-S autodetect"
EOF
	cat <<-'EOF' > /mnt/etc/mkinitcpio.d/linux-lts.preset
		# mkinitcpio preset file for the 'linux-lts' package
		
		#ALL_config="/etc/mkinitcpio.conf"
		ALL_kver="/boot/vmlinuz-linux-lts"
		
		#PRESETS=('default' 'fallback')
		PRESETS=('default')
		
		#default_config="/etc/mkinitcpio.conf"
		default_image="/boot/initramfs-linux-lts.img"
		#default_uki="/efi/EFI/Linux/arch-linux-lts.efi"
		#default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"
		
		#fallback_config="/etc/mkinitcpio.conf"
		fallback_image="/boot/initramfs-linux-lts-fallback.img"
		#fallback_uki="/efi/EFI/Linux/arch-linux-lts-fallback.efi"
		fallback_options="-S autodetect"
EOF
	fi
fi
if [[ -d /mnt/efi ]]; then
EFI=/efi
EFIINSTALL=efibootmgr
elif [[ -d /mnt/boot/efi ]]; then
EFI=/boot/efi
EFIINSTALL=efibootmgr
fi
if [[ $MICROCODE = AuthenticAMD ]]; then
	MICROCODE=amd-ucode
elif [[ $MICROCODE = GenuineIntel ]]; then
	MICROCODE=intel-ucode
fi
if [[ $XFS = xfs ]]; then
	XFS=xfsprogs
fi
if [[ $BTRFS = btrfs ]]; then
	BTRFS=btrfs-progs
fi
if [[ $LVMUSED = LVM2_member ]]; then
	LVM2=lvm2
fi
 

chmod 777 -R /mnt/ealis
clear
echo "Running the first part of the script." && sleep 2

# The mirrorlist for those living in the Netherlands and/or germany. Change if needed.
echo "Reflector is updating your mirrorlist. This might take a while..."
reflector -c germany,netherlands -p https --age 12 --sort score -n 5 --save /etc/pacman.d/mirrorlist

# Installing the base system
pacstrap /mnt man zsh zsh-completions grml-zsh-config reflector grub $EFIINSTALL $MICROCODE $XFS $BTRFS $LVM2 $KERNEL ntfs-3g gdisk util-linux base base-devel networkmanager wget nano nano-syntax-highlighting git curl zram-generator rsync smbclient linux-firmware linux-firmware-whence --needed
pacstrap /mnt kernel-modules-hook --needed
cat /etc/pacman.conf > /mnt/etc/pacman.conf
mkdir -p /mnt/etc/skel/.config/yay
cat <<-'EOF' > /mnt/etc/skel/.config/yay/config.json
	{
		"aururl": "https://aur.archlinux.org",
		"aurrpcurl": "https://aur.archlinux.org/rpc?",
		"buildDir": "/tmp/makepkg",
		"editor": "",
		"editorflags": "",
		"makepkgbin": "makepkg",
		"makepkgconf": "",
		"pacmanbin": "pacman",
		"pacmanconf": "/etc/pacman.conf",
		"redownload": "no",
		"answerclean": "",
		"answerdiff": "",
		"answeredit": "",
		"answerupgrade": "",
		"gitbin": "git",
		"gpgbin": "gpg",
		"gpgflags": "",
		"mflags": "",
		"sortby": "votes",
		"searchby": "name-desc",
		"gitflags": "",
		"removemake": "ask",
		"sudobin": "sudo",
		"sudoflags": "",
		"version": "12.3.5",
		"requestsplitn": 150,
		"completionrefreshtime": 7,
		"maxconcurrentdownloads": 1,
		"bottomup": true,
		"sudoloop": false,
		"timeupdate": false,
		"devel": false,
		"cleanAfter": false,
		"keepSrc": false,
		"provides": true,
		"pgpfetch": true,
		"cleanmenu": true,
		"diffmenu": true,
		"editmenu": false,
		"combinedupgrade": true,
		"useask": false,
		"batchinstall": false,
		"singlelineresults": false,
		"separatesources": true,
		"debug": false,
		"rpc": true,
		"doubleconfirm": true,
		"rebuild": "no"
	}
EOF
sed -i 's/#BUILDDIR/BUILDDIR/' /mnt/etc/makepkg.conf
sed -i 's/#PKGDEST\=\/home\/packages/PKGDEST\=\/var\/cache\/pacman\/aur/' /mnt/etc/makepkg.conf
mkdir -m 775 /mnt/var/cache/pacman/aur
arch-chroot /mnt zsh -c "chown :wheel /var/cache/pacman/aur"

# Installs adduser for easy user configuration.
arch-chroot /mnt zsh -c "pacman -U --needed --noconfirm /ealis/adduser-deb-3.137-1-any.pkg.tar.zst" >/dev/null # The sourcecode can be found here: https://salsa.debian.org/debian/adduser
sed -i 's/#DSHELL\=\/bin\/bash/DSHELL\=\/bin\/zsh/' /mnt/etc/adduser.conf

# Coniguring the language of the system.
clear
echo "Configuring the language of the system..."
while true; do
	read -r LANG1"?What language do you want the system to be in (i.e. en_US)? "
	if [[ -z $LANG1 ]]; then
		echo "Please enter a language."
	else
		break
	fi
done
while true; do
	read -r LANG2"?What language should be used for the other locales, except time (i.e. en_US)? "
	if [[ -z $LANG2 ]]; then
		echo "Please enter a language."
	else
		break
	fi
done
while true; do
	read -r LANG3"?What language should be used for the time locale (i.e. en_US)? "
	if [[ -z $LANG3 ]]; then
		echo "Please enter a language."
	else
		break
	fi
done

sed -i "s/#$LANG1.UTF-8/$LANG1.UTF-8/" /mnt/etc/locale.gen
sed -i "s/#$LANG1\ ISO-8859-1/$LANG1\ ISO-8859-1/" /mnt/etc/locale.gen
if [[ $LANG2 != $LANG1 ]]; then
	sed -i "s/#$LANG2.UTF-8/$LANG2.UTF-8/" /mnt/etc/locale.gen
	sed -i "s/#$LANG2\ ISO-8859-1/$LANG2\ ISO-8859-1/" /mnt/etc/locale.gen
fi
if [[ $LANG3 != $LANG1 || $LANG3 != $LANG2 ]]; then
	sed -i "s/#$LANG3.UTF-8/$LANG3.UTF-8/" /mnt/etc/locale.gen
	sed -i "s/#$LANG3\ ISO-8859-1/$LANG3\ ISO-8859-1/" /mnt/etc/locale.gen
fi
arch-chroot /mnt zsh -c "locale-gen"
read -r HUNSPELL"?Which hunspell (spellcheck) packages do you want to install (i.e. hunspell-en_us)? "
if [[ -z $HUNSPELL ]]; then
	:
else
	echo $HUNSPELL >/mnt/hunspell
	sed -i 's/\s\+/\n/g' /mnt/hunspell || true
	zsh -c "pacman -S --noconfirm - < /hunspell"
	rm /mnt/hunspell
fi

cat <<-EOF > /mnt/etc/locale.conf
	LANG=$LANG1.UTF-8
	LC_ADDRESS=$LANG2.UTF-8
	LC_IDENTIFICATION=$LANG2.UTF-8
	LC_MEASUREMENT=$LANG2.UTF-8
	LC_MONETARY=$LANG2.UTF-8
	LC_NAME=$LANG2.UTF-8
	LC_NUMERIC=$LANG2.UTF-8
	LC_PAPER=$LANG2.UTF-8
	LC_TELEPHONE=$LANG2.UTF-8
	LC_TIME=$LANG3.UTF-8
EOF
# Configuring the timezone.
echo "Configuring the clock of this system..."
while true; do
	read -r ZONEINFO"?In what timezone are you currently living (i.e. US/Central)? "
 	if [[ -z $ZONEINFO ]]; then
		echo "Please enter your timezone."
	else
		break
	fi
done
ln -sf /usr/share/zoneinfo/$ZONEINFO /mnt/etc/localtime

# Configures the zram generator
cat <<-'EOF' > /mnt/etc/systemd/zram-generator.conf
	[zram0]
	zram-size = ram / 2
	compression-algorithm = zstd
	swap-priority = 100
	fs-type = swap
EOF

# Instructs the kernel to be slightly aggressive in swapping out memory pages.
echo "vm.swappiness = 10" | tee /mnt/etc/sysctl.d/99-swappiness.conf >/dev/null

# Sets the standard editor to nano
echo "EDITOR=nano" | tee -a /etc/environment >/dev/null

# Enables Syntax Highlighting for nano
cat <<-'EOF' >> /mnt/etc/nanorc
	include "/usr/share/nano/*.nanorc"
	include "/usr/share/nano/extra/*.nanorc"
	include "/usr/share/nano-syntax-highlighting/*.nanorc"
EOF

# Generates the fstab file
genfstab -U /mnt | tee -a /mnt/etc/fstab >/dev/null
cat <<-'EOF' >> /mnt/etc/fstab
	# /tmp is mounted in ram instead of on the disk
	tmpfs		/tmp		tmpfs		defaults,size=4G,noatime,mode=1777		0 0
EOF

# Adding a system update alias to /etc/skell/zshrc
echo 'alias sysupdate="yes | sudo pacman -Scc && flatpak update --system --noninteractive --assumeyes && yay -Syu"' | tee -a /mnt/etc/skel/.zshrc >/dev/null

# Creating a path for user programs
mkdir -p /mnt/etc/skel/.bin
echo 'export PATH=$HOME/.bin:$PATH' | tee -a /mnt/etc/skel/.zshrc >/dev/null

# Configuring standard applications
mkdir -p /mnt/etc/skel/.config
cat  <<-'EOF' > /mnt/etc/skel/.config/mimeapps.list
	[Default Applications]
	audio/3gpp=vlc.desktop
	audio/3gpp2=vlc.desktop
	audio/AMR=vlc.desktop
	audio/AMR-WB=vlc.desktop
	audio/aac=vlc.desktop
	audio/ac3=vlc.desktop
	audio/basic=vlc.desktop
	audio/dv=vlc.desktop
	audio/eac3=vlc.desktop
	audio/flac=vlc.desktop
	audio/m4a=vlc.desktop
	audio/midi=vlc.desktop
	audio/mp1=vlc.desktop
	audio/mp2=vlc.desktop
	audio/mp3=vlc.desktop
	audio/mp4=vlc.desktop
	audio/mpeg=vlc.desktop
	audio/mpegurl=vlc.desktop
	audio/mpg=vlc.desktop
	audio/ogg=vlc.desktop
	audio/opus=vlc.desktop
	audio/scpls=vlc.desktop
	audio/vnd.dolby.heaac.1=vlc.desktop
	audio/vnd.dolby.heaac.2=vlc.desktop
	audio/vnd.dolby.mlp=vlc.desktop
	audio/vnd.dts=vlc.desktop
	audio/vnd.dts.hd=vlc.desktop
	audio/vnd.rn-realaudio=vlc.desktop
	audio/vorbis=vlc.desktop
	audio/wav=vlc.desktop
	audio/webm=vlc.desktop
	audio/x-aac=vlc.desktop
	audio/x-adpcm=vlc.desktop
	audio/x-aiff=vlc.desktop
	audio/x-ape=vlc.desktop
	audio/x-flac=vlc.desktop
	audio/x-gsm=vlc.desktop
	audio/x-it=vlc.desktop
	audio/x-m4a=vlc.desktop
	audio/x-matroska=vlc.desktop
	audio/x-mod=vlc.desktop
	audio/x-mp1=vlc.desktop
	audio/x-mp2=vlc.desktop
	audio/x-mp3=vlc.desktop
	audio/x-mpeg=vlc.desktop
	audio/x-mpegurl=vlc.desktop
	audio/x-mpg=vlc.desktop
	audio/x-ms-asf=vlc.desktop
	audio/x-ms-asx=vlc.desktop
	audio/x-ms-wax=vlc.desktop
	audio/x-ms-wma=vlc.desktop
	audio/x-musepack=vlc.desktop
	audio/x-pn-aiff=vlc.desktop
	audio/x-pn-au=vlc.desktop
	audio/x-pn-realaudio=vlc.desktop
	audio/x-pn-realaudio-plugin=vlc.desktop
	audio/x-pn-wav=vlc.desktop
	audio/x-pn-windows-acm=vlc.desktop
	audio/x-real-audio=vlc.desktop
	audio/x-realaudio=vlc.desktop
	audio/x-s3m=vlc.desktop
	audio/x-scpls=vlc.desktop
	audio/x-shorten=vlc.desktop
	audio/x-speex=vlc.desktop
	audio/x-tta=vlc.desktop
	audio/x-vorbis=vlc.desktop
	audio/x-vorbis+ogg=vlc.desktop
	audio/x-wav=vlc.desktop
	audio/x-wavpack=vlc.desktop
	audio/x-xm=vlc.desktop
	audio/mp4a-latm=vlc.desktop
	audio/mpeg3=vlc.desktop
	audio/wave=vlc.desktop
	audio/x-mpeg-3=vlc.desktop
	audio/x-ogg=vlc.desktop
	audio/x-oggflac=vlc.desktop
	image/avif=xviewer.desktop
	image/bmp=xviewer.desktop
	image/gif=xviewer.desktop
	image/heif=xviewer.desktop
	image/jpeg=xviewer.desktop
	image/jpg=xviewer.desktop
	image/pjpeg=xviewer.desktop
	image/png=xviewer.desktop
	image/svg+xml=xviewer.desktop
	image/svg+xml-compressed=xviewer.desktop
	image/tiff=xviewer.desktop
	image/vnd.wap.wbmp=xviewer.desktop
	image/webp=xviewer.desktop
	image/x-bmp=xviewer.desktop
	image/x-gray=xviewer.desktop
	image/x-icb=xviewer.desktop
	image/x-ico=xviewer.desktop
	image/x-pcx=xviewer.desktop
	image/x-png=xviewer.desktop
	image/x-portable-anymap=xviewer.desktop
	image/x-portable-bitmap=xviewer.desktop
	image/x-portable-graymap=xviewer.desktop
	image/x-portable-pixmap=xviewer.desktop
	image/x-xbitmap=xviewer.desktop
	image/x-xpixmap=xviewer.desktop
	application/pdf=xreader.desktop
	inode/directory=nemo.desktop

	[Added Associations]
	audio/3gpp=vlc.desktop;
	audio/3gpp2=vlc.desktop;
	audio/AMR=vlc.desktop;
	audio/AMR-WB=vlc.desktop;
	audio/aac=vlc.desktop;
	audio/ac3=vlc.desktop;
	audio/basic=vlc.desktop;
	audio/dv=vlc.desktop;
	audio/eac3=vlc.desktop;
	audio/flac=vlc.desktop;
	audio/m4a=vlc.desktop;
	audio/midi=vlc.desktop;
	audio/mp1=vlc.desktop;
	audio/mp2=vlc.desktop;
	audio/mp3=vlc.desktop;
	audio/mp4=vlc.desktop;
	audio/mpeg=vlc.desktop;
	audio/mpegurl=vlc.desktop;
	audio/mpg=vlc.desktop;
	audio/ogg=vlc.desktop;
	audio/opus=vlc.desktop;
	audio/scpls=vlc.desktop;
	audio/vnd.dolby.heaac.1=vlc.desktop;
	audio/vnd.dolby.heaac.2=vlc.desktop;
	audio/vnd.dolby.mlp=vlc.desktop;
	audio/vnd.dts=vlc.desktop;
	audio/vnd.dts.hd=vlc.desktop;
	audio/vnd.rn-realaudio=vlc.desktop;
	audio/vorbis=vlc.desktop;
	audio/wav=vlc.desktop;
	audio/webm=vlc.desktop;
	audio/x-aac=vlc.desktop;
	audio/x-adpcm=vlc.desktop;
	audio/x-aiff=vlc.desktop;
	audio/x-ape=vlc.desktop;
	audio/x-flac=vlc.desktop;
	audio/x-gsm=vlc.desktop;
	audio/x-it=vlc.desktop;
	audio/x-m4a=vlc.desktop;
	audio/x-matroska=vlc.desktop;
	audio/x-mod=vlc.desktop;
	audio/x-mp1=vlc.desktop;
	audio/x-mp2=vlc.desktop;
	audio/x-mp3=vlc.desktop;
	audio/x-mpeg=vlc.desktop;
	audio/x-mpegurl=vlc.desktop;
	audio/x-mpg=vlc.desktop;
	audio/x-ms-asf=vlc.desktop;
	audio/x-ms-asx=vlc.desktop;
	audio/x-ms-wax=vlc.desktop;
	audio/x-ms-wma=vlc.desktop;
	audio/x-musepack=vlc.desktop;
	audio/x-pn-aiff=vlc.desktop;
	audio/x-pn-au=vlc.desktop;
	audio/x-pn-realaudio=vlc.desktop;
	audio/x-pn-realaudio-plugin=vlc.desktop;
	audio/x-pn-wav=vlc.desktop;
	audio/x-pn-windows-acm=vlc.desktop;
	audio/x-real-audio=vlc.desktop;
	audio/x-realaudio=vlc.desktop;
	audio/x-s3m=vlc.desktop;
	audio/x-scpls=vlc.desktop;
	audio/x-shorten=vlc.desktop;
	audio/x-speex=vlc.desktop;
	audio/x-tta=vlc.desktop;
	audio/x-vorbis=vlc.desktop;
	audio/x-vorbis+ogg=vlc.desktop;
	audio/x-wav=vlc.desktop;
	audio/x-wavpack=vlc.desktop;
	audio/x-xm=vlc.desktop;
	audio/mp4a-latm=vlc.desktop;
	audio/mpeg3=vlc.desktop;
	audio/wave=vlc.desktop;
	audio/x-mpeg-3=vlc.desktop;
	audio/x-ogg=vlc.desktop;
	audio/x-oggflac=vlc.desktop;
	image/avif=xviewer.desktop;
	image/bmp=xviewer.desktop;
	image/gif=xviewer.desktop;
	image/heif=xviewer.desktop;
	image/jpeg=xviewer.desktop;
	image/jpg=xviewer.desktop;
	image/pjpeg=xviewer.desktop;
	image/png=xviewer.desktop;
	image/svg+xml=xviewer.desktop;
	image/svg+xml-compressed=xviewer.desktop;
	image/tiff=xviewer.desktop;
	image/vnd.wap.wbmp=xviewer.desktop;
	image/webp=xviewer.desktop;
	image/x-bmp=xviewer.desktop;
	image/x-gray=xviewer.desktop;
	image/x-icb=xviewer.desktop;
	image/x-ico=xviewer.desktop;
	image/x-pcx=xviewer.desktop;
	image/x-png=xviewer.desktop;
	image/x-portable-anymap=xviewer.desktop;
	image/x-portable-bitmap=xviewer.desktop;
	image/x-portable-graymap=xviewer.desktop;
	image/x-portable-pixmap=xviewer.desktop;
	image/x-xbitmap=xviewer.desktop;
	image/x-xpixmap=xviewer.desktop;
	application/pdf=xreader.desktop;
	inode/directory=nemo.desktop;
EOF

# Creating the first user
clear
echo "We are creating a new user with sudo privileges and locking down root."
while true; do
        read -r VARUSERNAME"?The name of the new user (no spaces, special symbols or caps): "
        if [[ $VARUSERNAME =~ [A-Z] || ${VARUSERNAME//[[:alnum:]]/} ]]; then
                echo "You entered an invalid username. Please try again." >&2
        elif [[ -z $VARUSERNAME ]]; then
                while true; do
                        read -r yn"?You didn't enter an username. Do you want to skip this part of the script? (y/N): "
                        case $yn in
                                [yY] ) break 2;;
                                [nN] ) break;;
                                "" ) break;;
                                *) echo "Wrong answer. Answer with either \"Y\" or \"N\"." >&2
                        esac
                done
        else
                arch-chroot /mnt zsh -c "usermod root -p '!' -s /bin/zsh && adduser $VARUSERNAME && usermod $VARUSERNAME -aG wheel,users,$VARUSERNAME && cat /ealis/sudoers | tee /etc/sudoers >/dev/null"
                break
        fi
done
sed -i 's/bash/zsh/' /mnt/etc/default/useradd
arch-chroot /mnt zsh -c "pacman -Rns adduser-deb --noconfirm" >/dev/null 2>&1 || true

# Setting your hostname
echo ""
echo "We are setting the hostname for this machine."
while true; do
read -r VARHOST"?What will be the hostname of this machine (no spaces or special characters)? "
	if [[ ${VARHOST//[[:alnum:]]/} ]]; then
		echo "You entered a invalid hostname. Please try again." >&2
	elif [[ -z $VARHOST ]]; then
		echo "You didn't enter a hostname. Please try again." >&2
	else
		VAR2HOST=$(echo "$VARHOST" | tr '[:upper:]' '[:lower:]')
		echo "$VARHOST" | tee /mnt/etc/hostname >/dev/null
cat <<-EOF >> /mnt/etc/hosts
	127.0.0.1	localhost	localhost.localdomain	localhost.local
 	127.0.1.1	$VAR2HOST	$VAR2HOST.localdomain	$VAR2HOST.local
EOF
		break
	fi
done

# Configuring the bootloader
echo "";echo "Configuring GRUB..." && sleep 2
if [[ $ENCUSED = crypto ]]; then
	echo "You are using LUKS Encryption. You need to configure mkinitcpio manually." && sleep 2
	if [[ $LVMUSED = LVM2_member ]]; then
		echo "You are also using Logical Volumes. Don't forget to add said module to mkinitcpio as well." && sleep 2
	fi
	if [[ -d /mnt/efi || -d /mnt/boot/efi ]]; then
 		arch-chroot /mnt zsh -c "grub-install --target=x86_64-efi --efi-directory=$EFI --recheck >/dev/null 2>&1 && grub-mkconfig -o /boot/grub/grub.cfg >dev/null || echo 'Your boot partition or directory (/boot) is encrypted, you need to configure grub manually.' && sleep 2"
	else
 		arch-chroot /mnt zsh -c "grub-install --target=i386-pc --recheck >/dev/null 2>&1 && grub-mkconfig -o /boot/grub/grub.cfg >/dev/null || echo 'Your boot partition or directory (/boot) is encrypted, you need to configure grub manually.' && sleep 2"
 	fi
elif [[ $LVMUSED = LVM2_member ]]; then
	echo "You are using Logical Volumes. The \"lvm2\" package will be installed. You need to configure mkinitcpio manually." && sleep 2
	if [[ -d /mnt/efi || -d /mnt/boot/efi ]]; then
 		arch-chroot /mnt zsh -c "grub-install --target=x86_64-efi --efi-directory=$EFI --recheck >/dev/null && grub-mkconfig -o /boot/grub/grub.cfg >/dev/null"
  	else
   		arch-chroot /mnt zsh -c "grub-install --target=i386-pc --recheck >/dev/null && grub-mkconfig -o /boot/grub/grub.cfg >/dev/null"
	fi
else
	if [[ -d /mnt/efi || -d /mnt/boot/efi ]]; then
 		arch-chroot /mnt zsh -c "grub-install --target=x86_64-efi --efi-directory=$EFI --recheck >/dev/null && grub-mkconfig -o /boot/grub/grub.cfg >/dev/null"
  	else
   		arch-chroot /mnt zsh -c "grub-install --target=i386-pc --recheck >/dev/null && grub-mkconfig -o /boot/grub/grub.cfg >/dev/null"
	fi
fi

# Changes the bootorder of your system so LTS is not the default.
if [[ -f /mnt/ealis/kernel.plugin && -f /mnt/ealis/kernel-lts.plugin ]]; then
	sed -i 's/-r/-V/' /mnt/etc/grub.d/10_linux
fi

# Here you make any changed and additions needed.
echo ""
echo "Entering your new system..."
arch-chroot /mnt zsh -c 'echo "Succesfully entered your new system"' && EDITOR=nano arch-chroot /mnt zsh
echo ""
echo "This script has runned succesfully. Please reboot."
