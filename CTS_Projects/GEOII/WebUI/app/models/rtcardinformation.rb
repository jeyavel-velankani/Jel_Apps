class Rtcardinformation < ActiveRecord::Base
  set_table_name "rt_card_information"
  establish_connection :real_time_db
  
  def device_number_and_slot_kind(consist_id, card_type, card_index)
    Rtcardinformation.find(:first, :select=>'slot_atcs_devnumber, slave_kind', 
              :conditions=>['consist_id = ? AND card_type = ? AND card_index = ?',consist_id, card_type, card_index])
  end
  
  def self.card_select_query(slave_kind, card_used)
    Rtcardinformation.find(:all, :select=>'slot_atcs_devnumber,card_type,card_index', :conditions=>['slave_kind = ? AND card_used = ?',slave_kind,card_used])
  end
  
  def self.slotdevnumber(consistid, card_type, card_index)
    Rtcardinformation.find(:all, :select=>'slot_atcs_devnumber,slave_kind', :conditions=>['consist_id = ? AND card_type = ? AND card_index = ?',consistid,card_type,card_index])
  end
end

