class SetUcnRequest < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_set_ucn_requests"
  set_primary_key "request_id"
end