class CdlTextMessage < ActiveRecord::Base
  
  establish_connection :real_time_status_db
  set_table_name "CDL_TextMessages"
  
  def locked?
    lock_flag == 1 ? "Yes" : "No"    
  end
end