class Rrpacuploadrequest < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_pac_upload_request"
  set_primary_key 'request_id'
  
  def self.upload_file(file_name , dir , content, overwrite=false)
    return false if file_name.blank? or ( !overwrite and File.exist?(dir + "/" + file_name))
    File.open(dir + "/" + file_name, "wb") { |f| f.write(content) }
  end 
  
end
