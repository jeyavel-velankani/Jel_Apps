class SystemStatesLogicstate < ActiveRecord::Base
  
  set_table_name "logic_states"
  
  establish_connection :real_time_db
    
end
