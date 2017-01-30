class RrFileUploadslot < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_upload_file_to_slots"
  set_primary_key 'request_id'
  
  
    def self.delete_requestid(id)
      RrFileUploadslot.delete_all(:request_id=>"#{id}")
  end
  
  
end
