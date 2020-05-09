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

        # Enable finish service
        systemctl enable cleanup-finish.service

        # Boot to cleanup.target
        systemctl set-default cleanup.target
        systemctl reboot
        ;;

    # Called from cleanup.service
    # Perform offline cleanup
    run)
        # We need a writeable rootfs
        mount -v / -o remount,rw

        # Restore the default target
        systemctl set-default multi-user.target

        # apt-daily.timer acquires lock and breaks apt execution in our 'finish'
        # Closes https://github.com/dkraemer/iac/issues/16
        systemctl disable apt-daily.timer

        # Tell grub that this boot was successful
        grub-editenv /boot/grub/grubenv unset recordfail

        # Prepare the re-generation of new SSH host keys
        rm -v -f /etc/ssh/ssh_host_*

        # Remove apt lists
        rm -v -r -f /var/lib/apt/lists/*

        # Remove all logs
        find /var/log -type f -delete

        # Run zerofree only when NOT in development mode
        if [ "${CLEANUP_DEV_MODE}" != 'true' ]; then
            mount -v / -o remount,ro
            zerofree -v /dev/sda2
        fi

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

        # Upgrade packages on first boot
        $apt_get upgrade -y

        # Re-install packages for VirtualBox kernel modules
        $apt_get_install $vbox_required_packages

        # Disable cleanup-finish.service
        systemctl disable cleanup-finish.service

        # Re-enable apt-dialy.timer
        systemctl enable apt-daily.timer

        # Exit this script when not preparing the system for Vagrant
        if [ "${PREPARE_FOR_VAGRANT}" != 'true' ]; then
            exit 0
        fi

        ### Setup this VM as a Vagrant base box
        # The original provision user is no longer required
        deluser --remove-home $PROVISION_USER
        rm -v -f /etc/sudoers.d/provision

        # See: https://www.vagrantup.com/docs/boxes/base.html#default-user-settings
        # Add vagrant user
        adduser --gecos 'Vagrant user' --disabled-password vagrant

        # SSH: Install vagrant's temporary insecure public key
        mkdir -v -m 700 /home/vagrant/.ssh
        wget 'https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub' -O /home/vagrant/.ssh/authorized_keys
        rm -v -f /root/.wget-hsts
        chmod -v 600 /home/vagrant/.ssh/authorized_keys
        chown -v -R vagrant.vagrant /home/vagrant/.ssh

        # Set root password
        yes vagrant | passwd root

        # Enable password-less sudo
        export EDITOR='tee -a'
        echo 'vagrant ALL=(ALL) NOPASSWD:ALL' | visudo -f /etc/sudoers.d/vagrant
        ;;

    # Handle unknown commands
    *)
        print_usage
esac
exit 0
