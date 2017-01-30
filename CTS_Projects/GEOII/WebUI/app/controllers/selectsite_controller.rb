#encoding: UTF-8
####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan /NNSV
# File: Selectsite_Controller.rb
# Description: This module user can able to create new configuration / Open existing configuration
#              / build OCE configuration files/ Remove Site Configuration files / Copy the OCE build configuration files to USB stick /
#              Save as Existing site configuration / Open configuration report & PTC Listining report / Configure the mcf parameters
####################################################################
#History:
# Log: /wayside/GEOII/Trunk/Software/WebUI/app/controllers/Selectsite_Controller.rb
#
# Rev 4668   Sep 30 2013 19:00:00   Jeyavel
# Change the masterdb_location.txt to site_details.yml conversion.

class SelectsiteController < ApplicationController
  layout "general"
  include ExpressionHelper
  include McfHelper
  include SelectsiteHelper
  include ApplicationHelper
  include ReportsHelper
  include RelayLogicHelper

  if OCE_MODE == 1
    require 'win32ole'
    require 'zip/zipfilesystem'
    require 'zip/zip'
    require 'builder'
    require 'socket'
    require 'timeout'
    require 'pathname'
    require 'markaby'
  end
  require 'net/http'
  require 'fileutils'
  require 'sqlite3'

  ####################################################################
  # Function:      index
  # Parameters:    params[:refresh_page] , params[:type] ,params[:importmsg] ,params[:errormessage]
  # Retrun:        @refresh , @mcftypename , @importfilemessage , @rc2keyerror , @mcf_installation_collection
  # Renders:       None
  # Description:   Display the Configuration Editor page
  ####################################################################  
  def index
    if session[:user_id] == nil
      redirect_to :controller => 'access', :action=> 'login_form'
    else
      #***** Below functions needs to enable If the system having multiple version of nvconfig databases *****
      #@iviu_ver = get_nv_config_ver('IVIU')      
      #@geo_ver = get_nv_config_ver('CPU-III')
      #@viu_ver = get_nv_config_ver('VIU')
      if !params[:refresh_page].blank?
        @refresh = params[:refresh_page].to_i
        if (@refresh == 1)
          session[:error] = ""
          session[:save] = ""
          session[:newopenflag]= nil
          clearAllValue_Sessions
        elsif (@refresh == 2)
          close_site_configuration
        elsif (@refresh == 3)
          removesite
        end
      else
        if(!flash[:removemessagesuccess].blank?)
          flash[:removemessagesuccess] = ""
        end
      end
      unless params[:type].blank?
        unless session[:pid].blank?
          # Close cfgmagr.exe file using pid - create new site
          close_cfgmgr(session[:pid])
        end
        # Clear All session variable values
        clearAllValue_Sessions
        session[:typeOfSystem] = params[:type]
        session[:save] = 'save'
      end
      header_function
      @mcftypename = selectmcftypename(session[:typeOfSystem])
      root_values_db  
      @importfilemessage = params[:importmsg]
      @rc2keyerror  = params[:errormessage]
      if !session[:cfgsitelocation].blank?
        validatemcfrtdatabase(session[:cfgsitelocation])
      else
        session[:validmcfrtdb] = false
      end
      if (session[:save] == "save" && !session[:errorandwarning].blank?)
        @disable=false
      elsif(session[:save] == "configure" || session[:validmcfrtdb] == true)
        session[:save] = "configure"
        @disable = true
        @valid_build = false
        @valid_build = validate_build(session[:cfgsitelocation])
      else
        @disable=false
      end
      @template_used = ""
      unless session[:cfgsitelocation].blank?
        @report = false
        @geoptcreportflag = false
        @export = false
        @enable_template = false
        @enable_pac = false
        Dir.foreach(session[:cfgsitelocation]) do |x|
          if session[:typeOfSystem] == "GCP"            
            if (File.fnmatch('*.PAC', File.basename(x)))
              @export = true
            end
            if (File.fnmatch('*.TPL', File.basename(x)))
              @export = true
            end
            if File.fnmatch('*report*.txt', File.basename(x))
              @report = true
            end
            if (File.fnmatch('version.txt', File.basename(x)))
              @version_report = true
            end
            if File.fnmatch('*Import_Report*.html', File.basename(x))
              @import_report = true
            end
            get_gcp_type            
          else
            if session[:typeOfSystem] == "VIU"
              if File.fnmatch('viu_configuration_report*', File.basename(x))
                @report = true
              end
            else
              if File.fnmatch('configuration_report*', File.basename(x))
                @report = true
              elsif File.fnmatch('GEO_PTC_Installation_Listing_Report*', File.basename(x))
                @geoptcreportflag = true 
              end
            end
            if (File.basename(x).downcase == 'cic.bin')
              @export = true
            end
          end
        end
      else
        if !session[:typeOfSystem].blank?
          @template_used = get_template(session[:typeOfSystem])
        end
      end
      @selMasterdbInfo = ""
      if !session[:selectedmasterdb].blank? && File.exist?(session[:selectedmasterdb])       
       (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:selectedmasterdb]
        @mcf_installation_collection = Installationtemplate.find(:all, :order => 'InstallationName COLLATE NOCASE').map(&:InstallationName)
        if session[:selectedinstallationname] == nil
          session[:selectedinstallationname] = @mcf_installation_collection[0]
        end
        get_installation_type(session[:typeOfSystem])
      else
        @mcf_installation_collection = []
        session[:selectedinstallationname] = nil
        session[:mcftypename] = nil
        if !session[:selectedmasterdb].blank? && (session[:typeOfSystem] == "iVIU PTC GEO")
          session[:save] = "save"
          @disable = false
          masterdbname_split = session[:selectedmasterdb].split('/')
          @selMasterdbInfo = "Master DB (" + masterdbname_split[masterdbname_split.length-1].strip.to_s + ") does not exist."
        end
      end
    end
    @typeOfSystem = session[:typeOfSystem]
    @nv_version = ""
    
    if !params[:nv_ver].blank?
      @nv_version = params[:nv_ver].to_s 
    else
      @nv_version = session[:nv_ver]
    end
    if @typeOfSystem == "GCP"
      site_details_path = "#{session[:cfgsitelocation]}/site_details.yml"
      if File.exists?(site_details_path)
        site_details = open_site_details(site_details_path)
        comments = site_details["Comments"]
        config_type = site_details["Config Type"]
       end
        if !comments.blank?
         session[:comments]= site_details["Comments"].strip.to_s
        else
         session[:comments]= ""
       end
       if !config_type.blank?
         session[:template_enable] = config_type.strip.to_s
       else
         session[:template_enable] = nil
       end
    end
    @template_mcfcrc =""
    if @typeOfSystem == "GCP"
      gcp_template_file_path = "#{RAILS_ROOT}/oce_configuration/templates/gcp"
      if File.exists?(gcp_template_file_path)
        if File.exists?("#{gcp_template_file_path}/mcf.db") && File.exists?("#{gcp_template_file_path}/rt.db") && File.exists?("#{gcp_template_file_path}/nvconfig.sql3") 
          if ((File.size("#{gcp_template_file_path}/mcf.db") > 0) && (File.size("#{gcp_template_file_path}/rt.db") >0))
            db_rt = SQLite3::Database.new("#{gcp_template_file_path}/rt.db")
            mcfcrc_temp = db_rt.execute("Select mcfcrc from rt_gwe")
            mcfcrc_temp1 = mcfcrc_temp[0][0]
            @template_mcfcrc = dec2hex(mcfcrc_temp1)
          end
        end
      end
    end
    
    @gcp_current_template = ""
    if @typeOfSystem == "GCP"
      template_directory_name = "#{RAILS_ROOT}/oce_configuration/templates/gcp"
      if File.exists?("#{template_directory_name}/mcf.db") && File.exists?("#{template_directory_name}/rt.db") && File.exists?("#{template_directory_name}/nvconfig.sql3")
        config = open_ui_configuration
        current_template = config["oce"]["GCPSiteTemplate"]
        @gcp_current_template = current_template unless current_template.blank?
      end
    end
    
    if @typeOfSystem == "GCP"
      if session[:template_enable] == "TPL"
        Dir.foreach(session[:cfgsitelocation]) do |x|
          if (File.fnmatch('*.PAC', File.basename(x)))
            file_name = File.basename(x).gsub(".PAC",".TPL").gsub(".pac",".TPL")
            File.rename("#{session[:cfgsitelocation]}/#{x}","#{session[:cfgsitelocation]}/#{file_name}")
          end
        end
      end
    end
    
    @aspect_file_error = ""
    if @typeOfSystem == "iVIU PTC GEO"
      @aspect_file_error = check_aspectfile_iviuptcgeo
    end
  end

  ####################################################################
  # Function:      masterdbselected
  # Parameters:    params[:typeofsystem] , params[:Masterdbselected]
  # Retrun:        stringinstallations
  # Renders:       render :text
  # Description:   Connect the selected master database
  ####################################################################  
  def masterdbselected
    @typeOfSystem = params[:typeofsystem]
    if (@typeOfSystem == "iVIU PTC GEO")
      root_values_db  
    else
      session[:selectedmasterdb] = nil
    end
    mcf_installation_collection = nil
    if !params[:Masterdbselected].blank? #&& File.exist?(params[:Masterdbselected])       
      session[:selectedmasterdb] = params[:Masterdbselected]
      (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = params[:Masterdbselected]
      mcf_installation_collection = Installationtemplate.find(:all, :order => 'InstallationName COLLATE NOCASE').map(&:InstallationName)
      if session[:selectedinstallationname].blank?
        session[:selectedinstallationname] = mcf_installation_collection[0]
      end
    end
    stringinstallations = ''
    mcf_installation_collection.each do |installation|
      stringinstallations << installation+','
    end
    render :text => stringinstallations
  end

  ####################################################################
  # Function:      open_site_config
  # Parameters:    None
  # Retrun:        false
  # Renders:       render :layout
  # Description:   Display the available site for open existing site
  ####################################################################  
  def open_site_config
    get_route_entries 
    render :layout => false
  end

  ####################################################################
  # Function:      get_route_entries
  # Parameters:    None
  # Retrun:        @root_entries
  # Renders:       None
  # Description:   open site configuration folder structure values
  ####################################################################  
  def get_route_entries    
    @root_directory = File.join(RAILS_ROOT, "/oce_configuration/#{session[:user_id].to_s}")
    Dir.mkdir(@root_directory) unless File.exists? @root_directory
    @root_entries = []
    @root_entries = Dir[@root_directory + "/*"].reject{|f| [".", "..", "#{@root_directory}/tmp" , "#{@root_directory}/xmltemplate" , "#{@root_directory}/DT2" , "#{@root_directory}/pac"].include?f }
    @gcp = ""
    @iviu_ptc_geo = ""
    @iviu = ""
    @viu = ""
    @geo = ""
    @geo_cpu3 = ""
    for i in 0...@root_entries.length.to_i
       @product_type = get_product_type(@root_entries[i])
       root_split = @root_entries[i].split('/')
       root_split_length = root_split.length.to_i
       root_name = root_split[root_split_length-1]
      if @product_type == "IVIU PTC GEO"   
        @iviu_ptc_geo = @iviu_ptc_geo + "||" +root_name
      elsif @product_type == "IVIU"
        @iviu = @iviu + "||"+ root_name
      elsif @product_type == "VIU"
        @viu = @viu + "||" + root_name
      elsif @product_type == "GEO"
        @geo = @geo + "||" + root_name
      elsif @product_type == "GCP"
        @gcp = @gcp + "||" + root_name
      elsif @product_type == "CPU-III"
        @geo_cpu3 = @geo_cpu3 + "||" + root_name
      end
    end
  end

  ####################################################################
  # Function:      cfglocationconpath
  # Parameters:    mystring
  # Retrun:        @path , mystring
  # Renders:       None
  # Description:   Substring the cfglocation from the full path - display only configuration location
  ####################################################################  
  def cfglocationconpath(mystring)
    substring = session[:OCE_ConfigPath]
    start_ss = mystring.index(substring)
    mystring[start_ss.to_i, substring.length] = ""
    @path = session[:OCE_ConfigPath] + mystring
    session[:cfgsitelocation]= @path
    return mystring
  end
  
  ####################################################################
  # Function:      selectsiteconfig
  # Parameters:    params[:open_path_name] 
  # Retrun:        value
  # Renders:       render :text
  # Description:   open the selected site configuration
  ####################################################################  
  def selectsiteconfig
    clearAllValue_Sessions
    session[:save] = nil
    siteptc_upgrade_msg = nil
    @path = params[:open_path_name]    
    if File.directory?(@path)
      sitename_split = @path.split('/')
      site_name_update = sitename_split[sitename_split.length-1].to_s
      session[:sitename] = site_name_update
      session[:cfgsitelocation] = @path
      session[:sitecreation] = true
      session[:cfgLocationconpath] = cfglocationconpath(@path)
      site_details_path = "#{@path}/site_details.yml"
      dot_mcf_file = false
      site_type = ""
      if File.exist?(site_details_path)
        site_details = open_site_details(site_details_path)
        site_type = site_details["Site Type"].strip.to_s
      end
      if site_type != "GCP"
        Dir["#{@path}/*.*"].each do  |file|
            dot_mcf_file = true if ((File.extname(file)=='.mcf') || (File.extname(file)=='.MCF')) 
        end
      else
        dot_mcf_file = true
      end
      unless ((File.exist?(site_details_path) || File.exist?("#{@path}/masterdb_location.txt")) && (File.exist?(@path +'/nvconfig.sql3')) && dot_mcf_file)
        render :json => {:valid_site => 'is not a valid site.'} and return
      end
      if !File.exist?(site_details_path)
        if File.exist?("#{@path}/masterdb_location.txt")
          read_existing_configuration_details(@path)
        end
      end
      readConfigurationfiles(@path)
      connectdatabase()
      if (@typeOfSystem == "iVIU PTC GEO") 
        root_values_db
      end
      
      if params[:saveasflag] == "saveas"
        StringParameter.stringparam_update_query(site_name_update, 1)
        generate_gcp_configuration_files(false) if (@typeOfSystem == "GCP") 
      end

      if File.exists?(session[:cfgsitelocation]+'/site_ptc_db.db')
        intialdb_path = RAILS_ROOT+'/db/InitialDB/iviu/GEOPTC.db'
        siteptc_path = session[:cfgsitelocation]+'/site_ptc_db.db'
        upgradesiteptclib  = WIN32OLE.new('MCFPTCDataExtractor.MCFExtractor')                
        siteptc_upgrade_msg = upgradesiteptclib.ValidateDbSchema(converttowindowspath(intialdb_path),converttowindowspath(siteptc_path))
        session[:siteptcdblocation] = session[:cfgsitelocation]+'/site_ptc_db.db'
         (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:cfgsitelocation]+'/site_ptc_db.db'
      end
      if File.exists?(@path +'/mcf.db') && File.exists?(@path+'/rt.db')
        if (File.size(@path+'/mcf.db') > 0) && (File.size(@path+'/rt.db') >0)
          mcfstatus = Mcf.find(:all,:select =>"mcf_status").map(&:mcf_status)
          rtdbvalue = Uistate.find(:all,:select =>"value" , :conditions =>['name=?',"Database completed"]).map(&:value)
          if mcfstatus[0].to_i ==1 && rtdbvalue[0].to_i == 1
            session[:newopenflag]=1
            session[:save]="configure"
            session[:validmcfrtdb] = true
          else
            session[:validmcfrtdb] = false
            session[:newopenflag]= nil
            session[:save]="save"            
          end
          rt_db_default_missing =  RtParameter.columns.map(&:name).include?('default_value')
          if rt_db_default_missing.to_s == 'false'
            rt_db_path = "#{session[:cfgsitelocation]}/rt.db"
            db = SQLite3::Database.new(rt_db_path)
            db.execute("ALTER TABLE rt_parameters ADD COLUMN default_value TEXT")
            db.close
            sleep 3
            RtParameter.update_all("default_value = current_value")
          end
        else
          session[:validmcfrtdb] = false
          session[:newopenflag]= nil
          session[:save]="save"
        end
      else
        session[:validmcfrtdb] = false
        session[:newopenflag]= nil
        session[:save]="save"
      end
      if (session[:validmcfrtdb] == false)
        render :json => {:valid_site => 'is not a valid site.'} and return
      end
      
    else
      session[:invalidcfgLocation]="Invalid Cfg Location Path"
      clearAllValue_Sessions
    end
    if session[:mcfnamefromselected].blank?
      session[:mcfnamefromselected] = ""
    end
    if session[:mcfCRCValue].blank?
      session[:mcfCRCValue] = ""
    end        
    reportflag = false
    geoptcreportflag = false
    exportflag = false
    pacavailable_flag = false
    template_flag = false
    Dir.foreach(session[:cfgsitelocation]) do |x| 
      if @typeOfSystem == "VIU"
        if File.fnmatch('viu_configuration_report*', File.basename(x))
          reportflag = true
        end
      else
        if File.fnmatch('configuration_report*', File.basename(x))
          reportflag = true
        elsif File.fnmatch('GEO_PTC_Installation_Listing_Report*', File.basename(x))
          geoptcreportflag = true 
        end
      end
      if (File.basename(x).downcase == 'cic.bin')
        exportflag = true
      end
    end
    selmasterdb = ""
    if session[:selectedinstallationname].blank?
      session[:selectedinstallationname] = ""
    end
    selMasterdbInfo = ""
    if @typeOfSystem == "iVIU PTC GEO"
      unless session[:selectedmasterdb].blank?
        selmasterdb = File.basename(session[:selectedmasterdb])
        strMasterDb = "#{RAILS_ROOT}/Masterdb/#{selmasterdb}"
        if !File.exist?(strMasterDb)
          session[:save]="save"
          selMasterdbInfo = "Master DB (" + selmasterdb + ") does not exist."
        end
      else
        session[:save]="save"
      end
    end
    
    unless session[:pid].blank?
      # Close existing cfgmagr.exe file using pid
      close_cfgmgr(session[:pid])
    end
    if @typeOfSystem == "VIU"
      strmsg = ""
      session[:cfgmgr_state] = false
      strmsg = run_cfgmgr  
      if strmsg.blank?
        flash[:errormessage] = nil
        if params[:saveasflag] == "saveas"
          update_viu_siteinfo(site_name_update, session[:mcfCRCValue])
        end
      else
        flash[:errormessage] = strmsg
      end      
    end
    
    if @typeOfSystem == "VIU" || @typeOfSystem == "CPU-III" || @typeOfSystem == "GEO"
      initialDB_nvconfig_path = RAILS_ROOT+'/db/InitialDB/geo/nvconfig.sql3'
    elsif @typeOfSystem == "GCP"
      initialDB_nvconfig_path = RAILS_ROOT+'/db/InitialDB/gcp/nvconfig.sql3'
    else
      initialDB_nvconfig_path = RAILS_ROOT+'/db/InitialDB/iviu/nvconfig.sql3'
    end
    strValidate_nvconfig = "valid"
    site_nvconfig_path = session[:cfgsitelocation] + '/nvconfig.sql3'
    if @typeOfSystem == "GCP"
      get_gcp_type
      if !@gcp_4000_version
        strValidate_nvconfig = validate_nvconfig(initialDB_nvconfig_path, site_nvconfig_path)
      end
    else
       strValidate_nvconfig = validate_nvconfig(initialDB_nvconfig_path, site_nvconfig_path)
    end
    clear_Header_values
    header_function
    aspect_file_error = ""
    if @typeOfSystem == "iVIU PTC GEO"
      aspect_file_error = check_aspectfile_iviuptcgeo
    end
    if @typeOfSystem == "GCP"
       site_details_path = "#{session[:cfgsitelocation]}/site_details.yml"
      if File.exists?(site_details_path)
        site_details = open_site_details(site_details_path)
        config_type = site_details["Config Type"]
       if !config_type.blank?
         session[:template_enable] = config_type.strip.to_s
       else
         session[:template_enable] = nil
       end
      end
    end
    render :json =>{  :valid_site => "valid",
                      :typeOfSystem => @typeOfSystem ,
                      :cfgLocationconpath => session[:cfgLocationconpath] ,
                      :selmasterdb => selmasterdb,
                      :selMasterdbInfo => selMasterdbInfo,
                      :selectedinstallationname => session[:selectedinstallationname],
                      :mcfnamefromselected => session[:mcfnamefromselected],
                      :mcfCRCValue => session[:mcfCRCValue],
                      :save => session[:save],
                      :reportflag => reportflag,
                      :exportflag => exportflag ,
                      :geoptcreportflag => geoptcreportflag,
                      :s_name => session[:s_name],
                      :atcs_address => session[:atcs_address],
                      :m_post => session[:m_post],
                      :dot_num => session[:dot_num],
                      :siteptc_upgrade_msg => siteptc_upgrade_msg,
                      :validate_nvconfig => strValidate_nvconfig,
                      :aspect_file_error => aspect_file_error,
                      :gcp_comments => session[:comments],
                      :config_type => session[:template_enable]
                    }
  end
  
  ####################################################################
  # Function:      removesite
  # Parameters:    session[:cfgsitelocation] 
  # Retrun:        None
  # Renders:       None
  # Description:   Remove the already open site configuration
  ####################################################################  
  def removesite
    if params[:selected_folder]
      if params[:selected_folder] == "true"
        params[:selected_folder] = session[:cfgsitelocation]
        render :text => "" if params[:selected_folder].blank?
      end
      removesitepath = params[:selected_folder] 
    else
      removesitepath = session[:cfgsitelocation]
    end
    session[:removepath] = nil
    session[:error] = ""
    session[:save] = ""
    session[:newopenflag]= nil
    session[:cfgsitelocation] = nil
    unless session[:pid].blank?
      # Close existing cfgmagr.exe file using pid
      close_cfgmgr(session[:pid])
    end
    close_database_connection
    clearAllValue_Sessions
    header_function
    begin
      FileUtils.rm_rf(removesitepath)
      if params[:selected_folder] == nil
        if File.directory?(removesitepath)
          FileUtils.rmdir removesitepath 
        end
      end
      session[:save]= ""
    rescue Exception => e
      session[:error] = "<span style = 'color:#FF0000'>Error: While removing the site, #{e.to_s}.</span>"
    end
    if (!params[:selected_folder].blank? && File.directory?(params[:selected_folder]))
      session[:error] = "<span style = 'color:#FF0000'>Error: While removing the site, Please close all open files related to this site(#{params[:selected_folder].split('/').last.to_s}) configuation.</span>"
    end
    if session[:error] != ""
      flash[:removemessagesuccess] = session[:error]
      render :text => session[:error] if params[:selected_folder]
    else
      flash[:removemessagesuccess] = "Removed site successfully"  
      render :text => "Removed site successfully" if params[:selected_folder]
    end
  end

  ####################################################################
  # Function:      build
  # Parameters:    params[:typeofsystem] , session[:cfgsitelocation]
  # Retrun:        buildcheck
  # Renders:       render :text
  # Description:   Build the configuration files - Create CIC.BIN, Configuration report , WIU_config.xml
  ####################################################################  
  def build
    errormessage =""
    buildcheck=""
    @typeOfSystem = params[:typeofsystem]
    if (@typeOfSystem.to_s == "GCP")
      Dir.foreach(session[:cfgsitelocation]) do |x| 
        if(File.fnmatch('*.PAC', File.basename(x)) || File.fnmatch('*report*.txt', File.basename(x)) || File.fnmatch('*.XML', File.basename(x)) || File.fnmatch('relaylogic.*', File.basename(x)))
          File.delete("#{session[:cfgsitelocation]}/#{x}")
        end
    	end
    	puts "------------------- Set Hidden Params to it's default values -------------------"
      set_hidden_params_to_defaults
    	
      session[:comments] = params[:comments]
      template_enable = params[:template_check]
      if template_enable == true || template_enable == 'true'
        config_type = "TPL"
      else 
        if template_enable == false || template_enable == 'false'
        config_type = "PAC"
        end
      end
      config = YAML.load_file("#{session[:cfgsitelocation]}/site_details.yml")
      config["Config Type"]=config_type
      config["Comments"] = params[:comments]
      File.open("#{session[:cfgsitelocation]}/site_details.yml", 'w') { |f| YAML.dump(config, f) }
    	
      # # Create the PAC file using the rt , mcf , nvconfig
      buildcheck = generate_gcp_configuration_files
      if buildcheck.blank?
        buildcheck = "Build created successfully"
      end
    else
  		Dir.foreach(session[:cfgsitelocation]) do |x| 
        if(File.fnmatch('WiuConfig-*', File.basename(x)) || File.fnmatch('viu_configuration_report*', File.basename(x)) || File.fnmatch('configuration_report*', File.basename(x)) || File.fnmatch('GEO_PTC_Installation_Listing_Report*', File.basename(x)) || File.basename(x)=='PTCUCN.txt' || File.basename(x)=='UCN.txt' || File.basename(x)=='ApprovalCRC.txt' || File.basename(x)=='cic.bin' || File.basename(x)=='RtAndDecompiledRt.log' || File.basename(x)=='cicbin.log' || File.basename(x)=='sin.txt' ||File.basename(x)=='decompiled_rt.db')
          File.delete("#{session[:cfgsitelocation]}/#{x}")
        end
      end
      begin
        if @typeOfSystem == "iVIU PTC GEO" || @typeOfSystem == "iVIU" || @typeOfSystem == "VIU"
          decompile_rt_db_path = "#{RAILS_ROOT}/db/InitialDB/iviu/decompiled_rt.db"  
        elsif @typeOfSystem == "GEO" || @typeOfSystem == "CPU-III"
          decompile_rt_db_path = "#{RAILS_ROOT}/db/InitialDB/geo/decompiled_rt.db"
        end
        FileUtils.cp(decompile_rt_db_path, session[:cfgsitelocation] + "/decompiled_rt.db")
      rescue Exception => e
      end
      rails_root = session[:cfgsitelocation]
      mcf_db = converttowindowspath("#{rails_root}/mcf.db")
      rt_db =  converttowindowspath("#{rails_root}/rt.db")
      site_details = open_site_details("#{rails_root}/site_details.yml")
      mcfName = site_details["MCF Name"].strip.to_s  
      unless session[:selectedinstallationname].blank?
        ptc_installation = session[:selectedinstallationname]
      else
        ptc_installation = ""
      end
      if File.exists?(mcf_db) && File.exists?(rt_db)
        pci_msg="#{session[:OCE_ROOT]}\\PCI_Msg.exe"
        begin     
          if File.exists?(session[:cfgsitelocation]+'/site_ptc_db.db')
            ptc_db = converttowindowspath(session[:cfgsitelocation]+'/site_ptc_db.db')
            # Add approvalCRC values from Master GEOPTC.db to site_ptc_db.db
            if @typeOfSystem == "iVIU PTC GEO"
              # Delete existing details from Site_ptc_db.db and add from Master GEOPTC.db
              db = SQLite3::Database.new(session[:cfgsitelocation]+'/site_ptc_db.db')
              db.execute("Delete from Approval")
              approvalvalue = Array.new
               (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:selectedmasterdb]
              approvalvalue = Approval.find_by_sql("Select InstallationName, Approver, ApprovalDate, ApprovalTime, ApprovalCRC, ApprovalStatus from Approval where InstallationName Like '#{ptc_installation}'")
              for t in 0..(approvalvalue.length-1)
                db.execute( "Insert into Approval values('#{approvalvalue[t].InstallationName}','#{approvalvalue[t].Approver}','#{approvalvalue[t].ApprovalDate}','#{approvalvalue[t].ApprovalTime}','#{approvalvalue[t].ApprovalCRC}','#{approvalvalue[t].ApprovalStatus}')" )   
              end
              db.close
               (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:cfgsitelocation]+'/site_ptc_db.db'
            end
          else
            ptc_db = ""
          end
          unless session[:cfgsitelocation].blank?
            if( @typeOfSystem == "VIU")
             strmsg=generate_rc2key(@typeOfSystem)
              unless !(strmsg.downcase.include?("error"))
                raise Exception, strmsg
              end
            end
            if File.exist?(mcf_db) && File.exist?(rt_db)
              wiuenabledid = 0
              enum_parameters = EnumParameter.enum_group(38, 0)
              wiu_channel_enable = enum_parameters.select{|parameter| parameter.Name == "WIU Channel Enabled"}.first
              wiuenabledid = wiu_channel_enable.ID.to_i
              
              libcic = WIN32OLE.new('CIC_BIN.CICBIN')
              libcic.Site_Type = @typeOfSystem
              strmsg = libcic.GenerateConfigFiles(mcfName, converttowindowspath(session[:cfgsitelocation]), ptc_db, ptc_installation, wiuenabledid, pci_msg)                
              unless strmsg.blank?
                raise Exception, strmsg
              end
            else
              buildcheck = "There is no mcfdb and RT DB"
            end
            if File.exists?(session[:cfgsitelocation]+'/site_ptc_db.db')
              #   Create WIU Configuration file using nvconfig , site_ptc_db.db
              createWIUConfigxmlfile
            end
          end  
        rescue Exception => e  
          errormessage = e
        end
        
        #   Generate Configuration Report 
        if errormessage.blank?
          begin 
            sin = Gwe.find(:all,:select =>'sin').map(&:sin)
            strpath ="\"#{session[:OCE_ROOT]}\\generatereport.exe\", \"#{mcf_db}\" \"#{rails_root}/decompiled_rt.db\" \"#{converttowindowspath(session[:cfgsitelocation])+'\\\\'}\" \"#{sin[0]}\""
            if system(strpath)
              Dir.foreach(session[:cfgsitelocation]) do |x| 
                if File.fnmatch('configuration_report*', File.basename(x))
                  if (@typeOfSystem != "VIU")
                    File.open(session[:cfgsitelocation]+'/'+x, "a+"){|f|
                      f.puts
                      f.puts
                      f.puts "UCN and PTC UCN parameters"
                      f.puts "=========================="
                      f.puts 'UCN          : '+ readucnvalue(session[:cfgsitelocation]+'/UCN.txt')
                      f.puts 'PTC UCN      : '+ readucnvalue(session[:cfgsitelocation]+'/PTCUCN.txt')
                      if @typeOfSystem != "VIU"
                        if session[:user_id].to_s == "oceadmin" 
                          f.puts 'APPROVAL CRC : '+ readucnvalue(session[:cfgsitelocation]+'/APPROVALCRC.txt')
                        end
                      end
                    }
                  end
                  #********** Display GEO PTC Databse information******
                  filename = session[:cfgsitelocation]+'/'+x
                  line_arr = IO::readlines(filename)
                  if File.exists?(session[:cfgsitelocation]+'/site_ptc_db.db')
                    mcf_installations = Installationtemplate.all.map(&:InstallationName)
                    installation_name_default = nil
                    unless mcf_installations.blank?
                      activeinstallation = Gwe.find(:all,:select=>"active_physical_layout").map(&:active_physical_layout)
                      installation_name_default = mcf_installations[activeinstallation[0].to_i-1]
                      if installation_name_default.blank?
                        installation_name_default = session[:selectedinstallationname].to_s
                      end
                    end
                    oceversion = "OCE Version        : "+ session[:webui_version].to_s
                    ptcgeodatabase = nil
                    if (@typeOfSystem.upcase == "IVIU PTC GEO")
                      database = session[:selectedmasterdb] 
                      dbvalue =database.split('/')
                      ptcgeodatabase = "PTC Database        : "+dbvalue[dbvalue.length-1]
                    else
                      ptcgeodatabase = "PTC Database        : site_ptc_db.db"
                    end
                    installationname = "Installation Name   : "+ installation_name_default.to_s                  
                    line_arr.insert(3 , oceversion)
                    line_arr.insert(4 , "")
                    line_arr.insert(5 , "MCF Information")
                    line_arr.insert(6 , "===============")
                    line_arr.insert(7 , "MCF Name             : " + site_details["MCF Name"].strip.to_s)
                    line_arr.insert(8 , "MCF CRC              : " + "0x" + site_details["MCFCRC"].strip.to_s)
                    line_arr.insert(9 , "")
                    line_arr.insert(10 , "PTC Database Information")
                    line_arr.insert(11 , "========================")
                    startinglineno = 11
                    mcf_names = Mcfphysicallayout.find(:all, :select =>"MCFName", :conditions => {:InstallationName => installation_name_default.to_s}).map(&:MCFName).uniq
                    mcf_names.each do |mcf|
                      geomcfnameandcrc = nil
                      mcfcrc = Mcfptc.find_by_MCFName(mcf, :select => "CRC").try(:CRC)
                      if mcfcrc
                        if mcfcrc.to_i == 0 && (@typeOfSystem.upcase == "IVIU" || @typeOfSystem.upcase == "CPU-III" || @typeOfSystem.upcase == "GEO")
                          mcfhexaCRCvale= "0x#{site_details["MCFCRC"].strip.to_s}"
                        else
                          intvalue = mcfcrc.to_i
                          mcfhexaCRCvale= '0x'+intvalue.to_s(16).upcase.to_s
                        end
                        geomcfnameandcrc = "MCF Name/CRC        : "+mcf.to_s+' / '+mcfhexaCRCvale.to_s
                      else
                        geomcfnameandcrc = "MCF Name/CRC        : "+mcf.to_s+' / 0'
                      end
                      startinglineno = startinglineno +1
                      line_arr.insert(startinglineno,geomcfnameandcrc)
                    end
                    line_arr.insert(startinglineno+1 , ptcgeodatabase)
                    line_arr.insert(startinglineno+2 , installationname)
                    cpu3_item = 3
                    line_arr.insert(startinglineno+cpu3_item , "")                  
                  else
                    oceversion = "OCE Version        : "+ session[:webui_version].to_s                  
                    line_arr.insert(3 , oceversion)
                    line_arr.insert(4 , "")
                    line_arr.insert(5 , "MCF Information")
                    line_arr.insert(6 , "===============")
                    line_arr.insert(7 , "MCF Name           : " + site_details["MCF Name"].strip.to_s)
                    line_arr.insert(8 , "MCF CRC            : " + "0x" + site_details["MCFCRC"].strip.to_s)
                    cpu3_item = 9
                    if (@typeOfSystem.upcase != "GEO")
                      line_arr.insert(9 , "")
                      line_arr.insert(10 , "PTC Database Information")
                      line_arr.insert(11 , "========================")                 
                      line_arr.insert(12 , "MCF Name/CRC   : ")
                      line_arr.insert(13 , "PTC Database   : ")
                      line_arr.insert(14 , "Installation Name  : ")
                      cpu3_item = 14
                    else
                      line_arr.insert(9, "")                    
                      line_arr.insert(10, "Site Information")
                      line_arr.insert(11, "================")
                      line_arr.insert(12, "Site Name         : " + StringParameter.get_string_value(1 , "Site Name"))
                      line_arr.insert(13, "DOT Number        : " + StringParameter.get_string_value(1 , "DOT Number"))
                      line_arr.insert(14, "Mile Post         : " + StringParameter.get_string_value(1 , "Mile Post"))
                      line_arr.insert(15, "ATCS Address      : " + StringParameter.get_string_value(1 , "ATCS Address"))
                      cpu3_item = 16
                    end
                    line_arr.insert(cpu3_item , "")
                  end
                  File.open(filename, "w") do |f| 
                    line_arr.each{|line| f.puts(line)}
                  end
                  if (@typeOfSystem.upcase == "GEO")
                    generate_geo_config_report(filename)
                  end
                  #**********END Display GEO PTC Databse information******
                  buildcheck = 'Build created successfully'
                end
              end # IF SYSTEM
              if File.exists?(session[:cfgsitelocation]+'/site_ptc_db.db')
                if ((session[:user_id].to_s == "oceadmin")  && (@typeOfSystem.upcase == "IVIU PTC GEO"))
                  # create geo_ptc_installation_listing_report start                      
                  returnval = create_geo_ptc_installation_listing_report
                  # create geo_ptc_installation_listing_report end
                  if (returnval == "Success")
                    buildcheck = 'Build created successfully'
                  else
                    buildcheck = returnval
                  end
                else
                  buildcheck = 'Build created successfully' << '|' << 'Disable'
                end
              else
                buildcheck = 'Build created successfully' << '|' << 'Disable'
              end
            else
              buildcheck ="Got Problem in configuration report creation"
            end
            if (@typeOfSystem == "VIU")
              # passing params - viu_congig_report path , 1 , port no
              strviupath ="\"#{session[:OCE_ROOT]}\\repgenr.exe\", \"#{session[:cfgsitelocation]}/viu_configuration_report.txt\" 1 \"#{session[:cfgmgrportno]}\""
              puts strviupath.inspect
              if system(strviupath)
                if File.exists?("#{session[:cfgsitelocation]}/viu_configuration_report.txt")
                  oceversion = "OCE Version        : "+ session[:webui_version].to_s
                  rep_gen_filepath = "#{session[:cfgsitelocation]}/viu_configuration_report.txt"
                  line_arr = IO::readlines(rep_gen_filepath)                
                  line_arr.insert(3 , oceversion)
                  line_arr.insert(4 , "")
                  line_arr.insert(5 , "MCF Information")
                  line_arr.insert(6 , "===============")
                  line_arr.insert(7 , "MCF Name           : " + site_details["MCF Name"].strip.to_s)
                  line_arr.insert(8 , "MCF CRC            : " + "0x" + site_details["MCFCRC"].strip.to_s)
                  line_arr.insert(9 , "")
                  line_arr.insert(10 , "Non Vital Configuration")
                  line_arr.insert(11 , "=======================")
                  line_arr.insert(12 , "")
                  get_ptc_general
                  unless @group_parameters.blank?
                    line_arr.insert(13 , "PTC General")
                    line_arr.insert(14 , "===========")
                    line_start = 15
                    @group_parameters.each do |group_param|
                      val_display = ("%-25s: %s" % ["#{group_param[:name]}" , "#{group_param[:value]}"])
                      line_arr.insert(line_start ,val_display )
                      line_start = line_start + 1
                    end
                    line_arr.insert(line_start , "")
                  end
                  File.open(rep_gen_filepath, "w") do |f| 
                    line_arr.each{|line| f.puts(line)}
                  end  
                  File.open(rep_gen_filepath, "a+"){|f| 
                    Dir.foreach(session[:cfgsitelocation]) do |x| 
                      if File.fnmatch('configuration_report*', File.basename(x))
                        delete_file = session[:cfgsitelocation]+'/'+x
                        countflag = false
                        file = File.new(session[:cfgsitelocation]+'/'+x, "r")
                        while (line = file.gets)
                          if ((line.rstrip.to_s.upcase =="VITAL CONFIGURATION") || (line.rstrip.to_s.upcase =="MCF CONFIGURATION") || (countflag == true))
                            f.puts line
                            countflag = true
                          end
                        end
                        file.close
                        File.delete(delete_file)
                      end
                    end
                  }
                  #returnval = create_viu_geo_ptc_report
                  returnval = "Success"
                  if (returnval == "Success")
                    buildcheck = 'Build created successfully'
                  else
                    buildcheck = returnval
                  end
                  File.open(rep_gen_filepath, "a+"){|f|
                    f.puts
                    f.puts
                    f.puts "UCN and PTC UCN parameters"
                    f.puts "=========================="
                    f.puts 'UCN          : '+ readucnvalue(session[:cfgsitelocation]+'/UCN.txt')
                    f.puts 'PTC UCN      : '+ readucnvalue(session[:cfgsitelocation]+'/PTCUCN.txt')
                    if @typeOfSystem != "VIU"
                      if session[:user_id].to_s == "oceadmin" 
                        f.puts 'APPROVAL CRC : '+ readucnvalue(session[:cfgsitelocation]+'/APPROVALCRC.txt')
                      end
                    end
                  }
                else
                  buildcheck ="Got Problem in VIU report creation"
                end
              else
                buildcheck ="Got Problem in VIU report creation"
              end
            end
          rescue Exception => e  
            buildcheck  ="Got Problem in configuration report creation"
            #              puts e
          end
        else
          buildcheck = errormessage.to_s
        end
      else
        buildcheck = "Mcf db/rt db is not available"  
      end
    end
    render :text =>buildcheck
  end
 
  ####################################################################
  # Function:      generate_geo_config_report
  # Parameters:    filename1
  # Retrun:        None
  # Renders:       None
  # Description:   Generate GEO Site configuration Report 
  ####################################################################  
  def generate_geo_config_report(filename1)
    line_read_start = true
    File.open(filename1, 'r') do |original_file|
      File.open("#{RAILS_ROOT}/tmp/file.txt.tmp", 'w') do |temp_file|
        original_file.each_line do |line|
          if (line.rstrip.to_s.upcase == "NON VITAL CONFIGURATION")
            line_read_start = false
          else
            if(line_read_start == false)
              if ((line.rstrip.to_s.upcase =="VITAL CONFIGURATION") || (line.rstrip.to_s.upcase =="MCF CONFIGURATION"))
                temp_file.write(line)
                line_read_start = true
              end
            else
              temp_file.write(line) 
            end
          end
        end
      end
    end
    FileUtils.mv "#{RAILS_ROOT}/tmp/file.txt.tmp", filename1
  end
  
  ####################################################################
  # Function:      get_ptc_general
  # Parameters:    None
  # Retrun:        @group_parameters
  # Renders:       None
  # Description:   Get ptc general page parameters name , value from the database to display viu config report 
  ####################################################################  
  def get_ptc_general
    group_ID = 44
    group_channel = 0
    parameters = ( EnumParameter.get(group_ID,group_channel)+ IntegerParameter.get(group_ID, group_channel) + StringParameter.get(group_ID, group_channel) + ByteArrayParameter.get(group_ID, group_channel)).sort_by &:DisplayOrder
    @group_parameters = []
    parameters.each do |p|
      if(p.class == EnumParameter)
        selection = EnumParameter.get_dropdownbox(p.ID)
        @group_parameters << {:name => [p.Name], :value => selection}
      elsif(p.class == IntegerParameter)
        @group_parameters << {:name => p.Name, :value => p.Value}
      elsif(p.class == ByteArrayParameter)
        @group_parameters << {:name => p.Name, :value => p.Array_Value}
      else
        @group_parameters << {:name => p.Name, :value => p.String}
      end
    end
  end

  ####################################################################
  # Function:      copybuildfiles
  # Parameters:    params[:typeofsystem] , session[:cfgsitelocation]
  # Retrun:        configedtmessage
  # Renders:       render :json
  # Description:   Download the configured/ Build files from the server - will create the zip file and will send the zip file to client side
  ####################################################################  
  def copybuildfiles
    @typeOfSystem = params[:typeofsystem]
    systemtype = @typeOfSystem
    session[:configedtmessage]=""
    if session[:cfgsitelocation] != nil
      if systemtype == "GCP"
        pac_available_flag = false
        pac_path = ""
        mcf_available_flag = false
        mcf_path = ""
        pacfilename =""
        pac_filename = ""
        split_pac_upload_path , split_cdl_upload_path ,split_mcf_upload_path  = read_gcp_export_usb_file_struct
        
        Dir.foreach(session[:cfgsitelocation]) do |filelist| 
          if ((File.extname(filelist) == '.pac') || (File.extname(filelist) == '.PAC') || (File.extname(filelist) == '.tpl') || (File.extname(filelist) == '.TPL'))
            pacfilename = File.basename(filelist).split('.')
            pac_filename = pacfilename[0]
          end
        end
        
        zip_filename = "#{RAILS_ROOT}/tmp/#{pac_filename}.zip"
        File.delete(zip_filename) if File.exists?(zip_filename)
        Zip::ZipFile.open(zip_filename, Zip::ZipFile::CREATE) do |zf|
          Dir.foreach(session[:cfgsitelocation]) do |filelist|
            filename = File.basename filelist
            if ((File.extname(filelist) == '.pac') || (File.extname(filelist) == '.PAC') || (File.extname(filelist) == '.tpl') || (File.extname(filelist) == '.TPL'))
              pac_available_flag = true
              pac_path = "#{session[:cfgsitelocation]}/#{filelist}"
              zf.mkdir("#{split_pac_upload_path[0]}") unless zf.find_entry("#{split_pac_upload_path[0]}")
              zf.mkdir("#{split_pac_upload_path[0]}/#{split_pac_upload_path[1]}") unless zf.find_entry("#{split_pac_upload_path[0]}/#{split_pac_upload_path[1]}")
              zf.mkdir("#{split_pac_upload_path[0]}/#{split_pac_upload_path[1]}/#{split_pac_upload_path[2]}") unless zf.find_entry("#{split_pac_upload_path[0]}/#{split_pac_upload_path[1]}/#{split_pac_upload_path[2]}")
              zf.add("#{split_pac_upload_path.join('/')}/#{filename}" ,pac_path)       
            elsif ((File.extname(filelist)=='.cdl') || (File.extname(filelist)=='.CDL'))
              cdl_path =  "#{session[:cfgsitelocation]}/#{filelist}"
              zf.mkdir("#{split_cdl_upload_path[0]}") unless zf.find_entry("#{split_cdl_upload_path[0]}")
              zf.mkdir("#{split_cdl_upload_path[0]}/#{split_cdl_upload_path[1]}") unless zf.find_entry("#{split_cdl_upload_path[0]}/#{split_cdl_upload_path[1]}")
              zf.mkdir("#{split_cdl_upload_path[0]}/#{split_cdl_upload_path[1]}/#{split_cdl_upload_path[2]}") unless zf.find_entry("#{split_cdl_upload_path[0]}/#{split_cdl_upload_path[1]}/#{split_cdl_upload_path[2]}")
              zf.add("#{split_cdl_upload_path.join('/')}/#{filename}",cdl_path)
            elsif ((File.extname(filelist)=='.mcf') || (File.extname(filelist)=='.MCF'))
              mcf_available_flag = true
              mcf_path =  "#{session[:cfgsitelocation]}/#{filelist}"
              zf.mkdir("#{split_mcf_upload_path[0]}") unless zf.find_entry("#{split_mcf_upload_path[0]}")
              zf.mkdir("#{split_mcf_upload_path[0]}/#{split_mcf_upload_path[1]}") unless zf.find_entry("#{split_mcf_upload_path[0]}/#{split_mcf_upload_path[1]}")
              zf.mkdir("#{split_mcf_upload_path[0]}/#{split_mcf_upload_path[1]}/#{split_mcf_upload_path[2]}") unless zf.find_entry("#{split_mcf_upload_path[0]}/#{split_mcf_upload_path[1]}/#{split_mcf_upload_path[2]}")
              zf.add("#{split_mcf_upload_path.join('/')}/#{filename}",mcf_path)
            end
          end
        end
        if !pac_path.blank?
          if (pac_available_flag == true)
            render :json =>{:error=> false, :file_path => zip_filename }
          else
            render :json =>{:error=> true , :message => "Build files not available Please build and try again"}
          end
        else
          render :json =>{:error=> true , :message => "Build files not available Please build and try again"}
        end
      else  
        if systemtype != "VIU"
          filecheck = Dir[session[:cfgsitelocation]+'/mcf.db', session[:cfgsitelocation]+'/rt.db',session[:cfgsitelocation]+'/cic.bin']
        else
          filecheck = Dir[session[:cfgsitelocation]+'/mcf.db', session[:cfgsitelocation]+'/rt.db',session[:cfgsitelocation]+'/cic.bin' , session[:cfgsitelocation]+'/nvconfig.bin']    
        end
        if ((filecheck.length == 3 && systemtype != "VIU") || (filecheck.length == 4 && systemtype == "VIU"))
          begin
            viu_siteinfo = read_viu_siteinfo if systemtype == "VIU"
            milepost =  (systemtype != "VIU")? StringParameter.get_string_value(1 , "Mile Post") : viu_siteinfo["MILEPOST"]
            sitename =  (systemtype != "VIU")? StringParameter.get_string_value(1 , "Site Name") : viu_siteinfo["SITE_NAME"]
            temp_sitename = Regexp.new("^[0-9A-Za-z_-]+$").match(sitename)
            site_char = ""
            if temp_sitename.blank?
              temp_sitename = sitename.split('')
              for i in 0..(temp_sitename.length - 1)
                site_flg = Regexp.new("^[0-9A-Za-z_-]+$").match(temp_sitename[i].to_s)
                if !site_flg.blank?
                  site_char = site_char + temp_sitename[i].to_s
                end
              end
              sitename = site_char
            end
            # create export file name Format Config-<site name>-<mile post>-<date>.zip
            formated_date_val = Time.new.strftime("%Y%m%d")
            formated_export_file_name = "Config-#{sitename}-#{milepost}-#{formated_date_val}"
            bundle_filename = "#{RAILS_ROOT}/tmp/#{formated_export_file_name}.zip"
            File.delete(bundle_filename) if File.exists?(bundle_filename)
            Zip::ZipFile.open(bundle_filename, Zip::ZipFile::CREATE) do |zf|
              if (systemtype.downcase != "cpu-iii")
                zf.mkdir("Safetran")  
              end
              if (systemtype.downcase == 'viu')
                zf.mkdir("Safetran/VIU")
                zf.mkdir("Safetran/VIU/Application")
                zf.mkdir("Safetran/VIU/Configuration")
              elsif (systemtype.downcase != "cpu-iii" && systemtype.downcase != "geo" )              
                zf.mkdir("Safetran/#{milepost+'-'+sitename}")
                zf.mkdir("Safetran/#{milepost+'-'+sitename}/iVIU")
                zf.mkdir("Safetran/#{milepost+'-'+sitename}/iVIU/Configuration")
                zf.mkdir("Safetran/#{milepost+'-'+sitename}/iVIU/Configuration/MCF")
                zf.mkdir("Safetran/#{milepost+'-'+sitename}/iVIU/Configuration/MCF/MCFs")
                zf.mkdir("Safetran/#{milepost+'-'+sitename}/iVIU/Configuration/0")
             elsif(systemtype.downcase == "geo")
                zf.mkdir("Safetran/#{milepost+'-'+sitename}")
                zf.mkdir("Safetran/#{milepost+'-'+sitename}/GEO")
                zf.mkdir("Safetran/#{milepost+'-'+sitename}/GEO/Configuration")
                zf.mkdir("Safetran/#{milepost+'-'+sitename}/GEO/Configuration/MCF")
                zf.mkdir("Safetran/#{milepost+'-'+sitename}/GEO/Configuration/MCF/MCFs")
                zf.mkdir("Safetran/#{milepost+'-'+sitename}/GEO/Configuration/0")
                if session[:wiuconfigxmlfilename].blank?
                  Dir.foreach(session[:cfgsitelocation]) do |filelist| 
                    if File.fnmatch('WiuConfig-*', File.basename(filelist))
                      session[:wiuconfigxmlfilename] = File.basename(filelist)
                    end
                  end
                end
              end
              temp=""
              wiuxmlpath = nil
              unless session[:wiuconfigxmlfilename].blank?
                wiuxmlpath = session[:cfgsitelocation]+"/#{session[:wiuconfigxmlfilename]}"
              else
                wiuxmlpath =  session[:cfgsitelocation]+"/*.xml"
              end
              if (systemtype.downcase == "viu")
                Dir[session[:cfgsitelocation]+'/*.MCF', 
                session[:cfgsitelocation]+'/site_details.yml', session[:cfgsitelocation]+'/mcf.db', session[:cfgsitelocation]+'/rt.db',
                session[:cfgsitelocation]+'/cic.bin', session[:cfgsitelocation]+'/nvconfig.bin', session[:cfgsitelocation]+'/nvconfig.sql3',
                session[:cfgsitelocation]+'/*.cdl',session[:cfgsitelocation]+'/*.llw',session[:cfgsitelocation]+'/*.llb', session[:cfgsitelocation]+'/rtstatus.sql3',
                session[:cfgsitelocation]+'/site_ptc_db.db',session[:cfgsitelocation]+'/rc2key.bin', wiuxmlpath].each do  |file|
                  flname = File.basename file
                  if(flname != temp)                
                    if ((File.extname(file)=='.mcf') || (File.extname(file)=='.MCF'))
                      zf.add("Safetran/VIU/Application/"+flname, file)
                    elsif ((flname == "site_details.yml") || (flname == "mcf.db") || (flname == "rt.db") )
                      zf.add("Safetran/VIU/"+flname, file)
                    elsif (flname == "cic.bin")
                      zf.add("Safetran/VIU/Configuration/"+ "V-#{milepost}-#{sitename}.bin", file)
                    elsif (flname == "nvconfig.bin")
                      zf.add("Safetran/VIU/Configuration/"+ "NV-#{milepost}-#{sitename}.bin", file)
                    else
                      zf.add("Safetran/VIU/Configuration/"+ flname, file)
                    end
                  end
                  temp = flname
                end   # do loop 
              else
                Dir[session[:cfgsitelocation]+'/*.MCF',  
                session[:cfgsitelocation]+'/site_details.yml', session[:cfgsitelocation]+'/mcf.db', session[:cfgsitelocation]+'/rt.db',
                session[:cfgsitelocation]+'/nvconfig.sql3', session[:cfgsitelocation]+'/cic.bin', session[:cfgsitelocation]+'/rtstatus.sql3',
                session[:cfgsitelocation]+'/*.cdl', session[:cfgsitelocation]+'/*.llw',session[:cfgsitelocation]+'/*.llb', session[:cfgsitelocation]+'/cdl_log.txt', session[:cfgsitelocation]+'/cdl_version.txt', 
                session[:cfgsitelocation]+'/site_ptc_db.db', session[:cfgsitelocation]+'/rc2key.bin',session[:cfgsitelocation]+'/sin.txt', wiuxmlpath].each do |file|
                  flname = File.basename file
                  if(flname != temp) 
                    if (systemtype.downcase == "cpu-iii")
                      if ((flname == "cic.bin") || (flname == "nvconfig.sql3"))
                        zf.add(flname.upcase, file)
                      else
                        zf.add(flname, file)
                      end
                    else if(systemtype.downcase == "geo")
                      if ((File.extname(file)=='.mcf') || (File.extname(file)=='.MCF'))
                        zf.add("Safetran/#{milepost+'-'+sitename}/GEO/Configuration/MCF/MCFs/"+flname, file)
                      elsif ((flname == "site_details.yml") || (flname == "mcf.db") || (flname == "rt.db") )
                        zf.add("Safetran/#{milepost+'-'+sitename}/GEO/"+flname, file)
                      else
                        zf.add("Safetran/#{milepost+'-'+sitename}/GEO/Configuration/0/"+ flname, file)
                      end
                    else
                      if ((File.extname(file)=='.mcf') || (File.extname(file)=='.MCF'))
                        zf.add("Safetran/#{milepost+'-'+sitename}/iVIU/Configuration/MCF/MCFs/"+flname, file)
                      elsif ((flname == "site_details.yml") || (flname == "mcf.db") || (flname == "rt.db") )
                        zf.add("Safetran/#{milepost+'-'+sitename}/iVIU/"+flname, file)
                      else
                        zf.add("Safetran/#{milepost+'-'+sitename}/iVIU/Configuration/0/"+ flname, file)
                      end
                    end 
                 end
                  temp = flname
                end  
              end
            end
          end
          rescue Exception => e
            flash[:configedtmessage] = e.message
            render :json =>{:error=> true , :message => e.message}
          end
          render :json =>{:error=> false, :file_path => bundle_filename}
        else
          configedtmessage = "Build files not available Please build and try again"
          flash[:configedtmessage] = configedtmessage
          render :json =>{:error=> true , :message => configedtmessage}
        end
      end
    end
  end
  
  ####################################################################
  # Function:      download_export_site_config
  # Parameters:    params[:file_path]
  # Retrun:        file_path
  # Renders:       send_file
  # Description:   Send the exported site configuration zip file to window
  ####################################################################    
  def download_export_site_config
    file_path = params[:file_path]
    send_file  file_path ,:disposition => 'inline' ,:stream => false
  end

  ####################################################################
  # Function:      selectinstallationame
  # Parameters:    params[:Masterdbselected] , params[:installationname]
  # Retrun:        session[:mcftypename] + '|' + session[:selectedinstallationname]
  # Renders:       render :text
  # Description:   Get the mcf type for selected installation name 
  ####################################################################  
  def selectinstallationame
    session[:selectedmasterdb] = params[:Masterdbselected]
    session[:selectedinstallationname] = params[:installationname]
    get_installation_type(params[:typeofsystem] || session[:typeOfSystem])
    render :text => session[:mcftypename] + '|' + session[:selectedinstallationname]
  end
  
  ####################################################################
  # Function:      get_installation_type
  # Parameters:    @typeOfSystem 
  # Retrun:        session[:mcftypename]
  # Renders:       None
  # Description:   Get the installation type for corresponding selected installation name
  ####################################################################  
  def get_installation_type(typeofsystem)
    @typeOfSystem = typeofsystem
    returnmcftype = nil
    session[:mcftypename] = nil
    unless session[:selectedmasterdb].blank?
      unless session[:selectedinstallationname].blank?
        installationtype = Mcfptc.select_gol_type(session[:selectedinstallationname])
        unless installationtype.blank?
          if installationtype[0][:GOLType].to_i == 1
            returnmcftype = "Non-Appliance Model"
          else
            returnmcftype = "Appliance Model"
          end
          session[:mcftypename] = returnmcftype
        else
          session[:mcftypename] = "Incomplete Installation"
        end
      end
    else
      session[:mcftypename] = ""  
    end
  end
  
  ####################################################################
  # Function:      createsitename
  # Parameters:    params[:typeofsystem] , session[:cfgsitelocation] , params[:sitename]
  # Retrun:        returnvalue
  # Renders:       render :text
  # Description:   Create site if the given site name already exist
  ####################################################################  
  def createsitename
    @typeOfSystem = params[:typeofsystem]
    
    sitename = params[:sitename]
    gcp_comments = params[:comments]
    template_enable = params[:template_checked]
    sitenameleftstrip = sitename.lstrip
    sitenamerightstrip = sitenameleftstrip.rstrip
    returnvalue =""
    unless sitenamerightstrip.blank?
      if File.directory?(session[:OCE_ConfigPath] + sitenamerightstrip)
        returnvalue = "Site name already exist"
        session[:sitename] = nil
        session[:cfgLocationconpath] = nil
      else
        returnvalue ="Success"
        session[:sitename]= sitenamerightstrip
        session[:cfgLocationconpath] = sitenamerightstrip
      end
    else
      session[:sitename] = nil
      session[:cfgLocationconpath] = nil
    end
   if @typeOfSystem == "GCP" && returnvalue == "Success"
     session[:comments]= gcp_comments
     session[:template_enable]= template_enable
   else
     session[:comments]= ""
     session[:template_enable] = nil
   end
    render :text => returnvalue
  end

  ####################################################################
  # Function:      select_mcf
  # Parameters:    params[:type] , session[:sitename]
  # Retrun:        refreshflag , session[:cfgsitelocation] , params[:selected_mcfCRCValue]
  # Renders:       render :json
  # Description:   Transfer the selected mcf file from client side to server current configuration location
  ####################################################################
  def select_mcf
    createfile = ""
    nv_config_name = ""
    @typeOfSystem = params[:type]
    unless session[:sitename].blank?
      createfile = session[:OCE_ConfigPath] + session[:sitename]
      session[:cfgsitelocation] = createfile
      if !File.directory?(createfile)
        Dir.mkdir(createfile)
        site_details_info = {"Site Type" => @typeOfSystem}
        write_site_details(createfile , site_details_info)
        initialDBpath = ""
        if @typeOfSystem == "iVIU PTC GEO" || @typeOfSystem == "iVIU" 
          initialDBpath = RAILS_ROOT.to_s + "/db/InitialDB/iviu"
        elsif @typeOfSystem == "GEO" || @typeOfSystem == "CPU-III" || @typeOfSystem == "VIU"
          initialDBpath = RAILS_ROOT.to_s + "/db/InitialDB/geo"
        elsif @typeOfSystem == "GCP" 
          initialDBpath = RAILS_ROOT.to_s + "/db/InitialDB/gcp"
        end
        session[:cfgLocationconpath] = session[:sitename]
        if (@typeOfSystem == "VIU")
           nvconfig_template = RAILS_ROOT + "/oce_configuration/templates/" + @typeOfSystem.downcase + "/nvconfig.bin"
          if File.exist?(nvconfig_template)
            FileUtils.cp(nvconfig_template, createfile + "/nvconfig.bin")
          else
            FileUtils.cp("#{RAILS_ROOT.to_s}/db/InitialDB/viu/nvconfig.bin", createfile + "/nvconfig.bin")
          end
        end
        if !params[:nv_ver].blank?
          nv_config_name =  "nvconfig_" + params[:nv_ver].to_s + ".sql3"
        else
          nv_config_name = "nvconfig.sql3"
        end
        session[:nv_ver] = ""
        nvconfig_template = "#{RAILS_ROOT}/oce_configuration/templates/#{@typeOfSystem.downcase}/nvconfig.sql3"
        # Copy the InitialDB nvconfig.sql3 to site folder if typeOfSystem == "GCP"
        if ((@typeOfSystem != "GCP") && File.exist?(nvconfig_template))
          FileUtils.cp(nvconfig_template, "#{createfile}/nvconfig.sql3")
        else
          FileUtils.cp("#{initialDBpath}/#{nv_config_name}", "#{createfile}/nvconfig.sql3")
        end
        (ActiveRecord::Base.configurations["development"])["database"] = session[:cfgsitelocation]+'/nvconfig.sql3'

        StringParameter.stringparam_update_query(session[:sitename].to_s, 1)
        FileUtils.cp(initialDBpath + "/rtstatus.sql3", createfile + "/rtstatus.sql3")
        (ActiveRecord::Base.configurations["real_time_status_db"])["database"] = session[:cfgsitelocation]+'/rtstatus.sql3'
        if @typeOfSystem == "iVIU PTC GEO"
          EnumParameter.enumparam_update_query(101,195)   #Log GEO Event should be yes default (!iVIU)
          EnumParameter.enumparam_update_query(101,193)   #Send msg on change of state should be yes default (!iVIU)          
        end
        if @typeOfSystem == "iVIU PTC GEO" || @typeOfSystem == "iVIU" || @typeOfSystem == "GEO"
          Generalststistics.update_ptc_enable             # Enable the PTC-WIU - ptc_enable flag
        end
        strmsg = generate_rc2key(@typeOfSystem) if @typeOfSystem != "GCP"
      end
      unless session[:cfgsitelocation].blank? 
        Dir.foreach(session[:cfgsitelocation]) do |x| 
          if (File.extname(x)=='.mcf' || File.extname(x)=='.log' || File.basename(x)== 'mcf.db' || File.basename(x)=='rt.db' || File.basename(x)=='cic.bin' || File.fnmatch('WiuConfig-*', File.basename(x)) || File.basename(x)=='PTCUCN.txt' || File.basename(x)=='UCN.txt' || File.basename(x)=='ApprovalCRC.txt' || File.basename(x)=='sin.txt' || File.basename(x)=='site_ptc_db.db' ||File.basename(x)=='decompiled_rt.db' || File.fnmatch('viu_configuration_report*', File.basename(x)) || File.fnmatch('configuration_report*', File.basename(x)) || File.fnmatch('GEO_PTC_Installation_Listing_Report*', File.basename(x)))          
            File.delete(session[:cfgsitelocation] + '/' + x)
          end
        end
        if (@typeOfSystem == "VIU")
          FileUtils.cp("#{RAILS_ROOT.to_s}/db/InitialDB/geo/GEOPTC.db" , createfile+"/site_ptc_db.db")
        end
        if File.directory?(session[:cfgsitelocation])
          selected_site_mcf = params[:selected_site_mcf].downcase
          uploaded_mcf_path = ""
          unless params[:uploaded_mcf_path].blank?
            uploaded_mcf_path = params[:uploaded_mcf_path].downcase
          end
          session[:mcfCRCValue] = params[:selected_mcfCRCValue]
          if (selected_site_mcf == uploaded_mcf_path)
            unless params[:mcffileUpload].blank?
              file_name = params[:mcffileUpload].original_filename
              session[:mcfnamefromselected]= file_name
              directory = session[:cfgsitelocation]
              content = params[:mcffileUpload].read
              path = File.join(directory, file_name)
              File.open(path, "wb") { |f| f.write(content) }
            end
          else
            unless params[:selected_site_mcf].blank?
              mcfname_load = params[:selected_site_mcf].split('/')
              unless params[:selected_site_mcf].blank?
                mcfname_selected = mcfname_load[mcfname_load.length-1]
                session[:mcfnamefromselected] = mcfname_selected
                FileUtils.cp(params[:selected_site_mcf], createfile +"/"+ mcfname_selected)
              end
            end
          end
          unless session[:pid].blank?
            # Close existing cfgmagr.exe file using pid
            close_cfgmgr(session[:pid])
          end
          if @typeOfSystem == "VIU"
            strmsg = ""
            session[:cfgmgr_state] = false
            strmsg = run_cfgmgr   
            if strmsg.blank?
              flash[:errormessage] = nil
              if params[:saveasflag] == "saveas"
                update_viu_siteinfo(session[:sitename], session[:mcfCRCValue])
              end
            else
              flash[:errormessage] = strmsg
            end
          end
          session[:sitecreation] = true
        end
      end
      unless session[:selectedmasterdb].blank?
        mcf_installation_collection = Installationtemplate.all.map(&:InstallationName)
        if session[:selectedinstallationname] != nil
        else
          session[:selectedinstallationname] = mcf_installation_collection[0]
        end
      else
        session[:selectedinstallationname] = nil
      end
      update_site_details(createfile , @typeOfSystem)
    end
    header_function
    
    # typeofsystem: sys_type,
    # mcfcrc: mcfcrc,
    # comments : comments
    params[:typeofsystem] = @typeOfSystem
    params[:mcfcrc] = session[:mcfCRCValue]
    updateconfiguration
    
    #render :nothing => true 
  end

  ####################################################################
  # Function:      update_site_details
  # Parameters:    sitelocation , site_type
  # Retrun:        sitelocation , site_details_info
  # Renders:       None
  # Description:   Update site details mcf, mcfcrc , site type in the site_details.yml  
  ####################################################################  
  def update_site_details(sitelocation , site_type)
    hexaCRC = params[:selected_mcfCRCValue].upcase.split('X')
    strhexaCRC = (hexaCRC.length > 1)? hexaCRC[1].to_s : hexaCRC[0].to_s 
    session[:mcfCRCValue] = strhexaCRC
    selecetd_mcf_path = params[:selected_site_mcf]
    session[:mcfnamefromselected]  = File.basename(selecetd_mcf_path) if !selecetd_mcf_path.blank?
    site_details_info = {}
    if site_type == 'iVIU PTC GEO'
      masterdbname_split = session[:selectedmasterdb].split('/')
      site_details_info = {"Site Type" => site_type , 
                         "Master Database" => masterdbname_split[masterdbname_split.length-1].strip.to_s , 
                         "Installation Name" => session[:selectedinstallationname] ,
                         "MCF Name" => session[:mcfnamefromselected].to_s ,
                         "MCFCRC" => strhexaCRC }
    elsif site_type == 'CPU-III'
      site_details_info = {"Site Type" => site_type , 
                         "MCF Name" => session[:mcfnamefromselected].to_s ,
                         "MCFCRC" => strhexaCRC }
    elsif site_type == 'GCP'
      gcp_comments = session[:comments]
      template_check = session[:template_enable]
      if template_check == true || template_check == "true"
        config_type = "TPL"
      else if template_check == false || template_check == "false"
        config_type = "PAC"
      end
     end
      site_details_info = {"Site Type" => site_type , 
                         "MCF Name" => session[:mcfnamefromselected].to_s ,
                         "MCFCRC" => strhexaCRC,                         
                         "Config Type" => config_type,
                         "Comments" => gcp_comments}
    else
      site_details_info = {"Site Type" => site_type , 
                         "MCF Name" => session[:mcfnamefromselected].to_s ,
                         "MCFCRC" => strhexaCRC }
    end
    write_site_details(sitelocation , site_details_info)
  end
  
  ####################################################################
  # Function:      updateconfiguration
  # Parameters:    params[:typeofsystem]
  # Retrun:        session[:errorandwarning]
  # Renders:       render :json
  # Description:   Update the configurations using the selected mcf file and generate rt.db & mcf.db 
  ####################################################################  
  def updateconfiguration
    session[:errorandwarning] = ""
    ptc_enable_val = false
    siteptc_upgrade_msg = nil
    config_type = ""
    @typeOfSystem = params[:typeofsystem]
    sitelocation =  session[:OCE_ConfigPath] + session[:cfgLocationconpath] 
    session[:cfgsitelocation] = sitelocation
    connectdatabase()
    selectedmcfname = "#{session[:cfgsitelocation]}/#{session[:mcfnamefromselected]}"

    if (@typeOfSystem != "GCP" && (findAMorNonAM_mcf(selectedmcfname) == false))
      session[:save] = "save"
      render :text=> "newsite"+"|"+"OCE can't create site configuration for Non-Applianc Model MCF" and return
      #render :json =>{:error_message => "OCE can't create site configuration for Non-Applianc Model MCF" } and return
    end
    if @typeOfSystem == "GCP"
      unless params[:comments].blank?
      session[:comments]= params[:comments]
      end
      template_check = session[:template_enable]
      if template_check == true || template_check == "true"
        config_type = "TPL"
      elsif template_check == false || template_check == "false"
        config_type = "PAC"
      end
      #-------------------- Validate PAC/TPL and MCF ---------------------------
      if (params[:new_site_type] != "create_new_site" && (!params[:uploaded_pac_path].blank? || !params[:mcffileUpload].blank?))
        pac1_directory = "#{RAILS_ROOT}/tmp/tplextract"
        file_name = File.basename(params[:uploaded_pac_path])
        file_name = File.basename(params[:selected_pac]) if file_name.blank?
        pac_path = File.join(pac1_directory, file_name)
        xml_name = file_name.chomp(File.extname(file_name))
        xml_path = "#{pac1_directory}/#{xml_name}.XML"        
        valid_mcf_pac = validate_pac_tpl_with_mcf(selectedmcfname, xml_path)
        if (!valid_mcf_pac)
          session[:errorandwarning] = "Upgrade/Downgrade to/from GCP 5000/4000 is not supported."
          session[:save]="save"
          render :text => "newsite"+"|"+session[:errorandwarning].to_s + "|||||" + valid_mcf_pac.to_s
          return
        end
      end
    end
    crcvalidateflag = false 
    calculatedmcfcrc = nil
    strhexaCRC = nil
    hexaCRC = params[:mcfcrc].split('x')
    if hexaCRC.length >1
      strhexaCRC = hexaCRC[1].to_s
    else
      strhexaCRC = hexaCRC[0].to_s
    end
    decimalCRC = strhexaCRC.hex
    if @typeOfSystem == "iVIU" || @typeOfSystem == "iVIU PTC GEO"|| @typeOfSystem == "GEO"
      IntegerParameter.integerparam_update_query(decimalCRC, 516)
      StringParameter.stringparam_update_query(session[:mcfnamefromselected].to_s, 116)
    elsif @typeOfSystem == "CPU-III"      
      IntegerParameter.update_all("Value =  '#{decimalCRC}'", {:Group_ID => 2, :Name => 'MCFCRC'})      
    end
    
    unless params[:mcfcrc].blank?
      session[:mcfCRCValue] = strhexaCRC
    end
    
    libcic = WIN32OLE.new('CIC_BIN.CICBIN')                
    calculatedmcfcrc = libcic.GetMcfCrc(converttowindowspath(selectedmcfname), @typeOfSystem.upcase.to_s)
    puts 'MCFCRC: ' + calculatedmcfcrc.inspect
    crcvalidateflag = true
    strCrcMsg = ""
    if (calculatedmcfcrc.hex != strhexaCRC.hex)      
      crcvalidateflag = false
      strCrcMsg = "MCF CRC"
    end
    
    if (crcvalidateflag == true)
      if @typeOfSystem == "iVIU PTC GEO"
        root_values_db
      end
      begin 
        Dir.foreach(session[:cfgsitelocation]) do |x| 
          if (File.extname(x)=='.log' || File.basename(x)== 'mcf.db' || 
            File.basename(x)=='rt.db' || File.basename(x)=='cic.bin' || 
            File.fnmatch('WiuConfig-*', File.basename(x)) || File.basename(x)=='PTCUCN.txt' || 
            File.basename(x)=='UCN.txt' || File.basename(x)=='ApprovalCRC.txt' || 
            File.basename(x)=='sin.txt' || File.basename(x)=='site_ptc_db.db' ||
            File.basename(x)=='decompiled_rt.db' || File.fnmatch('viu_configuration_report*', File.basename(x)) || 
            File.fnmatch('configuration_report*', File.basename(x)) || 
            File.fnmatch('GEO_PTC_Installation_Listing_Report*', File.basename(x)))
            
            next if File.basename(x)=='site_ptc_db.db' &&  @typeOfSystem == "VIU"
            File.delete(session[:cfgsitelocation]+'/'+x)
          end
        end
      rescue Exception => e
        session[:save] = "save"
        session[:errorandwarning] = e
        render :text => "newsite"+"|"+session[:errorandwarning].to_s and return
      end
      if @typeOfSystem == "iVIU PTC GEO"
       if (session[:selectedinstallationname] != nil)
        createsiteptcdb(session[:selectedmasterdb], session[:selectedinstallationname])
        end
      end
      session[:newopenflag] = 1
      if session[:mcfnamefromselected].blank?
        flash[:configedtmessage] = "Please Select the Config Location and mcf file"
      else
        if (session[:selectedinstallationname] != "nil") || (session[:selectedinstallationname] != "") || (@typeOfSystem == 'VIU')
          hexaCRC = session[:mcfCRCValue].split('x')
          if hexaCRC.length > 1
            strhexaCRC = hexaCRC[1].to_s  
          else
            strhexaCRC = hexaCRC[0].to_s
          end
          if @typeOfSystem == 'iVIU PTC GEO'
            masterdbname_split = session[:selectedmasterdb].split('/')
            site_details_info = {"Site Type" => @typeOfSystem , 
                               "Master Database" => masterdbname_split[masterdbname_split.length-1].strip.to_s , 
                               "Installation Name" => session[:selectedinstallationname] ,
                               "MCF Name" => session[:mcfnamefromselected].to_s ,
                               "MCFCRC" => strhexaCRC }  
          elsif @typeOfSystem == 'CPU-III'
            site_details_info = {"Site Type" => @typeOfSystem , 
                               "MCF Name" => session[:mcfnamefromselected].to_s ,
                               "MCFCRC" => strhexaCRC}
          elsif @typeOfSystem == 'GCP'
            site_details_info = {"Site Type" => @typeOfSystem , 
                               "MCF Name" => session[:mcfnamefromselected].to_s ,
                               "MCFCRC" => strhexaCRC,
                               "Config Type" => config_type,                               
                               "Comments" => session[:comments]}
          else
            site_details_info = {"Site Type" => @typeOfSystem , 
                               "MCF Name" => session[:mcfnamefromselected].to_s ,
                               "MCFCRC" => strhexaCRC }
          end
          write_site_details(sitelocation , site_details_info)
          mcfpath = sitelocation+'/'+session[:mcfnamefromselected].to_s
          out_dir =  RAILS_ROOT+"/oce_configuration/"+session[:user_id].to_s+'/DT2'
          if @typeOfSystem == "iVIU PTC GEO"
            geoptc_db = session[:siteptcdblocation]
          else
            geoptc_db=""
          end
          instalationname = session[:selectedinstallationname]
          aspectlookuptxtfilepath = session[:aspectfilepath] 
          begin
            if @typeOfSystem == "GCP"
              # Copy the existing MCFCRC matched databases(mcf\gcp\<MCFCRC>) to site folder
              copy_file_msg_flag = false
              copy_file_msg = "success"
              mcfcrc_folder = "#{RAILS_ROOT}/oce_configuration/mcf/gcp/#{strhexaCRC}"
              if File.exists?(mcfcrc_folder)
                mcfcrc_folder_empty_flag = (Dir.entries(mcfcrc_folder) == [".", ".."])
                # if the MCFCRC folder not empty go to validate & copy files
                if mcfcrc_folder_empty_flag == false  
                  copy_file_msg = copy_gcp_siteconfig(mcfcrc_folder , sitelocation)
                else
                  copy_file_msg = "MCFCRC Folder Empty"
                end  
                copy_file_msg_flag = true
                copy_file_msg = "success" if copy_file_msg.blank?
              end
              
              # Create the site configuration files using the selected mcf if don't have existing MCF repo((mcf\gcp\<MCFCRC>))  
              if ((copy_file_msg_flag == false) && (copy_file_msg == "success")) || ((copy_file_msg_flag == true) && (copy_file_msg != "success"))   
                default_aux_path = "#{RAILS_ROOT}/doc/"
                fixfile_path = "#{RAILS_ROOT}/config/FIXPARAMS.XML"
                simulator = "\"#{session[:OCE_ROOT]}\\GCP_OCE_Manager.exe\", \"#{0}\" \"#{converttowindowspath(sitelocation)}\" \"#{session[:OCE_ROOT]}\" \"#{mcfpath}\" \"#{default_aux_path}\" \"#{fixfile_path}\""
                puts  simulator
                if system(simulator)
                  gcp_errorfilepath = sitelocation+'/oce_gcp_error.log'
                  if File.exists?(gcp_errorfilepath)
                    file = File.open(gcp_errorfilepath, "r")
                    content = file.read
                    unless content.blank?
                      session[:errorandwarning] = content.to_s
                      if session[:errorandwarning].include?('Error')
                        session[:save]="save"
                        render :text => "newsite"+"|"+ session[:errorandwarning].to_s+"|"+ @typeOfSystem+"|"+ ptc_enable_val.to_s and return
                        #render :json =>{:warning_message => session[:errorandwarning] , :site_type => @typeOfSystem , :ptc_enable => ptc_enable_val } and return
                      else
                        session[:save]="configure"
                        copy_mcffile_and_create_mcfcrclog(mcfpath, @typeOfSystem , strhexaCRC)
                       # Copy the mc.db , rt.db , Aux files in to created MCFCRC folder 
                        Dir.mkdir(mcfcrc_folder) unless File.exists? mcfcrc_folder
                        copy_file_msg = copy_gcp_siteconfig(sitelocation , mcfcrc_folder)                 
                        session[:errorandwarning] = "Successfully created site. " + session[:errorandwarning]
                      end
                      puts session[:errorandwarning]  
                    else
                      session[:errorandwarning] = nil
                      copy_mcffile_and_create_mcfcrclog(mcfpath, @typeOfSystem , strhexaCRC)
                     # Copy the mc.db , rt.db , Aux files in to created MCFCRC folder 
                     Dir.mkdir(mcfcrc_folder) unless File.exists? mcfcrc_folder
                     copy_file_msg = copy_gcp_siteconfig(sitelocation , mcfcrc_folder)
                     session[:save]="configure"
                    end
                  else
                    session[:errorandwarning] = nil
                    copy_mcffile_and_create_mcfcrclog(mcfpath, @typeOfSystem , strhexaCRC)
                   # Copy the mc.db , rt.db , Aux files in to created MCFCRC folder 
                   Dir.mkdir(mcfcrc_folder) unless File.exists? mcfcrc_folder
                   copy_file_msg = copy_gcp_siteconfig(sitelocation , mcfcrc_folder)
                   session[:save]="configure"
                  end
#                  
#                  # Copy the mc.db , rt.db , Aux files in to created MCFCRC folder 
#                  Dir.mkdir(mcfcrc_folder) unless File.exists? mcfcrc_folder
#                  copy_file_msg = copy_gcp_siteconfig(sitelocation , mcfcrc_folder)
                  if !copy_file_msg.blank?
                    empty_flag = (Dir.entries(mcfcrc_folder) == [".", ".."])
                    if empty_flag == true
                      FileUtils.rm_rf(mcfcrc_folder, :secure=>true)
                    end
                    session[:errorandwarning] = copy_file_msg
                    session[:save] = "save"
                  end
                else
                  session[:errorandwarning] = "Error: Site creation process failed."
                  session[:save] = "save"
                  render :text => "newsite"+"|"+session[:errorandwarning].to_s and return
                end
              end
            else
              nvconfig_template = "#{RAILS_ROOT}/oce_configuration/templates/#{@typeOfSystem.downcase}/nvconfig.sql3"
              nv_template_flag = "false"
              if ((@typeOfSystem != "GCP") && File.exist?(nvconfig_template))
                nv_template_flag = "true"              
              end
              simulator = "\"#{session[:OCE_ROOT]}\\UIConnector.exe\", \"#{converttowindowspath(mcfpath)}\" \"#{converttowindowspath(out_dir)}\" \"#{converttowindowspath(geoptc_db)}\" \"#{instalationname}\" \"#{@typeOfSystem}\" \"#{1}\" \"#{0}\" \"#{converttowindowspath(aspectlookuptxtfilepath)}\" \"#{nv_template_flag}\" "
              puts  simulator
              if system(simulator) 
                errorfilepath = out_dir+'/UIConnector_Error.log'
                if File.exist?(errorfilepath)
                  file = File.open(errorfilepath, "r")
                  content = file.read
                  unless content.blank?
                    session[:errorandwarning] = content
                    if session[:errorandwarning].include?('Error')
                      session[:save]="save"
                      render :text => "newsite"+"|"+ session[:errorandwarning].to_s and return
                    else
                      session[:save]="configure"
                      copy_mcffile_and_create_mcfcrclog(mcfpath, @typeOfSystem , strhexaCRC)
                      session[:errorandwarning] = "Successfully created site. " + session[:errorandwarning]
                    end
                    puts session[:errorandwarning]  
                  else
                    session[:errorandwarning] = nil
                    copy_mcffile_and_create_mcfcrclog(mcfpath, @typeOfSystem , strhexaCRC)
                    session[:save]="configure"
                  end
                else
                  session[:errorandwarning] = nil
                  copy_mcffile_and_create_mcfcrclog(mcfpath, @typeOfSystem , strhexaCRC)
                  session[:save]="configure"
                end
              else
                session[:errorandwarning] = "Error: Site creation process failed."
                session[:save] = "save"
                render :text => "newsite"+"|"+session[:errorandwarning].to_s and return
              end
            end
          rescue Exception => e
            session[:save] = "save"
            session[:errorandwarning] = e
            render :text => "newsite"+"|"+session[:errorandwarning].to_s and return
          end
          connectdatabase()
          get_gcp_type
          atcs_addr =  Gwe.find(:first, :select => "sin").try(:sin)
          StringParameter.stringparam_update_query(atcs_addr.to_s, 4)
          if (@typeOfSystem == "GCP")
            if @gcp_4000_version
              StringParameter.update_all "DisplayOrder =  '4'", "ID = '4'"
            else
              arr_sin = atcs_addr.split('.')
              IntegerParameter.integerparam_update_query(arr_sin[1].to_i , 1)
              IntegerParameter.integerparam_update_query(arr_sin[2].to_i , 2)
              IntegerParameter.integerparam_update_query(arr_sin[3].to_i , 3)
              IntegerParameter.integerparam_update_query(arr_sin[4].to_i , 5)
            end
          else
            RtParameter.update_current_to_dafault_vale(session[:cfgsitelocation]+'/rt.db')
          end
          
          if @typeOfSystem == "VIU"
            # update sitename and MCFCRC with nvconfig.bin , sin value with RT.db
            update_viu_siteinfo(session[:sitename], session[:mcfCRCValue])
            if File.exist?(session[:cfgsitelocation]+'/site_ptc_db.db')
               session[:siteptcdblocation] = session[:cfgsitelocation]+'/site_ptc_db.db'
               (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:siteptcdblocation]
               temp_mcfname = session[:mcfnamefromselected].to_s.gsub('.mcf','')
               session[:selectedinstallationname] = temp_mcfname
               clear_and_create_siteptcdb(temp_mcfname, session[:siteptcdblocation], decimalCRC)
            end
          end
          if (@typeOfSystem == 'iVIU' || @typeOfSystem == 'GEO') 
            if File.exist?(session[:cfgsitelocation]+'/site_ptc_db.db')
              intialdb_path = RAILS_ROOT+'/db/InitialDB/iviu/GEOPTC.db'
              siteptc_path = session[:cfgsitelocation]+'/site_ptc_db.db'
              upgradesiteptclib  = WIN32OLE.new('MCFPTCDataExtractor.MCFExtractor')                
              siteptc_upgrade_msg = upgradesiteptclib.ValidateDbSchema(converttowindowspath(intialdb_path),converttowindowspath(siteptc_path))
              session[:siteptcdblocation] = session[:cfgsitelocation]+'/site_ptc_db.db'
               (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:siteptcdblocation]
              gcname = Gcfile.find(:all,:select =>"GCName").map(&:GCName)
              session[:selectedinstallationname] = gcname[0].to_s
              Ptcdevice.Update_ptcsitedeviceid_all
            else
              session[:siteptcdblocation] = nil
              session[:selectedinstallationname] = nil
            end
            ptc_enable_val = true
            Generalststistics.update_ptc_enable
          elsif (@typeOfSystem == 'iVIU PTC GEO')
            ptc_enable_val = true
            Generalststistics.update_ptc_enable
          elsif (@typeOfSystem == 'CPU-III')
            rt_card_information = RtCardInformation.find(:first ,:conditions =>["card_type=45"])
            unless rt_card_information.blank?
              ptc_enable_val = true
              Generalststistics.update_ptc_enable             # Enable the PTC-WIU - ptc_enable flag
            end
            if File.exist?(session[:cfgsitelocation]+'/site_ptc_db.db')
              intialdb_path = RAILS_ROOT+'/db/InitialDB/iviu/GEOPTC.db'
              siteptc_path = session[:cfgsitelocation]+'/site_ptc_db.db'
              upgradesiteptclib  = WIN32OLE.new('MCFPTCDataExtractor.MCFExtractor')                
              siteptc_upgrade_msg = upgradesiteptclib.ValidateDbSchema(converttowindowspath(intialdb_path),converttowindowspath(siteptc_path))
              session[:siteptcdblocation] = session[:cfgsitelocation]+'/site_ptc_db.db'
              (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:siteptcdblocation]
              gcname = Gcfile.find(:all,:select =>"GCName").map(&:GCName)
              session[:selectedinstallationname] = gcname[0].to_s              
            else
              session[:siteptcdblocation] = nil
              session[:selectedinstallationname] = nil
            end
          elsif (@typeOfSystem == "GCP")
            # Execute below block statements only the template/pac selected from the Select MCF dialog 
            if params[:new_site_type] && !params[:new_site_type].blank?
              errorandwarning = import_template_pac_files
              if !errorandwarning.blank?
                session[:errorandwarning] = errorandwarning
                session[:save]="save"
                render :text => "newsite"+"|"+session[:errorandwarning].to_s and return
              end 
            end
          end
          # Validate the MCF and RT Database and set the flag 
          validatemcfrtdatabase(session[:cfgsitelocation])
        end
      end
    else
      session[:errorandwarning] = "Error: Please enter correct #{strCrcMsg} value(s)."
      session[:save]="save"
      render :text => "newsite"+"|"+session[:errorandwarning].to_s + "||||" + crcvalidateflag.to_s and return
    end
    if @typeOfSystem !="iVIU PTC GEO"
      unless siteptc_upgrade_msg.blank?
        session[:errorandwarning] = siteptc_upgrade_msg
      end
    end
    render :text => "newsite"+"|"+""+"|"+session[:errorandwarning].to_s + "|" + @typeOfSystem + "|" + ptc_enable_val.to_s
    #render :json =>{:warning_message => session[:errorandwarning] , :site_type => @typeOfSystem , :ptc_enable => ptc_enable_val }
  end
  
 def clear_and_create_siteptcdb(temp_mcfname, db_path, decimalCRC)

    db = SQLite3::Database.new(db_path)

    db.execute("Delete From GCFile")
    db.execute("Delete From InstallationTemplate")
    db.execute("Delete From MCF")
    db.execute("Delete From MCFPhysicalLayout")
    db.execute("Delete From ATCSConfig")

    db.execute("Insert into GCFile (GCName,InstallationName) Values('#{temp_mcfname.to_s}','#{temp_mcfname.to_s}_1')")
    db.execute("Insert into InstallationTemplate (InstallationName) Values('#{temp_mcfname.to_s}_1')")
    db.execute("Insert into MCF(MCFName, CRC, GOLType) Values('#{temp_mcfname.to_s}','#{decimalCRC}',3)")
    db.execute("Insert into MCFPhysicalLayout (PhysLayoutNumber,PhysLayoutName, " +
    "GCName, MCFName, Subnode, InstallationName) Values('1', '#{temp_mcfname.to_s}'," +
    "'#{temp_mcfname.to_s}', '#{temp_mcfname.to_s}', '3', '#{temp_mcfname.to_s}_1' )")
    db.execute("Insert into ATCSConfig (Subnode, SubnodeName, GCName, UCN, InstallationName) Values(" +
    "'3', '#{temp_mcfname.to_s}', '#{temp_mcfname.to_s}', '0', '#{temp_mcfname.to_s}_1')")

    db.close
  end
  
  ####################################################################
  # Function:      copy_mcffile_and_create_mcfcrclog
  # Parameters:    selectedmcfpath, systemtype , selectedmcfcrc
  # Retrun:        None
  # Renders:       None
  # Description:   Display the event/Diag log in the page
  ####################################################################  
  
  def copy_mcffile_and_create_mcfcrclog(selectedmcfpath, systemtype , selectedmcfcrc)
    begin
        rootpath = nil
        rootpath = mcf_root_path(systemtype.downcase)
        root_directory = File.join(RAILS_ROOT, "/oce_configuration/mcf/#{rootpath}")
        mcf_root = File.join(RAILS_ROOT, "/oce_configuration/mcf")
        unless File.exists?(mcf_root)
          Dir.mkdir(mcf_root)
          unless File.exists?(root_directory)
            Dir.mkdir(root_directory)
          end
        else
          unless File.exists?(root_directory)
            Dir.mkdir(root_directory)
          end
        end
        mcfname_split = selectedmcfpath.split('/')
        mcfname = mcfname_split[mcfname_split.length-1]
        logfilename_split = mcfname.split('.')
        logfilename = logfilename_split[0]+'.log'
        logpath = "#{root_directory}/#{logfilename}"
        mcfpath = root_directory+'/'+mcfname
        if File.exist?(mcfpath)
          FileUtils.rm_rf(mcfpath)  
        end  
        FileUtils.cp(selectedmcfpath , mcfpath)
        if File.exist?(logpath)
          FileUtils.rm_rf(logpath)
        end
        File.open(logpath, "w+"){|f|
          f.puts "MCF CRC : 0x"+selectedmcfcrc
        }
      rescue Exception => e
        puts e.inspect
    end
  end
  
  ####################################################################
  # Function:      root_values_db
  # Parameters:    None
  # Retrun:        @root_entries
  # Renders:       None
  # Description:   Get the all available master database list
  ####################################################################  
  def root_values_db
    root_directory = File.join(RAILS_ROOT, "/Masterdb")
    Dir.mkdir(root_directory) unless File.exists? root_directory
    if Dir[root_directory + "/*"] !=nil
      @root_entries = Dir[root_directory + "/*"].reject{|f| [".", ".."].include? f}
    else
      @root_entries = nil
    end
  end

  ####################################################################
  # Function:      sendconfigreport
  # Parameters:    params[:typeofsystem]
  # Retrun:        None
  # Renders:       send_file
  # Description:   Send the configuration report file to the user
  ####################################################################  
  def sendconfigreport
    configreportfile = nil
    @typeOfSystem = params[:typeofsystem]
    Dir.foreach(session[:cfgsitelocation]) do |x| 
      if @typeOfSystem == "VIU"
        if File.fnmatch('viu_configuration_report*', File.basename(x))
          configreportfile = x
        end
      else
        if File.fnmatch('configuration_report*', File.basename(x))
          configreportfile = x
        end
      end
    end
    path =""
    unless configreportfile.blank?
      path = File.join(session[:cfgsitelocation] , configreportfile)
    end
    send_file(path, :filename => "Configuration Report.txt",:dispostion=>'inline',:status=>'200 OK',:stream=>'true' )
  end
  
  ####################################################################
  # Function:      send_gcp_configreports
  # Parameters:    params[:typeofsystem]
  # Retrun:        None
  # Renders:       send_file
  # Description:   Send the configuration report file to the user
  ####################################################################  
  def send_gcp_configreports
    configreportfile = ""
    report_type = params[:report_type]
    file_name_start , file_name = get_report_file_name(report_type)
    puts file_name_start.inspect , file_name.inspect
    Dir.foreach(session[:cfgsitelocation]) do |x| 
        if File.fnmatch("#{file_name_start}*", File.basename(x))
          configreportfile = x
        end
    end
    path =""
    unless configreportfile.blank?
      path = File.join(session[:cfgsitelocation] , configreportfile)
    end
    send_file(path, :filename => file_name ,:dispostion=>'inline',:status=>'200 OK',:stream=>'true' )
  end
  
  ####################################################################
  # Function:      sendgeoptclistiningreport
  # Parameters:    None
  # Retrun:        path
  # Renders:       send_file
  # Description:   Download the geo ptc listioning report to the user
  ####################################################################  
  def sendgeoptclistiningreport
    configreportfile = nil
    Dir.foreach(session[:cfgsitelocation]) do |x| 
      if File.fnmatch('GEO_PTC_Installation_Listing_Report_*', File.basename(x))
        configreportfile = x
      end
    end
    path =""
    unless configreportfile.blank?
      path = File.join(session[:cfgsitelocation] , configreportfile)
    end
    send_file(path, :filename => "GEO_PTC_Installation_Listing_Report.txt",:dispostion=>'inline',:status=>'200 OK',:stream=>'true' )
  end
  
  ####################################################################
  # Function:      select_switch
  # Parameters:    switch_type
  # Retrun:        None
  # Renders:       None
  # Description:   Return the switch type string value according to switch type vale
  ####################################################################  
  def select_switch(switch_type)
    case switch_type
      when 0 then return "Switch"
      when 1 then return "Switch with No NK2"
      when 2 then return "DT switch/Electric lock"      
    end
  end

  ####################################################################
  # Function:      create_geo_ptc_installation_listing_report
  # Parameters:    params[:typeofsystem] ,session[:cfgsitelocation]
  # Retrun:        None
  # Renders:       None
  # Description:   create geo ptc installation listing report
  ####################################################################  
  def create_geo_ptc_installation_listing_report
    @typeOfSystem = params[:typeofsystem]
    if File.exists?(session[:cfgsitelocation]+'/site_ptc_db.db')
     (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:cfgsitelocation]+'/site_ptc_db.db'
      begin 
        mcf_installations = Installationtemplate.all.map(&:InstallationName)
        installation_name_default = nil
        unless mcf_installations.blank?
          activeinstallation = Gwe.find(:all,:select=>"active_physical_layout").map(&:active_physical_layout)
          installation_name_default = mcf_installations[activeinstallation[0].to_i-1]
          if installation_name_default.blank?
            installation_name_default = session[:selectedinstallationname].to_s
          end
        end
        Dir.foreach(session[:cfgsitelocation]) do |x| 
          if File.fnmatch('configuration_report*', File.basename(x))
            name = "GEO_PTC_Installation_Listing_Report_"+Date.today.strftime('%d-%m-%Y')+'.txt'
            geoptcinstallation_filepath = session[:cfgsitelocation]+'/'+name
            File.open(geoptcinstallation_filepath, "w+"){|f| 
              f.puts "GEO PTC Installation Listing Report"
              f.puts "===================================="
              f.puts
              report_site_name_display = StringParameter.get_string_value(1 , "Site Name")
              f.puts "Site Name          : "+ report_site_name_display
              newtime = Time.new
              todaydatetime = newtime.strftime("%d-%m-%Y %H:%M:%S")
              f.puts "Date/Time          : "+todaydatetime.to_s
              f.puts "OCE Version        : "+ session[:webui_version].to_s
              site_details = open_site_details("#{session[:cfgsitelocation]}/site_details.yml")
              iviumcfcrcvalue = site_details["MCFCRC"].strip.to_s  
              iviumcfname = site_details["MCF Name"].strip.to_s   
              f.puts "iVIU MCF Name/CRC  : "+iviumcfname+' / '+'0x'+iviumcfcrcvalue
              mcf_names = Mcfphysicallayout.find(:all, :select =>"MCFName", :conditions => {:InstallationName => installation_name_default.to_s}).map(&:MCFName).uniq
              mcf_names.each do |mcf|
                mcfcrc = Mcfptc.find_by_MCFName(mcf, :select => "CRC").try(:CRC)
                if mcfcrc
                  intvalue = mcfcrc.to_i
                  mcfhexaCRCvale= '0x'+intvalue.to_s(16).upcase.to_s
                  f.puts "GEO MCF Name/CRC   : "+mcf.to_s+' / '+mcfhexaCRCvale.to_s
                else
                  f.puts "GEO MCF Name/CRC   : "+mcf.to_s+' / 0'
                end
              end
              if (@typeOfSystem == "iVIU PTC GEO")
                database = session[:selectedmasterdb] 
                dbvalue = database.split('/')
                f.puts "PTC GEO Database   : "+dbvalue[dbvalue.length-1]
              else
                f.puts "PTC GEO Database   : site_ptc_db.db"
              end
              f.puts "Installation Name  : "+ installation_name_default.to_s
              instname = installation_name_default.to_s
              installation = Installationtemplate.find_by_InstallationName(installation_name_default.to_s, :include => [:ptcdevices])
              ptcdevices = installation.ptcdevices
              goltype = Mcfptc.find_by_MCFName(mcf_names[0], :select => "GOLType").try(:GOLType).to_s == "1" ? "Non Appliance Model" : "Appliance Model"
              ptc_devices = ptcdevices.select{|device| device.InstallationName == installation.InstallationName}
              signals = []
              switches = []
              hazarddetectors = []
              ptc_devices.each do |ptc_device|
                signals << ptc_device.signal unless ptc_device.signal.blank?
                switches << ptc_device.switch unless ptc_device.switch.blank?
                hazarddetectors << ptc_device.hazarddetector unless ptc_device.hazarddetector.blank?
              end  
              signalcount = switchcount = hdcount = 1
              unless signals.blank?
                f.puts
                f.puts "SIGNALS"
                f.puts "======="
                case goltype
                  when "Appliance Model"
                  signals.each do |signal|
                    f.puts 'Signal'+signalcount.to_s+' : ' + signal.ptcdevice.PTCDeviceName
                    logic_states = Logicstate.find(:all, :conditions =>['Id=?',signal.Id], :order => "BitPosn asc")
                    f.puts "       Conditions         : " + signal.Conditions.to_s
                    f.puts "       Stop Aspect        : " + signal.StopAspect.to_s
                    f.puts "       Subnode            : " + signal.ptcdevice.Subnode.to_s
                    f.puts "       Aspect LS          : " + logic_states[0].try(:LogicStateNumber).to_s
                    f.puts "       Bit Position       : " + logic_states[0].try(:BitPosn).to_s
                    f.puts "       Contiguous Count   : " + logic_states[0].try(:ContiguousCount).to_s
                    f.puts "       IsDark LS          : " + logic_states[1].try(:LogicStateNumber).to_s
                    f.puts "       Bit Position       : " + logic_states[1].try(:BitPosn).to_s
                    f.puts "       Contiguous Count   : " + logic_states[1].try(:ContiguousCount).to_s
                    f.puts "       T1L                : " + logic_states[2].try(:LogicStateNumber).to_s
                    f.puts "       Bit Position       : " + logic_states[2].try(:BitPosn).to_s
                    f.puts "       Contiguous Count   : " + logic_states[2].try(:ContiguousCount).to_s
                    f.puts "       STASP              : " + logic_states[3].try(:LogicStateNumber).to_s
                    f.puts "       Bit Position       : " + logic_states[3].try(:BitPosn).to_s
                    f.puts "       Contiguous Count   : " + logic_states[3].try(:ContiguousCount).to_s
                    asptid = Signals.columns.map(&:name).include?('AspectId1')
                    if asptid
                      f.puts "       Aspect Id1         : " + signal.AspectId1.to_s
                      f.puts "       Alt Aspect1        : " + signal.AltAspect1.to_s
                      f.puts "       Aspect Id2         : " + signal.AspectId2.to_s
                      f.puts "       Alt Aspect2        : " + signal.AltAspect2.to_s
                      f.puts "       Aspect Id3         : " + signal.AspectId3.to_s
                      f.puts "       Alt Aspect3        : " + signal.AltAspect3.to_s
                    end
                    f.puts
                    signalcount = signalcount + 1
                  end
                  when "Non Appliance Model"
                  signals.each do |signal|
                    f.puts 'Signal'+signalcount.to_s+' : ' + signal.ptcdevice.PTCDeviceName
                    logic_states = Logicstate.find(:all, :conditions =>['Id=?',signal.Id], :order => "BitPosn asc")
                    cirout = []
                    ciroutflash = []
                    cirin = []
                    logic_states.each do |bitposition|
                      bitpos = bitposition.try(:BitPosn)
                      if bitpos >=0 && bitpos <=9
                        cirout << bitposition
                      elsif bitpos >=10 && bitpos <=19
                        ciroutflash << bitposition
                      elsif bitpos >=20 
                        cirin << bitposition
                      end
                    end
                    f.puts "       HeadA                  : " + signal.HeadA.to_s
                    f.puts "       HeadB                  : " + signal.HeadB.to_s
                    f.puts "       HeadC                  : " + signal.HeadC.to_s 
                    f.puts "       Subnode                : " + signal.ptcdevice.Subnode.to_s
                    unless cirout.blank?
                      for out in 0...(cirout.length.to_i)
                        if (cirout.length.to_i == 1)
                          f.puts "       CirOut.Aspect Steady   : " + cirout[out].try(:LogicStateNumber).to_s
                        else
                          f.puts "       CirOut.Aspect Steady#{out+1}  : " + cirout[out].try(:LogicStateNumber).to_s
                        end
                        f.puts "       Bit Position           : " + cirout[out].try(:BitPosn).to_s
                        f.puts "       Contiguous Count       : " + cirout[out].try(:ContiguousCount).to_s
                      end
                    else
                      f.puts "       CirOut.Aspect Steady   : "
                      f.puts "       Bit Position           : " 
                      f.puts "       Contiguous Count       : "
                    end
                    unless ciroutflash.blank?
                      for flash in 0...(ciroutflash.length.to_i)
                        if (ciroutflash.length.to_i == 1)
                          f.puts "       CirOut.Aspect Flashing : " + ciroutflash[flash].try(:LogicStateNumber).to_s
                        else
                          f.puts "       CirOut.Aspect Flashing#{flash+1} : " + ciroutflash[flash].try(:LogicStateNumber).to_s
                        end
                        f.puts "       Bit Position           : " + ciroutflash[flash].try(:BitPosn).to_s
                        f.puts "       Contiguous Count       : " + ciroutflash[flash].try(:ContiguousCount).to_s
                      end
                    else
                      f.puts "       CirOut.Aspect Flashing : " 
                      f.puts "       Bit Position           : " 
                      f.puts "       Contiguous Count       : " 
                    end
                    unless cirin.blank?
                      for cin in 0...(cirin.length.to_i)
                        if (cirin.length.to_i == 1)
                          f.puts "       CirIn.Aspect           : " + cirin[cin].try(:LogicStateNumber).to_s
                        else
                          f.puts "       CirIn.Aspect#{cin+1}          : " + cirin[cin].try(:LogicStateNumber).to_s
                        end
                        f.puts "       Bit Position           : " + cirin[cin].try(:BitPosn).to_s
                        f.puts "       Contiguous Count       : " + cirin[cin].try(:ContiguousCount).to_s
                      end
                    else
                      f.puts "       CirIn.Aspect           : "
                      f.puts "       Bit Position           : " 
                      f.puts "       Contiguous Count       : "
                    end
                    asptid = Signals.columns.map(&:name).include?('AspectId1')
                    if asptid
                      f.puts "       Aspect Id1             : " + signal.AspectId1.to_s
                      f.puts "       Alt Aspect1            : " + signal.AltAspect1.to_s
                      f.puts "       Aspect Id2             : " + signal.AspectId2.to_s
                      f.puts "       Alt Aspect2            : " + signal.AltAspect2.to_s
                      f.puts "       Aspect Id3             : " + signal.AspectId3.to_s
                      f.puts "       Alt Aspect3            : " + signal.AltAspect3.to_s
                    end
                    f.puts
                    signalcount = signalcount + 1
                  end
                end #case END
              end
              unless switches.blank?
                f.puts
                f.puts "SWITCHES"
                f.puts "========"
                case goltype
                  when "Appliance Model"
                  switches.each do |switch|
                    f.puts 'Switch'+switchcount.to_s+' :' + switch.ptcdevice.PTCDeviceName
                    f.puts "       Subnode             : " + switch.ptcdevice.Subnode.to_s
                    logic_states = Logicstate.find(:all, :conditions =>['Id=?',switch.Id], :order => "BitPosn asc")  
                    f.puts "       Switch Type         : " + select_switch(switch.SwitchType.to_i)
                    f.puts "       Number of LS        : " + switch.NumberOfLogicStates.to_s
                    f.puts "       NWP                 : " + logic_states[0].try(:LogicStateNumber).to_s
                    f.puts "       Bit Position        : " + logic_states[0].try(:BitPosn).to_s
                    f.puts "       Contiguous Count    : " + logic_states[0].try(:ContiguousCount).to_s
                    f.puts "       RWP                 : " + logic_states[1].try(:LogicStateNumber).to_s
                    f.puts "       Bit Position        : " + logic_states[1].try(:BitPosn).to_s
                    f.puts "       Contiguous Count    : " + logic_states[1].try(:ContiguousCount).to_s                                            
                    switchcount = switchcount + 1
                  end
                  when "Non Appliance Model"
                  switches.each do |switch|
                    f.puts 'Switch'+switchcount.to_s+' :' + switch.ptcdevice.PTCDeviceName
                    f.puts "       Subnode            : " + switch.ptcdevice.Subnode.to_s
                    logic_states = Logicstate.find(:all, :conditions =>['Id=?',switch.Id], :order => "BitPosn asc")  
                    f.puts "       Switch Type        : " + select_switch(switch.SwitchType.to_i) 
                    f.puts "       Number of LS       : " + switch.NumberOfLogicStates.to_s
                    if (logic_states.length == 1)
                      f.puts "       NWP                : " + logic_states[0].try(:LogicStateNumber).to_s
                      f.puts "       Bit Position       : " + logic_states[0].try(:BitPosn).to_s
                      f.puts "       Contiguous Count   : " + logic_states[0].try(:ContiguousCount).to_s
                      f.puts "       RWP                : " 
                      f.puts "       Bit Position       : " 
                      f.puts "       Contiguous Count   : "                                                
                      f.puts
                    elsif (logic_states.length == 2)
                      f.puts "       NWP                : " + logic_states[0].try(:LogicStateNumber).to_s
                      f.puts "       Bit Position       : " + logic_states[0].try(:BitPosn).to_s
                      f.puts "       Contiguous Count   : " + logic_states[0].try(:ContiguousCount).to_s
                      f.puts "       RWP                : " + logic_states[1].try(:LogicStateNumber).to_s
                      f.puts "       Bit Position       : " + logic_states[1].try(:BitPosn).to_s
                      f.puts "       Contiguous Count   : " + logic_states[1].try(:ContiguousCount).to_s
                      f.puts
                    else
                      f.puts "       NWP                : " 
                      f.puts "       Bit Position       : " 
                      f.puts "       Contiguous Count   : " 
                      f.puts "       RWP                : " 
                      f.puts "       Bit Position       : " 
                      f.puts "       Contiguous Count   : " 
                      f.puts
                    end
                    switchcount = switchcount + 1
                  end
                end
              end
              unless hazarddetectors.blank?
                f.puts
                f.puts "HAZARD DETECTOR"
                f.puts "==============="
                hazarddetectors.each do |hd|
                  logic_states = Logicstate.find(:all, :conditions =>['Id=?',hd.Id], :order => "BitPosn asc")
                  f.puts 'Hazard Detector'+hdcount.to_s+' : ' + hd.ptcdevice.PTCDeviceName
                  f.puts "       Subnode            : " + hd.ptcdevice.Subnode.to_s
                  f.puts "       AUX                : " + logic_states[0].try(:LogicStateNumber).to_s
                  f.puts "       Bit Position       : " + logic_states[0].try(:BitPosn).to_s
                  f.puts "       Contiguous Count   : " + logic_states[0].try(:ContiguousCount).to_s
                  f.puts
                  hdcount = hdcount + 1
                end
              end
              if goltype == "Appliance Model"
                aspectcount = 1
                aspects = Aspect.find(:all, :select=>"[Index],AspectName", :conditions=>['InstallationName=?',instname])
                unless aspects.blank?
                  f.puts 
                  f.puts "Aspect Table"
                  f.puts "============"
                  txtfilepath = session[:aspectfilepath]
                  aspects.each do |aspect|
                    f.puts 'Aspect'+aspectcount.to_s+' : ' 
                    f.puts "       GEO Aspect         : " + aspect.AspectName
                    returnvalue = nil
                    begin
                      file = File.new(txtfilepath, "r")
                      while (line = file.gets)
                        result=[]
                        data = "#{line}"
                        result = data.split(", \"")
                        if (result.length == 1)
                          result = data.split(",\"")
                        end
                        restrim = []
                        restrim1 = result[0].split("\"")
                        restrim = result[1].split("\"")
                        restrimf= restrim[0].split(", \"")
                        if(restrim1[0].rstrip.upcase == aspect.AspectName.upcase)
                          returnvalue = restrimf[0].rstrip
                          break
                        end
                      end
                      file.close
                    end  
                    unless returnvalue.blank?
                      ptcaspects = Ptcaspect.all(:conditions => {:InstallationName => instname },:order => "PTCCode asc")
                      for i in 0...(ptcaspects.length)
                        if (ptcaspects[i].AspectName.upcase == returnvalue.upcase)
                          f.puts "       PTC Aspect         : " + ptcaspects[i].AspectName.to_s 
                          f.puts "       PTC Code           : " + ptcaspects[i].PTCCode.to_s
                          break
                        end
                      end
                    else
                      f.puts "       PTC Aspect         : " 
                      f.puts "       PTC Code           : "
                    end
                    aspectcount = aspectcount + 1
                  end
                end
              end
              # Existing Report Merging Start - Only Vital Configuration report need to merge
              f.puts
              countflag = false
              file = File.new(session[:cfgsitelocation]+'/'+x, "r")
              while (line = file.gets)
                if ((line.rstrip.to_s.upcase =="VITAL CONFIGURATION") || (line.rstrip.to_s.upcase =="MCF CONFIGURATION") || (countflag == true))
                  f.puts line  
                  countflag = true
                end
              end
              file.close
              # Existing Report Merging END
              return "Success"
            }
          end
        end
      rescue Exception => e  
        return "Got Problem in GEO PTC Installation Listing Report creation, " + e.to_s
      end
    else
      return "Site ptc database not available please use latest mcf"
    end
  end

  ####################################################################
  # Function:      create_viu_geo_ptc_report
  # Parameters:    None
  # Retrun:        return success message /fail message
  # Renders:       None
  # Description:   update the viu geo ptc information in the viu configuration report 
  ####################################################################  
  def create_viu_geo_ptc_report
    if File.exists?(session[:cfgsitelocation]+'/site_ptc_db.db')
     (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:cfgsitelocation]+'/site_ptc_db.db'
      begin 
        Dir.foreach(session[:cfgsitelocation]) do |x| 
          if File.fnmatch('viu_configuration_*', File.basename(x))
            report_path = "#{session[:cfgsitelocation]}/#{x}"
            File.open(report_path, "a+"){|f| 
              f.puts
              f.puts "GEO PTC Report"
              f.puts "=============="
              f.puts
              installation_name_default = Installationtemplate.all.map(&:InstallationName)
              instname = installation_name_default[0].to_s
              installation = Installationtemplate.find_by_InstallationName(installation_name_default[0].to_s, :include => [:ptcdevices])
              ptcdevices = installation.ptcdevices
              mcf_names = Mcfphysicallayout.find(:all, :select =>"MCFName", :conditions => {:InstallationName => installation_name_default[0].to_s}).map(&:MCFName).uniq
              goltype = Mcfptc.find_by_MCFName(mcf_names[0], :select => "GOLType").try(:GOLType).to_s == "1" ? "Non Appliance Model" : "Appliance Model"
              ptc_devices = ptcdevices.select{|device| device.InstallationName == installation.InstallationName}
              signals = []
              switches = []
              hazarddetectors = []
              unless ptc_devices.blank?
                ptc_devices.each do |ptc_device|
                  signals << ptc_device.signal unless ptc_device.signal.blank?
                  switches << ptc_device.switch unless ptc_device.switch.blank?
                  hazarddetectors << ptc_device.hazarddetector unless ptc_device.hazarddetector.blank?
                end  
              else
                f.puts "No devices available"
              end
              signalcount = switchcount = hdcount = 1
              unless signals.blank?
                f.puts
                f.puts "SIGNALS"
                f.puts "======="
                case goltype
                  when "Appliance Model"
                  signals.each do |signal|
                    f.puts 'Signal'+signalcount.to_s+' : ' + signal.ptcdevice.PTCDeviceName
                    logic_states = Logicstate.find(:all, :conditions =>['Id=?',signal.Id], :order => "BitPosn asc")
                    f.puts "       Conditions         : " + signal.Conditions.to_s
                    f.puts "       Stop Aspect        : " + signal.StopAspect.to_s
                    f.puts "       Subnode            : " + signal.ptcdevice.Subnode.to_s
                    f.puts "       Aspect LS          : " + logic_states[0].try(:LogicStateNumber).to_s
                    f.puts "       Bit Position       : " + logic_states[0].try(:BitPosn).to_s
                    f.puts "       Contiguous Count   : " + logic_states[0].try(:ContiguousCount).to_s
                    f.puts "       IsDark LS          : " + logic_states[1].try(:LogicStateNumber).to_s
                    f.puts "       Bit Position       : " + logic_states[1].try(:BitPosn).to_s
                    f.puts "       Contiguous Count   : " + logic_states[1].try(:ContiguousCount).to_s
                    f.puts "       T1L                : " + logic_states[2].try(:LogicStateNumber).to_s
                    f.puts "       Bit Position       : " + logic_states[2].try(:BitPosn).to_s
                    f.puts "       Contiguous Count   : " + logic_states[2].try(:ContiguousCount).to_s
                    f.puts "       STASP              : " + logic_states[3].try(:LogicStateNumber).to_s
                    f.puts "       Bit Position       : " + logic_states[3].try(:BitPosn).to_s
                    f.puts "       Contiguous Count   : " + logic_states[3].try(:ContiguousCount).to_s
                    asptid = Signals.columns.map(&:name).include?('AspectId1')
                    if asptid
                      f.puts "       Aspect Id1         : " + signal.AspectId1.to_s
                      f.puts "       Alt Aspect1        : " + signal.AltAspect1.to_s
                      f.puts "       Aspect Id2         : " + signal.AspectId2.to_s
                      f.puts "       Alt Aspect2        : " + signal.AltAspect2.to_s
                      f.puts "       Aspect Id3         : " + signal.AspectId3.to_s
                      f.puts "       Alt Aspect3        : " + signal.AltAspect3.to_s
                    end
                    f.puts
                    signalcount = signalcount + 1
                  end
                  when "Non Appliance Model"
                  signals.each do |signal|
                    f.puts 'Signal'+signalcount.to_s+' : ' + signal.ptcdevice.PTCDeviceName
                    logic_states = Logicstate.find(:all, :conditions =>['Id=?',signal.Id], :order => "BitPosn asc")
                    cirout = []
                    ciroutflash = []
                    cirin = []
                    logic_states.each do |bitposition|
                      bitpos = bitposition.try(:BitPosn)
                      if bitpos >=0 && bitpos <=9
                        cirout << bitposition
                      elsif bitpos >=10 && bitpos <=19
                        ciroutflash << bitposition
                      elsif bitpos >=20 
                        cirin << bitposition
                      end
                    end
                    f.puts "       HeadA                  : " + signal.HeadA.to_s
                    f.puts "       HeadB                  : " + signal.HeadB.to_s
                    f.puts "       HeadC                  : " + signal.HeadC.to_s 
                    f.puts "       Subnode                : " + signal.ptcdevice.Subnode.to_s
                    unless cirout.blank?
                      for out in 0...(cirout.length.to_i)
                        if (cirout.length.to_i == 1)
                          f.puts "       CirOut.Aspect Steady   : " + cirout[out].try(:LogicStateNumber).to_s
                        else
                          f.puts "       CirOut.Aspect Steady#{out+1}  : " + cirout[out].try(:LogicStateNumber).to_s
                        end
                        f.puts "       Bit Position           : " + cirout[out].try(:BitPosn).to_s
                        f.puts "       Contiguous Count       : " + cirout[out].try(:ContiguousCount).to_s
                      end
                    else
                      f.puts "       CirOut.Aspect Steady   : "
                      f.puts "       Bit Position           : " 
                      f.puts "       Contiguous Count       : "
                    end
                    unless ciroutflash.blank?
                      for flash in 0...(ciroutflash.length.to_i)
                        if (ciroutflash.length.to_i == 1)
                          f.puts "       CirOut.Aspect Flashing : " + ciroutflash[flash].try(:LogicStateNumber).to_s
                        else
                          f.puts "       CirOut.Aspect Flashing#{flash+1} : " + ciroutflash[flash].try(:LogicStateNumber).to_s
                        end
                        f.puts "       Bit Position           : " + ciroutflash[flash].try(:BitPosn).to_s
                        f.puts "       Contiguous Count       : " + ciroutflash[flash].try(:ContiguousCount).to_s
                      end
                    else
                      f.puts "       CirOut.Aspect Flashing : " 
                      f.puts "       Bit Position           : " 
                      f.puts "       Contiguous Count       : " 
                    end
                    unless cirin.blank?
                      for cin in 0...(cirin.length.to_i)
                        if (cirin.length.to_i == 1)
                          f.puts "       CirIn.Aspect           : " + cirin[cin].try(:LogicStateNumber).to_s
                        else
                          f.puts "       CirIn.Aspect#{cin+1}          : " + cirin[cin].try(:LogicStateNumber).to_s
                        end
                        f.puts "       Bit Position           : " + cirin[cin].try(:BitPosn).to_s
                        f.puts "       Contiguous Count       : " + cirin[cin].try(:ContiguousCount).to_s
                      end
                    else
                      f.puts "       CirIn.Aspect           : "
                      f.puts "       Bit Position           : " 
                      f.puts "       Contiguous Count       : "
                    end
                    asptid = Signals.columns.map(&:name).include?('AspectId1')
                    if asptid
                      f.puts "       Aspect Id1             : " + signal.AspectId1.to_s
                      f.puts "       Alt Aspect1            : " + signal.AltAspect1.to_s
                      f.puts "       Aspect Id2             : " + signal.AspectId2.to_s
                      f.puts "       Alt Aspect2            : " + signal.AltAspect2.to_s
                      f.puts "       Aspect Id3             : " + signal.AspectId3.to_s
                      f.puts "       Alt Aspect3            : " + signal.AltAspect3.to_s
                    end
                    f.puts
                    signalcount = signalcount + 1
                  end
                end #case END
              end
              unless switches.blank?
                f.puts
                f.puts "SWITCHES"
                f.puts "========"
                case goltype
                  when "Appliance Model"
                  switches.each do |switch|
                    f.puts 'Switch'+switchcount.to_s+' :' + switch.ptcdevice.PTCDeviceName
                    f.puts "       Subnode             : " + switch.ptcdevice.Subnode.to_s
                    logic_states = Logicstate.find(:all, :conditions =>['Id=?',switch.Id], :order => "BitPosn asc")  
                    f.puts "       Switch Type         : " + select_switch(switch.SwitchType.to_i)
                    f.puts "       Number of LS        : " + switch.NumberOfLogicStates.to_s
                    f.puts "       NWP                 : " + logic_states[0].try(:LogicStateNumber).to_s
                    f.puts "       Bit Position        : " + logic_states[0].try(:BitPosn).to_s
                    f.puts "       Contiguous Count    : " + logic_states[0].try(:ContiguousCount).to_s
                    f.puts "       RWP                 : " + logic_states[1].try(:LogicStateNumber).to_s
                    f.puts "       Bit Position        : " + logic_states[1].try(:BitPosn).to_s
                    f.puts "       Contiguous Count    : " + logic_states[1].try(:ContiguousCount).to_s                                            
                    switchcount = switchcount + 1
                  end
                  when "Non Appliance Model"
                  switches.each do |switch|
                    f.puts 'Switch'+switchcount.to_s+' :' + switch.ptcdevice.PTCDeviceName
                    f.puts "       Subnode            : " + switch.ptcdevice.Subnode.to_s
                    logic_states = Logicstate.find(:all, :conditions =>['Id=?',switch.Id], :order => "BitPosn asc")  
                    f.puts "       Switch Type        : " + select_switch(switch.SwitchType.to_i) 
                    f.puts "       Number of LS       : " + switch.NumberOfLogicStates.to_s
                    if (logic_states.length == 1)
                      f.puts "       NWP                : " + logic_states[0].try(:LogicStateNumber).to_s
                      f.puts "       Bit Position       : " + logic_states[0].try(:BitPosn).to_s
                      f.puts "       Contiguous Count   : " + logic_states[0].try(:ContiguousCount).to_s
                      f.puts "       RWP                : " 
                      f.puts "       Bit Position       : " 
                      f.puts "       Contiguous Count   : "                                                
                      f.puts
                    elsif (logic_states.length == 2)
                      f.puts "       NWP                : " + logic_states[0].try(:LogicStateNumber).to_s
                      f.puts "       Bit Position       : " + logic_states[0].try(:BitPosn).to_s
                      f.puts "       Contiguous Count   : " + logic_states[0].try(:ContiguousCount).to_s
                      f.puts "       RWP                : " + logic_states[1].try(:LogicStateNumber).to_s
                      f.puts "       Bit Position       : " + logic_states[1].try(:BitPosn).to_s
                      f.puts "       Contiguous Count   : " + logic_states[1].try(:ContiguousCount).to_s
                      f.puts
                    else
                      f.puts "       NWP                : " 
                      f.puts "       Bit Position       : " 
                      f.puts "       Contiguous Count   : " 
                      f.puts "       RWP                : " 
                      f.puts "       Bit Position       : " 
                      f.puts "       Contiguous Count   : " 
                      f.puts
                    end
                    switchcount = switchcount + 1
                  end
                end
              end
              unless hazarddetectors.blank?
                f.puts
                f.puts "HAZARD DETECTOR"
                f.puts "==============="
                hazarddetectors.each do |hd|
                  logic_states = Logicstate.find(:all, :conditions =>['Id=?',hd.Id], :order => "BitPosn asc")
                  f.puts 'Hazard Detector'+hdcount.to_s+' : ' + hd.ptcdevice.PTCDeviceName
                  f.puts "       Subnode            : " + hd.ptcdevice.Subnode.to_s
                  f.puts "       AUX                : " + logic_states[0].try(:LogicStateNumber).to_s
                  f.puts "       Bit Position       : " + logic_states[0].try(:BitPosn).to_s
                  f.puts "       Contiguous Count   : " + logic_states[0].try(:ContiguousCount).to_s
                  f.puts
                  hdcount = hdcount + 1
                end
              end
              return "Success"
            }
          end
        end
      rescue Exception => e  
        return "Got Problem in VIU GEO PTC Report creation, " + e.to_s
      end
    else
      return "Site ptc database not available please use latest mcf"
    end
  end
  
  ####################################################################
  # Function:      saveassiteconfigfiles
  # Parameters:    params[:saveassitename]
  # Retrun:        returnvalue
  # Renders:       render :text
  # Description:   Save as the opened site with new name
  ####################################################################  
  def saveassiteconfigfiles
    close_database_connection
    sitename = params[:saveassitename]
    sitenameleftstrip = sitename.lstrip
    sitenamerightstrip = sitenameleftstrip.rstrip
    returnvalue =""
    @typeOfSystem = session[:typeOfSystem].to_s
    if @typeOfSystem == "GCP"
      source_folder = "#{session[:cfgsitelocation]}"
      errormsg = validate_gcp_supportfiles(source_folder)
      if !errormsg.blank?
        render :json =>{:message=>errormsg} and return
      end
    end
    unless sitenamerightstrip.blank?
      root_directory = session[:OCE_ConfigPath] + sitenamerightstrip
      unless File.directory?(root_directory)
        Dir.mkdir(root_directory)
        Dir.chdir(session[:cfgsitelocation])
        filelist = Dir.glob("*.{CDL,LLW,LLB,MCF,GC}")
        varientfileslist = []
        filelist.each do |fle|
          varientfileslist << "#{session[:cfgsitelocation]}/#{fle}"
        end
        if @typeOfSystem == "VIU"
          varientfileslist << "#{session[:cfgsitelocation]}/nvconfig.bin"
        elsif @typeOfSystem == "GCP"
          pac_file_available = ""
          Dir.chdir(session[:cfgsitelocation])
          mcf_file = Dir.glob("*.{MCF}")
          if mcf_file.blank?
            pac_file = Dir.glob("*.{PAC}")
            if pac_file.length >0
              pac_file_available = pac_file[0]
            end
            varientfileslist << "#{session[:cfgsitelocation]}/#{pac_file_available}" if !pac_file_available.blank?
          end
          if File.exists?(source_folder)
		        copy_gcp_siteconfig(source_folder , root_directory)
          end
        end
        if @typeOfSystem == "GCP"
          fixednamefiles = Dir[session[:cfgsitelocation]+'/nvconfig.sql3' , session[:cfgsitelocation]+'/site_details.yml',session[:cfgsitelocation]+'/cdl_log.txt' , session[:cfgsitelocation]+'/cdl_version.txt']
        else
          fixednamefiles = Dir[session[:cfgsitelocation]+'/nvconfig.sql3' , session[:cfgsitelocation]+'/mcf.db', session[:cfgsitelocation]+'/rt.db' , session[:cfgsitelocation]+'/site_details.yml' , session[:cfgsitelocation]+'/site_ptc_db.db' , session[:cfgsitelocation]+'/cdl_log.txt' , session[:cfgsitelocation]+'/cdl_version.txt']
        end
        copyallfiles = fixednamefiles + varientfileslist
        copyallfiles.each do |x |
          filename = x.split('/')
          FileUtils.cp(x , "#{root_directory}/#{filename[filename.length-1]}")
        end
        returnvalue = root_directory
        unless session[:pid].blank?
          # Close existing cfgmagr.exe file using pid
          close_cfgmgr(session[:pid])
        end
      else
        returnvalue = "Site name already exist"
      end
    end
    render :text =>returnvalue
  end
  
  ####################################################################
  # Function:      saveas_site
  # Parameters:    session[:cfgsitelocation]
  # Retrun:        @sitelocation
  # Renders:       render :layout 
  # Description:   Display the page to eneter the save as site name
  ####################################################################  
  def saveas_site
    unless session[:cfgsitelocation].blank?
      @sitelocation = session[:cfgsitelocation]
    else
      @sitelocation = nil
    end
    render :layout => false
  end
  
  ####################################################################
  # Function:      create_rc2keyfile
  # Parameters:    None
  # Retrun:        false
  # Renders:       render :layout 
  # Description:   Display the RC2Key file creation page
  ####################################################################  
  def create_rc2keyfile
    render :layout => false
  end
  
  ####################################################################
  # Function:      generate_rc2keyfile
  # Parameters:    params[:txtrc2key_value]
  # Retrun:        filname , rc2key_bin_crc
  # Renders:       render :json
  # Description:   Generate the RC2KEY.bin file 
  ####################################################################  
  def generate_rc2keyfile
    rc2keyvalue  = params[:txtrc2key_value]
    Dir.glob("#{RAILS_ROOT}/tmp/*.bin").each do |file|
       if File.exist?(file) && file.include?("_#{session[:user_id]}_")
          FileUtils.rm_rf(file)  
       end
    end
    filname = "rc2key_#{session[:user_id]}_#{Time.now.to_i}.bin"
    path = "#{RAILS_ROOT}/tmp/#{filname}"
    libcic = WIN32OLE.new('CIC_BIN.CICBIN')
    strmsg = libcic.GenerateRc2KeyFile(path , rc2keyvalue)
    if File.exists?(path)
      unless strmsg.blank?
        rc2Keybin  = File.open(path, "r")
        rc2Keybin_values = rc2Keybin.read
        if rc2Keybin_values.include? "CRC:"
          rc2Key_crc= rc2Keybin_values.split('CRC:')
          rc2key_bin_crc = rc2Key_crc[1].to_s 
        end
        render :json => {:rc2key_filename =>filname ,:rc2keyvale_crc =>rc2key_bin_crc }
      end
    else
       render :text => ""
    end
  end
  
  ####################################################################
  # Function:      download_rc2keyfile
  # Parameters:    params[:rc2key_filename]
  # Retrun:        None
  # Renders:       send_file
  # Description:   Download the RC2KEY.bin file from the specified path
  ####################################################################  
  def download_rc2keyfile
    file_name = params[:rc2key_filename]
    path = "#{RAILS_ROOT}/tmp/#{file_name}"
    if File.exists?(path)
      send_file(path, :filename => "rc2key.bin", :type=>'application/octet-stream', :disposition=>'attachment', :encoding=>'utf8', :stream=>'true')
    end
  end

  ####################################################################
  # Function:      check_importsitename
  # Parameters:    params[:sitename]
  # Retrun:        response_text
  # Renders:       render :text
  # Description:   Check the import site name already exist or not
  ####################################################################  
  def check_importsitename
    sitename = params[:sitename]
    response_text = ""
    unless sitename.blank?
      site_location = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/#{sitename.to_s}"
      if File.directory?(site_location) && !File.file?(site_location)
        response_text = "override"
      end
    end
    render :text =>response_text
  end

  ####################################################################
  # Function:      select_import_site
  # Parameters:    None
  # Retrun:        None
  # Renders:       None
  # Description:   Open the import site configuration page
  ####################################################################  
  def select_import_site
    render :layout => false
  end
  
  ####################################################################
  # Function:      select_import_files
  # Parameters:    params[:upload_siteconfig_zip]
  # Retrun:        message
  # Renders:       render :json 
  # Description:   Import the selected site configuration zip files
  ####################################################################  
  def select_import_files
     begin
      message = nil
      file_name = params[:upload_siteconfig_zip].original_filename
      file_type = file_name[-3,3].upcase
      site_name = ""
      
      gcp_zip_flag = false
      pacimport_temp_directory = "#{RAILS_ROOT}/tmp/paccontent"
      zip_path_val = ""
      type_str = ""
      if (file_type == "ZIP")
        Dir.mkdir(pacimport_temp_directory) unless File.exists? pacimport_temp_directory
        # Remove the all the files from the 'paccontent' temp directory and sub folders
        Pathname.new(pacimport_temp_directory).children.each { |p| p.rmtree }
        
        file_name = params[:upload_siteconfig_zip].original_filename
        content = params[:upload_siteconfig_zip].read
        path = File.join(pacimport_temp_directory, file_name)
        File.open(path, "wb") { |f| f.write(content) }
        
        Zip::ZipFile.open(path) do |zip_file|
          zip_file.each do |f|
            split_values = f.name.split(".")
            type_val = split_values[split_values.length-1].downcase
            if (gcp_zip_flag == false) && (type_val == "tpl" || type_val == "pac" )
              unzip_dir_path = "#{RAILS_ROOT}/tmp/paccontent/sitefiles"
              Dir.mkdir(unzip_dir_path) unless File.exists? unzip_dir_path
              # Remove the all the files from the 'paccontent' temp directory and sub folders
              Pathname.new(unzip_dir_path).children.each { |p| p.rmtree }
              
              f_path = File.join("#{unzip_dir_path}/", f.name)
              FileUtils.mkdir_p(File.dirname(f_path))
              zip_file.extract(f, f_path) unless File.exist?(f_path)
              gcp_zip_flag = true
              zip_path_val = f_path
              type_str = type_val.upcase
            end
          end
        end
      end
      
      site_type = ""
      site_type = "GCP" if gcp_zip_flag == true
      
      if params[:gcp_site_name].blank?        
        site_name = validate_sitename(file_name , site_type)
      else
        site_name = validate_sitename("#{params[:gcp_site_name]}.#{file_type}" , site_type)
      end

      puts "Site_name: " + site_name.inspect
      site_name = site_name.gsub("'","")
      site_name = site_name.gsub(".","")
      
      
      
      if ((gcp_zip_flag == true) || (file_type == "PAC" || file_type == "TPL"))
        
        # GCP PAC file import
        #file_name = params[:upload_siteconfig_zip].original_filename
        #file_name = file_name.gsub(".TPL", ".PAC").gsub(".tpl", ".PAC") if file_name.end_with?(".TPL", ".tpl")
        file_name = site_name + ".PAC"
        xml_file_name = file_name.gsub(".PAC", ".XML").gsub(".pac", ".XML")
        if !site_name.blank?
          destination = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/#{site_name}"
          Dir.mkdir(destination) unless File.exists? destination
          session[:cfgsitelocation] = destination
          session[:typeOfSystem] = "GCP"
          path = File.join(destination, file_name)
          if(gcp_zip_flag == true) && !zip_path_val.blank?
            FileUtils.cp(zip_path_val, path)
          else
            content = params[:upload_siteconfig_zip].read
            File.open(path, "wb") { |f| f.write(content) }
          end
          
          template_files = "#{RAILS_ROOT}/oce_configuration/mcf/gcp/"
          fixfile_path = "#{RAILS_ROOT}/config/FIXPARAMS.XML"
          simulator = "\"#{session[:OCE_ROOT]}\\GCP_OCE_Manager.exe\", \"#{2}\" \"#{converttowindowspath(destination)}\" \"#{session[:OCE_ROOT]}\" \"#{path}\" \"#{template_files}\" \"#{fixfile_path}\" \"#{xml_file_name}\""
          puts  simulator
          if system(simulator)
            gcp_errorfilepath = destination+'/oce_gcp_error.log'
            result,content= read_error_log_file(gcp_errorfilepath)
            if result == true
              render :text => "error"+"|"+"#{destination}" + "|"+"#{content}" and return
            else
              db_rt = SQLite3::Database.new("#{destination}/rt.db")
              mcf_info = db_rt.execute("Select mcf_name , mcfcrc, sin from rt_gwe")
              file_type = type_str if gcp_zip_flag == true
              if (!File.exists?(destination + '/site_details.yml'))
                mcfName = mcf_info[0][0].strip
                mcfcrc = mcf_info[0][1].to_s(16)
                site_details_info = {"Site Type" => "GCP" ,
                  "MCF Name" => mcfName ,
                  "MCFCRC" => mcfcrc.upcase,
                  "Template Flag" => false,
                  "Config Type" => file_type,
                  "Comments" => "" }
                write_site_details(destination , site_details_info)
              else
                config = YAML.load_file(destination + '/site_details.yml')              
                config["Config Type"] = file_type
                config["Template Flag"] = false
                File.open("#{session[:cfgsitelocation]}/site_details.yml", 'w') { |f| YAML.dump(config, f) }
              end
              db_rt.close()
              if (!(File.exists?(session[:cfgsitelocation]+'/nvconfig.sql3')) || (File.size(session[:cfgsitelocation]+'/nvconfig.sql3') == 0))
                initialdb_path = "#{RAILS_ROOT}/db/Initialdb/gcp"
                FileUtils.cp(initialdb_path + "/nvconfig.sql3", session[:cfgsitelocation] + "/nvconfig.sql3")
              end
              sin, dotnumber, milepost, site_name = read_pac_xml_file("#{destination}/#{xml_file_name}")
              puts sin, dotnumber, milepost, site_name
              connectdatabase()
              get_gcp_type
             
              db_nvconfig = SQLite3::Database.new("#{destination}/nvconfig.sql3")
              strparam = db_nvconfig.execute("Update String_Parameters set String = '#{site_name.to_s}', DisplayOrder = 4 Where Group_ID = 1 and ID = 1")
              strparam = db_nvconfig.execute("Update String_Parameters set String = '#{dotnumber.to_s}', DisplayOrder = 4 Where Group_ID = 1 and ID = 2")
              strparam = db_nvconfig.execute("Update String_Parameters set String = '#{milepost.to_s}', DisplayOrder = 4 Where Group_ID = 1 and ID = 3")
              strparam = db_nvconfig.execute("Update String_Parameters set String = '#{mcf_info[0][2].strip.to_s}', DisplayOrder = 4 Where Group_ID = 1 and ID = 4")
              
              if !@gcp_4000_version
                arr_sin = mcf_info[0][2].strip.split('.')
                strparam = db_nvconfig.execute("Update Integer_Parameters set value = #{arr_sin[1].to_i} Where Group_ID = 1 and ID = 1")
                strparam = db_nvconfig.execute("Update Integer_Parameters set value = #{arr_sin[2].to_i} Where Group_ID = 1 and ID = 2")
                strparam = db_nvconfig.execute("Update Integer_Parameters set value = #{arr_sin[3].to_i} Where Group_ID = 1 and ID = 3")
                strparam = db_nvconfig.execute("Update Integer_Parameters set value = #{arr_sin[4].to_i} Where Group_ID = 1 and ID = 5")              
              end
              db_nvconfig.close()
              mess = generate_gcp_configuration_files(false)
            end
          else
            render :text=>"error"+"|"+"#{destination}" and return
            puts "----------------------------- De-Compile PAC failed ------------------"
          end
          render :text => "success"+"|"+"#{destination}" and return
        end
      else
      # Other Site import
        if site_name.length > 20
          site_name = site_name.slice(0, 20) # allow only max 20 char to create site 
        end

        if !site_name.blank?
          destination = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/#{site_name}"
          session[:cfgsitelocation] = destination
          directory = "#{RAILS_ROOT}/tmp/"
          path = File.join(directory, file_name)
          path_content = File.join(pacimport_temp_directory, file_name)
          
          if File.exists?(path)
            FileUtils.rm(path)
          end
          
          FileUtils.cp(path_content, path)
          if File.exists?(path)
            message = unzip(path ,destination , file_name ,true)
          end
        else
          message = "Unable get the site name from configuration zip file."
        end
      end
    rescue Exception =>e
      puts e.inspect
      session[:cfgsitelocation] = ""
      message = e
    end
    render :text => message
  end
 
  ####################################################################
  # Function:      unzip
  # Parameters:    zip, unzip_dir1, filename ,remove_after = false
  # Retrun:        errormessage
  # Renders:       None
  # Description:   Unzip the zip file and create the site configuration
  ####################################################################  
  def unzip(zip, unzip_dir1, filename ,remove_after = false) 
    begin
      site_type = ""
      errormessage = nil
      override_flag = false
      if File.exists?(unzip_dir1)
        override_flag = true
      end
      unzip_dir = "#{RAILS_ROOT}/tmp/importfiles"
      FileUtils.rm_rf(unzip_dir)
      if File.directory?(unzip_dir)
        FileUtils.rmdir unzip_dir
      end
      Zip::ZipFile.open(zip) do |zip_file|
        zip_file.each do |f|
          f_path = File.join(unzip_dir+'/', f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) unless File.exist?(f_path)
        end
      end
      Dir.glob(unzip_dir+"/**/*.*").each do |file|
          if File.file?(file)
            if(File.basename(file) == "site_details.yml" )
              site_details = open_site_details(file)
              site_type = site_details["Site Type"].strip.to_s
            end
          end
      end
      mcf_flag = false
      nvconfigdb_flag =  false
      masterdb_flag = false
      import_mcfname = nil
      masterdb_txtfile_valid = false 
      if override_flag == true # override the site with existing file
        Dir.glob(unzip_dir+"/**/*.*").each do |file|
          if File.file?(file)
            to_file_name = File.basename(file)
            if File.fnmatch('NV-*.bin', File.basename(file))
                to_file_name = 'nvconfig.bin'
            elsif File.fnmatch('V-*.bin', File.basename(file))
                to_file_name = 'cic.bin'
            end
            FileUtils.cp(file , "#{unzip_dir1}/#{to_file_name}")
          end
        end
        if File.exists?(unzip_dir1)
          Dir[unzip_dir1+'/*.*'] .each do |file|
            if ((File.file?(file)) && (File.extname(file).downcase == ".mcf"))
              import_mcfname = File.basename(file)
              mcf_flag = true
            elsif((File.file?(file)) && ((File.basename(file).downcase == "nvconfig.sql3") || (File.basename(file).downcase == "nvconfig.bin")))   
              nvconfigdb_flag =  true
            elsif((File.file?(file)) && ((File.basename(file).downcase == "site_details.yml") || (File.basename(file).downcase == "masterdb_location.txt")) )
              masterdb_flag =  true
              returnvalue = validate_masterdb_location_file(file)
              unless returnvalue.blank?
                masterdb_txtfile_valid = false
                errormessage = returnvalue
              else
                masterdb_txtfile_valid = true
              end
            end
          end
        end
        if ((mcf_flag == true) &&(nvconfigdb_flag ==  true) && (masterdb_flag ==  true)) 
          if (masterdb_txtfile_valid == true)
            errormessage = nil
          end
        else
          nvconfig_file_name = (site_type != 'VIU')? "nvconfig.sql3" : "nvconfig.bin"
          errormessage = "Import pack file should contain basic configuration(#{nvconfig_file_name} ,*.mcf,site_details.yml) files"
        end
      elsif override_flag == false # import as new site
        if File.exists?(unzip_dir)
          Dir.glob(unzip_dir+"/**/*.*").each do |file|
            if ((File.file?(file)) && (File.extname(file).downcase == ".mcf"))
              import_mcfname = File.basename(file)
              mcf_flag = true
            elsif((File.file?(file)) && ((File.basename(file).downcase == "nvconfig.sql3") || (File.basename(file).downcase == "nvconfig.bin")))   
              nvconfigdb_flag =  true
            elsif((File.file?(file)) && ((File.basename(file).downcase == "site_details.yml") || (File.basename(file).downcase == "masterdb_location.txt")))
              masterdb_flag =  true
              returnvalue = validate_masterdb_location_file(file)
              unless returnvalue.blank?
                masterdb_txtfile_valid = false
                errormessage = returnvalue
              else
                masterdb_txtfile_valid = true
              end
            end
          end
        end
        if ((mcf_flag == true) &&(nvconfigdb_flag ==  true) && (masterdb_flag ==  true)) 
          if (masterdb_txtfile_valid == true)
            Dir.mkdir(unzip_dir1) unless File.exists? unzip_dir1
            Dir.glob(unzip_dir+"/**/*.*").each do |file|
              if File.file?(file)
                to_file_name = File.basename(file)
                if File.fnmatch('NV-*.bin', File.basename(file))
                   to_file_name = 'nvconfig.bin'
                elsif File.fnmatch('V-*.bin', File.basename(file))
                  to_file_name = 'cic.bin'
                end
                FileUtils.cp(file , "#{unzip_dir1}/#{to_file_name}")
              end
            end
          end
        else
           nvconfig_file_name = (site_type != 'VIU')? "nvconfig.sql3" : "nvconfig.bin"
           errormessage = "Import pack file should contain basic configuration(#{nvconfig_file_name},*.mcf,site_details.yml) files"
           session[:cfgsitelocation] = ""
        end
      end
      site_root_path = unzip_dir1
      if errormessage.blank?
        if ((File.exists?(site_root_path+'/rt.db')) && (File.exists?(site_root_path+'/mcf.db')))
          if File.exists?(site_root_path+'/cic.bin')
            # check phy layout & update with rt.db only
            if File.exists?(site_root_path+'/rt.db')
             (ActiveRecord::Base.configurations["real_time_db"])["database"] = site_root_path+'/rt.db'
            end
            gwe = Gwe.find(:all ,:select =>"active_physical_layout").map(&:active_physical_layout)
            rt_phy_layout = gwe[0].to_i # get values from rt.db
            libcic_phy = WIN32OLE.new('CIC_BIN.CICBIN')
            phy_layout = libcic_phy.GetPhysicalLayoutFromCic(converttowindowspath(site_root_path+'/cic.bin'))
            val_lay = phy_layout.to_i.to_s
            if (val_lay.to_i >=1)
              cicbin_phy_layout = val_lay # get the value frim CIC.Bin
            else
              errormessage = "Failed: Get physical values from CIC.bin"
            end
            if errormessage.blank?
              if (rt_phy_layout.to_i == cicbin_phy_layout.to_i)
                #update CIC.bin file values with RT.db
                libcic = WIN32OLE.new('CIC_BIN.CICBIN')
                libcic.Site_Type = site_type
                strmsg1 = libcic.UpdateCicBinToRt(converttowindowspath(site_root_path))
                unless strmsg1.blank?
                  errormessage = strmsg1
                else
                  errormessage = "success"+"|"+"#{unzip_dir1}"
                end
              else
                # create rt.db using cicbin_phy_layout
                update_flag = update_rt_phy_layout(import_mcfname , site_root_path , cicbin_phy_layout)
                if (update_flag == true || update_flag.to_s =="true")
                  # update the CIC.bin file values with RT.db
                  libcic = WIN32OLE.new('CIC_BIN.CICBIN')
                  libcic.Site_Type = site_type
                  strmsg2 = libcic.UpdateCicBinToRt(converttowindowspath(site_root_path))
                  unless strmsg2.blank?
                    errormessage = strmsg2
                  else
                    errormessage = "success"+"|"+"#{unzip_dir1}"
                  end
                else
                  errormessage = "Failed: Update physical layout changes"
                end
              end
            end
          else
            errormessage = "success"+"|"+"#{unzip_dir1}"
          end
        else
          # Create the RT.db and mcf.db file(write the function to create)
          if ((File.exists?(site_root_path+'/rt.db')) && (File.exists?(site_root_path+'/mcf.db')))
            errormessage = nil
          else
            errormessage =  create_RT_and_MCF_database(site_root_path ,import_mcfname , filename)
          end
          if errormessage.blank?
            if File.exists?(site_root_path+'/cic.bin')
              # check phy layout & update with rt.db only
              if File.exists?(site_root_path+'/rt.db')
               (ActiveRecord::Base.configurations["real_time_db"])["database"] = site_root_path+'/rt.db'
              end
              gwe = Gwe.find(:all ,:select =>"active_physical_layout").map(&:active_physical_layout)
              rt_phy_layout = gwe[0].to_i # get values from rt.db
              libcic_phy = WIN32OLE.new('CIC_BIN.CICBIN')
              phy_layout = libcic_phy.GetPhysicalLayoutFromCic(converttowindowspath(site_root_path+'/cic.bin'))
              val_lay = phy_layout.to_i.to_s
              if (val_lay.to_i >= 1)
                cicbin_phy_layout = val_lay # get the value frim CIC.Bin
              else
                errormessage = "Failed: Get physical values from CIC.bin"
              end
              if errormessage.blank?
                if (rt_phy_layout.to_i == cicbin_phy_layout.to_i)
                  #update CIC.bin file values with RT.db
                  libcic = WIN32OLE.new('CIC_BIN.CICBIN')
                  libcic.Site_Type = site_type
                  strmsg1 = libcic.UpdateCicBinToRt(converttowindowspath(site_root_path))
                  unless strmsg1.blank?
                    errormessage = strmsg1
                  else
                    errormessage = "success"+"|"+"#{unzip_dir1}"
                  end
                else
                  # create rt.db using cicbin_phy_layout
                  update_flag = update_rt_phy_layout(import_mcfname , site_root_path , cicbin_phy_layout)
                  if (update_flag == true || update_flag.to_s =="true")
                    # update the CIC.bin file values with RT.db
                    libcic = WIN32OLE.new('CIC_BIN.CICBIN')
                    libcic.Site_Type = site_type
                    strmsg2 = libcic.UpdateCicBinToRt(converttowindowspath(site_root_path))
                    unless strmsg2.blank?
                      errormessage = strmsg2
                    else
                      errormessage = "success"+"|"+"#{unzip_dir1}"
                    end
                  else
                    errormessage = "Failed: Update physical layout changes"
                  end
                end
              end
            else
              errormessage = "success"+"|"+"#{unzip_dir1}"
            end
          end
        end
      end
      FileUtils.rm(zip) if remove_after
    rescue Exception=>e
      FileUtils.rm(zip) if remove_after
      puts e.inspect
      errormessage = e
    end
    return errormessage
  end
  
  def check_import_zip_content
    pacimport_temp_directory = "#{RAILS_ROOT}/tmp/paccontent"
    Dir.mkdir(pacimport_temp_directory) unless File.exists? pacimport_temp_directory
    
    # Remove the all the files from the 'paccontent' temp directory and sub folders
    Pathname.new(pacimport_temp_directory).children.each { |p| p.rmtree }
    file_name = params[:upload_siteconfig_zip].original_filename
    content = params[:upload_siteconfig_zip].read
    path = File.join(pacimport_temp_directory, file_name)
    File.open(path, "wb") { |f| f.write(content) }
    tpl_pac_available_flag = false;
    str_val = ""
    Zip::ZipFile.open(path) do |zip_file|
      zip_file.each do |f|
        split_values = f.name.split(".")
        val_flag = split_values[split_values.length-1].downcase
        if (tpl_pac_available_flag == false) && (val_flag == "tpl" || val_flag == "pac" )
          tpl_pac_available_flag = true
          str_val = val_flag
        end
      end
    end
    if str_val.blank?
      str_val = "NotValidGCP|"
    else
      str_val = "ValidGCP|"+str_val
    end 
    render :text => "#{str_val}"
  end

  ####################################################################
  # Function:      update_rt_phy_layout
  # Parameters:    mcfname , site_path, new_phy_layout
  # Retrun:        simulator
  # Renders:       system(simulator)
  # Description:   RT Physical layout update from CIC.bin 
  ####################################################################  
  def update_rt_phy_layout(mcfname , site_path, new_phy_layout)
    conf = open_site_details("#{site_path}/site_details.yml")
    typeofsystem = conf["Site Type"].strip.to_s
    if typeofsystem == "iVIU" ||  typeofsystem == "iVIU PTC GEO"
      if (site_path+'/site_ptc_db.db')
       (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = site_path+'/site_ptc_db.db'
        mcf_installations = Installationtemplate.all.map(&:InstallationName)
        installation_name_default = mcf_installations[new_phy_layout.to_i-1]
        instalationname = installation_name_default.to_s    
        geoptc_db = site_path+'/site_ptc_db.db'
        geoptc_path = converttowindowspath(geoptc_db)
      else
        instalationname = ""
        geoptc_path = ""
      end
    else
      instalationname = ""
      geoptc_path = ""
    end
    mcfpath = site_path +'/'+mcfname
    out_dir =  RAILS_ROOT+"/oce_configuration/"+session[:user_id].to_s+'/DT2'
    aspectlookuptxtfilepath = session[:aspectfilepath]
    nv_template_flag = "false"
    simulator = "\"#{session[:OCE_ROOT]}\\UIConnector.exe\", \"#{converttowindowspath(mcfpath)}\" \"#{converttowindowspath(out_dir)}\" \"#{geoptc_path}\" \"#{instalationname}\" \"#{typeofsystem}\" \"#{new_phy_layout}\" \"#{2}\" \"#{converttowindowspath(aspectlookuptxtfilepath)}\" \"#{nv_template_flag}\""
    return system(simulator)
  end

  ####################################################################
  # Function:      create_RT_and_MCF_database
  # Parameters:    rootpath, mcfname , filename
  # Retrun:        return_message
  # Renders:       None
  # Description:   create Rt.db and Mcf.db if not available for import site configuration 
  ####################################################################
  def create_RT_and_MCF_database(rootpath, mcfname , filename)
    return_message = nil
    site_name = filename.split('.')
    sitelocation =  rootpath 
    if File.exists?(sitelocation+'/nvconfig.sql3')
     (ActiveRecord::Base.configurations["development"])["database"] = sitelocation+'/nvconfig.sql3'
    end
    StringParameter.stringparam_update_query(site_name[0].to_s, 1)
    selectedmcfname = rootpath+'/'+ mcfname
    calculatedmcfcrc = nil
    #Read the type of system from text file
    typeofsystem = nil
    selectedinsname = nil
    if File.exist?("#{sitelocation}/site_details.yml")
      conf = open_site_details("#{sitelocation}/site_details.yml")
      typeofsystem = conf["Site Type"].strip.to_s
      if typeofsystem == "iVIU PTC GEO"
        master_db_name = conf["Master Database"].strip.to_s
        installation_name = conf["Master Database"].strip.to_s
        unless master_db_name.blank?
          selectedinsname = installation_name
        end
      else
        selectedinsname  = ""
      end
    end
    @typeOfSystem = typeofsystem
    libcic = WIN32OLE.new('CIC_BIN.CICBIN')                
    calculatedmcfcrc = libcic.GetMcfCrc(converttowindowspath(selectedmcfname), @typeOfSystem.upcase.to_s)
    hexaCRC = calculatedmcfcrc.split('x')
    if hexaCRC.length > 1
      strhexaCRC = hexaCRC[1].to_s  
    else
      strhexaCRC = hexaCRC[0].to_s
    end
    site_details = open_site_details("#{sitelocation}/site_details.yml")
    site_details["MCF Name"] = mcfname
    site_details["MCFCRC"] = strhexaCRC
    if @typeOfSystem == "iVIU" || @typeOfSystem == "iVIU PTC GEO"
      decimalCRC = strhexaCRC.hex
      IntegerParameter.integerparam_update_query(decimalCRC, 516)
      StringParameter.stringparam_update_query(mcfname, 116)
    end
    File.open("#{sitelocation}/site_details.yml", 'w') { |f| YAML.dump(site_details , f) }
    mcfpath = selectedmcfname
    out_dir =  RAILS_ROOT+"/oce_configuration/"+session[:user_id].to_s+'/DT2'
    if typeofsystem == "iVIU PTC GEO" # read type from text file
      geoptc_db = rootpath+'/site_ptc_db.db'
    else
      geoptc_db = ""
    end
    instalationname = selectedinsname # read text file
    aspectlookuptxtfilepath = session[:aspectfilepath] 
    begin
      nv_template_flag = "false"
      simulator = "\"#{session[:OCE_ROOT]}\\UIConnector.exe\", \"#{converttowindowspath(mcfpath)}\" \"#{converttowindowspath(out_dir)}\" \"#{converttowindowspath(geoptc_db)}\" \"#{instalationname}\" \"#{typeofsystem}\" \"#{1}\" \"#{0}\" \"#{converttowindowspath(aspectlookuptxtfilepath)}\" \"#{nv_template_flag}\" "
      puts  simulator
      if system(simulator) 
        errorfilepath = out_dir+'/UIConnector_Error.log'
        if File.exist?(errorfilepath)
          file = File.open(errorfilepath, "r")
          content = file.read
          unless content.blank?
            return_message = content
          else 
            return_message = "success"
          end
        end
      else
        return_message = "mcf.db and rt.db creation process failed."
      end
    rescue Exception => e
      return e
    end
    if File.exists?(sitelocation+'/mcf.db')
     (ActiveRecord::Base.configurations["mcf_db"])["database"] = sitelocation+'/mcf.db'  
    end
    if File.exists?(sitelocation+'/rt.db')
     (ActiveRecord::Base.configurations["real_time_db"])["database"] = sitelocation+'/rt.db'
    end
    if typeofsystem == "VIU"
      # update sitename and MCFCRC with nvconfig.bin , sin value with RT.db 
      decimalCRC = strhexaCRC.hex
      update_viu_siteinfo(site_name[0] , decimalCRC)
    end
    if ((typeofsystem == 'iVIU') || (typeofsystem == 'VIU'))
      if File.exist?(sitelocation+'/site_ptc_db.db')
        intialdb_path = RAILS_ROOT+'/db/InitialDB/iviu/GEOPTC.db'
        siteptc_path = sitelocation+'/site_ptc_db.db'
        upgradesiteptclib  = WIN32OLE.new('MCFPTCDataExtractor.MCFExtractor')                
        siteptc_upgrade_msg = upgradesiteptclib.ValidateDbSchema(converttowindowspath(intialdb_path),converttowindowspath(siteptc_path))
         (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = siteptc_path 
      end
    end
    #         Validate the MCF and RT Database and set the flag
    validatemcfrtdatabase(sitelocation)
    
    if session[:validmcfrtdb] == false
      return_message = "MCF and RT database process failed"
    end
    return return_message
  end
  
  ####################################################################
  # Function:      close_site_configuration
  # Parameters:    session[:pid]
  # Retrun:        None
  # Renders:       None
  # Description:   Close the already open site configurations like database connection , clear the session values
  ####################################################################  
  def close_site_configuration
    session[:error] = ""
    session[:save] = ""
    session[:newopenflag]= nil
    unless session[:pid].blank?
      # Close existing cfgmagr.exe file using pid
      close_cfgmgr(session[:pid])
    end
    close_database_connection
    clearAllValue_Sessions
    header_function
  end
  
  ####################################################################
  # Function:      select_mcf_file
  # Parameters:    params[:typeofsystem]
  # Retrun:        @mcf_files
  # Renders:       render :layout
  # Description:   Select the mcf file from the list
  ####################################################################  
  def select_mcf_file
    @typeOfSystem = params[:typeofsystem]
    @nv_version = params[:nv_ver]
    session[:nv_ver] = params[:nv_ver]  
    site_type = @typeOfSystem.downcase
    @mcf_files = nil
    rootpath = nil
    rootpath = mcf_root_path(site_type)
    root_directory = File.join(RAILS_ROOT, "/oce_configuration/mcf/#{rootpath}")
    mcf_root = File.join(RAILS_ROOT, "/oce_configuration/mcf")
    unless File.exists? mcf_root
      Dir.mkdir(mcf_root)
      Dir.mkdir(root_directory) unless File.exists? root_directory
    else
      Dir.mkdir(root_directory) unless File.exists? root_directory
    end
    
    @mcf_files = Dir[root_directory + "/*.mcf"].reject{|f| [".", ".."].include?f }
    if site_type == 'gcp'
      get_gcp_templates
      get_pac_files
      get_mcf_name_and_mcfcrc
    end
    
    render :layout => false
  end

  ####################################################################
  # Function:      get_mcf
  # Parameters:    params[:typeofsystem]
  # Retrun:        filepaths
  # Renders:       render :text
  # Description:   Get all available mcf's in the mcf directory
  ####################################################################    
  def get_mcf
    @typeOfSystem = params[:typeofsystem]
    site_type = @typeOfSystem.downcase
    rootpath = nil
    rootpath = mcf_root_path(site_type)
    root_directory = File.join(RAILS_ROOT, "/oce_configuration/mcf/#{rootpath}")
    Dir.mkdir(root_directory) unless File.exists? root_directory
    file = Dir[root_directory + "/*.mcf"].reject{|f| [".", ".."].include?f }
    filepaths = ""
    file.each do |f|
      filepaths = filepaths+ '|' + f
    end
    render :text =>  filepaths
  end

  ####################################################################
  # Function:      get_mcfcrc
  # Parameters:    params[:mcf_path]
  # Retrun:        mcfcrc 
  # Renders:       render :json 
  # Description:   Get the mcfcrc , Signal logic crc , PTC Logic crc from the mcf log files
  ####################################################################  
  def get_mcfcrc 
    mcfcrc = ""
    mcf_location = ""
    typeofsystem = params[:typeofsystem]
    begin
      unless params[:mcf_path].blank?
        if File.exists?(params[:mcf_path])
          mcfcrc_log_path = params[:mcf_path].chomp(".mcf")
          log_path = mcfcrc_log_path+".log"
          if File.exists?(log_path)
            File.open(log_path).readlines.each do |line|
              chomp_line_val = line.chomp
              if chomp_line_val.include?('MCF CRC')
                mcf_crc_val = chomp_line_val.split('MCF CRC')
                if (mcf_crc_val.length > 1)
                  get_mcf_crc = mcf_crc_val[1].upcase.split('X')
                  mcfcrc = (get_mcf_crc.length >1)? get_mcf_crc[1].strip : get_mcf_crc[0].strip
                end
              end
              if typeofsystem == "GCP"
                File.open(params[:mcf_path]).readlines.each do |mcf_line|
                  puts "mcf_line: " + mcf_line.inspect
                  if(mcf_line.start_with?("Location Name"))
                    if(mcf_line.strip.end_with?("4000"))
                      mcf_location = "4k"
                    else
                      mcf_location = "5k"
                    end
                    break
                  end
                end
              end
            end
          end
        end
      end
    rescue Exception =>e
      mcfcrc = ""
      puts e.inspect
    end
    render :json =>{ :mcfcrc=> mcfcrc, :mcf_location => mcf_location}
  end

  ####################################################################
  # Function:      mcf_root_path
  # Parameters:    typeofsystem
  # Retrun:        rootpath
  # Renders:       None
  # Description:   Return the mcf root path according to the site stype
  ####################################################################  
  def mcf_root_path(typeofsystem)
    rootpath = nil
    case typeofsystem
      when "iviu"   
      rootpath = "iviu"   
      when  "iviu ptc geo"
      rootpath = "iviu"   
      when "viu"
      rootpath = "viu"   
      when "geo"
      rootpath = "geo" 
      when "cpu-iii"
      rootpath = "cpu3"  
      when "gcp"
      rootpath = "gcp" 
    end
    return rootpath
  end
  
  ####################################################################
  # Function:      validate_masterdb_location_file
  # Parameters:    file
  # Retrun:        error
  # Renders:       None
  # Description:   Validate the master database file location
  ####################################################################  
  def validate_masterdb_location_file(file)
    typeofsystem = nil
    masterdb_location = nil
    valid_masterdb_flag = false
    dbname = nil
    error = nil
    if File.exist?(file)  
      if (File.basename(file).downcase == "masterdb_location.txt")
        masterdbandtypearray = IO.readlines(file)
        typeofsystem = masterdbandtypearray[0].strip.to_s
        if typeofsystem.downcase == "iviu ptc geo"
          unless masterdbandtypearray[1].blank?
            arr_masterdb = masterdbandtypearray[1].strip.to_s.split('/')
            if arr_masterdb.length > 1
              dbname = File.basename(masterdbandtypearray[1].strip) # get the filename & assign value if masterdatabase path
            else
              dbname = arr_masterdb[0].strip # assign value direct masterdatabase name 
            end
          end
        end
      else
        conf = open_site_details(file)
        site_type = conf["Site Type"]
        master_datebase_name = conf["Master Database"]
        typeofsystem = site_type.strip.to_s
        dbname = master_datebase_name.strip.to_s if !master_datebase_name.blank?
      end
      if typeofsystem.downcase == "iviu ptc geo"
        masterdb_location = "#{RAILS_ROOT}/Masterdb/#{dbname}"
        if File.exist?(masterdb_location)
          valid_masterdb_flag = true
        end
        if valid_masterdb_flag != true
          error = "GEO PTC master database(#{dbname}) not available, please import master database and try again"
        end
      end
    end
    return error
  end
  
  ####################################################################
  # Function:      change_sim_binaries_temp
  # Parameters:    site_type
  # Retrun:        None
  # Renders:       None
  # Description:   Copy the geo_sim_engine.dll according to the site type
  ####################################################################
  def change_sim_binaries_temp(site_type)
    dir , base = File.split(session[:OCE_ROOT])
    if File.exists?("#{dir}/GEO/geo_sim_engine.dll")
      FileUtils.rm("#{dir}/GEO/geo_sim_engine.dll")
    end
    sleep 1
    sime_dll_copy_location = get_simengine_location(dir , site_type.downcase)
    FileUtils.cp(sime_dll_copy_location , "#{dir}/GEO/geo_sim_engine.dll")
  end
  
  ####################################################################
  # Function:      get_simengine_location
  # Parameters:    dir , site_type
  # Retrun:        None
  # Renders:       None
  # Description:   Return the geo_sim_engine.dll copy path according to the site type
  ####################################################################
  def get_simengine_location(dir , site_type)
    case site_type
      when 'iviu' then return "#{dir}/GEOSimEngineFile/IVIU/geo_sim_engine.dll"
      when 'iviu ptc geo' then return "#{dir}/GEOSimEngineFile/IVIU/geo_sim_engine.dll"
      when 'viu' then return "#{dir}/GEOSimEngineFile/VIU/geo_sim_engine.dll"
      when 'cpu-iii' then return "#{dir}/GEOSimEngineFile/GEO/CPU3/geo_sim_engine.dll"
      else
        return "#{dir}/GEOSimEngineFile/GEO/geo_sim_engine.dll"
    end
  end

  ####################################################################
  # Function:      copy_template
  # Parameters:    params[:typeOfSystem]
  # Retrun:        mess
  # Renders:       render :text
  # Description:   Copy the Non vital configuration file to template repository  
  ####################################################################
  def copy_template
    mess = ""
    upd_message = ""
    viu_nvconfig = ""
    begin
      if !session[:cfgsitelocation].blank?
        base_file = '/nvconfig.sql3'
        if !params[:typeOfSystem].blank?
          template_directory = File.join(RAILS_ROOT, "/oce_configuration/templates")
          Dir.mkdir(template_directory) unless File.exists? template_directory
          dist_directory = "#{template_directory}/#{params[:typeOfSystem].to_s.downcase}"
          Dir.mkdir(dist_directory) unless File.exists? dist_directory
          FileUtils.cp(session[:cfgsitelocation].to_s + base_file, dist_directory + base_file) if params[:typeOfSystem].to_s != "GCP"
          if params[:typeOfSystem] && params[:typeOfSystem].to_s.downcase == "viu"
            viu_nvconfig = '/nvconfig.bin'
            FileUtils.cp(session[:cfgsitelocation].to_s + viu_nvconfig, dist_directory + viu_nvconfig)
          elsif params[:typeOfSystem] && params[:typeOfSystem].to_s.downcase == "gcp"
            cfg_site_location = session[:cfgsitelocation]
            Dir["#{cfg_site_location}/*.PAC" , "#{cfg_site_location}/*.XML" ].each do |pac_file|
              #remove the existing pac and create the PAC
              next if File.fnmatch('WiuConfig-*', File.basename(pac_file))
              File.delete(pac_file) if File.exist?(pac_file)
            end
            
            # Create the PAC file using the rt , mcf , nvconfig
            simulator = "\"#{session[:OCE_ROOT]}\\GCP_OCE_Manager.exe\", \"#{1}\" \"#{cfg_site_location}\" \"#{session[:OCE_ROOT]}\""
            puts  simulator
            if system(simulator)
              puts "------------------------------- Pass Compress ----------------------"            
              created_pac_file_name = ""
              # Get the created PAC file name
              Dir["#{cfg_site_location}/*.PAC"].each do |site_pac_file|
                next if !created_pac_file_name.blank?
                created_pac_file_name = site_pac_file
              end
              
              # Copy the PAC in to template folder
              if File.exist?(created_pac_file_name)
                File.delete("#{dist_directory}/template.PAC") if File.exist?("#{dist_directory}/template.PAC")
                FileUtils.cp(created_pac_file_name, "#{dist_directory}/template.PAC")
              end
            else
              puts "------------------------------- Failed Compress ----------------------"
               upd_message = compress_pac_file_msg
            end
          end
        end
       
        if params[:typeOfSystem] == "CPU-III" || params[:typeOfSystem] == "GEO" || params[:typeOfSystem] == "VIU"
          initialDB_nvconfig_path = "#{RAILS_ROOT}/db/InitialDB/geo/nvconfig.sql3"
        elsif (params[:typeOfSystem] == "GCP")
          initialDB_nvconfig_path = "#{RAILS_ROOT}/db/InitialDB/gcp/nvconfig.sql3"
        else
          initialDB_nvconfig_path = "#{RAILS_ROOT}/db/InitialDB/iviu/nvconfig.sql3"
        end
        
        ##########If the template is old version upgrade to latest and Not GCP site
        if (File.exist?(dist_directory + base_file) &&  (params[:typeOfSystem] != "GCP")) 
          upd_message = update_db({ :db1 => initialDB_nvconfig_path, :db2 => dist_directory + base_file})
          Pathname.new(dist_directory).children.each { |p| p.rmtree } if !upd_message.blank?
        end
        if upd_message.blank?
          mess = "Template set successfully."
        else
          mess = "<span style = 'color:#FF0000'>Error: While copying template file, #{upd_message}.</span>"
        end        
      else
        mess = "Error: Unable to set the temaplate, please open same site and try again."
      end
    rescue Exception => e
      mess = "<span style = 'color:#FF0000'>Error: While copying template file, #{e.to_s}.</span>"
    end
    render :text => mess
  end

  ####################################################################
  # Function:      nvconfig_migration
  # Parameters:    params[:typeOfSystem]
  # Retrun:        upd_message
  # Renders:       render :text 
  # Description:   Migrate the old Non vital configuration to new version 
  ####################################################################
  def nvconfig_migration()
    site_nvconfig_path = session[:cfgsitelocation] + '/nvconfig.sql3'
    if params[:typeOfSystem] == "VIU" || params[:typeOfSystem] == "CPU-III" || params[:typeOfSystem] == "GEO"
      initialDB_nvconfig_path = RAILS_ROOT+'/db/InitialDB/geo/nvconfig.sql3'
    elsif (params[:typeOfSystem] == "GCP")
      initialDB_nvconfig_path = RAILS_ROOT+'/db/InitialDB/gcp/nvconfig.sql3'
    else
      initialDB_nvconfig_path = RAILS_ROOT+'/db/InitialDB/iviu/nvconfig.sql3'
    end
        
    if File.exist?(site_nvconfig_path)     
      upd_message = update_db({ :db1 => initialDB_nvconfig_path, :db2 => site_nvconfig_path})
    end
    if upd_message.blank?
      render :text => "Non vital configuration migrated successfully."
    else
      render :text => "<span style = 'color:#FF0000'>#{upd_message.to_s}.</span>"
    end
  end

  ####################################################################
  # Function:      import_template_pac_files
  # Parameters:    params
  # Retrun:        None 
  # Renders:       None 
  # Description:   import the template/PAC file with site configuration  
  ####################################################################    
   def import_template_pac_files
     log_path = ""
     begin
      createfile = session[:cfgsitelocation]
      uploaded_pac_path = ""
      if params[:new_site_type] == "create_new_site"
        selected_site_pac = params[:selected_template].downcase
        uploaded_pac_path = params[:uploaded_template_path].downcase if !params[:uploaded_template_path].blank?
      else
        if(params[:selected_pac].end_with?("*"))
          browsed_pac = params[:selected_pac].split('*')
          params[:selected_pac] = browsed_pac[0].to_s
        end
         selected_site_pac = params[:selected_pac].downcase
        uploaded_pac_path = params[:uploaded_pac_path].downcase if !params[:uploaded_pac_path].blank?
      end
      if selected_site_pac != "not used"
        # Remove the Existing site location .bak files
        Dir.foreach(createfile) do | site_file |
          if ((File.extname(site_file)=='.bak') || (File.extname(site_file)=='.BAK'))
            File.delete("#{createfile}/#{site_file}")
          end
        end
  
        #PAC file upload temp directory and create the temp directory if not available
        pacimport_directory = "#{RAILS_ROOT}/tmp/pacimport"
        pac1_directory = "#{RAILS_ROOT}/tmp/pacimport/pac1"
        Dir.mkdir(pacimport_directory) unless File.exists? pacimport_directory
        Dir.mkdir(pac1_directory) unless File.exists? pac1_directory
  
        # Remove the all the files from the PAC1 temp directory and sub folders
        Pathname.new(pac1_directory).children.each { |p| p.rmtree }
  
        # Write the GCP PAC import in the site folder
        pacfilename_path = ""
        file_type = ""
        # Write the uploaded PAC file in the site folder if user browse the file other than the PAC Repo
        if (selected_site_pac == uploaded_pac_path)
          if  !params[:uploadTemplateFile].blank? || !params[:uploadPacFile].blank? 
            # PAC file name
            if params[:new_site_type] == "create_new_site"
              file_name = params[:uploadTemplateFile].original_filename
              content = params[:uploadTemplateFile].read
            else
              file_name = params[:uploadPacFile].original_filename
              content = params[:uploadPacFile].read
            end
            #file_name = file_name.gsub(".TPL", ".PAC").gsub(".tpl", ".PAC") if file_name.end_with?(".TPL", ".tpl")
            file_type = file_name[-3,3].upcase
            file_name = file_name[0..-5]
            file_name = file_name.gsub("'","").gsub(".","") + ".PAC"            
            xml_file_name = file_name.gsub(".PAC", ".XML").gsub(".pac", ".XML")
            pacfilename_path = File.join(pac1_directory, file_name)
            File.open(pacfilename_path, "wb") { |f| f.write(content) }
          end
        else
        # copy the PAC file from the PAC Repo if user selecetd from repo
          if !selected_site_pac.blank?
            if params[:new_site_type] == "create_new_site"
              pacname_load = params[:selected_template].split('/')
              pacname_selected = pacname_load[pacname_load.length-1]
              tpl_name_selected = "#{params[:selected_template]}/#{pacname_selected}.TPL"
              file_type = "TPL"
              FileUtils.cp(tpl_name_selected , pac1_directory)
              pacfilename_path = "#{pac1_directory}/#{pacname_selected.gsub("'","").gsub(".","")}.PAC"
              File.rename("#{pac1_directory}/#{pacname_selected}.TPL", pacfilename_path)
              pac_name = File.basename(pacfilename_path)
              xml_file_name = pac_name.gsub(".PAC", ".XML").gsub(".pac", ".XML")
            else
              pacname_load = params[:selected_pac].split('/')
              pacname_selected = pacname_load[pacname_load.length-1]
              file_type = pacname_selected[-3,3].upcase
              pacname_selected = pacname_selected[0..-5].gsub("'","").gsub(".","") + ".PAC"
              pacfilename_path = "#{pac1_directory}/#{pacname_selected}"
              xml_file_name = pacname_selected.gsub(".PAC", ".XML").gsub(".pac", ".XML")
              FileUtils.cp(params[:selected_pac], pacfilename_path)
            end
          end
        end

        # take the backup of the rt, mcf , nvconfig database as .bak and revert the file if got any issue while upgrade(remove the .bak file success upgrade)
        Dir["#{createfile}/mcf.db" , "#{createfile}/rt.db" , "#{createfile}/nvconfig.sql3"].each do  |file|
          FileUtils.cp file, "#{file}.bak"
        end
  
        # Using C#.net exe create the rt , mcf , nvconfig database from the GCP importted pac file
        template_files = "#{RAILS_ROOT}/oce_configuration/mcf/gcp/"
        fixfile_path = "#{RAILS_ROOT}/config/FIXPARAMS.XML"
        simulator = "\"#{session[:OCE_ROOT]}\\GCP_OCE_Manager.exe\", \"#{2}\" \"#{pac1_directory}\" \"#{session[:OCE_ROOT]}\" \"#{pacfilename_path}\" \"#{template_files}\" \"#{fixfile_path}\" \"\""
        puts  simulator
        import_pac_path = "#{pac1_directory}/site_details.yml"
        if system(simulator)
          puts "---------------------- Pass decompile -------------"
          error_log = "#{pac1_directory}+\'oce_gcp_error.log'"
          result,content = read_error_log_file(error_log)
          if(result == true && !content.blank?)
           raise Exception, content
          end
          #FileUtils.cp import_pac_path, "#{createfile}/site_details.yml"
          if File.exists?(import_pac_path)
            site_details = open_site_details(import_pac_path)
            comments = site_details["Comments"].to_s
            config = YAML.load_file("#{session[:cfgsitelocation]}/site_details.yml")
            config["Comments"] = comments
            File.open("#{session[:cfgsitelocation]}/site_details.yml", 'w') { |f| YAML.dump(config, f) }
          end
          sin, dotnumber, milepost, site_name = read_pac_xml_file("#{pac1_directory}/#{xml_file_name}")
          puts sin, dotnumber, milepost, site_name
          old_site_name = StringParameter.get_string_value(1 , "Site Name")
          old_dotnumber = StringParameter.get_string_value(1 , "DOT Number")
          old_milepost = StringParameter.get_string_value(1 , "Mile Post")
          old_sin = StringParameter.get_string_value(1 , "ATCS Address")

          update_rt_sin_values(4, sin)
          if (!(File.exists?(pac1_directory +'/nvconfig.sql3')) || (File.size(pac1_directory +'/nvconfig.sql3') == 0))
            StringParameter.stringparam_update_query(site_name.to_s, 1)
            StringParameter.stringparam_update_query(dotnumber.to_s, 2)
            StringParameter.stringparam_update_query(milepost.to_s, 3)
          end
        else
          puts "---------------------- Failed decompile -------------"
        end

        # Compare the Already exist site  rt , mcf , nvconfig database and importted GCP PAC file databases
        # Update the database1(Primary) database values with database2(Secondary) database values
        #   - Update the Rt_parameters table values(update current value(db1 - rt) if the record available(if available record and mismatch the rt current value with db2 rt.db) , update default value to current value(db 1 - rt) if record not available in the db2(rt) )
        #   - Update the nvconfig database values(all table values except CDL and wizard)
        # Create the Report of update values
        #   -format(CardIndex ParameterName CurrentValue(old) UpdatedCurrentvalue(PAC) ) - rt parameters
        #   -format(ID ParameterName CurrentValue(old) UpdatedCurrentvalue(PAC) ) - nvconfig.sql3 database
        ### Location information ###
        @location_params = []
                
        if (old_site_name != site_name)
          @location_params << {:context_string => "" , :parameter_name => "Site Name", :value => site_name , :unit => "", :old_param_name => ""} 
        end
        if (old_dotnumber != dotnumber)
          @location_params << {:context_string => "" , :parameter_name => "DOT Number", :value => dotnumber , :unit => "", :old_param_name => ""}
        end
        if (old_milepost != milepost)
          @location_params << {:context_string => "" , :parameter_name => "Mile Post", :value => milepost , :unit => "", :old_param_name => ""}
        end
        if (old_sin != sin)
          @location_params << {:context_string => "" , :parameter_name => "ATCS Address", :value => sin , :unit => "", :old_param_name => ""}
        end
        databases1_loc =  createfile
        databases2_loc =  pac1_directory
        update_mtf_index(createfile, pac1_directory)
        import_file_name = File.basename(pacfilename_path)
        if file_type == "TPL"
          import_pac_name = import_file_name[0..-5]+".TPL"
        elsif file_type == "PAC"
          import_pac_name = import_file_name[0..-5]+".PAC"
        end
        log_path = "#{databases1_loc}/#{session[:sitename]}_PAC_Import_Report.html"
        compare_result = compare_and_update_databse_using_importpac(databases1_loc , databases2_loc , import_pac_name , log_path)
        if (!compare_result.blank?)
          raise Exception, compare_result
        end

        # sussceess display success message and failure display failure message in the site page/import page message dialog(alert)
        Dir.foreach(createfile) do | site_file |
          if ((File.extname(site_file)=='.bak') || (File.extname(site_file)=='.BAK'))
            File.delete("#{createfile}/#{site_file}" )
          end
        end
      end
     rescue Exception => e
       puts e.inspect
       Dir.foreach(createfile) do | site_file |
         if ((File.extname(site_file)=='.bak') || (File.extname(site_file)=='.BAK'))
           File.delete("#{createfile}/#{site_file}" )
         end
       end
       return e.message.to_s
     end
    return "" 
  end
  
  ####################################################################
  # Function:      nvconfig_migration
  # Parameters:    session[:user_id]
  # Retrun:        upd_message
  # Renders:       render :text 
  # Description:   Migrate the old Non vital configuration to new version 
  ####################################################################  
  def get_pac
    root_directory = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/pac"
    Dir.mkdir(root_directory) unless File.exists? root_directory
    file = Dir["#{root_directory}/*.*"].reject{|f| [".", ".."].include?f }
    filepaths = ""
    file.each do |f|
      filepaths = filepaths+ '|' + f
    end
    render :text =>  filepaths
  end
  
	####################################################################
  # Function:      findAMorNonAM_mcf
  # Parameters:    mcfpath
  # Retrun:        Boolean
  # Renders:       None 
  # Description:   Read the "Configuration Element Type" from the MCF and return the valid/invalid mcf flag
  ####################################################################
  def findAMorNonAM_mcf(mcfpath)
    mcfdata = IO.readlines(mcfpath)
    for i in 0..5
      # Check the Configuration Element Type - AM MCF if AC01(It's valid MCF - other than this MCF we should not allow NON-AM MCF - Bug#9803)  
      if ((mcfdata[i].include?("Configuration Element Type")) && (mcfdata[i].include?("AC01")))
          return true
      end
    end
    return false      
  end

  ####################################################################
  # Function:      create_gcp_template
  # Parameters:    session[:cfgsitelocation]
  # Retrun:        @templatename
  # Renders:       render :layout 
  # Description:   Open the create gcp template page with default name
  ####################################################################
  def create_gcp_template
    unless session[:cfgsitelocation].blank?
      @sitelocation = session[:cfgsitelocation]
      time = Time.new
      @templatename = "Config-#{time.strftime("%Y%b%d")}"
    else
      @sitelocation = nil
    end
    render :layout => false
  end

  ####################################################################
  # Function:      create_template_file
  # Parameters:    params
  # Retrun:        msg
  # Renders:       render :json 
  # Description:   Create the gcp template and place it in the gcp template repo 
  ####################################################################
  def create_template_file
    begin
      template_directory = File.join(RAILS_ROOT, "/oce_configuration/templates")
      Dir.mkdir(template_directory) unless File.exists? template_directory
      dist_directory = "#{template_directory}/gcp"
      Dir.mkdir(dist_directory) unless File.exists? dist_directory
      template_name = params[:templatename]
      template_directory = "#{dist_directory}/#{template_name}"
      site_location_path = params[:site_location]
      template_enable = params[:template_check]
      if template_enable == true || template_enable == 'true'
        config_type = "TPL"
      elsif template_enable == false || template_enable == 'false'
        config_type = "PAC"
      end
      if File.exists?(template_directory) && !(Dir.entries(template_directory) == [".", ".."])
         render :json => {:message => "Template already exists\r\nplease enter different tamplate name and try again."} and return
      else
         Dir.mkdir(template_directory) unless File.exists?(template_directory)
      end       
      
      # Create the PAC file using the rt , mcf , nvconfig
      mess = generate_gcp_configuration_files
      
      # Copy the mcf.db , rt.db , nvconfig.sql3 and .TPL/.PAC
      if mess.blank?
        msg = copy_gcp_template_files(site_location_path , template_directory , template_name) # Source to destination
        config = YAML.load_file("#{site_location_path}/site_details.yml")
        config["Config Type"]=config_type
        File.open("#{site_location_path}/site_details.yml", 'w') { |f| YAML.dump(config, f) }
        puts 'msg',msg.inspect
        if !msg.blank?
          render :json => {:message => msg} and return
        end
      else
        render :json => {:message => "Template creation failed, " + mess} and return
      end
    rescue Exception => e
        render :json => {:message => e} and return      
    end
    render :json => {:message =>""}
  end

  ####################################################################
  # Function:      update_comments
  # Parameters:    None
  # Retrun:        None
  # Renders:       None
  # Description:   Update comments section value
  ####################################################################  
  def update_comments
    @typeOfSystem = params[:typeofsystem]
    if @typeOfSystem == "GCP"
      site_details_path = "#{session[:cfgsitelocation]}/site_details.yml"
      if File.exists?(site_details_path)
        config = YAML.load_file("#{session[:cfgsitelocation]}/site_details.yml")
        config["Comments"] = params[:comments]
        File.open("#{session[:cfgsitelocation]}/site_details.yml", 'w') { |f| YAML.dump(config, f) }
      end
    end
    render :text => ""
  end

  ####################################################################
  # Function:      download_pac_import_report
  # Parameters:    None
  # Retrun:        None
  # Renders:       None
  # Description:   Download the PAC import report
  ####################################################################  
  def download_pac_import_report
    configreportfile = nil
    Dir.foreach(session[:cfgsitelocation]) do |x| 
      if File.fnmatch('*Import_Report*.html', File.basename(x))
        configreportfile = x
      end
    end
    log_path =""
    unless configreportfile.blank?
      log_path = File.join(session[:cfgsitelocation] , configreportfile)
    end
   send_file(log_path, :filename => configreportfile ,:dispostion=>'inline',:status=>'200 OK',:stream=>'true' )
 end

  ####################################################################
  # Function:      download_pac_import_report
  # Parameters:    None
  # Retrun:        None
  # Renders:       None
  # Description:   Download the PAC import report
  ####################################################################  
  def get_product_type(path_folder)
   site_details_path = "#{path_folder}/site_details.yml"
   if File.exists?(site_details_path)
    site_details = open_site_details(site_details_path)
    site_type = site_details["Site Type"]
    if !site_type.blank?
      site_type_name = site_type.strip.to_s
      return site_type_name.upcase
    else
      return ""
    end
   else
    return ""
   end
 end
 
 ####################################################################
 # Function:      get_template_list
 # Parameters:    None
 # Retrun:        None
 # Renders:       None
 # Description:   Get the template list from the templates repo
 ####################################################################  
 def get_template_list
   get_gcp_templates
   template = ""
   @templates.each do |temp|
     path_and_name = "#{temp}|#{File.basename(temp)}" 
     template = template+"#{path_and_name}||"
   end
   render :text =>template.to_s
 end

 ####################################################################
 # Function:      get_pac_file_list
 # Parameters:    None
 # Retrun:        None
 # Renders:       None
 # Description:   Get the PAC list from the PAC repo
 ####################################################################  
 def get_pac_file_list   
   get_gcp_templates
   pac_files = ""
   @templates.each do |temp|
     path_and_name = "#{temp}/#{File.basename(temp)}.TPL|#{File.basename(temp)}.TPL" 
     pac_files = pac_files+"#{path_and_name}||"
   end
   
   get_pac_files   
   @pac_files.each do |temp|
     dir_path = File.dirname(temp).split('/')
     dir_name = dir_path[dir_path.length - 1]
     path_and_name = "#{temp}|#{dir_name}/#{File.basename(temp)}" 
     pac_files = pac_files+"#{path_and_name}||"
   end
   render :text =>pac_files.to_s
 end

 ####################################################################
 # Function:      get_template_details
 # Parameters:    params[:template_path]
 # Retrun:        mcf_name , mcf_crc
 # Renders:       render :json 
 # Description:   Read the mcfname and mcfcrc from the templates database
 ####################################################################  
 def get_template_details
   template_path = params[:template_path].strip
   mcf_name = ""
   mcf_crc = ""
   mcf_location = ""
   if template_path[template_path.length-1] != '*'     
     if File.exists?(template_path) && File.exists?("#{template_path}/rt.db")
       db1 = SQLite3::Database.new("#{template_path}/rt.db")
       template_mcfname_mcfcrc = db1.execute("Select mcf_name , mcfcrc, mcf_location from rt_gwe")
       mcf_name =  template_mcfname_mcfcrc[0][0].strip
       mcf_crc =  template_mcfname_mcfcrc[0][1].to_s(16).upcase
       mcf_crc = mcf_crc.to_s.rjust(8,'0') if mcf_crc.length < 8
       mcf_location = template_mcfname_mcfcrc[0][2].strip
     end    
   else
      #this is the file currently in tmp
      directory = "#{RAILS_ROOT}/tmp/tplextract"      
      Dir.mkdir(directory) unless File.exists? directory
      file_name =template_path[0,template_path.length-1]
      tpl_path = File.join(directory, file_name)
      xml_name = file_name.chomp(File.extname(file_name))
      xml_path = "#{directory}/#{xml_name}.XML"
      mcf_name, mcf_crc, mcf_location, error, error_mess = read_pac_tpl_cpuversion_details(directory, tpl_path, xml_path)
   end
    if(mcf_location.upcase.start_with?("GCP"))
      if(mcf_location.upcase.end_with?("4000"))
        mcf_location = "4k"
      else
        mcf_location = "5k"
      end
    end
   render :json => {:mcf_name => mcf_name , :mcfcrc => mcf_crc, :mcf_location => mcf_location}
 end
 
 ####################################################################
 # Function:      get_pac_details
 # Parameters:    params[:pac_path]
 # Retrun:        mcf_name , mcf_crc
 # Renders:       render :json
 # Description:   Download the PAC import report
 ####################################################################  
 def get_pac_details
   pac_path = params[:pac_path].strip
   directory = "#{RAILS_ROOT}/tmp/tplextract"
   Dir.mkdir(directory) unless File.exists? directory

   if pac_path[pac_path.length-1] == '*'
    file_name = pac_path[0,pac_path.length-1]
    tpl_path = directory +'/'+ file_name
   else
    file_name = File.basename(pac_path)
    tpl_path = File.join(directory, file_name)
    FileUtils.cp(pac_path, tpl_path)
   end

   xml_name = file_name.chomp(File.extname(file_name))
   xml_path = "#{directory}/#{xml_name}.XML"
   mcf_name, mcf_crc, mcf_location, error, error_mess = read_pac_tpl_cpuversion_details(directory, tpl_path, xml_path)
   if(mcf_location.upcase.start_with?("GCP"))
     if(mcf_location.upcase.end_with?("4000"))
       mcf_location = "4k"
     else
       mcf_location = "5k"
     end
   end
   render :json => {:mcf_name => mcf_name.strip , :mcfcrc => mcf_crc.upcase, :mcf_location => mcf_location}
 end
 ####################################################################
 # Function:      download_pac_import_report
 # Parameters:    None
 # Retrun:        None
 # Renders:       None
 # Description:   Download the PAC import report
 ####################################################################  
 def template_readmcfcrc
   if !params[:uploadTemplateFile].blank? || !params[:uploadPacFile].blank?
     mcf_crc = ""
     mcf_name = ""
     if params[:new_site_type] == "create_new_site"
      file_name = params[:uploadTemplateFile].original_filename
      content = params[:uploadTemplateFile].read
      xml_name = file_name.chomp(File.extname(file_name))
     else
       file_name = params[:uploadPacFile].original_filename
       content = params[:uploadPacFile].read
       xml_name = file_name.chomp(File.extname(file_name))
     end
      directory = "#{RAILS_ROOT}/tmp/tplextract"
      Dir.mkdir(directory) unless File.exists? directory
      Pathname.new(directory).children.each { |p| p.rmtree }
      tpl_path = File.join(directory, file_name)
      File.open(tpl_path, "wb") { |f| f.write(content) }
      
      xml_path = "#{directory}/#{xml_name}.XML"
      
      mcf_name, mcf_crc, mcf_location, error, error_mess = read_pac_tpl_cpuversion_details(directory, tpl_path, xml_path)
      if(mcf_location.upcase.start_with?("GCP"))
        if(mcf_location.upcase.end_with?("4000"))
          mcf_location = "4k"
        else
          mcf_location = "5k"
        end
      end
      render :text=>  "#{mcf_name.strip}|#{mcf_crc.upcase}|#{mcf_location}"
    end
 end
 
  def update_mtf_index(createsite, pac1_directory)
   db_currentsite = SQLite3::Database.new("#{createsite}/rt.db")
   db_pac = SQLite3::Database.new("#{pac1_directory}/rt.db")
   mtf_current = db_currentsite.execute("Select mcfcrc, active_mtf_index from rt_gwe")
   mtf_pac = db_pac.execute("Select mcfcrc, active_mtf_index from rt_gwe")
   active_mtf_index = mtf_pac[0][1].to_i
   mtf_index = PageParameter.all(:conditions => {:mtf_index => active_mtf_index})
   #if ((!mtf_index.blank?) && (mtf_pac[0][0].to_i == mtf_current[0][0].to_i) && (mtf_pac[0][1].to_i != mtf_current[0][1].to_i))
   if ((!mtf_index.blank?) && (mtf_pac[0][1].to_i != mtf_current[0][1].to_i))
     simulator = "\"#{session[:OCE_ROOT]}\\GCP_OCE_Manager.exe\", \"#{5}\" \"#{session[:cfgsitelocation]}\" \"#{session[:OCE_ROOT]}\" \"#{active_mtf_index}\""
     puts simulator.inspect
     if system(simulator)
       puts "PASS"
     else
       puts "FAIL"
     end
   end
  end
 
 def read_gcp_export_usb_file_struct
    ini = IniFile.load("#{RAILS_ROOT}/config/Filestruct.ini")
    root = ini['Global']['Root']
    prod_dir = ""
    product = "GCP4000"
    pac_upload_path , cdl_upload_path , mcf_upload_path = ""  
    gcp_file_struct =  ini[product]
    gcp_file_struct.each do |key , value|
      if (value.to_s.include? "$Root")
        value.to_s.gsub!("$Root", root)
      end
      if (value.to_s.include? "&Product")
        value.to_s.gsub!("&Product", product)
      end
      if (key == "Prod_Dir")
        prod_dir = value.to_s
      end
    end
    
    gcp_file_struct.each do |key , value|
      if (value.to_s.include? "$Root")
        value.to_s.gsub!("$Root", root)
      end
      if (value.to_s.include? "&Product")
        value.to_s.gsub!("&Product", product)
      end
      if (value.to_s.include? "$Prod_Dir")
        value.to_s.gsub!("$Prod_Dir", prod_dir)
      end
      if (key.downcase == "pac_upload")
        pac_upload_path = value.to_s
      elsif (key.downcase == "*.mcf")
        mcf_upload_path = value.to_s
      elsif (key.downcase == "*.cdl")
        cdl_upload_path = value.to_s
      end
    end
    
    split_pac_upload_path = pac_upload_path.split("\\")
    split_cdl_upload_path = cdl_upload_path.split("\\")
    split_mcf_upload_path = mcf_upload_path.split("\\")
    split_pac_upload_path.reject! &:empty?
    split_cdl_upload_path.reject! &:empty?
    split_mcf_upload_path.reject! &:empty?
    
    return split_pac_upload_path , split_cdl_upload_path , split_mcf_upload_path
 end

def validate_sitename(file_name , site_type)
  site_name = ""
  file_type = file_name[-3,3].upcase
  if ((file_type == "PAC") || (file_type == "TPL") || (file_type == "ZIP"))
    file_name = file_name[0..-5]
  end
  if file_name.upcase.start_with?('CONFIG-')
    site_name = file_name[7..(file_name.length-1)]
    if (file_type == "ZIP")
      arr_filename = site_name.split('-')
      if(arr_filename.length >=3)
        temp_site = ""
        for i in 0..(arr_filename.length - 3)
          if (temp_site == "")
            temp_site = arr_filename[i]
          else
            temp_site = temp_site + '-' + arr_filename[i]
          end
        end
        site_name = temp_site if !temp_site.blank?
      end
    end    
  else
    site_name = file_name
  end
    
  site_name = site_name.gsub("'","")
  site_name = site_name.gsub(".","")
  valid_sitename = ""
  if (site_type == "GCP")
    if !site_name.blank?
      count = 0
      temp_site =""
      destination = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/#{site_name}"
      while(get_valid_site(destination) == false)
        count = count + 1
        temp_site = site_name + "_" + count.to_s
        destination = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/#{temp_site}"
      end
      if(!temp_site.blank?)
        valid_sitename = temp_site
      else
        valid_sitename = site_name
      end
    end
  else
    valid_sitename = site_name
  end
  return valid_sitename  
end

def update_sitename
  file_name = params[:filename]
  site_type = params[:site_type]
  valid_sitename = validate_sitename(file_name , site_type)
  render :json=>{:sitename=>valid_sitename}
end

end

# This class represents the INI file and can be used to parse, modify,
# and write INI files.
class IniFile
  include Enumerable

  class Error < StandardError; end
  VERSION = '3.0.0'

  # Public: Open an INI file and load the contents.
  #
  # filename - The name of the file as a String
  # opts     - The Hash of options (default: {})
  #            :comment   - String containing the comment character(s)
  #            :parameter - String used to separate parameter and value
  #            :encoding  - Encoding String for reading / writing
  #            :default   - The String name of the default global section
  #
  # Examples
  #
  #   IniFile.load('file.ini')
  #   #=> IniFile instance
  #
  #   IniFile.load('does/not/exist.ini')
  #   #=> nil
  #
  # Returns an IniFile instance or nil if the file could not be opened.
  def self.load( filename, opts = {} )
    return unless File.file? filename
    new(opts.merge(:filename => filename))
  end

  # Get and set the filename
  attr_accessor :filename

  # Get and set the encoding
  attr_accessor :encoding

  # Public: Create a new INI file from the given set of options. If :content
  # is provided then it will be used to populate the INI file. If a :filename
  # is provided then the contents of the file will be parsed and stored in the
  # INI file. If neither the :content or :filename is provided then an empty
  # INI file is created.
  #
  # opts - The Hash of options (default: {})
  #   :content   - The String/Hash containing the INI contents
  #   :comment   - String containing the comment character(s)
  #   :parameter - String used to separate parameter and value
  #   :encoding  - Encoding String for reading / writing
  #   :default   - The String name of the default global section
  #   :filename  - The filename as a String
  #
  # Examples
  #
  #   IniFile.new
  #   #=> an empty IniFile instance
  #
  #   IniFile.new( :content => "[global]\nfoo=bar" )
  #   #=> an IniFile instance
  #
  #   IniFile.new( :filename => 'file.ini', :encoding => 'UTF-8' )
  #   #=> an IniFile instance
  #
  #   IniFile.new( :content => "[global]\nfoo=bar", :comment => '#' )
  #   #=> an IniFile instance
  #
  def initialize( opts = {} )
    @comment  = opts.fetch(:comment, ';#')
    @param    = opts.fetch(:parameter, '=')
    @encoding = opts.fetch(:encoding, nil)
    @default  = opts.fetch(:default, 'global')
    @filename = opts.fetch(:filename, nil)
    content   = opts.fetch(:content, nil)

    @ini = Hash.new {|h,k| h[k] = Hash.new}

    if    content.is_a?(Hash) then merge!(content)
    elsif content             then parse(content)
    elsif @filename           then read
    end
  end

  # Public: Write the contents of this IniFile to the file system. If left
  # unspecified, the currently configured filename and encoding will be used.
  # Otherwise the filename and encoding can be specified in the options hash.
  #
  # opts - The default options Hash
  #        :filename - The filename as a String
  #        :encoding - The encoding as a String
  #
  # Returns this IniFile instance.
  def write( opts = {} )
    filename = opts.fetch(:filename, @filename)
    encoding = opts.fetch(:encoding, @encoding)
    mode = encoding ? "w:#{encoding}" : "w"

    File.open(filename, mode) do |f|
      @ini.each do |section,hash|
        f.puts "[#{section}]"
        hash.each {|param,val| f.puts "#{param} #{@param} #{escape_value val}"}
        f.puts
      end
    end

    self
  end
  alias :save :write

  # Public: Read the contents of the INI file from the file system and replace
  # and set the state of this IniFile instance. If left unspecified the
  # currently configured filename and encoding will be used when reading from
  # the file system. Otherwise the filename and encoding can be specified in
  # the options hash.
  #
  # opts - The default options Hash
  #        :filename - The filename as a String
  #        :encoding - The encoding as a String
  #
  # Returns this IniFile instance if the read was successful; nil is returned
  # if the file could not be read.
  def read( opts = {} )
    filename = opts.fetch(:filename, @filename)
    encoding = opts.fetch(:encoding, @encoding)
    return unless File.file? filename

    mode = encoding ? "r:#{encoding}" : "r"
    File.open(filename, mode) { |fd| parse fd }
    self
  end
  alias :restore :read

  # Returns this IniFile converted to a String.
  def to_s
    s = []
    @ini.each do |section,hash|
      s << "[#{section}]"
      hash.each {|param,val| s << "#{param} #{@param} #{escape_value val}"}
      s << ""
    end
    s.join("\n")
  end

  # Returns this IniFile converted to a Hash.
  def to_h
    @ini.dup
  end

  # Public: Creates a copy of this inifile with the entries from the
  # other_inifile merged into the copy.
  #
  # other - The other IniFile.
  #
  # Returns a new IniFile.
  def merge( other )
    self.dup.merge!(other)
  end

  # Public: Merges other_inifile into this inifile, overwriting existing
  # entries. Useful for having a system inifile with user overridable settings
  # elsewhere.
  #
  # other - The other IniFile.
  #
  # Returns this IniFile.
  def merge!( other )
    return self if other.nil?

    my_keys = @ini.keys
    other_keys = case other
      when IniFile
        other.instance_variable_get(:@ini).keys
      when Hash
        other.keys
      else
        raise Error, "cannot merge contents from '#{other.class.name}'"
      end

    (my_keys & other_keys).each do |key|
      case other[key]
      when Hash
        @ini[key].merge!(other[key])
      when nil
        nil
      else
        raise Error, "cannot merge section #{key.inspect} - unsupported type: #{other[key].class.name}"
      end
    end

    (other_keys - my_keys).each do |key|
      @ini[key] = case other[key]
        when Hash
          other[key].dup
        when nil
          {}
        else
          raise Error, "cannot merge section #{key.inspect} - unsupported type: #{other[key].class.name}"
        end
    end

    self
  end

  # Public: Yield each INI file section, parameter, and value in turn to the
  # given block.
  #
  # block - The block that will be iterated by the each method. The block will
  #         be passed the current section and the parameter/value pair.
  #
  # Examples
  #
  #   inifile.each do |section, parameter, value|
  #     puts "#{parameter} = #{value} [in section - #{section}]"
  #   end
  #
  # Returns this IniFile.
  def each
    return unless block_given?
    @ini.each do |section,hash|
      hash.each do |param,val|
        yield section, param, val
      end
    end
    self
  end

  # Public: Yield each section in turn to the given block.
  #
  # block - The block that will be iterated by the each method. The block will
  #         be passed the current section as a Hash.
  #
  # Examples
  #
  #   inifile.each_section do |section|
  #     puts section.inspect
  #   end
  #
  # Returns this IniFile.
  def each_section
    return unless block_given?
    @ini.each_key {|section| yield section}
    self
  end

  # Public: Remove a section identified by name from the IniFile.
  #
  # section - The section name as a String.
  #
  # Returns the deleted section Hash.
  def delete_section( section )
    @ini.delete section.to_s
  end

  # Public: Get the section Hash by name. If the section does not exist, then
  # it will be created.
  #
  # section - The section name as a String.
  #
  # Examples
  #
  #   inifile['global']
  #   #=> global section Hash
  #
  # Returns the Hash of parameter/value pairs for this section.
  def []( section )
    return nil if section.nil?
    @ini[section.to_s]
  end

  # Public: Set the section to a hash of parameter/value pairs.
  #
  # section - The section name as a String.
  # value   - The Hash of parameter/value pairs.
  #
  # Examples
  #
  #   inifile['tenderloin'] = { 'gritty' => 'yes' }
  #   #=> { 'gritty' => 'yes' }
  #
  # Returns the value Hash.
  def []=( section, value )
    @ini[section.to_s] = value
  end

  # Public: Create a Hash containing only those INI file sections whose names
  # match the given regular expression.
  #
  # regex - The Regexp used to match section names.
  #
  # Examples
  #
  #   inifile.match(/^tree_/)
  #   #=> Hash of matching sections
  #
  # Return a Hash containing only those sections that match the given regular
  # expression.
  def match( regex )
    @ini.dup.delete_if { |section, _| section !~ regex }
  end

  # Public: Check to see if the IniFile contains the section.
  #
  # section - The section name as a String.
  #
  # Returns true if the section exists in the IniFile.
  def has_section?( section )
    @ini.has_key? section.to_s
  end

  # Returns an Array of section names contained in this IniFile.
  def sections
    @ini.keys
  end

  # Public: Freeze the state of this IniFile object. Any attempts to change
  # the object will raise an error.
  #
  # Returns this IniFile.
  def freeze
    super
    @ini.each_value {|h| h.freeze}
    @ini.freeze
    self
  end

  # Public: Mark this IniFile as tainted -- this will traverse each section
  # marking each as tainted.
  #
  # Returns this IniFile.
  def taint
    super
    @ini.each_value {|h| h.taint}
    @ini.taint
    self
  end

  # Public: Produces a duplicate of this IniFile. The duplicate is independent
  # of the original -- i.e. the duplicate can be modified without changing the
  # original. The tainted state of the original is copied to the duplicate.
  #
  # Returns a new IniFile.
  def dup
    other = super
    other.instance_variable_set(:@ini, Hash.new {|h,k| h[k] = Hash.new})
    @ini.each_pair {|s,h| other[s].merge! h}
    other.taint if self.tainted?
    other
  end

  # Public: Produces a duplicate of this IniFile. The duplicate is independent
  # of the original -- i.e. the duplicate can be modified without changing the
  # original. The tainted state and the frozen state of the original is copied
  # to the duplicate.
  #
  # Returns a new IniFile.
  def clone
    other = dup
    other.freeze if self.frozen?
    other
  end

  # Public: Compare this IniFile to some other IniFile. For two INI files to
  # be equivalent, they must have the same sections with the same parameter /
  # value pairs in each section.
  #
  # other - The other IniFile.
  #
  # Returns true if the INI files are equivalent and false if they differ.
  def eql?( other )
    return true if equal? other
    return false unless other.instance_of? self.class
    @ini == other.instance_variable_get(:@ini)
  end
  alias :== :eql?

  # Escape special characters.
  #
  # value - The String value to escape.
  #
  # Returns the escaped value.
  def escape_value( value )
    value = value.to_s.dup
    value.gsub!(%r/\\([0nrt])/, '\\\\\1')
    value.gsub!(%r/\n/, '\n')
    value.gsub!(%r/\r/, '\r')
    value.gsub!(%r/\t/, '\t')
    value.gsub!(%r/\0/, '\0')
    value
  end

  # Parse the given content and store the information in this IniFile
  # instance. All data will be cleared out and replaced with the information
  # read from the content.
  #
  # content - A String or a file descriptor (must respond to `each_line`)
  #
  # Returns this IniFile.
  def parse( content )
    parser = Parser.new(@ini, @param, @comment, @default)
    parser.parse(content)
    self
  end

  # The IniFile::Parser has the responsibility of reading the contents of an
  # .ini file and storing that information into a ruby Hash. The object being
  # parsed must respond to `each_line` - this includes Strings and any IO
  # object.
  class Parser

    attr_writer :section
    attr_accessor :property
    attr_accessor :value

    # Create a new IniFile::Parser that can be used to parse the contents of
    # an .ini file.
    #
    # hash    - The Hash where parsed information will be stored
    # param   - String used to separate parameter and value
    # comment - String containing the comment character(s)
    # default - The String name of the default global section
    #
    def initialize( hash, param, comment, default )
      @hash = hash
      @default = default

      comment = comment.to_s.empty? ? "\\z" : "\\s*(?:[#{comment}].*)?\\z"

      @section_regexp  = %r/\A\s*\[([^\]]+)\]#{comment}/
      @ignore_regexp   = %r/\A#{comment}/
      @property_regexp = %r/\A(.*?)(?<!\\)#{param}(.*)\z/

      @open_quote      = %r/\A\s*(".*)\z/
      @close_quote     = %r/\A(.*(?<!\\)")#{comment}/
      @full_quote      = %r/\A\s*(".*(?<!\\)")#{comment}/
      @trailing_slash  = %r/\A(.*)(?<!\\)\\#{comment}/
      @normal_value    = %r/\A(.*?)#{comment}/
    end

    # Returns `true` if the current value starts with a leading double quote.
    # Otherwise returns false.
    def leading_quote?
      value && value =~ %r/\A"/
    end

    # Given a string, attempt to parse out a value from that string. This
    # value might be continued on the following line. So this method returns
    # `true` if it is expecting more data.
    #
    # string - String to parse
    #
    # Returns `true` if the next line is also part of the current value.
    # Returns `fase` if the string contained a complete value.
    def parse_value( string )
      continuation = false

      # if our value starts with a double quote, then we are in a
      # line continuation situation
      if leading_quote?
        # check for a closing quote at the end of the string
        if string =~ @close_quote
          value << $1

        # otherwise just append the string to the value
        else
          value << string
          continuation = true
        end

      # not currently processing a continuation line
      else
        case string
        when @full_quote
          self.value = $1

        when @open_quote
          self.value = $1
          continuation = true

        when @trailing_slash
          self.value ?  self.value << $1 : self.value = $1
          continuation = true

        when @normal_value
          self.value ?  self.value << $1 : self.value = $1

        else
          error
        end
      end

      if continuation
        self.value << $/ if leading_quote?
      else
        process_property
      end

      continuation
    end

    # Parse the ini file contents. This will clear any values currently stored
    # in the ini hash.
    #
    # content - Any object that responds to `each_line`
    #
    # Returns nil.
    def parse( content )
      return unless content

      continuation = false

      @hash.clear
      @line = nil
      self.section = nil

      content.each_line do |line|
        @line = line.chomp

        if continuation
          continuation = parse_value @line
        else
          case @line
          when @ignore_regexp
            nil
          when @section_regexp
            self.section = @hash[$1]
          when @property_regexp
            self.property = $1.strip
            error if property.empty?

            continuation = parse_value $2
          else
            error
          end
        end
      end

      # check here if we have a dangling value ... usually means we have an
      # unmatched open quote
      if leading_quote?
        error "Unmatched open quote"
      elsif property && value
        process_property
      elsif value
        error
      end

      nil
    end

    # Store the property/value pair in the currently active section. This
    # method checks for continuation of the value to the next line.
    #
    # Returns nil.
    def process_property
      property.strip!
      value.strip!

      self.value = $1 if value =~ %r/\A"(.*)(?<!\\)"\z/m

      section[property] = typecast(value)

      self.property = nil
      self.value = nil
    end

    # Returns the current section Hash.
    def section
      @section ||= @hash[@default]
    end

    # Raise a parse error using the given message and appending the current line
    # being parsed.
    #
    # msg - The message String to use.
    #
    # Raises IniFile::Error
    def error( msg = 'Could not parse line' )
      raise Error, "#{msg}: #{@line.inspect}"
    end

    # Attempt to typecast the value string. We are looking for boolean values,
    # integers, floats, and empty strings. Below is how each gets cast, but it
    # is pretty logical and straightforward.
    #
    #  "true"  -->  true
    #  "false" -->  false
    #  ""      -->  nil
    #  "42"    -->  42
    #  "3.14"  -->  3.14
    #  "foo"   -->  "foo"
    #
    # Returns the typecast value.
    def typecast( value )
      case value
      when %r/\Atrue\z/i;  true
      when %r/\Afalse\z/i; false
      when %r/\A\s*\z/i;   nil
      else
        Integer(value) rescue \
        Float(value)   rescue \
        unescape_value(value)
      end
    end

    # Unescape special characters found in the value string. This will convert
    # escaped null, tab, carriage return, newline, and backslash into their
    # literal equivalents.
    #
    # value - The String value to unescape.
    #
    # Returns the unescaped value.
    def unescape_value( value )
      value = value.to_s
      value.gsub!(%r/\\[0nrt\\]/) { |char|
        case char
        when '\0';   "\0"
        when '\n';   "\n"
        when '\r';   "\r"
        when '\t';   "\t"
        when '\\\\'; "\\"
        end
      }
      value
    end
  end

end  # IniFile