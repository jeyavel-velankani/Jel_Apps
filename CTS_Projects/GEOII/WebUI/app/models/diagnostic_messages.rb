class DiagnosticMessages < ActiveRecord::Base
  set_table_name "diagnostics"
  establish_connection :mcf_db
  set_primary_key :rowid
end
