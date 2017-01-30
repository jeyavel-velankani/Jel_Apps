#*********************************************************************************
  #File name    : rr_geo_stats_card_info.rb

  #Author       : Cognizant Technology Solutions

  #Description  : This model is used to connect to the request/reply database. This 
  #               uses the rr_geo_stats_request table.

  #Project Name : iVIU - WebUI Project

  #Copyright    : Safetran Systems Corporation, U.S.A. 
  #                   Research and Development

#*********************************************************************************
class RrGeoStatsRequest < ActiveRecord::Base
  
  establish_connection :request_reply_db
  set_primary_key 'request_id'
  
  has_many :rr_geo_stats_card_infos, :foreign_key => "request_id", :class_name => "RrGeoStatsCardInfo"
  
  STAT_TYPE = { 0 => "card_statistics",
                1 => "vital_atcs_statistics",
                2 => "nonvital_atcs_statistics",
                3 => "hd_statistics",
                4 => "time_statistics",
                5 => "sio_statistics",
                6 => "dt_statistics",
                7 => "lan_statistics",
                8 => "vlp_statistics",
                9 => "ptc_statistics",
                100 => "invalid_statistics"}
  
end
