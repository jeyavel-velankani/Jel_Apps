class Rrdownloadfile < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_download_requests"
  set_primary_key 'request_id' 
end
