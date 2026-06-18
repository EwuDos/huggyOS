#!/bin/bash
# HuggyOS build script
set -e

echo "==> Building HuggyOS..."

# 1. Создаём rootfs через debootstrap
sudo debootstrap --arch=amd64 --components=main,universe jammy rootfs http://archive.ubuntu.com/ubuntu/

# 2. Копируем конфиги
sudo cp -r configs/* rootfs/etc/
sudo cp -r branding/* rootfs/usr/share/backgrounds/huggylinux/ 2>/dev/null || true

# 3. Входим в chroot и донастраиваем
sudo chroot rootfs /bin/bash <<'CHROOT'
apt update
apt install -y xfce4 xfce4-goodies lightdm calamares neofetch htop firefox
# ... (добавь свои команды)
exit
CHROOT

# 4. Копируем ядро и initrd
sudo cp rootfs/boot/vmlinuz-*-generic iso/casper/vmlinuz
sudo cp rootfs/boot/initrd.img-*-generic iso/casper/initrd

# 5. Собираем squashfs
sudo mksquashfs rootfs iso/casper/filesystem.squashfs -comp xz -e boot

# 6. Собираем ISO
sudo xorriso -as mkisofs -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -c isolinux/boot.cat -b isolinux/isolinux.bin \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/eltorito.img -no-emul-boot \
  -isohybrid-gpt-basdat \
  -iso-level 3 -full-iso9660-filenames -volid "HuggyOS" \
  -o huggy-os-1.2.iso iso/

echo "==> ISO built: huggy-os-1.2.iso"
