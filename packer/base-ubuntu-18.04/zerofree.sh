#!/bin/bash
# Copyright 2020 Daniel Kraemer <dkraemer@dkross.org>. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# Sanity checks
if [ $(id -u) -ne 0 ]; then
    echo "Only root can execute this script!" >/dev/stderr
    exit 1
fi
if [ ! -f /etc/systemd/system/zerofree.target ]; then
    echo "zerofree.target not found!" >/dev/stderr
    exit 1
fi
if [ ! -f /etc/systemd/system/zerofree.service ]; then
    echo "zerofree.service not found!" >/dev/stderr
    exit 1
fi

# Enable tracing
set -o xtrace

# Called from zerofree.service
if [ "$1" == "service" ]; then
    # Execute zerofree
    zerofree -v /dev/sda2

    # Restore default target
    mount -v / -o remount,rw
    systemctl set-default multi-user.target
    
    # Tell grub that this boot was successful
    grub-editenv /boot/grub/grubenv unset recordfail
    
    # Shutdown VM
    systemctl poweroff
fi

# Called from command-line
# Set zerofree.target and reboot
systemctl set-default zerofree.target
systemctl reboot
