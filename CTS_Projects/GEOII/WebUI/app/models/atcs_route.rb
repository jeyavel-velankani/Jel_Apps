class AtcsRoute < ActiveRecord::Base
  
  establish_connection :real_time_status_db
  set_table_name "ATCS_Routes"
  
end