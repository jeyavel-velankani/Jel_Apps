class Template < ActiveRecord::Base
  establish_connection :mcf_db
  set_primary_key :mtf_index
  
  def self.get_template(value)
    find(value, :conditions => {:mcfcrc => Gwe.mcfcrc}, :select => 'description, picture')
  end
  
end