module GenericHelper
  require 'rexml/document'
  include REXML
  
  #****************************************************************************************
  # String 	
  #****************************************************************************************
  
  #Description: method removes whiteshpace before and after a stirng
  #Exampe: trim(" this is a test ") returns "this is a test"
  def self.trim (trim_string)
    return trim_string.gsub(/^\s+|\s+$/,'')
  end
  
  #Description: method converts camel case to a stirng with spaces
  #Exampe: camelcase_to_spaced("ThisIsATest") returns "This Is A Test"
  def self.camelcase_to_spaced(word)
    return word.gsub(/([A-Z])/, " \\1").strip
  end
  
  ####################################################################
  # Function:      check_user_presence 
  # Parameters:    N/A
  # Retrun:        @user_presence
  # Renders:       N/A
  # Description:   Checks user presence returns true when there is user presence and false when there is not
  ####################################################################
  def self.check_user_presence
    if (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE)
      return true
    else
      return (Uistate.vital_user_present)? true : false
    end
  end
  ####################################################################
  # Function:      toolbar 
  # Parameters:    N/A
  # Retrun:        tool_bar
  # Renders:       N/A
  # Description:   builds the tool bar
  ####################################################################
  def self.toolbar(item_hash,unlock_class = nil)
    user_presence = @user_presence || check_user_presence
    tool_bar = '<div class="toolbar_wrapper">'
    
    item_hash.each_with_index { |(key,value),index|
        display_flag = true
        if ((key.to_s == 'unlock' || key.to_s == 'reset_vlp') && (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE))
          display_flag = false                    
        end

        type = value.split('=>')
        type = type[0]

        if type == 'text'
          value = value.split('=>')
          value = value[1]

          if  unlock_class == 'unlock_required'
            tool_bar += ' <div class="toolbar_button toolbar_button_text '+key+' '+((unlock_class != nil &&  (key == unlock_class && user_presence) || (key != unlock_class && !user_presence)) ? 'disabled' : '')+'"><img alt="'+key+'" src="/images/u187_normal.png"><span>'+value+'</span></div>'
          else
            tool_bar += ' <div class="toolbar_button toolbar_button_text '+key+' '+((unlock_class != nil &&  (key == unlock_class && user_presence)) ? 'disabled' : '')+'"><img alt="'+key+'" src="/images/u187_normal.png"><span>'+value+'</span></div>'
          end
        else
          if display_flag == true
            if  unlock_class == 'unlock_required'
              tool_bar += ' <div class="toolbar_button '+key+' '+((unlock_class != nil &&  (key == unlock_class && user_presence) || (key != unlock_class && !user_presence)) ? 'disabled' : '')+'"><img alt="'+key+'" src="/images/'+value+'"></div>'
            else
              tool_bar += ' <div class="toolbar_button '+key+' '+((unlock_class != nil &&  (key == unlock_class && user_presence)) ? 'disabled' : '')+'"><img alt="'+key+'" src="/images/'+value+'"></div>'
            end
          end
        end
    }
    tool_bar += '<div class="clear"></div></div>'
    return tool_bar
  end
  
  ####################################################################
  # Function:      open_ui_configuration 
  # Parameters:    None
  # Retrun:        config
  # Renders:       None
  # Description:   Open the UI Configuration file 
  ####################################################################
  def open_ui_configuration
      if (LOCAL_MACHINE_WEBUI == 1 || PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE)
        config = YAML.load_file("#{RAILS_ROOT}/config/ui_configuration.yml")  # For Local System
      else
        config = YAML.load_file("/usr/safetran/conf/ui_configuration.yml")    # For GEOII System
      end
      return config
  end
  
  def self.read_config_xml
    ocemode = 0
    oceadmin = 0
    version = "0.0.0"
    xml_path = RAILS_ROOT.to_s + "/config/oce_config.xml"
    if File.exists?(xml_path)
      xmlfile = File.new(xml_path)
      xmldoc = Document.new(xmlfile)
      xmlroot = xmldoc.root
      xmlroot.each_element do |elmt|
        if elmt.name.to_s == "mode"
          ocemode = elmt.text.to_i
        elsif elmt.name.to_s == "admin"
          oceadmin = elmt.text.to_i
        elsif elmt.name.to_s == "version"
          version = elmt.text.to_s
        end
      end
    end
    xmlroot = nil
    xmldoc = nil
    xmlfile = nil
    return ocemode, oceadmin, version
  end
  
  # PAC Comparison and PAC import functionality reference code
  def get_enum_params(db_path , group_id , group_chennal)
    enum_val = db_path.execute("select ID,Group_ID , Group_Channel ,Name, Selected_Value_ID , Default_Value_ID from Enum_Parameters where Group_ID=#{group_id} AND Group_Channel=#{group_chennal} AND DisplayOrder!= -1 order by DisplayOrder")
    enum_protocol_val = []
    protocal_group_ids = db_path.execute("Select distinct(ID) from Parameter_Groups where Parent_Group_ID=#{group_id} AND Group_Channel=#{group_chennal} order by ID")
    protocal_group_ids.each do |protocal_group_id|
      vals = []
      vals = db_path.execute("select ID,Group_ID , Group_Channel ,Name, Selected_Value_ID , Default_Value_ID from Enum_Parameters where Group_ID=#{protocal_group_id[0].to_i} AND Group_Channel=#{group_chennal} AND DisplayOrder!= -1 order by DisplayOrder")
      if !vals.blank?
        enum_protocol_val = enum_protocol_val + vals
      end  
    end
    return enum_val+enum_protocol_val
  end
  
  def get_int_params(db_path , group_id , group_chennal) 
    int_val = db_path.execute("select ID,Group_ID , Group_Channel ,Name, Value ,Default_Value from Integer_Parameters where Group_ID=#{group_id} AND Group_Channel=#{group_chennal} AND DisplayOrder!= -1 order by DisplayOrder")
    int_protocol_val = []
    protocal_group_ids = db_path.execute("Select distinct(ID) from Parameter_Groups where Parent_Group_ID=#{group_id} AND Group_Channel=#{group_chennal} order by ID")
    protocal_group_ids.each do |protocal_group_id|
      vals = []
      vals = db_path.execute("select ID,Group_ID , Group_Channel ,Name, Value ,Default_Value from Integer_Parameters where Group_ID=#{protocal_group_id[0].to_i} AND Group_Channel=#{group_chennal} AND DisplayOrder!= -1 order by DisplayOrder")
      if !vals.blank?
        int_protocol_val = int_protocol_val + vals
      end  
    end
    return int_val+int_protocol_val
  end
  
  
  def get_string_params(db_path , group_id , group_chennal)
    strings_val = db_path.execute("select ID , Group_ID  , Group_Channel , Name , String , Default_String from String_Parameters where Group_ID=#{group_id} AND Group_Channel=#{group_chennal} AND DisplayOrder!= -1 order by DisplayOrder")
    string_protocol_val = []
    protocal_group_ids = db_path.execute("Select distinct(ID) from Parameter_Groups where Parent_Group_ID=#{group_id} AND Group_Channel=#{group_chennal} order by ID")
    protocal_group_ids.each do |protocal_group_id|
      vals = []
      vals = db_path.execute("select ID , Group_ID  , Group_Channel , Name , String , Default_String from String_Parameters where Group_ID=#{protocal_group_id[0].to_i} AND Group_Channel=#{group_chennal} AND DisplayOrder!= -1 order by DisplayOrder")
      if !vals.blank?
        string_protocol_val = string_protocol_val + vals
      end  
    end
    return strings_val +string_protocol_val
  end
   
  def get_bytearray_params(db_path , group_id ,group_chennal)
    bytearray_val = db_path.execute("select ID, Group_ID , Group_Channel ,Name,Array_Value , Default_Value from ByteArray_Parameters where Group_ID=#{group_id} AND Group_Channel=#{group_chennal} AND DisplayOrder!= -1 order by DisplayOrder")
    bytearray_protocol_val = []
    protocal_group_ids = db_path.execute("Select distinct(ID) from Parameter_Groups where Parent_Group_ID=#{group_id} AND Group_Channel=#{group_chennal} order by ID")
    protocal_group_ids.each do |protocal_group_id|
      vals = []
      vals = db_path.execute("select ID, Group_ID , Group_Channel ,Name,Array_Value , Default_Value from ByteArray_Parameters where Group_ID=#{protocal_group_id[0].to_i} AND Group_Channel=#{group_chennal} AND DisplayOrder!= -1 order by DisplayOrder")
      if !vals.blank?
        bytearray_protocol_val = bytearray_protocol_val + vals
      end  
    end
    return bytearray_val + bytearray_protocol_val
  end
  
  def get_subgroup_param_records(db_path ,group_ID, group_chennal)
    sub_group_params = db_path.execute("Select ID, Enum_Param_ID from Subgroup_Parameters Where group_ID = #{group_ID} AND Group_Channel=#{group_chennal} AND Enum_Param_ID is not null and DisplayOrder != -1 order by DisplayOrder")
    sub_group_params_val = []
    if !sub_group_params.blank?
      sub_group_params.each do |sub_group_param|
        if !sub_group_param.blank? && !sub_group_param[1].blank?
          enum_sel_val_id = db_path.execute("Select Selected_Value_ID from Enum_Parameters where group_ID = #{group_ID} AND Group_Channel=#{group_chennal} AND ID =#{sub_group_param[1]}")
          if !enum_sel_val_id.blank?
            subgroup_id_vals = db_path.execute("Select Subgroup_ID from Subgroup_Values where ID=#{sub_group_param[0]} and Enum_Value_ID = #{enum_sel_val_id[0][0]}").collect{|v|v[0]}
            if !subgroup_id_vals.blank?
              subgroup_id = subgroup_id_vals[0]
              sub_group_params_val << {:enum_params => get_enum_params(db_path , subgroup_id, group_chennal) , :int_params => get_int_params(db_path ,  subgroup_id, group_chennal) , :strings_params => get_string_params(db_path ,  subgroup_id, group_chennal) , :bytearray_params => get_bytearray_params(db_path ,  subgroup_id, group_chennal)}
            end
          end
        end
      end
    end
    return sub_group_params_val
  end
  
  def compare_hash_values(table1_hash_values , table2_hash_values)
    result_array_val = []
    table1_hash_values.each do | table1_hash_value|
      check_condition = table2_hash_values.select {|table2_hash_value| ((table2_hash_value[0] == table1_hash_value[0]) && (table2_hash_value[1] == table1_hash_value[1]) && (table2_hash_value[2] == table1_hash_value[2]))}
      result_array_val << table1_hash_value if check_condition.blank?
    end
    return result_array_val
  end
  
end
