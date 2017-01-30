class GcpProgrammingController < ApplicationController
  require 'json'
  require 'yaml'
  include GcpProgrammingHelper
  include GenericHelper
  include McfHelper
  include ExpressionHelper
  include ReportsHelper
  include SessionHelper
  require "rexml/document" 
  include REXML

  if OCE_MODE == 1
    require 'win32/registry'
    require 'win32ole'
    require 'socket'
    require 'timeout'
    require 'zip/zipfilesystem'
    require 'zip/zip'
  end

  layout "general"

  #before_filter :cpu_status_redirect_local     #filter method is a local
  before_filter :get_gcp_type, :only => [:index, :page_parameters, :check_update_req_state,:check_update_req_state_remotesin, :update_remote_sin_4k, :track_setup , :check_user_presence_request_state]

  def cpu_status_redirect_local
    @url_cpu = request.url
    @url_cpu = @url_cpu.split(params[:controller])
    @url_cpu  = @url_cpu[1]
    if @url_cpu != nil
      @url_cpu = @url_cpu.split('?')
      @method_cpu = @url_cpu[0]
    else
      @method_cpu = @url_cpu
    end

    #will allow the nav to be built still and the sear pages to be built

    if(!request.xhr? && (@method_cpu != nil && @method_cpu != "/io_assignment" && @method_cpu !="/sear_communication" && @method_cpu !="/sear_serial_port" && @method_cpu !="/sear_set_to_default_index"))
      @redirect_flag = false
      if GCP_CPU3==1
        session = Generalststistics.find(:first,:conditions=>['stat_name="HB-DISSES"'])

        if session == nil || (session && session.stat_value == 1)
          @redirect_flag = true
          redirect_to "/sessions/display_in_session"
        end
      end
      
      if !@redirect_flag 
        @session = RtSession.find(:first, :select=>"comm_status,status")

        if(@session == nil)
          redirect_to "/sessions/cpu_out_of_session?comm_status=0&status=0"
        else
          if @session.comm_status.to_i != 1 || @session.status.to_i != 10
            @redirect_flag = true
          end
          redirect_to "/sessions/cpu_out_of_session?comm_status="+@session.comm_status.to_s+"&status="+@session.status.to_s  unless !@redirect_flag
        end
      end
    end
  end

  def index
     #Uistate.refresh_is_expr_thread_running()
    extract_menu
  end

  # method to check user session
  def check_supervisor_session
    rt_parameter = RtParameter.find_by_parameter_name("SuperPassword4",
                    :conditions => {:mcfcrc => Gwe.mcfcrc, :sin => atcs_address, :parameter_type => 2}, :select => "current_value")
    session[:supervisor] = if(rt_parameter && !params[:user][:password].blank? && (rt_parameter.current_value.to_s.strip == params[:user][:password].strip))
      true
    else
      false
    end
    redirect_to("/gcp_programming/page_parameters?page_name=#{params[:page_name]}&menu_link=#{params[:menu_link]}")
  end

  def page_parameters
    #Uistate.refresh_is_expr_thread_running()
    @ui_state =  GenericHelper.check_user_presence
    @error_field = nil
    session[:mcf_parameters] = nil
    session[:envvarmap] = {"$WebUI" => 1}
    handle_security
    $expression_mapper = {}
    if @gcp_4000_version
      #check_user_session
      @atcs_address = atcs_address
      if @supervisor_session && (session[:supervisor] == nil)
        render :template => "gcp_programming/session"
      else
        @unconfig_page = false
        #params[:menu_link] = "TEMPLATE:  selection" #if !check_vlp_state
        params[:menu_link] = params[:page_name] if params[:menu_link].blank?
        redirect_to :action => :set_to_default_index and return if(params[:menu_link] == "set_template_defaults")
        @expression_structure = {}
        # Passing 'next' as default this would ensure to navigate next page in case track/link disabled
        @page =  get_page_object(params[:menu_link], (params[:page_type].blank?)? "next":params[:page_type]) #Page.find_by_page_name(params[:menu_link])
        page, @sub_menus = get_sub_menu_4k(params[:menu_link])
        #@sub_menus = Menu.all(:conditions => ["mcfcrc = ? and page_name like ? and link not like '{%' and mtf_index = ?", gwe.mcfcrc, params[:menu_link], temp_mtf_ind], :order => 'rowid', :select => "menu_name, link, show, enable")
        if !params[:track_setup].blank?
          @cards = RtCard.fetch_track_cards
          @atcs_address = atcs_address
          card_index = (params[:card_index].blank?)? "track_setup=true":"card_index=" + params[:card_index] + "&track_setup=true"
          @page_type = '/gcp_programming/page_parameters?' + card_index
          params[:page_name] = "Track 1: Setup"
          get_parameters
          render :partial => 'form' and return if request.xhr?
        else
          get_parameters
        end
        if(@parameters.blank?)
          @sub_menus.each do |menu|
            menu_expression = eval_expression(menu.show)
            if menu_expression
              redirect_to :action => :set_to_default_index and return if(menu.menu_name == "Set Template Defaults" && menu.link == "")
            end
          end
        end
      end
    else
      @unconfig_page = false
      if !params[:track_setup].blank?
        @cards = RtCard.fetch_track_cards
        @atcs_address = atcs_address
        card_index = (params[:card_index].blank?)? "track_setup=true":"card_index=" + params[:card_index] + "&track_setup=true"
        @page_type = '/gcp_programming/page_parameters?' + card_index
        params[:page_name] = "Track #{params[:card_number]}: Setup"
        get_5k_parameters
        render :partial => 'form' if request.xhr?
      else
        #redirect_to :action => :set_to_default_index and return #if !check_vlp_state
        get_5k_parameters
      end  
    end
  end

  def set_to_default_index
    @enable, @show = false, false
    #@ui_state = Uistate.vital_user_present?(atcs_address)
    @ui_state = GenericHelper.check_user_presence
    set_template_menu = Menu.find(:first, :conditions => ["menu_name = 'Set Template Defaults' and page_name = 'TEMPLATE:  selection' "], :select => "enable, show")
    if(set_template_menu && get_exp_value(set_template_menu.show))
      handle_security
      @show = true
     @expression_structure = {}
     @enable = eval_expression(set_template_menu.enable)
    end
  end

  def non_vital_to_default
    #@ui_state = Uistate.vital_user_present?(atcs_address)
    @ui_state = GenericHelper.check_user_presence
  end

  def non_vitual_set_to_default
    #ethernet => 6,1001861,1001800
    #serial => 4,1001200
    #router => 9
    #consoledisplay => 18
    #dns => 14
    # Diagnostic Logging => 40
    # Consolidated_Verbosity_Group => 42

    group_ids = [6,1001861,1001800,4,1001200,9,18,14,40,42,TRACK_DATA_GROUP_ID]

    EnumParameter.find_by_sql("update Enum_Parameters set Selected_Value_ID = Default_Value_ID where Group_ID in (#{group_ids.join(',')})")
    StringParameter.find_by_sql("update String_Parameters set String = Default_String where Group_ID in (#{group_ids.join(',')})")
    IntegerParameter.find_by_sql("update Integer_Parameters set Value = Default_Value where Group_ID in (#{group_ids.join(',')})")

    render :text => "finished"
  end

  def link_parameter
    @menu_param_name = params[:menu_name].to_s
    if !params[:link_name].blank?
      @link_name = params[:link_name].gsub("{","").gsub("}","").downcase
    end
    @sin_value = Gwe.find(:first, :select => "sin").try(:sin) || ""
  end

  # method to set the default values
  def set_to_default
    begin
    temp_mtf_ind = 0
    gwe =  Gwe.find(:first)
    temp_mtf_ind = gwe.active_mtf_index if !gwe.mcfcrc.blank?
    # OCE-GCP SetupWizard and SEt Template page MTFINDEX value change need to update the corresponding rt_parameters table values using OCE C#.Net component
    if (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE)
      simulator = "\"#{session[:OCE_ROOT]}\\GCP_OCE_Manager.exe\", \"#{5}\" \"#{session[:cfgsitelocation]}\" \"#{session[:OCE_ROOT]}\" \"#{temp_mtf_ind}\""
      puts  simulator
      message_str = ""
      if system(simulator)
        error_log_path = "#{session[:cfgsitelocation]}+'\oce_gcp_error.log'"
        result,content = read_error_log_file(error_log_path)
        if(result == true || result == 'true')
          message_str = content
        end
        puts "------------------------------------ Set Template Defaults Pass ----------------------------"
      else
        puts "------------------------------------ Set Template Defaults Failed ----------------------------"
        message_str = "Set Template Defaults Failed"
      end
      if !message_str.blank?
        raise Exception, message_str
      end
      render :json => {:request_id => 0}
    else
      simple_request = RrSimpleRequest.new
      simple_request.request_state = ZERO
      simple_request.atcs_address = (atcs_address + ".02")
      simple_request.command = REQUEST_SET_TO_DEFAULT
      simple_request.save
  
      udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, simple_request.request_id)
      render :json => {:request_id => simple_request.request_id}
    end
     rescue Exception => e
      render :json => {:error => true, :message => e.message} and return
    end
  end

  # method to check default value request status
  def check_set_to_defaults
    if (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE)
      render :json => {:req_state => 2}
    else  
      simple_request = RrSimpleRequest.find(params[:id].to_i, :select => "request_state")
  
      if simple_request
        render :json => {:req_state => simple_request.request_state}
      else
        render :text => '<h2>Request ID not found in database!!</h2>'
      end
    end
  end

  def sear_set_to_default_index
    #@ui_state = Uistate.vital_user_present?(atcs_address)
    @ui_state = GenericHelper.check_user_presence
  end

  def sear_set_to_default
    EnumParameter.sear_set_defaults([121,122,123,129,130,131,150,170,190])
    EnumParameter.sear_set_defaults_given_channel(130, [1,2])
    render :json => { :error => false }
  end

  def update
    parameters_values = {}
    #@page = Page.find_by_page_name(params[:page_name].strip, :conditions => {:mcfcrc => MCFCRC, :cdf => 'CFGVIEWDATA.XML'})
    parameter = Parameter.find_by_mcfcrc(Gwe.mcfcrc,
                :conditions => {:cardindex => params[:card_index], :parameter_type => params[:parameter_type], :name => params[:parameter_name]})
    
    integer_parameter = parameter.integertype[0]
    #Get the metric system from the nvconfig DB
    units_measure = EnumValue.units_of_measure
    if integer_parameter != nil      
      val = check_signed_value(integer_parameter.size, params[:updated_value].to_i)
      val = (val.to_f * (1000 / integer_parameter.scale_factor.to_f)).to_i
      
      #if the measure system is METRIC, then handle accordingly
      if units_measure.Value == 1    
        unit_val =  integer_parameter.metric_unit.strip
        val = metric_to_imperial(integer_parameter, val.to_f)
      else        
        unit_val =  integer_parameter.imperial_unit.strip
      end      
    else
      val = params[:updated_value]
    end
    
    if (PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE)
      consist_id = RtConsist.last(:conditions => {:mcfcrc => Gwe.mcfcrc, :sin => atcs_address}, :select => 'consist_id').try(:consist_id)
      card_info = RtCardInformation.find_by_consist_id_and_card_index(consist_id, params[:card_index])
      card = Card.find(:first, :select => 'pci_ci', :conditions => {:card_index => params[:card_index], :crd_type => card_info.card_type, :mcfcrc => Gwe.mcfcrc})
    
      data_kind = parameter_type_to_data_kind(params[:parameter_type])
      parameters_values = {}
      property_request = SetCfgPropertyRequest.new
      property_request.request_state = 0
      property_request.atcs_address = atcs_address + '.02'
      property_request.command = 0
      property_request.subcommand = 0
      property_request.card_type = card_info.card_type
      property_request.card_index = params[:card_index]
      property_request.data_kind = data_kind
      property_request.parameter_type = params[:parameter_type]
      property_request.parameter_name = params[:param_long_name]
      property_request.property_index = params[:parameter_index]
      if data_kind == 6 || data_kind == 7
        property_request.slot_or_atcs_device_no = 0
        property_request.slave_kind = 0
        property_request.pci_ci = 1
      else
        property_request.slot_or_atcs_device_no = card_info.slot_atcs_devnumber
        property_request.slave_kind = card_info.slave_kind
        property_request.pci_ci = card.pci_ci
      end
      property_request.text_value = (parameter.data_type == 'Enumeration') ? params[:updated_name] : params[:updated_value]
      property_request.context_string = parameter.context_string.strip
      property_request.unit = unit_val
      property_request.value = val
      property_request.save
    end
    
    # Added code to fix reporting of old/new value in Maint log
    if(parameter.data_type == 'Enumeration')
      old_value_name = parameter.getEnumerator(params[:current_value])
      new_value_name = parameter.getEnumerator(val)
    else
      # data_type = Integertype
      old_value_name = params[:current_value].to_s
      new_value_name = val.to_s
    end

    # Get page parameters
    page_parameters = Page.find(:all, :conditions => {:page_name    => params[:page_name],
                                                        :mcfcrc       => parameter.mcfcrc,
                                                        :layout_index => parameter.layout_index,
                                                        :layout_type  => parameter.layout_type})

    # Populate values used for maintaince logging.
    parameters_values[parameter.name] = {:card_index      => parameter.cardindex,
                                         :param_type      => parameter.parameter_type,
                                         :param_index     => parameter.parameter_index,
                                         :new_value       => val,
                                         :old_value       => params[:current_value],
                                         :context_string  => parameter.context_string ,
                                         :param_long_name => parameter.param_long_name,
                                         :old_value_name  => old_value_name,
                                         :new_value_name  => new_value_name}

    if (PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE)
      udp_send_cmd(REQUEST_COMMAND_SET_PARAMETER, property_request.request_id)
      render :json => {:error => false, :request_id => property_request.request_id, :parameters_values => parameters_values }
    else
      render :json => {:error => false, :request_id => 0, :parameters_values => parameters_values }
    end
  end

