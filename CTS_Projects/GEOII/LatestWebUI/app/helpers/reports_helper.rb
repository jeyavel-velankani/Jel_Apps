####################################################################
# Company : Siemens 
# Author  : Jeyavel Natesan
# File    : reports_helper.rb
# Description : This is the support file for OCE. 
#               this module is used to get the device details for PTC Message layout , Device attribute pages 
####################################################################
module ReportsHelper
  ####################################################################
  # Function:      get_mcf_signal_pos
  # Parameters:    installation_name
  # Retrun:        result
  # Renders:       None
  # Description:   Get all signals using selected installation name from the signals table  
  ####################################################################
  def get_mcf_signal_pos(installation_name)
    signals = Ptcdevice.find_by_sql("select p.Id , p.WSMMsgPosition from PTCDevice p inner join Signal s on s.Id=p.Id and p.WSMMsgPosition >0  and p.InstallationName='"+installation_name+"' order by p.WSMMsgPosition LIMIT 1")
    if signals[0] !=nil
      result = signals[0]
    else
      result = "0"
    end
    return result
  end
  
  ####################################################################
  # Function:      get_mcf_signal_pos_device_attribute
  # Parameters:    installation_name
  # Retrun:        result
  # Renders:       None
  # Description:   Get signal position details from the ptcdevice table
  ####################################################################
  def get_mcf_signal_pos_device_attribute(installation_name)
    signals = Ptcdevice.find_by_sql("select p.Id , p.WSMMsgPosition from PTCDevice p inner join Signal s on s.Id=p.Id and p.InstallationName='"+installation_name+"' order by p.WSMMsgPosition LIMIT 1")
    if signals[0] !=nil
      result = signals[0]
    else
      result = "0"
    end
    return result
  end
  
  ####################################################################
  # Function:      get_mcf_switches_pos
  # Parameters:    installation_name
  # Retrun:        result
  # Renders:       None
  # Description:   Get all switches using selected installation name from the ptcdevice table  
  #################################################################### 
  def get_mcf_switches_pos(installation_name)
    switches = Ptcdevice.find_by_sql("select p.Id , p.WSMMsgPosition from PTCDevice p inner join Switch  s on s.Id=p.Id and p.WSMMsgPosition >0  and p.InstallationName='"+installation_name+"' order by p.WSMMsgPosition LIMIT 1")
    if switches[0]!=nil
      result = switches[0]
    else
      result = "0"
    end
    return result
  end
  
  ####################################################################
  # Function:      get_mcf_switches_pos_device_attribute
  # Parameters:    installation_name
  # Retrun:        result
  # Renders:       None
  # Description:   Get switches position details using selected installation name from the ptcdevice table  
  ####################################################################
  def get_mcf_switches_pos_device_attribute(installation_name)
    switches = Ptcdevice.find_by_sql("select p.Id , p.WSMMsgPosition from PTCDevice p inner join Switch  s on s.Id=p.Id and p.InstallationName='"+installation_name+"' order by p.WSMMsgPosition LIMIT 1")
    if switches[0]!=nil
      result = switches[0]
    else
      result = "0"
    end
    return result
  end
  
  ####################################################################
  # Function:      get_mcf_hd_pos
  # Parameters:    installation_name
  # Retrun:        result
  # Renders:       None
  # Description:   Get all hazard detector using selected installation name from the ptcdevice table  
  ####################################################################
  def get_mcf_hd_pos(installation_name)
    hazarddetectors = Ptcdevice.find_by_sql("select p.Id , p.WSMMsgPosition from PTCDevice p inner join HazardDetector s on s.Id=p.Id and p.WSMMsgPosition >0  and p.InstallationName='"+installation_name+"' order by p.WSMMsgPosition LIMIT 1")
    if hazarddetectors[0] !=nil
      result = hazarddetectors[0]
    else
      result = "0"
    end
    return result
  end
  
  ####################################################################
  # Function:      get_mcf_hd_pos_device_attribute
  # Parameters:    installation_name
  # Retrun:        result
  # Renders:       None
  # Description:   Get HD position details using selected installation name from the ptcdevice table  
  ####################################################################
  def get_mcf_hd_pos_device_attribute(installation_name)
    hazarddetectors = Ptcdevice.find_by_sql("select p.Id , p.WSMMsgPosition from PTCDevice p inner join HazardDetector s on s.Id=p.Id and p.InstallationName='"+installation_name+"' order by p.WSMMsgPosition LIMIT 1")
    if hazarddetectors[0] !=nil
      result = hazarddetectors[0]
    else
      result = "0"
    end
    return result
  end
  
  ####################################################################
  # Function:      get_mcf_signals
  # Parameters:    installation_name
  # Retrun:        signals
  # Renders:       None
  # Description:   Get all the signals using the selected installation name 
  #                and return sorted signals ptcdevices by WSMBitPosition 
  ####################################################################
  def get_mcf_signals(installation_name)
    signals = Signals.find_by_sql("select p.Id as id, p.PTCDeviceName as device_name, p.Subnode as subnode, p.WSMBITPosition, p.WSMMsgPosition as element_position, p.TrackNumber as track_number , p.Direction as Direction , p.Milepost as Milepost , p.SubdivisionNumber as SubdivisionNumber ,p.SiteName as SiteName , p.SiteDeviceID as SiteDeviceID , p.Description as Description from Signal s inner join PTCDevice p 
     on s.Id = p.Id and p.WSMMsgPosition > 0 where p.InstallationName Like '"+installation_name+"' order by p.WSMBITPosition ASC")
    return signals.sort!{|a, b| a.WSMBitPosition.to_i <=> b.WSMBitPosition.to_i}
  end
  
  ####################################################################
  # Function:      get_mcf_signals_0
  # Parameters:    installation_name
  # Retrun:        signals
  # Renders:       None
  # Description:   Get all the signals using the selected installation name 
  #                and return sorted signals ptcdevices by WSMBitPosition 
  ####################################################################
  def get_mcf_signals_0(installation_name)
    signals = Signals.find_by_sql("select p.Id as id, p.PTCDeviceName as device_name, p.Subnode as subnode, p.WSMBITPosition, p.WSMMsgPosition as element_position, p.TrackNumber as track_number, p.Direction as Direction , p.Milepost as Milepost , p.SubdivisionNumber as SubdivisionNumber ,p.SiteName as SiteName , p.SiteDeviceID as SiteDeviceID , p.Description as Description from Signal s inner join PTCDevice p 
     on s.Id = p.Id and p.WSMMsgPosition = 0 where p.InstallationName Like '"+installation_name+"' order by p.WSMBITPosition ASC")
    return signals.sort!{|a, b| a.WSMBitPosition.to_i <=> b.WSMBitPosition.to_i}
  end
  
  ####################################################################
  # Function:      get_mcf_signals_device_attributes
  # Parameters:    installation_name
  # Retrun:        signals
  # Renders:       None
  # Description:   Get the signal device details using selected installation name from the ptcdevice table  order by WSMBitPosition
  ####################################################################
  def get_mcf_signals_device_attributes(installation_name)
    signals = Signals.find_by_sql("select p.Id as id, p.PTCDeviceName as device_name, p.Subnode as subnode, p.WSMBITPosition , p.WSMMsgPosition as element_position, p.TrackNumber as track_number, p.TrackName as track_name, p.Direction as Direction , p.Milepost as Milepost , p.SubdivisionNumber as SubdivisionNumber ,p.SiteName as SiteName , p.SiteDeviceID as SiteDeviceID , p.Description as Description from Signal s inner join PTCDevice p 
     on s.Id = p.Id where p.InstallationName Like '"+installation_name+"' order by p.WSMBITPosition ASC")
    return signals.sort!{|a, b| a.WSMBitPosition.to_i <=> b.WSMBitPosition.to_i}
  end
  
  ####################################################################
  # Function:      get_mcf_switches
  # Parameters:    installation_name
  # Retrun:        switches
  # Renders:       None
  # Description:   Get all the switches device values from the ptcdevice table order by WSMBitPosition
  ####################################################################
  def get_mcf_switches(installation_name)
    switches = Switch.find_by_sql("select p.Id as id, p.PTCDeviceName as device_name, 
   p.Subnode as subnode, p.WSMBITPosition,  p.WSMMsgPosition as element_position, p.TrackNumber as track_number , p.Direction as Direction , p.Milepost as Milepost , p.SubdivisionNumber as SubdivisionNumber ,p.SiteName as SiteName , p.SiteDeviceID as SiteDeviceID , p.Description as Description from Switch s inner join PTCDevice p 
   on s.Id = p.Id and p.WSMMsgPosition >0 where p.InstallationName Like '"+installation_name+"' order by p.WSMBITPosition ASC")
    return switches.sort!{|a, b| a.WSMBitPosition.to_i <=> b.WSMBitPosition.to_i}
  end
  
  ####################################################################
  # Function:      get_mcf_switches_0
  # Parameters:    installation_name
  # Retrun:        switches
  # Renders:       None
  # Description:   Get all the switch device values from the ptcdevice table order by WSMBitPosition
  ####################################################################
  def get_mcf_switches_0(installation_name)
    switches = Switch.find_by_sql("select p.Id as id, p.PTCDeviceName as device_name, 
   p.Subnode as subnode, p.WSMBITPosition , p.WSMMsgPosition as element_position, p.TrackNumber as track_number , p.Direction as Direction , p.Milepost as Milepost , p.SubdivisionNumber as SubdivisionNumber ,p.SiteName as SiteName , p.SiteDeviceID as SiteDeviceID , p.Description as Description from Switch s inner join PTCDevice p 
   on s.Id = p.Id and p.WSMMsgPosition =0 where p.InstallationName Like '"+installation_name+"' order by p.WSMBITPosition ASC")
    return switches.sort!{|a, b| a.WSMBitPosition.to_i <=> b.WSMBitPosition.to_i}
  end
  
  ####################################################################
  # Function:      get_mcf_switches_device_attributes
  # Parameters:    installation_name
  # Retrun:        switches
  # Renders:       None
  # Description:   Get all the switch device values from the ptcdevice table order by WSMBitPosition
  ####################################################################
  def get_mcf_switches_device_attributes(installation_name)
    switches = Switch.find_by_sql("select p.Id as id, p.PTCDeviceName as device_name, 
   p.Subnode as subnode, p.WSMBITPosition,  p.WSMMsgPosition as element_position, p.TrackNumber as track_number,p.TrackName as track_name  , p.Direction as Direction , p.Milepost as Milepost , p.SubdivisionNumber as SubdivisionNumber ,p.SiteName as SiteName , p.SiteDeviceID as SiteDeviceID , p.Description as Description from Switch s inner join PTCDevice p 
   on s.Id = p.Id where p.InstallationName Like '"+installation_name+"' order by p.WSMBITPosition ASC")
    return switches.sort!{|a, b| a.WSMBitPosition.to_i <=> b.WSMBitPosition.to_i}
  end
  
  ####################################################################
  # Function:      get_mcf_hazard_detectors
  # Parameters:    installation_name
  # Retrun:        hazarddetectors
  # Renders:       None
  # Description:   Get all the hazard detector device values from the ptcdevice table order by WSMBitPosition
  ####################################################################
  def get_mcf_hazard_detectors(installation_name)
    hazarddetectors = Hazarddetector.find_by_sql("select p.Id as id, p.PTCDeviceName as device_name, 
   p.Subnode as subnode, p.WSMBITPosition,  p.WSMMsgPosition as element_position, p.TrackNumber as track_number , p.Direction as Direction , p.Milepost as Milepost , p.SubdivisionNumber as SubdivisionNumber ,p.SiteName as SiteName , p.SiteDeviceID as SiteDeviceID , p.Description as Description from HazardDetector s inner join PTCDevice p 
   on s.Id = p.Id and p.WSMMsgPosition >0 where p.InstallationName Like '"+installation_name+"' order by p.WSMBITPosition ASC")
    return hazarddetectors.sort!{|a, b| a.WSMBitPosition.to_i <=> b.WSMBitPosition.to_i}
  end
  
  ####################################################################
  # Function:      get_mcf_hazard_detectors_0
  # Parameters:    installation_name
  # Retrun:        hazarddetectors
  # Renders:       None
  # Description:   Get all the hazard detector device values from the ptcdevice table order by WSMBitPosition
  ####################################################################
  def get_mcf_hazard_detectors_0(installation_name)
    hazarddetectors = Hazarddetector.find_by_sql("select p.Id as id, p.PTCDeviceName as device_name, 
   p.Subnode as subnode, p.WSMBITPosition,  p.WSMMsgPosition as element_position, p.TrackNumber as track_number , p.Direction as Direction , p.Milepost as Milepost , p.SubdivisionNumber as SubdivisionNumber ,p.SiteName as SiteName , p.SiteDeviceID as SiteDeviceID , p.Description as Description from HazardDetector s inner join PTCDevice p 
   on s.Id = p.Id and p.WSMMsgPosition = 0 where p.InstallationName Like '"+installation_name+"' order by p.WSMBITPosition ASC")
    return hazarddetectors.sort!{|a, b| a.WSMBitPosition.to_i <=> b.WSMBitPosition.to_i}
  end
  
  ####################################################################
  # Function:      get_mcf_hazard_detectors_device_attributes
  # Parameters:    installation_name
  # Retrun:        hazarddetectors
  # Renders:       None
  # Description:   Get all the hazard detector device values from the ptcdevice table order by WSMBitPosition
  ####################################################################
  def get_mcf_hazard_detectors_device_attributes(installation_name)
    hazarddetectors = Hazarddetector.find_by_sql("select p.Id as id, p.PTCDeviceName as device_name, 
   p.Subnode as subnode, p.WSMBITPosition,  p.WSMMsgPosition as element_position, p.TrackNumber as track_number, p.TrackName as track_name , p.Direction as Direction , p.Milepost as Milepost , p.SubdivisionNumber as SubdivisionNumber ,p.SiteName as SiteName , p.SiteDeviceID as SiteDeviceID , p.Description as Description from HazardDetector s inner join PTCDevice p 
   on s.Id = p.Id where p.InstallationName Like '"+installation_name+"' order by p.WSMBITPosition ASC")
    return hazarddetectors.sort!{|a, b| a.WSMBitPosition.to_i <=> b.WSMBitPosition.to_i}
  end
  
  ####################################################################
  # Function:      get_mcf_signals_order
  # Parameters:    params[:errorflag] , params[:errorflag] ,params[:success]
  # Retrun:        @selected_geoaspectfile , @selected_ptcaspectfile
  # Renders:       None
  # Description:   Get all the signals device details from the selected installation name order by Id
  ####################################################################
  def get_mcf_signals_order(installation_name)
    signals = Signals.find_by_sql("select p.Id as id, p.PTCDeviceName as device_name, p.Subnode as subnode, p.WSMBITPosition, p.WSMMsgPosition as element_position, p.TrackNumber as track_number from Signal s inner join PTCDevice p 
     on s.Id = p.Id where p.InstallationName Like '"+installation_name+"' and p.WSMMsgPosition >0  order by p.Id ASC")
    return signals 
  end
  
  ####################################################################
  # Function:      get_mcf_switches_order
  # Parameters:    installation_name
  # Retrun:        switches
  # Renders:       None
  # Description:   Get all the switches device details from the selected installation name order by Id
  ####################################################################
  def get_mcf_switches_order(installation_name)
    switches = Switch.find_by_sql("select p.Id as id, p.PTCDeviceName as device_name, 
   p.Subnode as subnode, p.WSMBITPosition, p.TrackNumber as track_number from Switch s inner join PTCDevice p 
   on s.Id = p.Id where p.InstallationName Like '"+installation_name+"' and p.WSMMsgPosition >0  order by p.Id ASC")
    return switches 
  end
  
  ####################################################################
  # Function:      get_mcf_hazard_detectors_order
  # Parameters:    installation_name
  # Retrun:        hazard_detectors
  # Renders:       None
  # Description:   Get all the hazard detector device details from the selected installation name by Id
  ####################################################################
  def get_mcf_hazard_detectors_order(installation_name)
    hazard_detectors = Hazarddetector.find_by_sql("select p.Id as id, p.PTCDeviceName as device_name,
   p.Subnode as subnode, p.TrackNumber as track_number from HazardDetector s inner join PTCDevice p 
   on s.Id = p.Id where p.InstallationName Like '"+installation_name+"' and p.WSMMsgPosition >0  order by p.Id ASC") 
    return hazard_detectors  
  end
  
  ####################################################################
  # Function:      get_mcf_aspects
  # Parameters:    installation_name
  # Retrun:        Ptcaspect
  # Renders:       None
  # Description:   Get the aspect values from the PTC aspect table
  ####################################################################
  def get_mcf_aspects(installation_name)
    mcf_names = Ptcdevice.all(:conditions => {:InstallationName => installation_name}, :select => "distinct InstallationName")
    return Ptcaspect.all(:conditions => {:InstallationName => mcf_names.map(&:InstallationName)}, :order => "InstallationName desc")
  end
  
  ####################################################################
  # Function:      order_elements_positions
  # Parameters:    params[:installation_name]
  # Return:        None
  # Renders:       None
  # Description:   Order the elements positions values 
  ####################################################################
  def order_elements_positions
    begin
      installationname = params[:installation_name].blank? ? Installationtemplate.find(:first).try(:InstallationName) : params[:installation_name]
      @sig = Ptcdevice.find(:all , :conditions =>"Id IN(select p.Id from PTCDevice p, Signal h where p.InstallationName='#{installationname}' and p.WSMMsgPosition >0 and p.id=h.id order by p.id)", :order =>"WSMMsgPosition")
      @swi = Ptcdevice.find(:all , :conditions =>"Id IN(select p.Id from PTCDevice p, Switch h where p.InstallationName='#{installationname}' and p.WSMMsgPosition >0 and p.id=h.id order by p.id)", :order =>"WSMMsgPosition")
      @hd  = Ptcdevice.find(:all , :conditions =>"Id IN(select p.Id from PTCDevice p, HazardDetector h where p.InstallationName='#{installationname}' and p.WSMMsgPosition >0 and p.id=h.id order by p.id)", :order =>"WSMMsgPosition")
      @count =1
      iStartBitPos = 0;
      @elementorder =[]
      unless session[:elementorder].blank? 
        @elementorder = session[:elementorder]
      else
        @elementorder[0]=["Signal" ,1]
        @elementorder[1]=["Switch",2]
        @elementorder[2]=["Hazard Detector",3]
      end
      for i in 0...(@elementorder.length)
        case @elementorder[i][0]
          when 'Signal'
          for i in 0...(@sig.length.to_i)
            Ptcdevice.update_all("WSMMsgPosition = #{@count.to_i}, WSMBitPosition = #{iStartBitPos.to_i}", {:id => @sig[i].Id})
            @count = @count+1
            iStartBitPos = iStartBitPos + 5;
          end
          when 'Switch'
          for i in 0...(@swi.length.to_i)      
            Ptcdevice.update_all("WSMMsgPosition = #{@count.to_i}, WSMBitPosition = #{iStartBitPos.to_i}", {:id => @swi[i].Id})
            @count = @count+1
            iStartBitPos = iStartBitPos + 2;
          end
          when 'Hazard Detector'
          for i in 0...(@hd.length.to_i)      
            Ptcdevice.update_all("WSMMsgPosition = #{@count.to_i} , WSMBitPosition = #{iStartBitPos.to_i}", {:id => @hd[i].Id})
            @count = @count+1
            iStartBitPos = iStartBitPos + 1;
          end    
        end        
      end
    rescue Exception => e
      puts e.inspect
      if params[:reoder_refresh_flag] == "true"
        flash[:deviceattr] = e.to_s
      end
    end
  end
  
  
  ####################################################################
  # Function:      format_cell
  # Parameters:    content
  # Retrun:        string
  # Renders:       None
  # Description:   Return the "---" string if the content blank
  ####################################################################
  def format_cell(content)
    content.blank? ? "---" : content
  end
  
  ####################################################################
  # Function:      close_database_connection
  # Parameters:    None
  # Retrun:        None
  # Renders:       None
  # Description:   Close all the database connections
  ####################################################################
  def close_database_connection()
    initial_nvconfigdb = RAILS_ROOT+'/db/Initialdb/iviu/nvconfig.sql3'
     (ActiveRecord::Base.configurations["development"])["database"] = initial_nvconfigdb
     (ActiveRecord::Base.configurations["mcf_db"])["database"] = "db/mcf.db"
     (ActiveRecord::Base.configurations["real_time_db"])["database"] = "db/rt.db"
     (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = "db/Initialdb/iviu/GEOPTC.db"
     (ActiveRecord::Base.configurations["real_time_status_db"])["database"] = 'db/Initialdb/iviu/rtstatus.sql3'
    IntegerParameter.integerparam_update_query("0", 516)       
    StringParameter.stringparam_update_query("", 116)
  end
  
  ####################################################################
  # Function:      connectdatabase
  # Parameters:    session[:cfgsitelocation]
  # Retrun:        None
  # Renders:       None
  # Description:   Connect the mcf, rt , nvconfig.sql3 , rtstatus.sql3 database
  ####################################################################
  def connectdatabase()
    typeOfSystem = session[:typeOfSystem]
    initialdb_path = ""
    if (typeOfSystem == "iVIU PTC GEO" || typeOfSystem == "iVIU" || typeOfSystem == "VIU")
      initialdb_path = "#{RAILS_ROOT}/db/Initialdb/iviu"  
    elsif (typeOfSystem == "GEO" || typeOfSystem == "CPU-III")
      initialdb_path = "#{RAILS_ROOT}/db/Initialdb/geo"
    elsif (typeOfSystem == "GCP")
      initialdb_path = "#{RAILS_ROOT}/db/Initialdb/gcp"
    end
    
    if (!(File.exists?(session[:cfgsitelocation]+'/nvconfig.sql3')))
      FileUtils.cp(initialdb_path + "/nvconfig.sql3", session[:cfgsitelocation] + "/nvconfig.sql3")
    end

   (ActiveRecord::Base.configurations["development"])["database"] = session[:cfgsitelocation]+'/nvconfig.sql3'
    
    if (!File.exists?(session[:cfgsitelocation]+'/rtstatus.sql3'))
      FileUtils.cp(initialdb_path + "/rtstatus.sql3", session[:cfgsitelocation] + "/rtstatus.sql3")
      if (typeOfSystem == "iVIU PTC GEO" || typeOfSystem == "iVIU")
        (ActiveRecord::Base.configurations["real_time_status_db"])["database"] = session[:cfgsitelocation]+'/rtstatus.sql3'
        Generalststistics.update_ptc_enable
      end
    end
    (ActiveRecord::Base.configurations["real_time_status_db"])["database"] = session[:cfgsitelocation]+'/rtstatus.sql3'
    
    if File.exists?(session[:cfgsitelocation]+'/mcf.db')
     (ActiveRecord::Base.configurations["mcf_db"])["database"] = session[:cfgsitelocation]+'/mcf.db'  
    end
    
    if File.exists?(session[:cfgsitelocation]+'/rt.db')
     (ActiveRecord::Base.configurations["real_time_db"])["database"] = session[:cfgsitelocation]+'/rt.db'
    end
  end
  
  ####################################################################
  # Function:      get_rc2keybin_crc_values
  # Parameters:    None
  # Retrun:        session[:rc2keycrc] , @emp
  # Renders:       None
  # Description:   Get the RC2Key CRC & values from the RC2KEY.BIN file
  ####################################################################
  def get_rc2keybin_crc_values()
      if OCE_MODE == 1
        rc2bin_path = session[:cfgsitelocation] +"/rc2key.bin"
      else
        rc2bin_path = "/usr/safetran/ecd/0/rc2key.bin"
      end
      rc2Key_crc = []
      if File.exists?(rc2bin_path)
        rc2Keybin  = File.open(rc2bin_path, "rb")
        rc2Keybin_values = rc2Keybin.read
        calculated_rc2key_values_crc = calculate_rc2key_vales_crc(rc2Keybin_values, 20, 0)
        if rc2Keybin_values.include? "CRC:"
          rc2Key_crc = rc2Keybin_values.split('CRC:')
          unless rc2Key_crc[1].blank?
            if calculated_rc2key_values_crc.hex != rc2Key_crc[1].hex
              session[:rc2keycrc] = "Invalid Rc2key file!"
            else
              session[:rc2keycrc] = "CRC:#{rc2Key_crc[1].to_s}"
            end
          else
            session[:rc2keycrc] = "No CRC"
          end
        else
          session[:rc2keycrc] = "No CRC"
        end
        return rc2Key_crc[0].to_s
      else
        session[:rc2keycrc] = "No Rc2key file found"
         return 'file not found'
      end
      return ""
  end  
  
  ####################################################################
  # Function:      connectgeoptcmasterdb
  # Parameters:    session[:mantmasterdblocation]
  # Retrun:        None
  # Renders:       None
  # Description:   Connect the selected GEO PTC Master database connection
  ####################################################################
  def connectgeoptcmasterdb()
    unless session[:mantmasterdblocation].blank?
     (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:mantmasterdblocation]  
    end
  end
  
  ####################################################################
  # Function:      converttowindowspath
  # Parameters:    path
  # Retrun:        windowspath
  # Renders:       None
  # Description:   Convert to the Windows path format
  ####################################################################
  def converttowindowspath(path)
    windowspath =""
    unless path.blank?
      arrayvalue = path.split('/')
      windowspath = arrayvalue.join("\\\\") 
    end
    return windowspath
  end
  
  ####################################################################
  # Function:      validatemcfrtdatabase
  # Parameters:    path
  # Retrun:        session[:validmcfrtdb]
  # Renders:       None
  # Description:   Validate the mcf database
  ####################################################################
  def validatemcfrtdatabase(path)
    session[:validmcfrtdb] = false
    if File.exists?(path+'/mcf.db') && File.exists?(path+'/rt.db')
      if (File.size(path+'/mcf.db') > 0) && (File.size(path+'/rt.db') >0)
        mcfstatus = Mcf.find(:all,:select =>"mcf_status").map(&:mcf_status)
        rtdbvalue = Uistate.find(:all,:select =>"value" , :conditions =>['name=?',"Database completed"]).map(&:value)
        if mcfstatus[0].to_i ==1 && rtdbvalue[0].to_i == 1
          session[:validmcfrtdb] = true
        end
      end
    end
  end
  
  ####################################################################
  # Function:      current_geoaspectfile
  # Parameters:    None
  # Retrun:        PATH
  # Renders:       None
  # Description:   Get the current geo aspect file selected path from the ui_configuration.yml
  ####################################################################
  def current_geoaspectfile
    config = YAML.load_file(RAILS_ROOT+"/config/ui_configuration.yml")
    geo_aspect_filename = config["oce"]["geo_aspect_file"]
    aspect_file_path = ""
    unless geo_aspect_filename.blank?
      aspect_file_path = "#{RAILS_ROOT}/doc/geo_aspects/#{geo_aspect_filename}"
    end
    return aspect_file_path
  end
  
  ####################################################################
  # Function:      current_ptcaspectfile
  # Parameters:    None
  # Retrun:        Path
  # Renders:       None
  # Description:   Get the current ptc aspect file selected path from the ui_configuration.yml
  ####################################################################
  def current_ptcaspectfile
    config = YAML.load_file(RAILS_ROOT+"/config/ui_configuration.yml")
    ptc_aspect_filename = config["oce"]["ptc_aspect_file"]
    ptc_aspect_file_path = ""
    unless ptc_aspect_filename.blank?
      ptc_aspect_file_path = "#{RAILS_ROOT}/doc/ptc_aspects/#{ptc_aspect_filename}"
    end
    return ptc_aspect_file_path
  end
  
  ####################################################################
  # Function:      check_aspectfile_iviuptcgeo
  # Parameters:    None
  # Retrun:        @aspect_file_error
  # Renders:       None
  # Description:   Check the aspectlookup file availablity & default name availablity in ui_configuration.yml
  ####################################################################  
  def check_aspectfile_iviuptcgeo
    geo_aspect_dir = "#{RAILS_ROOT}/doc/geo_aspects/"
    ptc_aspect_dir = "#{RAILS_ROOT}/doc/ptc_aspects/"
    geo_asp_files = []
    ptc_asp_files = []
    if (File.exists?(geo_aspect_dir))
      geo_asp_files = Dir[geo_aspect_dir+"/*.txt"]
    end
    if (File.exists?(ptc_aspect_dir))    
      ptc_asp_files = Dir[ptc_aspect_dir+"/*.txt"]
    end
    if (geo_asp_files.blank? || ptc_asp_files.blank?)
      session[:aspectfilepath]  = ""
      return "Aspectlookup table files are not available. Do you want to upload?" + " <a href='/aspectlookup/index' class = 'upload_config'><img src='/images/upload.png' style='width:auto;'></img></a>"
    end
    
    current_geo_aspect_file_path = current_geoaspectfile
    current_ptc_aspect_file_path = current_ptcaspectfile
    if(File.exists?(current_geo_aspect_file_path))
      session[:aspectfilepath]  = current_geo_aspect_file_path
    else
      session[:aspectfilepath]  = ""
    end
    
    if(current_geo_aspect_file_path.blank? || current_ptc_aspect_file_path.blank? || !File.exists?(current_geo_aspect_file_path) || !File.exists?(current_ptc_aspect_file_path))
      return "No Aspectlookup table files selected, Do you want to select the Aspectlookup tables?" + " <a href='/aspectlookup/index' class = 'upload_config'><img src='/images/select.png' style='width:auto;'></img></a>"
    end
    return ""
  end
  
  ####################################################################
  # Function:      check_databaseschema
  # Parameters:    session[:cfgsitelocation]
  # Retrun:        return_val
  # Renders:       None
  # Description:   Check the site ptc database schema details
  ####################################################################
  def check_databaseschema
   (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:cfgsitelocation]+'/site_ptc_db.db'
    return_val = Signals.columns.map(&:name).include?('AspectId1')
    return return_val
  end
  
  ####################################################################
  # Function:      selectmcftypename
  # Parameters:    mcftypename
  # Retrun:        string
  # Renders:       None
  # Description:   Get the MCF Name lable for the selected product type
  ####################################################################
  def selectmcftypename(mcftypename)
    case mcftypename
      when "iVIU"   
      return "iVIU MCF"  
      when  "iVIU PTC GEO"
      return "iVIU MCF" 
      when "VIU"
      return "VIU MCF" 
      when "GEO"
      return "GEO MCF"
      when "CPU-III"
      return "CPU-III MCF"
      when "GCP"
      return "GCP MCF"
    end
  end

  def calculate_rc2key_vales_crc(datavalue, size, startcrc)
    listExpr = Array.new
    counter = 0
    datavalue.each_byte do |c|
      listExpr[counter] = c
      counter=counter+1
    end
    crc = startcrc
    for i in 0...size
      crc = (crc << 8) ^ ($emp32_crc[((crc >> (24)) ^ listExpr[i])&0x000000FF])  
    end
    crc = crc & 0xFFFFFFFF    
    return crc.to_s(16).upcase
  end
  
  $emp32_crc = [0x00000000,  0x00001021,  0x00002042,  0x00003063,
                0x00004084,  0x000050A5,  0x000060C6,  0x000070E7,
                0x00008108,  0x00009129,  0x0000A14A,  0x0000B16B,
                0x0000C18C,  0x0000D1AD,  0x0000E1CE,  0x0000F1EF,
                0x00010210,  0x00011231,  0x00012252,  0x00013273,
                0x00014294,  0x000152B5,  0x000162D6,  0x000172F7,
                0x00018318,  0x00019339,  0x0001A35A,  0x0001B37B,
                0x0001C39C,  0x0001D3BD,  0x0001E3DE,  0x0001F3FF,
                0x00020420,  0x00021401,  0x00022462,  0x00023443,
                0x000244A4,  0x00025485,  0x000264E6,  0x000274C7,
                0x00028528,  0x00029509,  0x0002A56A,  0x0002B54B,
                0x0002C5AC,  0x0002D58D,  0x0002E5EE,  0x0002F5CF,
                0x00030630,  0x00031611,  0x00032672,  0x00033653, 
                0x000346B4,  0x00035695,  0x000366F6,  0x000376D7,
                0x00038738,  0x00039719,  0x0003A77A,  0x0003B75B,
                0x0003C7BC,  0x0003D79D,  0x0003E7FE,  0x0003F7DF,
                0x00040840,  0x00041861,  0x00042802,  0x00043823,
                0x000448C4,  0x000458E5,  0x00046886,  0x000478A7,
                0x00048948,  0x00049969,  0x0004A90A,  0x0004B92B, 
                0x0004C9CC,  0x0004D9ED,  0x0004E98E,  0x0004F9AF,
                0x00050A50,  0x00051A71,  0x00052A12,  0x00053A33,
                0x00054AD4,  0x00055AF5,  0x00056A96,  0x00057AB7,
                0x00058B58,  0x00059B79,  0x0005AB1A,  0x0005BB3B, 
                0x0005CBDC,  0x0005DBFD,  0x0005EB9E,  0x0005FBBF,
                0x00060C60,  0x00061C41,  0x00062C22,  0x00063C03,
                0x00064CE4,  0x00065CC5,  0x00066CA6,  0x00067C87,
                0x00068D68,  0x00069D49,  0x0006AD2A,  0x0006BD0B, 
                0x0006CDEC,  0x0006DDCD,  0x0006EDAE,  0x0006FD8F,
                0x00070E70,  0x00071E51,  0x00072E32,  0x00073E13,
                0x00074EF4,  0x00075ED5,  0x00076EB6,  0x00077E97,
                0x00078F78,  0x00079F59,  0x0007AF3A,  0x0007BF1B,
                0x0007CFFC,  0x0007DFDD,  0x0007EFBE,  0x0007FF9F,
                0x00081080,  0x000800A1,  0x000830C2,  0x000820E3,
                0x00085004,  0x00084025,  0x00087046,  0x00086067,
                0x00089188,  0x000881A9,  0x0008B1CA,  0x0008A1EB,
                0x0008D10C,  0x0008C12D,  0x0008F14E,  0x0008E16F,
                0x00091290,  0x000902B1,  0x000932D2,  0x000922F3,
                0x00095214,  0x00094235,  0x00097256,  0x00096277,
                0x00099398,  0x000983B9,  0x0009B3DA,  0x0009A3FB,
                0x0009D31C,  0x0009C33D,  0x0009F35E,  0x0009E37F,
                0x000A14A0,  0x000A0481,  0x000A34E2,  0x000A24C3,
                0x000A5424,  0x000A4405,  0x000A7466,  0x000A6447,
                0x000A95A8,  0x000A8589,  0x000AB5EA,  0x000AA5CB,
                0x000AD52C,  0x000AC50D,  0x000AF56E,  0x000AE54F,
                0x000B16B0,  0x000B0691,  0x000B36F2,  0x000B26D3,
                0x000B5634,  0x000B4615,  0x000B7676,  0x000B6657,
                0x000B97B8,  0x000B8799,  0x000BB7FA,  0x000BA7DB, 
                0x000BD73C,  0x000BC71D,  0x000BF77E,  0x000BE75F,
                0x000C18C0,  0x000C08E1,  0x000C3882,  0x000C28A3, 
                0x000C5844,  0x000C4865,  0x000C7806,  0x000C6827,
                0x000C99C8,  0x000C89E9,  0x000CB98A,  0x000CA9AB,
                0x000CD94C,  0x000CC96D,  0x000CF90E,  0x000CE92F,
                0x000D1AD0,  0x000D0AF1,  0x000D3A92,  0x000D2AB3,
                0x000D5A54,  0x000D4A75,  0x000D7A16,  0x000D6A37,
                0x000D9BD8,  0x000D8BF9,  0x000DBB9A,  0x000DABBB,
                0x000DDB5C,  0x000DCB7D,  0x000DFB1E,  0x000DEB3F,
                0x000E1CE0,  0x000E0CC1,  0x000E3CA2,  0x000E2C83,
                0x000E5C64,  0x000E4C45,  0x000E7C26,  0x000E6C07,
                0x000E9DE8,  0x000E8DC9,  0x000EBDAA,  0x000EAD8B,
                0x000EDD6C,  0x000ECD4D,  0x000EFD2E,  0x000EED0F,
                0x000F1EF0,  0x000F0ED1,  0x000F3EB2,  0x000F2E93, 
                0x000F5E74,  0x000F4E55,  0x000F7E36,  0x000F6E17,
                0x000F9FF8,  0x000F8FD9,  0x000FBFBA,  0x000FAF9B,
                0x000FDF7C,  0x000FCF5D,  0x000FFF3E,  0x000FEF1F
                ];
  


end
