class IoView < ActiveRecord::Base
  
  establish_connection :real_time_db
  
  set_table_name "rt_views"  
  set_primary_key 'sin'   
  
  # Checking for IO View for selected ATCS address
  def self.find_view(atcs_address, mcfcrc, view_type)
    find_by_sin(atcs_address, :conditions => {:mcfcrc => mcfcrc, :view_type => view_type}, :select => "status")
  end
  
end
