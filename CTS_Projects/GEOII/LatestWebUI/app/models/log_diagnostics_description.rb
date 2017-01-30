class LogDiagnosticsDescription < ActiveRecord::Base
  establish_connection :log_db
  set_table_name "log_daignostics"
end
