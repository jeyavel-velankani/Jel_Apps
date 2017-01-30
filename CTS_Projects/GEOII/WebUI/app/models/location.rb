#*********************************************************************************
  #File name    : location.rb

  #Author       : Cognizant Technology Solutions

  #Description  : This model is used to connect to the request/reply database. This 
  #               uses the rr_location_requests table.

  #Project Name : iVIU - WebUI Project

  #Copyright    : Safetran Systems Corporation, U.S.A. 
  #                   Research and Development

#*********************************************************************************
class Location < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_location_requests"  
  set_primary_key 'request_id'
  
  def self.create_location(atcs_addr)
    # make entry into the request/reply database
    set_location_rq = Location.new
    set_location_rq.request_state = 0
    set_location_rq.atcs_address = atcs_addr + ".01"
    set_location_rq.command = 0
    set_location_rq.save
    return set_location_rq
  end
  
end
