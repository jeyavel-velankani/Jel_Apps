class EnumToValue < ActiveRecord::Base
  establish_connection :development
  set_table_name "Enum_To_Values"
  set_primary_key 'ID'
  belongs_to :enum_parameters
  
  def self.enum_valget(grp_id, grp_channel,enum_id)
    EnumToValue.find :all, :select=>'DISTINCT Param_ID', :joins=> "INNER JOIN Enum_Parameters", :conditions=>['Enum_Parameters.Group_ID = ? and Enum_Parameters.Group_Channel=? and Enum_To_Values.Value_ID=? and Enum_Parameters.ID= Enum_To_Values.Param_ID',grp_id,grp_channel,enum_id]
     
  end
end
