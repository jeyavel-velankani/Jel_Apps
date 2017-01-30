class RrSimpleRequest < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_simple_requests"
  set_primary_key 'request_id'

  def self.delete_req_repid(id,state)
      RrSimpleRequest.delete_all(:request_id=>"#{id}", :request_state => "#{state}")
  end

  def self.delete_request(id)
      RrSimpleRequest.delete_all(:request_id => id.to_i) rescue nil
  end


end