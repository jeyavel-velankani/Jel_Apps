class ParamEnumerator < ActiveRecord::Base
  set_table_name "enumerators"
  establish_connection :mcf_db
end