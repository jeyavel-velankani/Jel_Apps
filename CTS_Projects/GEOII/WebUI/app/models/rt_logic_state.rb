class RtLogicState < ActiveRecord::Base
  establish_connection :real_time_db
  set_table_name "logic_states"  
  set_primary_key 'sin'
  
  def self.ls_number_values(atcs_address, req_id)
    all(:conditions => {:mcfcrc => Gwe.mcfcrc, :sin => atcs_address, :isno => req_id}, :select => 'value').map(&:value)
  end
  
end
