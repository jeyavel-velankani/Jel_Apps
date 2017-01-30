class LogFilter < ActiveRecord::Base
  set_table_name "rr_log_filters"
  establish_connection :request_reply_db
  set_primary_key "filter_id"
  
  def self.filter_exists?
    self.count == 0 ? false : true
  end
  
  def logics
    [["AND", 0], ["OR", 1]]  
  end
  
  def operations 
    [["EQUALS", 0], ["CONTAINS", 1], ["STARTSWITH", 2]]
  end
  
  def filters
    [["EQUIPMENT", 0], ["SITENAME", 1], ["CARDSLOT", 2], ["TYPE", 3], ["TEXT", 4]]
  end
  
  def text
    ["CDL", "APPL"]
  end
  
end