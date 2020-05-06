# Copyright 2020 Daniel Kraemer <dkraemer@dkross.org>. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

require 'rake'
require_relative 'utils.rb'

class Project

  def initialize(project_path)
    Utils.mandatory_argument(project_path, 'project_path')

    # Use powershell on Windows because it accepts linux-style paths. (and cmd.exe sucks)
    @sub_shell = /mingw/ =~ RUBY_PLATFORM ? 'powershell' : nil

    # Full path to the given project
    @project_path = project_path

    # Project path must exist
    unless Dir.exist?(project_path)
      puts "[ERROR] Directory does not exist: '#{project_path}'"
      exit 1
    end
  end

  def git_clean_ignored()
    Dir.chdir(@project_path) do
      Rake::FileUtilsExt.sh 'git clean -dXf'
    end
  end

  attr_reader :project_path
end
