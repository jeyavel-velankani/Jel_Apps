class RrLsSpecificRequest < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_ls_specific_request"
end
