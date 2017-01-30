class RtStatus < ActiveRecord::Base
  
  establish_connection :real_time_status_db
  set_table_name "PTC_Objects"  
  
  has_many  :id,
            :class_name => "PtcObjectsType"
            
  
            
end