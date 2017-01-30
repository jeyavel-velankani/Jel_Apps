class EnumValue < ActiveRecord::Base
  
  set_table_name "Enum_Values"
  set_primary_key 'ID'
  establish_connection :development
  has_and_belongs_to_many :enum_parameter
    
  def self.tempenum_dropdownbox_values
     EnumValue.find(:all,:select=>'ID, Name', :conditions => ['Description like "Cartridge Type"'], :group => "Value")
  end

  def self.connections_values
     EnumValue.find(:all, :select=>'ID, Name', :conditions => ['Description like "Cartridge Connection Type"'])
 end
 
   def self.units_of_measure      
     EnumValue.find(:first, :conditions => ["Enum_Parameters.Group_ID = 1 AND Enum_Parameters.Name Like 'Units of Measure'"],
                                           :joins => ["join Enum_Parameters on Enum_Parameters.Selected_Value_ID = Enum_Values.ID"],
                                           :select => "Enum_Values.Value")
  end

end
