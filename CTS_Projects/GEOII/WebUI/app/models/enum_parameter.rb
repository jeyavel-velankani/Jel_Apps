####################################################################
# Company: Siemens 
# Author: Kevin Ponce
# File: enum_parameter.rb
# Description: Builds, validates, updates and controlls all nv config enum
####################################################################
class EnumParameter < ActiveRecord::Base
  if OCE_MODE == 1
    establish_connection :development
  end
  set_table_name "Enum_Parameters"
  set_primary_key 'ID'
  
  has_one :enum_value, :class_name => "EnumValue", :foreign_key => "ID", :primary_key => 'Selected_Value_ID'  
  #has_many :enum_value, :through => :enum_to_values 
  #has_and_belongs_to_many :enum_value

####################################################################
# Function:      high_availability_enabled_parameter
# Parameters:    None
# Description:   get high availability enabled parameters from the enum parameters
####################################################################
  
  def self.high_availability_enabled_parameter
      find_by_Group_ID(46, :select => "Name, ID, Selected_Value_ID, Default_Value_ID, Group_ID")
  end

####################################################################
# Function:      get
# Parameters:    group_ID  & group_Channel
# Description:   gets info to build all enum parameters except the options
####################################################################
  def self.get(group_ID, group_Channel)
    if group_Channel == '*'
      self.find(:all,:conditions=>['Group_ID=? AND DisplayOrder!= ?', group_ID, -1],:order => 'DisplayOrder')
    else
      self.find(:all,:conditions=>['Group_Channel= ? AND Group_ID=? AND DisplayOrder!= ?', group_Channel, group_ID, -1],:order => 'DisplayOrder')
    end
  end

####################################################################
# Function:      get_dropdownbox
# Parameters:    id
# Description:   gets the drop down options
####################################################################
  def self.get_dropdownbox(id)
     EnumValue.find_by_sql("select a.ID, a.Name, a.Value, b.Param_id from Enum_Values a, Enum_To_Values b, Enum_parameters c where b.Param_id = '#{id}' and c.ID='#{id}' and b.Value_ID = a.ID order by a.ID" )
  end

####################################################################
# Function:      validate
# Parameters:    element_Id  & value_ID
# Description:   validate enum parameters
####################################################################
  def self.validate(element_Id,value_ID)
    enum_resp = EnumValue.find_by_sql("select a.ID, a.Name, a.Value, b.Param_id from Enum_Values a, Enum_To_Values b, Enum_parameters c where b.Param_id = '#{element_Id}' and c.ID='#{element_Id}' and b.Value_ID = a.ID and a.ID = #{value_ID}" )
    
    if enum_resp == nil || enum_resp[0] == nil
      enum_resp = self.find(:first,:conditions=>['ID= ?', element_Id])
      return "Answer is invalid"
    end
  end

####################################################################
# Function:      update
# Parameters:    element_ID  & value_ID
# Description:   gets info to build all string parameters
####################################################################
  def self.update(element_ID,value_ID)
    if !self.locked?(element_ID)
      self.update_all "Selected_Value_ID =  #{value_ID}", "id = #{element_ID}"
    end
  end

####################################################################
# Function:      locked?
# Parameters:    element_ID  
# Description:   checks if the parameter is locked
####################################################################
  def self.locked?(element_ID)
    parameters = self.find_by_ID(element_ID)

    if parameters.isLocked == 0
      return false
    else 
      return true
    end
  end

####################################################################
# Function:      get_selected_text
# Parameters:    element_ID  
# Description:   gets the text displayed for element current answer
####################################################################
  def self.get_selected_text(element_ID)
    selected = EnumValue.find_by_sql("select a.ID, a.Name, a.Value from Enum_Values a, Enum_parameters c where c.ID='#{element_ID}' and a.ID = c.Selected_Value_ID")  

    return selected[0]['Name']
  end

####################################################################
# Function:      set_to_defaults
# Parameters:    group_ID & group_Channel 
# Description:   updates a enum parameters to default parameters
####################################################################
  def self.set_to_defaults(group_ID, group_Channel)
    update_all("Selected_Value_ID = Default_Value_ID", "Group_Channel= #{group_Channel} AND Group_ID = #{group_ID}")
  end

####################################################################
# Function:      set_to_defaults
# Parameters:    group_ID  
# Description:   updates a enum parameters to default parameters
####################################################################
  def self.set_to_defaults_find_id(group_ID)
    update_all("Selected_Value_ID = Default_Value_ID", "Group_ID = #{group_ID}")
  end
  
  def self.update_io_assignment_parameters(parameters)
    parameter_keys = parameters.keys
    enums = find(parameter_keys, :select => "ID, Selected_Value_ID")
    updated = false
    parameters.each_pair do |key, value|
      enum_param = enums.find{|enum| enum.ID.to_s == key }
      updated = true if enum_param.Selected_Value_ID.to_s != value.to_s && enum_param.update_attribute("Selected_Value_ID", value)
    end
    updated
  end 
 
  def self.enumparam_update_query(selected_value,id_val)
      EnumParameter.update_all "Selected_Value_ID =  #{selected_value}", "id = #{id_val}"
  end
  
  def self.enum_select_query(id)
        returnvalue = EnumParameter.find_by_sql("select Selected_Value_ID from Enum_Parameters where ID='#{id}'")
        return returnvalue[0].Selected_Value_ID.to_i
