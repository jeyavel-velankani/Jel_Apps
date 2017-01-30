class ParameterGroup < ActiveRecord::Base
  
  set_table_name "Parameter_Groups"
  belongs_to :enum_parameter, :foreign_key => "GroupId"
  if OCE_MODE == 1
      establish_connection :development
  end

####################################################################
# Function:      get
# Parameters:    Group_ID & Group_Channel
# Description:   gets Parameter Group
####################################################################
  def self.get(group_ID, group_Channel)
    self.find(:first,:conditions=>['Parent_Group_ID = ? AND Group_Channel = ?',group_ID, group_Channel],:select => "*")
  end

####################################################################
# Function:      get_tabs
# Parameters:    ID  
# Description:   gets all of the tabs that belong to the ID
####################################################################  
  def self.get_tabs(id)
    self.find(:all,:select=>"ID,Group_Channel,Group_Name",:conditions=>["ID = ?",id],:order =>"Group_Channel")
  end








  # ====================
  # = @author = Rajesh =
  # + The following methods are to carry out the server side validations+
  # + Server side validations are done based on the Parameter's type and its validation information +
  # ====================
  
  def group_name
    string ||= StringParameter.find_by_Group_ID_and_Group_Channel(self.ID, self.Group_Channel)
    enum   ||= EnumParameter.find_by_Group_ID_and_Group_Channel_and_Name(self.ID, self.Group_Channel,'Type')
    if enum && string
      
      if string[:String] != "" && string[:String] != string[:Default_String]
        string[:String]
