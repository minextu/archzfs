#!/bin/bash
if [[ ! -f /.dockerenv ]]; then
    echo "This script must be run in a docker container!"
    exit 1
fi

# fix /dev/shm symbolic link
mkdir /run/shm

# update system
pacman -Syu --noconfirm

# install needed pacman packages
pacman -S --noconfirm git wget pkgbuild-introspection

# add build user
useradd -m demizer
mkdir -p /scratch/chroot64

# give sudo permissions to build user
echo "demizer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# install ccm64
su -s /bin/bash demizer -c "
cd ~
wget https://aur.archlinux.org/cgit/aur.git/snapshot/clean-chroot-manager.tar.gz
tar -xvf clean-chroot-manager.tar.gz
cd clean-chroot-manager
makepkg -si --noconfirm
"

# run ccm64 once, to generate config file
su -s /bin/bash demizer -c "sudo ccm64"
# create new chroot
su -s /bin/bash demizer -c "sudo ccm64 c"

# test: remove!!
su -s /bin/bash demizer -c "
cd ~/clean-chroot-manager
sudo ccm64 s
"
