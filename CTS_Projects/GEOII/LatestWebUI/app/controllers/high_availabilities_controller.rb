####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: high_availabilities_controller.rb
# Description: Builds,validates, updates of High Availability
####################################################################
class HighAvailabilitiesController < ApplicationController
  layout 'general'
  
  ####################################################################
  # Function:      index
  # Parameters:    None
  # Retrun:        @selected_type , @enabled_parameter
  # Renders:       partial =>  form
  # Description:   Builds High availability page
  ####################################################################
  def index
    @selected_type = params[:selected_value] || 'selected_value'
    @enabled_parameter = EnumParameter.high_availability_enabled_parameter
    group_parameter_values
    render(:partial => "form") if request.xhr?
  end
  
  ####################################################################
  # Function:      update
  # Parameters:    params
  # Retrun:        int_updated_value , str_updated_value ,enum_updated_value
  # Renders:       :text => "Parameters updated successfully.." , :nothing => true
  # Description:   Update the High availability page parameters
  ####################################################################
  def update
    if request.xhr? && logged_in?
      int_updated_value = IntegerParameter.update_high_availability_parameters(params["integer"])
      str_updated_value = StringParameter.update_high_availability_parameters(params["string"])
      enum_updated_value = EnumParameter.update_high_availability_parameters(params["enum"])
      if int_updated_value || str_updated_value || enum_updated_value
        render :text => "Parameters updated successfully.."
      else
        render :nothing => true
      end
    end
  end
  
  ####################################################################
  # Function:      connections
  # Parameters:    None
  # Retrun:        @enabled_parameter , @connections
  # Renders:       partial =>  status
  # Description:   Get the status of the high availabilities enabled cards
  ####################################################################
  def connections
    @enabled_parameter = EnumParameter.high_availability_enabled_parameter.Selected_Value_ID
    @connections = HighAvailabilityStatus.all(:conditions => ["state like ?", '%connected%']) if @enabled_parameter == 103
    if params[:auto_refresh]
      render :partial => "status"
    end
  end 
  
  private
  ####################################################################
  # Function:      group_parameter_values
  # Parameters:    channel_id
  # Retrun:        @group_parameters , @group_id , @parameters
  # Renders:       None
  # Description:   Get the group parameter values for high availability page
  ####################################################################  
  def group_parameter_values(channel_id = 0)
    @group_id = 1013801
    @parameters = Array.new
    @group_parameters = Hash.new
    high_availability_parameters = [{:title =>  StringParameter.string_group(@group_id, channel_id), :type => String_Type},
    {:title =>  EnumParameter.enum_group(@group_id, channel_id), :type => Enum_Type},
    {:title => IntegerParameter.Integer_group(@group_id, channel_id), :type => Integer_Type}]
    high_availability_parameters.each do |parameter|
      find_value(parameter[:title], parameter[:type])
    end
    @parameters.compact!
    ordered_params = Array.new
    flag = 1
    temp = 0
    @parameters.each_with_index do |parameter, index|
      ordered_params[index] = parameter
      if flag == 4
        ordered_params.compact!
        @group_parameters[temp] = ordered_params
        flag = 0
        ordered_params = []
        temp += 1
      end
      flag += 1
    end
  end
  
end