#      elsif enum[:Selected_Value_ID] != enum[:Default_Value_ID]
#        "#{EnumValue.find_by_ID(enum[:Selected_Value_ID]).Name} #{self.Group_Channel.to_i+1}" 
      elsif string[:String] == "" || string[:String] == string[:Default_String]
        string[:Default_String]
      end
    end
  end
  
  def self.mask_validator(value, mask)
    x_mask = mask.gsub("M:",'').gsub("N:",'').split('.')
    value = value.split('.')
    
    if ret = (x_mask.length == value.length)
      @set_value = ''
      is_act = !(mask.gsub(/[^0-9]/, "").empty?)
      x_mask.each_with_index do |b, i|
        len = value[i].length
        blen = b.length
        if blen ==1 && b.to_i >= 1
          ret = (value[i] == "#{b}")
          val = value[i]
        else
          val = is_act ? acts_convertor(blen, value[i]) : value[i].to_i
          ret = (value[i].match(/^[0-9]*?$/) && (len <= blen))
        end
        @set_value << "#{val}#{(g='.'if value.length != (i+1))}"
        break unless ret
      end
    end
    @errors << "'#{@string_param.Description}' not in valid format and should be in the range ('#{mask.gsub("M:",'').gsub("N:",'').gsub('#', '0')}' - '#{mask.gsub("M:",'').gsub("N:",'').gsub('#', '9')}')" unless ret
    ret
  end
  
  def self.ip_validator(value, string_type)
    value = value.split('.')
    if ret = value.length == 4
      value.each do |b|
        ret = b.match(/^[0-9]*?$/) && b.length <= 3 && (0..255).to_a.include?(b.to_i)
        break unless ret
      end
    end
    @errors << "'#{@string_param.Description}' is not a valid IP address and should be in the range of (0.0.0.0 - 255.255.255.255)" unless ret
    ret
  end
  
  def self.symbolic_validator(value, string_type)
    e = @errors.dup
    #ret = value.match(/[A-Za-z0-9].com$/) || value.match(/[A-Za-z0-9].COM$/)
    ret = value.match(/[A-Za-z0-9].[A-Za-z]/) || value.match(/[A-Za-z0-9].[A-Za-z]/)
    ret = ret || ip_validator(value, string_type) if string_type.Type_Name.match('IP Addr') && ['S'].include?(string_type.Format_Mask[0].chr)
    @errors =  (e << "'#{@string_param.Description}' should be in the range (0.0.0.0 - 255.255.255.255)") unless ret
    ret
  end
    
  def self.acts_convertor(len, val)
    while(len > val.length) do  
      val = "0#{val}"
    end
    val
  end
  
  def self.string_validator(rec_id, value)
    if @string_param = StringParameter.find_by_ID(rec_id) 
      string_type = @string_param.string_type
      min = string_type.Min_Length
      max = string_type.Max_Length
      mask = string_type.Format_Mask
      
      value = "#{value}" if min.to_i == 0

      unless ret = value && (value.length >= min && value.length <= max)
        @errors << "'#{@string_param.Description}' Should be of #{min} to #{max} Characters"
      end
      @set_value = value
      ret = ret && self.mask_validator(value, mask) if ['M', 'N'].include?(mask[0].chr) && !string_type.Type_Name.match('IP Addr')
      ret = ret && (value.length == 0 && min == 0 ? true: self.ip_validator(value, string_type))if ret && string_type.Type_Name.match('IP Addr') && !['S'].include?(mask[0].chr)
      ret = ret && self.symbolic_validator(value, string_type) if ret && ['S'].include?(mask[0].chr)
      ret
    end
  end
  
  def self.integer_validator(rec_id, value)
    if (@int_param = IntegerParameter.find_by_ID(rec_id))
      @int_value = value
      int_type = @int_param.int_type
      min = int_type.Min_Value
      max = int_type.Max_Value
      
      if value && int_type.Format_Mask.match('H:') #The hexadecimal validation!
        @int_value = value.hex.to_s
        txt = " In conversion to Hexadecimal"
        unless ret = value.match(/^-{0,1}[a-fA-f0-9]*?$/)
          @errors << "'#{@int_param.Description}' Should be in Hexadecimal format"
        end
      end
      
      unless ret = @int_value && @int_value.match(/^-{0,1}\d*\.{0,1}\d+$/) && (@int_value.to_i >= min && @int_value.to_i <= max)
        @errors << "'#{@int_param.Description}' Should be in the numeric Range of (#{min} to #{max})#{txt}"
      end
      ret
    end
  end
  
  def self.check_ucn(rec, old_value, new_value)
    ret = nil
    # Included OCE_MODE == 0 condition for OCE
    if OCE_MODE == 0
    if (old_value != new_value) && (rec.isUCNProtected == 1 || rec.isUCNProtected == 2)
      atcs_addr = StringParameter.string_select_query(ATCS_Address)
      ui_state = Uistate.find_by_name_and_value_and_sin("local_user_present", 1, atcs_addr) 
      if ui_state.nil?
        @errors << "Saving of UCN/PTC item Denied! Please try again"
      end
    end
    end
    !ret
  end
  
  def self.group_parameter_values_update(values, time_source_ntp = false)
      @errors = []
        # begin
      values.split(',').each_with_index do |r , i|
        param_values = r.split('_')
        rec_type = param_values[0]
        rec_id = param_values[1]
        value = r.split('=')[1]
        if rec_type == 'enum'
          if r.match("keypad_display")
            enum_param = EnumParameter.find_by_Name("Keypad/Display Password Enabled", :select => "ID, Default_Value_ID")
            if enum_param
              enum_value = EnumValue.find_by_ID(enum_param.Default_Value_ID)
              value = param_values.last.split("=").last
              enum_value.update_attributes({:Name => value, :Value => (value == "No" ? 0 : 1)})
            end
          else
            e_parameter = EnumParameter.find(:last, :conditions => ["ID = ?", rec_id])
            if(!time_source_ntp)
              EnumParameter.enum_update_group(value, rec_id) if e_parameter.Group_ID != 1010500
            else
              EnumParameter.enum_update_group(value, rec_id)
            end
          end
          
        elsif rec_type == 'string' && self.string_validator(rec_id, value) && self.check_ucn(@string_param, @string_param[:String], @set_value)
          @string_param[:String] = @set_value
          if(!time_source_ntp)
              @string_param.save if @string_param.Group_ID != 1010500
          else
              @string_param.save     
          end
          if (@string_param.Name == "ATCS Address")
            if OCE_MODE ==1
              gwesinvalue = Gwe.find(:all,:select=>"sin").map(&:sin)
              if (gwesinvalue != @string_param.String)
                RtCard.update_all("sin = '#{@set_value.to_s}'")
                RtConsist.update_all("sin = '#{@set_value.to_s}'")
                Gwe.update_all("sin = '#{@set_value.to_s}'")
                RtParameter.update_all("sin = '#{@set_value.to_s}'")
                RtSession.update_all("atcs_address = '#{@set_value.to_s+'.02'}'")
                Uistate.update_all("sin = '#{@set_value.to_s}'")
              end
            end
          end
        elsif rec_type == 'int' && self.integer_validator(rec_id, value) && self.check_ucn(@int_param, @int_param.Value, @int_value)
          @int_param.Value = @int_value
          if(!time_source_ntp)
              @int_param.save if @int_param.Group_ID != 1010500
          else
              @int_param.save   
          end
        elsif rec_type == "byte"
          ByteArrayParameter.Byte_update_group(value, rec_id)
        end
      end
      # rescue =>e
      #   @errors << "<b>Problem Saving Information!</b> <br/>Looks like DB is busy Please try after Some time.)"
      # end
      @errors.empty? ? nil : @errors
    end





