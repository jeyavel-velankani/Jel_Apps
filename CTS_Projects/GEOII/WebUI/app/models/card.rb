class Card < ActiveRecord::Base
  set_table_name "cards"
  establish_connection :mcf_db

  def self.card_name(crdind, crdtype)
    @temp = Card.find(:all, :select=>'crd_name', :conditions=>['card_index = ? AND crd_type = ?',crdind,crdtype])
  end
  
  def self.card_name(mcfcrc, card_index, card_type, layout_index=nil)
    find_by_mcfcrc(mcfcrc, :select => "crd_name", :conditions => {:card_index => card_index, :crd_type => card_type, :layout_index => layout_index}).try(:crd_name)
  end
  
end