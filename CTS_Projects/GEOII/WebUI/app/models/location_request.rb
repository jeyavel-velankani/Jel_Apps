class LocationRequest < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_location_requests"
end