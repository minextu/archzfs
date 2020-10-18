#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="archlinux_zfs"
iso_label="ARCHZFS_$(date +%Y%m)"
iso_publisher="ArchZFS <https://www.archzfs.com>"
iso_application="Arch Linux ZFS Live/Rescue CD"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
