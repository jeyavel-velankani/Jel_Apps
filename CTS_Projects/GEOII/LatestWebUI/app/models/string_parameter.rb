####################################################################
# Company: Siemens 
# Author: Kevin Ponce
# File: string_parameter.rb
# Description: Builds, validates, updates and controlls all nv config string
####################################################################
class StringParameter < ActiveRecord::Base
  set_table_name "String_Parameters"
  set_primary_key "ID"
  #if OCE_MODE == 1
    establish_connection :development
  #end
  belongs_to :string_type, :class_name => 'Stringtype', :foreign_key => "Type_ID"

####################################################################
# Function:      get
# Parameters:    group_ID  & group_Channel
# Description:   gets info to build all string parameters
####################################################################
  def self.get(group_ID, group_Channel, atcs_address_only = false, location_only = false)

    atcs_address_condition = ""
    atcs_address_condition = (atcs_address_only)? " AND String_Parameters.Name Like 'ATCS Address'" : ""
    atcs_address_condition = (atcs_address_condition.blank? && location_only)? " AND String_Parameters.Name Not Like 'ATCS Address'" : atcs_address_condition

    if group_Channel == "*"
      self.find(:all,
               :conditions=>["String_Parameters.Group_ID=? AND String_Parameters.DisplayOrder!= ?" + atcs_address_condition, group_ID, -1],
               :joins => ["join String_Types on String_Parameters.Type_ID = String_Types.ID"], 
               :select => "String_Parameters.*, String_Types.Min_Length,String_Types.Max_Length,String_Types.Format_Mask,String_Parameters.DisplayOrder",
               :order => 'String_Parameters.DisplayOrder')
    else
      self.find(:all,
               :conditions=>["String_Parameters.Group_Channel= ? AND String_Parameters.Group_ID=? AND String_Parameters.DisplayOrder!= ?" + atcs_address_condition, group_Channel, group_ID, -1],
               :joins => ["join String_Types on String_Parameters.Type_ID = String_Types.ID"], 
               :select => "String_Parameters.*, String_Types.Min_Length,String_Types.Max_Length,String_Types.Format_Mask,String_Parameters.DisplayOrder",
               :order => 'String_Parameters.DisplayOrder')
    end
  end

####################################################################
# Function:      validate
# Parameters:    element_ID & value
# Description:   validates string paramters
####################################################################
  def self.validate(element_ID, value)
    if @string_param = self.find_by_ID(element_ID) 
      error = ''

      string_type = @string_param.string_type
      min = string_type.Min_Length
      max = string_type.Max_Length
      mask = string_type.Format_Mask
      
      if error == '' && value && !(value.length >= min && value.length <= max)
        error =  "Should be of #{min} to #{max} Characters"
      end

      #checks if the min and the length are equal to 0. This will stop other error checking. 
      if(value.length == 0 && min == 0)
        return error
      end

      #checks mask type M and N
      if error == '' && ['M', 'N'].include?(mask[0].chr) && !string_type.Type_Name.match('IP Addr')
        error = self.m_n_mask_validate(value, mask)

      #checks ip but excludes mask type S (symbolic)
      elsif error == '' && string_type.Type_Name.match('IP Addr') && !['S'].include?(mask[0].chr) && !['P'].include?(mask[0].chr)
        error = self.ip_validate(value, string_type)

      #checks hex
      elsif error == '' && ['H'].include?(mask[0].chr)
        error = self.hex_validate(value)

      end
  
      return error
    end
  end

####################################################################
# Function:      m_n_mask_validate
# Parameters:    value & mask
# Description:   validates M & N mask types
####################################################################
  def self.m_n_mask_validate(value, mask)
    escape = false
    error = false

    x_mask = mask.gsub("M:",'').gsub("N:",'').split('.')
    value = value.split('.')
    
    #checks if both are the same formate
    if(x_mask.length == value.length)
      is_act = !(mask.gsub(/[^0-9]/, "").empty?)

      #indexes through each both arrays to compare them
      x_mask.each_with_index do |b, i|
        len = value[i].length
        blen = b.length

        if blen ==1 && b.to_i >= 1
          escape = !(value[i] == "#{b}")
          val = value[i]
        else
          val = is_act ? acts_convertor(blen, value[i]) : value[i].to_i
          escape = !(value[i].match(/^[0-9]*?$/) && (len <= blen))
        end

        #escapes only when there is an error
        if escape 
          error = true
          break
        end
      end
    else
      error = true
    end

    if error 
      return "Should be in the range ('#{mask.gsub("M:",'').gsub("N:",'').gsub('#', '0')}' - '#{mask.gsub("M:",'').gsub("N:",'').gsub('#', '9')}')"
    end
  end

