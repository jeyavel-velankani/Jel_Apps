####################################################################
# Company: Siemens 
# Author: Kevin Ponce
# File: nv_config_controller.rb
# Description: Builds, validates, updates and controlls all nv config
####################################################################

class NvConfigController < ApplicationController
  include GenericHelper
  include PtcHelper
  include ApplicationHelper
  include ReportsHelper
  layout 'general'
  before_filter :ptc_setup # this method is defined in PtcHelper and it is only for OCE
  
  def index
    generic(25,0)
  end
  
  def connections
    params[:channel] = (params[:channel] || params[:id] || "0")
    @modules = ParameterGroup.find(:all, :conditions => ["ID = ?", 25])
  end
  
  def feeder
    generic(25,params[:channel])
  end
  
# Site Configuration
  def site_configuration
    if(params[:atcs_address_only].blank?)

      if OCE_MODE == 0
        @site_time = Time.now

        @time_source = EnumParameter.get_parameter_value_from_name('WIU Time Source')
      end
      generic(1,0)
    else
      generic(1,0,true,false)
    end
  end
  def site
    if(params[:atcs_address_only].blank?)
      @site_time = Time.now
      
      #@time_source = EnumParameter.get_parameter_value_from_name('WIU Time Source')
      
      generic(1,0)
    else
      generic(1,0,true)
    end
  end
# Site Configuration Location only
 def site_location
   generic(1,0, false, true)
 end

# PTC 
  def general
    if session[:typeOfSystem] == "VIU" || session[:typeOfSystem] == "CPU-III"
      generic(44,0)
    else
      generic(38,0)
    end
  end
  
  def emp
    @emp = get_rc2keybin_crc_values()
    generic(31,0)
  end

# WIU XML General Configuration
  def wiu
    generic(44,0)
  end

  def class_c_d_message
    generic(32,0)
  end
  
  def beacon_message
    generic(34,0)
  end

  def time_source
    generic(35,0)
  end

  def pref_time_source
    generic(48,0)
  end

####################################################################
# Function:      high_availability
# Parameters:    None 
# Retrun:        None
# Renders:       None
# Description:   Builds high availability pages
####################################################################
  def high_availability
    generic(46,0)
  end

# Communication
  def searial_port
    if params[:channel] != nil
       channel = params[:channel]
    else
      channel = 0
    end

    generic_array([4,1001200],channel)

  end

  def laptop_ethernet
    generic(6,0)
  end

  def ethernet_port
    if params[:channel] != nil
       channel = params[:channel]
    else
      channel = 1
    end
    generic_array([6,1001800],channel)
  end

  def SNMP
    generic(20,0)
  end

  def routing
    generic(9,0)
  end

#Log Setup
  def diagnostic_logging
    generic(40,0)
  end

  def log_verbosity_settings
    generic(42,0)
  end

  #ExternalNetworking
  def cad
    generic(16,0)
  end

  def wams
    generic(19,0)
  end
  
  def wnc
    generic(15,0)
  end

  #DNS
  def dns
    generic(14,0)
  end

  #Security
  def security
    generic(17,0)
  end

  def ptc_test
    generic(36,0)
  end


  def mos
    generic(49,0)
  end

  #Web Server
  def web_server
    generic(47,0)
  end

  # Echelon (iviu)
  def echelon
    generic(24,0)
  end

  # Consolidated Logging
  def consolidated_logging
    generic(41,0)
  end

  # Connections
  def module_connections
    page = params[:page] != nil ? params[:page].to_i : 1
    generic_with_table(25,19,page)
  end

  def digital_inputs
    page = params[:page] != nil ? params[:page].to_i : 1
    io_assignment_digital_inputs(121,16,page,'digital_inputs')
  end

  def analog_inputs
    page = params[:page] != nil ? params[:page].to_i : 1
    io_assignment_generic(122,16,page,'analog_inputs')
  end

  def non_vital_outputs
    page = params[:page] != nil ? params[:page].to_i : 1
    io_assignment_generic(123,16,page,'non_vital_outputs')
  end

  def sear_echelon_modules
    page = params[:page] != nil ? params[:page].to_i : 1
    sear_module_with_table(131,19,page)
  end

  def sear_communication
    generic(129,0)
  end

  def sear_serial_port
    if params[:channel] != nil
       channel = params[:channel]
    else
      channel = 0
    end
    generic(130,channel)
  end

  def sear_defaults

  end

  def sear_set_to_default
    set_default('121,122,123,131,129,130','*')

    render :text => "set to defaults"  
  end

  def defaults 
    #nothing
  end

  def build_site_info
    @site_info = StringParameter.find(:all,:conditions=>['Group_ID = ? and Group_Channel = ?',1,0])

    render :layout => false
  end

  def set_to_defaults
    set_default('25,38,31,32,34,35,48,46,47,4,20,24,40,41,42,16,19,15,17,18,6,9,14','*')

    render :text => 'default'
  end

####################################################################
# Function:      generic
# Parameters:    group_ID & group_channel 
# Retrun:        @subgroup_parameters_id, @group_parameters, & @subgroup_parameters
# Renders:       partial =>  build_generic
# Description:   Builds all of the parameters for nv config pages
# Example:       generic(31,0)
####################################################################
  def generic(group_id,group_ch, atcs_address_only = false, location_only = false)
    @user_presence =  GenericHelper.check_user_presence
    
    @group_id = group_id
    @group_ch = group_ch

    build(@group_id,@group_ch, atcs_address_only, location_only)

     render :partial => "build_generic"
  end

