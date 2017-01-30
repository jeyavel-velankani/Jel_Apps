class ExcludeParameter < ActiveRecord::Base
  set_table_name "exclude_parameters"
  establish_connection :mcf_db 
end