####################################################################
# Function:      acts_convertor
# Parameters:    length & value
# Description:   prepends '0' to make address proper length
####################################################################
  def self.acts_convertor(len, value)
    while(len > value.length) do  
      value = "0#{value}"
    end
    value
  end

####################################################################
# Function:      ip_validate
# Parameters:    value & string_type
# Description:   validates ip to make sure it is the correct range
####################################################################
  def self.ip_validate(value, string_type)
    error = false
    value = value.split('.')

    if ret = value.length == 4
      #index though array and chceks if all values are numbers and with in the range of 0 and 255
      value.each do |b|
        
        error = (!b.match(/^[0-9]*?$/) || b.length > 3 || b.to_i < 0 || b.to_i >  255)

        if error
          break
        end
      end
    else
       error = true
    end
    
    if error
      return "Should be in the range of (0.0.0.0 - 255.255.255.255)"
    end
  end

####################################################################
# Function:      hex_validate
# Parameters:    value & string_type
# Description:   validates ip to make sure it is the correct range
####################################################################
  def self.hex_validate(value)
    error = false

    unless value.match(/^-{0,1}[a-fA-f0-9]*?$/)
      error = true
    end
        
    if error
      return "Should be in Hexadecimal format"
    end
  end

####################################################################
# Function:      update
# Parameters:    element_ID & value 
# Description:   updates string paramters
####################################################################
  def self.update(element_ID,value) 
    if !self.locked?(element_ID)   
      update_all "String =  '#{value}'", "Id = '#{element_ID}'"
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
# Function:      get_channel
# Parameters:    group_ID  
# Description:   gets all of the channels that belong to the group_ID
####################################################################  
  def self.get_channel(group_ID,page_number = nil,number_per_page = nil)
    if page_number != nil && number_per_page != nil
      self.paginate(:all,:select=>"Group_Channel,String,Default_String",:conditions=>["Group_ID = ? and Name = ? ",group_ID,"Name"],:order =>"Group_Channel", :page => page_number, :per_page => number_per_page)
    else
      self.find(:all,:select=>"Group_Channel,String,Default_String",:conditions=>["Group_ID = ? and Name = ? ",group_ID,"Name"],:order =>"Group_Channel")
    end
  end

####################################################################
# Function:      get_channel_count
# Parameters:    group_ID  
# Description:   gets count of the channels that belong to the group_ID
####################################################################  
  def self.get_channel_count(group_ID)
    count = self.find(:all,:select=>"count(*) as count",:conditions=>["Group_ID = ? and Name = ? ",group_ID,"Name"])

    if count
      count = count[0][:count]
    else 
      count = 0
    end

    return count
  end

####################################################################
# Function:      set_to_defaults
# Parameters:    group_ID & group_Channel 
# Description:   updates a string parameters to default parameters
####################################################################
  def self.set_to_defaults(group_ID, group_Channel)
    update_all("String = Default_String", "Group_ID = #{group_ID} and Group_Channel = #{group_Channel}")
  end

####################################################################
# Function:      set_to_defaults
# Parameters:    group_ID 
# Description:   updates a string parameters to default parameters
####################################################################
  def self.set_to_defaults_find_id(group_ID)
    update_all("String = Default_String", "Group_ID = #{group_ID}")
  end