def update_remote_sin_4k
  parameters_values = {}
  update_value = 0
  old_value = 0
  update_flag = false
  
  #sin_params = PageParameter.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :page_name => params[:page_name], :card_index=> params[:card_index]}, :order => 'display_order')
  
  remote_sin = params[:updated_value].split('.')
  current_sin = params[:current_value].split('.')
  atcs_sin = params[:atcs_sin].split('.')
  
  sin_params = PageParameter.all(:conditions => ["mcfcrc = ? and page_name = ? and card_index = ? and parameter_name Like \'%offset\'", Gwe.mcfcrc, params[:page_name], params[:card_index]], :order => 'display_order')
  parameters_values = {}
  sin_params.each do |sin_offset|
    update_flag = false
    if (sin_offset[:parameter_name].to_s.downcase == "rrroffset")
      if (remote_sin[1].to_i != current_sin[1].to_i)
        update_flag = true
        update_value = remote_sin[1].to_i -  atcs_sin[1].to_i
        old_value = current_sin[1].to_i -  atcs_sin[1].to_i
      end
    elsif (sin_offset[:parameter_name].to_s.downcase == "llloffset")
      if (remote_sin[2].to_i != current_sin[2].to_i)
        update_flag = true
        update_value = remote_sin[2].to_i -  atcs_sin[2].to_i
        old_value = current_sin[2].to_i -  atcs_sin[2].to_i
      end
    elsif (sin_offset[:parameter_name].to_s.downcase == "gggoffset")
      if (remote_sin[3].to_i != current_sin[3].to_i)
        update_flag = true
        update_value = remote_sin[3].to_i -  atcs_sin[3].to_i
        old_value = current_sin[3].to_i -  atcs_sin[3].to_i
      end
    elsif (sin_offset[:parameter_name].to_s.downcase == "ssoffset")
      if (remote_sin[4].to_i != current_sin[4].to_i)
        update_flag = true
        update_value = remote_sin[4].to_i -  atcs_sin[4].to_i
        old_value = current_sin[4].to_i -  atcs_sin[4].to_i
      end
    end
    
    if update_flag
      parameter = Parameter.find_by_mcfcrc(Gwe.mcfcrc,
                   :conditions => {:cardindex => params[:card_index], :parameter_type => sin_offset[:parameter_type], :name => sin_offset[:parameter_name]})
      
      integer_parameter = parameter.integertype[0]
      data_kind = parameter_type_to_data_kind(sin_offset[:parameter_type])
      if (PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE)
        consist_id = RtConsist.last(:conditions => {:mcfcrc => Gwe.mcfcrc, :sin => atcs_address}, :select => 'consist_id').try(:consist_id)
        card_info = RtCardInformation.find_by_consist_id_and_card_index(consist_id, params[:card_index])
        card = Card.find(:first, :select => 'pci_ci', :conditions => {:card_index => params[:card_index], :crd_type => card_info.card_type, :mcfcrc => Gwe.mcfcrc})
        property_request = SetCfgPropertyRequest.new
        property_request.request_state = 0
        property_request.atcs_address = atcs_address + '.02'
        property_request.command = 0
        property_request.subcommand = 0
        property_request.card_type = card_info.card_type
        property_request.card_index = params[:card_index]
        property_request.data_kind = data_kind
        property_request.parameter_type = sin_offset[:parameter_type]
        property_request.parameter_name = parameter.param_long_name
        property_request.property_index = parameter.parameter_index + 1
        if data_kind == 6 || data_kind == 7
          property_request.slot_or_atcs_device_no = 0
          property_request.slave_kind = 0
          property_request.pci_ci = 1
        else
          property_request.slot_or_atcs_device_no = card_info.slot_atcs_devnumber
          property_request.slave_kind = card_info.slave_kind
          property_request.pci_ci = card.pci_ci
        end
        property_request.text_value = update_value
        property_request.context_string = parameter.context_string.strip

        if integer_parameter != nil
          property_request.unit =  integer_parameter.imperial_unit.strip
          val = check_signed_value(integer_parameter.size, update_value.to_i)
          val = (val.to_f * (1000 / integer_parameter.scale_factor.to_f)).to_i
        else
          val = update_value
        end
        property_request.value = val
        property_request.save
      else
        if integer_parameter != nil
          val = check_signed_value(integer_parameter.size, update_value.to_i)
          measurement = integer_parameter.imperial_unit.strip
          new_value = params[parameter.name]
          val = (val.to_f * (1000 / integer_parameter.scale_factor.to_f)).to_i
        end
      end
      parameters_values[parameter.name] = {:card_index => parameter.cardindex, :param_type => parameter.parameter_type,
                             :param_index => parameter.parameter_index, :new_value => val, :old_value => old_value}
    end
  end 
  
  if (PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE)
    udp_send_cmd(REQUEST_COMMAND_SET_PARAMETER, property_request.request_id)
    render :json=> {:error => false, :request_id => property_request.request_id, :parameters_values => parameters_values }
  else
    render :json=> {:error => false, :request_id => 0, :parameters_values => parameters_values }
  end      
end
    
def check_update_req_state_remotesin
  parameters_values = params[:parameters_values]
  if PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE
    setcfgproprq = SetCfgPropertyRequest.find_by_request_id(params[:req_id])
    if(setcfgproprq.request_state == 2)
      parameters_values.each do |offset|
        RtParameter.update_all("current_value = #{offset[1][:new_value].to_i}", :mcfcrc => Gwe.mcfcrc, :card_index => offset[1][:card_index].to_i,
                               :parameter_type => offset[1][:param_type].to_i, :parameter_index => offset[1][:param_index].to_i)
      end
      session[:mcf_parameters] = nil
      page, @sub_menus = get_sub_menu_4k(params[:menu_link])
      @atcs_address = atcs_address
      #@sub_menus = Menu.all(:conditions => {:page_name => params[:menu_link]}, :order => 'rowid', :select => "menu_name, link, show, enable")
      @expression_structure = {}
      get_parameters
      render :json => {:error => (setcfgproprq.confirmed == 0 )? false : true,:request_state => 2,  :html => render_to_string(:partial => "form")}
    else
      render :json => {:req_state => setcfgproprq.request_state }
    end
  else
    parameters_values.each do |offset|
      RtParameter.update_all("current_value = #{offset[1][:new_value].to_i}", :mcfcrc => Gwe.mcfcrc, :card_index => offset[1][:card_index].to_i,
                               :parameter_type => offset[1][:param_type].to_i, :parameter_index => offset[1][:param_index].to_i)
    end
    session[:mcf_parameters] = nil
    page, @sub_menus = get_sub_menu_4k(params[:menu_link])
    @atcs_address = atcs_address
    #@sub_menus = Menu.all(:conditions => {:page_name => params[:menu_link]}, :order => 'rowid', :select => "menu_name, link, show, enable")
    @expression_structure = {}
    get_parameters
    render :json => {:error => false,:request_state => 2,  :html => render_to_string(:partial => "form")}    
  end
