class Versions < ActiveRecord::Base
  set_table_name "Versions"
  set_primary_key 'Id'
  establish_connection :site_ptc_db unless OCE_MODE == 0
end
