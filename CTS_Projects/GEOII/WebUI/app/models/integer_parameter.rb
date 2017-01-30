####################################################################
# Company: Siemens 
# Author: Kevin Ponce
# File: integer_parameter.rb
# Description: Builds, validates, updates and controlls all nv config integer
####################################################################

class IntegerParameter < ActiveRecord::Base
  establish_connection :development
  set_table_name "Integer_Parameters"
  set_primary_key "ID"
  belongs_to :int_type, :class_name => 'IntegerType', :foreign_key => "Type_ID"

####################################################################
# Function:      get
# Parameters:    group_ID & group_channel 
# Description:   gets all of the info to build integer parameters
####################################################################
  def self.get(group_ID, group_Channel)
    if group_Channel == '*'
      self.find(:all,
               :conditions=>['Integer_Parameters.Group_ID=? AND Integer_Parameters.DisplayOrder!= ?', group_ID, -1],
               :joins => ["join Integer_Types on Integer_Parameters.Type_ID = Integer_Types.ID"], 
               :select => "Integer_Parameters.*,Integer_Types.Min_Value,Integer_Types.Max_Value,Integer_Types.Units,Integer_Types.Increments,Integer_Types.Format_Mask",
               :order => 'Integer_Parameters.DisplayOrder')
    else
      self.find(:all,
               :conditions=>['Integer_Parameters.Group_Channel= ? AND Integer_Parameters.Group_ID=? AND Integer_Parameters.DisplayOrder!= ?', group_Channel, group_ID, -1],
               :joins => ["join Integer_Types on Integer_Parameters.Type_ID = Integer_Types.ID"], 
               :select => "Integer_Parameters.*,Integer_Types.Min_Value,Integer_Types.Max_Value,Integer_Types.Units,Integer_Types.Increments,Integer_Types.Format_Mask",
               :order => 'Integer_Parameters.DisplayOrder')
    end
  end

####################################################################
# Function:      validate
# Parameters:    element_ID & value 
# Description:   validates integer parameters
####################################################################
  def self.validate(element_ID, value)

    if (int_param = IntegerParameter.find_by_ID(element_ID))
      base = 10
      error = ''
      int_value = value
      int_type = int_param.int_type

      #gets the min and the max
      min = int_type.Min_Value
      max = int_type.Max_Value

      #set the message for standard numbers
      msg_max = max
      msg_min = min
      
      #checks if there is a mask

      if value && int_type.Format_Mask.match('H:') #The hexadecimal validation!
        base = 16
        #set the message for hex numbers
        msg_min = msg_min.to_s(16)
        msg_max = msg_max.to_s(16)

        unless value.to_s.match(/^-{0,1}[a-fA-f0-9]*?$/)
          error = "Should be in Hexadecimal format"
        end
      elsif value && int_type.Format_Mask.match('T:') #The Time validation!

      else
        #checks if it is a numbner
        unless  int_value && int_value.to_s.match(/^-{0,1}\d*\.{0,1}\d+$/)
          error = "Should be in the numeric Range of (#{msg_min} to #{msg_max})"
        end
      end   

      #checks if number is between the max and the min
      unless  int_value && (int_value.to_i(base) >= min.to_i && int_value.to_i(base) <= max.to_i)
        error = "Should be in the numeric Range of (#{msg_min} to #{msg_max})"
      end
      
      #if there is an error it recturns the erros info
      return error
    end
  end

####################################################################
# Function:      update
# Parameters:    element_ID & value 
# Description:   updates a integer parameters
####################################################################
  def self.update(element_ID,value)
    int_param = self.get_mask(element_ID)
   
    #parameter will only be updated if it is unlocked
    if !self.locked?(element_ID)

      if(int_param != nil && int_param[0] && int_param[0].Format_Mask.split(':') != nil && int_param[0].Format_Mask.split(':')[0] == 'H')
        #updates Hex
        if element_ID.to_i == 55
          # Savign 'Starting Comm ID'
          IntegerParameter.update_all "Value= #{Float(Array(value.to_i(16)).pack('N').unpack('I')[0]).to_s}", "ID= #{element_ID}"
        else
          IntegerParameter.update_all "Value= #{Float(Array(value.to_i(16)).pack('V').unpack('I')[0]).to_s}", "ID= #{element_ID}"
        end
      else
        #update Decimal
        IntegerParameter.update_all "Value= #{value}", "ID= #{element_ID}"
      end
    end
  end

