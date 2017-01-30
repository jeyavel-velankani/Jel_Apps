class Mcf < ActiveRecord::Base
  set_table_name "mcfs"
  establish_connection :mcf_db
  
  def self.select_mcf_crc_value()
    Mcf.find(:all,:select=>"mcfcrc").map(&:mcfcrc)
  end
end