####################################################################
# Function:      build_all
# Parameters:    group_ID & group_channel 
# Retrun:        @subgroup_parameters_id, @group_parameters, & @subgroup_parameters
# Renders:       N/A
# Description:   Builds all of the parameters for nv config pages
####################################################################
def build_all(group_ID,group_channel)
  if !group_ID.blank? && is_numeric?(group_ID) && !group_channel.blank? && (is_numeric?(group_channel) || group_channel == '*')
  
    if params[:default] != nil && (params[:default] == 'true' || params[:default] == true) 
      @default = true
    else
      @default = false
    end
    @subgroup_parameters_id = []
    
    parameters = ( EnumParameter.get(group_ID,group_channel)+ IntegerParameter.get(group_ID, group_channel) + StringParameter.get(group_ID, group_channel) + ByteArrayParameter.get(group_ID, group_channel)).sort_by &:DisplayOrder
    
    @group_parameters = []
    parameters.each do |p|
      if(p.class == EnumParameter)
        selection = EnumParameter.get_dropdownbox(p.ID)
        @group_parameters << {:input => [p], :type => "enum", :selection => selection, :group_ID => group_ID}
      elsif(p.class == IntegerParameter)
        @group_parameters << {:input => [p], :type => "int", :group_ID => group_ID}
      elsif(p.class == ByteArrayParameter)
        @group_parameters << {:input => [p], :type => "byte", :group_ID => group_ID}
      else
        @group_parameters << {:input => [p], :type => "string", :group_ID => group_ID}
      end
    end

    subgroups = Subgroupparameters.get_subgroup_params(group_ID, group_channel)
    subgroupid = nil
    if subgroups != nil      
      @subgroup_parameters = []
      subgroups.each do |sg|
        enum_param_value_ids = EnumToValue.find(:all, :conditions => ["Param_ID = #{sg.Enum_Param_ID}"])

        enum_param_value_ids.each do |enum|
          subgroup_id = Subgroupvalues.find(:first, :select => "Subgroup_ID", :conditions => ["ID = #{sg.ID} and Enum_Value_ID = #{enum[:Value_ID]}"]).try(:Subgroup_ID)

          @subgroup_parameters_id[enum[:Param_ID]] = subgroup_id             
          build_subgroup(subgroup_id, group_channel, enum[:Param_ID], false)
        end
      end
    end
  end
end

def is_numeric?(obj) 
   obj.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
end

####################################################################
# Function:      generic
# Parameters:    group_ID & group_channel 
# Retrun:        @subgroup_parameters_id, @group_parameters, & @subgroup_parameters
# Renders:       partial =>  build_generic
# Description:   Builds all of the parameters for nv config pages
# Example:       generic_array([31,34,38],0)
####################################################################
  def generic_array(group_ids,group_ch, atcs_address_only = false)
    @user_presence =  GenericHelper.check_user_presence
    if (!params[:default].blank? && (params[:default] == 'true' || params[:default] == true))
       @group_id = group_ids
    else
       @group_id = 'array'
    end
    @group_ch = group_ch

    @subgroup_parameters_id_temp = []
    @group_parameters_temp = []
    @subgroup_parameters_temp = []

    group_ids.each do |group_id|
       build(group_id,@group_ch, atcs_address_only)


      @group_parameters.each do |group_parameters|
        @group_parameters_temp << group_parameters
      end

      @subgroup_parameters_id.each do |subgroup_parameters_id|
        @subgroup_parameters_id_temp << subgroup_parameters_id
      end

      @subgroup_parameters.each do |subgroup_parameters|
        @subgroup_parameters_temp << subgroup_parameters
      end
    end

    @subgroup_parameters_id = @subgroup_parameters_id_temp 
    @group_parameters = @group_parameters_temp
    @subgroup_parameters = @subgroup_parameters_temp

     render :partial => "build_generic"
  end


####################################################################
# Function:      build_all_array
# Parameters:    group_ids,group_ch
# Retrun:        @subgroup_parameters_id, @group_parameters, & @subgroup_parameters
# Renders:       partial =>  build_generic
# Description:   Builds all of the parameters for nv config pages
# Example:       build_all_array([31,34,38],0)
####################################################################
def build_all_array(group_ids,group_ch)
  @group_id = group_ids
  @group_ch = group_ch

  @subgroup_parameters_id_temp = []
  @group_parameters_temp = []
  @subgroup_parameters_temp = []

  group_ids.each do |group_id|
     build_all(group_id,@group_ch)


    @group_parameters.each do |group_parameters|
      @group_parameters_temp << group_parameters
    end

    @subgroup_parameters_id.each do |subgroup_parameters_id|
      @subgroup_parameters_id_temp << subgroup_parameters_id
    end

    @subgroup_parameters.each do |subgroup_parameters|
      @subgroup_parameters_temp << subgroup_parameters
    end
  end

  @subgroup_parameters_id = @subgroup_parameters_id_temp 
  @group_parameters = @group_parameters_temp
  @subgroup_parameters = @subgroup_parameters_temp
end

####################################################################
# Function:      generic_with_table
# Parameters:    group_id, number_per_page, &current_page
# Retrun:        @subgroup_parameters_id, @group_parameters, & @subgroup_parameters
# Renders:       partial =>  build_generic_table
# Description:   Builds all of the parameters for nv config pages
# Example:       page = params[:page] != nil ? params[:page].to_i : 1
#                generic_with_table(25,19,page)
####################################################################
  def generic_with_table(group_id,number_per_page,current_page)
    @user_presence =  GenericHelper.check_user_presence

    @group_id = group_id
    
    @number_per_page = number_per_page

    @current_page = current_page

    build_channels(@group_id,current_page,@number_per_page)

    if @channels[0].Group_Channel != nil
      @group_ch = @channels[0].Group_Channel
      build(@group_id,@group_ch)
    end
    
    render :partial => "build_generic_table"
  end