####################################################################
# Function:      get_mask
# Parameters:    element_ID  
# Description:   get the element mask
####################################################################
  def self.get_mask(element_ID)
    self.find(:all,
               :conditions=>['Integer_Parameters.ID = ?', element_ID],
               :joins => ["join Integer_Types on Integer_Parameters.Type_ID = Integer_Types.ID"], 
               :select => "Integer_Types.Format_Mask",
               :order => 'Integer_Parameters.DisplayOrder')
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
# Description:   updates a integer parameters to default parameters
####################################################################
  def self.set_to_defaults(group_ID, group_Channel)
    update_all("Value= Default_Value", "Group_Channel= #{group_Channel} and Group_ID = #{group_ID}")
  end

####################################################################
# Function:      set_to_defaults
# Parameters:    group_ID 
# Description:   updates a integer parameters to default parameters
####################################################################
  def self.set_to_defaults_find_id(group_ID)
    update_all("Value= Default_Value", "Group_ID = #{group_ID}")
  end






  
  def self.Integer_group(gid, gch)
    self.find(:all,
               :conditions=>['Group_Channel= ? AND Group_ID=? AND DisplayOrder!= ?', gch, gid, -1],
               :order => 'DisplayOrder')
  end
  
  def self.update_io_assignment_parameters(parameters)
    parameter_keys = parameters.keys
    integers = find(parameter_keys, :select => "ID, Value")
    updated = false
    parameters.each_pair do |key, value|
      integer = integers.find{|integer| integer.ID.to_s == key }
      updated = true if integer.Value != value.to_i && integer.update_attribute("Value", value.to_i)
    end
    updated
  end
    
  
  def self.group_channel(sub_node)
    find_by_Value(sub_node, :select => "Group_Channel", :conditions => ["Group_ID = ? and Name like 'ATCS Subnode%'", 1007501]).try(:Group_Channel)
  end
  
  def self.integer_select_query(id)
    find(id, :select => "Value").try(:Value)
  end
  
  def self.integerparam_update_query(selected_value,id_val)
    IntegerParameter.update_all "Value =  '#{selected_value}'", "ID = '#{id_val}'"
  end
  
  def self.integer_defaultvalue_query(id)
    find(id, :select => "Default_Value").try(:Default_Value)
  end
  
  #To get the Units from Integer_Types
  def self.integer_select_units_query(id)
    queryvaluet = find_by_sql("select b.Units from Integer_Parameters a, Integer_Types b where a.Type_ID = b.ID and a.ID='#{id}'") 
    t1 = queryvaluet.to_s.split('Units'); 
    t1[1]
  end
  
  def self.integer_select_minValue_query(id)
    queryvaluet = find_by_sql("select b.Min_Value from Integer_Parameters a, Integer_Types b where a.Type_ID = b.ID and a.ID='#{id}'") 
    t1 = queryvaluet.to_s.split('Min_Value'); 
    t1[1]
  end
  
  def self.integer_select_maxValue_query(id)
    queryvaluet = find_by_sql("select b.Max_Value from Integer_Parameters a, Integer_Types b where a.Type_ID = b.ID and a.ID='#{id}'") 
    t1 = queryvaluet.to_s.split('Max_Value'); 
    t1[1]
  end
  

  
  def self.Integer_group2(gid, gch)
    self.find(:first, :select=>'Value',:conditions=>['Group_Channel= ? AND Group_ID=? AND Name=?', gch, gid, 'ATCS Subnode'])
  end
  def self.Integer_update_group(sel_id, e_id)
    IntegerParameter.update_all "Value='#{sel_id}'", "ID='#{e_id}'"
  end
  
  def self.integer_groupselect_query(id, gid, gch)
    IntegerParameter.find(:all,:select=>'Value',:conditions=>['Group_Channel= ? AND Group_ID=? AND ID=?',gch,gid,id])
  end
  
  def self.integer_groupdefault_query(id, gid, gch)
    IntegerParameter.find(:all,:select=>'Default_Value,Type_ID',:conditions=>['Group_Channel= ? AND Group_ID=? AND ID=?',gch,gid,id])
  end
  
  def self.protocolsub_group(gid,gch)
    IntegerParameter.find(:all, :select=>'ID,Name,Group_ID,Group_Channel,Value,isUCNProtected,Type_ID', :conditions=>['Group_ID=? AND Group_Channel=?',gid,gch])
  end
  
  def self.protocoldefaultsub_group(gid,gch)
    IntegerParameter.find(:all, :select=>'ID,Name,Default_Value,isUCNProtected,Type_ID', :conditions=>['Group_ID=? AND Group_Channel=?',gid,gch])
  end
  
  def self.protocolparameter_update_group(grp_id, grp_ch, value, id)
    IntegerParameter.update_all "Value='#{sel_id}'","ID='#{id}'"
  end

  def self.protocolparameter_update_group(value, id)
    error = nil 
    ip= IntegerParameter.find(:first,:select=>"Type_ID",:conditions=>["ID = ?",id])
    type_id = ip.Type_ID

    int_type = IntegerType.find(:first,:select=>"Min_Value,Max_Value",:conditions=>["ID = ?",type_id])
    min = int_type.Min_Value
    max = int_type.Max_Value

    if min.to_i <= value.to_i and value.to_i <= max.to_i
      IntegerParameter.update_all "Value='#{value}'","ID='#{id}'"
    else
      error = "Range is ("+min.to_s+"-"+max.to_s+")"
    end
    return error
  end
  
  def self.get_atcs_address
     # get ATCS address - 7.RRR.LLL.GGG.SSS(CPU2 subnode)
     atcs = self.find(:all, :conditions=> {:Group_Channel => 0, :Group_ID => 1}, :order => 'DisplayOrder ASC')
     atcs_railroad = atcs[0].Value.to_s
     atcs_line = atcs[1].Value.to_s
     atcs_group = atcs[2].Value.to_s
     atcs_subnode_cpu2 = atcs[4].Value.to_s
     address = "7." + ("%03d" % atcs_railroad) + "." + ("%03d" % atcs_line) + "." + ("%03d" % atcs_group) + "." + ("%02d" % atcs_subnode_cpu2)
     return address
  end

  def self.get_display_atcs_address
   #NOTE: THIS FUNCTION IS DEPENDENT ON DISPLAYORDER FOLLOWING 7.RRR.LLL.GGG.SSS
   #Otherwise, 4 database queries must be made. 
   address = ""
   atcs = self.find(:all, :conditions=> {:Group_Channel => 0, :Group_ID => 1}, :order => 'DisplayOrder ASC')
   if !atcs.blank?
     atcs_railroad = atcs[0].Value.to_s
     atcs_line = atcs[1].Value.to_s
     atcs_group = atcs[2].Value.to_s
     atcs_subnode_display = atcs[3].Value.to_s
     
     address = "7." + atcs_railroad + "." + atcs_line + "." + atcs_group + "." + atcs_subnode_display
   end
   return address
  end
  
  def self.get_cpu2_atcs_address
    # Create ATCS address in the form: 7.RRR.LLL.GGG.SS.DD

    # Railroad RRR   
    entry    = self.find(:all, :conditions=> {:Group_Channel => 0, :Group_ID => 1, :Name => 'ATCS - Railroad' } )
    railroad = "%.3d" % entry[0].Value
   
    # Line LLL
    entry = self.find(:all, :conditions=> {:Group_Channel => 0, :Group_ID => 1, :Name => 'ATCS - Line' } )
    line  = "%.3d" % entry[0].Value
   
    # Group GGG
    entry = self.find(:all, :conditions=> {:Group_Channel => 0, :Group_ID => 1, :Name => 'ATCS - Group' } )
    group = "%.3d" % entry[0].Value
   
    # CPU2+ Subnode SS
    entry        = self.find(:all, :conditions=> {:Group_Channel => 0, :Group_ID => 1, :Name => 'ATCS - CPU2+ Subnode' } )
    cpu2_subnode = "%.2d" % entry[0].Value

    # Display Subnode DD
    entry           = self.find(:all, :conditions=> {:Group_Channel => 0, :Group_ID => 1, :Name => 'ATCS - Display Subnode' } )
    display_subnode = "%.2d" % entry[0].Value

    atcs_address = "7." + railroad + "." + line + "." + group + "." + cpu2_subnode + "." + display_subnode

    return atcs_address
  end
  
    def self.get_sin_atcs_address
    # Create ATCS address in the form: 7.RRR.LLL.GGG.SS

    # Railroad RRR   
    entry    = self.find(:all, :conditions=> {:Group_Channel => 0, :Group_ID => 1, :Name => 'ATCS - Railroad' } )
    railroad = "%.3d" % entry[0].Value
   
    # Line LLL
    entry = self.find(:all, :conditions=> {:Group_Channel => 0, :Group_ID => 1, :Name => 'ATCS - Line' } )
    line  = "%.3d" % entry[0].Value
   
    # Group GGG
    entry = self.find(:all, :conditions=> {:Group_Channel => 0, :Group_ID => 1, :Name => 'ATCS - Group' } )
    group = "%.3d" % entry[0].Value
   
    # CPU2+ Subnode SS
    entry        = self.find(:all, :conditions=> {:Group_Channel => 0, :Group_ID => 1, :Name => 'ATCS - CPU2+ Subnode' } )
    cpu2_subnode = "%.2d" % entry[0].Value

    atcs_address = "7." + railroad + "." + line + "." + group + "." + cpu2_subnode

    return atcs_address
  end

  # get the first record matching group id and name
  def self.get_value(group_id , name)
    int_value = 0
    self.find(:first,:select => "Value", :conditions=>["Group_ID = ? and Name like ?", group_id, name]).try(:Value)
  end

end
