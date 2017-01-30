class LogRequest < ActiveRecord::Base
   establish_connection :request_reply_db
  set_table_name "rr_log_requests"
  set_primary_key 'request_id' 
  
   def self.delete_requestid(id, type)
              LogRequest.delete_all(:request_id=>"#{id}", :log_type_id => "#{type}")
              redirect_to :controller =>'logreplies', :action=>'index'
              flash[:notice]="sucess"
    end
  
  
end
