class IsRequest < ActiveRecord::Base
  set_table_name "rr_is_requests"
  establish_connection :request_reply_db
  set_primary_key 'request_id'
  
#    def self.delete_requestid(id, type)
#      @type= type
#      @id = id
#      IsRequest.delete_all(:request_id=>"#{@id}", :request_state=>"#{@type}")
#  end
  
  #delete the record
  def self.delete_requestid(id)
      IsRequest.delete_all(:request_id=>"#{id}",:request_state => "2")
      redirect_to :controller =>'logreplies', :action=>'index'
      flash[:notice]="success"
  end
  
end
