class RrIsReplies < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_is_replies"
end
