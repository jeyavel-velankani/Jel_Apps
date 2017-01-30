#*********************************************************************************
#File name    : vitaltimer.rb

#Author       : Cognizant Technology Solutions

#Description  : This model is used to connect to the request/reply database. This 
#               uses the rr_geo_vital_prop table.

#Project Name : iVIU - WebUI Project

#Copyright    : Safetran Systems Corporation, U.S.A. 
#                   Research and Development

#*********************************************************************************
class Vitaltimer < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_geo_vital_prop"
  set_primary_key 'request_id'  
  
  has_many :atcs_sin_values, :class_name => 'Vitalpropvalue', :foreign_key => "request_id", :dependent => :destroy
  
end