####################################################################
# Function:      get_io_assignment_digital_inputs_names
# Parameters:    group_ID,number,page_numnber
# Description:   get data for io assigments table
####################################################################
  def self.get_io_assignment_digital_inputs_names(group_ID,page_numnber,number)
    self.find_by_sql("Select * from String_Parameters where String_Parameters.Name = 'Name' and Group_ID IN (select Subgroup_Values.Subgroup_ID from Enum_Parameters inner join Subgroup_Values on Enum_Parameters.Selected_value_id = Subgroup_Values.Enum_Value_ID where Enum_Parameters.Group_ID = #{group_ID} and Enum_Parameters.Name = 'Algorithm' order by Enum_Parameters.Group_Channel) limit #{number} offset #{number*page_numnber};")
  end

####################################################################
# Function:      get_count_io_assignment_digital_inputs_names
# Parameters:    group_ID
# Description:   get number of rows for io assigments table
####################################################################
  def self.get_count_io_assignment_digital_inputs_names(group_ID)
    self.find_by_sql("Select count(DISTINCT  Group_Channel) as count from String_Parameters where String_Parameters.Name = 'Name' and Group_ID IN (select Subgroup_Values.Subgroup_ID from Enum_Parameters inner join Subgroup_Values on Enum_Parameters.Selected_value_id = Subgroup_Values.Enum_Value_ID where Enum_Parameters.Group_ID = #{group_ID} and Enum_Parameters.Name = 'Algorithm' order by Enum_Parameters.Group_Channel);")
  end

####################################################################
# Function:      get_io_assignment_names
# Parameters:    group_ID,number,page_numnber
# Description:   get data for io assigments table
####################################################################
  def self.get_io_assignment_names(group_ID,page_numnber,number)
    self.find_by_sql("Select * from String_parameters where group_ID = #{group_ID} and Name = 'Name' limit #{number} offset #{number*page_numnber};")
  end

