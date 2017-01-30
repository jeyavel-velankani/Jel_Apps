class CardInfo < ActiveRecord::Base
  set_table_name "rt_card_information"  
  set_primary_key 'card_info_id'   
  establish_connection :real_time_db
end
