#require 'sqlite3'
class GeoCard < ActiveRecord::Base
  establish_connection :mcf_db
  set_table_name 'geo_cards'
  set_primary_key "card_index"
  cardslots = {"slot1" => 1, "slot2" => 2, "slot3" => 3, "slot4" => 4, "slot5" => 5, "slot6" => 6, "slot7" => 7, "slot8" => 8}
  set_inheritance_column :card_type
  
  def self.get_card_index_and_type(mcfcrc, cdf)
    GeoCard.find(:first, :select => "card_index, type as card_type", :conditions => ["mcfcrc= ? AND cdf like '#{cdf}%'", mcfcrc])
  end
  
  def self.getcardindex_type(mcfcrc,cdf)
    GeoCard.find(:all, :select => "card_index, type as card_type", :conditions => ["mcfcrc= ? AND cdf like '#{cdf}%'", mcfcrc])
  end
  
  def self.cardindex(mcfcrc,cdf)
    GeoCard.find(:all, :select => "card_index",:conditions => ["mcfcrc= ? AND cdf like '#{cdf}%'", mcfcrc])
  end
  def self.cardtype(mcfcrc,cdf)
    GeoCard.find(:all, :select => "type as card_type",:conditions => ["mcfcrc= ? AND cdf like '#{cdf}%'", mcfcrc])
  end
  
end