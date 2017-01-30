class RrGeoOnline < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_geo_io_status"  
  set_primary_key 'request_id'
  
  def self.make_io_status_request(atcs_address, mcf_type, card_index, information_type)
    information_type = information_type.blank? ? 3 : information_type
    self.create(:request_state => 0, :atcs_address => atcs_address,
                :mcf_type => mcf_type, :information_type => information_type,
                :card_index => card_index)
  end
end