####################################################################
# Function:      sear_module_with_table
# Parameters:    group_id, number_per_page, &current_page
# Retrun:        @subgroup_parameters_id, @group_parameters, & @subgroup_parameters
# Renders:       partial =>  build_generic_table
# Description:   Builds all of the parameters for nv config pages
# Example:       page = params[:page] != nil ? params[:page].to_i : 1
#                sear_module_with_table(25,19,page)
####################################################################
  def sear_module_with_table(group_id,number_per_page,current_page)
    @user_presence =  GenericHelper.check_user_presence

    @group_id = group_id
    
    @number_per_page = number_per_page

    @current_page = current_page

    build_channels(@group_id,current_page,@number_per_page)

    if @channels[0].Group_Channel != nil
      @group_ch = @channels[0].Group_Channel
      build(@group_id,@group_ch)

      @sscc_set = false

      if @group_parameters != nil
        @group_parameters.each do |t| 
          
            if t[:type] == 'enum' && t[:input][0][:Name] == 'Type'
              value = t[:input][0][:Selected_Value_ID]
              
              t[:selection].each do |sel|
                name = sel[:Name]
              option_id = sel[:ID]
              option_value = sel[:Value]
                if option_id == value &&  name == 'SSCC'
                  @sscc_set = true

                  if params[:stat_index]
                    stat_index = params[:stat_index]
                  else
                    stat_index = 150
                  end

                  if params[:stat_index]
                    stat_index = params[:stat_index]
                  else
                    stat_index = 150
                  end

                  if params[:select_group_channel]
                    select_group_channel = params[:select_group_channel]
                  else
                    select_group_channel = 0
                  end

                  get_sscc_content(stat_index,@group_ch,select_group_channel)
                end
              end
            end
        end
      end
    end
    
    render :partial => "build_generic_table"
  end
####################################################################
# Function:      io_assignment_digital_inputs
# Parameters:    group_id,number_per_page,current_page,io_type
# Retrun:        
# Renders:       partial =>  build_generic_io_assignment
# Description:   
####################################################################
  def io_assignment_digital_inputs(group_id,number_per_page,current_page,io_type)
    @user_presence =  GenericHelper.check_user_presence

    @group_id = group_id
    
    @number_per_page = number_per_page

    @current_page = current_page

    io_assingment_build_channels_digital_inputs(@group_id,current_page,@number_per_page)

    if @channels[0].Group_Channel != nil
      @group_ch = @channels[0].Group_Channel
      build(@group_id,@group_ch)

      @io_template_options = get_io_assignment_template(io_type,@group_id,@group_ch)
    end
    if OCE_MODE == 1
      @channel_labels = get_channel_labels
    end     
    
    render :partial => "build_generic_io_assignment",:locals=>{:digital_inputs=>true}
  end

####################################################################
# Function:      io_assignment_generic
# Parameters:    group_id,number_per_page,current_page,io_type
# Retrun:        
# Renders:       partial =>  build_generic_io_assignment
# Description:   
####################################################################
  def io_assignment_generic(group_id,number_per_page,current_page,io_type)
    @user_presence =  GenericHelper.check_user_presence

    @group_id = group_id
    
    @number_per_page = number_per_page

    @current_page = current_page

    io_assingment_build_channels(@group_id,current_page,@number_per_page)

    if @channels[0].Group_Channel != nil
      @group_ch = @channels[0].Group_Channel
      build(@group_id,@group_ch)

      @io_template_options = get_io_assignment_template(io_type,@group_id,@group_ch)
    end
    
    render :partial => "build_generic_io_assignment",:locals=>{:digital_inputs=>false}
  end

  def get_io_assignment_template(io_type,group_id,group_ch)
    get_io_assignment_template = true
    if io_type == 'digital_inputs'
      algorithm_id = EnumParameter.find(:all,:select=>"ID",:conditions=>['Group_Channel= ? AND Group_ID=? AND DisplayOrder!= ? AND Name = "Algorithm"', group_ch, group_id, -1],:order => 'DisplayOrder')

      if algorithm_id  
        algorithm_id =  algorithm_id[0][:ID]

        algorithm_values_check = EnumToValue.find_by_sql("Select * from enum_to_values inner join enum_values on enum_to_values.Value_ID = enum_values.ID where enum_to_values.Param_ID = #{algorithm_id}")

        if algorithm_values_check
          discrete = false
          mtss = false
          gft = false

          algorithm_values_check.each do |val|
            name = val[:Name].downcase 
            if name == 'discrete'
              discrete = true
            elsif name == 'mtss'
              mtss = true
            elsif name == 'gft'
              gft = true
            end
          end
        else
          get_io_assignment_template = false
        end
      else
        get_io_assignment_template = false
      end
    end
    if get_io_assignment_template
      options = ''
      if OCE_MODE == 1
        xml_file = "#{RAILS_ROOT}/oce_configuration/templates/GCP5000/config_templates.xml"
      else
        xml_file = "/usr/safetran/conf/config_templates.xml"
      end
     
      if File.exist?(xml_file)
        doc = Document.new File.new(xml_file)

        if io_type == 'digital_inputs'
          
            if discrete

              doc.elements.each("SEAR_Templates/io_type[@ID='digital_inputs']/algorithm[@ID='Discrete']/DataSet") { |element| 
                if element && element.attributes["tag"] && element.attributes["off_state_name"] && element.attributes["on_state_name"]
                options += '<option tag="'+element.attributes["tag"] +'" off_state_name="'+element.attributes["off_state_name"] +'" on_state_name="'+ element.attributes["on_state_name"] +'">'+element.attributes["name"] +'</option>';
                end
              }     
            end

            if mtss
              doc.elements.each("SEAR_Templates/io_type[@ID='digital_inputs']/algorithm[@ID='MTSS']/DataSet") { |element| 
                if element && element.attributes["tag"] && element.attributes["off_state_name"] && element.attributes["on_state_name"]
                  options += '<option tag="'+element.attributes["tag"] +'" off_state_name="'+element.attributes["off_state_name"] +'" on_state_name="'+ element.attributes["on_state_name"] +'">'+element.attributes["name"] +'</option>';
                end
              } 
            end 

            if gft
              doc.elements.each("SEAR_Templates/io_type[@ID='digital_inputs']/algorithm[@ID='GFT']/DataSet") { |element| 
                if element && element.attributes["tag"] && element.attributes["off_state_name"] && element.attributes["on_state_name"]
                  options += '<option tag="'+element.attributes["tag"] +'" off_state_name="'+element.attributes["off_state_name"] +'" on_state_name="'+ element.attributes["on_state_name"] +'">'+element.attributes["name"] +'</option>';
                end
              } 
            end

        elsif io_type == 'non_vital_outputs'
          doc.elements.each("SEAR_Templates/io_type[@ID='non_vital_outputs']/algorithm[@ID='Not_Applicable']/DataSet") { |element| 
              if element && element.attributes["tag"] && element.attributes["off_state_name"] && element.attributes["on_state_name"]
                options += '<option tag="'+element.attributes["tag"] +'" off_state_name="'+element.attributes["off_state_name"] +'" on_state_name="'+ element.attributes["on_state_name"] +'">'+element.attributes["name"] +'</option>';
              end
          } 
        end

        if options != ''
          return options
        else
          #no options
          return 'error'
        end
      else
        #no file
        return 'error'
      end
    else
      return 'error'
    end
  end

