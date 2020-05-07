# Minimal Ubuntu 18.04 LTS from existing VM

### Creating the required base VM
This is required until I decide to preseed the installation. (Which sucks BTW)
1. Download [Ubuntu 18.04 (Bionic) mini.iso](http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso).
2. Create a VirtualBox VM and connect mini.iso.
3. Boot the VM and install Ubuntu. The Task `OpenSSH Server` must be selected!
4. Shutdown the VM and create a snapshot for Packer.

### Project structure
- User variables:
  - `vm_name`: Name of the VM created in step 2. (default: `base-ubuntu-18.04`).
  - `attach_snapshot`: Name of the snapshot created in step 4 (default: `packer-start`).
  - `target_snapshot`: Name of the snapshot created after Packer finished (default: `packer-finished`).
  - `ssh_username`: Name of the user created during Ubuntu installation (default: `ubuntu`).
  - `ssh_password`: The password for the user set in `ssh_username` (default: `ubuntu`).
  - `skip_export`: When set to `false`, the cleanup script will reduce image size and prepare the VM for cloning. The VM will be exported as OVA (default: `false`).
  - `headless`: When set to `true`, Packer will the VM start without a console *during build* (default: `true`).
  - `force_delete_snapshot`: When set to `true`, overwrite an existing `target_snapshot`. Otherwise Packer will yield an error if the specified target snapshot already exists (default: `false`).
  - `cleanup_dev_mode`: When set to `true`, the cleanup script will run in development mode and won't reduce the image size (default: `false`).
- Builders:
  - [virtualbox-vm](https://www.packer.io/docs/builders/virtualbox/vm/)
    - Communicator: [ssh](https://www.packer.io/docs/communicators/ssh/)
    - Export format: OVA
- Provisioners:
  - [file](https://www.packer.io/docs/provisioners/file/)
  - [shell](https://www.packer.io/docs/provisioners/shell/)
  - [shell-local](https://www.packer.io/docs/provisioners/shell-local/)

### Notes on the VM built by this Packer file
  - SSH access is only possible if you copy the desired `authorized_keys` file to your *running* VM.
    - You can use the VirtualBox UI of your VM (Menu: `Machine/File Manager...`)
    - You can use the command line
      - Example: `VBoxManage guestcontrol base-ubuntu-18.04 copyto --username ubuntu --password ubuntu --verbose --target-directory /home/ubuntu/.ssh /path/to/local/desired/authorized_keys`
