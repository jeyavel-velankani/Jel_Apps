class PtcObjectsType < ActiveRecord::Base
  
  establish_connection :real_time_status_db
  set_table_name "PTC_Object_Types"
  
end