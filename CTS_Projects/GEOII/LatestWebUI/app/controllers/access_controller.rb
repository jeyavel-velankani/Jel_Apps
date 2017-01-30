####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan 
# File: access_controller.rb
# Description: This module used to authenticate the login user and allow them  
####################################################################
#History:
# Log: /wayside/GEOII/Trunk/Software/WebUI/app/controllers/access_controller.rb
#
# Rev 5266   Sep 03 2013 15:00:00   Jeyavel Natesan
# Initial version
class AccessController < ApplicationController
  include SelectsiteHelper
  include ReportsHelper
  include UdpCmdHelper
  skip_before_filter :authorize
  if OCE_MODE == 1
    require 'win32/registry'
    require 'win32ole'
    require 'socket'
    require 'timeout'
  end
  layout "loginpage"
  
  ####################################################################
  # Function:      login_access 
  # Parameters:    None
  # Retrun:        session[:user_id]
  # Renders:       None
  # Description:   Display login access page
  ####################################################################
  def login_access
    session[:user_id] = nil
  end
  
  ####################################################################
  # Function:      check_user_presence 
  # Parameters:    N/A
  # Retrun:        @user_presence
  # Renders:       text
  # Description:   Checks user presence
  ####################################################################
  def check_user_presence
    @user_presence = (Uistate.vital_user_present)? true : false
    render :text => @user_presence 
  end
  
  ####################################################################
  # Function:      request_user_presence 
  # Parameters:    atcs_addr geo(optional)
  # Retrun:        request_id
  # Renders:       N/A
  # Description:   request the user presence
  ####################################################################
  def request_user_presence(atcs_addr, geo = false)
    sub_command = (geo) ? 2 : 1
    simplerequest = RrSimpleRequest.create({:atcs_address => atcs_addr + ".02", :command => 1, :subcommand => sub_command, :request_state => 0, :result => ""})
    udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, simplerequest.request_id)
    return simplerequest.request_id
  end
  
  ####################################################################
  # Function:      check_user_presence_request_state 
  # Parameters:    request_id 
  # Retrun:        error, request_state, message
  # Renders:       json
  # Description:   request the user presence
  ####################################################################
  def check_user_presence_request_state
    simple_request = RrSimpleRequest.find_by_request_id(params[:request_id], :select => "request_id, request_state, result")
    if simple_request !=nil
      if simple_request.request_state == 2 
        ui_state = Uistate.vital_user_present
        user_presence = ui_state ? (simple_request.result == 0 ? true : false) : false
        message = user_presence ? "Successfully unlocked parameters" : "Unlock parameters failed"
        render :json => { :error => !user_presence, :request_state => simple_request.request_state, :message => message}
      else
        render :json => {:request_state => simple_request.request_state}
      end
    else
      render :json =>{:error => "no db"}
    end
  end
  
  ####################################################################
  # Function:      authenticate 
  # Parameters:    params[:selectedusername]
  # Retrun:        None
  # Renders:       None
  # Description:   Authenticate user level
  ####################################################################
  def authenticate
    clear_old_req_rep
    clearAllValue_Sessions
    if request.post?
      if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
        #ver = YAML.load_file(RAILS_ROOT+"/config/OCE_version.yml")
        session[:webui_version] = WEBUI_VERSION #ver["webui"]["version"]
        @username = params[:selectedusername]
        close_database_connection
      else
        cp_ver = SoftwareVersions.find(:first, :conditions => ["sw_type = 'MEF' and sw_9V_number like ?","9VC52%"])
        if cp_ver
          session[:webui_version] =  "#{cp_ver.version}.#{cp_ver.build_number}"
        end
        @username = params[:selectedusername].strip
      end
      
      time_db = get_session_logout    #from application helper
      
      if  single_user?   #a function from application helper
        check_uesrs = CurrentUsers.find(:all)
        @check_uesrs = check_uesrs
      end
      
      if check_uesrs && check_uesrs.length > 0 && check_uesrs[0][:session_id] != session[:session_id] && Time.now < check_uesrs[0][:keep_alive] && single_user?   #a function from application helper
        flash.now[:notice] = "A user is already logged in."
        render :action => "login_form"
      else
        if  single_user?   #a function from application helper
          CurrentUsers.delete_all
        end
        
        valid_user = ""
        
        if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
          value = ""
          Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Safetran\OCE') do |reg|
            value = reg['OCE_ROOT'] 
          end
          if File.directory?(value)
            session[:OCE_ROOT] = value
          else
            if File.directory?("C:\\Program Files\\Common Files\\SAFETRAN\\OCE")
              session[:OCE_ROOT] = "C:\\Program Files\\Common Files\\SAFETRAN\\OCE"
            elsif File.directory?("C:\\Program Files (x86)\\Common Files\\SAFETRAN\\OCE")
              session[:OCE_ROOT] = "C:\\Program Files (x86)\\Common Files\\SAFETRAN\\OCE"
            else
              session[:OCE_ROOT] = "C:\\Program Files\\Common Files\\SAFETRAN\\OCE"
            end
          end
          
          if @username == "oceadmin"
            valid_user = Users.find_by_name("OCE Admin", :conditions => ["password = ?", params[:password]])
          elsif @username == "admin"
             valid_user = Users.find_by_name("admin", :conditions => ["password = ?" ,params[:password]])
          end
        elsif PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI
          valid_user = StringParameter.find_by_Name("WebUI password", :conditions => ["String = ? and Group_ID = 17 and Group_Channel = 0", params[:password]])
        else
          valid_user = StringParameter.find_by_Name("WebUI password", :conditions => ["String = ? and Group_ID = 17 and Group_Channel = 0", params[:password]])
        end
        if valid_user
          session[:user_id] = @username
          if PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE
            session[:alarms_check] = check_alarms
          end
          if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
            if !File.directory?(RAILS_ROOT+'/oce_configuration')
              Dir.mkdir(RAILS_ROOT+'/oce_configuration')
            end
            rootpath = RAILS_ROOT+'/oce_configuration/'+session[:user_id].to_s
            masterdbpath = RAILS_ROOT+'/Masterdb'
            # check oce_configuration/user folder available or not - if not create oce_configuration/user folder in application root
            if File.directory?(rootpath)
              if !File.directory?(rootpath+'/tmp')
                Dir.mkdir(rootpath+'/tmp')
              end
              if !File.directory?(rootpath+'/xmltemplate')
                Dir.mkdir(rootpath+'/xmltemplate')
              end
            else
              Dir.mkdir(rootpath)
              Dir.mkdir(rootpath+'/tmp')
              Dir.mkdir(rootpath+'/xmltemplate')
            end
            # check master db folder available or not - if not create Masterdb folder in application root
            if !File.directory?(masterdbpath)
              Dir.mkdir(RAILS_ROOT+'/Masterdb')
            end
            session[:OCE_ConfigPath] = rootpath+'/'
            session[:aspectfilepath] = nil
            session[:aspectfilepath] = current_geoaspectfile
          elsif (PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI)
            simplerequest = RrSimpleRequest.create(:request_state => 0, :command => 11, :subcommand => 0, 
                                              :value => "Log in", :source => "WebUser")
            udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, simplerequest.id)
            
            gcpmcftype = Gwe.find(:all,:select =>"mcf_location").map(&:mcf_location)
          end
          if params[:password] != nil
            flash[:check_diag] = 1
            login_user
          else
            flash[:check_diag] = 0
            login_user
          end
        else
          flash.now[:notice] = "Invalid Password"
          render :action => "login_form"
        end
      end
    else
      render :action => "login_form" 
    end  
  end

  def clear_old_req_rep
    time =  (-6).hour.from_now.to_s

    LogRequest.delete_all("created_at < '"+time+"'")
    CDLCompilerReq.delete_all("created_at < '"+time+"'")              #rr_cdl_compiler_requests
    #missing rr_connect_requests
    Rrdownloadfile.delete_all("created_at < '"+time+"'")              #rr_download_requests
    RrGeoIOStatus.delete_all("created_at < '"+time+"'")               #rr_geo_io_status
    RrGeoIOReplies.delete_all("created_at < '"+time+"'")              #rr_geo_io_status_replies
    RrGeoIOStatusValues.delete_all("created_at < '"+time+"'")         #rr_geo_io_status_values
    RrGeoLogReply.delete_all("created_at < '"+time+"'")               #rr_geo_log_replies
    RrGeoLogRequest.delete_all("created_at < '"+time+"'")             #rr_geo_log_requests
    Nonvitaltimer.delete_all("created_at < '"+time+"'")               #rr_geo_nvital_cfg
    Nvconfigprop.delete_all("created_at < '"+time+"'")                #rr_geo_nvital_cfg_values
    ObjectName.delete_all("created_at < '"+time+"'")                  #rr_geo_obj_requests
    RrGeoStatsCardInfo.delete_all("created_at < '"+time+"'")          #rr_geo_stats_card_info
    #rr_geo_stats_requests
    AtcsSin.delete_all("created_at < '"+time+"'")                     #rr_geo_vital_prop
    Vitalpropvalue.delete_all("created_at < '"+time+"'")              #rr_geo_vital_prop_values
    HiddenParam.delete_all("created_at < '"+time+"'")                 #rr_hidden_params
    #rr_install_ech_mod
    RrIsReplies.delete_all("created_at < '"+time+"'")                 #rr_is_replies
    RrIsRequests.delete_all("created_at < '"+time+"'")                #rr_is_requests
    LocationRequest.delete_all("created_at < '"+time+"'")             #LocationRequest
    LogFilter.delete_all("created_at < '"+time+"'")                   #rr_log_filters
    ReqRepLogReplies.delete_all("created_at < '"+time+"'")            #rr_log_replies
    LogRequest.delete_all("created_at < '"+time+"'")                  #rr_log_requests
    #rr_log_types
    RrLogVerboRequests.delete_all("created_at < '"+time+"'")          #rr_log_verbo_requests
    RrLsSpecificRequest.delete_all("created_at < '"+time+"'")         #rr_ls_specific_request
    Rrpacuploadrequest.delete_all("created_at < '"+time+"'")          #rr_pac_upload_request
    RebootRequest.delete_all("created_at < '"+time+"'")               #rr_reboot_requests
    #rr_report_replies
    ReportsDb.delete_all("created_at < '"+time+"'")                   #rr_report_requests
    RrSafeMode.delete_all("created_at < '"+time+"'")                  #rr_safe_mode
    SetCfgPropertyRequest.delete_all("created_at < '"+time+"'")       #rr_set_cfg_prop_requests
    SetPropIviuCard.delete_all("created_at < '"+time+"'")             #rr_set_prop_iviu_cards
    SetPropIviuParam.delete_all("created_at < '"+time+"'")            #rr_set_prop_iviu_params
    SetCfgPropertyiviuRequest.delete_all("created_at < '"+time+"'")   #rr_set_prop_iviu_requests
    SetTimeRequest.delete_all("created_at < '"+time+"'")              #rr_set_time_requests
    SetUcnRequest.delete_all("created_at < '"+time+"'")               #rr_set_ucn_requests
    RrSimpleRequest.delete_all("created_at < '"+time+"'")             #rr_simple_requests
    RrUnsolicitedEvent.delete_all("created_at < '"+time+"'")          #rr_unsolicited_events
    SoftwareUpload.delete_all("created_at < '"+time+"'")              #rr_upload_file_requests
    RrFileUploadslot.delete_all("created_at < '"+time+"'")            #rr_upload_file_to_slots
    VerifyDataIviuRequest.delete_all("created_at < '"+time+"'")       #rr_verify_data_iviu_requests
    VerifyScreenIviuRequest.delete_all("created_at < '"+time+"'")     #rr_verify_screen_iviu_requests
    VerifyScreenParam.delete_all("created_at < '"+time+"'")           #rr_verify_screen_params
    VerifyScreenRequest.delete_all("created_at < '"+time+"'")         #rr_verify_screen_requests

  end

  def login_user
    time_db = get_session_logout    #from application helper
    if (PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI)
      current_user = CurrentUsers.find(:all, :conditions => ['session_id = ?',session[:session_id]])
      
      if current_user.blank?
        CurrentUsers.create(:session_id => "#{session[:session_id]}", :keep_alive => time_db.minute.from_now)
      else
        CurrentUsers.update_all("keep_alive = '#{time_db.minute.from_now}'","session_id = '#{session[:session_id]}'")
      end
    end
    redirect_to :controller=>"home"
  end
  
  ####################################################################
  # Function:      home 
  # Parameters:    None
  # Retrun:        None
  # Renders:       None
  # Description:   Redirect to login page if user session not available
  ####################################################################  
  def home
    if !session[:user_id]
      redirect_to :action=> 'login'
    end
  end
  
  ####################################################################
  # Function:      redirect_home 
  # Parameters:    None
  # Retrun:        None
  # Renders:       None
  # Description:   Redirect the home/login page
  ####################################################################
  def redirect_home
    if session[:user_id]=="admin"
      redirect_to :controller=>'authenticateduser' ,:action=> 'index'
    else
      session[:logerror] = nil
      redirect_to :controller => 'access', :action=> 'login_form'
    end
  end
  
  ####################################################################
  # Function:      logout 
  # Parameters:    session[:user_id]
  # Retrun:        None
  # Renders:       None
  # Description:   Logout the user session
  ####################################################################  
  def logout
    if (PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI)
      CurrentUsers.delete_all("session_id = '#{session[:session_id]}'")
    end

    reset_session
    clearAllValue_Sessions
    session[:user_id] = nil
    session[:logerror] = nil
    session[:alarms_check] = nil
    if (PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI)
      simplerequest = RrSimpleRequest.create(:request_state => 0, :command => 11, :subcommand => 0, 
                                              :value => "Log out", :source => "WebUser")
      udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, simplerequest.id)
    
      event_string = "WebUser Log out\r\n"
    end

    redirect_to :controller=>'access', :action=> 'login_form' 
  end
  
  ####################################################################
  # Function:      login_form 
  # Parameters:    None
  # Retrun:        None
  # Renders:       None
  # Description:   Open the login page if user id available
  ####################################################################  
  def login_form
    redirect_to :controller=>'home' if session[:user_id]
  end
  
  ####################################################################
  # Function:      request_user_presence 
  # Parameters:    params[:session_flag]
  # Retrun:        None
  # Renders:       None
  # Description:   method to set parameters edit mode/requesting user presence
  ####################################################################  
  def request_user_presence
    atcs_address_val = atcs_address
    if(params[:session_flag].to_s == 'false')
      atcs_address_val = Generalststistics.vlp_sin if atcs_address_val.blank?
    end
    ui_state = Uistate.vital_user_present
    unless (ui_state)
      request_id = set_user_presence(atcs_address_val)
      render :json => {:user_presence => false, :request_id => request_id, :atcs_address => atcs_address_val}
    else
      render :json => {:user_presence => true, :message => "Parameters already unlocked"}
    end
  end

  ####################################################################
  # Function:      check_user_presence_request_state 
  # Parameters:    params[:request_id]
  # Retrun:        None
  # Renders:       None
  # Description:   method to check user presence state
  ####################################################################  
  def check_user_presence_request_state
    simple_request = RrSimpleRequest.find_by_request_id(params[:request_id], :select => "request_id, request_state, result")
    if simple_request !=nil
      if simple_request.request_state == 2 
        ui_state = Uistate.vital_user_present
        user_presence = ui_state ? (simple_request.result == 0 ? true : false) : false
        message = user_presence ? "Unlock Successful. System is in edit mode now." : "Unlock failed! System is not in edit mode."
        delete_request(params[:request_id], REQUEST_COMMAND_SIMPLE_REQUEST)
        render :json => { :error => !user_presence, 
          :request_state => simple_request.request_state, :message => message}
      else
        delete_request(params[:request_id], REQUEST_COMMAND_SIMPLE_REQUEST) if(params[:delete_request] == "true")
        render :json => {:request_state => simple_request.request_state}
      end
    else
      render :json =>{:error => "no db"}
    end
  end

end
