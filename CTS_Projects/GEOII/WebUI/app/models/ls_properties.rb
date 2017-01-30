class LsProperties < ActiveRecord::Base
  set_table_name "ls_properties"
  establish_connection :mcf_db
end
