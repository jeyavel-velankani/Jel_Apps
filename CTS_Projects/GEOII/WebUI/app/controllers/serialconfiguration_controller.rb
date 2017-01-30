class SerialconfigurationController < ApplicationController
  layout "general"
  include ReportsHelper
  before_filter :setup
  
  def setup
    params[:act_type] = 'sel_val' if params[:act_type]=='' 
    @disable_signal = !logged_in?
    @type = 'sel_val'
    @channeldefault =''
    
    @base_id = 4

    if params[:act_type] == 'default'
       @channeldefault = 0
       @type='default'
     end
   if OCE_MODE == 1
        unless session[:cfgsitelocation].blank?
          (ActiveRecord::Base.configurations["development"])["database"] = session[:cfgsitelocation]+'/nvconfig.sql3'
        else
          redirect_to :controller=>"redirectpage" , :action=>"index"
        end
   end
  end
  
  def group_parameter_values(channel_id)
    @group_parameters =  [{:title =>  EnumParameter.enum_group(4, channel_id), :type =>Enum_Type },
                          {:title =>  IntegerParameter.Integer_group(1001200, channel_id), :type=> Integer_Type},
                          {:title =>  EnumParameter.enum_group(1001200, channel_id), :type =>Enum_Type }]
  end
  
  def update
    if request.xhr? && logged_in?
       unless @errors = ParameterGroup.group_parameter_values_update(params[:result]) # means no errors saving was successfull!
         text = params[:channel].to_i == 0 ? "Laptop Port" : "Port #{params[:channel]}"
         flash.now[:notice]="Successfully updated the #{text} Information"
       end
       group_parameter_values(params[:channel].to_i)
       render :partial=>"/layouts/partials/parameters_form"
    end
  end
  
   def laptop_port
     @channel = 0
     group_parameter_values(@channel)
     render :template=>'ethernet_configuration/ethernet'
  end
  
   def serial_port1
     @channel = 1
     group_parameter_values(@channel)
     render :template=>'ethernet_configuration/ethernet'
   end
 
 
   def serial_port2
     @channel = 2
     group_parameter_values(@channel)
     render :template=>'ethernet_configuration/ethernet'
   end
 
   def serial_port3
     @channel = 3
     group_parameter_values(@channel)
     render :template=>'ethernet_configuration/ethernet'
   end

   def protocol_params
    @protocol = params[:protocol]
    @gid = params[:gid]
    @gch = params[:grp_channel]
    session[:gch]=@gch
    @enumid = Subgroupvalues.sgrp_valget(@base_id, @gch, @protocol)
    @protocolid =  @enumid.map{|gid| gid.Subgroup_ID.to_i}

    session[:protocol_Groupid]=@protocolid
    @protocolvalues = IntegerParameter.protocolsub_group(@protocolid,@gch)
    @stringprotocolvalues = StringParameter.protocolsub_group(@protocolid,@gch)

    session[:protocolvalues]=@protocolvalues
    render :update do |page|
      page.replace_html  'protocoldiv', :partial=>'ethernet_configuration/protocolparams'
    end                      
  end
  
end