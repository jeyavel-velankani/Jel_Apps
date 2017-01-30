#*********************************************************************************
  #File name    : rr_geo_ptc_stats_requests.rb

  #Author       : Cognizant Technology Solutions

  #Description  : This model is used to connect to the request/reply database. This 
  #               uses the rr_geo_ptc_stats_requests table.

  #Project Name : iVIU - WebUI Project

  #Copyright    : Safetran Systems Corporation, U.S.A. 
  #                   Research and Development

#*********************************************************************************
class RrGeoPtcStats < ActiveRecord::Base
  
  establish_connection :request_reply_db
  set_table_name "rr_geo_ptc_stats_replies"
  set_primary_key 'request_id'

end

