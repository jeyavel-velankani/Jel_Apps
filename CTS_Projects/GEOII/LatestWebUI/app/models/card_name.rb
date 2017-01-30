####################################################################
# Company: Siemens 
# Author: Vijay Anand G
# File: object_name_controller.rb
# Description: This model is used to set the database connection,table name and primary key.
####################################################################
class CardName < ActiveRecord::Base
  set_table_name "rt_card_names"  
  set_primary_key 'card_index' 
  establish_connection :real_time_db
end
