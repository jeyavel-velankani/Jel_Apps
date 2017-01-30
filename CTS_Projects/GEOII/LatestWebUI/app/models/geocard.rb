#*********************************************************************************
  #File name    : geocard.rb

  #Author       : Cognizant Technology Solutions

  #Description  : This model is used to connect to the mcf database. This 
  #               uses the geo_cards table.

  #Project Name : iVIU - WebUI Project

  #Copyright    : Safetran Systems Corporation, U.S.A. 
  #                   Research and Development

#*********************************************************************************
class Geocard < ActiveRecord::Base
  establish_connection :mcf_db
  set_table_name "geo_cards"
  set_inheritance_column :card_type
end
