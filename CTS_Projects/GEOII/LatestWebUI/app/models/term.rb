class Term < ActiveRecord::Base
  set_table_name "terms"
  establish_connection :mcf_db
  
  #named_scope :get_terms, lambda{|params| {:conditions => {:name => params, :mcfcrc => MCFCRC}} }
  
  def self.get_terms(params, mcfcrc)
    all(:conditions => {:name => params, :mcfcrc => mcfcrc})
  end
  
end