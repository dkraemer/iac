#!/bin/bash
#
# This script helps to prepare the VM for exporting or cloning.
# By temporarily removing packages the export size is reduced.
#
# Copyright 2020 Daniel Kraemer <dkraemer@dkross.org>. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
set -o nounset
set -o errexit
#set -o xtrace

print_usage() {
    echo "Usage: $0 start|run|finish" >/dev/stderr
    exit 1
}

### Sanity checks
if [ $# -ne 1 ]; then
    print_usage
fi
if [ $(id -u) -ne 0 ]; then
    echo "ERROR: Only root can execute this script!" >/dev/stderr
    exit 1
fi
if [ ! -f /etc/systemd/system/cleanup.target ]; then
    echo "ERROR: File '/etc/systemd/system/cleanup.target' does not exist!" >/dev/stderr
    exit 1
fi
if [ ! -f /etc/systemd/system/cleanup.service ]; then
    echo "ERROR: File '/etc/systemd/system/cleanup.service' does not exist!" >/dev/stderr
    exit 1
fi

### Source common code
. /opt/provision/common

### Main
case "$1" in

    # Called from command-line
    # Prepare the system and perform an online cleanup
    start)
        # zerofree is required by 'run'
        $apt_get_install zerofree

        # Free space by removing packages for building VirtualBox's kernel modules (they are re-installed later)
        $apt_get_autoremove $vbox_required_packages

        # Clean apt package cache
        $apt_get clean
        rm -v -r -f /var/lib/apt/lists/*

        # Enable finish service
        systemctl enable cleanup-finish.service

        # Boot to cleanup.target
        systemctl set-default cleanup.target
        systemctl reboot
        ;;

    # Called from cleanup.service
    # Perform offline cleanup
    run)

        # Prepare the generation of new SSH host keys
        mount -v / -o remount,rw
        rm -v -f /etc/ssh/ssh_host_*
        mount -v / -o remount,ro

        # Run zerofree only when NOT in development mode
        if [ ! -f /.cleanup_dev_mode ]; then
            zerofree -v /dev/sda2
        fi
        
        # The following commands need a writable filesystem
        mount -v / -o remount,rw

        # Restore the default target
        systemctl set-default multi-user.target

        # Tell grub that this boot was successful
        grub-editenv /boot/grub/grubenv unset recordfail

        # Shutdown the VM for exporting/cloning
        systemctl poweroff
        ;;

    # Called from cleanup-finish.service after first boot
    # Restore working system state
    finish)
        # Generate SSH host keys
        DEBIAN_FRONTEND=noninteractive dpkg-reconfigure openssh-server

        # Populate apt package cache again
        $apt_get update

        # Re-install packages for VirtualBox kernel modules
        $apt_get_install $vbox_required_packages

        # Disable cleanup-finish.service
        systemctl disable cleanup-finish.service

        # Remove possible left-over file from development mode
        if [ -f /.cleanup_dev_mode ]; then
            rm -v -f /.cleanup_dev_mode
        fi
        ;;
    *)
        print_usage
esac
exit 0
