#*********************************************************************************
  #File name    : rr_geo_stats_card_info.rb

  #Author       : Cognizant Technology Solutions

  #Description  : This model is used to connect to the request/reply database. This 
  #               uses the rr_geo_stats_card_info table.

  #Project Name : iVIU - WebUI Project

  #Copyright    : Safetran Systems Corporation, U.S.A. 
  #                   Research and Development

#*********************************************************************************
class RrGeoStatsCardInfo < ActiveRecord::Base
  
  establish_connection :request_reply_db
  set_table_name "rr_geo_stats_card_info"
  
  belongs_to :rr_geo_stats_request

end
