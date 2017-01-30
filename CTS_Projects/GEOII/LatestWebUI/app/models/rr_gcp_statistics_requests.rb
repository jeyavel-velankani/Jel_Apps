class RrGcpStatisticsRequests < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_gcp_statistics_requests"
  set_primary_key "request_id"
  
   def self.create_record(cmd , eventtext , cardindex)
      RrGcpStatisticsRequests.create(:atcs_address =>Gwe.atcs_address,:command=>cmd ,:card_index =>cardindex,:evt_log =>eventtext, :request_state =>0)
  end
end
