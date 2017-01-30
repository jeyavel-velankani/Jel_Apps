class Gcfile < ActiveRecord::Base
  
  set_table_name "GCFile"
  establish_connection :site_ptc_db if OCE_MODE == 1
  set_primary_key "InstallationName"
end