#      @id = id
#         sql = ActiveRecord::Base.connection();
#         @queryvaluet = sql.execute("select Selected_Value_ID from Enum_Parameters where ID='#{@id}'") 
#          @t1 = @queryvaluet[0]
#          @queryvalue = @t1['Selected_Value_ID']
#          return @queryvalue
    end
    
    def self.enum_select_query_value(id)
      EnumValue.find(:all,:select=>"Name" , :conditions=>["ID='#{id}'"]).map(&:Name)
    end
    
   def self.enum_dropdownbox_values(id)
     EnumValue.find_by_sql("select a.ID, a.Name, a.Value, b.Param_id from Enum_Values a, Enum_To_Values b, Enum_parameters c where b.Param_id = '#{id}' and c.ID='#{id}' and b.Value_ID = a.ID order by a.ID" )
   end
   
    def self.enum_find_group(grp_id)
      EnumParameter.find_by_sql("select selected_value_id from enum_parameters where Group_Id = '#{grp_id}'")
  end
  
   def self.update_portvalue(selected_value,id_val)
      EnumParameter.update_all "Selected_Value_ID =  '#{selected_value}'", "ID = '#{id_val}'"
  end
  
  
  def self.check(id)
    returnvalue = EnumParameter.find_by_sql("select distinct c.Name from Enum_Parameters a, Enum_To_Values b, Enum_Values c where a.ID=3 and a.ID = b.Param_ID and c.ID = a.Selected_Value_ID")
    return returnvalue
 end
  
  def self.paramid(id)
    returnvalue = EnumParameter.find_by_sql("select id from enum_parameters where id = (select ParameterId from enum_to_values where enum_to_values.ValueId = (select id from enum_values where id = '#{id}' ))")
    return returnvalue[0].id.to_i
  end
   
  def self.enum_defaultvalue_query(id)
          returnvalue = EnumParameter.find_by_sql("select Default_Value_ID from Enum_Parameters where ID='#{id}'")
          return returnvalue[0].Default_Value_ID.to_i
          
  end
  
  def self.enum_group(gid, gch)
    self.find(:all,
              :conditions=>['Group_Channel= ? AND Group_ID=? AND DisplayOrder!= ?', gch, gid, -1],
              :order => 'DisplayOrder')
  end
  
   def self.enum_update_group(sel_id, e_id)
     EnumParameter.update_all "Selected_Value_ID='#{sel_id}'", "ID='#{e_id}'"
   end
   
   def self.enum_updateverbo_group(sel_id, e_id)
     EnumParameter.update_all "Selected_Value_ID='#{sel_id}'", "Group_ID='#{e_id}'"
   end

   def self.get_enum_value(grp_id, name = nil)
     name_condition = name ? "AND Enum_Parameters.Name = '#{name}'" : ""

     catridges = EnumParameter.find(:all, :conditions => ["Enum_Parameters.Group_ID = ? #{name_condition}", grp_id],
                                           :joins => ["join Enum_Values on Enum_Parameters.Selected_Value_ID = Enum_Values.ID"],
                                           :select => "Enum_Values.Name as item, Enum_Parameters.*")
   end
   
   def self.get_enum_value_new(grp_id)
     catridges = EnumParameter.find(:all, :conditions => ["Enum_Parameters.Group_ID = ?", grp_id],
                                           :joins => ["join Enum_Values on Enum_Parameters.Selected_Value_ID = Enum_Values.ID"],
                                           :select => "Enum_Values.Name as item, Enum_Parameters.*")
   end
   
   
   def self.get_cartridge_io_points(slot_id, type_id)
     if sub_group = Subgroupparameters.find_by_Group_ID_and_Group_Channel(50, slot_id)
       if selected_value = EnumParameter.find_by_ID(sub_group.Enum_Param_ID)
         if enum_selected = Subgroupvalues.find_by_ID_and_Enum_Value_ID(sub_group.ID, type_id)
           if (int_param = IntegerParameter.find_by_Group_ID_and_Group_Channel(enum_selected.Subgroup_ID, slot_id))
              catridges_io_points = EnumParameter.find(:all, :conditions => ["Enum_Parameters.Group_ID = ?", (slot_id.to_i + 51)],
                                                    :joins => ["LEFT join Enum_Values on Enum_Parameters.Selected_Value_ID = Enum_Values.ID"],
                                                    :select => "Enum_Values.Name as item, Enum_Parameters.*",
                                                    :limit => int_param.Value)
              
           end
         end
       end
     end
     catridges_io_points || []
   end
   
   
   def self.get_cartridge_enum_values(slot_id, type_id)
     if sub_group = Subgroupparameters.find_by_Group_ID_and_Group_Channel(50, slot_id)
       if selected_value = EnumParameter.find_by_ID(sub_group.Enum_Param_ID)
         if enum_selected = Subgroupvalues.find_by_ID_and_Enum_Value_ID(sub_group.ID, type_id)
           if (array_param = ByteArrayParameter.find_by_Group_ID_and_Group_Channel(enum_selected.Subgroup_ID, slot_id))
              selected_value.Selected_Value_ID = type_id
              selected_value.save
             enum_options = EnumValue.find(:all, 
                                            :conditions=>{:ID => array_param.Array_Value.gsub('0','').split('D').map{|c| "D#{c}".to_i(16) if c.to_i > 0}.compact})
           end
         end
       end
     end
     enum_options || []
   end
   
   def self.save_comm_cartridge(slot_id, comm_id)
     catridge = EnumParameter.find_by_Group_ID_and_Group_Channel_and_Name(50, slot_id, 'Connection')
     catridge.Selected_Value_ID = comm_id
     catridge.save
   end 
   
   def self.get_mode_params(slot_id, mode_id)
     if sub_group = Subgroupparameters.find_by_Group_ID_and_Group_Channel((51 + slot_id.to_i), 0)
       if selected_value = EnumParameter.find_by_ID(sub_group.Enum_Param_ID)
         if sub_group_value = Subgroupvalues.find_by_ID_and_Enum_Value_ID(sub_group.ID, mode_id)
           group_parameters = [{:title =>  IntegerParameter.Integer_group(sub_group_value.Subgroup_ID, 0), :type=> Integer_Type},
                                 {:title =>  EnumParameter.enum_group(sub_group_value.Subgroup_ID, 0), :type =>Enum_Type },
                                 {:title =>  StringParameter.string_group(sub_group_value.Subgroup_ID, 0), :type =>String_Type }]
           
         end
       end
     end
     group_parameters || []
   end
   
   def self.logverbosity_enums
     catridges_type = EnumParameter.get_enum_value(42, "Type")
     catridges_connection = EnumParameter.get_enum_value(42, "Connection")
     catridges = catridges_type.map{|e| catridges_connection.map{|f| 
       ["Cartridge #{e.Group_Channel.to_i - 1} Diagnostic Log Verbosity"] if (f.Group_Channel == e.Group_Channel && e.item == 'None')}.compact}.flatten
       self.find(:all,
                 :conditions=>['Group_Channel= ? AND Group_ID=? AND DisplayOrder!= ? AND Name not in (?)', Consolidated_Verbosity_Group_Channel, Consolidated_Verbosity_Group, -1, catridges],
                 :order => 'DisplayOrder')
       
   end

   def self.logverbosity_enums_4000

     catridges = EnumParameter.find(:all, :conditions => ["Enum_Parameters.Group_ID = ? AND Enum_Values.Name like ?", 42,"%Info%"],
                                           :joins => ["join Enum_Values on Enum_Parameters.Selected_Value_ID = Enum_Values.ID"],
                                           :select => "Enum_Values.Name as item, Enum_Parameters.*")

   end
    
   
   def self.logverbosity_enums_new
     catridges = EnumParameter.get_enum_value_new(42)
   end
   
  def self.sear_set_defaults(g_ids = [])
    group_ids = self.get_parameter_group_ids(g_ids)
    if(!group_ids.blank?)
      EnumParameter.find_by_sql("update Enum_Parameters set Selected_Value_ID = Default_Value_ID where Group_ID in (#{group_ids.join(',')})")
      StringParameter.find_by_sql("update String_Parameters set String = Default_String where Group_ID in (#{group_ids.join(',')})")
      IntegerParameter.find_by_sql("update Integer_Parameters set Value = Default_Value where Group_ID in (#{group_ids.join(',')})")
    end
  end
  
  def self.sear_set_defaults_given_channel(g_ids = nil, channel_ids = [])
    return if g_ids.nil?
    group_ids = self.get_parameter_group_ids([g_ids])
    if(!group_ids.blank?)
      EnumParameter.find_by_sql("update Enum_Parameters set Selected_Value_ID = Default_Value_ID where Group_ID = (#{group_ids}) and Group_Channel in (#{channel_ids.join(',')})")
      StringParameter.find_by_sql("update String_Parameters set String = Default_String where Group_ID = (#{group_ids}) and Group_Channel in (#{channel_ids.join(',')})")
      IntegerParameter.find_by_sql("update Integer_Parameters set Value = Default_Value where Group_ID = (#{group_ids}) and Group_Channel in (#{channel_ids.join(',')})")
    end
  end
  
  def self.get_parameter_group_ids(g_ids = [])
    p_ids = []
    g_ids.each do |value|
      parameter_group = ParameterGroup.find(:all, :conditions => ["Parent_Group_ID = ?", value])
      if(parameter_group.blank?)
        p_ids += [value]
      else
        p_ids += [value]
        p_ids += parameter_group.collect{|x| x.ID}
      end
    end
    p_ids.uniq!
  end 


  def self.get_parameter_value_from_name(name)
    query = EnumParameter.find(:all, :conditions => ["Enum_Parameters.Name = ?",name],:joins => ["join Enum_Values on Enum_Parameters.Selected_Value_ID = Enum_Values.ID"],:select => "Enum_Values.Name as item, Enum_Parameters.*")
    
    return query
  end
end