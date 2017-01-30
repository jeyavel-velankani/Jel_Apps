class Logreply < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_log_replies"
  set_primary_key 'reply_id'
end
