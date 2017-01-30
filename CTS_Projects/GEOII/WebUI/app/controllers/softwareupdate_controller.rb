####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: softwareupdate_controller.rb
# Description: Upload/Download the Vital/Non-Vital system configuration files 
####################################################################
class SoftwareupdateController < ApplicationController  
  layout "general" 
  include UdpCmdHelper
  include GenericHelper
  include SessionHelper
  
  before_filter :cpu_status_redirect , :only => [:configuration]  #session_helper
  
  ####################################################################
  # Function:      udp_request_download
  # Parameters:    None
  # Retrun:        rrdownload
  # Renders:       render :text
  # Description:   udp request download
  ####################################################################
  def udp_request_download
    rt_download = Rrdownloadfile.find(:last)
    if(rt_download && rt_download.request_state.to_i == 1)
      render :text => "" 
    else
      atcs_value_val = StringParameter.string_select_query(4)
      rrdownload = insert_download(atcs_value_val)
      udp_send_cmd(REQUEST_COMMAND_CONF_PACKAGE_UPLOAD, rrdownload.request_id)
      render :text => rrdownload.request_id
    end
  end
  
  ####################################################################
  # Function:      insert_download
  # Parameters:    None
  # Retrun:        None
  # Renders:       None
  # Description:   insert download
  ####################################################################
  def insert_download(atcs_address_val)
    Rrdownloadfile.create({:atcs_address => atcs_address_val, :request_state => 0})
  end
  
  ####################################################################
  # Function:      get_download_status
  # Parameters:    None
  # Retrun:        None
  # Renders:       render :json 
  # Description:   get download status
  ####################################################################
  def get_download_status
    downloadfile = Rrdownloadfile.find(:last,:select =>"request_state ,percent_complete , full_path ,file_name , result ,status_message" , :conditions =>['request_id = ? ',params[:request_id]])
    percentage = 0
    unless downloadfile.percent_complete.blank?
      percentage = downloadfile.percent_complete
    end  
    render :json => { :request_state => downloadfile.request_state , 
                      :percent_complete => percentage ,
                      :full_path => downloadfile.full_path ,
                      :file_name => downloadfile.file_name ,
                      :result => downloadfile.result,
                      :status_message => downloadfile.status_message}
  end
  
  ####################################################################
  # Function:      download_txtfile
  # Parameters:    params[:id]
  # Retrun:        file_name , path
  # Renders:       send_file(path)
  # Description:   Download the given file from path
  ####################################################################
  def download_txtfile
    path = params[:id]
    file_name = File.basename(path)
    send_file(path ,:filename => file_name , :type=>'text/plain' , :disposition => 'attachment', :stream=>true)
  end
  
  ####################################################################
  # Function:      get_atcs_address
  # Parameters:    None
  # Retrun:        None
  # Renders:       None
  # Description:   Get the current ATCS address 
  ####################################################################
  def get_atcs_address
    atc_temp = Gwe.find(:first, :select => "sin").try(:sin)

    if atc_temp.blank?
      return  Generalststistics.vlp_sin
    else
      return atc_temp
    end
  end
  
  ####################################################################
  # Function:      cpumodule_upload
  # Parameters:    None
  # Retrun:        None
  # Renders:       render :text => @sear_status.comm_status
  # Description:   Vital CP/Module page Load
  ####################################################################
  def cpumodule_upload
    get_user_presence_val    
    if !params[:fileupload_flag].blank?
      rt_console = RtConsole.find(:first)
      @upload_options = RtConsoleOptions.find(:all, :conditions =>['console_id=?',rt_console.console_id])
    end
    @firm_type = ''
    @target = params[:target]
    @mcfcrc = params[:mcfcrc1]
    if @mcfcrc
      @mcfcrcval = @mcfcrc.hex
    end
    @file_type = params[:update_type]
    @atcs_addr = get_atcs_address
    if(params[:fileToUpload] || @mcfcrcval)
      config = open_ui_configuration      
      @mcf = config["upload_directory"]["iviu_mcf"]
      @mef = config["upload_directory"]["iviu_mef"]
      case @file_type.to_s
        when '1'
        @firm_type = @mcf
        when '2'
        @firm_type = @mef
        when '7'
        @firm_type = 7
      else
        @firm_type = @mef
      end
      if params[:fileToUpload] && !params[:fileToUpload].original_filename.blank?
        temp = params[:fileToUpload].original_filename
        temp2 = params[:fileToUpload].read
        localpath = params[:fileToUpload].local_path
      end
      @temp = temp
      if @firm_type != 7 
        @continue = !(SoftwareUpload.upload_file(@temp, @firm_type, temp2, true))? 2:1
      else
        @continue =1 
      end
      save_software_upload(@target, 3, @temp, @firm_type, @atcs_addr, @file_type, @mcfcrc)
    end
  end
  
  ####################################################################
  # Function:      softwareupdate_upload_status
  # Parameters:    params[:request_id]
  # Retrun:        @status
  # Renders:       render :json
  # Description:   Get tha status of upload files
  ####################################################################
  def softwareupdate_upload_status
    @status =  SoftwareUpload.find_by_request_id(params[:request_id])
    unless @status.blank?
      render :json => { :request_id => @status.request_id , :request_state => @status.request_state ,:result => @status.result ,:percentage_complete => @status.percentage_complete , :error_message => @status.error_message  }    
    else
      render :text => ""
    end
  end
  
  ####################################################################
  # Function:      initiate_softwareupdate
  # Parameters:    None
  # Retrun:        softupdate
  # Renders:       render :json => {:request_id =>softupdate.request_id }
  # Description:   install software update - initiate software update
  ####################################################################
  def initiate_softwareupdate
    @user_message = ""
    rt_exist_val = RtConsole.find(:last)
    val = (Time.now.to_i - rt_exist_val.last_viewed.to_i) unless rt_exist_val.blank?
    if ( rt_exist_val.blank? || rt_exist_val.last_viewed.to_i == 0 || val.to_i >= 120)
      softupdate = SoftwareUpload.new
      softupdate.request_state = 0
      softupdate.atcs_address = get_atcs_address
      softupdate.target = 4
      softupdate.file_type = FILE_TYPE_NONE
      softupdate.save
      if rt_exist_val.blank?
        RtConsole.create(:console_id => softupdate.request_id ,:last_viewed => Time.now.to_i)
      end
      RtConsole.update_all({:console_id => softupdate.request_id , :last_viewed => Time.now.to_i , :options_enabled => 0})
      udp_send_cmd(REQUEST_COMMAND_UPLOAD_FILE, softupdate.request_id )
      render :json => {:request_id =>softupdate.request_id }
    else
      render :json => {:request_id =>"" }
    end
  end
  
  ####################################################################
  # Function:      get_software_update_options
  # Parameters:    params[:console_id]
  # Retrun:        @options_enabled , @upload_options , @user_message
  # Renders:       page.replace_html  'upload_files_list'
  # Description:   Get the options menu from the system and the enabled status
  ####################################################################
  def get_software_update_options
    @user_message = ""
    @upload_options = ""
    console_id = params[:console_id]
    unless console_id.blank?
      rt_console = RtConsole.find(:last)
      unless rt_console.blank?
        @options_enabled = rt_console.options_enabled.to_i
        @upload_options = RtConsoleOptions.find(:all, :conditions =>['console_id=?',rt_console.console_id.to_i])  
      end
    else
      @user_message = "Another software upload in progress so please refer the console text log."
    end
    render :update do |page|
      page.replace_html  'upload_files_list', :partial=>'softwareupdate_options' 
    end 
  end
  
  ####################################################################
  # Function:      get_software_update_options_status
  # Parameters:    params[:console_id]
  # Retrun:        initiate_swupdate , console_id
  # Renders:       render :json
  # Description:   get the options menu request ststus
  ####################################################################
  def get_software_update_options_status
    console_id = params[:console_id]
    initiate_swupdate = SoftwareUpload.find(:last,:select =>"request_state , result , percentage_complete , error_message ",:conditions=>["request_id=?",console_id.to_i])
    render :json => {:request_id =>console_id ,:request_state => initiate_swupdate.request_state , :result => initiate_swupdate.result , :percentage_complete => initiate_swupdate.percentage_complete , :error_message => initiate_swupdate.error_message}
  end
  
  ####################################################################
  # Function:      save_software_upload
  # Parameters:    target, port, filename, path, atcs_addr, filetype, mcfcrc
  # Retrun:        @upload_options , @status
  # Renders:       None
  # Description:   Save upload files
  ####################################################################
  def save_software_upload(target, port, filename, path, atcs_addr, filetype, mcfcrc)
    console_id = RtConsole.find(:last).try(:console_id)
    if filetype.to_s == '7'
      RtConsoleQuestions.update_all(:answer => mcfcrc.to_s)
      SoftwareUpload.update_all({:request_state => 0 ,:atcs_address => atcs_addr.to_s + '.01' ,:mcfcrc => mcfcrc , :file_type => filetype ,  :result => 0 , :percentage_complete => 0 , :port => 3 },{:request_id => console_id.to_i })
    else
      RtConsoleQuestions.update_all(:answer => filename.to_s)
      SoftwareUpload.update_all({:request_state => 0 ,:atcs_address => atcs_addr.to_s , :file_name => filename , :path => path ,:file_type => filetype , :result => 0 , :percentage_complete => 0 , :port => 3 },{:request_id => console_id.to_i })    
    end
    udp_send_cmd(REQUEST_COMMAND_UPLOAD_FILE, console_id.to_i)
    @status =  SoftwareUpload.find_by_request_id(console_id.to_i)
    @upload_options = RtConsoleOptions.find(:all, :conditions =>['console_id=?',console_id.to_i])
  end
  
  ####################################################################
  # Function:      get_questions
  # Parameters:    None
  # Retrun:        console_id
  # Renders:       render :json => {:console_id => console_id}
  # Description:   Get the current questions value from the Questions table
  ####################################################################
  def get_questions
    options_selected = params[:options_selected]
    update_type = params[:file_type] 
    console_id = params[:console_id]
    RtConsoleOptions.update_all({:selected => 1},{:console_id => console_id ,:command_code => options_selected.to_i })
    SoftwareUpload.update_all({:request_state => 0 ,:file_type => update_type , :result => 0 ,:percentage_complete => 0},{:request_id => console_id })
    udp_send_cmd(REQUEST_COMMAND_UPLOAD_FILE, console_id.to_i)
    #    sleep 3
    render :json => {:console_id => console_id}
  end
  
  ####################################################################
  # Function:      get_console_text
  # Parameters:    None
  # Retrun:        @sear_status
  # Renders:       render :json => {:text => combined_text}
  # Description:   Read the console text from the Console text table 
  ####################################################################
  def get_console_text
    console_id = ""
    rt_console_text = ""
    combined_text = ""
    display_text = params[:display_text]
    if display_text.to_s == 'all'
      rt_console = RtConsole.find(:last)
      unless rt_console.blank?
        console_id = rt_console.try(:console_id)
        rt_console_text = RtConsoleText.find(:all,:conditions => ['console_id=?',console_id])
      end
    else
      console_id = params[:console_id]
      rt_console_text = RtConsoleText.find(:all,:conditions => ['console_id=?',console_id])
    end
    unless rt_console_text.blank?
      rt_console_text.each do |text|
        combined_text = combined_text + text.console_text + "\r\n\r\n"
      end
    end
    render :json => {:text => combined_text}
  end
  
  ####################################################################
  # Function:      update_console_last_viewed
  # Parameters:    None
  # Retrun:        None
  # Renders:       render :text => ""
  # Description:   Sear Status
  ####################################################################
  def update_console_last_viewed
    RtConsole.update_all(:last_viewed => Time.now.to_i)
    render :text => ""
  end
  
  ####################################################################
  # Function:      questions_status
  # Parameters:    params[:console_id]
  # Retrun:        console_id ,sw_questions_status
  # Renders:       render :json
  # Description:   Get value for the requested question status
  ####################################################################
  def questions_status
    console_id = params[:console_id]
    sw_questions_status = SoftwareUpload.find(:last,:select =>"request_state , result , percentage_complete",:conditions=>["request_id=?",console_id])
    render :json => {:console_id =>console_id ,:request_state => sw_questions_status.request_state ,:result => sw_questions_status.result ,:percentage_complete =>sw_questions_status.percentage_complete}
  end
  
  ####################################################################
  # Function:      get_fileupload_user_level_status
  # Parameters:    None
  # Retrun:        initiate_swupdate
  # Renders:       render :json
  # Description:   Get the file uploading/downloading current status
  ####################################################################
  def get_fileupload_user_level_status
    console_id = RtConsole.find(:last).try(:console_id)
    initiate_swupdate = SoftwareUpload.find(:last,:select =>"request_state , result , percentage_complete",:conditions=>["request_id=?",console_id.to_i])
    render :json => {:percentage_complete => initiate_swupdate.percentage_complete}
  end
  
  ####################################################################
  # Function:      read_questions
  # Parameters:    params[:console_id]
  # Retrun:        questions_val
  # Renders:       render :json
  # Description:   Read the current questions from the questions table
  ####################################################################
  def read_questions
    console_id = params[:console_id]
    questions_val = RtConsoleQuestions.find(:last,:conditions =>['console_id=?',console_id])
    if questions_val.blank?
      render :text => ""
    else
      render :json => {:question => questions_val.question ,:question_type => questions_val.question_type}
    end
  end
  
  ####################################################################
  # Function:      update_answer
  # Parameters:    params[:console_id] , params[:file_type] , params[:answer]
  # Retrun:        console_id
  # Renders:       render :json => {:console_id => console_id}
  # Description:   Update the answer with questions table 
  ####################################################################
  def update_answer
    console_id = params[:console_id]
    update_type = params[:file_type]
    answer =  if update_type.to_i == 7 
      params[:answer].hex
    else
      params[:answer]
    end
    RtConsoleQuestions.update_all(:answer => answer )
    if update_type.to_s == '7'
      SoftwareUpload.update_all({:request_state => 0 , :mcfcrc => answer ,:file_type => update_type , :result => 0 , :percentage_complete => 0 },{:request_id => console_id })
    else
      SoftwareUpload.update_all({:request_state => 0 ,:file_type => update_type , :result => 0 , :percentage_complete => 0 },{:request_id => console_id })
    end
    udp_send_cmd(REQUEST_COMMAND_UPLOAD_FILE, console_id.to_i )
    sleep 2
    render :json => {:console_id => console_id}
  end
  
  ####################################################################
  # Function:      exit_softwareupdate
  # Parameters:    params[:console_id]
  # Retrun:        console_id
  # Renders:       render :json =>{:console_id => console_id } 
  # Description:   Exit setup options functionality
  ####################################################################
  def exit_softwareupdate
    console_id =  params[:console_id]
    SoftwareUpload.update_all({:request_state => 0, :file_type => FILE_TYPE_EXIT_SOFTWARE , :result => 0 } , {:request_id => console_id})
    udp_send_cmd(REQUEST_COMMAND_UPLOAD_FILE, console_id.to_i )
    render :json =>{:console_id => console_id } 
  end
  
  ####################################################################
  # Function:      exit_setup_status
  # Parameters:    params[:console_id]
  # Retrun:        request_state
  # Renders:       render :json =>{:request_state => request_state }
  # Description:   exit_setup_status
  ####################################################################
  def exit_setup_status
    console_id =  params[:console_id] #RtConsole.find(:last).try(:console_id)
    request_state = SoftwareUpload.find(:last,:select =>"request_state",:conditions =>["request_id =?", console_id]).try(:request_state)
    render :json =>{:request_state => request_state }
  end
  
  ####################################################################
  # Function:      exit_sw_update_page
  # Parameters:    None
  # Retrun:        exit_sw_update
  # Renders:       render :text => ""
  # Description:   Exit Software update page functionality
  ####################################################################
  def exit_sw_update_page
    atcs_address_lup =  get_atcs_address
    atcs_address_lup = "7.000.000.000.00" if atcs_address_lup.blank?
    exit_sw_update = SoftwareUpload.create({:atcs_address => atcs_address_lup + ".01" , :target => 4 ,:file_type =>FILE_TYPE_EXIT_SOFTWARE_UPDATE_PAGE, :request_state => 0 })
    udp_send_cmd(REQUEST_COMMAND_UPLOAD_FILE, exit_sw_update.request_id)
    render :text => ""
  end
  
  ####################################################################
  # Function:      abort_cancel_sw_update
  # Parameters:    params[:console_id]
  # Retrun:        request_id
  # Renders:       render :json => {:request_id => request_id}
  # Description:   Abort software update process
  ####################################################################
  def abort_cancel_sw_update
    request_id = nil
    unless params[:console_id].blank?
      request_id = params[:console_id].to_i
      SoftwareUpload.update_all({:request_state => 0, :file_type => FILE_TYPE_ABORT_CANCEL_SOFTWARE_UPDATE , :target => 4 , :result => 0 } , {:request_id => request_id})
    end
    udp_send_cmd(REQUEST_COMMAND_UPLOAD_FILE, request_id)
    render :json => {:request_id => request_id}
  end
  
  ####################################################################
  # Function:      abort_cancel_sw_update_status
  # Parameters:    params[:request_id]
  # Retrun:        cancel_upload_status
  # Renders:       render :json 
  # Description:   Get the Abort software update process status
  ####################################################################
  def abort_cancel_sw_update_status
    request_id = params[:request_id]
    cancel_upload_status = SoftwareUpload.find(:last, :select => 'request_id , request_state, result ,error_message', :conditions => ['request_id = ?',request_id])
    render :json => {:request_id => cancel_upload_status.request_id , :request_state => cancel_upload_status.request_state ,:result => cancel_upload_status.result , :error_message => cancel_upload_status.error_message }
  end
  
  ####################################################################
  # Function:      configuration
  # Parameters:    None
  # Retrun:        @userpresence_permission , uistate
  # Renders:       None
  # Description:   load configuration upload/download page
  ####################################################################
  def configuration
    get_user_presence_val
    @product_type = Menu.cpu_3_menu_system
  end
  
  ####################################################################
  # Function:      configuration_upload
  # Parameters:    None
  # Retrun:        softupdate , config ,target , iviu_pac , pacupload
  # Renders:       :text=> {:request_id=> request_id }.to_json
  # Description:   Process the user uploaded files to the corresponding system
  ####################################################################
  def configuration_upload
    config = open_ui_configuration
    iviu_conf_package = config["upload_directory"]["iviu_pac"] #20
    nv_cfg = config["upload_directory"]["iviu_nv_cfg"] # 10
    v_cfg =  config["upload_directory"]["iviu_v_cfg"] # 11
    nv_rc2 =  config["upload_directory"]["iviu_nv_rc2"] #9
    file_type = params[:update_type]
    target = params[:target]
    if(params[:fileToUpload])
      case file_type.to_i
        when FILE_TYPE_RC2KEY
        firm_type = nv_rc2
        when FILE_TYPE_NV_DB
        firm_type = nv_cfg
        when FILE_TYPE_CIC_BIN
        firm_type = v_cfg
        when FILE_TYPE_CONF_PACKAGE_ZIP
        firm_type = iviu_conf_package
      else
        firm_type = '/tmp/upload'
      end
    end
    filename = ""
    request_id = ""
    if params[:fileToUpload]
      filename = params[:fileToUpload].original_filename
      filecontent = params[:fileToUpload].read
      SoftwareUpload.upload_file(filename, firm_type, filecontent, true)
      atcs_address_val = StringParameter.string_select_query(4)
      softupdate = SoftwareUpload.create({:request_state=> 0, :atcs_address=> atcs_address_val, :target=> target.to_i ,:path=> firm_type , :file_name=> filename , :file_type=> file_type.to_i})
      request_id = softupdate.request_id
      udp_send_cmd(REQUEST_COMMAND_UPLOAD_FILE ,request_id)
    end
    render :text => request_id
  end
  
  ####################################################################
  # Function:      configuration_upload_status
  # Parameters:    params[:request_id]
  # Retrun:        request_id , upload_status
  # Renders:       :json => { :request_state => upload_status.request_state}
  # Description:   Check the configuration uploaded process status 
  ####################################################################
  def configuration_upload_status
    request_id = params[:request_id]
    upload_status_record_val = SoftwareUpload.find(:last,:conditions=>["request_id=?",request_id])
    delete_request(params[:request_id], REQUEST_COMMAND_UPLOAD_FILE) if upload_status_record_val.request_state == 2
    render :json => { :request_state => upload_status_record_val.request_state ,
                      :result => upload_status_record_val.result ,
                      :error_message =>upload_status_record_val.error_message,
                      :percent_complete => upload_status_record_val.percentage_complete}
  end
  
  ####################################################################
  # Function:      download_system_file
  # Parameters:    None
  # Retrun:        full_path , file_name
  # Renders:       send_file
  # Description:   Download the configuration system file
  ####################################################################
  def download_system_file
    config = open_ui_configuration
    path =  config["ecd"]["download_dir"] if params[:id].to_i == 9 # Rc2key.bin
    path =  config["ecd"]["download_dir"] if params[:id].to_i == 10 # NVCONFIG.SQL3
    path =  config["ecd"]["download_dir"] if params[:id].to_i == 11 # CIC.BIN
    full_path = ""
    Dir.foreach(path) do |x|
      if (File.fnmatch('rc2key.bin', File.basename(x).downcase) && (params[:id].to_i == 9))
        full_path = path+'/'+File.basename(x)
      elsif File.fnmatch('nvconfig.sql3', File.basename(x).downcase) && (params[:id].to_i == 10)
        full_path = path+'/'+File.basename(x)
      elsif (File.fnmatch('cic.bin', File.basename(x).downcase) && (params[:id].to_i == 11))
        full_path = path+'/'+File.basename(x)
      end
    end
    file_name = File.basename(full_path)
    if File.exists?(full_path)
      render :json => {:full_path => full_path , :file_name => file_name}
    else
      render :json => {:error => "Unable to find the Valid file..." }
    end
  end
  
  ####################################################################
  # Function:      upload_vital_nonvital
  # Parameters:    params[:page]
  # Retrun:        @userpresence_permission
  # Renders:       None
  # Description:   Vital & non vital file upload page 
  ####################################################################
  def upload_vital_nonvital
    @nv_exe = 'true' if params[:page] == "tgz"
    @vlp_mef = 'true' if params[:page] == "vlp_mef"
    @vlp_mcf = 'true' if params[:page] == "vlp_mcf"
    @mcf_info = SoftwareVersions.find(:first, :conditions => ["sw_type = 'MCF'"])
    get_user_presence_val
  end
  
  ####################################################################
  # Function:      upload_file
  # Parameters:    params[:fileToUpload] ,type
  # Retrun:        path,file_name,atcs_addr,mcfcrc.mcfcrc
  # Renders:       none
  # Description:   method used as part of mef update
  ####################################################################
  def upload_file(type)
    atcs_addr = atcs_address
    path = ""
    file_name = ""
    if (type == "MCFCRC")
      return path, file_name, atcs_addr
    else
      config = open_ui_configuration
      path = config["upload_directory"]["iviu_mef"] if type == 'MEF'
      path = config["upload_directory"]["iviu_mef"] if type == 'tgz'
      path = config["upload_directory"]["iviu_mcf"] if type == 'MCF'
      file_name = params[:fileToUpload].original_filename
      file_data = params[:fileToUpload].read
      continue = !(SoftwareUpload.upload_file(file_name, path, file_data, true))? 2:1
      if continue ==1
        return path, file_name, atcs_addr
      else
        return -2
      end
    end
  end
  
  ####################################################################
  # Function:      upload_vital_nonvital_file
  # Parameters:    params[:type] ,params[:update_type]
  # Retrun:        none
  # Renders:       request_id 
  # Description:   Get the upload mef,mcf request_id
  ####################################################################
  def upload_vital_nonvital_file
    if(params[:type] != 'MCFCRC' && params[:type] != 'MCF_WITH_MCFCRC')
      values = upload_file(params[:type])
      file_update_type = params[:update_type]
      if (params[:type] == 'MCF' || params[:type] == 'MEF') 
        target = 5
      end
      if params[:type] == 'tgz'
        target = 1
      end
      if values == -2
        render :text => '-2'
      else
        upload_req = SoftwareUpload.create({:request_state => 0, 
                                            :atcs_address => values[2], 
                                            :port => 0, 
                                            :target => target, 
                                            :path => values[0], 
                                            :file_name => values[1], 
                                            :file_type => file_update_type , 
                                            :slot_no => 0});
        udp_send_cmd(REQUEST_COMMAND_UPLOAD_FILE, upload_req.request_id)
        render :text => upload_req.request_id
      end
    elsif (params[:type] == 'MCFCRC' || params[:type] == 'MCF_WITH_MCFCRC')
      if Generalststistics.isUSB?
          mcfcrc = params[:mcfcrc].to_i(16)
          id = IntegerParameter.get(2,0)

          if id
            id = id[0][:ID]

            IntegerParameter.update(id,mcfcrc)

          end
         render :text => ""
      else
        mcfcrc = params[:mcfcrc].hex

        atcs_address = get_atcs_address
        simplerequest = RrSimpleRequest.new  
        simplerequest.atcs_address = atcs_address << '.01'
        simplerequest.command = SIMPLE_CMD_SET_MCFCRC
        simplerequest.request_state = REQUEST_STATE_START
        simplerequest.value = mcfcrc
        simplerequest.result = ''
        simplerequest.save
        id = simplerequest.request_id                                                                                                                    
        session[:request_id] = id           
        udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, id)

        render :text => ""

      end
    end
  end
  
  ####################################################################
  # Function:      upload_status
  # Parameters:    params[:request_id]
  # Retrun:        none
  # Renders:       request_state
  # Description:   Get the upload mef status
  ####################################################################
  def upload_status
    software_upload_req = SoftwareUpload.find_by_request_id(params[:request_id])
    delete_request(params[:request_id], REQUEST_COMMAND_UPLOAD_FILE) if software_upload_req.request_state ==2
    render :json => {:req_state => software_upload_req.request_state , 
                     :result => software_upload_req.result , 
                     :error_message => software_upload_req.error_message,
                     :percentage_complete => software_upload_req.percentage_complete}
  end
  
  ####################################################################
  # Function:      rebootrequest
  # Parameters:    None
  # Retrun:        None
  # Renders:       None
  # Description:   Re-Boot the Module
  ####################################################################
  def rebootrequest
    atcs_address = get_atcs_address
    simplerequest = RrSimpleRequest.new  
    simplerequest.atcs_address = atcs_address << '.01'
    simplerequest.command = REQUEST_REBOOT
    simplerequest.request_state = 0
    simplerequest.result = ''
    simplerequest.save
    @id = simplerequest.request_id                                                                                                                    
    session[:request_id] = @id           
    udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, @id)
    render :nothing => true
  end
  
  ####################################################################
  # Function:      get_user_presence_val
  # Parameters:    None
  # Retrun:        @userpresence_permission
  # Renders:       None
  # Description:   Get the user presence value
  ####################################################################
  def get_user_presence_val
    @userpresence_permission = GenericHelper.check_user_presence
  end

  ####################################################################
  # Function:      clear_ecd_cic
  # Parameters:    None
  # Retrun:        @userpresence_permission , uistate
  # Renders:       None
  # Description:   Clear the ECD or CIC
  ####################################################################
  def clear_ecd_cic
    get_user_presence_val
    @type = params[:type]
  end
  
  ####################################################################
  # Function:      ecd_cic_request
  # Parameters:    params[:type]
  # Retrun:        simplerequest
  # Renders:       :text
  # Description:   Give the ECD CIC request
  ####################################################################
  def ecd_cic_request
    @type = params[:type]

    if @type == 'ecd'
      cmd = REQUEST_CLEAR_ECD
    else
      cmd = REQUEST_CLEAR_CIC
    end 

    atcs_address = get_atcs_address

    simplerequest = RrSimpleRequest.new  
    simplerequest.atcs_address = atcs_address << '.01'
    simplerequest.command = cmd
    simplerequest.request_state = 0
    simplerequest.result = ''
    simplerequest.save
    @id = simplerequest.request_id                                                                                                                    
      
    udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, @id)

    render :text => simplerequest.request_id.to_s
  end
  
  ####################################################################
  # Function:      check_ecd_cic_request
  # Parameters:    params[:request_id]
  # Retrun:        rr_simple_request
  # Renders:       :json
  # Description:   Check the ECD CIC request status
  ####################################################################
  def check_ecd_cic_request
    request_id = params[:request_id].to_i
    rr_simple_request = RrSimpleRequest.find(:first,:conditions => ["request_id = ?",request_id])
    if(rr_simple_request.request_state.to_i == 2)
      RrSimpleRequest.delete_all "request_id = #{request_id}"
    end
    if rr_simple_request
      render :json => {:request_state => rr_simple_request.request_state, :result => rr_simple_request.result, :percentage => rr_simple_request.progress}
    else
      render :json => {:request_state => 1, :result => 0, :percentage => 0}
    end
  end
  
  ####################################################################
  # Function:      download_console_log
  # Parameters:    params[:console_id]
  # Retrun:        path , file_name
  # Renders:       Json
  # Description:   Create the console text table log values as a text file for download
  ####################################################################
  def download_console_log
    unless params[:console_id].blank?
      console_id = params[:console_id]
    else
      rt_console = RtConsole.find(:last)
      console_id = rt_console.try(:console_id)
    end
    unless console_id.blank?
        rt_console_text = RtConsoleText.find(:all,:conditions => ['console_id=?',console_id])
    else
        rt_console_text = RtConsoleText.find(:all)
    end
    path = "#{RAILS_ROOT}/tmp"
    file_name  = "console_log_#{Time.now.strftime("%d-%b-%Y_h%Hm%Ms%S")}.txt"
    if File.directory?(path)
      Dir.foreach(path) do |x| 
        if (File.fnmatch('console_log*', File.basename(x)))          
            File.delete("#{path}/#{x}")
          end
       end
    else
      Dir.mkdir(path)
    end
    File.open("#{path}/#{file_name}", "w"){|f|
         f.puts "\r\n"
         unless rt_console_text.blank?
            rt_console_text.each do |text|
              f.puts text.console_text + "\r\n\r\n"
            end
          else
            f.puts "Console logs not available.\r\n\r\n"
          end
    }
    render :json => {:full_path => "#{path}/#{file_name}" ,:file_name =>file_name}
  end
  
  ####################################################################
  # Function:      exit_setup_timeout
  # Parameters:    None
  # Retrun:        None
  # Renders:       render :text => ""
  # Description:   Remove the all the module upload dependent table records
  ####################################################################
  def exit_setup_timeout
    RtConsole.delete_all()
    RtConsoleOptions.delete_all()
    RtConsoleQuestions.delete_all()
    RtConsoleText.delete_all()
    render :text => ""
  end
  
end  
