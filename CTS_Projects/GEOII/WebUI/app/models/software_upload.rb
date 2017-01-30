class SoftwareUpload < ActiveRecord::Base
  
  establish_connection :request_reply_db
  set_table_name "rr_upload_file_requests"
  set_primary_key 'request_id'
  
  def self.upload_file(file_name , dir , content, overwrite=false)
    return false if file_name.blank? or ( !overwrite and File.exist?(dir + "/" + file_name))
    File.open("#{dir}/#{file_name}", "wb") { |f| f.write(content) }
  end  
  
  def self.delete_requestid(id, type)
    SoftwareUpload.delete_all(:request_id=>"#{id}", :request_state=>"#{type}")
  end
  
  def self.update_req_repid(id,state)
    SoftwareUpload.update_all "request_state =  '#{state}'", "request_id = '#{id}'"
  end
end