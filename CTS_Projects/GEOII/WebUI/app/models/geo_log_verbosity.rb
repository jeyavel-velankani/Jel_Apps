#*********************************************************************************
  #File name    : geo_log_verbosity.rb

  #Author       : Cognizant Technology Solutions

  #Description  : This model is used to connect to the request/reply database. This 
  #               uses the rr_logverbo_requests table.

  #Project Name : iVIU - WebUI Project

  #Copyright    : Safetran Systems Corporation, U.S.A. 
  #                   Research and Development

#*********************************************************************************
class GeoLogVerbosity < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_log_verbo_requests"
  set_primary_key 'request_id'
end
