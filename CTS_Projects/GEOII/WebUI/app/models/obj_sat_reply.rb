#*********************************************************************************
  #File name    : object_sat_reply.rb

  #Author       : Cognizant Technology Solutions

  #Description  : This model is used to connect to the request/reply database. This 
  #               uses the rr_obj_sat_replies table.

  #Project Name : iVIU - WebUI Project

  #Copyright    : Safetran Systems Corporation, U.S.A. 
  #                   Research and Development

#*********************************************************************************
class ObjSatReply < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_geo_obj_sat_replies"
  set_primary_key "reply_id" 
  belongs_to :object_name
end
