# Copyright 2020 Daniel Kraemer <dkraemer@dkross.org>. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

require 'tempfile'

class Utils
  def self.on_windows?
    RUBY_PLATFORM =~ /mswin|mingw|windows/
  end

  def self.mandatory_argument(arg, arg_name)
    return unless arg.nil?

    puts "[ERROR] Missing mandatory argument: #{arg_name}"
    exit 1
  end

  def self.assert_file_exist(filename)
    return if File.exist? filename

    puts "[ERROR] #{filename} does not exist!"
    exit 1
  end

  def self.assert_file_not_exist(filename)
    return unless File.exist? filename

    puts "[ERROR] #{filename} does already exist!"
    exit 1
  end

  # Replace a string in a text file (like: sed -e 's/old/new/g' -i filename)
  def self.replace_in_file filename, regexp, replacement
    mandatory_argument filename, 'filename'
    mandatory_argument regexp, 'regexp'
    mandatory_argument replacement, 'replacement'

    new_content = File.read(filename).gsub(regexp, replacement)

    # Write as binary file to prevent unwanted EOL conversion
    File.write filename, new_content, :open_args => ['wb']
  end
end