####################################################################
# Function:      generic_with_tabs
# Parameters:    group_id, number_per_page, & current_page
# Retrun:        @subgroup_parameters_id, @group_parameters, & @subgroup_parameters
# Renders:       partial =>  build_generic_table
# Description:   Builds all of the parameters for nv config pages
# Example:       generic_with_tabs(1,1)
####################################################################
  def generic_with_tabs(group_id,group_ch)
    @user_presence =  GenericHelper.check_user_presence
    
     @group_id = group_id
     @group_ch = group_ch

     build_tabs(@group_id)
     build(@group_id,@group_ch)

     render :partial => "build_generic_tabs"
  end
  
####################################################################
# Function:      build
# Parameters:    group_ID & group_channel 
# Retrun:        @subgroup_parameters_id, @group_parameters, & @subgroup_parameters
# Renders:       N/A
# Description:   Builds all of the parameters for nv config pages
####################################################################
  def build(group_ID,group_channel, atcs_address_only = false, location_only = false)
    if params[:default] != nil && (params[:default] == 'true' || params[:default] == true) 
      @default = true
    else
      @default = false
    end
  	
    if group_ID != nil && group_channel != nil
      @subgroup_parameters_id = []
      if(atcs_address_only)
        parameters = ( StringParameter.get(group_ID, group_channel, true)).sort_by &:DisplayOrder
      elsif(location_only)
        parameters = ( StringParameter.get(group_ID, group_channel, false, true)).sort_by &:DisplayOrder
      else
	  	  parameters = ( EnumParameter.get(group_ID,group_channel)+ IntegerParameter.get(group_ID, group_channel) + StringParameter.get(group_ID, group_channel) + ByteArrayParameter.get(group_ID, group_channel)).sort_by &:DisplayOrder
      end
	    @group_parameters = []
	    parameters.each do |p|
	      if(p.class == EnumParameter)
	      	selection = EnumParameter.get_dropdownbox(p.ID)
	        @group_parameters << {:input => [p], :type => "enum", :selection => selection, :group_ID => group_ID}
	      elsif(p.class == IntegerParameter)
	        @group_parameters << {:input => [p], :type => "int", :group_ID => group_ID}
        elsif(p.class == ByteArrayParameter)
          @group_parameters << {:input => [p], :type => "byte", :group_ID => group_ID}
	      else
	        @group_parameters << {:input => [p], :type => "string", :group_ID => group_ID}
	      end
	    end
	  end

    subgroups = Subgroupparameters.get_subgroup_params(group_ID, group_channel)
    subgroupid = nil
    if subgroups != nil      
      @subgroup_parameters = []
      subgroups.each do |sg|
          if @default
            if !sg.Enum_Param_ID.blank?
              subgroupid = Subgroupparameters.get_subgroup_id(sg.ID, group_ID, group_channel, sg.Enum_Param_ID, "default")
            end            
          else
            if !sg.Enum_Param_ID.blank?
              subgroupid = Subgroupparameters.get_subgroup_id(sg.ID, group_ID, group_channel, sg.Enum_Param_ID, "selected")
            end
          end
        
          @subgroup_parameters_id[sg.Enum_Param_ID] = subgroupid                
          build_subgroup(subgroupid, group_channel, sg.Enum_Param_ID, false)
        
      end
    end
  end

####################################################################
# Function:      build_subgroup
# Parameters:    enum_val_id, group_channel, enum_id, & update
# Retrun:        @update_nv_config, & @subgroup_parameters
# Renders:       N/A
# Description:   Builds the sub group parameters
####################################################################
  def build_subgroup(enum_val_id,group_channel,enum_id,update)

    @update_nv_config = update

    if enum_val_id != nil && group_channel != nil
      subgroups = ( EnumParameter.get(enum_val_id,group_channel)+ IntegerParameter.get(enum_val_id, group_channel) + StringParameter.get(enum_val_id, group_channel) + ByteArrayParameter.get(enum_val_id, group_channel)).sort_by &:DisplayOrder

      #this will allow multiple subgroups to be build on initial build
      if @subgroup_parameters == nil
        @subgroup_parameters = []
      end

      if subgroups.length > 0
        subgroups.each do |sg|
          if(sg.class == EnumParameter)
            selection = EnumParameter.get_dropdownbox(sg.ID)
            @subgroup_parameters << {:input => [sg], :type => "enum", :selection => selection, :id => enum_id,:group_ID => enum_val_id}
          elsif(sg.class == IntegerParameter)
            @subgroup_parameters << {:input => [sg], :type => "int", :id => enum_id,:group_ID => enum_val_id}
          elsif(sg.class == ByteArrayParameter)
             @subgroup_parameters << {:input => [sg], :type => "byte",:group_ID => enum_val_id}
          else
            @subgroup_parameters << {:input => [sg], :type => "string", :id => enum_id,:group_ID => enum_val_id}
          end
        end
      else
        @subgroup_parameters << {:input => '', :type => "blank", :id => enum_id}
      end

      subgroups = Subgroupparameters.get_subgroup_params(enum_val_id, group_channel)
      subgroupid = nil
      if @subgroup_parameters_id == nil
        @subgroup_parameters_id = []
      end

      if subgroups != nil      
        subgroups.each do |sg|
          subgroupid = Subgroupparameters.get_subgroup_id(sg.ID, enum_val_id, group_channel, sg.Enum_Param_ID, (@default ? "default" : "selected"))            
         
          @subgroup_parameters_id[sg.Enum_Param_ID] = subgroupid  

          build_subgroup(subgroupid, group_channel, sg.Enum_Param_ID, false)
        end
      end
    end
  end

