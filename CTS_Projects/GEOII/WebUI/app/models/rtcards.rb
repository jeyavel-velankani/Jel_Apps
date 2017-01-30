class Rtcards < ActiveRecord::Base
  set_table_name "rt_cards"
  establish_connection :real_time_db

  def self.getpci(mcfcrc, slotnumber, atcsaddr)
      Rtcards.find(:all, :select => "pci_ci", :conditions => ["mcfcrc= ? AND slot_number = ? AND sin = ?", mcfcrc, slotnumber, atcsaddr])
  end
  
end
