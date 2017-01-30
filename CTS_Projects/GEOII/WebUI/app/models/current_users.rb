class CurrentUsers < ActiveRecord::Base
  set_table_name "rt_current_users"
  establish_connection :real_time_db

  set_primary_key [:session_id]
end
