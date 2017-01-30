#*********************************************************************************
  #File name    : vitalpropvalue.rb

  #Author       : Cognizant Technology Solutions

  #Description  : This model is used to connect to the request/reply database. This 
  #               uses the rr_geo_vital_prop_values table.

  #Project Name : iVIU - WebUI Project

  #Copyright    : Safetran Systems Corporation, U.S.A. 
  #                   Research and Development

#*********************************************************************************

class Vitalpropvalue < ActiveRecord::Base
  
  establish_connection :request_reply_db
  set_table_name "rr_geo_vital_prop_values"
  set_primary_key 'id'
  
end