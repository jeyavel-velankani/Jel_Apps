class RrUnsolicitedEvent < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_unsolicited_events"
  set_primary_key 'request_id'
  
end