class ReqRepLogReplies < ActiveRecord::Base
 establish_connection :request_reply_db
  set_table_name "rr_log_replies"
  set_primary_key 'request_id'

   def self.delete_req_repid(id)
      ReqRepLogReplies.delete_all(:request_id=>"#{id}")
      #redirect_to :controller =>'logreplies', :action=>'index'
   end

end
