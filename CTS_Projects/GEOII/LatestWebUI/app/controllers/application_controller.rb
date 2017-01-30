####################################################################
# Company: Siemens 
# Author: 
# File: ApplicationController.rb
# Description: Has methods which can be used by all controllers
####################################################################
#History:
# Log: /wayside/GEOII/Trunk/Software/WebUI/app/controllers/application_controller.rb.rb
#
# Rev 4639   July 06 2013 06:00:00   Jeyavel
# Removed get_card_names_and_slots methods & get_CP_info methods - not using.
class ApplicationController < ActionController::Base

  include UdpCmdHelper
  include ApplicationHelper

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  before_filter :authorize, :clear_enumerators
  skip_before_filter :verify_authenticity_token
  #before_filter :get_gcp_type if PRODUCT_TYPE == PRODUCT_TYPE_GCP_WEBUI
  before_filter :check_vlp_state, :only => [:detail_view, :lamp_adjustment, :sscc_test, :track_setup]

  def ajax_check_session
    redirect_resp = check_session(params[:reset])  #ApplicationHelper

    if redirect_resp == true
      #clears session
      if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
        reset_session
        clearAllValue_Sessions
        session[:user_id] = nil
        session[:logerror] = nil
        session[:alarms_check] = nil
      end
      render :text => "redirect"
    else 
      render :text => ""
    end
  end

  def ptc_enable_check
    ptc_check = Generalststistics.isPTC?

    render :text => ptc_check
  end

  def usb_enable_check
    ptc_check = Generalststistics.isUSB?

    render :text => ptc_check
  end

  def cpu_3_menu_system
    cpu_3_menu_system = Menu.cpu_3_menu_system

    render :text => cpu_3_menu_system
  end

  def gcp5k 
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      is_gcp_5k = Gwe.gcp5k?
    else
      is_gcp_5k = false
    end

    render :text => is_gcp_5k
  end

  def reset_timeout_session
    reset_session_logout #ApplicationHelper

    render :text => ""
  end

  def rebuild_site_info
    header_function

    render :partial => '/layouts/partials/site_info/'
  end

  def refresh_mcfcrc
    Gwe.refresh_mcfcrc
    logger.info "*************** udating MCFCRC Class variable: #{Gwe.mcfcrc} ***************"
  end
  # Populates the hash only when enumerators are available for specific pages/controller
  def clear_enumerators
    $enumerators_hash = nil if controller_name != 'programming' && !request.xhr?
  end

  # Returns atcs address
  def atcs_address
    @atcs_address ||= Gwe.atcs_address
  end

  def get_atcs_address
    atcs_address
    if @atcs_address != nil
      render :text => @atcs_address.to_s
    else 
      render :text => ""
    end
  end

  # To find out the version of GCP
  def get_gcp_type
    if Menu.cpu_3_menu_system
      @gcp_4000_version = false
    else
      @gcp_4000_version = true
    end
    return @gcp_4000_version
    #@gcp_4000_version ||= Gwe.find(:first, :conditions => ["mcf_location Like ? ", "%4000%"], :select => 'sin')
  end

  def CPU_connection
    #check_system_status(false, false)
    content = (!@gcp_status)? render_to_string(:template => 'cards/system_status', :layout => false) : ""
    render :json => {:status => @gcp_status, :message => @txt, :content => content}
  end

#  Set request to get the header information
  def make_header_request
    if ((PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE) && (!session[:typeOfSystem].blank?) && (session[:typeOfSystem].to_s == "GCP"))
      render :text => 0      
    else
      if atcs_address != nil
        location = Location.new(:request_state => ZERO, :command => ZERO, :atcs_address => (atcs_address + '.01'))
        location.save
        udp_send_cmd(REQUEST_COMMAND_LOCATION, location.request_id)
        render :text => location.request_id
      else
        render :text => '-1'
      end
    end
  end

