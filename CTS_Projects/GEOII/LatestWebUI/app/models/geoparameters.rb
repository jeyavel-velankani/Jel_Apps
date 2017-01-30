#*********************************************************************************
  #File name    : geo_parameters.rb

  #Author       : Cognizant Technology Solutions

  #Description  : This model is used to connect to the MCF database. This 
  #               uses the geo_parameters table.

  #Project Name : iVIU - WebUI Project

  #Copyright    : Safetran Systems Corporation, U.S.A. 
  #                   Research and Development

#*********************************************************************************
class Geoparameters < ActiveRecord::Base
  set_table_name "geo_parameters"
  set_inheritance_column :ruby_type
  establish_connection :mcf_db
end
