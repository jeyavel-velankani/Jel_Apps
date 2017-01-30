class Enumeration < ActiveRecord::Base
  set_table_name "enumerations"
  establish_connection :mcf_db
end