class VerifyScreenIviuRequest < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_verify_screen_iviu_requests"
  set_primary_key :request_id
  
  def self.initiate_verify_request(atcs_address, number_of_parameters)
    screen_iviu_request = VerifyScreenIviuRequest.new
    screen_iviu_request.request_state = ZERO
    screen_iviu_request.atcs_address = (atcs_address + '.02')
    screen_iviu_request.command = ZERO
    screen_iviu_request.mcf_type = ZERO
    screen_iviu_request.number_of_parameters = number_of_parameters #@page.page_parameter.size
    screen_iviu_request.save
    return screen_iviu_request
  end
  
end