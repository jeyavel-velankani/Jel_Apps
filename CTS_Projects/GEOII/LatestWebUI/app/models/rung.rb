class Rung < ActiveRecord::Base
  set_table_name "rungs"
  establish_connection :mcf_db
end