#*********************************************************************************
  #File name    : geouseroptions.rb

  #Author       : Cognizant Technology Solutions

  #Description  : This model is used to connect to the mcf database. This 
  #               uses the geo_user_config_parameters table.

  #Project Name : iVIU - WebUI Project

  #Copyright    : Safetran Systems Corporation, U.S.A. 
  #                   Research and Development

#*********************************************************************************

class Geouseroptions < ActiveRecord::Base
  establish_connection :mcf_db
  set_table_name "geo_user_config_parameters" 
end
