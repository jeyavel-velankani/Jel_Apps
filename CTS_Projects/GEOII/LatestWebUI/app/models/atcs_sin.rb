####################################################################
# Company: Siemens 
# Author: Vijay Anand G
# File: AtcsSin.rb
# Description: This model is used to set the database connection,table name,primary key and relationship.
####################################################################
class AtcsSin < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_geo_vital_prop"  
  set_primary_key 'request_id'
  
  has_many :atcs_sin_values, :class_name => 'AtcsSinValue', :foreign_key => "request_id", :dependent => :destroy
  
end
