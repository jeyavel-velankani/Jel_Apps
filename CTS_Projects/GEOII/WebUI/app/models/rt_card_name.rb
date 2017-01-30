class RtCardName < ActiveRecord::Base
  set_table_name "rt_card_names"
  set_primary_key 'id'  
  establish_connection :real_time_db
  
  def self.card_names(atcs_address)
    all(:conditions => {:sin => atcs_address})
  end
end
