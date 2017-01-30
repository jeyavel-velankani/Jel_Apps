class Uistate < ActiveRecord::Base
  set_table_name "rt_ui_states"
  set_primary_key 'name'
  establish_connection :real_time_db
  
  def self.vital_user_present
    find_by_name_and_value("local_user_present", 1)
  end
  
   def self.vital_user_present?(atcs_address)
    find_by_name_and_value_and_sin("local_user_present", 1, atcs_address)
  end
  
end
