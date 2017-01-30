class RrGeoLogRequest < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_geo_log_requests"
end