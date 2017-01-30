class ByteArrayParameter < ActiveRecord::Base
  set_table_name "ByteArray_Parameters"
  establish_connection :development

####################################################################
# Function:      get
# Parameters:    group_ID & group_channel 
# Description:   gets all of the info to build byte parameters
####################################################################
  def self.get(group_ID, group_Channel)
    if group_Channel == "*"
      self.find(:all,
               :conditions=>['Group_ID=? AND DisplayOrder!= ?', group_ID, -1],
               :select => "*",
               :order => 'DisplayOrder')
    else
      self.find(:all,
               :conditions=>['Group_Channel= ? AND Group_ID=? AND DisplayOrder!= ?', group_Channel, group_ID, -1],
               :select => "*",
               :order => 'DisplayOrder')
    end
  end

####################################################################
# Function:      validate
# Parameters:    element_ID & value 
# Description:   validates integer parameters
####################################################################
  def self.validate(element_ID, value)
    byte_param = ByteArrayParameter.find_by_ID(element_ID,:first)
    error = ''
    if byte_param != nil
      #if the value is longer that the byte size it is an error
      if (byte_param[:Size] * 2) < value.to_s.length
        error = "Should only have "+byte_param[:Size].to_s+" bytes"
      elsif value.to_s.length % 2 !=0
        error = "Needs both a lower and uppper nibble."
      elsif value.scan(/[0-9a-fA-F]/).length != value.length
        error = "Parameter should me hexadecimal."
      end
    end
    return error
  end

####################################################################
# Function:      update
# Parameters:    element_ID & value 
# Description:   updates a integer parameters
####################################################################
  def self.update(element_ID,value)
    #parameter will only be updated if it is unlocked
    if !self.locked?(element_ID)
      ByteArrayParameter.update_all "Array_Value= '"+value.to_s+"'", "ID= #{element_ID}"
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
# Function:      set_to_defaults
# Parameters:    group_ID & group_Channel 
# Description:   updates a byte array parameters to default parameters
####################################################################
  def self.set_to_defaults(group_ID, group_Channel)
    update_all("Array_Value = Default_Value", "Group_Channel= #{group_Channel} AND Group_ID = #{group_ID}")
  end

####################################################################
# Function:      set_to_defaults
# Parameters:    group_ID  
# Description:   updates a byte array parameters to default parameters
####################################################################
  def self.set_to_defaults_find_id(group_ID)
    update_all("Array_Value = Default_Value", "Group_ID = #{group_ID}")
  end


  # Existing method is not up to standards, so defining new byte_group method
  def self.byte_group(group_id, group_channel)
    find(:all, :conditions => ["Group_channel = ? and Group_ID = ?", group_channel, group_id], :order => "DisplayOrder")
  end
  
  def self.Bytearray_select_query(id)
    o = find(id)
    o['Array_Value']
  end
  
  def self.Byteparam_update_query(selected_value,id_val)
    ByteArrayParameter.update_all "Array_Value =  '#{selected_value}'", "ID = '#{id_val}'"
  end
  
  def self.Bytearray_defaultvalue_query(id)
    o = find(id)
    o['Default_Value']
  end
  
  def self.Byte_group(gid, gch)
    self.find(:all,
                :conditions=>['Group_Channel= ? AND Group_ID=?', gch, gid], 
                :order => 'DisplayOrder')
  end
  
  def self.Byte_update_group(sel_id, e_id)
    ByteArrayParameter.update_all "Array_Value='#{sel_id}'", "ID='#{e_id}'"
  end
  
  
  def self.Byte_groupselect_query(id, gid, gch)
    ByteArrayParameter.find(:all,:select=>'Array_Value',:conditions=>['Group_Channel= ? AND Group_ID=? AND ID=?',gch,gid,id])
  end
  
  def self.Byte_groupdefault_query(id, gid, gch)
    ByteArrayParameter.find(:all,:select=>'Default_Value',:conditions=>['Group_Channel= ? AND Group_ID=? AND ID=?',gch,gid,id])
  end
  
   # get the first record matching group id and name
  def self.get_value(group_id , name)
    self.find(:first, :conditions=>["Group_ID = ? and name like ?", group_id, name])
  end
end
