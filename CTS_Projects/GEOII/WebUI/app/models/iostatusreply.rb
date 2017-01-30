class Iostatusreply < ActiveRecord::Base
    establish_connection :request_reply_db
    set_table_name "rr_geo_io_status_replies"  
    set_primary_key 'reply_id'
    
    has_many :iostatusvalues, :foreign_key => "reply_id"
end
