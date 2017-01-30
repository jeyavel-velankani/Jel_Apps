####################################################################
# Company: Siemens 
# Author: Vijay Anand G
# File: AtcsSinValue.rb
# Description: This model is used to set the database connection and primary key.
####################################################################
class AtcsSinValue < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_geo_vital_prop_values"
  set_primary_key 'id'
#  belongs_to "atcs_sin", :foreign_key => "reply_id"
  #has_one :atcs_sin  
end
