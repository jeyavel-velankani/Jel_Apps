class RtConsole < ActiveRecord::Base
  set_table_name "rt_console"
  establish_connection :real_time_db
  set_primary_key "console_id"
end
