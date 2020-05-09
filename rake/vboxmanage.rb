require_relative 'utils.rb'

class VBoxManage
  def initialize(vm_name)
    Utils.mandatory_argument(vm_name, 'vm_name')
    @vm_name = vm_name
  end

  def vm_info_hash
    vbm_output = %x(VBoxManage showvminfo #{@vm_name} --machinereadable).encode universal_newline: true
    vminfo_array = []
    vbm_output.each_line.map do |line|
      # We don't know how to handle multi-line values yet - skip them.
      if line.scan(/(?=\")/).count % 2 == 1
        next
      end
      key, value = line.chomp.split '=', 2
      if key.nil? == false && value.nil? == false
        vminfo_array.push key.gsub(/"/, ''), value.gsub(/"/, '')
      end
    end
    Hash[*vminfo_array]
  end

  def modify_vm(*args)
    system 'VBoxManage', 'modifyvm', @vm_name, *args
  end

  def snapshot(*args)
    system 'VBoxManage', 'snapshot', @vm_name, *args
  end

  def snapshot_restore(snapshot_name)
    snapshot 'restore', snapshot_name
  end

  def regenerate_mac_address(network_adapter_id)
    raise '[ERROR] network_adapter_id must be an integer' unless network_adapter_id.is_a? Integer
    modify_vm "--macaddress#{network_adapter_id}", 'auto'
  end
end
