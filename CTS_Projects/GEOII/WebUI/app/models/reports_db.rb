class ReportsDb < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_report_requests"
  set_primary_key 'request_id'

  def self.delete_report(id, type)
      ReportsDb.delete_all(:request_id=>"#{id}")
   end
end
