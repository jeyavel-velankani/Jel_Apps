class Cartridge < ActiveRecord::Base
  establish_connection :real_time_status_db
  set_table_name "Cartridges"  
end