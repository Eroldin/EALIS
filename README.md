# **Eroldin’s Arch Linux Install Script**
The requirements you need before running this script are that you’ve manually formatted your partitions and mounted it on /mnt accordingly.
EALIS is a simple installation script (though some knowledge on how to install Arch Linux s=is required) for installing a multi-purpose Arch Linux system. It features:

- A plugin system: move the plug-in files from the Plugin directory to the root of the script’s folder to install said programs when running the scripts.
- Easy access to multiple desktop environments. For now, only Xfce4 and Cinnamon are supported. More will be added soon.
- This script knows what kind of system you are using. Whether you are on a bios system, efi system (mounted either at /boot/efi or /efi), you’re using LVM and/or encryption. Keep in mind though that some editing of your /etc/mkinitcpio.conf file might be needed.
