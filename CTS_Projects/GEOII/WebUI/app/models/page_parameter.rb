class PageParameter < ActiveRecord::Base
  
  establish_connection :mcf_db
  set_table_name "page_parameter"
  set_primary_key "page_name"
  
  if PRODUCT_TYPE == 2
    
    #has_one :parameter, :primary_key => 'parameter_name'
    
    #has_many :parameter,
    #       :class_name => "Parameter",
    #       :finder_sql => 'select parameters.* from parameters, page_parameter where parameters.name = page_parameter.parameter_name and parameters.parameter_type = page_parameter.parameter_type and parameters.cardindex = page_parameter.card_index and parameters.mcfcrc= page_parameter.mcfcrc and parameters.name = \'#{parameter_name}\' limit 1'
    
    has_many :cards, :class_name => "Card", :foreign_key =>"mcfcrc", :primary_key => "mcfcrc"
  else
    has_many :parameter,
           :class_name => "Parameter",
           :finder_sql => 'select parameters.* from parameters where parameters.layout_index = #{layout_index} and parameters.cardindex = #{card_index} and parameters.parameter_type = #{parameter_type} and parameters.name = \'#{parameter_name}\' and parameters.mcfcrc = #{mcfcrc} limit 1'
    
  end
  
  
  
  
  def getEnumValue(val,enumTypeName)
    ParamEnumerator.find_by_value_and_enum_type_name_and_mcfcrc(val,enumTypeName,Gwe.mcfcrc).long_name
  end
end