#*********************************************************************************
  #File name    : object_update.rb

  #Author       : Cognizant Technology Solutions

  #Description  : This model is used to connect to the request/reply database. This 
  #               uses the rr_obj_updates table.

  #Project Name : iVIU - WebUI Project

  #Copyright    : Safetran Systems Corporation, U.S.A. 
  #                   Research and Development

#*********************************************************************************
class ObjUpdate < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_geo_obj_updates"
  set_primary_key "update_id"  
end
