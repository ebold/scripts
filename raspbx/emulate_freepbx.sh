#!/bin/bash

# emulate FreePBX with provided image file (eg., raspbx_20180709_bak.img)

# requires: qemu-system-arm
#           ($ sudo apt-get install qemu-system-arm qemu-efi)

KERNEL="$HOME/kernel-qemu-3.10.25-wheezy"
image="$1"
qemu-system-arm -kernel "$KERNEL" -cpu arm1176 -m 256 \
                -M versatilepb -no-reboot -daemonize\
                -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw" \
                -hda "$image"
