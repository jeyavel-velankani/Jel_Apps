class CdlStatus < ActiveRecord::Base
  
  establish_connection :real_time_status_db
  set_table_name "CDL_Status"
  
  class << self
    def is_running?
      status = find(:all)

      if status  && status[0] && status[0][:is_running] == 1	
      	return true
      else
      	logger.info "f"
      	return false
      end
    end
  end
  
end
