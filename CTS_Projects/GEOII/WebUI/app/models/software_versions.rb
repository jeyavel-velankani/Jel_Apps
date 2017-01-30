class SoftwareVersions < ActiveRecord::Base
  establish_connection :real_time_status_db
  set_primary_key 'id'
  set_table_name 'Software_Versions'  
end