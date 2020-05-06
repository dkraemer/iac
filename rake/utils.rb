# Copyright 2020 Daniel Kraemer <dkraemer@dkross.org>. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

class Utils
  def self.mandatory_argument(arg, arg_name)
    return unless arg.nil?
      puts "Missing mandatory argument: #{arg_name}"
    exit 1
  end
end
