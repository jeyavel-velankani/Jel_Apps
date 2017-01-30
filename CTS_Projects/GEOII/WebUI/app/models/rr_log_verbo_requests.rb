class RrLogVerboRequests < ActiveRecord::Base
  set_table_name "rr_log_verbo_requests"
   establish_connection :request_reply_db
end
