class SetPropIviuCard < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_set_prop_iviu_cards"
end