####################################################################
# Function:      get_build
# Parameters:    group_id, group_ch
# Return:        @subgroup_parameters
# Renders:       :partial => "build_subgroup_parameters"  
# Description:   Allows users to update sub group when the enum changes
####################################################################
  def get_build
    group_ID = params[:group_id]
    group_channel = params[:group_ch]

    build(group_ID,group_channel)

    render :partial => "parameters"
  end

####################################################################
# Function:      get_sear_mod_build
# Parameters:    group_id, group_ch
# Return:        @subgroup_parameters
# Renders:       :partial => "build_subgroup_parameters"  
# Description:   Allows users to update sub group when the enum changes
####################################################################
  def get_sear_mod_build
    group_ID = params[:group_id]
    group_channel = params[:group_ch]

    build(group_ID,group_channel)

    if @group_parameters != nil
      @group_parameters.each do |t| 
        
          if t[:type] == 'enum' && t[:input][0][:Name] == 'Type'
            value = t[:input][0][:Selected_Value_ID]
            
            t[:selection].each do |sel|
              name = sel[:Name]
            option_id = sel[:ID]
            option_value = sel[:Value]
              if option_id == value &&  name == 'SSCC'
                @sscc_set = true

                if params[:stat_index]
                  stat_index = params[:stat_index]
                else
                  stat_index = 150
                end

                if params[:stat_index]
                  stat_index = params[:stat_index]
                else
                  stat_index = 150
                end

                if params[:select_group_channel]
                  select_group_channel = params[:select_group_channel]
                else
                  select_group_channel = 0
                end

                get_sscc_content(stat_index,@group_ch,select_group_channel)
              end
            end
          end
      end
    end

    render :partial => "parameters"
  end

####################################################################
# Function:      get_sscc_build
# Parameters:    group_id, group_ch
# Return:        @subgroup_parameters
# Renders:       :partial => "build_subgroup_parameters"  
# Description:   Allows users to update sub group when the enum changes
####################################################################
  def get_sscc_build
    group_ID = params[:group_id]
    group_channel = params[:group_ch]

    build(group_ID,group_channel)

    @sscc_set = false

    if @group_parameters != nil
      @group_parameters.each do |t| 
        
          if t[:type] == 'enum' && t[:input][0][:Name] == 'Type'
            value = t[:input][0][:Selected_Value_ID]
            
            t[:selection].each do |sel|
              name = sel[:Name]
            option_id = sel[:ID]
            option_value = sel[:Value]
              if option_id == value &&  name == 'SSCC'
                @sscc_set = true

                if params[:stat_index]
                  stat_index = params[:stat_index]
                else
                  stat_index = 150
                end

                if params[:stat_index]
                  stat_index = params[:stat_index]
                else
                  stat_index = 150
                end

                if params[:select_group_channel]
                  select_group_channel = params[:select_group_channel]
                else
                  select_group_channel = 0
                end

                get_sscc_content(stat_index,@group_ch,select_group_channel)
              end
            end
          end
      end
    end

    render :partial => "parameters"
  end

####################################################################
# Function:      get_io_assignment_build
# Parameters:    group_id, group_ch, selected_id, & enum_id
# Return:        @subgroup_parameters
# Renders:       :partial => "build_subgroup_parameters"  
# Description:   Allows users to update sub group when the enum changes
####################################################################
  def get_io_assignment_build
    group_ID = params[:group_id]
    group_channel = params[:group_ch]
    io_type = params[:io_type]

    @group_id = group_ID
    @group_ch = group_channel

    build(group_ID,group_channel)

    @io_template_options = get_io_assignment_template(io_type,group_ID,group_channel)

    render :partial => "io_assignment_parameters"
  end
####################################################################
# Function:      get_subgroup
# Parameters:    group_id, group_ch, selected_id, & enum_id
# Return:        @subgroup_parameters
# Renders:       :partial => "build_subgroup_parameters"  
# Description:   Allows users to update sub group when the enum changes
####################################################################
  def get_subgroup
    group_id = params[:group_id]
    group_ch = params[:group_ch]
    selected_id = params[:selected_id]
    enum_id = params[:enum_id]
    selected_readable = params[:selected_readable]

    @subgroup_parameters_id = []
        
    subgroups = Subgroupparameters.get_subgroup_params(group_id.to_i, group_ch.to_i)
    subgroupid = nil
    if subgroups != nil      
      @subgroup_parameters = []
      subgroups.each do |sg|
        subgroupid = Subgroupvalues.find(:first, :select => "Subgroup_ID", :conditions => ["ID = #{sg.ID} and Enum_Value_ID = #{selected_id.to_i}"]).try(:Subgroup_ID)
        @subgroup_parameters_id[sg.Enum_Param_ID] = subgroupid      
        build_subgroup(subgroupid, group_ch, enum_id, false)
      end
    end

    if selected_readable == 'SSCC'
      if params[:stat_index]
        stat_index = params[:stat_index]
      else
        stat_index = 150
      end

      if params[:stat_index]
        stat_index = params[:stat_index]
      else
        stat_index = 150
      end

      if params[:select_group_channel]
        select_group_channel = params[:select_group_channel]
      else
        select_group_channel = 0
      end

      get_sscc_content(stat_index,group_ch,select_group_channel)
      @sscc_set = true
    else
      @sscc_set = false
    end

    render :partial => "build_subgroup_parameters"
  end