#-------------------------------------------------------------------------------------------
#start new error message area
#-------------------------------------------------------------------------------------------

def self.new_check_ucn(rec, old_value, new_value,rec_id,type)
    ret = nil
    # Included OCE_MODE == 0 condition for OCE
    if OCE_MODE == 0
    if (old_value != new_value) && (rec.isUCNProtected == 1 || rec.isUCNProtected == 2)
      atcs_addr = StringParameter.string_select_query(ATCS_Address)
      ui_state = Uistate.find_by_name_and_value_and_sin("local_user_present", 1, atcs_addr) 
      if ui_state.nil?
        @errors << "#{type}_#{rec_id}=>Saving of UCN/PTC item Denied! Please try again"
      end
    end
    end
    !ret
end

  def self.new_mask_validator(value, mask,rec_id)
    x_mask = mask.gsub("M:",'').gsub("N:",'').split('.')
    value = value.split('.')
    
    if ret = (x_mask.length == value.length)
      @set_value = ''
      is_act = !(mask.gsub(/[^0-9]/, "").empty?)
      x_mask.each_with_index do |b, i|
        len = value[i].length
        blen = b.length
        if blen ==1 && b.to_i >= 1
          ret = (value[i] == "#{b}")
          val = value[i]
        else
          val = is_act ? acts_convertor(blen, value[i]) : value[i].to_i
          ret = (value[i].match(/^[0-9]*?$/) && (len <= blen))
        end
        @set_value << "#{val}#{(g='.'if value.length != (i+1))}"
        break unless ret
      end
    end
    @errors << "string_#{rec_id}=>Not in valid format and should be in the range ('#{mask.gsub("M:",'').gsub("N:",'').gsub('#', '0')}' - '#{mask.gsub("M:",'').gsub("N:",'').gsub('#', '9')}')" unless ret
    ret
  end

  def self.new_ip_validator(value, string_type,rec_id)
    value = value.split('.')
    if ret = value.length == 4
      value.each do |b|
        ret = b.match(/^[0-9]*?$/) && b.length <= 3 && (0..255).to_a.include?(b.to_i)
        break unless ret
      end
    end
    @errors << "string_#{rec_id}=>is not a valid IP address and should be in the range of (0.0.0.0 - 255.255.255.255)" unless ret
    ret
  end

  def self.new_symbolic_validator(value, string_type,rec_id)
    e = @errors.dup
    #ret = value.match(/[A-Za-z0-9].com$/) || value.match(/[A-Za-z0-9].COM$/)
    ret = value.match(/[A-Za-z0-9].[A-Za-z]/) || value.match(/[A-Za-z0-9].[A-Za-z]/)
    ret = ret || self.new_ip_validator(value, string_type,rec_id) if string_type.Type_Name.match('IP Addr') && ['S'].include?(string_type.Format_Mask[0].chr)
    @errors =  (e << "string_#{rec_id}=>should be in the range (0.0.0.0 - 255.255.255.255)") unless ret
    ret
  end

  def self.new_string_validator(rec_id, value)
    if @string_param = StringParameter.find_by_ID(rec_id) 
      string_type = @string_param.string_type
      min = string_type.Min_Length
      max = string_type.Max_Length
      mask = string_type.Format_Mask
      
      value = "#{value}" if min.to_i == 0

      unless ret = value && (value.length >= min && value.length <= max)
        @errors << "string_#{rec_id}=>Should be of #{min} to #{max} Characters"
      end
      @set_value = value
      ret = ret && self.new_mask_validator(value, mask,rec_id) if ['M', 'N'].include?(mask[0].chr) && !string_type.Type_Name.match('IP Addr')
      ret = ret && (value.length == 0 && min == 0 ? true: self.new_ip_validator(value, string_type,rec_id))if ret && string_type.Type_Name.match('IP Addr') && !['S'].include?(mask[0].chr)
      ret = ret && self.new_symbolic_validator(value, string_type,rec_id) if ret && ['S'].include?(mask[0].chr)
      ret
    end
  end

  def self.new_integer_validator(rec_id, value)
    if (@int_param = IntegerParameter.find_by_ID(rec_id))
      @int_value = value
      int_type = @int_param.int_type
      min = int_type.Min_Value
      max = int_type.Max_Value
      
      if value && int_type.Format_Mask.match('H:') #The hexadecimal validation!
        @int_value = value.hex.to_s
        txt = " In conversion to Hexadecimal"
        unless ret = value.match(/^-{0,1}[a-fA-f0-9]*?$/)
          @errors << "int_#{rec_id}=>Should be in Hexadecimal format"
        end
      end
      
      unless ret = @int_value && @int_value.match(/^-{0,1}\d*\.{0,1}\d+$/) && (@int_value.to_i >= min && @int_value.to_i <= max)
        @errors << "int_#{rec_id}=>Should be in the numeric Range of (#{min} to #{max})#{txt}"
      end
      ret
    end
  end
    #values = string_id_
    #authenticity_token=K6xrNEvc%2FB4tSSaHlf3IoJJVwiXN9cgVGRxChknL9mg%3D,
    #enum_87_DHCP2=170,enum_88_eSSR2=100,enum_89_Path2=60,enum_90_Protocol2=121,string_88_IP2=192.168.3.101,string_89_Network2=255.255.255.01,string_90_Default2=
    def self.new_group_parameter_values_update(values, time_source_ntp = false)
      @errors = []
        # begin
      values.split(',').each_with_index do |r , i|
        param_values = r.split('_')
        rec_type = param_values[0]
        rec_id = param_values[1]
        value = r.split('=')[1]
        if rec_type == 'enum'
          if r.match("keypad_display")
            enum_param = EnumParameter.find_by_Name("Keypad/Display Password Enabled", :select => "ID, Default_Value_ID")
            if enum_param
              enum_value = EnumValue.find_by_ID(enum_param.Default_Value_ID)
              value = param_values.last.split("=").last
              enum_value.update_attributes({:Name => value, :Value => (value == "No" ? 0 : 1)})
            end
          else
            e_parameter = EnumParameter.find(:last, :conditions => ["ID = ?", rec_id])
            if(!time_source_ntp)
              EnumParameter.enum_update_group(value, rec_id) if e_parameter.Group_ID != 1010500
            else
              EnumParameter.enum_update_group(value, rec_id)
            end
          end
          
        elsif rec_type == 'string' && self.new_string_validator(rec_id, value) && self.new_check_ucn(@string_param, @string_param[:String], @set_value,rec_id,"string")
          @string_param[:String] = @set_value
          if(!time_source_ntp)
              @string_param.save if @string_param.Group_ID != 1010500
          else
              @string_param.save     
          end
          if (@string_param.Name == "ATCS Address")
            if OCE_MODE ==1
              gwesinvalue = Gwe.find(:all,:select=>"sin").map(&:sin)
              if (gwesinvalue != @string_param.String)
                RtCard.update_all("sin = '#{@set_value.to_s}'")
                RtConsist.update_all("sin = '#{@set_value.to_s}'")
                Gwe.update_all("sin = '#{@set_value.to_s}'")
                RtParameter.update_all("sin = '#{@set_value.to_s}'")
                RtSession.update_all("atcs_address = '#{@set_value.to_s+'.02'}'")
                Uistate.update_all("sin = '#{@set_value.to_s}'")
              end
            end
          end
        elsif rec_type == 'int' && self.new_integer_validator(rec_id, value) && self.new_check_ucn(@int_param, @int_param.Value, @int_value,rec_id,"int")
          @int_param.Value = @int_value
          if(!time_source_ntp)
              @int_param.save if @int_param.Group_ID != 1010500
          else
              @int_param.save   
          end
        elsif rec_type == "byte"
          ByteArrayParameter.Byte_update_group(value, rec_id)
        end
      end
      # rescue =>e
      #   @errors << "<b>Problem Saving Information!</b> <br/>Looks like DB is busy Please try after Some time.)"
      # end
      @errors.empty? ? nil : @errors
    end


