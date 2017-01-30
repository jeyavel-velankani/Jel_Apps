#*********************************************************************************
  #File name    : geotimers.rb

  #Author       : Cognizant Technology Solutions

  #Description  : This model is used to connect to the mcf database. This 
  #               uses the geo_timers table.

  #Project Name : iVIU - WebUI Project

  #Copyright    : Safetran Systems Corporation, U.S.A. 
  #                   Research and Development

#*********************************************************************************

class Geotimers < ActiveRecord::Base
  set_table_name "geo_timers"  
  establish_connection :mcf_db
end
