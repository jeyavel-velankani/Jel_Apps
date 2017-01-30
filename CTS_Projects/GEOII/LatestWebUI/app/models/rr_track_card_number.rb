class RrTrackCardNumber < ActiveRecord::Base
    establish_connection :request_reply_db
    set_table_name "rr_track_card_number"
end
