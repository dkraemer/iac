# Copyright 2020 Daniel Kraemer <dkraemer@dkross.org>. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

require_relative 'project.rb'
require_relative 'utils.rb'

class PackerProject < Project

  PACKER_FILE_NAME = 'packer.json'

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
end
