===============
Archzfs Archiso
===============

Used to create custom archiso with archzfs integrated. Supports only the x86_64 architecture. The archiso package needs to be installed.

How to use:

.. code:: console

    # ./build.sh -v

to test with qemu,

.. code:: console

    # qemu-system-x86_64 -enable-kvm -m 4096 -smp 2 -drive file=./out/archlinux_zfs-2016.09.04.iso,if=virtio,media=disk,format=raw
