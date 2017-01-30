class VerifyDataIviuRequest < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_verify_data_iviu_requests"
  set_primary_key :id
end