class RtSatName < ActiveRecord::Base
  set_table_name "rt_sat_names"
  set_primary_key 'id'
  establish_connection :real_time_db

end