####################################################################
# Function:      get_count_io_assignment_names
# Parameters:    group_ID
# Description:   get number of rows for io assigments table
####################################################################
  def self.get_count_io_assignment_names(group_ID)
    self.find_by_sql("Select * from String_parameters where group_ID = #{group_ID} and Name = 'Name';")
  end  

  def self.update_io_assignment_parameters(parameters)
    parameter_keys = parameters.keys
    strings = find(parameter_keys, :select => "ID, String")
    updated = false
    parameters.each_pair do |key, value|
      string_param = strings.find{|string| string.ID.to_s == key }
      updated = true if string_param.String != value && string_param.update_attribute("String", value)
    end
    updated
  end
    
  def self.string_select_query(id) 
    find(id, :select => "String as str").try(:str)
  end
  
  def self.stringparam_update_query(selected_value,id_val)    
    update_all "String =  '#{selected_value}'", "Id = '#{id_val}'"
  end
  
  def self.select_isucnprotected_query()
    find(:all,:conditions=>["isUCNProtected !='0'"]).map(&:String)
  end
  
  def self.Name_select_query(id)
    find(:all,:select=>"Name",:conditions=>['id=?',id]).map(&:Name)    
  end
  
  def self.string_defaultvalue_query(id)
    find(id, :select => "Default_String as Defstr").try(:Defstr)
  end
  
  def self.string_minlength_query(id)
    find_by_sql("select b.Min_Length from String_Parameters a, String_Types b where a.Type_ID = b.ID and a.ID='#{id}'").try(:Min_Length)
  end
  
  def self.string_maxlength_query(id)
    find_by_sql("select b.Max_Length from String_Parameters a, String_Types b where a.Type_ID = b.ID and a.ID='#{id}'").try(:Max_Length)
  end
  def self.string_ucn(id)
    find(id, :select => "isUCNProtected").try(:isUCNProtected)
  end
  
  def self.string_locked(id)
    find(:all,:select=>'isLocked', :conditions=>['ID = ? and isLocked != ?',id,0])
  end
  
  def self.selectgeoatcsaddress(id)
    @atcs_addr = StringParameter.find(:all, :select=>'String,ID', :conditions=>['Group_ID = ?',id])
  end
  
  def self.getatcsaddress(id)
    find(id, :select => "String as str").try(:str)   
  end
  
  def self.string_valget(grp_id, grp_channel)
    StringParameter.find(:all, :select=>'ID', :conditions=>['Group_ID = ? and Group_Channel=?',grp_id,grp_channel])
  end
  
  def self.string_group(gid, gch)
    #self.find(:all, :conditions=>['Group_Channel= ? AND Group_ID=? AND DisplayOrder!= ?', gch, gid, -1],
    #               :order => 'DisplayOrder')
    self.find(:all, :conditions=>['Group_Channel= ? AND Group_ID=? AND DisplayOrder!= ?', gch, gid,-1],
                    :order => 'DisplayOrder')
  end
  
  def self.string_update_group( sel_id, e_id )
    StringParameter.update_all "String='#{sel_id}'", "ID='#{e_id}'"  #, "Group_ID='#{@grp_id}'", "Group_Channel='#{@grp_channel}'"
  end
  
  def self.string_groupselect_query(id, gid, gch)
    find(:all,:select=>'String,Type_ID',:conditions=>['Group_Channel= ? AND Group_ID=? AND ID=?',gch,gid,id])
  end
  
  def self.string_groupdefault_query(id, gid, gch)
    find(:all,:select=>'Default_String,Type_ID',:conditions=>['Group_Channel= ? AND Group_ID=? AND ID=?',gch,gid,id])
  end
  
  def self.protocolsub_group(gid,gch)
    find(:all, :select=>'ID,Name,Group_ID,Group_Channel,String,isUCNProtected,Type_ID', :conditions=>['Group_ID=? AND Group_Channel=?',gid,gch])
  end
  
  def self.protocoldefaultsub_group(gid,gch)
    find(:all, :select=>'ID,Name,Default_String,isUCNProtected,Type_ID', :conditions=>['Group_ID=? AND Group_Channel=?',gid,gch])
  end
  
  def self.protocolparameter_update_group(grp_id, grp_ch, value, id)
    StringParameter.update_all "String='#{sel_id}'","ID='#{id}'"
  end

  def self.protocolparameter_update_group(value, id)
    @error = nil 
    sp= StringParameter.find(:first,:select=>"Type_ID",:conditions=>["ID = ?",id])
    type_id = sp.Type_ID

    string_type = Stringtype.find(:first,:select=>"Min_Length,Max_Length",:conditions=>["ID = ?",type_id])
    min = string_type.Min_Length
    max = string_type.Max_Length

    if min.to_i <= value.length and value.length <= max.to_i
      StringParameter.update_all "String='#{value}'","ID='#{id}'"
    else
      @error = "Range is ("+min.to_s+"-"+max.to_s+")"
    end
    return @error
  end
  
  def get_display_atcs_address
   #NOTE: THIS FUNCTION IS DEPENDENT ON DISPLAYORDER FOLLOWING 7.RRR.LLL.GGG.SSS
   #Otherwise, 4 database queries must be made. 
   
   atcs = self.find(:all, :conditions=> {:Group_Channel => 0, :Group_ID => 1}, :order => 'DisplayOrder ASC')
   atcs_railroad = atcs[0].Value.to_s
   atcs_line = atcs[1].Value.to_s
   atcs_group = atcs[2].Value.to_s
   atcs_subnode_display = atcs[3].Value.to_s
   
   address = "7." + atcs_railroad + "." + atcs_line + "." + atcs_group + "." + atcs_subnode_display
   return address
  end
  
  #This method is used in selecting particular ATCS address for module name.
  def self.selectgeomodule(id)
    mygroup = StringParameter.find(id).Group_Channel
    StringParameter.find(:first, :conditions=>["Group_Channel = ? and name = ?", mygroup, 'Name'])
  end
  
  # get the first record matching group id and name
  def self.get_value(group_id , name)
    self.find(:first, :conditions=>["Group_ID = ? and name like ?", group_id, name])
  end
  
  def self.get_string_value(group_id , name)
    str_value = ''
    strvalue = self.find(:first, :conditions =>["Group_ID = ? and Name like ?", group_id, name])
    str_value= strvalue.String unless strvalue.blank?
    return str_value
  end
  
  def self.update_value_by_name(name , value)
    update_all("String =  '#{value}'", "Group_ID =1 and name like '#{name}'")
  end  
end