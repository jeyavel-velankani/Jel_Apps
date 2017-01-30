class SetPropIviuParam < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_set_prop_iviu_params"
end