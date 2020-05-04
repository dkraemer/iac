# Infrastructure as Code using the [HashiCorp Stack](https://www.hashicorp.com/#overview)
A collection of templates to automate my virtual test environment.

### Required software
- [Oracle VirtualBox 6.1.6](https://www.virtualbox.org/wiki/Downloads)
- [HashiCorp packer 1.5.5](https://www.packer.io/downloads/)

### Creating the required base VM
This is required until I decide to preseed the installation. (Which sucks BTW)
1. Download [Ubuntu 18.04 (Bionic) mini.iso](http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso)
2. Create a VirtualBox VM and connect mini.iso.
3. Boot the VM and install Ubuntu. The Task `OpenSSH Server` must be selected!
4. Shutdown the VM and create a snapshot for packer.

### Project structure
- [Settings](.vscode) for [Visual Studio Code](https://code.visualstudio.com/)
- Files for packer (build and provision)
  - [Minimal Ubuntu 18.04 LTS base image](packer/base-ubuntu-18.04)
    - Variables:
      - `dev_mode`: When set to `yes`, the provision script will run in development mode (default: `no`).
      - `source_vm_name`: Name of the VM created in step 2. (default: `base-ubuntu-18.04`).
      - `source_vm_attach_snapshot`: Name of the snapshot created in step 4 (default: `packing`).
      - `source_vm_target_snapshot`: Name of the snapshot that is created by packer (default: `packed`).
      - `source_vm_user`: Name of the user created during Ubuntu installation (default: `ubuntu`).
      - `source_vm_password`: User's password (default: `ubuntu`).
      - `vm_cleanup`: When set to `yes`, the provision script will reduce the image-size and prepare the VM for cloning/exporting (default: `yes`).
      - `output_name_prefix`: Prefix for `output_name` (default: `base-`)
      - `output_name`: Name of the created OVA (default: `ubuntu-18.04`)
    - Builders:
      - [virtualbox-vm](https://www.packer.io/docs/builders/virtualbox/vm/)
        - Communicator: [ssh](https://www.packer.io/docs/communicators/ssh/)
        - Export format: OVA
    - Provisioners:
      - [file](https://www.packer.io/docs/provisioners/file/)
      - [shell](https://www.packer.io/docs/provisioners/shell/)
      - [shell-local](https://www.packer.io/docs/provisioners/shell-local/)
