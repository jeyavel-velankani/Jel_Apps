class HighAvailabilityStatus < ActiveRecord::Base
  establish_connection :real_time_status_db
  set_table_name 'HA_LinkStatus'
  set_primary_key "link_number"
end
