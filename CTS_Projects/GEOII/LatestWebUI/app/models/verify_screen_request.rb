class VerifyScreenRequest < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_verify_screen_requests"
  set_primary_key :request_id
  
  # method to initiate screen verification request
  def self.initiate_verify_request(atcs_address, page, screen_index = 0)
    request = create(:request_state => ZERO, :atcs_address => atcs_address, :screen_index => (page.page_index + 1 + screen_index), :no_of_hidden_params => ZERO)
    VerifyScreenParam.create_screen_verify_param_request(request.request_id, page.page_name, -1)
    request
  end
end