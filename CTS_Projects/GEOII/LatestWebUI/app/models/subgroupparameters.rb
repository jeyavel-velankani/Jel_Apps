####################################################################
# Company: Siemens 
# Author: Kevin Ponce
# File: subgroupparameters.rb
# Description: Builds nv config subgroups
####################################################################
class Subgroupparameters < ActiveRecord::Base
  set_table_name "Subgroup_Parameters"
  has_and_belongs_to_many :Subgroup_Values
  establish_connection :development
  
  def self.get_subgroup_params_find_id(group_ID)
    Subgroupparameters.find_by_sql("Select ID, Enum_Param_ID from Subgroup_Parameters Where group_ID = #{group_ID} and Enum_Param_ID is not null and DisplayOrder != -1 order by DisplayOrder")
  end

  def self.get_subgroup_params(group_ID, group_Channel)
    if group_Channel == "*"
      Subgroupparameters.find_by_sql("Select ID, Enum_Param_ID from Subgroup_Parameters Where group_ID = #{group_ID} and Enum_Param_ID is not null and DisplayOrder != -1 order by DisplayOrder")
    else
      Subgroupparameters.find_by_sql("Select ID, Enum_Param_ID from Subgroup_Parameters Where group_ID = #{group_ID} And Group_Channel = #{group_Channel} and Enum_Param_ID is not null and DisplayOrder != -1 order by DisplayOrder")
    end
  end
  
  def self.get_subgroup_id(id, group_ID, group_Channel, enum_param_ID, str_defalut)
    if (str_defalut == "default")
      if group_Channel == "*"
        enum_param_value_id = EnumParameter.find(:first, :select => "Default_Value_ID", :conditions => ["group_ID = #{group_ID} and ID = #{enum_param_ID}"]).try(:Default_Value_ID)
      else
        enum_param_value_id = EnumParameter.find(:first, :select => "Default_Value_ID", :conditions => ["group_ID = #{group_ID} And Group_Channel = #{group_Channel} and ID = #{enum_param_ID}"]).try(:Default_Value_ID)
      end
    else
      if group_Channel == "*"
        enum_param_value_id = EnumParameter.find(:first, :select => "Selected_Value_ID", :conditions => ["group_ID = #{group_ID} and ID = #{enum_param_ID}"]).try(:Selected_Value_ID)
      else
        enum_param_value_id = EnumParameter.find(:first, :select => "Selected_Value_ID", :conditions => ["group_ID = #{group_ID} And Group_Channel = #{group_Channel} and ID = #{enum_param_ID}"]).try(:Selected_Value_ID)
      end
    end
    if enum_param_value_id
      subgroup_id = Subgroupvalues.find(:first, :select => "Subgroup_ID", :conditions => ["ID = #{id} and Enum_Value_ID = #{enum_param_value_id}"]).try(:Subgroup_ID)
      return subgroup_id
    else
      return nil
    end
  end

  def self.get_subgroup_ids(id)    
    subgroup_id = Subgroupvalues.find(:all, :select => "Subgroup_ID", :conditions => ["ID = #{id}"])
    return subgroup_id
  end
end
