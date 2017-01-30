class VerifyScreenParam < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_verify_screen_params"
  set_primary_key :id
  
  def self.create_screen_verify_param_request(request_id, page_name, param_index)
    create(:request_id => request_id, :param_index => param_index, :parameter_name => page_name)
  end
  
end