end
  # method to update GCP-5k parameters
  def update_parameters
    render :json  => save_page_parameters(params)
  end

  # to save parameters using setCfgProperty request
  def save_page_parameters (params)
    begin
    number_of_cards, number_of_params = 0, 0
    param_change_count = 0
    prop_card_id = nil
    parameters_values = {}
    updated_values = []
    templateSelected = 0
    
    gwe = Gwe.get_mcfcrc(atcs_address)
    if gwe.blank?
      gwe = Gwe.find(:first)
    end
    current_mcfcrc = gwe.mcfcrc
    current_phy_layout = gwe.active_physical_layout || 0
    current_mtf_index = gwe.active_mtf_index || 0
    
    get_parameters
    
      units_measure = EnumValue.units_of_measure
      if ((params[:page_name].to_s == "TEMPLATE:  selection") || (params[:menu_link].to_s == "TEMPLATE:  selection"))
        if !params[:MTFIndex].blank? && ((PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE ) && (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP")))          
          selected_mtfindex = params[:MTFIndex].to_i
          if (current_mtf_index != selected_mtfindex)
            simulator = "\"#{session[:OCE_ROOT]}\\GCP_OCE_Manager.exe\", \"#{5}\" \"#{session[:cfgsitelocation]}\" \"#{session[:OCE_ROOT]}\" \"#{selected_mtfindex}\""
            puts  simulator
            message_str = ""
            if system(simulator)
              error_log_path = "#{session[:cfgsitelocation]}+'\oce_gcp_error.log'"
              result,content = read_error_log_file(error_log_path)
              if(result == true || result == 'true')
                 message_str = content
              end
              puts "------------------------------------ Setup Wizard Pass ----------------------------"
            else
              puts "------------------------------------ Setup Wizard Failed ----------------------------"
              message_str = "Decompress Failed"
            end
            if !message_str.blank?
              raise Exception, message_str
            end
          end
        end
      end
      @page_parameters.each do |page_parameter|
        next if page_parameter.blank?
        parameter = @parameters["#{page_parameter.card_index}.#{page_parameter.parameter_name.strip}"]
        if(parameter)
          if (parameter.name.downcase == "predsys")
            param_name = parameter.name
          else
            param_name = parameter.name + "_" + parameter.cardindex.to_s  
          end
          integertype = parameter.integertype[0]
          curval = get_current_value(parameter)
          newval = params[param_name]
          unitstr = ""
          old_value_name = ""
          new_value_name = ""
          measurement = ""
          unless integertype.blank?
            unit_imp = integertype.imperial_unit
            if((units_measure.Value == 1) && (!unit_imp.blank?))      
              unitstr =  integertype.metric_unit.strip
              newval = metric_to_imperial(integertype,  params[param_name].to_i)
            else
              unitstr = integertype.imperial_unit.strip
            end
          end
          next if ((params[param_name] == nil) || (curval.to_i == newval.to_i))
          number_of_params += 1
          param_change_count += 1
          
          if integertype != nil
            newval = check_signed_value(integertype.size, newval.to_i)
            measurement = integertype.imperial_unit.strip
            old_value_name = curval
            new_value_name = params[param_name]
          end
          
          if(parameter.data_type == "IntegerType")
            if integertype.signed_number.to_s == 'Yes' && newval < 0
              factor = 1
              unless integertype.nil?
                factor = (integertype.scale_factor.to_f / 1000).to_f
              end
              factor_value = (newval.abs.to_f * factor).to_f
              value = get_dispsigned_value(factor_value, integertype.size)
            else
              value = scale_down_value(newval, integertype)
            end
          else
            value = newval
          end
          RtParameter.update_all("current_value = #{value.to_i}", :mcfcrc => parameter.mcfcrc, :card_index => parameter.cardindex,
                              :parameter_type => parameter.parameter_type, :parameter_index => parameter.parameter_index)
          
        end   #if(parameter)
      end    
    return {:error => false, :request_id => 0, :parameters_values => ""}
     rescue Exception => e
      return{:error => true, :error_msg => e.message}
    end
  end

  # method to check request for GCP-5k parameters
  # confirmed = 400 means no change
  def check_update_state
    @parameters = {}
    @expression_structure = {}
    if PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE
      setcfgproprq = SetCfgPropertyiviuRequest.find_by_request_id(params[:id])
      if(setcfgproprq && setcfgproprq.request_state == 2)
        @parameters = {}
        @expression_structure = {}
        result = false
        error_msg = ""
        if(setcfgproprq.confirmed != 400)
          result, error_msg = update_rt_parameter(params[:parameters_values].to_json) if setcfgproprq.confirmed == 0
        end
        get_parameters
        render :json => {:error => (setcfgproprq.confirmed == 0 || setcfgproprq.confirmed == 400 || result) ? false : true, :request_state => setcfgproprq.request_state , :html => render_to_string(:partial => "form"), :error_msg => error_msg}        
      else
        render :json => { :request_state => setcfgproprq.request_state }
      end
    else
      #result, error_msg = update_rt_parameter(params[:parameters_values].to_json)
      @atcs_address = atcs_address
      get_gcp_type
      page, @sub_menus = get_sub_menu_4k(params[:menu_link])
      get_parameters
      render :json => {:error =>  false , :request_state => 2 , :html => render_to_string(:partial => "form"), :error_msg => error_msg}
    end
  end

  def check_user_presence
    @user_presence = GenericHelper.check_user_presence
    render :text => @user_presence
  end

  # method to set parameters edit mode/requesting user presence
  def request_user_presence
    sin = atcs_address

    if sin == nil
      sin = '7.000.000.000.00'
    end
    ui_state = GenericHelper.check_user_presence
    unless(ui_state)
      request_id = set_user_presence(sin)
      render :json => {:user_presence => false, :request_id => request_id, :atcs_address => sin}
    else
      render :json => {:user_presence => true, :message => "Parameters already unlocked"}
    end
  end

  # method to check user presence state
  def check_user_presence_request_state
    simple_request = RrSimpleRequest.find_by_request_id(params[:request_id], :select => "request_id, request_state, result")
    if simple_request.request_state == 2
      ui_state = GenericHelper.check_user_presence #Uistate.vital_user_present?(params[:atcs_address])
      if @gcp_4000_version && params[:outside_request].blank?
        sin = atcs_address

        if sin == nil
          sin = '7.000.000.000.00'
        end
        
        @expression_structure = {}
        @page, @sub_menus = get_sub_menu_4k(params[:menu_link])
        @atcs_address = sin
        get_parameters if params[:outside_request].blank?
      else
        params[:page_name] = params[:menu_link]
        params[:user_presence_req] = true
        get_5k_parameters if params[:outside_request].blank?
      end

      user_presence = ui_state ? (simple_request.result == 0 ? true : false) : false
      message = if params[:outside_request].blank?
        @expression_structure = {}
        user_presence ? "Successfully unlocked parameters" : "Unlock parameters failed"
      else
        user_presence ? "Successfully unlocked" : "Unlocking failed"
      end
      parameters_form = ''
      @ui_state = GenericHelper.check_user_presence #Uistate.vital_user_present?(sin)
      parameters_form = render_to_string(:partial => 'form') if user_presence && params[:outside_request].blank?
      render :json => {:request_state => simple_request.request_state, :user_presence => user_presence, :message => message, :parameters_form => parameters_form}
    else
      render :json => {:request_state => simple_request.request_state}
    end
  end

  # method to verify screen parameters
  def verify_screen
    if Gwe.gcp_4000?
      @page = Page.find_by_page_name_and_mcfcrc(params[:menu_link], Gwe.mcfcrc)
      screen_index = 0
      if(@page && @page.page_group == "template")
        gwe = Gwe.get_mcfcrc(atcs_address)
        # first get template of active_mtf_index
        sel_template = Page.find(:first, :conditions => ["page_group = ? and mcfcrc = ? and mtf_index = ? and page_name = ?", "template", Gwe.mcfcrc, gwe.active_mtf_index, params[:menu_link]])
        # if active template not available then try to get common template
        if(sel_template.nil?)
          sel_template = Page.find(:first, :conditions => ["page_group = ? and mcfcrc = ? and mtf_index = ? and page_name = ?", "template", Gwe.mcfcrc, 0, params[:menu_link]])
        else
          max_page_index = Page.maximum("page_index", :conditions => ["mcfcrc = ? and mtf_index = 0", Gwe.mcfcrc])
          screen_index = max_page_index + 1 if max_page_index && gwe.active_mtf_index != 0
        end
        mtf_index = (sel_template.nil?)? 0:sel_template.mtf_index
        @page_parameters = PageParameter.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :page_name => params[:menu_link], :mtf_index => mtf_index}, :order => 'display_order')
      else
        @page_parameters = PageParameter.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :page_name => params[:menu_link]}, :order => 'display_order')
      end
      @mcf_parameters = Parameter.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :cardindex => @page_parameters.map(&:card_index).uniq, :name => @page_parameters.map(&:parameter_name), :parameter_type => @page_parameters.map(&:parameter_type).uniq})
      screen_request = VerifyScreenRequest.initiate_verify_request((atcs_address + '.02'), @page, screen_index)
      screen_request_id = screen_request.request_id
      @sub_menus = Menu.all(:conditions => {:page_name => @page.page_name, :mcfcrc => Gwe.mcfcrc}, :order => 'rowid', :select => "menu_name, link, mtf_index")
      @atcs_address = atcs_address
      screen_verification_for_4k(screen_request, screen_request_id)
      render :text => screen_request_id
    else
      @page = Page.find_by_page_name_and_mcfcrc(params[:menu_link], Gwe.mcfcrc)
      # get active mtf_index for template pages
      if(@page && @page.page_group == "template")
        sel_template = get_active_template(params[:menu_link])
        mtf_index = (sel_template.blank?)? 0:sel_template.mtf_index
        @page_parameters = PageParameter.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :page_name => params[:page_name], :mtf_index => mtf_index},
                       :order => 'display_order')
        @mcf_parameters = Parameter.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :cardindex => @page_parameters.map(&:card_index).uniq,
                         :name => @page_parameters.map(&:parameter_name), :parameter_type => @page_parameters.map(&:parameter_type).uniq})
      else
        @page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and page_name = ? and target NOT LIKE 'LocalUI'",Gwe.mcfcrc, params[:page_name]] ,
                           :order => 'display_order')
        @mcf_parameters = Parameter.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :cardindex => @page_parameters.map(&:card_index).uniq,
                         :name => @page_parameters.map(&:parameter_name), :parameter_type => @page_parameters.map(&:parameter_type).uniq})
      end
      number_of_parameters = evalute_showhide_exp(@page_parameters)
      screen_iviu_request = VerifyScreenIviuRequest.initiate_verify_request(atcs_address, number_of_parameters)
      screen_verification_for_5k(screen_iviu_request)
      render :text => screen_iviu_request.request_id
    end
  end

  def load_template_details
    template = Template.get_template(params[:mtf_index])
    render :partial => 'template_details', :locals => {:template => template}
  end

  def setup_wizard
    @expression_structure = {}
    @templates_list = []
    @selected_template = nil
    first_menu_link = nil
    gwe =  Gwe.find(:first)
    # get first menu link
    first_menu_link = Page.find(:first, :conditions => ["page_group = ? and mcfcrc = ? and page_name like '%TEMPLATE:%' and page_name like '%selection%'", "template", gwe.mcfcrc])
    # get first template of active_mtf_index
    next_template = Page.find(:first, :conditions => ["page_index = 0 and page_group = ? and mcfcrc = ? and mtf_index = ? ", "template", gwe.mcfcrc, gwe.active_mtf_index])
    if(next_template.nil? || (first_menu_link && next_template.page_name != first_menu_link.page_name))
      if first_menu_link && eval_expression(first_menu_link.enable)
        @templates_list << first_menu_link
        @selected_template = first_menu_link
        first_template_page_name = first_menu_link.page_name
      end
    end
    if next_template && eval_expression(next_template.enable)
      @templates_list << next_template
      if(@selected_template.nil?)
        @templates_list << next_template
        @selected_template = next_template
        first_template_page_name = next_template.page_name
      end
    end
    while (next_template && next_template.next != first_template_page_name)
      #get ative template
      tmp_template = Page.find(:first, :conditions => ["page_group = ? and mcfcrc = ? and mtf_index = ? and page_name = ?", "template", gwe.mcfcrc, gwe.active_mtf_index, next_template.next])
      #if active template not available get common template with mtf_index 0
      if(tmp_template.nil?)
        next_template = Page.find(:first, :conditions => ["page_group = ? and mcfcrc = ? and mtf_index = ? and page_name = ?", "template", gwe.mcfcrc, 0, next_template.next])
      else
        next_template = tmp_template
      end
      expression = eval_expression(next_template.enable) if next_template
      @templates_list << next_template if expression
    end
    params[:setup_wizard] = true
  end

  def string_validator(rec_id, value)
    if string_param = StringParameter.find_by_ID(rec_id)
      string_type = string_param.string_type
      min = string_type.Min_Length
      max = string_type.Max_Length
      mask = string_type.Format_Mask
      errors = []
      unless (value.length >= min && value.length <= max)
        return "string_#{rec_id} => Should be of #{min} to #{max} Characters"
      end
      return ""
    end
  end

  def integer_validator(rec_id, value)
    if (int_param = IntegerParameter.find_by_ID(rec_id))
      int_value = value
      int_type = int_param.int_type
      min = int_type.Min_Value
      max = int_type.Max_Value

      if value && int_type.Format_Mask.match('H:') #The hexadecimal validation!
        int_value = value.hex.to_s
        txt = " In conversion to Hexadecimal"
        unless value.match(/^-{0,1}[a-fA-f0-9]*?$/)
          return "integer_#{rec_id} => Should be in Hexadecimal format"
        end
      end

      unless int_value.match(/^-{0,1}\d*\.{0,1}\d+$/) && (int_value.to_i >= min && int_value.to_i <= max)
        return "integer_#{rec_id} => Should be in the numeric Range of (#{min} to #{max})#{txt}"
      end
      return ""
    end
  end

  # Saves the displayed fields/attributes
  def io_assignment_update
    error_msg = []
    if params["string"] != nil
      params["string"].each_with_index do |p, i|
        error = string_validator(p[0],p[1])
        error_msg << error if error.length > 0
      end
    end
    if params["integer"] != nil
      params["integer"].each_with_index do |p, i|
        error = integer_validator(p[0],p[1])
        error_msg << error if error.length > 0
      end
    end

    #puts "Error: " + @errors.inspect
    if (error_msg.blank?)
      if params[:first_field_id]!= nil && params[:first_field_id] != '' && params[:algorithm_option] != nil && params[:algorithm_option] != ''
        enum_param = EnumParameter.find_by_ID(params[:first_field_id].to_i) if params[:first_field_id] != ''

        EnumParameter.update_all("Selected_Value_ID = "+params[:algorithm_option].to_s,"ID = "+ params[:first_field_id].to_s)

      end
      if request.xhr? && logged_in?
        int_updated_value = IntegerParameter.update_io_assignment_parameters(params["integer"]) if params["integer"]
        str_updated_value = StringParameter.update_io_assignment_parameters(params["string"]) if params["string"]
        enum_updated_value = EnumParameter.update_io_assignment_parameters(params["enum"]) if params["enum"]
        
        render :text => "Parameters updated successfully..."

      end
    else
      msg = "<h3>" + error_msg.length.to_s + " parameter(s) failed to save:</h3>"
      msg = msg + "<ul>"
      error_msg.each do |err|
        msg =  msg + "<li>" + err + "</li>"
      end
      msg = msg + "</ul>"
      render :text => msg
    end
  end

  # To get group parameter values for given Group_Channel & sub_group_ID
  def get_subgroups(channel_id,io_assignment_id)
    subgroup_params = Subgroupparameters.find_by_Group_Channel_and_Group_ID(channel_id,io_assignment_id)
    if subgroup_params != nil
      enum_param = EnumParameter.find_by_ID(subgroup_params.Enum_Param_ID) if subgroup_params.Enum_Param_ID > 0
      @enum_param_selected_value = enum_param.Selected_Value_ID
      sub_group_id = Subgroupvalues.find_by_ID_and_Enum_Value_ID(subgroup_params.ID,enum_param.Selected_Value_ID)
      group_parameter_values(channel_id,sub_group_id.Subgroup_ID) if sub_group_id
    else
      group_parameter_values(channel_id,io_assignment_id)
    end
  end

  # Fetches the group parameters to display onto UI based on tabs selected
 def io_assignment
    @number_per_page = 16
    # For tab selection
    @selected_type = params[:selected_value] || 'selected_value'

    if params[:page_type]
      @page_type = params[:page_type]
    else
      @page_type = 'digital_inputs'
    end

    @channel_names = nil
    # For selecting the constants as per the tab selected
    case params[:page_type]
      when 'digital_inputs'
      io_assignment_id = IO_ASSIGNMENT_DIGITAL_INPUTS
      @channel_names = SearDigitalinput.paginate(:all, :select => "chan_name,name,channel",:order =>"channel", :page => params[:page], :per_page => @number_per_page )
      when 'analog_inputs'
      io_assignment_id = IO_ASSIGNMENT_ANALOG_INPUTS
      @channel_names = SearAnaloginput.paginate(:all, :select => "chan_name,name,channel",:order =>"channel", :page => params[:page], :per_page => @number_per_page )
      when 'non_vital_outputs'
      io_assignment_id = IO_ASSIGNMENT_NONVITAL_OUTPUTS
      @channel_names = SearDigitaloutput.paginate(:all, :select => "chan_name,name,channel",:order =>"channel", :page => params[:page], :per_page => @number_per_page )
    else
      io_assignment_id = 121
      @channel_names = SearDigitalinput.paginate(:all, :select => "chan_name,name,channel",:order =>"channel", :page => params[:page], :per_page => @number_per_page )
    end


    # To display the channels and its Name & Tag values
    if params[:page]
      channel_id = 16 * (params[:page].to_i - 1)
    else
      channel_id = 0
    end
    @channel_id = channel_id
    group_id = 0
    group_id = io_input_channel(io_assignment_id, channel_id,nil)
    
    @input_channels = StringParameter.paginate(:all, :select => "Group_Channel, Name, String", :conditions=>["Group_ID = #{group_id} AND (Name LIKE 'Name')"], :page => params[:page], :per_page => 16 )

    @page_channels = []
    str_params = {}
    prev_channel = -1
    @input_channels.each do |chn|
      if (chn.Group_Channel != prev_channel)
        str_params["Group_Channel"] = chn.Group_Channel
        str_params[chn.Name] = chn.String
      else
        str_params[chn.Name] = chn.String
        @page_channels << str_params
        str_params = {}
      end
      prev_channel = chn.Group_Channel
    end
  end

  def get_io_assignment_template
    io_type = params[:type]
    options = ''

    xml_file = "/usr/safetran/conf/config_templates.xml"
   
    if File.exist?(xml_file)
      doc = Document.new File.new(xml_file)

      if io_type == 'digital_inputs'

          if params[:discrete] == 'true'
            doc.elements.each("SEAR_Templates/io_type[@ID='digital_inputs']/algorithm[@ID='Discrete']/DataSet") { |element| 
              options += '<option tag="'+element.attributes["tag"] +'" off_state_name="'+element.attributes["off_state_name"] +'" on_state_name="'+ element.attributes["on_state_name"] +'">'+element.attributes["name"] +'</option>';
            }     
          end

          if params[:mtss] == 'true'
            doc.elements.each("SEAR_Templates/io_type[@ID='digital_inputs']/algorithm[@ID='MTSS']/DataSet") { |element| 
              options += '<option tag="'+element.attributes["tag"] +'" off_state_name="'+element.attributes["off_state_name"] +'" on_state_name="'+ element.attributes["on_state_name"] +'">'+element.attributes["name"] +'</option>';
            } 
          end 

          if params[:gft] == 'true'
            doc.elements.each("SEAR_Templates/io_type[@ID='digital_inputs']/algorithm[@ID='GFT']/DataSet") { |element| 
              options += '<option tag="'+element.attributes["tag"] +'" off_state_name="'+element.attributes["off_state_name"] +'" on_state_name="'+ element.attributes["on_state_name"] +'">'+element.attributes["name"] +'</option>';
            } 
          end

      elsif io_type == 'non_vital_outputs'
        doc.elements.each("SEAR_Templates/io_type[@ID='non_vital_outputs']/algorithm[@ID='Not_Applicable']/DataSet") { |element| 
            options += '<option tag="'+element.attributes["tag"] +'" off_state_name="'+element.attributes["off_state_name"] +'" on_state_name="'+ element.attributes["on_state_name"] +'">'+element.attributes["name"] +'</option>';
        } 
      end

      if options != ''
        render :text => options
      else
        render :text => 'no options'
      end
    else
      render :text => 'no file'
    end
  end

  def io_input_channel(parent_id, channel_id, algorithm_id)
    group_id = 0
    subGroup_id = 0

    parameter_group_object = ParameterGroup.find_by_Parent_Group_ID_and_Group_Channel(parent_id,channel_id)
    if (!parameter_group_object.blank?)
      group_id = parameter_group_object.ID
      subgroup_params = Subgroupparameters.find_by_Group_Channel_and_Group_ID(channel_id,parent_id)

      @first_field_options = []
      @first_field_option_ids = []
      @first_field = EnumParameter.find_by_ID(subgroup_params.Enum_Param_ID)

      #algorithm_id is used only when the user changes the drop down
      if @algorithm_id != nil
        selected_id = algorithm_id
      else
        selected_id = @first_field.Selected_Value_ID
      end

      sub_group_id = Subgroupvalues.find(:first,:conditions=>["ID = ? and Enum_Value_ID = ?",subgroup_params.ID,selected_id])

      if sub_group_id != nil
        subGroup_id = sub_group_id.Subgroup_ID
      else
        subGroup_id =  parameter_group_object.ID
      end

      enum_values = EnumToValue.find_all_by_Param_ID(@first_field.ID)
      enum_values.each do |enum|
        @first_field_options += EnumValue.find_all_by_ID(enum.Value_ID)
      end
    else
      group_id = parent_id
      subGroup_id  = parent_id
    end
      group_parameter_values(channel_id,subGroup_id)

    return group_id
  end

  def get_io_input_channel

    @algorithm_id = params[:Algorithm]


    @selected_type = params[:selected_value] || 'selected_value'
    if params[:page_type]
      @page_type = params[:page_type]
    else
      @page_type = 'digital_inputs'
    end

    # For selecting the constants as per the tab selected
    case params[:page_type]
      when 'digital_inputs'
      io_assignment_id = IO_ASSIGNMENT_DIGITAL_INPUTS
      when 'analog_inputs'
      io_assignment_id = IO_ASSIGNMENT_ANALOG_INPUTS
      when 'non_vital_outputs'
      io_assignment_id = IO_ASSIGNMENT_NONVITAL_OUTPUTS
    else
      io_assignment_id = 121
    end

    # To display the channels and its Name & Tag values
    if params[:channel_id]
      channel_id = params[:channel_id]
    else
      channel_id = 0
    end
    @channel_id = channel_id
    group_id = 0
    group_id = io_input_channel(io_assignment_id, channel_id, @algorithm_id)
    io_input_content = render_to_string(:partial => 'io_assign_details')

    render :json => { :io_input_content => io_input_content}
  end


  def echelon_modules

  end

  def essr_radio_settings
    if request.xhr?
        params[:channel] = (params[:channel] || "0")
        @modules = ParameterGroup.find(:all, :conditions => ["ID = ?", 49])
        @group_parameters =  group_parameter_values(params[:channel].to_i, 49)
        render :partial => 'essr_radio_settings'
    else
      @atcs_address = atcs_address
      @page_type = '/gcp_programming/essr_radio_settings'
      @group_channels = ParameterGroup.find(:all, :conditions => ["ID = ?", 49])
      render :template => 'gcp_programming/essr_radio_settings_index'
    end
  end

  def essr_parameters
    @selected_type = params[:selected_value] || 'selected_value'
    params[:channel] = (params[:channel] || "0")
    @modules = ParameterGroup.find(:all, :conditions => ["ID = ?", 49])
    @group_parameters =  group_parameter_values(params[:channel].to_i, 49)
    render :partial => 'essr_parameters'
  end

  def update_essr_parameters
   if request.xhr? && logged_in?
      if request.xhr? && logged_in?
        int_updated_value = IntegerParameter.update_io_assignment_parameters(params["integer"])
        str_updated_value = StringParameter.update_io_assignment_parameters(params["string"])
        enum_updated_value = EnumParameter.update_io_assignment_parameters(params["enum"])
        if int_updated_value || str_updated_value || enum_updated_value
          render :text => "Parameters updated successfully.."
        else
          render :nothing => true
        end
      end
   end
 end

  # GCP 5K SEAR Programming - Communication page
  def sear_communication
    @channel_id = 0

    enum_name = EnumValue.find_by_sql("select Enum_Values.Name from Enum_Values join Enum_To_values on Enum_Values.ID = Enum_To_values.Value_ID where param_ID = 1026 and value_id = (select Selected_Value_ID from Enum_parameters where group_ID = 129)")
    enum_name = enum_name[0]['Name']

    subgroup_ID = ParameterGroup.find_by_sql("select ID from Parameter_Groups where Parent_Group_ID = 129  and Group_Name like '%#{enum_name}'")

    parameters = ( EnumParameter.enum_group(129,@channel_id)+ IntegerParameter.Integer_group(129, @channel_id) + StringParameter.string_group(129, @channel_id)).sort_by &:DisplayOrder


      @group_parameters = []
      parameters.each do |p|
        if(p.class == EnumParameter)
          @group_parameters << {:title => [p], :type => Enum_Type}
        elsif(p.class == IntegerParameter)
          @group_parameters << {:title => [p], :type => Integer_Type}
        else
          @group_parameters << {:title => [p], :type => String_Type}
        end
      end
  end

  # GCP 5K SEAR Programming - Communication page(Default,Refresh,discard)
  def sear_communication_parameters
    @selected_type = params[:selected_value] || 'selected_value'
    @channel_id = 0

    parameters = ( EnumParameter.enum_group(129,@channel_id)+ IntegerParameter.Integer_group(129, @channel_id) + StringParameter.string_group(129, @channel_id)).sort_by &:DisplayOrder


      @group_parameters = []
      parameters.each do |p|
        if(p.class == EnumParameter)
          @group_parameters << {:title => [p], :type => Enum_Type}
        elsif(p.class == IntegerParameter)
          @group_parameters << {:title => [p], :type => Integer_Type}
        else
          @group_parameters << {:title => [p], :type => String_Type}
        end
      end
    render :partial => "sear_communication_parameters"
  end

  def sear_communication_subgroup_parameters
    @channel_id = 0

    enum_name = EnumValue.find(:first,:select => "Name",:conditions => ["ID = ?",params[:value_id].to_i]) 
    enum_name = enum_name['Name']
        
    subgroup_ID = ParameterGroup.find_by_sql("select ID from Parameter_Groups where Parent_Group_ID = 129  and Group_Name like '%#{enum_name}'")
    
    if subgroup_ID != nil &&  subgroup_ID[0] != nil 
      subgroup_ID =  subgroup_ID[0]['ID']

      parameters = ( EnumParameter.enum_group(subgroup_ID,@channel_id)+ IntegerParameter.Integer_group(subgroup_ID, @channel_id) + StringParameter.string_group(subgroup_ID, @channel_id)).sort_by &:DisplayOrder

        @group_parameters = []
        parameters.each do |p|
          if(p.class == EnumParameter)
            @group_parameters << {:title => [p], :type => Enum_Type}
          elsif(p.class == IntegerParameter)
            @group_parameters << {:title => [p], :type => Integer_Type}
          else
            @group_parameters << {:title => [p], :type => String_Type}
          end
        end

        render :partial => "sear_communication_parameters"
    else
      #no parameters
      render :text => ""
    end
  end
  def comm_string_validator(rec_id, value)
    if string_param = StringParameter.find_by_ID(rec_id)
      string_type = string_param.string_type
      min = string_type.Min_Length
      max = string_type.Max_Length
      mask = string_type.Format_Mask
      errors = []
      unless (value.length >= min && value.length <= max)
        return "Should be of #{min} to #{max} Characters"
      end
      return ""
    end
  end

  def comm_integer_validator(rec_id, value)
    if (int_param = IntegerParameter.find_by_ID(rec_id))
      int_value = value
      int_type = int_param.int_type
      min = int_type.Min_Value
      max = int_type.Max_Value

      if value && int_type.Format_Mask.match('H:') #The hexadecimal validation!
        int_value = value.hex.to_s
        txt = " In conversion to Hexadecimal"
        unless value.match(/^-{0,1}[a-fA-f0-9]*?$/)
          return "'#{int_param.Description}' Should be in Hexadecimal format"
        end
      end

      unless int_value.match(/^-{0,1}\d*\.{0,1}\d+$/) && (int_value.to_i >= min && int_value.to_i <= max)
        return "Should be in the numeric Range of (#{min} to #{max})#{txt}"
      end
      return ""
    end
  end

  
  # GCP 5K SEAR Programming - Update Communication page parameters
  def update_sear_communication
    #updates 
    @errors = ParameterGroup.new_group_parameter_values_update(params[:result]) # means no errors saving was successfull!


    #puts "Error: " + @errors.inspect
    if @errors == nil
      render :text => "Parameters updated successfully.."
    else
      render :text =>  @errors
    end
  end

  # GCP 5K SEAR Programming - Display Serial port page parameters
  def sear_serial_port
    if params[:page_type]
      @page_type = params[:page_type]
      @channel_id = params[:channel]
    else
      @page_type = 'aux_port'
      @channel_id = 1
    end
    @group_parameters = group_parameter_values(@channel_id, 130)
  end

  # GCP 5K SEAR Programming - Display(Default, Discard,Refresh) Serial port page parameters
  def sear_serialport_parameters
    @selected_type = params[:selected_value] || 'selected_value'
    unless params[:channel].blank?
      @channel_id = params[:channel]
    else
      @channel_id = 1
    end
    @group_parameters = group_parameter_values(@channel_id, 130)
    render :partial => 'sear_serialport_parameters'
  end

  # GCP 5K SEAR Programming - Update Serial port page parameters
  def update_sear_serial_port
      if request.xhr? && logged_in?
        int_updated_value = IntegerParameter.update_io_assignment_parameters(params["integer"]) if (params["integer"])
        str_updated_value = StringParameter.update_io_assignment_parameters(params["string"]) if (params["string"])
        enum_updated_value = EnumParameter.update_io_assignment_parameters(params["enum"]) if (params["enum"])
        if int_updated_value || str_updated_value || enum_updated_value
