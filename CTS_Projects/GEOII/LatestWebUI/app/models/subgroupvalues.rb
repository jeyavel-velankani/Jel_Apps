class Subgroupvalues < ActiveRecord::Base
  set_table_name "Subgroup_Values"
  set_primary_key 'ID'
  belongs_to :Subgroup_Parameters
  establish_connection :development
  
  def self.sgrp_valget(grp_id, grp_channel,enum_id)
    Subgroupvalues.find :all, :select=>'Subgroup_ID', :joins=> "INNER JOIN Subgroup_Parameters", :conditions=>['Subgroup_Values.ID=Subgroup_Parameters.ID and Subgroup_Parameters.Group_ID= ? and  Subgroup_Parameters.Group_Channel=? and Subgroup_Values.Enum_Value_ID =?',grp_id,grp_channel,enum_id]
 end
 
end
