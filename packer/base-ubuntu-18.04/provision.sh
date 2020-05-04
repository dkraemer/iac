#!/bin/bash
# Copyright 2020 Daniel Kraemer <dkraemer@dkross.org>. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
echo "DEV_MODE=${DEV_MODE}"
set -o nounset
set -o errexit

### Unlock sudo and add provision sudoers file
echo $PASSWORD | sudo -S echo "sudo unlocked"
echo "$USER ALL=(ALL) NOPASSWD:ALL" | (sudo su -c 'EDITOR="tee -a" visudo -f /etc/sudoers.d/provision')

### Remove password and disable password login
sudo passwd -d $USER
sudo passwd -l $USER

### Install files in files.tar.gz
tar -xzf files.tar.gz -C /tmp
rm -v -f files.tar.gz
chmod +x /tmp/files/installer
/tmp/files/installer

### Enable tracing
set -o xtrace

### Source common code (installed from files.tar.gz)
. /opt/provision/common

### Update & upgrade packages
$apt_get update
$apt_get upgrade -y

### Install VirtualBox guest additions
$apt_get_install $vbox_required_packages
sudo mount -v VBoxGuestAdditions.iso /media -o loop,ro
set +o errexit
sudo /media/VBoxLinuxAdditions.run
set -o errexit
sudo umount /media
rm -v -f VBoxGuestAdditions.iso

### Remove swapfile
sudo swapoff /swapfile
sudo rm -v -f /swapfile
sudo sed -e 's;^/swapfile.*;;' -i /etc/fstab

### Setup /tmp as tmpfs
echo 'tmpfs /tmp tmpfs defaults 0 0' | (sudo su -c 'tee -a /etc/fstab')
sudo rm -v -r -f /tmp
sudo mkdir -v -m 1777 /tmp
sudo mount -v /tmp

### SSH: Disable root login and password authentication
sudo sed -e 's/^#\(PermitRootLogin\).*/\1 no/' -e 's/^#\(PasswordAuthentication\).*/\1 no/' -i /etc/ssh/sshd_config

### Purge unwanted packages
$apt_get_autoremove plymouth linux-firmware

### Purge unneeded auto packages
# TODO: Is this really required? Does the previous run:
# a) Remove ONLY plymouth, ... and their auto packages?
# b) Remove ALL unneeded auto packages?
$apt_get_autoremove

### Free diskspace on demand
if [ "${COMPACT}" == "yes" ]; then

    # Tell cleanup.sh to run in development mode
    if [ "${DEV_MODE}" == "yes" ]; then
        sudo touch /.dev_mode
    fi

    sudo /opt/provision/cleanup.sh start
fi