# Check if the state is 2, and get header information
  def check_header_status
    if ((PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE) && (!session[:typeOfSystem].blank?) && (session[:typeOfSystem].to_s == "GCP"))
      site_info
      render :json => {:request_state => 2, :sname_4000 => session[:s_name], :atcs_address_4000 => session[:atcs_address], :m_post_4000 => session[:m_post], :dot_num_4000 => session[:dot_num] }
    else
      location = Location.find(params[:request_id], :select => "request_id, request_state, mile_post, site_name, dot_number, atcs_address")
      if location.request_state == 2
        sname_4000 =  location.site_name.strip[0..24] if(!location.site_name.nil?)
        m_post_4000 = location.mile_post.strip[0..10] if(!location.mile_post.nil?)
        dot_num_4000 = location.dot_number.strip[0..6] if(!location.dot_number.nil?)
        atcs_address_4000 = ""
        if (!location.atcs_address.blank?)
          atcs_addr = location.atcs_address.split('.')
          if (atcs_addr.size > 5)
            for addr_ind in 0..4
              if (atcs_address_4000.length > 0)
                atcs_address_4000 = atcs_address_4000 + "." + atcs_addr[addr_ind]
              else
                atcs_address_4000 = atcs_addr[addr_ind]
              end
            end
          else
            atcs_address_4000 = location.atcs_address
          end
        end
        delete_request(params[:request_id], REQUEST_COMMAND_LOCATION)
        render :json => {:request_state => location.request_state, :sname_4000 => sname_4000, :atcs_address_4000 => atcs_address_4000, :m_post_4000 => m_post_4000, :dot_num_4000 => dot_num_4000 }
      else
        delete_request(params[:request_id], REQUEST_COMMAND_LOCATION) if(params[:delete_request] == "true")
        render :json => {:request_state => location.request_state}
      end
    end
  end

  # Checks for the signed & un-signed values
  def check_signed_value(size, pval)
    if pval < 0
      pval *= -1
    else
      return pval
    end
    case size
      when 8
      pval = pval & 0x7FFF
      pval += 128
      return pval
      when 16
      pval = pval & 0x7FFF
      pval += 32768
      return pval
      when 32
      pval = pval & 0x7FFFFFFF
      pval += 2147483648
      return pval
    end
  end

  # Statements to map parameters to data kind
  def parameter_type_to_data_kind(nParamType)
    case nParamType.to_i
      when VitalConfiguration then DataKindVCfg
      when NonVitalConfiguration then DataKindNVCfg
      when Status then DataKindStatus
      when Command then DataKindCommand
      when LCfg then DataKindLocalCfg
      when SATCfg then DataKindSATCfg
      when SATRouteCfg then DataKindRouteCfg
    end
  end

  # Checks for the system status
  def check_system_status(rendertemplate = true, check_non_ajax_req = true)
            return if check_non_ajax_req && request.xhr?
             if( !(controller_name == "softwareupdate")  && PRODUCT_TYPE == PRODUCT_TYPE_GCP_WEBUI )
              @gcp_status = false
              dest_address  = Gwe.find(:first)
                        if dest_address
                                    if @rtsession = RtSession.find_by_atcs_address(dest_address.sin)
                                                  if @rtsession.comm_status == 1
                                                              if @rtsession.status == 10
                                                                @gcp_status = true
                                                                return true
                                                              else
                                                                          if @rtsession.status == 0
                                                                            @txt=" Connecting..."
                                                                          elsif @rtsession.status == 1
                                                                            @txt="Getting the AUX Files"
                                                                          elsif @rtsession.status == 2
                                                                            @txt=" Creating / Updating MCF Database"
                                                                          elsif @rtsession.status == 3
                                                                            @txt="Creating / Updating Real Time Database"
                                                                          end
                                                              end
                                                  else
                                                    @txt="CP is Out Of Session with VLP."
                                                  end
                                      render :template => "cards/system_status", :layout => "general" if rendertemplate
                                    end
                        else
                          @txt="CP is Out Of Session with VLP."
                        end
            end
  end

  # Stops the unsolicited events
  def stop_unsolicit_event
    unsolicited_event = RrUnsolicitedEvent.create({:request_state => 0, :atcs_address => session[:online_atcs_address], :io_changes => 0, :events => 0, :event_format => 0})
    udp_send_cmd(REQUEST_COMMAND_UNSOL_EVENTS, unsolicited_event.request_id)
    sleep 1
    RtOnlineStatus.delete_all(["sin = ?", session[:online_atcs_address]])
    session[:online_atcs_address] = nil
    session[:record_count] = nil
    RrUnsolicitedEvent.delete(unsolicited_event.request_id)
  end

  # Action triggered based on user presence
  def do_something
    #logger.info "HELLO, IVE TIMED OUT!"
    #redirect_to :controller=>"login"
    if PRODUCT_TYPE == 0
      simplerequest = RrSimpleRequest.create(:request_state => 0, :command => 11, :subcommand => 0, :value => "Auto Log out", :source => "WebUser")
      udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST,simplerequest.id)
    end

    if(request.xhr?)
      respond_to do |format|
        format.js  do
          render :update do |page|
            page.redirect_to 'home/redirect_home'
          end
        end
      end
    else
      render :template =>'home/redirect_home', :layout => nil
    end
  end

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  def current_user
    @current_user ||= session[:user_id]
  end

  # Checks for user log in status
  def logged_in?
    !current_user.blank?
  end

  # Method to authorize
  def authorize
    if !logged_in?
      redirect_to :controller => 'access', :action=> 'login_form'
    end
    logged_in?
  end

  # Check user presence
  def is_user_presence(atcs_address)
    return false if atcs_address.blank?
    return !Uistate.find_by_name_and_value_and_sin("local_user_present", 1, atcs_address).nil?
  end

  # Set user presence
  def set_user_presence(atcs_addr, geo = false)
    sub_command = (geo) ? 2 : 1

    if atcs_addr.blank?
      atcs_addr = "7.000.000.000.00"
    end
    # make entry into the request/reply database
    simplerequest = RrSimpleRequest.create({:atcs_address => atcs_addr+".02", :command => 1, :subcommand => sub_command, :request_state => 0, :result => ""})
    udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, simplerequest.request_id)
    return simplerequest.request_id
  end

  # Checks for gwe status
  def check_gwe_state(safe_mode_request)
    if safe_mode_request.gwe_state == 3
      @editmode = 1
      return true
    elsif safe_mode_request.gwe_state == 0
      @flag = 1
    end
  end

  # bypassing session ReInitialization if the session_flag is true
  # Added by Rajesh
  def initialize_session_expiry(time)
    unless params[:session_flag]
      expires_at = time.from_now
      session[:expires_at] = expires_at
    end
  end

  # Check for geo am or non-am
  def geo_non_am(atcs_addr)
    @gwe = Gwe.find(:last, :conditions => ["sin = ?", atcs_addr])
    if(@gwe && @gwe.active_physical_layout == 0 && @gwe.active_logical_layout == 0 && @gwe.active_mtf_index == 0)
      return true
    end
    return false
  end

  # Method to find the if geo is in session as per the atcs address provided
  def is_geo_in_session(atcs_addr)
    rt_session = RtSession.find_by_atcs_address(atcs_addr, :conditions => {:comm_status => GEO_COMM_STATUS, :status => GEO_STATUS}) if !atcs_addr.blank?
    return !rt_session.blank?
  end

  ####################################################################
  # Function:      alarms_refresh
  # Parameters:    none
  # Retrun:        none
  # Renders:       System Diagnostics
  # Description:   Fetches the required alarm information to be displayed in alarms page!
  ##############################################################
  def alarms_refresh
    alarms
    alarms_content = render_to_string(:partial => '/logreplies/alarms')
    render :json => { :alarms_content=> alarms_content}
  end
  ####################################################################
  # Function:      alarms
  # Parameters:    none
  # Retrun:        @alarm_diagnostics
  # Renders:       none
  # Description:   Fetches the required alarm information to be displayed in alarms page!
  ####################################################################  
  def alarms
    get_alarms(true)
  end

  ####################################################################
  # Function:      get_alarms
  # Parameters:    params[:page],params[:slot_num]
  # Retrun:        @alarm_diagnostics
  # Renders:       none
  # Description:   Fetches the required alarm information to be displayed in alarms page!
  #################################################################### 
  def get_alarms(flag)
    # Get indices of active cards
    if !params[:page].blank?
      @page_no = params[:page]
    else
      @page_no = 1
    end

    # local variables and instance variables
    slot_num = []
    card_type = []
    @slotnums = []
    strwhere = ""
    strwhere_in = ""

    #preprocessing to get the information for SIN and MCFCRC
    gwe_info = Gwe.find(:first, :select => "mcfcrc, ucn, occn,sin, active_physical_layout")

    if gwe_info
      @alarm_mcfcrc = gwe_info[:mcfcrc].to_i
      @alarm_sin = gwe_info[:sin].to_s
      @alarm_layout_index = gwe_info[:active_physical_layout].to_i
    else
      @alarm_mcfcrc = Gwe.mcfcrc
      @alarm_sin = ""
      @alarm_layout_index = 0
    end
    diag_messages = []
    if false == flag && gwe_info && gwe_info[:mcfcrc].to_i == 0 && gwe_info[:ucn].to_s.upcase == "7FFFFFFF"
     return true
    else if gwe_info && gwe_info[:mcfcrc].to_i == 0 && gwe_info[:ucn].to_s.upcase == "7FFFFFFF"
        diagnostics = {}
        @slotnums << "ALL"
        diagnostics[:info] = "No Valid MCF"
        diagnostics[:cause_remedy] = "\nCause:\nNo valid MCF present in ECD.\n\nRemedy:\nLoad the new MCF\n"
        diag_messages << diagnostics
    else
      #Get the slot information from the rt_view_cards, it will have the current status of cards information
      slots_info = IoViewCard.find(:all, :select => "DISTINCT slot_no, slot_name, card_type, card_index", :order => "slot_no")
      #check what we got from the User
      if params[:slot_num].blank? || params[:slot_num].to_s == "All"
        @selected_slotnum = "All"
      else
        @selected_slotnum = params[:slot_num]
      end
  
      #populate the table with the diagnostic messages for the selected slot/All
  #    diag_messages = []
      
      consist_id = RtConsist.maximum("consist_id")
      #Run the loop for each slot or for all the slots based on the user selection
      unless slots_info.blank?
        slots_info.each do |slot|
          # Check for the cards which are in use
          card_slot = RtCardInformation.find(:first, :conditions => {:card_type => slot[:card_type], :card_used => 0, :slot_atcs_devnumber => slot[:slot_no] , :consist_id => consist_id})
          if !card_slot.blank?
            slot_full_name = slot[:slot_name].to_s + " "
            if(card_slot.slave_kind == 0)
              slot_full_name += card_slot.slot_atcs_devnumber.to_s
            elsif(card_slot.slave_kind == 7)
              slot_full_name += "1"
            end
            slot_num[slot[:card_index].to_i] = slot_full_name
            card_type[slot[:card_index].to_i] = slot[:card_type]
            # Process the user selected slot "ALL or single"
            if (@selected_slotnum == "All") || (@selected_slotnum == slot_full_name)
              if (strwhere_in == "")
                strwhere_in = slot[:card_index].to_s
              else
                strwhere_in =  strwhere_in + "," + slot[:card_index].to_s
              end
            end  #end for the if to check whether ALL or individual slots selected
          end # if !card_slot.blank?
        end # slots_info.each do |slot|
      end  # unless slots_info.blank?
      if (strwhere_in != "")
        strwhere = "card_index in (" + strwhere_in  +  ") AND " + "current_value = 1 " + " AND " + "parameter_type  = 6 AND parameter_name not like '%.Filler%'"
      end
      if (strwhere != "")
        rt_parameters = RtParameter.find(:all, :select => "parameter_name,card_index", :conditions => strwhere)
        #check whether we have some diagnostics to tell system view to display diagnostics icon, else
        #process the data to show up the diagnostic messages in the Alarms page
        if(false == flag && !rt_parameters.blank?)
          return true #Done, return and tell system view to display diagnostic icon
        else
          rt_parameters.each do |diag|
          if !diag.blank?
             # spliting the message to get the diagnostic name
             # XXXX.YYYY  =>  DiagnosticHeader = XXXX; Diagnostic Name = YYYY (use this name to search in diagnostics table)
             diag_name = diag[:parameter_name].split(".")
             #Get the required data from the MCF/DIAGNOSTICS table, using CDF to remove duplicate data if any
             cdf_names = Card.find(:all, :select=> "cdf", :conditions=> {:card_index => "#{diag[:card_index]}", :parameter_type => 3, :crd_type => card_type[diag[:card_index].to_i].to_i}).map(&:cdf)
             #Get the Description and cause, remedy data, Limit the data only with one record
             diagnostic_data = DiagnosticMessages.find_by_sql("select  * from diagnostics where name like '%#{diag_name[1].to_s.strip}%' and cdf = '#{cdf_names[0]}' COLLATE NOCASE")
             diagnostics = {}
             if(!diagnostic_data.blank?)
                #Split the description info with format
                #XXXX(DiagYYYY) => Description = XXXX; Error Code = YYYY
                desc_info = diagnostic_data[0].description.to_s.split("(Diag")
                diagnostics[:info] = desc_info[0].to_s.strip
                #chop the last ")", if there is no error code for any diagnostic message,place "-"
                diagnostics[:code] = (desc_info[1].nil?)? "-" : desc_info[1].to_s.strip.chop
                diagnostics[:cause_remedy] = diagnostic_data[0].cause_remedy
                diagnostics[:slot] = slot_num[diag[:card_index].to_i] #slot_full_name.to_s
                #Holder for all the diagnostics Data for display purposes
                diag_messages << diagnostics
  
              end #if(!diagnostic_data.blank?)
            end #if !diag.blank?
          end  # rt_parameters.each do |diag|
        end  #end to check rt_parameters for the diagnostics
      end
      #populate the combo box with the slot names
      unless slot_num.blank?
        @slotnums << "All"
        slot_num.each do |n|
          @slotnums <<n if !(n.nil?)
       end
     end
  end
