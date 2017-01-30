class Integertype < ActiveRecord::Base
  set_table_name "integertypes"
  establish_connection :mcf_db
end