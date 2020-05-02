#!/bin/bash
set -o nounset
set -o errexit

apt_get="sudo DEBIAN_FRONTEND=noninteractive apt-get"
apt_get_install="${apt_get} install -y --no-install-recommends"

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
$apt_get_install make gcc perl
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

### Install .bash_aliases
chmod -v 644 .bash_aliases
sudo cp -v .bash_aliases /etc/skel/
sudo cp -v .bash_aliases /root/

### Install addtional packages
$apt_get_install zerofree

### Purge unwanted packages
$apt_get remove -y --purge plymouth linux-firmware

### Purge unneeded auto packages
$apt_get autoremove -y --purge