####################################################################
# Function:      save
# Parameters:    int, string, enum parameters ex: int_123 = 12
# Return:        @subgroup_parameters
# Renders:       variable error 
# Description:   saves all nv config parameters
####################################################################
  def save
    nvSavedDefaultInt = []
    nvSavedDefaultEnum = []
    nvSavedDefaultString = []
    nvSavedDefaultByte = []
  	error = ''
    #if time and date are set it will save and reset the server
    if OCE_MODE == 0
      if params[:date] != nil && params[:hour] != nil && params[:min]  != nil && params[:sec] != nil
        error = sever_date_time_update( params[:date], params[:hour], params[:min], params[:sec])
      end
    end

    #if there was no error saving the time it will validate all parameters
    if error == ''|| error == nil
      #checks for errors
      params.each do |key,p|
        type = key.split('_')[0]
        id = key.split('_')[1]
        val = p
        
        if id != nil && type != nil && val != nil
          case type
            when "int"
              temp_error = IntegerParameter.validate(id,val)
              nvSavedDefaultInt << id
            when "string"
              temp_error = StringParameter.validate(id,val)
              nvSavedDefaultString << id
            when "enum"
              temp_error  = EnumParameter.validate(id,val)
              nvSavedDefaultEnum << id
            when "byte"
              temp_error  = ByteArrayParameter.validate(id,val)
              nvSavedDefaultByte << id
          end 
        end
        
        if temp_error != nil && temp_error != ''
          error += type+'_'+id+'=>'+temp_error+','
        end
      end
    end

    #if there was no error saving the time it will validate all parameters
    if error == ''|| error == nil      
      params.each do |key,p|
        type = key.split('_')[0]
        id = key.split('_')[1]
        val = p
        if id != nil && type != nil && val != nil
          case type
            when "int"
            IntegerParameter.update(id,val)
            when "string"
            StringParameter.update(id,val)
            when "enum"
            EnumParameter.update(id,val)
            when "byte"
            ByteArrayParameter.update(id,val)
          end 
        end
      end

      if params[:default]
        if params[:group_id] && params[:group_ch]
          group_ID = params[:group_id]
          group_ch = params[:group_ch]

          if group_ID.index(',') != nil
            group_IDs = group_ID.gsub(/\[|\]/,'').split(/,/).map(&:to_i)
            build_all_array(group_IDs,group_ch)
          else
            build_all(group_ID,group_ch)
          end

          nvSetDefaultInt = []
          nvSetDefaultEnum = []
          nvSetDefaultString = []
          nvSetDefaultByte = []

          paramIdsArray = [@group_parameters,@subgroup_parameters]

          paramIdsArray.each do |paramIds| 

            paramIds.each do |t| 
              type = t[:type]

              if ["int","string","enum","byte"].include?(type) 
                id = t[:input][0][:ID]

                case type
                  when "int"
                    if !nvSavedDefaultInt.include?(id.to_i)
                      nvSetDefaultInt << id
                    end
                  when "string"
                    if !nvSavedDefaultString.include?(id.to_i)
                      nvSetDefaultString << id
                    end
                  when "enum"  
                    if !nvSavedDefaultEnum.include?(id.to_i)
                      nvSetDefaultEnum << id
                    end
                  when "byte"
                    if !nvSavedDefaultByte.include?(id.to_i)
                      nvSetDefaultByte << id
                    end
                end
              end
            end
          end

          #checks if int has any ids to set to default
          if !nvSetDefaultInt.empty?
            IntegerParameter.update_all("Value = Default_Value","ID IN (#{nvSetDefaultInt.join(',')})")
          end

          #checks if String has any ids to set to default
          if !nvSetDefaultString.empty?
            StringParameter.update_all("String = Default_String","ID IN (#{nvSetDefaultString.join(',')})")
          end

          #checks if String has any ids to set to default
          if !nvSetDefaultEnum.empty?
            EnumParameter.update_all("Selected_Value_ID = Default_Value_ID","ID IN (#{nvSetDefaultEnum.join(',')})")
          end

          #checks if String has any ids to set to default
          if !nvSetDefaultByte.empty?
            ByteArrayParameter.update_all("Array_Value = Default_Value","ID IN (#{nvSetDefaultByte.join(',')})")
          end
        else
          if params[:group_id]
            error = 'Group ID is not set'
          elsif params[:group_ch]
            error = 'Group channel is not set'
          else
            error = 'Group ID and Group channel are not set'
          end
        end
      end
    else
      error = error[0..error.length-2]
  	end
  	
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      if ((!params[:string_4].blank?) && (session[:typeOfSystem] != "GCP"))
        update_rt_sin_values(4, params[:string_4].to_s)  if params[:string_4].to_s.length == 16
      elsif !params[:int_1].blank? && !params[:int_2].blank? && !params[:int_3].blank? && !params[:int_5].blank?
    	  atcs_sin =  "7." + ("%03d" % params[:int_1].to_s) + "." + ("%03d" % params[:int_2].to_s) + "." + ("%03d" % params[:int_3].to_s) + "." + ("%02d" % params[:int_5].to_s)      
    	  update_rt_sin_values(4, atcs_sin)
      end
    end
  	render :text => error
  end

  ####################################################################
  # Function:      save_rc2_key
  # Parameters:    params[:val] 
  # Retrun:        simplerequest
  # Renders:       render :text
  # Description:   Save RC2Key Values
  ####################################################################
  def save_rc2_key
    if (!params[:def_flg].blank?) && (params[:def_flg].to_s == "true")
      params[:val] = ByteArrayParameter.Bytearray_defaultvalue_query(2)
    end
        
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      rc2_val = ""
      unless params[:val].blank?
        rc2_val = params[:val].to_s
      end
        rc2bin_path = "#{session[:cfgsitelocation]}/rc2key.bin"
        libcic = WIN32OLE.new('CIC_BIN.CICBIN')
        strmsg = libcic.GenerateRc2KeyFile(rc2bin_path , rc2_val)
        rc2key_field_val = ByteArrayParameter.get_value(31,"RC2 Key")
        ByteArrayParameter.update(rc2key_field_val.ID , rc2_val)
      render :text => 1
    else
      simplerequest = RrSimpleRequest.create(:request_state => 0, :command => 8, :value => params[:val])
      udp_send_cmd(17, simplerequest.request_id)
      render :text => simplerequest.request_id
    end
  end
  
  ####################################################################
  # Function:      check_rc2_key
  # Parameters:    params[:request_id]
  # Retrun:        simplerequest
  # Renders:       render :json
  # Description:   Check the RC2Key Value update status
  ####################################################################
  def check_rc2_key
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      render :json => {:request_state => 2 , :result => 0}
    else
      simplerequest = RrSimpleRequest.find(:first,:conditions=>['request_id = ?',params[:request_id]])
      if simplerequest[:request_state] == 2
        #RrSimpleRequest.delete_all("request_id = #{simplerequest[:request_id]}")
      end 
      render :json => {:request_state => simplerequest[:request_state], :result => simplerequest[:result]}
    end
  end
  
  def set_web_server
    changed_val = params[:webserver_val]
    simplerequest = RrSimpleRequest.create(:request_state => 0, :command => 15, :value => changed_val)
    udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, simplerequest.request_id)
    render :json => { :request_id => simplerequest.request_id , :new_value => changed_val}
  end
  
  def web_server_req_state
    simplerequest = RrSimpleRequest.find_by_request_id(params[:request_id])
    render :json => { :request_state => simplerequest.request_state, :result => simplerequest.result, :value => simplerequest.value}
  end

  ####################################################################
  # Function:      set_default
  # Parameters:    group_ID,group_ch
  # Retrun:        N/A
  # Renders:       N/A
  # Description:   Sets select to default
  # Example:       set_default('1','0')
  #                set_default('1,2,3','0')
  #                set_default('1,2,3','*')
  ####################################################################
