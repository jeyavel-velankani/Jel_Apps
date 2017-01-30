class ExpressionMap < ActiveRecord::Base
  set_table_name "expression_maps"
  establish_connection :mcf_db
end