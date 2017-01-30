class RequestReplydb < ActiveRecord::Base
   establish_connection :request_reply_db
  set_table_name "rr_log_requests"
  set_primary_key 'request_id'
  #self_primary_key "request_id"
  # establish_connection(:adapter => "sqlite3", :database => "db/req_rep.db")


  def self.post_logrequest
   logreq = new
   logreq.log_type_id=11
   id = logreq.request_id
    logreq.save
   return id
  end

  def savevalues

  end

  def self.delete_requestid(id, type)
      RequestReplydb.delete_all(:request_id=>"#{id}", :request_state => "#{type}")
   end

   def self.delete_diagrequestid(id, type)
      RequestReplydb.delete_all(:request_id=>"#{id}", :request_state => "#{type}")
      redirect_to :controller =>'diagnostic_log', :action=>'index'
      flash[:notice]="sucess"
   end

end
