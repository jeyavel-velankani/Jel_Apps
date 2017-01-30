class Iostatusvalue < ActiveRecord::Base
    establish_connection :request_reply_db
    set_table_name "rr_geo_io_status_values"  
    belongs_to "iostatusreply", :foreign_key => "reply_id"
end
