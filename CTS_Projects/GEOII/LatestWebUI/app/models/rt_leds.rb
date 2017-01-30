class RtLedsInformation < ActiveRecord::Base
  set_table_name "LED_Status"
  establish_connection :real_time_status_db
  set_primary_key :chnnel_id



 
end