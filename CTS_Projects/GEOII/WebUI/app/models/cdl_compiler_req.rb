class CDLCompilerReq < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_cdl_compiler_requests"
  set_primary_key 'request_id'
  #self_primary_key "request_id"
  # establish_connection(:adapter => "sqlite3", :database => "db/req_rep.db")
  def self.delete_request_id(id)
      CDLCompilerReq.delete_all(:request_id=>"#{id}")
  end

end