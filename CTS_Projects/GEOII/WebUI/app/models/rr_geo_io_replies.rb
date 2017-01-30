class RrGeoIOReplies < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_geo_io_status_replies"
end