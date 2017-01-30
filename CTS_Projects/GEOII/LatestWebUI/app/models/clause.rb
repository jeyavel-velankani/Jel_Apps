class Clause < ActiveRecord::Base
  set_table_name "when_clauses"
  establish_connection :mcf_db

  #named_scope :when_clause, lambda {|term_map, enum_long_name| {:conditions => {:mcfcrc => MCFCRC, :name => term_map, :value => enum_long_name}}}
  
  def self.when_clause(term_map, enum_long_name)
    first(:conditions => {:mcfcrc => Gwe.mcfcrc, :name => term_map, :value => enum_long_name})
  end
  
end