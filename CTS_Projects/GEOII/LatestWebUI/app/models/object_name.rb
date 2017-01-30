####################################################################
# Company: Siemens 
# Author: Vijay Anand G
# File: ObjectName.rb
# Description: This model is used to set the database connection,table name,primary key and relationship.
####################################################################
class ObjectName < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_geo_obj_requests"
  set_primary_key "request_id"
  has_many :obj_sat_replies, :foreign_key => "request_id"
end
