####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: users.rb
# Description: Users login authentication table
####################################################################
class Users < ActiveRecord::Base
  establish_connection :oce_db
  set_table_name "users"
  set_primary_key "name"
end
