class HiddenParam < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_hidden_params"  
  set_primary_key 'id'
end
