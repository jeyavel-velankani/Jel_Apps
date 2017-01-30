class Georequestreplydb < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_geo_log_requests"
  set_primary_key 'request_id'
 
  def self.post_logrequest
   logreq = new
   @id = logreq.request_id
    logreq.save
   return @id
  end

  def savevalues

  end

  def self.delete_requestid(id, type)
      @type= type
      @id = id
      Georequestreplydb.delete_all(:request_id=>"#{@id}")
   end
   
end