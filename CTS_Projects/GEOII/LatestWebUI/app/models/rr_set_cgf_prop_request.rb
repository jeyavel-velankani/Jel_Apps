class RrSetCgfPropRequest < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_set_cgf_property_requests"
end