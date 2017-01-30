class IsReply < ActiveRecord::Base
  set_table_name "rr_is_replies"
  establish_connection :request_reply_db
  
#      def self.delete_requestid(id, type)
#      @type= type
#      @id = id
#      IsReply.delete_all(:request_id=>"#{@id}", :request_state=>"#{@type}")
#      redirect_to :controller =>'tree_view', :action=>'index'
#      flash[:notice]="sucess"
#  end
  
  def self.delete_requestid(id)
      IsReply.delete_all(:request_id=>"#{id}")
      redirect_to :controller =>'tree_view', :action=>'index'
      flash[:notice]="sucess"
  end

  
end