#        if enum_updated_value
          render :text => "Parameters updated successfully.."
        else
          render :nothing => true
        end
      end
  end

  #*****************************************************************
  #*****************************************************************
  # 4/8/2013
  # module_reset method does not appear to be used.
  # FIXME: Delete in a future build.
  #*****************************************************************
  #*****************************************************************
  def module_reset
    reboot_request = RebootRequest.new
    reboot_request.request_state = 0
    reboot_request.atcs_address = atcs_address + ".01"
    reboot_request.slot_number = 1
    reboot_request.save!
    udp_send_cmd(REQUEST_COMMAND_RESET, reboot_request.request_id)
    sleep 2
    render :text => "Vital CPU rebooted"
  end
  #*****************************************************************
  #*****************************************************************

  def calculate_ccn_and_occn
    atcs_address = Gwe.find(:first, :select => "sin").try(:sin)
    simple_request = RrSimpleRequest.create(:request_state => ZERO , :atcs_address => atcs_address , :command => 15)
    udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, simple_request.request_id)
    render :json => { :request_id => simple_request.request_id}
  end

  def ccn_and_occn_request_status
    request_id = params[:request_id]
    simple_request_status = RrSimpleRequest.find(:last,:conditions=>['request_id=?',request_id])
    render :json => { :request_id => simple_request_status.request_id, :request_state => simple_request_status.request_state}
  end

  def read_ccn_and_occn
    rt_gwe = Gwe.find(:first, :select => "config_check_word , occn")
    render :json => { :ccn => rt_gwe.config_check_word.to_s(16).upcase, :occn => rt_gwe.occn.to_s(16).upcase}
  end

  def cleanup_simplerequest
    RrSimpleRequest.delete_request(params[:request_id])
    render :json => {:cleanupOK => true}
  end

  def cleanup_config_property_request
    SetCfgPropertyRequest.delete_request(params[:request_id])
    render :json => {:cleanupOK => true}
  end

  def cleanup_config_property_iviu_request
    SetCfgPropertyiviuRequest.delete_request(params[:request_id])
    render :json => {:cleanupOK => true}
  end

  def cleanup_verify_screen_request
    request_id = params[:request_id].to_i

    # Check type of system and delete appropriate database requests
    if Gwe.gcp_4000?
      # 4k system, delete any database entries
      VerifyScreenParam.delete_all(:request_id => request_id) rescue nil
      HiddenParam.delete_all(:request_id => request_id) rescue nil
      VerifyScreenRequest.delete_all(:request_id => request_id) rescue nil
    else
      # 5k system, delete any database entries
      VerifyDataIviuRequest.delete_all(:request_id => request_id) rescue nil
      VerifyScreenIviuRequest.delete_all(:request_id => request_id) rescue nil
    end

    render :json => {:cleanupOK => true}
  end
  def vital_config_menu
    html_content = ""
    oceflag = false
    parent_used = false
    @expression_structure = {}
    #set_ui_expr_variables()
    if true #RtSession.ready? # TODO: check for ready session
      if !session[:cfgsitelocation].blank? && ((File.exists?(session[:cfgsitelocation] + '/mcf.db') && File.exists?(session[:cfgsitelocation] + '/rt.db')))
        oceflag = true
        connectdatabase()
      end
      if ((PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE && oceflag) || PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI)
          
          Gwe.refresh_mcfcrc
          @main_menu = {}
          @ucn_in_mcf = false
          
          parent_used = Menu.cpu_3_menu_system
          
          if (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP") && (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE && oceflag))
              # OCE GCP MENU System
              menus = Menu.all(:conditions => ["mcfcrc = ? and (target Not Like 'LocalUI')", Gwe.mcfcrc],:order => 'rowid', :select => "menu_name, link, parent, page_name, show, enable")
          else          
            if parent_used
              menus = Menu.all(:select => "menu_name, link, parent, page_name, show, enable", :conditions => ["mcfcrc = ? and layout_index = ? and page_name Like 'Vital Configuration'", Gwe.mcfcrc, Gwe.physical_layout],:order => 'rowid')  
              # puts menus.inspect
            else
              menus = Treemenu.all(:select => "name as menu_name, link, '' as parent, parent_id as page_name, 'true' as enable",:conditions => ["mcfcrc = ? and layout_index = ?", Gwe.mcfcrc, Gwe.physical_layout],:order => 'display_order')        
            end
          end
                  
          if parent_used && PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI
            menus << Menu.new(:menu_name => "Name Editors", :page_name => "Vital Configuration", :show => "true", :enable => "true", :link => "(NULL)", :parent => "(NULL)")
            menus << Menu.new(:menu_name => "Object Names", :page_name => "Vital Configuration", :show => "true", :enable => "true", :link => "{OBJECTNAMEEDITOR/SAT}", :parent => "Name Editors")
            menus << Menu.new(:menu_name => "Card Names", :page_name => "Vital Configuration", :show => "true", :enable => "true", :link => "{OBJECTNAMEEDITOR/CARD}", :parent => "Name Editors")
          end
          
          menus.each_with_index do |menu, index|
            if parent_used
              show_value = eval_expression(menu.show) ? true : false
            else
              menu_show = true
              menu_enable = true
              menu_show, menu_enable = Treemenu.get_menu_show_value(menu) if !menu.link.empty?
              show_value = eval_expression(menu_show.to_s) ? true : false if !menu_show.blank?            
              menu.enable = menu_enable.to_s
            end          
             if show_value
              if parent_used
                if (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP") && (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE && oceflag))
                  parent_name = (menu.parent == '(NULL)' && menu.page_name.eql?('MAIN PROGRAM menu')) ? 'ROOT' : menu.parent
                else
                  parent_name = (menu.parent == '(NULL)' && menu.page_name.eql?('Vital Configuration')) ? 'ROOT' : menu.parent    
                end
              else
                parent_name = (menu.page_name.eql?('MAIN PROGRAM menu')) ? 'ROOT' : menu.page_name
              end
              if @main_menu.has_key?(parent_name)
                menu_item = @main_menu[parent_name]
                menu_item << menu
                @main_menu[parent_name] = menu_item
              elsif (!parent_used && parent_name != 'MAIN PROGRAM menu') || (parent_used && parent_name != 'Vital Configuration')
                @main_menu[parent_name] = [menu]
              end
              #@ucn_in_mcf = true if menu.menu_name == "Unique Check Number (UCN)"
            end
            @ucn_in_mcf = true if menu.menu_name == "Unique Check Number (UCN)"
          end
          if !@ucn_in_mcf && parent_used && PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI
            @main_menu["ROOT"] << Menu.new(:menu_name => "Unique Check Number (UCN)", :page_name => "Vital Configuration", :show => "true", :enable => "true", :link => "{UCN}")
          end
          html_content = render_to_string(:partial => 'vital_config_menu')
      end
    end
    render :json => {:html_content => html_content} and return
  end


  def hd_linker
    @atcs_address = Gwe.find(:first).sin  

    #gets the atcs address for the selected
    rgls_offset = get_rgls_offset(params[:page_name])

    rrr_offset = rgls_offset[0]
    lll_offset = rgls_offset[1]
    ggg_offset = rgls_offset[2]
    ss_offset = rgls_offset[3]
    @card_index = rgls_offset[4]

    @rgls_offset = rgls_offset

    @remote_sin = cal_remote_sin(@atcs_address, rrr_offset, lll_offset, ggg_offset, ss_offset)

    new_hd_name =  @remote_sin.split('.')
    @new_hd_name = new_hd_name[2]+new_hd_name[3]+new_hd_name[4]+'.mcf'

    link_type = params[:page_name].split(' ')
    link_type = link_type[link_type.length-1]

    xml_file = "#{RAILS_ROOT}/oce_configuration/templates/HDMCFs/DTCONFIG.XML"
    site_path = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/#{session[:sitename]}/"

    @MCF = ''
    @UCN = ''
    @UCN_hd_new = ''
    @UserMCFDir = ''
    @message = ''
    if File.exist?(xml_file)
      doc = Document.new File.new(xml_file)


      doc.elements.each("DTConfiguration/HDMCFVitalLink"+link_type+"/MCF") { |element| 
        @MCF = element.text.gsub("\\","/").gsub "#{RAILS_ROOT}", ''
      } 

      doc.elements.each("DTConfiguration/HDMCFVitalLink"+link_type+"/UCN") { |element| 
        @UCN = element.text
      } 

      doc.elements.each("DTConfiguration/HDMCFVitalLink"+link_type+"/UserMCFDir") { |element| 
        @UserMCFDir = element.text
      }   

    end

    #checks the yml file to to display the correct new_hd_name
    yml_file = "#{site_path}hd_mcfs.yml"

    if File.exist?(yml_file)
      d = YAML::load_file(yml_file) #Load
      if !d['VCom '+link_type].blank?
        @new_hd_name = d['VCom '+link_type]
      end
    end

    #validate UCN
    hdmcf = WIN32OLE.new('HDMCFServer.HDMCFManager.1')
    hdmcf.gcp_sin = Gwe.find(:first).sin  
    hdmcf.hd_mcf_template = "#{RAILS_ROOT}/#{@MCF}".gsub("\\","/")
    hdmcf.hd_sin = @remote_sin

    if File.exist?("#{RAILS_ROOT}#{@MCF}")
      validate_ucn = hdmcf.get_ucn("#{RAILS_ROOT}#{@MCF}".gsub("/","\\"))
      if validate_ucn != @UCN
        @message = "Source HD MCF UCN is invalid."
      end
    else
      @message = "Source HD MCF does not exist."
    end

    if File.exist?("#{site_path}#{@new_hd_name}")
      @UCN_hd_new = hdmcf.get_ucn("#{site_path}/#{@new_hd_name}".gsub("/","\\"))
    end

    hdmcf.ole_free
    hdmcf = nil
    GC.start

  end

  def hd_atcs_used
    params[:page_name] = "BASIC:  Vital Comms links"
    params[:menu_link] = "BASIC:  Vital Comms links"
    hd_sin_check = params[:hd_sin]

    if @gcp_4000_version
      get_parameters
    else
      get_5k_parameters
    end

    num_hd_links = @parameters.size
    @atcs_address = Gwe.find(:first).sin  

    hd_atcs_used = false

    for i in 1..num_hd_links
      if params[:current_page_name] != "BASIC:  Vital Comms link #{i}"
        if hd_sin_check == get_hd_atcs(@atcs_address,"BASIC:  Vital Comms link #{i}")
          hd_atcs_used = true
        end
      end
    end

    render :text => hd_atcs_used
  end

  def hd_check_mcf_exsist
    link_type = params[:menu_link].split(' ')
    link_type = link_type[link_type.length-1]

    xml_file = "#{RAILS_ROOT}/oce_configuration/templates/HDMCFs/DTCONFIG.XML"

    mcf = ''

    if File.exist?(xml_file)
      doc = Document.new File.new(xml_file)

      doc.elements.each("DTConfiguration/HDMCFVitalLink"+link_type+"/MCF") { |element| 
        mcf = element.text
      }    

      site_path = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/#{session[:sitename]}/"

      if File.exist?("#{site_path}#{params[:hd_mcf_template_name]}")
        render :text => true
      else
        render :text => false
      end
    else
      render :text => false
    end
  end

  def hd_check_report_exsist 
    link_type = params[:menu_link].split(' ')
    link_type = link_type[link_type.length-1]

    xml_file = "#{RAILS_ROOT}/oce_configuration/templates/HDMCFs/DTCONFIG.XML"

    mcf = ''

    if File.exist?(xml_file)
      doc = Document.new File.new(xml_file)

      doc.elements.each("DTConfiguration/HDMCFVitalLink"+link_type+"/MCF") { |element| 
        mcf = element.text
      }    

      site_path = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/#{session[:sitename]}/"

      if File.exist?("#{site_path}#{params[:hd_report_template_name]}")
        render :text => true
      else
        render :text => false
      end
    else
      render :text => false
    end
  end

  def hd_create_mcf
    link_type = params[:menu_link].split(' ')
    link_type = link_type[link_type.length-1]

    xml_file = "#{RAILS_ROOT}/oce_configuration/templates/HDMCFs/DTCONFIG.XML"

    mcf = ''

    if File.exist?(xml_file)
      doc = Document.new File.new(xml_file)

      doc.elements.each("DTConfiguration/HDMCFVitalLink"+link_type+"/MCF") { |element| 
        mcf = element.text
      }    
    
      site_path = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/#{session[:sitename]}/"

      hdmcf = WIN32OLE.new('HDMCFServer.HDMCFManager.1')
      hdmcf.gcp_sin = Gwe.find(:first).sin  
      hdmcf.hd_mcf_template = "#{mcf}".gsub("\\","/")
      hdmcf.hd_sin = params[:hd_atcs]

      mcf_template_name = params[:hd_mcf_template_name]
      log_template_name = mcf_template_name.gsub("mcf","txt")
      html_template_name = mcf_template_name.gsub("mcf","html")

      if link_type =~ /^\d+$/
        hd_update_hd_mcfs_name('VCom '+link_type,mcf_template_name)
      end

      report = ''
      report_html = ''
      strmsg = hdmcf.create_mcf("#{site_path}#{params[:hd_mcf_template_name]}" )
      create_reports_message = hdmcf.create_reports("#{site_path}#{params[:hd_mcf_template_name]}",params[:menu_link],"#{site_path}#{log_template_name}","#{site_path}#{html_template_name}")
      strmsg = hdmcf.get_ucn("#{site_path}#{params[:hd_mcf_template_name]}".gsub("/","\\"))

      hdmcf.ole_free
      hdmcf = nil
      GC.start

      render :text => strmsg
    else
      render :text => "error"
    end
  end

  def hd_view_report
    site_path = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/#{session[:sitename]}/"
    if File.exist?("#{site_path}#{params[:hd_report_template_name]}")
      data = File.read("#{site_path}#{params[:hd_report_template_name]}")

      if data
        render :text => data
      else
        render :text => "Report does not exsist"
      end
    else
      render :text => "Report does not exsist"
    end
  end

  def hd_get_ucn
    hdmcf = WIN32OLE.new('HDMCFServer.dll')
    hdmcf.gcp_sin = Gwe.find(:first).sin  
    hdmcf.hd_mcf_template = params[:hd_mcf_template_name]
    hdmcf.hd_sin = params[:hd_atcs]
    strmsg = hdmcf.get_ucn(params[:mcf_name])
  end

  def hd_create_reports
    hdmcf = WIN32OLE.new('HDMCFServer.dll')
    hdmcf.gcp_sin = Gwe.find(:first).sin  
    hdmcf.hd_mcf_template = params[:hd_mcf_template_name]
    hdmcf.hd_sin = params[:hd_atcs]
    strmsg = hdmcf.get_ucn(params[:mcf_name])

    #validate UCN
    hdmcf = WIN32OLE.new('HDMCFServer.HDMCFManager.1')
    hdmcf.gcp_sin = Gwe.find(:first).sin  
    hdmcf.hd_mcf_template = "#{RAILS_ROOT}/#{@MCF}".gsub("\\","/")
    hdmcf.hd_sin = @remote_sin
        
    @strmsg = hdmcf.get_ucn("#{RAILS_ROOT}/#{@MCF}".gsub("/","\\"))
  end

  def hd_create_all
    hdmcf = WIN32OLE.new('HDMCFServer.dll')
    hdmcf.gcp_sin = Gwe.find(:first).sin  
    hdmcf.hd_mcf_template = params[:hd_mcf_template_name]
    hdmcf.hd_sin = params[:hd_atcs]
    strmsg = hdmcf.get_ucn(params[:mcf_name])
  end

  def hd_check_dl
    name = params[:name]
    
    site_path = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/#{session[:sitename]}/"

    if File.exist?("#{site_path}#{name}")
      render :text => true
    else
      render :text => false
    end
  end

  def hd_dl
    name = params[:name]
    
    site_path = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/#{session[:sitename]}/"

    if File.exist?("#{site_path}#{name}")
      begin
        send_file("#{site_path}#{name}", :filename => name, :type => "application/octet-stream", :disposition => "attachment", :encoding => "utf8")
      rescue Exception => e
        render :text => "<p style='color:#FFF'>Exception Raised: #{e.message}</p>"
      end
    else
      render :text => false
    end
  end

  def hd_update_hd_mcfs_name(which_one,name)
    site_path = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/#{session[:sitename]}/"
    yml_file = "#{site_path}hd_mcfs.yml"

    if !File.exist?(yml_file)
      aFile = File.new(yml_file, "w+")

      d = {}
      d['VCom 1'] = (which_one == 'VCom 1' ? name : '')
      d['VCom 2'] = (which_one == 'VCom 2' ? name : '')
      d['VCom 3'] = (which_one == 'VCom 3' ? name : '')
      d['VCom 4'] = (which_one == 'VCom 4' ? name : '')
    else
      d = YAML::load_file(yml_file) #Load
      d[which_one] = name
    end

    File.open(yml_file, 'w+') {|f| f.write d.to_yaml } #Store
  end

  def hd_dl_all_create
   site_path = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/#{session[:sitename]}/"
    yml_file = "#{site_path}hd_mcfs.yml"
    @dl_files = {}

    if File.exist?(yml_file)
      d = YAML::load_file(yml_file) #Load
      d.each do |page_name,new_hd_mcf|
        if !new_hd_mcf.blank?
          temp_dl_files = []

          new_hd_name = new_hd_mcf.gsub(".mcf","")

          #checks if files exist before adding to array
          if File.exist?("#{site_path}#{new_hd_name}.mcf")
            temp_dl_files << "#{new_hd_name}.mcf"
          end

          if File.exist?("#{site_path}#{new_hd_name}.html")
            temp_dl_files << "#{new_hd_name}.html"
          end

          if File.exist?("#{site_path}#{new_hd_name}.txt")
            temp_dl_files << "#{new_hd_name}.txt"
          end
          
          #onlys adds list of files if the array is not empty
          if !temp_dl_files.empty?
            @dl_files[page_name] = temp_dl_files
          end
        end
      end
    end

    zipfilename = 'hd_mcfs'
    bundle_filename = "#{RAILS_ROOT}/tmp/#{zipfilename}.zip"

    File.delete(bundle_filename) if File.exists?(bundle_filename)

    if !@dl_files.empty?
      Zip::ZipFile.open(bundle_filename, Zip::ZipFile::CREATE) do |zf|
        @dl_files.each do |page_name,dl_files| 
          zf.mkdir(page_name)

          dl_files.each do |dl_file|
            zf.add(page_name+"/"+dl_file.to_s, site_path+dl_file.to_s)
          end
        end
      end
      if File.exist?(bundle_filename)
        render :text => zipfilename
      else
        render :text => false
      end
    else
      render :text => "blank"
    end
  end

  def hd_dl_all
    
    bundle_filename = "#{RAILS_ROOT}/tmp/#{params[:name]}.zip"
    if File.exist?(bundle_filename)
      send_file(bundle_filename ,:disposition => 'inline' ,:stream => false)
    else
      render :text => "Error finding zip file: #{params[:name]}s.zip"
    end
  end
  
   ####################################################################
  # Function:      set_to_default_pso
  # Parameters:    none
  # Return:        request_id
  # Renders:       None
  # Description:   Initial call for set to default 
  ####################################################################    
  def set_to_default_pso
    if PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE     
      simple_request = RrSimpleRequest.new
      simple_request.request_state = ZERO
      simple_request.atcs_address = (atcs_address + ".02")
      simple_request.command = REQUEST_SET_TO_DEFAULT
      simple_request.save
      
      udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, simple_request.request_id)
      render :json => {:request_id => simple_request.request_id}
    else
      #       ONLY FOR OCE - START DEFAULT
      puts"entered"
      render :json => {:request_id => 0}
    end  
  end
  
  ####################################################################
  # Function:      check_set_to_default
  # Parameters:    none
  # Return:        none
  # Renders:       geo_session
  # Description:   checking geo_session for set_to_default
  ####################################################################    
  def check_set_to_default
    if (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE)
      RtParameter.update_default_to_current_vale(session[:cfgsitelocation]+'/rt.db')
      render :json => {:req_state => 2}
    else  
      simple_request = RrSimpleRequest.find(params[:id].to_i, :select => "request_state")
      
      if simple_request
        render :json => {:req_state => simple_request.request_state}
      else
        render :text => '<h2>Request ID not found in database!!</h2>'
      end
    end
  end

  #***********************************************************************************************************************
  private
  #***********************************************************************************************************************

  # Arranging group parameters based on the Display order
  def find_value(parameters, param_type)
    parameters.each do |parameter|
      @parameters[parameter.DisplayOrder] = {:type => param_type, :title => [parameter]}
    end
  end

  # To Fetch parameter values based on Group ID and and Types
  def group_parameter_values(channel_id = 0, group_id = 1036300)
    @group_id = group_id
    @parameters = Array.new
    @group_parameters = Hash.new

    digital_inputs_parameters = [{:title =>  StringParameter.string_group(@group_id, channel_id), :type => String_Type},
    {:title =>  EnumParameter.enum_group(@group_id, channel_id), :type => Enum_Type},
    {:title => IntegerParameter.Integer_group(@group_id, channel_id), :type => Integer_Type}]

    digital_inputs_parameters.each do |parameter|
      find_value(parameter[:title], parameter[:type])
    end

    @parameters.compact!
    ordered_params = Array.new

    flag = 1
    temp = 0
    @parameters.each_with_index do |parameter, index|
      ordered_params[index] = parameter
      #      if flag == 4
      ordered_params.compact!
      @group_parameters[temp] = ordered_params
      flag = 0
      ordered_params = []
      temp += 1
      #      end
      flag += 1
    end
  end
  
 
  def extract_menu
    session[:supervisor] = nil
    @expression_structure = {}
    # loading all enumerators into hash object
    #get_enumerators

    if @gcp_4000_version
      if RtSession.ready?
        atcs_address
        @menus = Menu.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :page_name => 'MAIN PROGRAM menu'}, :order => 'rowid', :select => "menu_name, link, show, enable")
      end
    else
      get_menus
    end
  end

  def screen_verification_for_5k(screen_iviu_request)
    unit_measure = EnumValue.units_of_measure
    @page_parameters.each do |page_parameter|
      parameter = @mcf_parameters.find{|mcf_parameter| page_parameter.card_index == mcf_parameter.cardindex && page_parameter.parameter_name == mcf_parameter.name && page_parameter.parameter_type == mcf_parameter.parameter_type }

      if $expression_mapper[page_parameter.parameter_name.strip + "_" + page_parameter.card_index.to_s]
        data_verify_request = VerifyDataIviuRequest.new
        data_verify_request.request_id = screen_iviu_request.request_id
        data_verify_request.parameter_index = (parameter.parameter_index + 1)
        data_verify_request.parameter_name = parameter.param_long_name
        parameter_long_name = params[parameter.name + "_" + parameter.cardindex.to_s]
        current_value = nil
        if(parameter_long_name == parameter.param_long_name)
          current_value = params[parameter.name]
        end
        data_verify_request.parameter_type = parameter_type_to_data_kind(parameter.parameter_type)
        data_verify_request.card_number = parameter.cardindex

        if parameter.enumerator[0]
          # get current valu from rt parameters if current_value is nil
          rt_parameter =  RtParameter.parameter(parameter) if current_value.blank?
          current_value = rt_parameter.current_value if rt_parameter
          data_verify_request.value = parameter.getEnumerator(current_value) if !current_value.blank?
        else
          data_verify_request.value = get_current_value(parameter)
        end
        data_verify_request.context_string = parameter.context_string.strip
        integer_type = parameter.integertype[0]
        data_verify_request.unit =  integer_type.imperial_unit.strip if integer_type
        
        if((!integer_type.blank?) && (unit_measure.Value == 1))
          unit_imp = integer_type.imperial_unit.strip 
          if(unit_imp != nil)
          data_verify_request.value = imperial_to_metric(integer_type,data_verify_request.value.to_i)
          data_verify_request.unit  =  integer_type.metric_unit.strip
          end
        end
      data_verify_request.save
      end
    end
    udp_send_cmd(REQUEST_COMMAND_VERIFY_SCREEN_IVIU, screen_iviu_request.request_id)
    $expression_mapper = {}
    screen_iviu_request.request_id
  end

  # method to verify screen for 4k
  def screen_verification_for_4k(screen_request, screen_request_id)

    rt_parameters = RtParameter.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :card_index => @page_parameters.map(&:card_index).uniq,
                         :parameter_name => @page_parameters.map(&:parameter_name)})
    mtf_index = 0
    hidden_param_count = 0
    @page_parameters.each_with_index do |page_parameter, index|
      mtf_index = page_parameter.mtf_index 
      parameter = @mcf_parameters.find{|mcf_parameter| page_parameter.card_index == mcf_parameter.cardindex && page_parameter.parameter_name == mcf_parameter.name && page_parameter.parameter_type == mcf_parameter.parameter_type }
      sub_menu = @sub_menus.find{|sub_menu| sub_menu.menu_name == page_parameter.menu_name }

      if $expression_mapper[page_parameter.parameter_name.strip + "_" + page_parameter.card_index.to_s]
        verify_request = VerifyScreenParam.new
        verify_request.request_id = screen_request_id
        verify_request.param_index = parameter.parameter_index
        verify_request.parameter_name = sub_menu.blank? ? parameter.param_long_name : page_parameter.menu_name
        current_value = params[parameter.name]
        rt_parameter = rt_parameters.find{|rt_param| parameter.cardindex == rt_param.card_index && parameter.name == rt_param.parameter_name}

        if parameter.enumerator[0]
          verify_request.value = parameter.getEnumerator(rt_parameter.current_value)
        else
          verify_request.value = get_current_value(parameter, rt_parameter)
        end
        verify_request.context_string = sub_menu.blank? ? parameter.context_string.strip : ""
        integer_type = parameter.integertype[0]
        verify_request.unit =  integer_type.imperial_unit.strip if integer_type
        verify_request.save
      else
        hidden_param_count += 1
        HiddenParam.create(:request_id => screen_request_id, :param_index => (index + 1))
      end
    end

    screen_request.update_attribute("no_of_hidden_params", hidden_param_count) if hidden_param_count != 0

    @sub_menus.each do |menu|
      if menu.mtf_index == mtf_index
        if((menu.link.blank? || menu.link.eql?('(NULL)')) || (menu.link.index("{") && menu.link.index("}")))
           param_request = VerifyScreenParam.new
          param_request.request_id = screen_request_id
          param_request.param_index =  -1
          param_request.parameter_name = menu.menu_name
          param_request.save
        end
      end
    end
    udp_send_cmd(REQUEST_COMMAND_VERIFY_SCREEN, screen_request_id)
  end

  def get_page_object(menu_link, page_type='next')
    gwe =  Gwe.find(:first)
    page = Page.find_by_page_name_and_mcfcrc(menu_link, gwe.mcfcrc)
    if(page && page.page_group == "template")        
      page = Page.find(:first, :conditions => ["page_group = ? and mcfcrc = ? and mtf_index = ? and page_name = ?", "template", gwe.mcfcrc, gwe.active_mtf_index, menu_link])
      if(page.nil?)
        page = Page.find(:first, :conditions => ["page_group = ? and mcfcrc = ? and mtf_index = ? and page_name = ?", "template", gwe.mcfcrc, 0, menu_link])
      end
    end
    if (!page.blank?)
      if(menu_link == "MAIN PROGRAM menu")
        expression = false
      else
        if (page.enable.blank?)
          expression = true
        else
          expression = eval_expression((page.enable))
        end
      end
      if expression
        params[:menu_link] = page.page_name
        return page
      else
        link = get_page_link(page, page_type)
        # calling recursively if page is disabled
        get_page_object(link, page_type)
    end
    end
  end

  def get_page_link(page, page_type)
    case page_type
      when 'alt_prev' then page.alt_prev
      when 'alt_next' then page.alt_next
      when 'prev' then page.prev
      when 'next' then page.next
      end
  end

  # method copied from mcfiviu controller and optimized to re-use for programming screen verification
  def get_current_value(parameter, rt_parameter=nil)
    rt_parameter ||= RtParameter.find(:first, :conditions => {:mcfcrc => parameter.mcfcrc, :card_index => parameter.cardindex, :parameter_name => parameter.name, :parameter_index => parameter.parameter_index})
    if rt_parameter
      factor = 1
      check_for_signed = nil
      integer_parameter = parameter.integertype[0]
      unless integer_parameter.nil?
        factor = (integer_parameter.scale_factor.to_f / 1000).to_f
        check_for_signed = true if integer_parameter.signed_number == 'Yes'
      end
      value = rt_parameter.current_value.to_f * factor
      value = get_signed_value(value, parameter.integertype[0].size) if !check_for_signed.nil?
      value.to_i
    else
      parameter.default_value
    end
  end

  # method to get GCP-5000 parameters based on page name
  def get_5k_parameters
    if params[:track_setup].blank?
      @page = Page.find_by_page_name(params[:menu_link], :include => [:tabs])
      @tabs = @page.tabs if @page
    end
    @expression_structure = {}
    @ui_state = GenericHelper.check_user_presence   # Uistate.vital_user_present?(atcs_address)
    @template_disable = import_site
    if(!params[:setup_wizard].blank?)
      @sel_template = get_active_template(params[:page_name])
      expression = eval_expression(@sel_template.enable) if @sel_template
      next_template = @sel_template if expression
      unless next_template.nil?
      while !expression && next_template.prev != "LAST PAGE"
        next_template_page_name = (params[:page_type] == "prev")? next_template.prev : next_template.next
        next_template = get_active_template(next_template_page_name)
        if next_template
          expression = eval_expression(next_template.enable)
        else
          expression = true
        end
      end
      @sel_template = next_template
      @mtf_index = @sel_template.mtf_index
      params[:page_name] = @sel_template.page_name
      end
    end
    @parameters = {}

    if @tabs.blank?
      if(@mtf_index)
        @page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and page_name = ? and (target <> 'LocalUI' or target isNULL) and mtf_index = ? ", Gwe.mcfcrc, params[:page_name].strip, @mtf_index], :order => 'display_order asc')
      else
        if params[:page_name]
          @page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and page_name = ? and (target <> 'LocalUI' or target isNULL)", Gwe.mcfcrc, params[:page_name].strip], :order => 'display_order asc')
          if (@page_parameters.blank? && (!params[:menu_link].blank?))
            @page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and page_name = ? and (target <> 'LocalUI' or target isNULL)", Gwe.mcfcrc, params[:menu_link].strip], :order => 'display_order asc')
          end
        end
      end
      if @page_parameters
        mcf_parameters = Parameter.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :cardindex => @page_parameters.map(&:card_index),
                           :name => @page_parameters.map(&:parameter_name), :parameter_type => @page_parameters.map(&:parameter_type)})

        mcf_parameters.each do |parameter|
          @parameters["#{parameter.cardindex}.#{parameter.name.strip}"] = parameter
        end
      end
    end
     params[:setup_wizard] = nil if params[:refresh_parameters]
     #render :partial => 'form' if request.xhr? && params[:track_setup].blank? && params[:setup_wizard].blank? && params[:user_presence_req].blank?
  end

  def get_menus
    if RtSession.ready?
      @parent_page = Page.find_by_page_name('MAIN PROGRAM menu', :select => 'enable, page_name',
                                            :conditions => {:mcfcrc => Gwe.mcfcrc, :cdf => 'CFGVIEWDATA.XML'})

      @main_menu = {}
      unless @parent_page.nil?
        menus = Menu.all(:conditions => ["mcfcrc = ? and (target Not Like 'LocalUI')", Gwe.mcfcrc],
                         :order => 'rowid', :select => "menu_name, link, parent, page_name, show, enable")

        menus.each_with_index do |menu, index|
          parent_name = (menu.parent == '(NULL)' && menu.page_name.eql?('MAIN PROGRAM menu')) ? 'ROOT' : menu.parent

          if @main_menu.has_key?(parent_name)
            menu_item = @main_menu[parent_name]
            menu_item << menu
            @main_menu[parent_name] = menu_item
          elsif parent_name != 'MAIN PROGRAM menu'
            @main_menu[parent_name] = [menu]
          end
        end
      end
    end
  end
 
  # This method is used to get the current value of the parameter from rt_parameter table of RT database
  def get_current_integer_value(page_param)
    temp_card_index = page_param.card_index
    RtParameter.find_by_mcfcrc_and_card_index_and_parameter_type_and_parameter_index(Gwe.mcfcrc,temp_card_index,page_param.parameter_type,page_param.parameter_index) || 0
  end

  def scale_down_value(value, integertype)
    integertype.nil? ? value : (value.to_f * (1000 / integertype.scale_factor.to_f)).to_i
  end

  def get_parameters
    @parameters = {}
    @template_disable = import_site
    params[:menu_link] = params[:page_name] if params[:menu_link].blank?
    template_page = Page.find(:first, :conditions => ["page_group = 'template' and page_name = ? ", params[:menu_link]])
    mtf_index = nil
    if(template_page)
       active_template = get_active_template(params[:menu_link])
       mtf_index = (active_template.blank?)? 0:active_template.mtf_index
    end

    if(params[:track_setup])
      parameter_names = ['GCPXmitFreqCategory','GCPXmitFrequency','ApproachDistance', 'GCPXmitLevel','IPIXmitFrequency','IslandDistance','LowEXAdjustment']
      @page_parameters = PageParameter.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :page_name => [params[:menu_link], "GCP:  track #{params[:card_number]} MS Control", "ISLAND:  track #{params[:card_number]}"], :parameter_name => parameter_names}, :order => 'display_order asc')
      @mcf_parameters = Parameter.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :cardindex => @page_parameters.map(&:card_index).uniq,
                         :name => parameter_names, :parameter_type => @page_parameters.map(&:parameter_type).uniq})
    else
      if(mtf_index)
        @page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and page_name = ? and target not like 'LocalUI' and mtf_index = ?", Gwe.mcfcrc , params[:menu_link], mtf_index], :order => 'display_order asc')
      else
        @page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and page_name = ? and target not like 'LocalUI'", Gwe.mcfcrc , params[:menu_link]], :order => 'display_order asc')
      end
      @mcf_parameters = Parameter.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :cardindex => @page_parameters.map(&:card_index).uniq,
                         :name => @page_parameters.map(&:parameter_name), :parameter_type => @page_parameters.map(&:parameter_type).uniq})
    end
    @mcf_parameters.each do |parameter|
      @parameters["#{parameter.cardindex}.#{parameter.name.strip}"] = parameter
    end
  end

  def get_enumerators
    if !RtSession.ready?
      return false
    end
    if $enumerators_hash.blank?
      $enumerators_hash = {}
      enumerators = ParamEnumerator.all(:conditions => {:mcfcrc => Gwe.mcfcrc})
      enumerators.each do |enumerator|
        $enumerators_hash["#{enumerator.enum_type_name}~#{enumerator.long_name}"] = enumerator.value
      end
    end
  end

  def check_user_session
    @supervisor_session = RtParameter.find_by_mcfcrc(Gwe.mcfcrc, :conditions => {:parameter_name => 'SuperPasswordActive',
                                :sin => atcs_address, :current_value => 2}, :select => "current_value")
    session[:envvarmap]  = (@supervisor_session && session[:supervisor]) ? {"$DTSupportsSuperPassword" => 1, "$SuperPasswordMatch" => 1, "$PasswordMatch" => 1} : {"$DTSupportsSuperPassword" => 1, "$SuperPasswordMatch" => 0, "$PasswordMatch" => 1}
  end
  
  def get_sub_menu_4k(page_name)
    temp_mtf_ind = 0
    gwe =  Gwe.find(:first)
    page = Page.find_by_page_name_and_mcfcrc(page_name, gwe.mcfcrc)
    if(page && page.page_group == "template")
      temp_mtf_ind = gwe.active_mtf_index
      page_mtf = Page.find(:first, :conditions => ["page_group = ? and mcfcrc = ? and mtf_index = ? and page_name = ?", "template", gwe.mcfcrc, gwe.active_mtf_index, page_name])
      if(page_mtf.nil?)
        temp_mtf_ind = 0
      end
    end
    sub_menus = Menu.all(:conditions => ["mcfcrc = ? and page_name like ? and link not like '{%' and mtf_index = ?", gwe.mcfcrc, page_name, temp_mtf_ind], :order => 'rowid', :select => "menu_name, link, show, enable, mtf_index")
    return page, sub_menus
  end

end
