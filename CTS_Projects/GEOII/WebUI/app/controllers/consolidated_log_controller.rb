class ConsolidatedLogController < ApplicationController
  layout "general"
  include ReportsHelper
  before_filter :setup 
  
  def setup
    params[:act_type] = 'sel_val' if params[:act_type]=='' 
    @disable_signal = !logged_in?
    @type = 'sel_val'
    @channeldefault =''
    #Initialized to have access to config_left_menu js file in programming pages
    @load_config_event = true
    if params[:act_type] == 'default'
       @channeldefault = 0
       @type='default'
   end
   
   if OCE_MODE == 1
        unless session[:cfgsitelocation].blank?
            (ActiveRecord::Base.configurations["development"])["database"] = session[:cfgsitelocation]+'/nvconfig.sql3'
        else 
          session[:error] = "Please create/open the configuration from the configuration editor page and try again"
          redirect_to :controller=>"redirectpage" , :action=>"index"
        end
    end
  end
  
  def index
    @group_parameters =  [{:title =>  IntegerParameter.Integer_group(Consolidated_Event_Group, Consolidated_Event_Group_Channel), :type=> Integer_Type},
                          {:title =>  EnumParameter.enum_group(Consolidated_Event_Group, Consolidated_Event_Group_Channel), :type =>Enum_Type },
                          {:title =>  StringParameter.string_group(Consolidated_Event_Group, Consolidated_Event_Group_Channel), :type =>String_Type }]
  end
  
  def update
    if request.xhr? && logged_in?
       unless @errors = ParameterGroup.group_parameter_values_update(params[:result]) # means no errors saving was successfull!
         flash.now[:notice]="Successfully updated the Consolidate Event Log Information"
       end
       @group_parameters =  [{:title =>  IntegerParameter.Integer_group(Consolidated_Event_Group, Consolidated_Event_Group_Channel), :type=> Integer_Type},
                             {:title =>  EnumParameter.enum_group(Consolidated_Event_Group, Consolidated_Event_Group_Channel), :type =>Enum_Type },
                             {:title =>  StringParameter.string_group(Consolidated_Event_Group, Consolidated_Event_Group_Channel), :type =>String_Type }]

        render :partial=>"/layouts/partials/parameters_form"
    end
  end
  
end
