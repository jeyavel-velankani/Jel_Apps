class RtConsist < ActiveRecord::Base
  set_table_name "rt_consist"
  establish_connection :real_time_db
  set_primary_key "consist_id"

  def self.getconsistid(mcfcrc, atcssin)
      RtConsist.find(:all, :select => "consist_id, mcfcrc", :conditions => ["sin = ? AND mcfcrc = ?",atcssin,mcfcrc])
  end
  
  def self.consist_id(atcs_address, mcfcrc)
    find(:last, :select => "consist_id, num_slots , cpu_card_id", :conditions => ["sin = ? AND mcfcrc = ?", atcs_address, mcfcrc], :order => "consist_id")
  end
end