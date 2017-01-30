class RrIsRequests < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_is_requests"
  set_primary_key "request_id"
  
  def self.ladder_logic_ls_no_request(term_state_lsno, atcs_address)
    is_request = create(:request_state => ZERO, :start_is_number => ZERO, :end_is_number => ZERO, 
             :command => Status, :atcs_address => atcs_address)
    request_id = is_request.request_id
    
    term_state_lsno.uniq.sort.each do |lsno|
      RrLsSpecificRequest.create(:request_id => request_id, :ls_number => lsno)
    end
          
    # term_map.each_value do |value|
      # RrLsSpecificRequest.create(:request_id => request_id, :ls_number => value[:lsno]) if value[:show]
    # end   
    request_id
  end
  
end
