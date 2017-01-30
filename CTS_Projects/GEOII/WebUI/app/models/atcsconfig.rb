class Atcsconfig < ActiveRecord::Base
  set_table_name "atcsconfig"
  set_primary_key "Subnode"
  establish_connection :site_ptc_db if OCE_MODE == 1
end