def set_default(group_ID,group_ch)
  if group_ID.index(',') != nil
    group_IDs = group_ID.split(',')

    build_all_array(group_IDs,group_ch)
  else
    build_all(group_ID,group_ch)
  end

  nvSetDefaultInt = []
  nvSetDefaultEnum = []
  nvSetDefaultString = []
  nvSetDefaultByte = []

  paramIdsArray = [@group_parameters,@subgroup_parameters]

  paramIdsArray.each do |paramIds| 

    paramIds.each do |t| 
      type = t[:type]

      if ["int","string","enum","byte"].include?(type) 
        id = t[:input][0][:ID]

        case type
          when "int"
            nvSetDefaultInt << id
          when "string"
            nvSetDefaultString << id
          when "enum"  
            nvSetDefaultEnum << id
          when "byte"
            nvSetDefaultByte << id
        end
      end
    end
  end

  #checks if int has any ids to set to default
  if !nvSetDefaultInt.empty?
    IntegerParameter.update_all("Value = Default_Value","ID IN (#{nvSetDefaultInt.join(',')})")
  end

  #checks if String has any ids to set to default
  if !nvSetDefaultString.empty?
    StringParameter.update_all("String = Default_String","ID IN (#{nvSetDefaultString.join(',')})")
  end

  #checks if String has any ids to set to default
  if !nvSetDefaultEnum.empty?
    EnumParameter.update_all("Selected_Value_ID = Default_Value_ID","ID IN (#{nvSetDefaultEnum.join(',')})")
  end

  #checks if String has any ids to set to default
  if !nvSetDefaultByte.empty?
    ByteArrayParameter.update_all("Array_Value = Default_Value","ID IN (#{nvSetDefaultByte.join(',')})")
  end
end
####################################################################
# Function:      build_tabs
# Parameters:    group_ID
# Return:        @tabs 
# Renders:       N/A 
# Description:   builds all tabs for a specific ID
####################################################################
  def build_tabs(group_ID)
    @tabs = ParameterGroup.get_tabs(group_ID)
  end

####################################################################
# Function:      build_channels
# Parameters:    group_ID, page_number,& number_per_page
# Return:        @channels & @number_per_page
# Renders:       N/A 
# Description:   builds all channels for a specific ID
####################################################################
  def build_channels(group_ID,page_number,number_per_page)
    @number_per_page = number_per_page
    @channels = StringParameter.get_channel(group_ID,page_number,number_per_page)
    @channel_count = StringParameter.get_channel_count(group_ID)
    @current_channel = @channels[0].Group_Channel
    @rebuild = false
  end

####################################################################
# Function:      io_assingment_build_channels_digital_inputs
# Parameters:    group_ID, page_number,& number_per_page
# Return:        @channels & @number_per_page
# Renders:       N/A 
# Description:   builds all channels for a specific ID
####################################################################
  def io_assingment_build_channels_digital_inputs(group_ID,page_number,number_per_page)
    @number_per_page = number_per_page
    @channels = StringParameter.get_io_assignment_digital_inputs_names(group_ID,page_number-1,number_per_page)
    channel_count = StringParameter.get_count_io_assignment_digital_inputs_names(group_ID)
    @channel_count = channel_count[0]['count']
    @current_channel = @channels[0].Group_Channel
    @rebuild = false
  end

####################################################################
# Function:      io_assingment_build_channels
# Parameters:    group_ID, page_number,& number_per_page
# Return:        @channels & @number_per_page
# Renders:       N/A 
# Description:   builds all channels for a specific ID
####################################################################
  def io_assingment_build_channels(group_ID,page_number,number_per_page)
    @number_per_page = number_per_page
    @channels = StringParameter.get_io_assignment_names(group_ID,page_number-1,number_per_page)
    channel_count = StringParameter.get_count_io_assignment_names(group_ID)
    @channel_count = channel_count[0]['count']
    @current_channel = @channels[0].Group_Channel
    @rebuild = false
  end

