class RrSafeMode < ActiveRecord::Base
  
  establish_connection :request_reply_db
  set_table_name "rr_safe_mode"
  set_primary_key 'request_id'
  
end