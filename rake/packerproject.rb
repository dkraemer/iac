# Copyright 2020 Daniel Kraemer <dkraemer@dkross.org>. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

require_relative 'project.rb'
require_relative 'utils.rb'
require_relative 'vboxmanage.rb'

class PackerProject < Project

  PACKER_FILE_NAME = 'packer.json'
  PACKER_OUTPUT_DIR = 'output'

  # Invoke the packer executable
  def packer(command, *extra_args)
    Utils.mandatory_argument(command, 'command')

    # Pass extra arguments to packer
    packer_args = ''
    unless extra_args.nil?
      extra_args.each do |arg|
        packer_args += " #{arg}"
      end
    end

    # Build the packer command to invoke
    packer = "#{@sub_shell} packer #{command}#{packer_args} #{PACKER_FILE_NAME}"

    # Enter project directory and invoke packer
    Dir.chdir(@project_path) do
      Rake::FileUtilsExt.sh packer
    end
  end

  # packer inspect
  def inspect()
    packer('inspect')
  end

  # packer validate
  def validate(extra_args)
    packer('validate', *extra_args)
  end

  # packer build
  def build(extra_args)
    packer('build', *extra_args)
  end

  def post_processor_vagrant_box(target_name)
    raise ArgumentError, '[ERROR] Argument target_name must be a string', post_process unless target_name.is_a? String

    Dir.chdir File.join(@project_path, PACKER_OUTPUT_DIR) do
      metadata_filename = 'metadata.json'
      vagrant_filename = 'Vagrantfile'

      source_ovf_filename = "#{@project_name}.ovf"
      source_disk_filename = "#{@project_name}-disk001.vmdk"
      source_metadata_path = File.expand_path File.join('..', metadata_filename)
      source_vagrantfile_path = File.expand_path File.join('..', vagrant_filename)
      
      target_ovf_filename = 'box.ovf'
      target_disk_filename = 'box-disk1.vmdk'
      target_metadata_filename = metadata_filename
      target_vagrant_filename = vagrant_filename
      target_box_filename = "#{target_name}.box"
      
      # OVF file
      target_ovf_content = File
        .read(source_ovf_filename)
        .gsub(/#{source_disk_filename}/, target_disk_filename)
        .gsub(/#{@project_name}/, target_name)
      File.write target_ovf_filename, target_ovf_content, :open_args => ['wb']

      # VMDK file
      FileUtils.mv source_disk_filename, target_disk_filename

      # Metadata file
      FileUtils.cp source_metadata_path, target_metadata_filename

      # Vagrantfile
      mac_address = VBoxManage.new(@project_name).vm_info_hash['macaddress1']
      target_vagrantfile_content = File.read(source_vagrantfile_path).gsub(/@BASE_MAC@/, mac_address)
      File.write target_vagrant_filename, target_vagrantfile_content, :open_args => ['wb']

      # Create .box file for Vagrant
      system 'tar', '-cvzf', target_box_filename, target_ovf_filename, target_disk_filename, target_vagrant_filename, target_metadata_filename
    end
  end
end
