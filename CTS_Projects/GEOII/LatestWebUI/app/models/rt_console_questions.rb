class RtConsoleQuestions < ActiveRecord::Base
  set_table_name "rt_console_questions"
  establish_connection :real_time_db
  set_primary_key "id"
end
