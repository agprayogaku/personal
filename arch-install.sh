#!/bin/bash

# === USER VARIABLES ===
DISK="/dev/nvme0n1"
EFI_PART="${DISK}p1"
ROOT_PART="${DISK}p4"
HOSTNAME="thinkpad-arch"
USERNAME="agung"
PASSWORD="toor" # Change after installation
TIMEZONE="Asia/Jakarta"
LOCALE="en_US.UTF-8"

# === MOUNT FILESYSTEM ===
mount $ROOT_PART /mnt
mkdir /mnt/boot
mount $EFI_PART /mnt/boot

# === INSTALL BASE SYSTEM ===
pacstrap -K /mnt base linux linux-firmware sudo networkmanager intel-ucode systemd-boot intel-media-driver mesa

# === CONFIGURE SYSTEM ===
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<EOF

# Time and locale
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "$LOCALE UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

# Hostname and hosts
echo "$HOSTNAME" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
HOSTS

# Root password
echo "root:$PASSWORD" | chpasswd

# Create user
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Enable essential services
systemctl enable NetworkManager

# Bootloader - systemd-boot (safer than GRUB with EFI conflicts)
bootctl install
cat <<LOADER > /boot/loader/loader.conf
default arch
timeout 3
editor no
LOADER

cat <<ARCHBOOT > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=$ROOT_PART rw
ARCHBOOT

# DE: KDE Plasma (wayland/x11), audio (pipewire)
pacman -Sy --noconfirm xorg plasma kde-applications \
    sddm pipewire pipewire-audio wireplumber \
    xdg-desktop-portal xdg-desktop-portal-kde

systemctl enable sddm

EOF

# Done
echo -e "\nInstallation complete! Unmounting..."
umount -R /mnt
echo "Reboot and enjoy your KDE Arch system!"