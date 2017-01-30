class RebootRequest < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_reboot_requests"
  set_primary_key "request_id"
end