class EchelonStatistics < ActiveRecord::Base
  set_table_name "Echelon_Statistics"
  establish_connection :real_time_status_db
 
end
