#!/bin/bash
# Copyright 2020 Daniel Kraemer <dkraemer@dkross.org>. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

set -o nounset
set -o errexit

apt_get="sudo DEBIAN_FRONTEND=noninteractive apt-get"
apt_get_install="${apt_get} install -y --no-install-recommends"
apt_get_autoremove="${apt_get} autoremove -y --purge"

### Unlock sudo and add provision sudoers file
echo $PASSWORD | sudo -S echo "sudo unlocked"
echo "$USER ALL=(ALL) NOPASSWD:ALL" | (sudo su -c 'EDITOR="tee -a" visudo -f /etc/sudoers.d/provision')

### Remove password and disable password login
sudo passwd -d $USER
sudo passwd -l $USER

### Enable tracing AFTER using password operations
set -o xtrace

### Update & upgrade packages
$apt_get update
$apt_get upgrade -y

### All paths are relative to HOME
cd $HOME

### Install VirtualBox guest additions
$apt_get_install make gcc perl linux-headers-$(uname -r)
sudo mount -v VBoxGuestAdditions.iso /media -o loop,ro
set +o errexit
sudo /media/VBoxLinuxAdditions.run
set -o errexit
sudo umount /media
rm -v -f VBoxGuestAdditions.iso

### Install default grub config
sudo mv -v /etc/default/grub /etc/default/grub.ubuntu
sudo install -v -m 644 grub /etc/default/
rm -v -f grub
sudo update-grub

### Remove swapfile
sudo swapoff /swapfile
sudo rm -v -f /swapfile
sudo sed -e 's;^/swapfile.*;;' -i /etc/fstab

### Setup /tmp as tmpfs
echo 'tmpfs /tmp tmpfs defaults 0 0' | (sudo su -c 'tee -a /etc/fstab')
sudo rm -v -r -f /tmp
sudo mkdir -v -m 1777 /tmp
sudo mount -v /tmp

### Setup SSH
sudo sed -e 's/^#\(PermitRootLogin\).*/\1 no/' -e 's/^#\(PasswordAuthentication\).*/\1 no/' -i /etc/ssh/sshd_config
chmod -v 600 authorized_keys
mkdir -v -m 700 .ssh
mv -v authorized_keys .ssh/

### Disable clearing off tty1
sudo mkdir -v '/etc/systemd/system/getty@tty1.service.d/'
sudo install -v -m 644 noclear.conf '/etc/systemd/system/getty@tty1.service.d/'
rm -v -f noclear.conf

### Install .bash_aliases
chmod -v 644 .bash_aliases
sudo cp -v .bash_aliases /etc/skel/
sudo cp -v .bash_aliases /root/

### Install zerofree files for systemd
sudo install -v -m 744 zerofree.sh /usr/local/sbin/
sudo install -v -m 644 zerofree.service /etc/systemd/system/
sudo install -v -m 644 zerofree.target /etc/systemd/system/
rm -v -f zerofree.*

### Install addtional packages
$apt_get_install zerofree net-tools

### Purge unwanted packages
$apt_get_autoremove plymouth linux-firmware

### Purge unneeded auto packages
# TODO: Is this really required? Does the previous run:
# a) Remove ONLY plymouth, ... and their auto packages?
# b) Remove ALL unneeded auto packages?
$apt_get_autoremove

### Free diskspace on demand
if [ "${COMPACT}" == "yes" ]; then
    # Remove VBoxAddition pre-reqs
    $apt_get_autoremove make gcc perl linux-headers-$(uname -r)

    # Clean apt
    $apt_get clean
    sudo rm -v -r -f /var/lib/apt/lists/*

    # Boot to zerofree.target
    sudo zerofree.sh
fi
