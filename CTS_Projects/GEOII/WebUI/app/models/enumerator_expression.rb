class EnumeratorExpression < ActiveRecord::Base
  set_table_name "enumerator_expression"
  establish_connection :mcf_db
end