#-------------------------------------------------------------------------------------------
#end new error message area
#-------------------------------------------------------------------------------------------

  
    def self.all_catrigdes
      @all_catrigdes = ParameterGroup.find_all_by_ID(27)
    end
    
    def strings_for_catrigdes
      @strings_for_catrigdes ||= StringParameter.find_all_by_Group_ID(27)
    end
    
    def integers_for_catrigdes
      @integers_for_catrigdes ||= IntegerParameter.find_all_by_Group_ID(27)
    end
    
    def enum_for_catrigdes
      @enum_for_catrigdes ||= EnumParameter.find(:all, 
                                       :conditions => {:Group_Id => 50},
                                       :joins => ["LEFT join Enum_Values on Enum_Parameters.Selected_Value_ID = Enum_Values.ID"], 
                                       :select => "Enum_Values.Name as item, Enum_Parameters.ID as enum_id, Enum_Parameters.Group_Channel as Group_Channel")
    end
    
    def self.enum_value(group_ch_id, limit = :first)
      @enum_for_catrigdes = EnumParameter.find(limit, 
                                       :conditions => {:Group_Id => 50, :Group_Channel => group_ch_id},
                                       :joins => ["LEFT join Enum_Values on Enum_Parameters.Selected_Value_ID = Enum_Values.ID"], 
                                       :select => "Enum_Values.Name as item, Enum_Parameters.*")
       return @enum_for_catrigdes
    end
    
    
    # def strings_for_catrigdes
    #   @strings_for_catrigdes ||= StringParameter.find_all_by_Group_ID_and_Group_Channel(27, self.Group_Channel)
    # end
    # 
    # def integers_for_catrigdes
    #   @integers_for_catrigdes ||= IntegerParameter.find_all_by_Group_ID_and_Group_Channel(27, self.Group_Channel)
    # end
    # 
    # def enum_for_catrigdes
    #   @enum_for_catrigdes ||= EnumParameter.find_all_by_Group_ID_and_Group_Channel(50, self.Group_Channel)
    # end
    
    
    def mcf_crc_val
      @mcf_crc_val ||= fetch_value(integers_for_catrigdes)
    end
    
    def mcf_val
      @mcf_val ||=  fetch_value(strings_for_catrigdes)
    end
    
    def item_val
      @item_val ||= fetch_value(enum_for_catrigdes)
    end
    
    def fetch_value(data_type)
      data_type.find{|s| s.Group_Channel == self.Group_Channel} || {}
    end
    
  end