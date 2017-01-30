class TermMap < ActiveRecord::Base
  set_table_name "term_maps"
  establish_connection :mcf_db
end