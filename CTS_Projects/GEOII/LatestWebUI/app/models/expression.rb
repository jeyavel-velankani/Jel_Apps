class Expression < ActiveRecord::Base
  set_table_name "expressions"
  establish_connection :mcf_db
end