####################################################################
# Function:      rebuild_channels_table
# Parameters:    group_ID, page_number,& number_per_page
# Return:        @channels & @number_per_page
# Renders:       N/A 
# Description:   builds all channels for a specific ID
####################################################################
  def rebuild_channels_table
    @group_ID = params[:group_ID].to_i
    @page_number = params[:page_number].to_i
    @number_per_page = params[:number_per_page].to_i
    @current_channel = params[:current_channel].to_i
    @rebuild = true

    if @group_ID != nil 
      @channels = StringParameter.get_channel(@group_ID,@page_number,@number_per_page)
      @channel_count = StringParameter.get_channel_count(@group_ID)
      
      if @current_channel == nil
        @current_channel = @channels[0].Group_Channel
      end

      render :partial => "build_channels_table",:locals=>{:io_assignment=>false}
    else
      render :text => ""
    end
  end

####################################################################
# Function:      rebuild_io_assigment_channels_table
# Parameters:    group_ID, page_number,& number_per_page
# Return:        @channels & @number_per_page
# Renders:       N/A 
# Description:   builds all channels for a specific ID
####################################################################
  def rebuild_io_assigment_channels_table
    @group_ID = params[:group_ID].to_i
    @page_number = params[:page_number].to_i
    @number_per_page = params[:number_per_page].to_i
    @current_channel = params[:current_channel].to_i
    io_type = params[:io_type]
    

    if @group_ID != nil 
      if io_type == 'digital_inputs'
        io_assingment_build_channels_digital_inputs(@group_ID,@page_number,@number_per_page)
      else
        io_assingment_build_channels(@group_ID,@page_number,@number_per_page)
      end
      @rebuild = true

      render :partial => "build_channels_table",:locals=>{:io_assignment=>false}
    else
      render :text => ""
    end
  end

####################################################################
# Function:      sever_date_time_update
# Parameters:    date , hour, minute, second
# Return:        @err_msg
# Renders:       N/A 
# Description:   updates the server with the new time
####################################################################
  def sever_date_time_update(date, hour, minute, second)
    #Update the Non vital CPU time
    selected_date = date.split('-')

    # Making time, Time.mktime(year, month, day, hour, min, sec_with_frac) => time   
    mk_time = Time.mktime(selected_date[2], selected_date[0], selected_date[1], hour.to_i, minute.to_i, second.to_i) rescue Time.now
    
    #creates row in the datebase to send a udp to change the server time
    simple_rq_set_date = RrSimpleRequest.new()
    simple_rq_set_date.atcs_address = "#{Gwe.atcs_address}.02"
    simple_rq_set_date.request_state = 0
    simple_rq_set_date.command = 10
    simple_rq_set_date.subcommand = 0
    simple_rq_set_date.value = mk_time.to_i
    simple_rq_set_date.save
    
    udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST,  simple_rq_set_date.request_id)
    
    request_state = 0
    counter = 0
    @err_msg = ""

    #waites until backend sets request sate to 2
    until request_state == 2
      sleep 2
      counter += 1

      #gets the datebase to check if the request steate is 2 yet
      set_time_request = RrSimpleRequest.find(:all,:select =>"request_state",:conditions=>["request_id=?",simple_rq_set_date.request_id])

      if set_time_request && set_time_request[0].request_state == 2 
        request_state = 2
      elsif counter >= 10
        #time out and will return an error
        request_state = 2
        @err_msg  = "<span style='color:red'>Failed to save Non Vital Date and Time</span>"
      else
        request_state = 0
      end
    end

    #returns the error messate. if there no no error message it will return a blank string
    return @err_msg
  end

  ####################################################################
  # Function:      get_rc2key_status
  # Parameters:    None
  # Retrun:        session[:rc2keycrc]
  # Renders:       render :text
  # Description:   Return the RC2Key CRC values from the RC2KEY.BIN file
  ####################################################################
  def get_rc2key_status
    @emp = get_rc2keybin_crc_values()
    render :text => session[:rc2keycrc]
  end
  # display config
  def display
    generic(18,0)
  end

  def get_sscc_content(stat_index,channel,select_group_channel)
    @start_index = stat_index

    group_id = stat_index.to_i+channel.to_i
    @select_group_channel = select_group_channel
   
    @num = stat_index.to_i + channel.to_i

    @sscc_modules = StringParameter.find_by_sql('select String_Parameters.*,String_Types.Min_Length,String_Types.Max_Length from String_Parameters join String_Types on String_Parameters.Type_ID = String_Types.ID where Group_ID = '+group_id.to_s+' and DisplayOrder > -1')
   
    @num_of_items = StringParameter.count(:conditions => ["Group_Channel =? and Group_ID  = ? and DisplayOrder > ?",0,stat_index.to_i+channel.to_i,-1])

    @size = StringParameter.count(:conditions => ["Name =? and Group_ID = ? and DisplayOrder > ?","Name",stat_index.to_i+channel.to_i,-1])

    @Parameter_group = ParameterGroup.find(:all,:conditions=>["ID = ?",group_id])

    @VitaulOutputsTitle = []

    @Parameter_group.each do |pg|
      @VitaulOutputsTitle[pg.Group_Channel] = pg.Group_Name
    end
  end 

  def get_sscc_content_render
    if params[:stat_index]
      stat_index = params[:stat_index]
    else
      stat_index = 150
    end

    if params[:stat_index]
      stat_index = params[:stat_index]
    else
      stat_index = 150
    end

    if params[:select_group_channel]
      select_group_channel = params[:select_group_channel]
    else
      select_group_channel = 0
    end

    if params[:channel]
      group_ch = params[:channel]
    else
      group_ch = 0
    end

    get_sscc_content(stat_index,group_ch,select_group_channel)

    render :partial=> "sscc_subgroup_view"
  end 
  def get_channel_labels

    xml_file = "#{RAILS_ROOT}/config/chassis_label.xml"
    channel_names = {}
    if File.exist?(xml_file)
      doc = Document.new File.new(xml_file)
      doc.elements.each("chassis_label/label") { |element| 
        if element && element.text.to_s && element.attributes["channel"]
          channel_names[element.attributes["channel"].to_i] = element.text.strip.to_s
        end
      }
      return channel_names
    end
  end
end