end
    #push the data further to view
    @alarm_diagnostics = diag_messages.paginate(:page => params[:page], :per_page => 10)

  end

  # Checks for the existance of alarm entries in db
  def check_alarms
    if (get_alarms(false) == true)
     return true
    else
      return false
    end
  end

  # TODO: removed from application controller and put it is lib, as application helper also contains thsi methods
  def dec2hex(number)
    number = Integer(number);
    return '0'+number.to_s(16).upcase if number < 16
    hex_digit = "0123456789ABCDEF".split(//)
    ret_hex = ''
    while(number != 0)
      ret_hex = String(hex_digit[number % 16 ] ) + ret_hex
      number = number / 16
    end

    return ret_hex.to_s.upcase ## Returning HEX
  end

  # TODO: removed from application controller and put it is lib, as io_status_view helper also contains this methods
  def modulation_code(current_value, short_code = false)
    return case current_value
      when 0 then "No Code"
      when 1 then short_code ? "A" : "Code A"
      when 2 then short_code ? "C" : "Code C"
      when 4 then short_code ? "D" : "Code D"
      when 8 then short_code ? "E" : "Code E"
      when 16 then short_code ? "F" : "Code F"
    end
  end

  def get_active_template(page_name)
    if ((PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE ) && (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP")))
      atcs_addr = Gwe.find(:first, :select => "sin").try(:sin)  
    else
      atcs_addr = atcs_address
    end
    gwe = Gwe.get_mcfcrc(atcs_addr)
    # first get template of active_mtf_index
    selected_template = Page.find(:first, :conditions => ["page_group = ? and mcfcrc = ? and mtf_index = ? and page_name = ?", "template", gwe.mcfcrc, gwe.active_mtf_index, page_name])
    # if active template not available then try to get common template
    if(selected_template.nil?)
      selected_template = Page.find(:first, :conditions => ["page_group = ? and mcfcrc = ? and mtf_index = ? and page_name = ?", "template", gwe.mcfcrc, 0, page_name])
    end
    return selected_template
  end

  # This methods will return 0 or 1 or 2 value
  # 0 => ms gcp set to No
  # 1 => ms gcp set to Yes and island is internal
  # 2 => ms gcp set to Yes and island is external
  def ms_gcp_operation(card_index)
    gcp_used, island_used = 0, 0
    parameters = RtParameter.find(:all, :conditions => ["(parameter_name = 'GCPUsed' or parameter_name = 'IPIUsed') and card_index = ? and parameter_type = ? and mcfcrc = ?", card_index, NonVitalConfiguration, Gwe.mcfcrc])
    parameters.each{|parameter|
      if(parameter.parameter_name == "GCPUsed" )
        gcp_used = parameter.current_value
      elsif(parameter.parameter_name == "IPIUsed" )
        island_used = parameter.current_value
      end
    }
    return gcp_used, island_used
  end

  #*********************************************************************************************************
  # Gets CPU Session
  #*********************************************************************************************************
  def get_cpu_session
    @session = RtSession.find(:first, :select=>"comm_status,status")
    if @session
      if Gwe.mcfcrc == 0
        Gwe.refresh_mcfcrc
      end
      render :json => {:comm_status => @session.comm_status, :status => @session.status}
    else
      Gwe.reset_mcfcrc
      render :json => {:comm_status => 0, :status => 0}
    end

  end

  def check_vlp_state
    card_index = RtCardInformation.find(:first,:conditions=>["card_type = 9"], :select => "card_index").try(:card_index)
    cp_unconfig_status = RtParameter.find(:first, :conditions => ["(card_index = #{card_index}) and (parameter_name = 'DiagFlags1.UnconfiguredState')"], :select => "current_value").try(:current_value) if card_index
    if (cp_unconfig_status && cp_unconfig_status != 0 )
      redirect_to "/sessions/vlp_unconfig?cp_unconfig_status="+cp_unconfig_status.to_s and return if @unconfig_page.nil?
      return false
    end
    return true
  end

  def get_user_presence
    ui_state = Uistate.vital_user_present
    render :json => {:user_presence => (ui_state.blank?)? false:true} and return
  end

  protected
  
  #renders the product name
  def get_product
    if Gwe.is_GOL_app?
      return "CPU II"
    else
      return "CPU III"
    end
  end
  
  ####################################################################
  # Function:      delete_request
  # Parameters:    request_id, UDP Command
  # Return:        None
  # Renders:       None
  # Description:   This method deletes request record from db
  #################################################################### 
  def delete_request(request_id = nil, udp_command = nil)
    return if request_id.blank? || udp_command.blank?
    case udp_command
      when REQUEST_COMMAND_SET_PROP_IVIU
        SetCfgPropertyiviuRequest.delete_all(:request_id => request_id) rescue nil
      when REQUEST_COMMAND_VERIFY_SCREEN_IVIU
        VerifyScreenIviuRequest.delete_all(:request_id => request_id) rescue nil
      when REQUEST_COMMAND_LOCATION
        Location.delete_all(:request_id => request_id) rescue nil
      when REQUEST_GEO_OBJ_MSG
        ObjectName.delete_all(:request_id => request_id) rescue nil
      when REQUEST_COMMAND_GEO_STATISTICS
        RrGeoStatsRequest.delete_all(:request_id => request_id) rescue nil
      when REQUEST_COMMAND_SIMPLE_REQUEST
        RrSimpleRequest.delete_all(:request_id => request_id) rescue nil
      when REQUEST_COMMAND_SET_UCN
        SetUcnRequest.delete_all(:request_id => request_id) rescue nil
      when REQUEST_COMMAND_GET_MODULES
        RrGeoOnline.delete_all(:request_id => request_id) rescue nil
      when REQUEST_COMMAND_UPLOAD_FILE
        SoftwareUpload.delete_all(:request_id => request_id) rescue nil
    end  
  end
  
  def port_open?(ip, port, seconds=2)
    Timeout::timeout(seconds) do
      begin
        TCPSocket.new(ip, port).close
        true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        false
      end
    end
  rescue Timeout::Error
    false
  end
  
  def cfgmgr_getfreeportno
    while true 
        y = 12340+rand(100)
        if ! port_open?("127.0.0.1", y.to_i, seconds = 2)
            return y
        end
    end
  end
  
  def close_cfgmgr(pid)
    sleep(1)
    readxmlfile = WIN32OLE.new('Cfg2xml_Engine.Cfg2Xml')  
    readxmlfile.StopExe(pid)
    session[:pid] = nil
  end

  ####################################################################
  # Function:      update_rt_sin_values
  # Parameters:    updatesinvalues
  # Retrun:        None
  # Renders:       None
  # Description:   Update atcs sin with RT.db - Site info atcs values for OCE only
  ####################################################################  
  def update_rt_sin_values(sin_id, updatesinvalues)
    if File.exists?(session[:cfgsitelocation]+'/rt.db')
        gwesinvalue = Gwe.find(:all,:select=>"sin").map(&:sin)
        if (updatesinvalues != gwesinvalue[0].to_s)
            StringParameter.stringparam_update_query(updatesinvalues.to_s, sin_id)
            Gwe.update_all("sin = '#{updatesinvalues.to_s}'")
            RtParameter.update_all("sin = '#{updatesinvalues.to_s}'")
            Uistate.update_all("sin = '#{updatesinvalues.to_s}'")
            if ((!session[:typeOfSystem].blank?) && (session[:typeOfSystem].to_s == "GCP"))
              RtSession.update_all("atcs_address = '#{updatesinvalues.to_s}'")
            else  
              RtCard.update_all("sin = '#{updatesinvalues.to_s}'")
              RtConsist.update_all("sin = '#{updatesinvalues.to_s}'")
              RtSatName.update_all("sin = '#{updatesinvalues.to_s}'")
              RtCardName.update_all("sin = '#{updatesinvalues.to_s}'")
              RtSession.update_all("atcs_address = '#{updatesinvalues.to_s+'.02'}'")
            end
            header_function
        end  
    end
  end
  
  def import_site
    template_disable = false
    if ((PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE ) && (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP")))
      unless session[:cfgsitelocation].blank?
        site_details_path = "#{session[:cfgsitelocation]}/site_details.yml"
        if File.exists?(site_details_path)
          site_details = YAML.load_file(site_details_path)
          templateflag = site_details["Template Flag"].to_s
          if !templateflag.blank?
            if ((templateflag == true) || (templateflag.to_s.downcase == "true"))
              template_disable = false
            else
              template_disable = true
            end
          else
           template_disable = false
          end      #if !templateflag.blank?    
        end
      end
    end
    return template_disable
  end
     
  def update_db options
    begin      
      lst_tables = {:ByteArray_Parameters => ["ID", "Array_Value"],
              :CDL_Answer_Options => ["ID", "Answer_Value"],
              :CDL_Conditions => ["ID", "Condition_Value"],
              :CDL_OpParam_Options => ["ID", "Option_Value"],
              :CDL_OpParams => ["ID", "Current_Value"],
              :CDL_Questions => ["ID", "Answer_Value"],
              :Enum_Parameters => ["ID", "Selected_Value_ID"],
              :Integer_Parameters => ["ID", "Value"],
              :String_Parameters => ["ID", "String"],
              :Wizard_Answer_Options => ["ID", "Answer_Value"],
              :Wizard_Conditions => ["ID", "Condition_Value"],
              :Wizard_Database_Operations => ["ID", "Parameter_Value"],
              :Wizard_Questions => ["ID", "Answer_Value"]}
      
      #Deleting existing log file
      File.delete(session[:cfgsitelocation]+'/update_DB_Log.log') if File::exists?(session[:cfgsitelocation]+'/update_DB_Log.log')
      db1 = SQLite3::Database.new(options[:db1])
      db2 = SQLite3::Database.new(options[:db2])
      
      # Get version information from both db's
      db1_version_info = db1.execute('select Product_Name, Platform_Name, Database_Version from Version_Information limit 0,1')
      db2_version_info = db2.execute('select Product_Name, Platform_Name, Database_Version from Version_Information limit 0,1')
      delete_old_file = false
      #Check change in version information and than only update database
      if(!db1_version_info.blank? && !db2_version_info.blank? && (db1_version_info[0][2] != db2_version_info[0][2]))
        if(db1_version_info[0][0] != db2_version_info[0][0] || db1_version_info[0][1] != db2_version_info[0][1])
          File.open(session[:cfgsitelocation]+'/update_DB_Log.log', 'a') do |f|
            f.puts "Updating database failed as Product_Name or Platform_Name does not matched between two DB's of Version_Information table "
          end
          return "InValid Non vital configuration."
        end
        # copy initial DB to site db location
        FileUtils.cp(options[:db1], options[:db2].sub(/nvconfig/, 'nvconfig_new'))
        db1.close
        # Refer copied version of db instead of initial DB
        db1 = SQLite3::Database.new(options[:db2].sub(/nvconfig/, 'nvconfig_new'))
        
        # Iterate all the table for difference
        lst_tables.each do |table_name, columns|
          if (table_name.to_s.start_with?("CDL", "Wizard"))
            exist_records = db2.execute("Select * from " + table_name.to_s)
            if (!exist_records.blank?)
              File.open(session[:cfgsitelocation]+'/update_DB_Log.log', 'a') do |f|
                f.puts "-------------------------------------------------"
                f.puts "Inserting records into " + table_name.to_s + " table"
                f.puts "-------------------------------------------------"
                exist_records.each do |cdl|                  
                  insrt_sql = 'Insert Into ' + table_name.to_s + ' Values("' + cdl.join('","') + '")'
                  db1.execute(insrt_sql)
                  f.puts "ID :: " + cdl.join("      ")
                end
              end
            end
          else
            db1_results = db1.execute("select * from  #{table_name.to_s}")
            db2_results = db2.execute("select * from  #{table_name.to_s}")
            
            db1_nv_results_formated = []
            db1_results.each do |db1_result|
              db1_nv_results_formated << db1_result[0,6].join('_$$_')
            end
            
            db2_nv_results_formated = []
            db2_results.each do |db2_result|
              db2_nv_results_formated << db2_result[0,6].join('_$$_')
            end
            
            res = db2_nv_results_formated - db1_nv_results_formated
            if(res.length > 0)
              File.open(session[:cfgsitelocation]+'/update_DB_Log.log', 'a') do |f|
                f.puts "-------------------------------------------------"
                f.puts "Updating records into " + table_name.to_s + " table"
                f.puts "-------------------------------------------------"
                res.each do |v|
                  where_conditions = ""
                  set_value = ""
                  column_values = v.split("_$$_")
                  record_id = column_values[0] # ID
                  record_value = column_values[5] # Record value
                  where_conditions = (columns[0] + " = '" + record_id +"'")
                  if record_value.blank?
                    set_value = "#{columns[1]} = ''"
                  else
                    set_value = (columns[1] + " = '" + record_value +"'")  
                  end
                  
                  existing_records = db1.execute("Select * from  #{table_name.to_s}  Where #{where_conditions}")
                  if(existing_records.length > 0)
                    strsql = "Update #{table_name.to_s}  Set #{set_value}  Where #{where_conditions}"
                    db1.execute(strsql)
                    f.puts "#{columns[0]} :: #{column_values[0]}"
                    f.puts "#{columns[1]} :: #{column_values[5]}"
                  end
                end
              end
            end       #if(res.length > 0)
          end     #if (table_name.start_with?("CDL"))
        end
        delete_old_file = true
      end
      db1.close
      db2.close
      if(delete_old_file)
        # delete old db from the site location
        File.delete(options[:db2])
        # rename newly copied db(which is from initial DB) to old db name
        File.rename(options[:db2].sub(/nvconfig/, 'nvconfig_new'), options[:db2])
      end
      return ""
    rescue Exception => e
      File.open(session[:cfgsitelocation]+'/update_DB_Log.log', 'a') do |f|
        f.puts "Exception raised while updating database"
        f.puts "Error Message: "
        f.puts "-------------------------------------------------"
        f.puts e.message
        f.puts "-------------------------------------------------"
      end
      return "InValid Non vital configuration. " + e.message
    end
  end
end