class LogMaintenance < ActiveRecord::Base
    establish_connection :log_db
    set_table_name "log_maintenance"
end

