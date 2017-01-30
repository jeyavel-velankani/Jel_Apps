class LsLogicStates < ActiveRecord::Base
  set_table_name "ls_logic_state_properties"
  establish_connection :mcf_db
end
