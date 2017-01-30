class Units < ActiveRecord::Base
  set_table_name "unit_conversions"
  establish_connection :mcf_db
end