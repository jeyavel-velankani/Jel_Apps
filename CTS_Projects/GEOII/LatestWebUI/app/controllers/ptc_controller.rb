####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: ptc_controller.rb
# Description: Used to get/update the Message layout & device attributes pages values 
####################################################################
#History:
# Log: /wayside/GEOII/Trunk/Software/WebUI/app/controllers/ptc_controller.rb
#
# Rev 5374  Sep 13 2013 17:30:00   Jeyavel Natesan
# Initial version
class PtcController < ApplicationController
  layout "general"
  include PtcHelper
  include ReportsHelper
  include AspectlookupHelper
  include UdpCmdHelper
  include SelectsiteHelper
  before_filter :ptc_setup # this method is defined in PtcHelper
  
  ####################################################################
  # Function:      message_layout
  # Parameters:    None
  # Return:        None
  # Renders:       partial
  # Description:   Fetch message layout values based on the installation selection
  ####################################################################
  def message_layout
    begin
      session[:defaultsitename] = nil
      session[:defaultmilepost] = nil
      session[:defaultdivnumber] = nil 
      sel_aspect =  validate_aspect_textfile
      if (session[:typeOfSystem] == 'iVIU PTC GEO') && (sel_aspect.blank? || sel_aspect.to_s == 'false')
        session[:error] = "Selected GEO Aspect Lookup text file is invalid" 
        render :template => "/redirectpage/index" and return
      else
        unless session[:cfgsitelocation].blank? 
          if File.exists?(session[:cfgsitelocation]+'/site_ptc_db.db')
            validatedatabase =  check_databaseschema
            if validatedatabase
             (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:siteptcdblocation]
              unless session[:siteptcdblocation].blank?
                if !(File.exists?(session[:siteptcdblocation]))        
                  session[:error] = "Select master GEOPTC DB from configuration editor page, then try again"
                  render :template => "/redirectpage/index" and return
                end
                @mcf_installations = Installationtemplate.all.map(&:InstallationName)
                unless @mcf_installations.blank?
                  if (@mcf_installations.length >1)
                    activeinstallation = Gwe.find(:all,:select=>"active_physical_layout").map(&:active_physical_layout)
                    @installation_name_default = @mcf_installations[activeinstallation[0].to_i-1]
                  else
                    @installation_name_default = @mcf_installations[0]
                  end
                  @installation_name = params[:installation_name].blank? ? @installation_name_default.to_s : params[:installation_name]
                else
                  @installation_name = nil
                end
                unless @installation_name.blank?
                  begin                                 
                    session[:value] = 1
                    get_config_elements(@installation_name) 
                  rescue => e  
                    session[:error] = "Selected mcf not compatible " 
                    render :template => "/redirectpage/index" and return
                  end
                else
                  session[:value] = 0
                  session[:error] = "Site PTC DB database empty" 
                  render :template => "/redirectpage/index" and return
                end
              else
                session[:error] = "Site PTC DB not available for this site configuration"
                render :template => "/redirectpage/index" and return
              end
            else
              session[:error] = "Site ptc database schema not compatible with new schema, please create new site configuration with new schema and try again" 
              render :template => "/redirectpage/index" and return
            end
          else
            session[:error] = "Site PTC DB not available for this site configuration" 
            render :template => "/redirectpage/index" and return
          end
        else
          session[:error] = "Please create/open the configuration from configuration editor page, then try again" 
          render :template => "/redirectpage/index" and return
        end
      end
    rescue Exception => e
      session[:error] = e.message
      render :partial => "error_message" and return
    end
  end
  
  ####################################################################
  # Function:      update_message_layout
  # Parameters:    None
  # Return:        None
  # Renders:       partial
  # Description:   Updating message layout values
  ####################################################################
  def update_message_layout
    begin
      devices_list = ""
      device= ""
      msgpos = 1
      bitpos = 0
      site_ptcdb = session[:cfgsitelocation]+'/site_ptc_db.db'
      update_status = ""
      unless params[:devices].blank?
        devices_list = params[:devices]
        #update msgpos, bitpos with device id
        for ind in 0..(devices_list.length-1) 
          device = devices_list[ind].split('|')
          if(device.length == 3)          
            case device[0]
              when "signal"
              if device[1].to_i > 0
                Ptcdevice.update_device_msgpos_and_bitpos(msgpos , bitpos , device[1].to_i)
                msgpos = msgpos + 1
                bitpos = bitpos + 5  
              end
              
              when "switch"
              if device[1].to_i > 0
                Ptcdevice.update_device_msgpos_and_bitpos(msgpos , bitpos , device[1].to_i)
                msgpos = msgpos + 1
                bitpos = bitpos + 2  
              end
              
              when "hzdetector"
              if device[1].to_i > 0
                Ptcdevice.update_device_msgpos_and_bitpos(msgpos , bitpos , device[1].to_i)
                msgpos = msgpos + 1
                bitpos = bitpos + 1
              end
            end     #case device[0]
          else
            update_status = "Unable to process the changes."          
          end       #if(device.length == 3)
        end   #for ind      
      else
        update_status = "No devices present."
      end   #unless params[:devices].blank?
      if (update_status.length == 0)
        mcf_installations = Installationtemplate.all.map(&:InstallationName)
        activeinstallation = Gwe.find(:all,:select=>"active_physical_layout").map(&:active_physical_layout)
        if (mcf_installations.length > 1)
          installation_name_default = mcf_installations[activeinstallation[0].to_i-1]
        else
          installation_name_default = mcf_installations[0].to_s
        end
        mcfpath = "#{session[:cfgsitelocation]}/#{session[:mcfnamefromselected]}"
        out_dir = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id]}/DT2"
        geoptc_db = site_ptcdb
        instalationname = installation_name_default.to_s
        aspectlookuptxtfilepath = session[:aspectfilepath]
        nv_template_flag = "false"
        simulator = "\"#{session[:OCE_ROOT]}\\UIConnector.exe\", \"#{converttowindowspath(mcfpath)}\" \"#{converttowindowspath(out_dir)}\" \"#{converttowindowspath(geoptc_db)}\" \"#{instalationname}\" \"#{session[:typeOfSystem]}\" \"#{1}\" \"#{3}\" \"#{converttowindowspath(aspectlookuptxtfilepath)}\" \"#{nv_template_flag}\""
        puts simulator.inspect
        system(simulator)
        update_status = "Successfully updated the Msg Layout Information."     
      end
      render :json => { :error => false, :message => update_status }
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end  
  end
  
  ####################################################################
  # Function:      device_attributes
  # Parameters:    None
  # Return:        None
  # Renders:       partial
  # Description:   Device attribute Page code - display included and excluded site ptc devices
  ####################################################################
  def device_attributes
    session[:defaultsitename] = nil
    session[:defaultmilepost] = nil
    session[:defaultdivnumber] = nil
    sel_aspect =  validate_aspect_textfile
    if (session[:typeOfSystem] == 'iVIU PTC GEO') && (sel_aspect.blank? || sel_aspect.to_s == 'false')
      session[:error] = "Selected GEO Aspect Lookup text file is invalid" 
      render :template => "/redirectpage/index" and return
    else
      unless session[:cfgsitelocation].blank? 
        if File.exists?(session[:cfgsitelocation]+'/site_ptc_db.db')
          session[:siteptcdblocation] = session[:cfgsitelocation]+'/site_ptc_db.db'
          validatedatabase =  check_databaseschema
          if validatedatabase
           (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:siteptcdblocation]
            unless session[:siteptcdblocation].blank?
              if !(File.exists?(session[:siteptcdblocation]))        
                session[:error] = "Select master GEOPTC DB from configuration editor page, then try again"
                render :template => "/redirectpage/index" and return
              end              
              if (session[:typeOfSystem] == 'VIU')
                get_valid_wiuxml_objects()
              end
              @mcf_installations = Installationtemplate.all.map(&:InstallationName)
              unless @mcf_installations.blank?
                if (@mcf_installations.length >1)
                  activeinstallation = Gwe.find(:all,:select=>"active_physical_layout").map(&:active_physical_layout)
                  @installation_name_default = @mcf_installations[activeinstallation[0].to_i-1]
                else
                  @installation_name_default = @mcf_installations[0]
                end
                @installation_name = params[:installation_name].blank? ? @installation_name_default.to_s : params[:installation_name]
              else
                @installation_name = nil
              end
              unless @installation_name.blank?
                begin
                  goltype = Mcfptc.find(:all, :select => "GOLType").map(&:GOLType)
                  if (goltype[0].to_i == 0)
                    @aspects =Aspect.select_all_aspectsdetails(@installation_name.to_s)
                    @ptcaspects =Ptcaspect.select_all_aspectsdetails(@installation_name.to_s)
                    session[:aspectsCount]= @aspects.length
                  else
                    session[:aspectsCount] = nil 
                    @aspects = nil
                    @ptcaspects = nil
                  end
                  get_config_elements_device_attribute(@installation_name)
                  render :partial => "device_attribute"
                rescue => e  
                  session[:error] = "Selected mcf not compatible" 
                  render :template => "/redirectpage/index" and return
                end
              else
                session[:error] = "Site PTC DB database empty" 
                render :template => "/redirectpage/index" and return
              end
            else
              session[:error] = "Site PTC DB not available for this site configuration" 
              render :template => "/redirectpage/index" and return
            end
          else
            session[:error] = "Site ptc database schema not compatible with new schema, please create new site configuration with new schema and try again" 
            render :template => "/redirectpage/index" and return
          end
        else
          session[:error] = "Site PTC DB not available for this site configuration" 
          render :template => "/redirectpage/index" and return
        end
      else
        session[:error] = "Please create/open the configuration from configuration editor page, then try again" 
        render :template => "/redirectpage/index" and return
      end
    end
  end
  
  ####################################################################
  # Function:      update_device_attributes
  # Parameters:    params
  # Return:        None
  # Renders:       render :json 
  # Description:   Updating device attributes
  ####################################################################
  def update_device_attributes
    begin
      includeflag = false
      excludeflag = false
      actual_signals = session[:signalCount].to_i
      actual_switches = session[:switchCount].to_i
      actual_hzdetectors = session[:hazarddetectorsCount].to_i

      new_signals = params["hd_newsignal_count"].to_i
      new_switches = params["hd_newswitch_count"].to_i
      new_hzdetectors = params["hd_newhzdetector_count"].to_i
      remove_devices_list = params["remove_devices_list"]
      
      new_remove_device_ids = delete_device(remove_devices_list.to_s)
      
      for i in 0...session[:signalCount].to_i
        signal_direction = nil
        signal_id = params["signal_id_#{i}"]
        track_number = params["signal_tracknumber_#{i}"] == nil ? "" : params["signal_tracknumber_#{i}"]
        track_name = params["signal_trackname_#{i}"] == nil ? "" : ((params["signal_trackname_#{i}"].downcase == "not set") ? "" : params["signal_trackname_#{i}"])
        signal_directionvalue = params["signal_direction_#{i}"]
        if signal_directionvalue == "Select"
          signal_direction =""
        else
          signal_direction = signal_directionvalue
        end
        signal_milepost = params["signal_milepost_#{i}"]
        signal_subdivisionnumber = (!params["signal_subdivisionnumber_#{i}"].blank? && params["signal_subdivisionnumber_#{i}"].downcase == "not set") ? "" : params["signal_subdivisionnumber_#{i}"]
        signal_sitename = params["signal_sitename_#{i}"]
        signal_sitedeviceid = params["signal_sitedeviceid_#{i}"]
        signal_device_name = params["signal_device_name_#{i}"]
        signal_description = params["signal_description_#{i}"]
        if (session[:typeOfSystem] != 'VIU')
          existing_wsmmsg_pos = Ptcdevice.find(:all,:select=>"WSMMsgPosition",:conditions=>['Id=?',signal_id.to_i]).map(&:WSMMsgPosition)
          if params["sig_include_#{signal_id}"] == "Include" && params["signal_id_#{i}"]
            if existing_wsmmsg_pos[0].to_i == 0
              include_exclude_device_parameter("include",signal_id)
              includeflag = true
            end
            if (track_number == "" || track_number.downcase == "not set")
              Ptcdevice.update_all("TrackNumber = null, TrackName = '#{track_name}',  Direction  = \"#{signal_direction}\", Milepost  = \"#{signal_milepost}\", SubdivisionNumber  = \"#{signal_subdivisionnumber}\", SiteName  = \"#{signal_sitename}\" , SiteDeviceID =  \"#{signal_sitedeviceid}\", PTCDeviceName =  \"#{signal_device_name}\", Description =  \"#{signal_description}\"", "Id = '#{signal_id}'")
            else
              Ptcdevice.update_all("TrackNumber = '#{track_number}', TrackName = '#{track_name}', Direction  = \"#{signal_direction}\", Milepost  = \"#{signal_milepost}\", SubdivisionNumber  = \"#{signal_subdivisionnumber}\", SiteName  = \"#{signal_sitename}\" , SiteDeviceID =  \"#{signal_sitedeviceid}\", PTCDeviceName =  \"#{signal_device_name}\", Description =  \"#{signal_description}\"", "Id = '#{signal_id}'")
            end
          else
            if existing_wsmmsg_pos[0].to_i != 0
              include_exclude_device_parameter("exclude",signal_id)
              excludeflag = true
            end
          end
        else
          if track_number == ""
            Ptcdevice.update_all("TrackNumber = null, TrackName = '#{track_name}',  Direction  = \"#{signal_direction}\", Milepost  = \"#{signal_milepost}\", SubdivisionNumber  = \"#{signal_subdivisionnumber}\", SiteName  = \"#{signal_sitename}\" , SiteDeviceID =  \"#{signal_sitedeviceid}\", PTCDeviceName =  \"#{signal_device_name}\", Description =  \"#{signal_description}\"", "Id = '#{signal_id}'")
          else
            Ptcdevice.update_all("TrackNumber = '#{track_number}', TrackName = '#{track_name}', Direction  = \"#{signal_direction}\", Milepost  = \"#{signal_milepost}\", SubdivisionNumber  = \"#{signal_subdivisionnumber}\", SiteName  = \"#{signal_sitename}\" , SiteDeviceID =  \"#{signal_sitedeviceid}\", PTCDeviceName =  \"#{signal_device_name}\", Description =  \"#{signal_description}\"", "Id = '#{signal_id}'")
          end
        end
      end
      for j in 0...session[:switchCount].to_i
        switch_direction = nil
        switch_id = params["switch_id_#{j}"]
        switch_track_number = params["switch_track_number_#{j}"] == nil ? "" : params["switch_track_number_#{j}"]
        switch_track_name = params["switch_track_name_#{j}"] == nil ? "" : ((params["switch_track_name_#{j}"].downcase == "not set") ? "" : params["switch_track_name_#{j}"])
        switch_directionvalue = params["switch_direction_#{j}"]
        if switch_directionvalue == "Select"
          switch_direction = ""
        else
          switch_direction = switch_directionvalue
        end
        switch_milepost = params["switch_milepost_#{j}"]
        switch_subdivisionnumber = (!params["switch_subdivisionnumber_#{j}"].blank? && params["switch_subdivisionnumber_#{j}"].downcase == "not set") ? "" : params["switch_subdivisionnumber_#{j}"]
        switch_sitename = params["switch_sitename_#{j}"]
        switch_sitedeviceid = params["switch_sitedeviceid_#{j}"]
        switch_device_name = params["switch_device_name_#{j}"]
        switch_description = params["switch_description_#{j}"]
        if (session[:typeOfSystem] != 'VIU')
          existing_wsmmsg_pos = Ptcdevice.find(:all,:select=>"WSMMsgPosition",:conditions=>['Id=?',switch_id.to_i]).map(&:WSMMsgPosition)
          if params["sw_include_#{switch_id}"] == "Include" && params["switch_id_#{j}"]
            if existing_wsmmsg_pos[0].to_i == 0
              include_exclude_device_parameter("include",switch_id)
              includeflag = true
            end
            if (switch_track_number == "" || switch_track_number.downcase == "not set")
              Ptcdevice.update_all("TrackNumber = null, TrackName = '#{switch_track_name}', Direction  = \"#{switch_direction}\", Milepost  = \"#{switch_milepost}\", SubdivisionNumber  = \"#{switch_subdivisionnumber}\", SiteName  = \"#{switch_sitename}\" , SiteDeviceID =  \"#{switch_sitedeviceid}\", PTCDeviceName =  \"#{switch_device_name}\", Description =  \"#{switch_description}\"", "Id = '#{switch_id}'")
            else
              Ptcdevice.update_all("TrackNumber = '#{switch_track_number}',TrackName = '#{switch_track_name}', Direction  = \"#{switch_direction}\", Milepost  = \"#{switch_milepost}\", SubdivisionNumber  = \"#{switch_subdivisionnumber}\", SiteName  = \"#{switch_sitename}\" , SiteDeviceID =  \"#{switch_sitedeviceid}\", PTCDeviceName =  \"#{switch_device_name}\", Description =  \"#{switch_description}\"", "Id = '#{switch_id}'")
            end
          else
            if existing_wsmmsg_pos[0].to_i != 0
              include_exclude_device_parameter("exclude",switch_id)
              excludeflag = true
            end
          end
        else
          if switch_track_number == ""
            Ptcdevice.update_all("TrackNumber = null, TrackName = '#{switch_track_name}', Direction  = \"#{switch_direction}\", Milepost  = \"#{switch_milepost}\", SubdivisionNumber  = \"#{switch_subdivisionnumber}\", SiteName  = \"#{switch_sitename}\" , SiteDeviceID =  \"#{switch_sitedeviceid}\", PTCDeviceName =  \"#{switch_device_name}\", Description =  \"#{switch_description}\"", "Id = '#{switch_id}'")
          else
            Ptcdevice.update_all("TrackNumber = '#{switch_track_number}',TrackName = '#{switch_track_name}', Direction  = \"#{switch_direction}\", Milepost  = \"#{switch_milepost}\", SubdivisionNumber  = \"#{switch_subdivisionnumber}\", SiteName  = \"#{switch_sitename}\" , SiteDeviceID =  \"#{switch_sitedeviceid}\", PTCDeviceName =  \"#{switch_device_name}\", Description =  \"#{switch_description}\"", "Id = '#{switch_id}'")
          end
        end
      end
      for k in 0...session[:hazarddetectorsCount].to_i
        hazarddetector_direction = nil
        hdid = params["hazarddetector_id_#{k}"]
        hdtracknumber = params["hdtrk#{k}"] == nil ? "" : params["hdtrk#{k}"]
        hdtrackname = params["hdtrkname#{k}"] == nil ? "" : ((params["hdtrkname#{k}"].downcase == "not set")? "" : params["hdtrkname#{k}"])
        hazarddetector_directionvalue = params["hazarddetector_direction_#{k}"]
        if hazarddetector_directionvalue == "Select"
          hazarddetector_direction = ""
        else
          hazarddetector_direction = hazarddetector_directionvalue
        end
        hazarddetector_milepost = params["hazarddetector_milepost_#{k}"]
        hazarddetector_subdivisionnumber = (!params["hazarddetector_subdivisionnumber_#{k}"].blank? && params["hazarddetector_subdivisionnumber_#{k}"].downcase == "not set") ? "" : params["hazarddetector_subdivisionnumber_#{k}"]
        hazarddetector_sitename = params["hazarddetector_sitename_#{k}"]
        hazarddetector_sitedeviceid = params["hazarddetector_sitedeviceid_#{k}"]
        hazarddetector_device_name = params["hazarddetector_device_name_#{k}"]
        hazarddetector_description = params["hazarddetector_description_#{k}"]
        if (session[:typeOfSystem] != 'VIU')
          existing_wsmmsg_pos = Ptcdevice.find(:all,:select=>"WSMMsgPosition",:conditions=>['Id=?',hdid.to_i]).map(&:WSMMsgPosition)
          if params["hd_include_#{hdid}"] == "Include" && params["hazarddetector_id_#{k}"]            
            if existing_wsmmsg_pos[0].to_i == 0
              include_exclude_device_parameter("include",hdid)
              includeflag = true
            end
            if (hdtracknumber == "" || hdtracknumber.downcase == "not set")
              Ptcdevice.update_all("TrackNumber = null,TrackName = '#{hdtrackname}', Direction  = \"#{hazarddetector_direction}\", Milepost  = \"#{hazarddetector_milepost}\", SubdivisionNumber  = \"#{hazarddetector_subdivisionnumber}\", SiteName  = \"#{hazarddetector_sitename}\" , SiteDeviceID =  \"#{hazarddetector_sitedeviceid}\", PTCDeviceName =  \"#{hazarddetector_device_name}\", Description =  \"#{hazarddetector_description}\"", "Id = '#{hdid}'")
            else
              Ptcdevice.update_all("TrackNumber = '#{hdtracknumber}',TrackName = '#{hdtrackname}', Direction  = \"#{hazarddetector_direction}\", Milepost  = \"#{hazarddetector_milepost}\", SubdivisionNumber  = \"#{hazarddetector_subdivisionnumber}\", SiteName  = \"#{hazarddetector_sitename}\" , SiteDeviceID =  \"#{hazarddetector_sitedeviceid}\", PTCDeviceName =  \"#{hazarddetector_device_name}\", Description =  \"#{hazarddetector_description}\"", "Id = '#{hdid}'")
            end
          else
            if existing_wsmmsg_pos[0].to_i != 0
              include_exclude_device_parameter("exclude",hdid)
              excludeflag = true
            end
          end
        else
          if hdtracknumber == ""
            Ptcdevice.update_all("TrackNumber = null,TrackName = '#{hdtrackname}', Direction  = \"#{hazarddetector_direction}\", Milepost  = \"#{hazarddetector_milepost}\", SubdivisionNumber  = \"#{hazarddetector_subdivisionnumber}\", SiteName  = \"#{hazarddetector_sitename}\" , SiteDeviceID =  \"#{hazarddetector_sitedeviceid}\", PTCDeviceName =  \"#{hazarddetector_device_name}\", Description =  \"#{hazarddetector_description}\"", "Id = '#{hdid}'")
          else
            Ptcdevice.update_all("TrackNumber = '#{hdtracknumber}',TrackName = '#{hdtrackname}', Direction  = \"#{hazarddetector_direction}\", Milepost  = \"#{hazarddetector_milepost}\", SubdivisionNumber  = \"#{hazarddetector_subdivisionnumber}\", SiteName  = \"#{hazarddetector_sitename}\" , SiteDeviceID =  \"#{hazarddetector_sitedeviceid}\", PTCDeviceName =  \"#{hazarddetector_device_name}\", Description =  \"#{hazarddetector_description}\"", "Id = '#{hdid}'")
          end
        end
      end
      
      add_new_device('signal', actual_signals + 1, actual_signals + new_signals + 1, new_remove_device_ids)
      add_new_device('switch', actual_switches + 1, actual_switches + new_switches + 1, new_remove_device_ids)
      add_new_device('hazarddetector', actual_hzdetectors + 1, actual_hzdetectors + new_hzdetectors + 1, new_remove_device_ids)
      
      if excludeflag == true || includeflag == true || (!remove_devices_list.blank?) || (new_signals + new_switches + new_hzdetectors > 0)
        order_elements_positions
        #     OCE UPDATE PTC WIU MSG LAYOUT PARAMETRS WITH RT.DB & MCF.db IMPLEMENTATION - START
        mcf_installations = Installationtemplate.all.map(&:InstallationName)
        activeinstallation = Gwe.find(:all,:select=>"active_physical_layout").map(&:active_physical_layout)
        if (mcf_installations.length > 1)
          installation_name_default = mcf_installations[activeinstallation[0].to_i-1]
        else
          installation_name_default = mcf_installations[0].to_s
        end
        mcfpath = session[:cfgsitelocation]+'/'+session[:mcfnamefromselected].to_s
        out_dir =  RAILS_ROOT+"/oce_configuration/"+session[:user_id].to_s+'/DT2'
        geoptc_db = session[:siteptcdblocation]
        instalationname = installation_name_default.to_s
        aspectlookuptxtfilepath = session[:aspectfilepath]
        nv_template_flag = "false"
        simulator = "\"#{session[:OCE_ROOT]}\\UIConnector.exe\", \"#{converttowindowspath(mcfpath)}\" \"#{converttowindowspath(out_dir)}\" \"#{converttowindowspath(geoptc_db)}\" \"#{instalationname}\" \"#{session[:typeOfSystem]}\" \"#{1}\" \"#{3}\" \"#{converttowindowspath(aspectlookuptxtfilepath)}\" \"#{nv_template_flag}\""
        system(simulator)
        #     OCE UPDATE PTC WIU MSG LAYOUT PARAMETRS WITH RT.DB & MCF.db IMPLEMENTATION - END
      end
      update_status = "Successfully updated the device attributes."
      render :json => { :error => false, :message => update_status }
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end 
  end
  
  ####################################################################
  # Function:      get_config_elements_device_attribute
  # Parameters:    installationname
  # Return:        None
  # Renders:       render :json 
  # Description:   Get the elements device values 
  ####################################################################
  def get_config_elements_device_attribute(installationname) 
    @signaldirection = ["Increasing" , "Decreasing"]
    @switchdirection = ["LF", "LR", "RF", "RR"]
    if session[:typeOfSystem] == 'VIU' 
      viu_site_info = read_viu_siteinfo  

       session[:defaultmilepost] = viu_site_info["MILEPOST"]
       session[:defaultsitename] = viu_site_info["SITE_NAME"]

    else
      session[:defaultsitename] = StringParameter.string_select_query(1)
      session[:defaultmilepost] = StringParameter.string_select_query(3)
    end


    sub_div_no = StringParameter.get_value(44 , "Subdivision Number")
   
      session[:defaultdivnumber] = sub_div_no[:String]  unless sub_div_no[:String].blank?
    
    unless session[:siteptcdblocation].blank?
      @mcf_installations = Installationtemplate.all.map(&:InstallationName)
      @selectedins = installationname  
      signalpos = get_mcf_signal_pos(installationname)
      switchpos = get_mcf_switches_pos(installationname)
      hdpos = get_mcf_hd_pos(installationname)
      a = []
      @elementorder =[]
      a[0]= signalpos =="0" ? 0 : signalpos.WSMMsgPosition
      a[1]= switchpos =="0" ? 0 : switchpos.WSMMsgPosition
      a[2]= hdpos =="0" ? 0 : hdpos.WSMMsgPosition
      b =[]
      @sig = Ptcdevice.find(:all , :conditions =>"Id IN(select p.Id from PTCDevice p, Signal h where p.InstallationName='#{installationname}' and p.id=h.id )" , :order =>"WSMMsgPosition")
      @swi = Ptcdevice.find(:all , :conditions =>"Id IN(select p.Id from PTCDevice p, Switch h where p.InstallationName='#{installationname}' and p.id=h.id )" , :order =>"WSMMsgPosition")
      @hd = Ptcdevice.find(:all , :conditions =>"Id IN(select p.Id from PTCDevice p, HazardDetector h where p.InstallationName='#{installationname}' and p.id=h.id )" , :order =>"WSMMsgPosition")
      b[0] = @sig.length
      b[1] = @swi.length
      b[2] = @hd.length
      @ptcdevices = Ptcdevice.find(:all , :conditions =>"InstallationName='#{installationname}' and WSMMsgPosition >0 " , :order =>"WSMMsgPosition")
      @deviceOrderflg = checkdevice(@ptcdevices)
      if(@deviceOrderflg == 'true')    
        if ((a[0] >0) && (a[1]>0) && (a[2]>0))
          if((a[0] < a[1]) && (a[1] < a[2]))
            @elementorder[0]=["Signal" ,1]
            @elementorder[1]=["Switch",2]
            @elementorder[2]=["Hazard Detector",3]
          elsif((a[0] < a[2]) && (a[2] < a[1]))
            @elementorder[0]=["Signal" ,1]
            @elementorder[1]=["Hazard Detector",2]
            @elementorder[2]=["Switch",3]                
          elsif((a[1] < a[0]) && (a[0] < a[2]))
            @elementorder[0]=["Switch",1]
            @elementorder[1]=["Signal" ,2]                
            @elementorder[2]=["Hazard Detector",3]
          elsif((a[1] < a[2]) && (a[2] < a[0]))
            @elementorder[0]=["Switch",1]
            @elementorder[1]=["Hazard Detector",2]
            @elementorder[2]=["Signal" ,3]                
          elsif((a[2] < a[1]) && (a[1] < a[0]))
            @elementorder[0]=["Hazard Detector",1]
            @elementorder[1]=["Switch",2]
            @elementorder[2]=["Signal" ,3]
          elsif((a[2] < a[0]) && (a[0] < a[1]))
            @elementorder[0]=["Hazard Detector",1]
            @elementorder[1]=["Signal" ,2]
            @elementorder[2]=["Switch",3]
          end
        elsif((a[0] >0) && (a[1]>0))
          if((a[0] < a[1]))
            @elementorder[0]=["Signal" ,1]
            @elementorder[1]=["Switch",2]
            @elementorder[2]=["Hazard Detector",3]
          else
            @elementorder[0]=["Switch",1]
            @elementorder[1]=["Signal" ,2]                  
            @elementorder[2]=["Hazard Detector",3]
          end
        elsif((a[0] >0) && (a[2]>0))
          if(a[0]<a[2])
            @elementorder[0]=["Signal" ,1]
            @elementorder[1]=["Hazard Detector",2]
            @elementorder[2]=["Switch",3]                  
          else
            @elementorder[0]=["Hazard Detector",1]
            @elementorder[1]=["Signal" ,2]
            @elementorder[2]=["Switch",3]
          end              
        elsif((a[1]>0) && (a[2]>0))
          if(a[1]<a[2])
            @elementorder[0]=["Switch",1] 
            @elementorder[1]=["Hazard Detector",2]
            @elementorder[2]=["Signal" ,3]
          else
            @elementorder[0]=["Hazard Detector",1]
            @elementorder[1]=["Switch",2]
            @elementorder[2]=["Signal" ,3]
          end
        elsif((a[0]>0) && (a[1]==0) && (a[2]==0))
          @elementorder[0]=["Signal" ,1]
          @elementorder[1]=["Switch",2]
          @elementorder[2]=["Hazard Detector",3]
        elsif((a[0]==0) && (a[1]>0) && (a[2]==0))
          @elementorder[0]=["Switch" ,1]
          @elementorder[1]=["Signal",2]
          @elementorder[2]=["Hazard Detector",3]
        elsif((a[0]==0) && (a[1]==0) && (a[2]>0))
          @elementorder[0]=["Hazard Detector" ,1]
          @elementorder[1]=["Signal",2]
          @elementorder[2]=["Switch",3]
        else
          @elementorder[0]=["Signal" ,1]
          @elementorder[1]=["Switch",2]
          @elementorder[2]=["Hazard Detector",3]             
        end
        session[:elementorder] = @elementorder
        @signals = get_mcf_signals_device_attributes(@installation_name) 
        session[:signalCount] = @signals.length
        @switches = get_mcf_switches_device_attributes(@installation_name)
        session[:switchCount] = @switches.length
        @hazarddetectors = get_mcf_hazard_detectors_device_attributes(@installation_name)
        session[:hazarddetectorsCount] = @hazarddetectors.length 
        @device_last_id_val = Ptcdevice.maximum("id") # Get the last/Max id in the table
        goltype = Mcfptc.find(:all, :select => "GOLType").map(&:GOLType)
        if (goltype[0].to_i == 0)
          @aspects = Aspect.select_all_aspectsdetails(@installation_name)
          @ptcaspects =Ptcaspect.select_all_aspectsdetails(@installation_name.to_s)
          session[:aspectsCount] = @aspects.length.to_i-1
        else
          session[:aspectsCount] = nil 
          @aspects = nil
          @ptcaspects = nil
        end
      else
        @elementorder[0]="Error on the order"
      end
    end
  end 
  
  ####################################################################
  # Function:      reorder_elements
  # Parameters:    None
  # Return:        None
  # Renders:       redirect_to
  # Description:   Re-order the elements positions values 
  ####################################################################
  def reorder_elements
    order_elements_positions
    if params[:reoder_refresh_flag] == "true"
      redirect_to :controller=>'ptc', :action=>'device_attributes'
    elsif (params[:pagename] == "messagelayout")
      redirect_to :controller=>'ptc', :action=>'message_layout'
    end
  end
  
  ####################################################################
  # Function:      include_exclude_device_parameter
  # Parameters:    event_type, device_id
  # Return:        None
  # Renders:       None
  # Description:   Update the WSMMsgPosition for included/excluded devices
  ####################################################################
  def include_exclude_device_parameter(event_type, device_id)
    if(event_type.downcase == "exclude")
      Ptcdevice.update_all("WSMMsgPosition = #{0}", {:id => device_id})
    elsif(event_type.downcase == "include")
      Ptcdevice.update_all("WSMMsgPosition = #{999}", {:id => device_id})
    end
  end
  
  ####################################################################
  # Function:      checkdevice
  # Parameters:    device
  # Return:        @returnvalues
  # Renders:       None
  # Description:   Check the device position is in order or not in order
  ####################################################################
  def checkdevice(device)
    @x =0
    @returnvalues = true
    @devicelen = device.length
    if (@devicelen > 0)
      for i in 1..@devicelen
        if (i.to_i != device[@x].WSMMsgPosition.to_i)
          @returnvalues = false
        end
        @x = @x + 1
      end
    end
    return @returnvalues.to_s
  end
  
  ####################################################################
  # Function:      get_elements
  # Parameters:    element, installation_name
  # Return:        None
  # Renders:       None
  # Description:   get the elements order values for corresponding installationname , element
  ####################################################################
  def get_elements(element, installation_name)
    case element
      when "Signal" then get_mcf_signals_order(installation_name)
      when "Switch" then get_mcf_switches_order(installation_name)
      when "Hazard Detector" then get_mcf_hazard_detectors_order(installation_name)      
    end
  end
  
  ####################################################################
  # Function:      get_config_elements
  # Parameters:    installationname
  # Return:        @elementorder
  # Renders:       None
  # Description:   get the elements values for corresponding installationname
  ####################################################################
  def get_config_elements(installationname) 
    @signaldirection = ["Increasing" , "Decreasing"]
    @switchdirection = ["LF", "LR", "RF", "RR"]
    session[:defaultsitename] = StringParameter.string_select_query(1)
    session[:defaultmilepost] = StringParameter.string_select_query(3)
    sub_div_no = StringParameter.get_value(44 , "Subdivision Number")
    session[:defaultdivnumber] = sub_div_no.String  unless sub_div_no.String.blank?
    unless session[:siteptcdblocation].blank?
      @mcf_installations = Installationtemplate.all.map(&:InstallationName)
      @selectedins = installationname  
      signalpos = get_mcf_signal_pos(installationname)
      switchpos = get_mcf_switches_pos(installationname)
      hdpos = get_mcf_hd_pos(installationname)
      a = []
      @elementorder =[]
      a[0]= signalpos =="0" ? 0 : signalpos.WSMMsgPosition
      a[1]= switchpos =="0" ? 0 : switchpos.WSMMsgPosition
      a[2]= hdpos =="0" ? 0 : hdpos.WSMMsgPosition
      b =[]
      @sig = Ptcdevice.find(:all , :conditions =>"Id IN(select p.Id from PTCDevice p, Signal h where p.InstallationName='#{installationname}' and p.WSMMsgPosition >0  and p.id=h.id )" , :order =>"WSMMsgPosition")
      @swi = Ptcdevice.find(:all , :conditions =>"Id IN(select p.Id from PTCDevice p, Switch h where p.InstallationName='#{installationname}' and p.WSMMsgPosition >0  and p.id=h.id )" , :order =>"WSMMsgPosition")
      @hd = Ptcdevice.find(:all , :conditions =>"Id IN(select p.Id from PTCDevice p, HazardDetector h where p.InstallationName='#{installationname}' and p.WSMMsgPosition >0  and p.id=h.id )" , :order =>"WSMMsgPosition")
      b[0] = @sig.length
      b[1] = @swi.length
      b[2] = @hd.length
      @ptcdevices = Ptcdevice.find(:all , :conditions =>"InstallationName='#{installationname}' and WSMMsgPosition >0" , :order =>"WSMMsgPosition")
      @deviceOrderflg = checkdevice(@ptcdevices)
      if(@deviceOrderflg == 'true')    
        if ((a[0] >0) && (a[1]>0) && (a[2]>0))
          if((a[0] < a[1]) && (a[1] < a[2]))
            @elementorder[0]=["Signal" ,1]
            @elementorder[1]=["Switch",2]
            @elementorder[2]=["Hazard Detector",3]
          elsif((a[0] < a[2]) && (a[2] < a[1]))
            @elementorder[0]=["Signal" ,1]
            @elementorder[1]=["Hazard Detector",2]
            @elementorder[2]=["Switch",3]                
          elsif((a[1] < a[0]) && (a[0] < a[2]))
            @elementorder[0]=["Switch",1]
            @elementorder[1]=["Signal" ,2]                
            @elementorder[2]=["Hazard Detector",3]
          elsif((a[1] < a[2]) && (a[2] < a[0]))
            @elementorder[0]=["Switch",1]
            @elementorder[1]=["Hazard Detector",2]
            @elementorder[2]=["Signal" ,3]                
          elsif((a[2] < a[1]) && (a[1] < a[0]))
            @elementorder[0]=["Hazard Detector",1]
            @elementorder[1]=["Switch",2]
            @elementorder[2]=["Signal" ,3]
          elsif((a[2] < a[0]) && (a[0] < a[1]))
            @elementorder[0]=["Hazard Detector",1]
            @elementorder[1]=["Signal" ,2]
            @elementorder[2]=["Switch",3]
          end
        elsif((a[0] >0) && (a[1]>0))
          if((a[0] < a[1]))
            @elementorder[0]=["Signal" ,1]
            @elementorder[1]=["Switch",2]
            @elementorder[2]=["Hazard Detector",3]
          else
            @elementorder[0]=["Switch",1]
            @elementorder[1]=["Signal" ,2]                  
            @elementorder[2]=["Hazard Detector",3]
          end
        elsif((a[0] >0) && (a[2]>0))
          if(a[0]<a[2])
            @elementorder[0]=["Signal" ,1]
            @elementorder[1]=["Hazard Detector",2]
            @elementorder[2]=["Switch",3]                  
          else
            @elementorder[0]=["Hazard Detector",1]
            @elementorder[1]=["Signal" ,2]
            @elementorder[2]=["Switch",3]
          end              
        elsif((a[1]>0) && (a[2]>0))
          if(a[1]<a[2])
            @elementorder[0]=["Switch",1] 
            @elementorder[1]=["Hazard Detector",2]
            @elementorder[2]=["Signal" ,3]
          else
            @elementorder[0]=["Hazard Detector",1]
            @elementorder[1]=["Switch",2]
            @elementorder[2]=["Signal" ,3]
          end
        elsif((a[0]>0) && (a[1]==0) && (a[2]==0))
          @elementorder[0]=["Signal" ,1]
          @elementorder[1]=["Switch",2]
          @elementorder[2]=["Hazard Detector",3]
        elsif((a[0]==0) && (a[1]>0) && (a[2]==0))
          @elementorder[0]=["Switch" ,1]
          @elementorder[1]=["Signal",2]
          @elementorder[2]=["Hazard Detector",3]
        elsif((a[0]==0) && (a[1]==0) && (a[2]>0))
          @elementorder[0]=["Hazard Detector" ,1]
          @elementorder[1]=["Signal",2]
          @elementorder[2]=["Switch",3]
        else
          @elementorder[0]=["Signal" ,1]
          @elementorder[1]=["Switch",2]
          @elementorder[2]=["Hazard Detector",3]             
        end
        session[:elementorder] = @elementorder
        @signals = get_mcf_signals(@installation_name) 
        @signals1 = get_mcf_signals_0(@installation_name)
        session[:signalCount] = @signals.length + @signals1.length
        session[:signalCount_inc] = @signals.length
        @switches = get_mcf_switches(@installation_name)
        @switches1 = get_mcf_switches_0(@installation_name)
        session[:switchCount] = @switches.length + @switches1.length
        session[:switchCount_inc] = @switches.length
        @hazarddetectors = get_mcf_hazard_detectors(@installation_name)
        @hazarddetectors1 = get_mcf_hazard_detectors_0(@installation_name)
        session[:hazarddetectorsCount] = @hazarddetectors.length + @hazarddetectors1.length
        session[:hazarddetectorsCount_inc] = @hazarddetectors.length
        goltype = Mcfptc.find(:all, :select => "GOLType").map(&:GOLType)
        if (goltype[0].to_i == 0)
          @aspects = Aspect.select_all_aspectsdetails(@installation_name)
          @ptcaspects =Ptcaspect.select_all_aspectsdetails(@installation_name.to_s)
          session[:aspectsCount] = @aspects.length.to_i-1
        else
          session[:aspectsCount] = nil 
          @aspects = nil
          @ptcaspects = nil
        end
      else
        @elementorder[0]="Error on the order"
      end
    end
  end
  
  def add_new_device(device_type, start_id, end_id, deleted_device_ids)
    ptc_devices = Ptcdevice.find(:last,:select =>"Id", :order => "Id").try(:Id)
    unless ptc_devices.blank?
      newid = ptc_devices.to_i+1
    else
      newid = 1
    end
    
    removed_devices = deleted_device_ids.split('|')
    inst_name = params["installation_name"]

    for device_id in start_id...end_id
      if !removed_devices.include?(device_id.to_s)
        sitedeviceid    = params["#{device_type}_sitedeviceid_#{device_id}"]
        device_name     = params["#{device_type}_device_name_#{device_id}"]
        subnode         = params["#{device_type}_subnode_#{device_id}"]
        tracknumber     = (params["#{device_type}_tracknumber_#{device_id}"].blank?) ? "" : ((params["#{device_type}_tracknumber_#{device_id}"].downcase == "not set") ? "" : params["#{device_type}_tracknumber_#{device_id}"])
        trackname       = (params["#{device_type}_trackname_#{device_id}"].blank?) ? "" : ((params["#{device_type}_trackname_#{device_id}"].downcase == "not set") ? "" : params["#{device_type}_trackname_#{device_id}"])
        direction       = params["#{device_type}_direction_#{device_id}"]
        milepost        = params["#{device_type}_milepost_#{device_id}"]
        subdivnumber    = params["#{device_type}_subdivisionnumber_#{device_id}"]
        sitename        = params["#{device_type}_sitename_#{device_id}"]
        description     = params["#{device_type}_description_#{device_id}"]

        if (device_name.length > 0)  
          Ptcdevice.create_device(newid,tracknumber,trackname,device_name,inst_name,sitedeviceid,subnode,direction,milepost,subdivnumber,sitename,description)
          
          case device_type
            when "signal"
              Signals.create_signal(newid,0,0)
            when "switch"
              Switch.create_switch(newid,0,0)
            when "hazarddetector"
              Hazarddetector.create_hazard(newid,0)
          end
          newid = newid + 1
        end
      end
   end

  end
  
  def delete_device(device_list)
   strdevices =  device_list.split('|');
   device_count = strdevices.size
   new_device_ids = ""
   if (device_count > 0)
     for device_ind in 0..device_count-1
       device = strdevices[device_ind].to_s.split('_')
       if device.size == 3
         device_id = device[2].to_i
         case device[0].to_s
            when "signal"
              Signals.delete_all("Id='#{device_id}'")
            when "switch"
              Switch.delete_all("Id='#{device_id}'")
            when "hazarddetector"
              Hazarddetector.delete_all("Id='#{device_id}'")           
         end
         Ptcdevice.delete_all("Id='#{device_id}'")
       elsif device.size == 4
         new_device_ids = new_device_ids + '|' + device[3].to_s         
       end
     end

   end
    return new_device_ids
  end
    
end
