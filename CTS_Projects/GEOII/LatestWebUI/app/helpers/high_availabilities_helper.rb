####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: high_availabilities_helper.rb
# Description: Helper file to support the High Availability page 
####################################################################
module HighAvailabilitiesHelper
  ####################################################################
  # Function:      get_label
  # Parameters:    parameter , group_parameter
  # Retrun:        parameter.first.Name , units
  # Renders:       None
  # Description:   Design the lable name for high availability page parameters
  ####################################################################
  def get_label(parameter, group_parameter = nil)
    units = ""
    if (!group_parameter.blank?) && (group_parameter  == Integer_Type)
      units = IntegerType.find_by_ID(parameter.first.Type_ID).try(:Units)
      unless units.blank?
        units = "&nbsp;&nbsp;<small>(#{units})</small>"
      end
      return parameter.first.Name.strip + units
    else
      return parameter.first.Name.strip
    end
  end
  
  ####################################################################
  # Function:      get_field
  # Parameters:    parameter_type, parameter, value_type='selected_value'
  # Retrun:        Html
  # Renders:       None
  # Description:   Design the field & value for high availability page parameters
  ####################################################################
  def get_field(parameter_type, parameter, value_type='selected_value')
    if parameter != nil && parameter.isLocked != nil
      readonly_flag = parameter.isLocked == 1 ? true : false
    else
      readonly_flag = false
    end
    if readonly_flag
      readonly_class = "disabled_buttons"
      lock_img = image_tag("/images/green-lock.png", :alt => "locked", :style => "position: relative;top: 5px;left: 5px;")
    else
      readonly_class = ""
      lock_img = ''
    end
    case parameter_type
      when String_Type
      element_value = value_type == "default" ? parameter.Default_String : parameter.String
      ip_required = (parameter.Name == "IP Address")? "ip_required":"required"
      string_types = Stringtype.find_by_ID(parameter.Type_ID)
      if string_types
        if(parameter.Name.include?("Password"))
          return password_field("string", "#{parameter.ID}", :value => element_value, :class=>"contentCSPsel password_verify block_space #{ip_required} #{readonly_class}", :min => string_types.Min_Length, :max => string_types.Max_Length ,:maxlength => string_types.Max_Length, :readonly => readonly_flag) + ' ' + lock_img
        else
          return text_field("string", "#{parameter.ID}", :value => element_value, :class=>"contentCSPsel #{ip_required} #{readonly_class}", :min => string_types.Min_Length, :max => string_types.Max_Length, :readonly => readonly_flag) + ' ' + lock_img
        end
      else
        return text_field("string", "#{parameter.ID}", :value => element_value, :class=>"contentCSPsel #{ip_required} #{readonly_class}",:readonly => readonly_flag) + ' ' + lock_img    
      end
      when Integer_Type
      element_value = value_type == "default" ? parameter.Default_Value : parameter.Value
      integer_types = IntegerType.find_by_ID(parameter.Type_ID)
      if integer_types
        #check whether the fields are retrieved for ATCS RRR,LLL,GGG.identifiy using sin_field class   
        if( (parameter.Name.include?("ATCS - Railroad")) ||(parameter.Name.include?("ATCS - Line"))||(parameter.Name.include?("ATCS - Group"))||(parameter.Name.include?("ATCS - CPU2+ Subnode")))          
          return text_field("integer", "#{parameter.ID}", :value => element_value, :current_value => element_value, :class=>"contentCSPsel required integer_only sin_field #{readonly_class}", :sin_id => parameter.ID, :min => integer_types.Min_Value, :max => integer_types.Max_Value, :step => integer_types.Increments, :desc => parameter.Name,:readonly => readonly_flag) + ' ' + lock_img
        else
          return text_field("integer", "#{parameter.ID}", :value => element_value, :current_value => element_value, :class=>"contentCSPsel required integer_only #{readonly_class}", :min => integer_types.Min_Value, :max => integer_types.Max_Value, :step => integer_types.Increments, :desc => parameter.Name,:readonly => readonly_flag) + ' ' + lock_img
        end
      else        
        return text_field("integer", "#{parameter.ID}", :value => element_value, :class=>"contentCSPsel required integer_only #{readonly_class}",:readonly => readonly_flag) + ' ' + lock_img
      end
      when Enum_Type
      selected_configure = value_type == "default" ? parameter.Default_Value_ID : parameter.Selected_Value_ID 
      enum_options = EnumParameter.enum_dropdownbox_values(parameter.ID)
      return select("enum", "#{parameter.ID}", options_for_select(set_legend_for_default_values(enum_options, parameter), selected_configure), {}, :class => "contentCSPsel validate[required] #{readonly_class}",:readonly => readonly_flag) + ' ' + lock_img
    end
  end
  
  ####################################################################
  # Function:      get_field_id
  # Parameters:    parameter_type, parameter, value_type='selected_value'
  # Retrun:        "integer_#{parameter.ID}"
  # Renders:       None
  # Description:   Design the field & value for high availability page parameters
  ####################################################################
  def get_field_id(parameter_type, parameter, value_type='selected_value')
    case parameter_type
      when Integer_Type
      element_value = value_type == "default" ? parameter.Default_Value : parameter.Value
      integer_types = IntegerType.find_by_ID(parameter.Type_ID)
      return "integer_#{parameter.ID}"
    end
  end
  
  ####################################################################
  # Function:      get_ha_state
  # Parameters:    connection
  # Retrun:        ha_status
  # Renders:       None
  # Description:   To connection state and state image for high availability page parameters
  ####################################################################
  def get_ha_state(connection)
    ha_status = {}
    if connection.state && connection.state.downcase.eql?('connected')
      ha_status[:state] = "up".titleize #connection.state.titleize
      ha_status[:state] = "#{ha_status[:state]} to '#{connection.ip_address}'" unless connection.ip_address.blank?
      ha_status[:image] = image_tag("/images/dt/plaingreencircle.png")
    elsif connection.state && connection.state.downcase.eql?('disconnected')
      ha_status[:state] = "down".titleize #connection.state.titleize      
      unless connection.status.blank?
        ha_status[:state] = connection.status.titleize #"#{ha_status[:state]} (#{connection.status.titleize})"
        ha_status[:image] = image_tag("/images/time_go.png")
      else
        ha_status[:image] = image_tag("/images/dt/plainredcircle.png")
      end      
    end
    ha_status
  end
  
end
