#*********************************************************************************
  #File name    : nonvitaltimer.rb

  #Author       : Cognizant Technology Solutions

  #Description  : This model is used to connect to the request/reply database. This 
  #               uses the rr_geo_nvital_cfg table.

  #Project Name : iVIU - WebUI Project

  #Copyright    : Safetran Systems Corporation, U.S.A. 
  #                   Research and Development

#*********************************************************************************
class Nonvitaltimer < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_geo_nvital_cfg"
  set_primary_key 'request_id'
  has_many :nv_config_props, :class_name => 'Nvconfigprop', :foreign_key => "request_id", :dependent => :destroy

end
