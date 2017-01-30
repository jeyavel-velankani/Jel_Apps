####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: SelectsiteHelper.rb
# Description: Support file for OCE configuration editor page  
####################################################################
#History:
# Log: /wayside/GEOII/Trunk/Software/WebUI/app/helpers/selectsite_helper.rb
#
# Rev 4668   Sep 30 2013 19:00:00   Jeyavel
# Change the masterdb_location.txt to site_details.yml conversion.
module SelectsiteHelper
  include ReportsHelper
  if OCE_MODE == 1
    require 'win32ole'
    require 'builder'
    require 'rexml/document'
    include REXML
  end
  ####################################################################
  # Function:      readConfigurationfiles
  # Parameters:    locationpath
  # Retrun:        session[:selectedmasterdb] , session[:selectedinstallationname]
  # Renders:       None
  # Description:   Read the site configuration details from the given path
  ####################################################################
  def readConfigurationfiles(locationpath)
    if File.exist?("#{locationpath}/site_details.yml")
      site_details = open_site_details("#{locationpath}/site_details.yml")
      @typeOfSystem = site_details["Site Type"].strip.to_s
      session[:typeOfSystem] = @typeOfSystem
      if session[:typeOfSystem] == "iVIU PTC GEO"
        master_db = site_details["Master Database"].strip.to_s  if !site_details["Master Database"].blank?
        installation_name = site_details["Installation Name"].strip.to_s if !site_details["Installation Name"].blank?
        unless master_db.blank?
          session[:selectedmasterdb] = "#{RAILS_ROOT}/Masterdb/#{master_db}"
        end
        unless installation_name.blank?
          session[:selectedinstallationname] = installation_name
        end
      else
        session[:selectedmasterdb] = ""
        session[:selectedinstallationname] = ""
      end
      session[:mcfCRCValue]= site_details["MCFCRC"].to_s  
      session[:mcfnamefromselected] = site_details["MCF Name"] 
      if session[:typeOfSystem] == "GCP"
        session[:comments]= site_details["Comments"]
      else
        session[:comments]= nil
      end
    end 
  end
  
  ####################################################################
  # Function:      read_existing_configuration_details
  # Parameters:    path
  # Retrun:        None
  # Renders:       None
  # Description:   Read the site configuration details from the 
  #                existing configuration files and upgrade to new
  ####################################################################  
  def read_existing_configuration_details(path)
    masterdbandtypearray = IO.readlines("#{path}/masterdb_location.txt")
    type_of_system = masterdbandtypearray[0].strip.to_s
    site_details_info = {}
    if (File.exist?(session[:cfgsitelocation]+'/nvconfig.sql3'))
     (ActiveRecord::Base.configurations["development"])["database"] = session[:cfgsitelocation]+'/nvconfig.sql3'
      mcf_name = StringParameter.string_select_query(116)
      mcf_crc = IntegerParameter.integer_select_query(516)
    else
      mcf_name = ""
      mcf_crc = 0
    end
    if type_of_system == "iVIU PTC GEO"
      unless masterdbandtypearray[1].blank?
        arr_masterdb = masterdbandtypearray[1].strip.to_s.split('/')
        if arr_masterdb.length > 1
          masterdblocation = File.basename(masterdbandtypearray[1].strip) # get the filename & assign value if masterdatabase path
        else
          masterdblocation = arr_masterdb[0].strip # assign value direct masterdatabase name 
        end
      end
      unless masterdbandtypearray[2].blank?
        selectedinsname = masterdbandtypearray[2].strip.to_s
      end
      site_details_info = {"Site Type" => type_of_system , 
                             "Master Database" => masterdblocation , 
                             "Installation Name" => selectedinsname ,
                             "MCF Name" => mcf_name.strip ,
                             "MCFCRC" => mcf_crc.to_s(16).upcase } 
    else
      site_details_info = {"Site Type" => type_of_system , 
                             "MCF Name" => mcf_name.strip ,
                             "MCFCRC" => mcf_crc.to_s(16).upcase }
    end
    write_site_details(path , site_details_info)
  end
  
  ####################################################################
  # Function:      readucnvalue
  # Parameters:    filepathname
  # Retrun:        returnvalue
  # Renders:       None
  # Description:   Read the UCN Value
  ####################################################################
  def readucnvalue(filepathname)
    returnvalue = ""
    if File.exist?(filepathname)
      File.open(filepathname) do |fp|
        fp.each do |line|
          value  = line.split(":")
          if (value[0].strip == "UCN")
            returnvalue = value[1].strip.to_s
          elsif (value[0].strip == "CRC")
            returnvalue = value[1].strip.to_s
          end
        end
      end
    else
      returnvalue = "0"
    end
    return returnvalue
  end
  
  ####################################################################
  # Function:      createsiteptcdb
  # Parameters:    masterdbloc, installationname
  # Retrun:        siteptcdb
  # Renders:       None
  # Description:   Get the values from Master DB for corresponding selected installation records and then create SitePTC.db
  ####################################################################  
  def createsiteptcdb(masterdbloc, installationname)
    initptcdb = RAILS_ROOT.to_s+"/db/InitialDB/iviu/GEOPTC.db"
    siteptcdb = session[:cfgsitelocation]+"/site_ptc_db.db"
    FileUtils.cp(initptcdb, siteptcdb)
     (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = masterdbloc
    if File.exist?(siteptcdb)
      mcfphysicallayoutvalue = Mcfphysicallayout.find_by_sql("select * from MCFPhysicalLayout where InstallationName='#{installationname}'")
      value =Installationtemplate.find_by_sql("select * from InstallationTemplate where InstallationName='#{installationname}'")
      
      ptcvalues = Ptcdevice.find_by_sql("select * from PTCDevice where InstallationName='#{installationname}' order by Id")
      db = SQLite3::Database.new(siteptcdb)
      db.execute( "Insert into InstallationTemplate values('#{value[0].InstallationName}')" )
      for q in 0..(mcfphysicallayoutvalue.length-1) 
        db.execute( "Insert into MCFPhysicalLayout values('#{mcfphysicallayoutvalue[q].PhysLayoutNumber}','#{mcfphysicallayoutvalue[q].PhysLayoutName}','#{mcfphysicallayoutvalue[q].GCName}','#{mcfphysicallayoutvalue[q].MCFName}','#{mcfphysicallayoutvalue[q].Subnode}','#{mcfphysicallayoutvalue[q].InstallationName}')" )   
      end
      
      for i in 0..(ptcvalues.length-1) 
        tracknumber = ptcvalues[i].TrackNumber == nil ? "null" : ptcvalues[i].TrackNumber
        sitedeviceid = ptcvalues[i].SiteDeviceID.blank? ? ptcvalues[i].PTCDeviceName : ptcvalues[i].SiteDeviceID
        validate_gcname_field = Ptcdevice.columns.map(&:name).include?('GCName')
        if validate_gcname_field
          db.execute( "Insert into PTCDevice (Id ,TrackNumber , WSMMsgPosition , WSMBitPosition , PTCDeviceName , InstallationName , SiteDeviceID , Subnode , Direction , Milepost , SubdivisionNumber , SiteName , GCName) values('#{ptcvalues[i].id}',#{tracknumber},'#{ptcvalues[i].WSMMsgPosition}','#{ptcvalues[i].WSMBitPosition}','#{ptcvalues[i].PTCDeviceName}','#{ptcvalues[i].InstallationName}','#{sitedeviceid}','#{ptcvalues[i].Subnode}' , '#{ptcvalues[i].Direction }' , '#{ptcvalues[i].Milepost }' , '#{ptcvalues[i].SubdivisionNumber }' , '#{ptcvalues[i].SiteName }' , '#{ptcvalues[i].GCName}')" )
        else
          db.execute( "Insert into PTCDevice (Id ,TrackNumber , WSMMsgPosition , WSMBitPosition , PTCDeviceName , InstallationName , SiteDeviceID , Subnode , Direction , Milepost , SubdivisionNumber , SiteName ) values('#{ptcvalues[i].id}',#{tracknumber},'#{ptcvalues[i].WSMMsgPosition}','#{ptcvalues[i].WSMBitPosition}','#{ptcvalues[i].PTCDeviceName}','#{ptcvalues[i].InstallationName}','#{sitedeviceid}','#{ptcvalues[i].Subnode}' , '#{ptcvalues[i].Direction }' , '#{ptcvalues[i].Milepost }' , '#{ptcvalues[i].SubdivisionNumber }' , '#{ptcvalues[i].SiteName }')" )            
        end
      end
      validate_aspectid = Signals.columns.map(&:name).include?('AspectId1')
      signalvalue = nil
      if validate_aspectid
        signalvalue = Signals.find_by_sql("select s.Id , s.NumberOfLogicStates , s.Conditions , s.StopAspect , s.HeadA , s.HeadB , s.HeadC , s.AspectId1 , s.AltAspect1 , s.AspectId2 , s.AltAspect2 , s.AspectId3 , s.AltAspect3  from PTCDevice as p , Signal as s where s.Id = p.Id and p.InstallationName='#{installationname}'")
      else
        signalvalue = Signals.find_by_sql("select s.Id , s.NumberOfLogicStates , s.Conditions , s.StopAspect , s.HeadA , s.HeadB , s.HeadC from PTCDevice as p , Signal as s where s.Id = p.Id and p.InstallationName='#{installationname}'")           
      end
      
      for j in 0..(signalvalue.length-1) 
        stopaspect = signalvalue[j].StopAspect == nil ? "null" : signalvalue[j].StopAspect
        if validate_aspectid
          aspectid1 = signalvalue[j].AspectId1 == nil ? "null" : signalvalue[j].AspectId1
          aspectid2 = signalvalue[j].AspectId2 == nil ? "null" : signalvalue[j].AspectId2
          aspectid3 = signalvalue[j].AspectId3 == nil ? "null" : signalvalue[j].AspectId3
          db.execute( "Insert into Signal (Id , NumberOfLogicStates,Conditions,StopAspect,HeadA,HeadB,HeadC,AspectId1,AltAspect1,AspectId2,AltAspect2,AspectId3,AltAspect3) values('#{signalvalue[j].Id}','#{signalvalue[j].NumberOfLogicStates}','#{signalvalue[j].Conditions}',#{stopaspect},'#{signalvalue[j].HeadA}','#{signalvalue[j].HeadB}','#{signalvalue[j].HeadC}',#{aspectid1},'#{signalvalue[j].AltAspect1}',#{aspectid2},'#{signalvalue[j].AltAspect2}',#{aspectid3},'#{signalvalue[j].AltAspect3}')" )
        else
          db.execute( "Insert into Signal (Id , NumberOfLogicStates , Conditions , StopAspect , HeadA , HeadB , HeadC ) values('#{signalvalue[j].Id}','#{signalvalue[j].NumberOfLogicStates}','#{signalvalue[j].Conditions}',#{stopaspect},'#{signalvalue[j].HeadA}','#{signalvalue[j].HeadB}','#{signalvalue[j].HeadC}')" )
        end
        
      end
      
      switchvalue = Switch.find_by_sql("select s.Id ,s.SwitchType, s.NumberOfLogicStates from PTCDevice as p , Switch as s where s.Id = p.Id and p.InstallationName='#{installationname}'")
      for k in 0..(switchvalue.length-1) 
        db.execute( "Insert into Switch values('#{switchvalue[k].Id}','#{switchvalue[k].SwitchType}','#{switchvalue[k].NumberOfLogicStates}')" )   
      end
      
      hazarddetectorvalue = Hazarddetector.find_by_sql("select h.Id ,h.NumberOfLogicStates from PTCDevice as p , HazardDetector as h where h.Id = p.Id and InstallationName='#{installationname}'")
      for l in 0..(hazarddetectorvalue.length-1) 
        db.execute( "Insert into HazardDetector values('#{hazarddetectorvalue[l].Id}','#{hazarddetectorvalue[l].NumberOfLogicStates}')" )   
      end
      
      mcfnamevalues = Array.new
      mcfnamevalues = Mcfptc.find_by_sql("select m.MCFName, m.CRC, m.GOLType  from MCFPhysicalLayout as mcfp ,PTCDevice as p , MCF as m where mcfp.InstallationName ='#{installationname}' and mcfp.MCFName = m.MCFName  GROUP BY mcfp.MCFName")
      for m in 0..(mcfnamevalues.length-1) 
        db.execute( "Insert into MCF values('#{mcfnamevalues[m].MCFName}','#{mcfnamevalues[m].CRC}','#{mcfnamevalues[m].GOLType}')" )   
      end
      
      logicstatevalue = Array.new
      logicstatevalue=Logicstate.find_by_sql("select l.LogicStateNumber, l.BitPosn, l.ContiguousCount, l.Id from LogicState as l, PTCDevice as p where l.Id=p.Id and p.InstallationName='#{installationname}'")
      for n in 0..(logicstatevalue.length-1)
        db.execute( "Insert into LogicState values('#{logicstatevalue[n].LogicStateNumber}','#{logicstatevalue[n].BitPosn}','#{logicstatevalue[n].ContiguousCount}','#{logicstatevalue[n].Id}')" )   
      end
      
      aspectvalue = Array.new
      aspectvalue=Ptcaspect.find_by_sql("select * from PTCAspect where InstallationName in (select distinct(InstallationName) from PTCDevice where InstallationName='#{installationname}')")
      for o in 0..(aspectvalue.length-1)
        db.execute( "Insert into PTCAspect values('#{aspectvalue[o].PTCCode}','#{aspectvalue[o].AspectName}','#{aspectvalue[o].InstallationName}')" )   
      end
      
      aspect = Array.new
      aspect = Aspect.find_by_sql("select * from Aspect where InstallationName='#{installationname}'")
      for r in 0..(aspect.length-1)
        db.execute( "Insert into Aspect values('#{aspect[r].Index}','#{aspect[r].AspectName}','#{aspect[r].GCName}','#{aspect[r].InstallationName}')" )   
      end
      
      gcfilevalue = Array.new
      gcfilevalue = Gcfile.find_by_sql("select * from GCFile where InstallationName='#{installationname}'")
      for s in 0..(gcfilevalue.length-1)
        db.execute( "Insert into GCFile values('#{gcfilevalue[s].GCName}','#{gcfilevalue[s].InstallationName}')" )   
      end
      
      approvalvalue = Array.new
      approvalvalue = Approval.find_by_sql("select * from Approval where InstallationName='#{installationname}'")
      for t in 0..(approvalvalue.length-1)
        db.execute( "Insert into Approval values('#{approvalvalue[t].InstallationName}','#{approvalvalue[t].Approver}','#{approvalvalue[t].ApprovalDate}','#{approvalvalue[t].ApprovalTime}','#{approvalvalue[t].ApprovalCRC}','#{approvalvalue[t].ApprovalStatus}')" )   
      end
      
      atcsvalue = Array.new
      atcsvalue = Atcsconfig.find_by_sql("select * from ATCSConfig where InstallationName='#{installationname}'")
      for p in 0..(atcsvalue.length-1)
        db.execute( "Insert into ATCSConfig values('#{atcsvalue[p].Subnode}','#{atcsvalue[p].SubnodeName}','#{atcsvalue[p].GCName}','#{atcsvalue[p].UCN}','#{atcsvalue[p].InstallationName}')" ) 
      end
      if Versions.table_exists?
        versions_table_value = Versions.find_by_sql("select * from Versions")
        unless versions_table_value.blank?
          db.execute( "Insert into Versions (Id ,SchemaVersion , ApprovalCRCVersion) values(#{versions_table_value[0].Id},#{versions_table_value[0].SchemaVersion},#{versions_table_value[0].ApprovalCRCVersion})")  
        end
      end
      # Close The SitePTC.DB 
      db.close
      session[:siteptcdblocation] = siteptcdb
       (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:siteptcdblocation]
    end
  end
  
  ####################################################################
  # Function:      clearAllValue_Sessions
  # Parameters:    None
  # Retrun:        None
  # Renders:       None
  # Description:   Clear All Global Session Variable values
  ####################################################################  
  def clearAllValue_Sessions
    session[:s_name] =  nil
    session[:atcs_address] = nil
    session[:m_post] = nil
    session[:dot_num] = nil
    session[:mcfnamefromselected] = nil
    session[:mcfCRCValue] = nil
    session[:cfgsitelocation] = nil
    session[:cfgLocationconpath] = nil
    session[:typeOfSystem] = nil
    session[:selectedinstallationname] = nil
    session[:selectedmasterdb] = nil
    session[:siteptcdblocation] = nil
    session[:sitecreation] = false
    session[:validmcfrtdb] = false
    session[:mcftypename] = nil
    session[:iViuPtcGeoenabled]= false   
    session[:validmcfrtdb] = false
    session[:comments]=nil
    session[:template_enable]=nil
    Dir.chdir(RAILS_ROOT)
  end
  
  ####################################################################
  # Function:      createWIUConfigxmlfile
  # Parameters:    session[:cfgsitelocation]
  # Retrun:        output_string
  # Renders:       None
  # Description:   Generate WIU_config.xml file
  ####################################################################  
  def createWIUConfigxmlfile
    if @typeOfSystem == "VIU"
      viu_siteinfo = read_viu_siteinfo
      viu_emp = read_viu_emp
    end
    milepost =  (@typeOfSystem != "VIU")? StringParameter.get_string_value(1 , "Mile Post") : viu_siteinfo["MILEPOST"]
    session[:wiuconfigxmlfilename] = "WiuConfig-#{milepost}.xml"
    begin
      if File.exists?(session[:cfgsitelocation]+"/#{session[:wiuconfigxmlfilename]}")
        File.delete(session[:cfgsitelocation]+"/#{session[:wiuconfigxmlfilename]}")
      end
      x = DateTime.now
      y = DateTime.new(x.year, x.month, x.day, x.hour, x.min, x.sec, x.sec_fraction, x.offset)
      xml = Builder::XmlMarkup.new(:target=> output_string = "" ,:indent => 2 )
      xml.instruct! :xml, :encoding => "UTF-8"
      xml.WIUConfig("xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xsi:noNamespaceSchemaLocation"=>"WIU_config.xsd") {
        xml.Timestamp y
        wiu_addr = (@typeOfSystem != "VIU") ? StringParameter.get_string_value(31, "EMP Src Addr") : viu_emp["WIU_EMP_HDR_SRC_ADR"] 
        xml.WIUAddress wiu_addr
        
        wiu_name = StringParameter.get_string_value(44 , "WIU Name")
        if !wiu_name.blank?
          xml.WIUName wiu_name
        else
          xml.WIUName "WIU Addr"
        end
        ibeaconflagvalue = EnumParameter.enum_select_query(10)
        if ibeaconflagvalue.to_i == 136
          bBeaconFlag = "Y"
        else
          bBeaconFlag = "N"
        end
        xml.BeaconFlag bBeaconFlag
        hmackey = (@typeOfSystem != "VIU") ? ByteArrayParameter.Bytearray_select_query(1) : viu_emp["EMP_HMAC_KEY"]
        xml.EncryptedHMACkey hmackey.gsub(" ", "")       
        #         PTCUCN.txt
        crcvalue = readucnvalue(session[:cfgsitelocation]+'/PTCUCN.txt')
        crchexvalue = crcvalue.split('x')
        ptcucnvalue = nil
        if crchexvalue.length == 2
          ptcucnvalue = crchexvalue[1].to_s
        elsif crchexvalue.length == 1
          ptcucnvalue = crchexvalue[0].to_s
        end
        xml.LibraryCRC StringParameter.get_string_value(44 , "Library CRC")
        xml.ConfigCRC  ptcucnvalue  #PTCUCN value
        
        site_details = open_site_details("#{session[:cfgsitelocation]}/site_details.yml")
        
        #         MCF NAME
        xml.AppProgramName  site_details["MCF Name"].strip.to_s 
        
        #         MCF CRC        
        xml.AppProgramCRC site_details["MCFCRC"].strip.to_s
        
        xml.DeviceStatusConfigSCAC StringParameter.get_string_value(44 , "Device Status SCAC")
        xml.DeviceStatusConfigTableId IntegerParameter.get_value(44 , "Status Config Table ID")
        xml.DeviceStatusConfigVersion StringParameter.get_string_value(44 , "Status Config Version")
        iTrack_Ind = 0;
        if File.exists?(session[:cfgsitelocation]+'/site_ptc_db.db')   
          mcf_installations = Installationtemplate.all.map(&:InstallationName)
          installation_name = nil
          unless mcf_installations.blank?
            if (mcf_installations.length >1)
              activeinstallation = Gwe.find(:all,:select=>"active_physical_layout").map(&:active_physical_layout)
              installation_name = mcf_installations[activeinstallation[0].to_i-1]
            else
              installation_name = mcf_installations[0]
            end
          else
            installation_name = nil
          end
          unless installation_name.blank?
            defaultsitename = (@typeOfSystem != "VIU")? StringParameter.get_string_value(1 , "Site Name") : viu_siteinfo["SITE_NAME"]
            defaultmilepost = milepost
            defaultdivnumber = StringParameter.get_string_value(44 , "Subdivision Number")
            if defaultdivnumber.blank?
              defaultdivnumber = "Not Set"
            end
            signals = Signals.select_all_signal(installation_name)
            signals.each {|s| 
              currentsignal = Ptcdevice.select_ptcdevice_value(s.Id)
              xml.Signal do |p|
                currentsignal.each {|ptcdevice|
                  sitedeviceid = (ptcdevice.SiteDeviceID.blank?) ? ptcdevice.PTCDeviceName : ptcdevice.SiteDeviceID
                  p.SiteDeviceId sitedeviceid
                  unless ptcdevice.Description.blank?
                    p.Description ptcdevice.Description
                  else
                    p.Description ""
                  end
                  validateolddatabase = Ptcdevice.columns.map(&:name).include?('SiteName')
                  sitename = validateolddatabase ? ((ptcdevice.SiteName.blank?) ? defaultsitename : ptcdevice.SiteName): ""
                  unless sitename.blank?
                    p.SiteName sitename
                  else
                    p.SiteName ""
                  end
                  
                  #track_number = (@typeOfSystem == "VIU")? ((ptcdevice.TrackName.blank?) ? "Not Set" : ptcdevice.TrackName) : ((ptcdevice.TrackNumber.blank?) ? "Not Set" : ptcdevice.TrackNumber)
                  track_number = (ptcdevice.TrackName.blank?) ? "Not Set" : ptcdevice.TrackName
                  p.TrackName track_number
                  
                  validateolddatabase = Ptcdevice.columns.map(&:name).include?('SubdivisionNumber')
                  subdno = validateolddatabase ? ((ptcdevice.SubdivisionNumber.blank?) ? defaultdivnumber : ptcdevice.SubdivisionNumber) : "Not Set"
                  unless subdno.blank?
                    p.SubdivisionNumber subdno
                  else
                    p.SubdivisionNumber ""
                  end
                  validateolddatabase = Ptcdevice.columns.map(&:name).include?('Milepost')
                  milepost = validateolddatabase ? ((ptcdevice.Milepost.blank?) ? defaultmilepost : ptcdevice.Milepost) : ""
                  unless milepost.blank?
                    p.Milepost milepost
                  else
                    p.Milepost ""
                  end
                  p.WIUStatusIndex ptcdevice.WSMBitPosition
                  validateolddatabase = Ptcdevice.columns.map(&:name).include?('Direction')
                  sigdirection = validateolddatabase ? ((ptcdevice.Direction.blank?) ? "Increasing" : ptcdevice.Direction) : ""
                  p.SignalDirection  sigdirection
                  iTrack_Ind = iTrack_Ind + 1
                }
              end
            }
            switchs = Switch.select_all_switch(installation_name)
            switchs.each {|s| 
              currentswitch = Ptcdevice.select_ptcdevice_value(s.Id)
              xml.Switch do |p|
                currentswitch.each {|ptcdevice|
                  sitedeviceid = (ptcdevice.SiteDeviceID.blank?) ? ptcdevice.PTCDeviceName : ptcdevice.SiteDeviceID
                  p.SiteDeviceId sitedeviceid
                  unless ptcdevice.Description.blank?
                    p.Description ptcdevice.Description
                  else
                    p.Description ""
                  end
                  validateolddatabase = Ptcdevice.columns.map(&:name).include?('SiteName')
                  sitename = validateolddatabase ? ((ptcdevice.SiteName.blank?) ? defaultsitename : ptcdevice.SiteName) : ""
                  unless sitename.blank?
                    p.SiteName sitename
                  else
                    p.SiteName ""
                  end
                  track_number =  (@typeOfSystem == "VIU")? ((ptcdevice.TrackName.blank?) ? "Not Set" : ptcdevice.TrackName) : ((ptcdevice.TrackNumber.blank?) ? "Not Set" : ptcdevice.TrackNumber)
                  p.TrackName track_number
                  validateolddatabase = Ptcdevice.columns.map(&:name).include?('SubdivisionNumber')
                  subdno = validateolddatabase ? ((ptcdevice.SubdivisionNumber.blank?) ? defaultdivnumber : ptcdevice.SubdivisionNumber) : "Not Set"
                  unless subdno.blank?
                    p.SubdivisionNumber subdno
                  else
                    p.SubdivisionNumber ""
                  end
                  validateolddatabase = Ptcdevice.columns.map(&:name).include?('Milepost')
                  milepost = validateolddatabase ? ((ptcdevice.Milepost.blank?) ? defaultmilepost : ptcdevice.Milepost) : ""
                  unless milepost.blank?
                    p.Milepost milepost
                  else
                    p.Milepost ""
                  end
                  p.WIUStatusIndex ptcdevice.WSMBitPosition
                  validateolddatabase = Ptcdevice.columns.map(&:name).include?('Direction')
                  swirection = validateolddatabase ? ((ptcdevice.Direction.blank?) ? "LF" : ptcdevice.Direction) : ""  
                  p.SwitchDirection  swirection
                  iTrack_Ind = iTrack_Ind + 1
                }
              end
            }
            hds = Hazarddetector.select_all_hd(installation_name)
            hds.each {|s| 
              currenthd = Ptcdevice.select_ptcdevice_value(s.Id)
              xml.HazardDetector do |p|
                currenthd.each {|ptcdevice|
                  sitedeviceid = (ptcdevice.SiteDeviceID.blank?) ? ptcdevice.PTCDeviceName : ptcdevice.SiteDeviceID
                  p.SiteDeviceId sitedeviceid
                  unless ptcdevice.Description.blank?
                    p.Description ptcdevice.Description
                  else
                    p.Description ""
                  end
                  validateolddatabase = Ptcdevice.columns.map(&:name).include?('SiteName')
                  sitename = validateolddatabase ? ((ptcdevice.SiteName.blank?) ? defaultsitename : ptcdevice.SiteName) : ""
                  unless sitename.blank?
                    p.SiteName sitename
                  else
                    p.SiteName ""
                  end
                  track_number =  (@typeOfSystem == "VIU")? ((ptcdevice.TrackName.blank?) ? "Not Set" : ptcdevice.TrackName) : ((ptcdevice.TrackNumber.blank?) ? "Not Set" : ptcdevice.TrackNumber)
                  p.TrackName track_number
                  validateolddatabase = Ptcdevice.columns.map(&:name).include?('SubdivisionNumber')
                  subdno = validateolddatabase ? ((ptcdevice.SubdivisionNumber.blank?) ? defaultdivnumber : ptcdevice.SubdivisionNumber) : "Not Set"
                  unless subdno.blank?
                    p.SubdivisionNumber subdno
                  else
                    p.SubdivisionNumber ""   
                  end
                  validateolddatabase = Ptcdevice.columns.map(&:name).include?('Milepost')
                  milepost = validateolddatabase ? ((ptcdevice.Milepost.blank?) ? defaultmilepost : ptcdevice.Milepost) : ""
                  unless milepost.blank?
                    p.Milepost milepost
                  else
                    p.Milepost ""
                  end
                  p.WIUStatusIndex ptcdevice.WSMBitPosition
                  validateolddatabase = Ptcdevice.columns.map(&:name).include?('Direction')
                  hddirection = validateolddatabase ? ((ptcdevice.Direction.blank?) ? "Increasing" : ptcdevice.Direction) : ""
                  unless hddirection.blank?
                    p.SignalDirection  hddirection  
                  end                  
                }
              end
            }
          end
        end
      }
      f = File.new(session[:cfgsitelocation]+"/#{session[:wiuconfigxmlfilename]}", "w")
      f.write(output_string)
      f.close
    rescue Exception => e  
      puts e
    end
  end
  
  ####################################################################
  # Function:      open_site_details
  # Parameters:    file_path
  # Retrun:        config
  # Renders:       None
  # Description:   Open site details from the site_details.yml file
  ####################################################################  
  def open_site_details(file_path)
    config = YAML.load_file(file_path)
  end
  
  ####################################################################
  # Function:      write_site_details
  # Parameters:    site_path , site_details_info
  # Retrun:        site_details_info
  # Renders:       None
  # Description:   Write the site details with site_details.yml
  ####################################################################  
  def write_site_details(site_path , site_details_info)
    output = File.new("#{site_path}/site_details.yml", 'w')
    output.puts YAML.dump(site_details_info)
    output.close
  end
  
  ####################################################################
  # Function:      Get_nonvitalconfig_parameters
  # Parameters:    params
  # Retrun:        ret
  # Renders:       None
  # Description:   Get the Non vital configuration parameters
  ####################################################################  
  def Get_nonvitalconfig_parameters(params)
    labelname =params[0]
    titile = params[1]
    value = params[2]
    datatype = params[3]
    enable = params[4]
    show = params[5]
    display_order = params[6]
    default_value = params[7] || nil

    valueid = labelname
    ret ="<div class='nv_config_generic_wrapper' id='#{labelname+'_div'}'>"
    ret += "<div class='nv_row'>"
    ret += "<div class='nv_title'>#{titile}</div>"
    ret += "<div class='dv_input'>"
    if (datatype == "string" || datatype == "integer" || datatype == "bytearray" || datatype == "hex" || datatype == "sin" || datatype == "ip")
      if(datatype == "hex" || datatype == "bytearray")
        value.gsub!(" ", "")
      end
      if valueid == 'MCF_CRC'
        ret += text_field_tag(valueid, value , :class=>"contentCSPsel" , :disabled => true, :onchange => "viu_parameter_validation()",:enable => enable, :show =>show, :display_order =>display_order)
       elsif valueid == 'EMP_RC2_KEY'
        ret += password_field_tag(valueid, value , :class=>"contentCSPsel rc2key_anchor" , :disabled => false, :onchange => "viu_parameter_validation()",:enable => enable, :show =>show, :display_order =>display_order)  
      elsif default_value
        ret += text_field_tag(valueid, value , :class=>"contentCSPsel" , :disabled => false, :onchange => "viu_parameter_validation()", :current_value => value, :default_value => default_value, :display_order =>display_order)
      else
        ret += text_field_tag(valueid, value , :class=>"contentCSPsel" , :disabled => false, :onchange => "viu_parameter_validation()",:enable => enable, :show =>show, :display_order =>display_order)
      end
      @nonvital_params_names[labelname] = ""
    elsif(datatype == "boolean")
      @collectionvalues = [["No","0"] , ["Yes","1"]]
      ret += select_tag(valueid,options_for_select(@collectionvalues, @collectionvalues.map{value}),:class=>"contentCSPsel" ,:disabled => false,:enable => enable, :show =>show, :display_order =>display_order)
    else 
      @collectionvalues = get_collection_of_constant(datatype)
      show_ret = (show != nil ? 'show="'+show.to_s+'"' : '')
      enable_ret = (enable != nil ? 'enable="'+enable.to_s+'"' : '')
      display_order_ret = (display_order != nil ? 'display_order="'+display_order.to_s+'"' : '')

      ret += '<select id="'+valueid.to_s+'" name="'+valueid.to_s+'" class="contentCSPsel" '+enable_ret.to_s+' '+show_ret.to_s+' '+display_order_ret.to_s+'>'
      
      if @collectionvalues != nil
        @collectionvalues.each do |c|
          if c != nil 

            ret += '<option value="'+c[1].to_s+'"'+(c[1]==value ? ' selected': '')+(c[2] != nil ? ' show="'+c[2]+'"' : '')+'>'+c[0]+'</option>'
          end
        end
      end
      ret += '</select>'

      #ret += select_tag(valueid,options_for_select(@collectionvalues, @collectionvalues.map{value}),:class=>"contentCSPsel" ,:disabled => false,:enable => enable, :show =>show, :display_order =>display_order)
    end
    ret += "</div>"
    if @tagname == "4" && labelname == "EMP_RC2_KEY"
      ret += "<div style='float:left;font-size:12px;color: #FFF380;'>&nbsp;&nbsp;&nbsp;" + session[:rc2keycrc] + "</div>"
      ret += "</div></div>"
      ret +="<div class='nv_config_generic_wrapper' id='#{labelname+'_div'}'>"
      ret += "<div class='nv_row'>"
      ret += "<div class='nv_title'>#{titile} Confirm</div>"
      ret += "<div class='dv_input'>"
      ret += password_field_tag('', '', :class=>"contentCSPsel rc2key_Confirm" , :disabled => false,:enable => enable, :show =>show, :display_order =>display_order)  
      ret += "</div>"
    end
    ret += "</div></div>"
  end
  
  ####################################################################
  # Function:      get_collection_of_constant
  # Parameters:    datatype
  # Retrun:        params
  # Renders:       None
  # Description:   Get the constant collections
  ####################################################################  
  def get_collection_of_constant(datatype)
    params = Array.new
    unless datatype.blank?
      path = RAILS_ROOT+'/doc/cfgdef.viu.xml'
      xmlfile = File.new(path)
      xmldoc = Document.new(xmlfile)
      xmldoc.elements.each("*/record[@name='_GLOBAL_CONSTS_']/Enumeration[@name='#{datatype}']") do |element|
        element.elements.each do |e| 
          longname = e.elements["LongName"].text
          val = e.elements["Value"].text
          show = e.attributes["show"]
          params << [longname,val,show]
        end
      end
    end
    return params
  end

  ####################################################################
  # Function:      read_cfgdef_xml
  # Parameters:    nonvital_params_names, tag_value
  # Retrun:        None
  # Renders:       None
  # Description:   Read the default configuration VIU xml file
  ####################################################################  
  def read_cfgdef_xml(nonvital_params_names, tag_value)
    filename = RAILS_ROOT+'/doc/cfgdef.viu.xml'
    xmlfile = File.new(filename)
    xmldoc = Document.new(xmlfile)
    root = xmldoc.root
    root.each_element_with_attribute('tag') do |e| 
      if(e.attributes["tag"].to_i == tag_value.to_i && e.has_elements?)
        e.elements.each do |c|
          if(!nonvital_params_names[c.attributes["name"]].nil?)
            values = { :default => "", :max => "", :min => "", :title => "", :datatype => "", :validate => ""}
            values[:default] = c.attributes["default"] if(c.attributes["default"])
            values[:max] = c.attributes["max"] if(c.attributes["max"])
            values[:min] = c.attributes["min"] if(c.attributes["min"])
            values[:title] = c.attributes["title"] if(c.attributes["title"])
            values[:datatype] = c.attributes["datatype"] if(c.attributes["datatype"])
            values[:validate] = c.attributes["validate"] if(c.attributes["validate"])
            nonvital_params_names[c.attributes["name"]] = values
          end
        end
      end     
    end
    return nonvital_params_names
  end

  ####################################################################
  # Function:      update_viu_siteinfo
  # Parameters:    sitename , mcfcrc
  # Retrun:        None
  # Renders:       None
  # Description:   Update the VIU Site information
  ####################################################################  
  def update_viu_siteinfo(sitename , mcfcrc = nil)
    strmsg = viu_generate_xml(1) 
    if strmsg.blank?
      path = RAILS_ROOT+'/doc/cfgdef.viu.xml'
      filename = getfilename_for_tagname(path, 1)
      resultfilepath = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id]}/xmltemplate/#{filename}.xml"
      if File.exists?(resultfilepath)
        xmlfile = File.new(resultfilepath)
        xmldoc = Document.new(xmlfile)
        root = xmldoc.root
        if(root.attributes["tag"].to_i == 1)
          root.each_element_with_attribute('name') do |e| 
            name = e.attributes["name"]
            if(name == 'SITE_NAME')
              unless sitename.blank?
                e.text = sitename
              end
            elsif (name == 'MCF_CRC')
              unless mcfcrc.blank?
                e.text = mcfcrc
              end
            elsif (name == "SITE_ATCS_ADDR")
              # update sin with RT.db - Site info atcs values 
              update_rt_sin_values(4, e.text.to_s)
            end
          end
        end
        File.open(resultfilepath, 'w') do |result|
          xmldoc.write(result)
        end
        strmsg = viu_update_xml(1, resultfilepath)
      end
    else
      puts "---------- fail----------"
      puts "strmsg: " + strmsg.inspect
    end
  end
  
  ####################################################################
  # Function:      read_viu_siteinfo
  # Parameters:    None
  # Retrun:        site_info_value
  # Renders:       None
  # Description:   Read VIU Site information to display the header
  ####################################################################  
  def read_viu_siteinfo
    return read_viu_nv_config_data(1)
  end
  def read_viu_emp
    return read_viu_nv_config_data(4)
  end
  
  def read_viu_nv_config_data(tagnumber)
    strmsg = viu_generate_xml(tagnumber)
    nvconfig_data = Hash.new
    if strmsg.blank?
      path = RAILS_ROOT+'/doc/cfgdef.viu.xml'
      filename = getfilename_for_tagname(path, tagnumber)
      resultfilepath = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id]}/xmltemplate/#{filename}.xml"
      if File.exists?(resultfilepath)
        xmlfile = File.new(resultfilepath)
        xmldoc = Document.new(xmlfile)
        root = xmldoc.root
        if(root.attributes["tag"].to_i == tagnumber)
          root.each_element_with_attribute('name') do |e| 
            name = e.attributes["name"]
              nvconfig_data[name] =  e.text
          end
        end
        root = nil
        xmldoc = nil
        xmlfile = nil
      end
    end
    return nvconfig_data
  end

  ####################################################################
  # Function:      getfilename_for_tagname
  # Parameters:    mainxmlfilepath, tagname
  # Retrun:        filename
  # Renders:       None
  # Description:   Get the files name according to the tag name from the xml file 
  ####################################################################    
  def getfilename_for_tagname(mainxmlfilepath, tagname)
    xmlfile = File.new(mainxmlfilepath)
    xmldoc = Document.new(xmlfile)
    nameoffile = xmldoc.elements().to_a("*/record[@tag=#{tagname}]").first.attributes["name"]
    filename = nameoffile.titleize.downcase.gsub(/\s+/, "")
    return filename
  end

  ####################################################################
  # Function:      getfilename_for_tagname
  # Parameters:    mainxmlfilepath, tagname
  # Retrun:        filename
  # Renders:       None
  # Description:   Get the files name according to the tag name from the xml file 
  ####################################################################    
  def run_cfgmgr
    session[:cfgmgrportno] = nil
    session[:cfgmgrportno] = cfgmgr_getfreeportno
    cfglocation = session[:cfgsitelocation]+'/nvconfig.bin'
    if File.exist?(cfglocation)
      cfgmgr = "\"#{session[:OCE_ROOT]}\\cfgmgr.exe\" \"#{cfglocation}\" \"#{session[:cfgmgrportno]}\""
      pid = spawn(cfgmgr)
      session[:pid] = pid
      cookies[:pid] = session[:pid]
      return ""
    else
      session[:pid] = nil
      cookies[:pid] = session[:pid]
      return "Non Vital Configuration file was missing in the site configuration folder."
    end 
  end

  ####################################################################
  # Function:      getfilename_for_tagname
  # Parameters:    mainxmlfilepath, tagname
  # Retrun:        filename
  # Renders:       None
  # Description:   Get the files name according to the tag name from the xml file 
  ####################################################################      
  def viu_generate_xml(tag_num)
    xmlfilpath = RAILS_ROOT+'/oce_configuration/'+session[:user_id]+'/xmltemplate/'
    strmsg = nil
    if !File.directory?(xmlfilpath)      
      Dir.mkdir("#{RAILS_ROOT}/oce_configuration/#{session[:user_id]}/xmltemplate")
    end
    
    mainxmlpath = RAILS_ROOT + '/doc/cfgdef.viu.xml'
    readxmlfile = WIN32OLE.new('Cfg2xml_Engine.Cfg2Xml')
    readxmlfile.cfgmgr_port_num = session[:cfgmgrportno].to_i
    readxmlfile.cfgmgr_process_id = session[:pid].to_i
    strmsg = readxmlfile.GenerateXml("#{session[:OCE_ROOT]}", mainxmlpath, tag_num.to_i , xmlfilpath)
    if (readxmlfile.cfgmgr_process_id == 0 && session[:cfgmgr_state] == false)
      strmsg = ""
      strmsg = run_cfgmgr
      session[:cfgmgr_state] = true      
      if strmsg.blank?
        strmsg = viu_generate_xml(tag_num)
      end
    end
    unless strmsg.blank?
      flash[:errormessage] = strmsg
    else
      flash[:errormessage] = nil
    end
    return strmsg
  end

  ####################################################################
  # Function:      getfilename_for_tagname
  # Parameters:    mainxmlfilepath, tagname
  # Retrun:        filename
  # Renders:       None
  # Description:   Get the files name according to the tag name from the xml file 
  ####################################################################      
  def viu_update_xml(tag_num, xmlfilpath)
    strmsg = nil
    readxmlfile = WIN32OLE.new('Cfg2xml_Engine.Cfg2Xml')
    readxmlfile.cfgmgr_port_num = session[:cfgmgrportno].to_i
    readxmlfile.cfgmgr_process_id = session[:pid].to_i
    strmsg = readxmlfile.UpdateNvConfigParams("#{session[:OCE_ROOT]}" , xmlfilpath, tag_num.to_i)
    if (readxmlfile.cfgmgr_process_id == 0)
      strmsg = strmsg + " Please reload the page."
    end
    return strmsg;
  end
  
  ####################################################################
  # Function:      getfilename_for_tagname
  # Parameters:    mainxmlfilepath, tagname
  # Retrun:        filename
  # Renders:       None
  # Description:   Get the files name according to the tag name from the xml file 
  ####################################################################      
  def get_nv_config_ver(system_type)
    db_path = ""
    db_list = []
    db_version = ""
    db_display_name = ""
    if (system_type.upcase == 'IVIU' || system_type == 'IVIU PTC GEO')
      db_path = RAILS_ROOT+'/db/InitialDB/iviu'
    end
    
    case system_type.upcase
      when 'IVIU' then db_path = RAILS_ROOT+'/db/InitialDB/iviu'
      when 'IVIU PTC GEO' then db_path = RAILS_ROOT+'/db/InitialDB/iviu'
      when 'CPU-III' then db_path = RAILS_ROOT+'/db/InitialDB/geo'
      when 'VIU' then db_path = RAILS_ROOT+'/db/InitialDB/viu'
      when 'GEO' then db_path = RAILS_ROOT+'/db/InitialDB/geo'   
    end
    if !db_path.blank?
      Dir.foreach(db_path) do |nv_file|
        if File.fnmatch('nvconfig_*', File.basename(nv_file,'.sql3'))          
          db_version = File.basename(nv_file,'.sql3').gsub('nvconfig_', '')
          db_display_name = db_version.gsub('v','Ver ').gsub('s','.')
          db_list << [db_version, db_display_name]
        end
      end
    end
    
    return db_list
  end
  
  ####################################################################
  # Function:      getfilename_for_tagname
  # Parameters:    mainxmlfilepath, tagname
  # Retrun:        filename
  # Renders:       None
  # Description:   Get the files name according to the tag name from the xml file 
  ####################################################################     
  def get_template(site_type)
    template_dir = "#{RAILS_ROOT}/oce_configuration/templates/"
    if (site_type.downcase == "viu")
      template_path = template_dir + site_type.downcase + "/nvconfig.bin"
    elsif (site_type.downcase == "gcp")
      template_path = "#{template_dir}#{site_type.downcase}/rt.db"
    else
      template_path = template_dir + site_type.downcase + "/nvconfig.sql3"  
    end
    
    if File.exists?(template_path)
      if (site_type.downcase != "gcp")
        # write the function to validate the mcf.db , rt.db , nvconfig.sql3
        return "Template used"    
      end
    else
      return ""
    end
  end

  ####################################################################
  # Function:      getfilename_for_tagname
  # Parameters:    mainxmlfilepath, tagname
  # Retrun:        filename
  # Renders:       None
  # Description:   Get the files name according to the tag name from the xml file 
  ####################################################################    
  def validate_nvconfig(db1, db2)
    db1_conn = SQLite3::Database.new(db1)
    db2_conn = SQLite3::Database.new(db2)
    
    # Get version information from both db's
    db1_version_info = db1_conn.execute('select Product_Name, Platform_Name, Database_Version from Version_Information limit 0,1')
    db2_version_info = db2_conn.execute('select Product_Name, Platform_Name, Database_Version from Version_Information limit 0,1')
    if(!db1_version_info.blank? && !db2_version_info.blank? && (db1_version_info[0][2] != db2_version_info[0][2]))
      if(db1_version_info[0][0] != db2_version_info[0][0] || db1_version_info[0][1] != db2_version_info[0][1])
        return "Error: InValid Non vital configuration(Product name OR Platform name missmatch)."
      end
      return "Warning: Non vital database schema is out of date."
    else
      return "valid"
    end
  end

  ####################################################################
  # Function:      getfilename_for_tagname
  # Parameters:    mainxmlfilepath, tagname
  # Retrun:        filename
  # Renders:       None
  # Description:   Get the files name according to the tag name from the xml file 
  ####################################################################      
  def generate_rc2key(site_type)
    rc2bin_path = "#{session[:cfgsitelocation]}/rc2key.bin"
    rc2_val = ""
    if (site_type.downcase == 'viu')
      viu_emp = read_viu_emp
      if !viu_emp["EMP_RC2_KEY"].blank?
        rc2_val = viu_emp["EMP_RC2_KEY"]
      end
    else
      rc2key_field_val = ByteArrayParameter.get_value(31,"RC2 Key")
      if !rc2key_field_val.Array_Value.blank?
        rc2_val = rc2key_field_val.Array_Value
      end
    end
    begin
      libcic = WIN32OLE.new('CIC_BIN.CICBIN')
      strmsg = libcic.GenerateRc2KeyFile(rc2bin_path , rc2_val)
    rescue Exception => e
      strmsg = "Error:" +e  
    end
    return strmsg
  end
  
  ####################################################################
  # Function:      update_mcf_rt_parameters_and_upgrade_nvconfig
  # Parameters:    mainxmlfilepath, tagname
  # Retrun:        filename
  # Renders:       None
  # Description:   Get the files name according to the tag name from the xml file 
  ####################################################################    
  def update_mcf_rt_parameters_and_upgrade_nvconfig(site_files_path , template_files_path)
      begin
        db1 = SQLite3::Database.new("#{site_files_path}/mcf.db")
        db2 = SQLite3::Database.new("#{template_files_path}/mcf.db")
        
        db1_rt = SQLite3::Database.new("#{site_files_path}/rt.db")
        db2_rt = SQLite3::Database.new("#{template_files_path}/rt.db")
        
        site_nv_path = "#{site_files_path}/nvconfig.sql3"
        template_nv_path = "#{template_files_path}/nvconfig.sql3"
        updated_vital_records = []
        lst_tables = {:parameters => ["layout_index", "layout_type","cardindex", "parameter_type" ,"parameter_index" , "name"]}
        lst_tables.each do |table_name, columns|
          db1_results = db1.execute('select * from ' + table_name.to_s + ' where parameter_type = 2') 
          
          db1_v_results_formated = []
          db1_results.each do |db1_result|
            db1_v_results_formated << db1_result[0,8].join('_$$_')
          end
          db1_v_results_formated.each do |res_db1_result_value|
            column_values = res_db1_result_value.split("_$$_")
            where_conditions = "#{columns[0]}= #{column_values[1]} and #{columns[1]}= #{column_values[2]} and #{columns[2]}= #{column_values[3]} and #{columns[3]}= #{column_values[4]} and #{columns[4]}= #{column_values[5]} and #{columns[5]}= '#{column_values[6]}'"
            db1_records = db1.execute("Select layout_index , cardindex , param_long_name ,context_string from #{table_name.to_s} Where #{where_conditions}")
            db2_records = db2.execute("Select layout_index , cardindex , param_long_name ,context_string from #{table_name.to_s} Where #{where_conditions}")
            rt_where_conditions = "parameter_type =2 and card_index= #{column_values[3]} and #{columns[4]}= #{column_values[5]}"
            rt1_current_value = db1_rt.execute("Select current_value , default_value from rt_parameters where #{rt_where_conditions}")
            rt2_current_value = db2_rt.execute("Select current_value , default_value from rt_parameters where #{rt_where_conditions}")
            if (!db1_records.blank?  && !db2_records.blank? && !rt1_current_value.blank? && !rt2_current_value.blank?  && (rt1_current_value[0][0].to_i != rt2_current_value[0][0].to_i))
              # Update rt 2 current value to rt1 current value 
              update_default_value_query = "update rt_parameters set current_value = #{rt2_current_value[0][0].to_i} Where #{rt_where_conditions}"
              db1_rt.execute(update_default_value_query)
              long_name = column_values[7]
              if long_name.blank?
                long_name = column_values[6]
              end
              updated_vital_records << {:layout_index => column_values[1] , :layout_type =>  column_values[2] , :cardindex => column_values[3] , 
                                        :parameter_type => column_values[4] , :parameter_index => column_values[5] , :name => long_name,
                                        :existing_current_value => rt1_current_value[0][0] , :default_value => rt1_current_value[0][1] , :updated_current_value => rt2_current_value[0][0]}
            end
          end
        end
        File.open("#{session[:cfgsitelocation]}/update_DB_from_template.log", 'a') do |f|
          if !updated_vital_records.blank?
            f.puts "Vital Parameters changes"
            f.puts "========================"
            f.puts "Lindex.Ltype.Cindex.Ptype.Pindex      Params Name          Existing current value        Default value     Updated current value"
            f.puts "================================================================================================================================"
            updated_vital_records.each do |vital_record|
              f.puts "#{vital_record[:layout_index]}.#{vital_record[:layout_type]}.#{vital_record[:cardindex]}.#{vital_record[:parameter_type]}.#{vital_record[:parameter_index]}      #{vital_record[:name]}      #{vital_record[:existing_current_value]}          #{vital_record[:default_value]}          #{vital_record[:updated_current_value]}"
            end
          end
        end
        db1.close
        db2.close
        db1_rt.close
        db2_rt.close
        
        upd_message = update_db({ :db1 => site_nv_path, :db2 => template_nv_path})
      rescue Exception => e
        # puts e.inspect
        upd_message = e.message
      end
    return upd_message
  end

  ####################################################################
  # Function:      getfilename_for_tagname
  # Parameters:    mainxmlfilepath, tagname
  # Retrun:        filename
  # Renders:       None
  # Description:   Get the files name according to the tag name from the xml file 
  ####################################################################    
  # Sitepath , /tmp/pacimport/pac1 path
  def compare_and_update_databse_using_importpac(databases1_loc , databases2_loc , import_pacname , log_path)
    nvconfig_update_records = []
    if File.exists?(log_path)
      File.delete(log_path)
    end
    begin
      db1 = SQLite3::Database.new("#{databases1_loc}/mcf.db")
      db2 = SQLite3::Database.new("#{databases2_loc}/mcf.db")
      
      db1_rt = SQLite3::Database.new("#{databases1_loc}/rt.db")
      db2_rt = SQLite3::Database.new("#{databases2_loc}/rt.db")
      begin
        db1_rt.transaction
        db2_rt.transaction
        current_config_info = db1_rt.execute("Select mcf_name , mcfcrc, mcf_revision, active_mtf_index from rt_gwe")
        imported_pac_info  = db2_rt.execute("Select mcf_name , mcfcrc, mcf_revision, active_mtf_index from rt_gwe")
        current_config_mcf_info = {:MCFName => current_config_info[0][0] , :MCFCRC => current_config_info[0][1] , :MCFRevision => current_config_info[0][2]}
        imported_pac_mcf_info = {:PACName => import_pacname ,:MCFName => imported_pac_info[0][0] , :MCFCRC => imported_pac_info[0][1] , :MCFRevision => imported_pac_info[0][2]}
      
        ####################### Get Vital records from two data bases #######################
        page_result_display = [] 
        pac_records_display = []
        page_result_display, pac_records_display = get_vitalconfig_compared_records(db1, current_config_info[0][1],  db2, imported_pac_info[0][1], db1_rt, db2_rt, true)
        #####################################################################################
        db1_rt.commit
        db2_rt.commit
      rescue SQLite3::Exception => e
        db1_rt.rollback
        db2_rt.rollback
      end
      db1.close
      db2.close
      db1_rt.close
      db2_rt.close
      
      nv_configuration_update = false
      
      if ((File.exists?("#{databases2_loc}/nvconfig.sql3")) && (File.size(databases2_loc +'/nvconfig.sql3') > 0))  
        # -------------------- Non-Vital parameters update logs
        lst_tables_nv = {:ByteArray_Parameters => ["ID","Group_ID","Group_Channel" ,"Name","Array_Value" , "Default_Value"],
                      :Enum_Parameters => ["ID","Group_ID" , "Group_Channel" ,"Name", "Selected_Value_ID" , "Default_Value_ID"],
                      :Integer_Parameters => ["ID","Group_ID" , "Group_Channel" ,"Name", "Value" ,"Default_Value"],
                      :String_Parameters => ["ID" , "Group_ID" , "Group_Channel" , "Name" , "String" , "Default_String"],
                      :CDL_Answer_Options => ["ID","Question_ID" ,"Answer_Value" , "Option_Text"],
                      :CDL_Conditions => ["ID", "Question_ID","Condition_Question_ID","Condition_Operator","Condition_Value", ],
                      :CDL_OpParam_Options => ["ID", "OpParam_ID" , "Option_Value" , "Option_Text" , "Option_Value"],
                      :CDL_OpParams => ["ID" , "Param_Type" , "Param_Name" , "Param_Comment" , "Min_Value" , "Max_Value" , "Current_Value"],
                      :CDL_Questions => ["ID","Question_Type","Question_Title","Question_Text", "Is_Answered","Answer_Min","Answer_Max","Answer_Default", "Answer_Value"],
                      :Wizard_Answer_Options => ["ID","Question_ID", "Answer_Value" , "Option_Text"],
                      :Wizard_Conditions => ["ID","Question_ID","Condition_Question_ID","Condition_Operator", "Condition_Value"],
                      :Wizard_Database_Operations => ["ID","Question_ID","Database_Operation","Parameter_Name", "Parameter_Value"],
                      :Wizard_Questions => ["ID", "Question_Type","Question_Title", "Question_Text","Is_Answered","Answer_Min","Answer_Max","Answer_Default","Answer_Value"]
        }
        
        nv_cdl_wizard_records = []
        nv_not_in_import_package  = []
        nv_enumeration_not_found  = []
        nv_value_out_of_range  = []
        nv_not_in_current_configuration = []
        nv_configuration_update = true
        db1_nvconfig = SQLite3::Database.new("#{databases1_loc}/nvconfig.sql3")
        db2_nvconfig = SQLite3::Database.new("#{databases2_loc}/nvconfig.sql3")
        
        # Iterate all the table for difference
        lst_tables_nv.each do |table_name, columns|
          if (table_name.to_s.start_with?("CDL", "Wizard"))
            exist_records = db2_nvconfig.execute("Select * from " + table_name.to_s)
            if (!exist_records.blank?)
                db1_nvconfig.execute("Delete from #{table_name.to_s}")
                exist_records.each do |cdl|     
                  insrt_sql = 'Insert Into ' + table_name.to_s + ' Values("' + cdl.join('","') + '")'
                  db1_nvconfig.execute(insrt_sql)
                  if (table_name.to_s == "CDL_OpParams")
                    value = cdl[6] 
                    if cdl[1].to_i == 1
                      value = db1_nvconfig.execute("Select Option_Text from CDL_OpParam_Options where OpParam_ID=#{cdl[0].to_i} and Option_Value = #{cdl[6].to_i}").collect{|v|v[0]}  
                      value = value[0].to_s
                    end
                    nv_cdl_wizard_records << {:TableName => table_name.to_s ,:ParamsName =>cdl[2] ,:Value => value }
                  elsif (table_name.to_s == "CDL_Questions")
                    value = cdl[8] 
                    if cdl[1].to_i == 1
                      value = db1_nvconfig.execute("Select Option_Text from CDL_Answer_Options where Question_ID=#{cdl[0].to_i} and Answer_Value = #{cdl[8].to_i}").collect{|v|v[0]}  
                      value = value[0].to_s
                    end
                    nv_cdl_wizard_records << {:TableName => table_name.to_s ,:ParamsName =>cdl[3] ,:Value => value }
                  elsif (table_name.to_s == "Wizard_Questions")
                    value = cdl[8] 
                    if cdl[1].to_i == 1
                      value = db1_nvconfig.execute("Select Option_Text from Wizard_Answer_Options where Question_ID=#{cdl[0].to_i} and Answer_Value = #{cdl[8].to_i}").collect{|v|v[0]}  
                      value = value[0].to_s
                    end
                    nv_cdl_wizard_records << {:TableName => table_name.to_s ,:ParamsName =>cdl[3] ,:Value => value }
                  end
                end
            end
          else
            db1_results = db1_nvconfig.execute('select * from ' + table_name.to_s)
            db2_results = db2_nvconfig.execute('select * from ' + table_name.to_s)
            db1_nv_results_formated = []
            db2_nv_results_formated = []
            
            db1_results.each do |db1_result|
              db1_nv_results_formated << db1_result[0,10].join('_$$_')
            end
            
            db2_results.each do |db2_result|
              db2_nv_results_formated << db2_result[0,10].join('_$$_')
            end
            
            db1_nv_results_formated.each do |res_db1_value|
              column_values = res_db1_value.split("_$$_")
              where_conditions = ""
              id = column_values[0]
              group_id = column_values[1]
              group_channel = column_values[2]
              name = column_values[3]
              db1_ct_record_value = column_values[5]
              db1_ct_default_value = column_values[6]
              updated_value = ""
              group_name = db1_nvconfig.execute("Select Group_Name from Parameter_Groups where ID =#{group_id.to_i} LIMIT 1").collect{|v|v[0]}
              group_name = group_name[0]
              where_conditions = ("#{columns[0]} =#{id}  and #{columns[1]} = #{group_id} and #{columns[2]} = #{group_channel} ")
              query = "Select #{columns[4]} , #{columns[5]} from #{table_name.to_s} Where #{where_conditions}"
              db2_existing_records =  db2_nvconfig.execute(query)
              if !db2_existing_records.blank?
                db2_ct_record_value =  db2_existing_records[0][0]
                db2_ct_default_value = db2_existing_records[0][1]
                # update db2 current value to db1 current value
                if(db1_ct_record_value.to_s !=  db2_ct_record_value.to_s)
                  if db2_ct_record_value.blank?
                    set_value = "#{columns[4]} = ''"
                  else
                    set_value = "#{columns[4]} = '#{db2_ct_record_value}'"
                    if(table_name.downcase.to_s == "enum_parameters")
                      enum_values_db2_ct = db1_nvconfig.execute("select Name from Enum_Values where ID=#{db2_ct_record_value.to_i}").collect{|v|v[0]}
                      enum_values_db2 = db2_nvconfig.execute("select Name from Enum_Values where ID=#{db2_ct_record_value.to_i}").collect{|v|v[0]}
                      
                      # To handle the Enums name mismatch display the difference and update the default value
                      if !enum_values_db2_ct.blank? && !enum_values_db2.blank? && (enum_values_db2_ct[0].strip.to_s != enum_values_db2[0].strip.to_s)
                        # Display the db2 current value enumeration not found values to user . update default value
                        set_value = "#{columns[4]} = '#{db1_ct_default_value}'"
                        updated_value = enum_values_db2[0].to_s
                        nv_enumeration_not_found  << {:ID => id ,:GroupID => group_id ,:Group_Name => group_name ,:ParamsName =>name ,:Value => updated_value ,:Unit => "" }
                      end

                      if enum_values_db2_ct.blank?
                        # Display the db2 current value enumeration not found values to user . update default value
                        set_value = "#{columns[4]} = '#{db1_ct_default_value}'"
                        updated_value = enum_values_db2[0].to_s
                        nv_enumeration_not_found  << {:ID => id ,:GroupID => group_id ,:Group_Name => group_name ,:ParamsName =>name ,:Value => updated_value ,:Unit => "" }
                      end
                    elsif (table_name.downcase.to_s == "integer_parameters")
                      type_id = column_values[9]
                      int_type_id_values = db1_nvconfig.execute("select Type_Name , Units , Min_Value , Max_Value from Integer_Types where ID=#{type_id.to_i}")
                      if ((db2_ct_record_value.to_i >= int_type_id_values[0][2].to_i) && (db2_ct_record_value.to_i <= int_type_id_values[0][3].to_i))
                        updated_value = db2_ct_record_value.to_i # condition check only
                      else
                        set_value = "#{columns[4]} = #{db1_ct_default_value}"
                        # Display the db2 current value out of range values to user . update default value
                        updated_value = db2_ct_record_value.to_i
                        int_type_id_units = db1_nvconfig.execute("select Units from Integer_Types where ID=#{type_id.to_i}").collect{|v|v[0]}
                        unit = int_type_id_units[0]
                        nv_value_out_of_range  << {:ID => id ,:GroupID => group_id ,:Group_Name => group_name ,:ParamsName =>name ,:Value => updated_value ,:Unit => unit }
                      end
                    elsif (table_name.downcase.to_s == "string_parameters")
                      type_id = column_values[9]
                      string_type_id_value = db1_nvconfig.execute("select Min_Length , Max_Length from String_Types where ID=#{type_id.to_i}")
                      if ((db2_ct_record_value.length.to_i >= string_type_id_value[0][0].to_i) && (db2_ct_record_value.length.to_i <= string_type_id_value[0][1].to_i))
                        updated_value = db2_ct_record_value # condition check only
                      else
                        set_value = "#{columns[4]} = #{db1_ct_default_value}"
                        updated_value = db1_ct_default_value.to_i
                        nv_value_out_of_range  << {:ID => id ,:GroupID => group_id ,:Group_Name => group_name ,:ParamsName =>name ,:Value => updated_value ,:Unit => "" }
                      end
                    end
                  end
                  strsql = "Update #{table_name.to_s}  Set #{set_value}  Where #{where_conditions}"
                  str1 = db1_nvconfig.execute(strsql)
                else
                    if(table_name.downcase.to_s == "enum_parameters")
                      enum_values_db2_ct = db1_nvconfig.execute("select Name from Enum_Values where ID=#{db2_ct_record_value.to_i}").collect{|v|v[0]}
                      enum_values_db2 = db2_nvconfig.execute("select Name from Enum_Values where ID=#{db2_ct_record_value.to_i}").collect{|v|v[0]}
                      
                      # To handle the Enums name mismatch display the difference and update the default value
                      if !enum_values_db2_ct.blank? && !enum_values_db2.blank? && (enum_values_db2_ct[0].strip.to_s != enum_values_db2[0].strip.to_s)
                        # Display the db2 current value enumeration not found values to user . update default value
                        set_value = "#{columns[4]} = '#{db1_ct_default_value}'"
                        updated_value = enum_values_db2[0].to_s
                        nv_enumeration_not_found  << {:ID => id ,:GroupID => group_id ,:Group_Name => group_name ,:ParamsName =>name ,:Value => updated_value ,:Unit => "" }
                        strsql = "Update #{table_name.to_s}  Set #{set_value}  Where #{where_conditions}"
                        str1 = db1_nvconfig.execute(strsql)
                      end
                    end
                end # update db2 current value to db1 current value
              else
                  if(db1_ct_record_value.to_s !=  db1_ct_default_value.to_s)
                    if db1_ct_default_value.blank?
                      set_value = "#{columns[4]} = ''"
                    else
                      set_value = "#{columns[4]} = '#{db1_ct_default_value}'"
                      if(table_name.downcase.to_s == "enum_parameters")
                        enum_values_db1_default = db1_nvconfig.execute("select Name from Enum_Values where ID=#{db1_ct_default_value.to_i}").collect{|v|v[0]}
                        if enum_values_db1_default.blank?
                          set_value = "#{columns[4]} = '#{db1_ct_default_value}'"
                          enum_values_db1_default = db1_nvconfig.execute("select Name from Enum_Values where ID=#{db1_ct_default_value.to_i}").collect{|v|v[0]}
                          updated_value = enum_values_db1_default[0].to_s
                          nv_enumeration_not_found  << {:ID => id ,:GroupID => group_id ,:Group_Name => group_name ,:ParamsName =>name ,:Value => updated_value ,:Unit => "" }
                        end
                      elsif (table_name.downcase.to_s == "integer_parameters")
                        type_id = column_values[9]
                        int_type_id_values = db1_nvconfig.execute("select Type_Name , Units , Min_Value , Max_Value from Integer_Types where ID=#{type_id.to_i}")
                        if ((db1_ct_default_value.to_i >= int_type_id_values[0][2].to_i) && (db1_ct_default_value.to_i <= int_type_id_values[0][3].to_i))
                          updated_value = db1_ct_default_value.to_i # condition check only
                        else
                          set_value = "#{columns[4]} = #{db1_ct_default_value}"
                          updated_value = db1_ct_default_value.to_i
                          int_type_id_units = db1_nvconfig.execute("select Units from Integer_Types where ID=#{type_id.to_i}").collect{|v|v[0]}
                          unit = int_type_id_units[0]
                          nv_value_out_of_range  << {:ID => id ,:GroupID => group_id ,:Group_Name => group_name ,:ParamsName =>name ,:Value => updated_value ,:Unit => unit }
                        end
                      elsif (table_name.downcase.to_s == "string_parameters")
                        type_id = column_values[9]
                        string_type_id_value = db1_nvconfig.execute("select Min_Length , Max_Length from String_Types where ID=#{type_id.to_i}")
                        if ((db1_ct_default_value.length.to_i >= string_type_id_value[0][0].to_i) && (db1_ct_default_value.length.to_i <= string_type_id_value[0][1].to_i))
                          updated_value = db1_ct_default_value # condition check only
                        else
                          set_value = "#{columns[4]} = #{db1_ct_default_value}"
                          updated_value = db1_ct_default_value.to_i
                          nv_value_out_of_range  << {:ID => id ,:GroupID => group_id ,:Group_Name => group_name ,:ParamsName =>name ,:Value => updated_value ,:Unit => "" }
                        end
                      else
                        updated_value = db1_ct_default_value.to_s
                        nv_not_in_import_package << {:ID => id ,:GroupID => group_id ,:Group_Name => group_name ,:ParamsName =>name ,:Value => updated_value ,:Unit => "" }  
                      end
                    end
                    strsql = "Update #{table_name.to_s}  Set #{set_value}  Where #{where_conditions}"
                    str1 = db1_nvconfig.execute(strsql)
                  end # if(db1_ct_record_value.to_s !=  db1_ct_default_value.to_s)
              end #if !db2_existing_records.blank?
              
            end # db1_nv_results_formated.each do |res_db1_value|
            
            db2_nv_results_formated.each do |res_db2_value|
              column_values = res_db2_value.split("_$$_")
              where_conditions = ""
              id = column_values[0]
              group_id = column_values[1]
              group_channel = column_values[2]
              name = column_values[3]
              db2_ct_record_value = column_values[5]
              db2_ct_default_value = column_values[6]
              updated_value = ""
              group_name = db2_nvconfig.execute("Select Group_Name from Parameter_Groups where ID =#{group_id.to_i} LIMIT 1").collect{|v|v[0]}
              group_name = group_name[0]
              where_conditions = ("#{columns[0]} = #{id}  and #{columns[1]} = #{group_id} and #{columns[2]} = #{group_channel} ")
              query = "Select #{columns[4]} , #{columns[5]} from #{table_name.to_s} Where #{where_conditions}"
              db1_existing_records =  db1_nvconfig.execute(query)
              if db1_existing_records.blank?
                 unit = ""
                 updated_value = db2_ct_record_value.to_s
                 if(table_name.downcase.to_s == "enum_parameters")
                    enum_values_db2_default = db2_nvconfig.execute("select Name from Enum_Values where ID=#{db2_ct_record_value.to_i}").collect{|v|v[0]}
                    updated_value = enum_values_db2_default[0].to_s
                  elsif (table_name.downcase.to_s == "integer_parameters")
                    type_id = column_values[9]
                    updated_value = db2_ct_record_value.to_s
                    int_type_id_units = db2_nvconfig.execute("select Units from Integer_Types where ID=#{type_id.to_i}").collect{|v|v[0]}
                    unit = int_type_id_units[0]
                  end
                  nv_not_in_current_configuration << {:ID => id ,:GroupID => group_id ,:Group_Name => group_name ,:ParamsName =>name ,:Value => updated_value ,:Unit => unit }
              end
            end
         
          end #if (table_name.start_with?("CDL"))
        end  #each lst_tables  
        nvconfig_update_records << {:nv_not_in_import_package => nv_not_in_import_package ,:nv_enumeration_not_found => nv_enumeration_not_found ,:nv_value_out_of_range => nv_value_out_of_range ,:nv_not_in_current_configuration =>nv_not_in_current_configuration}
        db1_nvconfig.close
        db2_nvconfig.close
        #--------------NV Update END
      end
      
      #Display PAC Files Comaprison Table
      mab = Markaby::Builder.new
      mab.html do
        head do 
          title "PAC File Import"
          style :type => "text/css" do
           %[body { font-family: Arial;font-size: 13px; background-color:#000;color:#F2F2F2; }
             .pacfileimportcontent table th{font-family: Arial;background-color: #424242;text-align: center ;color: #CFD638; width: 8%;font-size:13px;font-weight:bold; }
             .pacfileimportcontent table{font-family: Arial;background-color: #787878; border:1px solid #4E4E4E; color: #E4E4E4; width: 100%; text-align: left ;}
             .pacfileimportcontent table tr td {font-family: Arial;font-size:13px;word-wrap: break-word;}
             ]
          end
        end
        
        dark_bg = "background: #424242;"
        light_bg = "background: #515151;"
        body do 
          div.pacfileimportcontent  :style =>"border-top: 0;" do
            div "", :style => "clear:both; padding-top:10px;width:auto;"
            div "PAC File Import" , :style => "color: #CFD638;font-family: Arial; font-size:15px;font-weight:bold;text-align: center;"
            div "", :style => "clear:both; padding-top:20px;width:auto;"
            
            table :style =>"width:97%;" do
                tr do
                  th "Current Configuration",:style =>"width:50%;"
                  th "Imported PAC File",:style =>"width:50%;"
                end
                                
                # Display the MCF Name , MCFCRC , MCF Revision , PAC information 
                tr  :style => "background: #515151;" do
                  td :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" do 
                    div "MCF Name: #{current_config_mcf_info[:MCFName]}"
                    div "MCFCRC: #{current_config_mcf_info[:MCFCRC].to_s(16).upcase}"
                    div "MCF Revision: #{current_config_mcf_info[:MCFRevision]}"
                  end 
                  
                  td :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" do 
                    div "PAC File Name: #{imported_pac_mcf_info[:PACName]}"
                    div "MCF Name: #{imported_pac_mcf_info[:MCFName]}"
                    div "MCFCRC: #{imported_pac_mcf_info[:MCFCRC].to_s(16).upcase}"
                    div "MCF Revision: #{imported_pac_mcf_info[:MCFRevision]}"
                  end                                           
                end
                if !page_result_display.blank?
                  tr do
                    th "Warnings",:style =>"width:50%;"
                    th "Description",:style =>"width:50%;"
                  end
                
                  page_result_display.each do | page_result |
                      tr :style =>dark_bg  do
                        td "#{page_result[:page_name]}",:colspan => 2,:style=>"font-weight:bold;color: #CFD638;"
                      end
                      tr_count = 0
                      page_result[:not_in_import_package].each do |not_in_import_pac|
                        bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                        tr  :style =>bg do
                          td "#{not_in_import_pac[:context_string]} #{not_in_import_pac[:parameter_name]} = #{not_in_import_pac[:value]} #{not_in_import_pac[:unit]}" , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                          td "Not present in PAC File, default value used." , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                        end
                        tr_count+=1
                      end
                      
                      page_result[:enumeration_not_found].each do |enum_not_found|
                        bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                        tr  :style =>bg do
                          td "#{enum_not_found[:context_string]} #{enum_not_found[:parameter_name]} = #{enum_not_found[:value]} #{enum_not_found[:unit]}" , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                          td "Values different from PAC File, default value used. #{enum_not_found[:old_param_name]}" , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                        end
                        tr_count+=1
                      end
                      
                      page_result[:value_out_of_range].each do |val_out_of_range|
                        bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                        tr  :style =>bg do
                          td "#{val_out_of_range[:context_string]} #{val_out_of_range[:parameter_name]} = #{val_out_of_range[:value]} #{val_out_of_range[:unit]}" , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                          td "Values different from PAC File, default value used." , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                        end
                        tr_count+=1
                      end
                      
                      page_result[:updated_from_pac].each do |updated_from_pac|
                        bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                        tr  :style =>bg do
                          td "#{updated_from_pac[:context_string]} #{updated_from_pac[:parameter_name]} = #{updated_from_pac[:value]} #{updated_from_pac[:unit]}" , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                          td "Updated from PAC File. #{updated_from_pac[:old_param_name]}" , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                        end
                        tr_count+=1
                      end
                      
                  end   #page_result_display
                else
                  tr :style =>dark_bg  do
                      th "Vital Parameters Updated Successfully",:colspan => 2,:style=>"font-weight:bold;color: #CFD638;"
                  end
                end # if !page_result_display.blank?                
                                
            end # table
            
            ###########################################################################################################            
            if !pac_records_display.blank?
              div "", :style => "clear:both; padding-top:50px;width:auto;"
              div "Parameters exist in the PAC file but not in current MCF", :style => "color: #CFD638;font-size:13px;font-weight:bold;"
              table :style =>"width:97%;" do             
                tr do
                  th "Warnings",:style =>"width:50%;"
                  th "Description",:style =>"width:50%;"
                end                
                pac_records_display.each do | page_result |
                    tr :style =>dark_bg  do
                      td "#{page_result[:page_name]}",:colspan => 2,:style=>"font-weight:bold;color: #CFD638;"
                    end
                    tr_count = 0
                    page_result[:not_in_current_configuration].each do |not_in_current_config|
                      bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                      tr  :style =>bg do
                        td "#{not_in_current_config[:context_string]} #{not_in_current_config[:parameter_name]} = #{not_in_current_config[:value]} #{not_in_current_config[:unit]}" , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                        td "Parameter exist in the PAC file but does not exist in the current MCF." , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                      end
                      tr_count+=1
                    end
                    
                end   #pac_records_display                
              end   #table
            end # if !pac_records_display.blank?
              
           ################################################
            
            div "", :style => "clear:both; padding-top:50px;width:auto;"
            div "Non-Vital Parameters", :style => "color: #CFD638;font-size:13px;font-weight:bold;"
            if nv_configuration_update
              cdl_questions = nv_cdl_wizard_records.select {|cdl_wizard| cdl_wizard[:TableName] == "CDL_Questions" }
              cdl_opParams = nv_cdl_wizard_records.select {|cdl_wizard| cdl_wizard[:TableName] == "CDL_OpParams" }
              wizard_questions = nv_cdl_wizard_records.select {|cdl_wizard| cdl_wizard[:TableName] == "Wizard_Questions" }
              
              # Non-Vital Parameters update information
              table :style =>"width:97%;" do
                if nvconfig_update_records[0][:nv_not_in_import_package].blank? && nvconfig_update_records[0][:nv_enumeration_not_found].blank? &&
                   nvconfig_update_records[0][:nv_value_out_of_range].blank? && nvconfig_update_records[0][:nv_not_in_current_configuration].blank? && 
                   cdl_questions.blank? && cdl_opParams.blank? && wizard_questions.blank?
  
                   tr :style =>dark_bg  do
                      th "Non-Vital Parameters Updated Successfully",:colspan => 2,:style=>"font-weight:bold;color: #CFD638;"
                   end
                else  
                  tr do
                    th "Warnings",:style =>"width:50%;"
                    th "Description",:style =>"width:50%;"
                  end
                  
                  # #start -enum, int , binary , string params update records
                  nvconfig_update_records.each do | nvconfig_update_record|
                    nv_not_in_group_id = nvconfig_update_record[:nv_not_in_import_package].map{|group_ids|group_ids[:GroupID].to_i}.uniq
                    nv_enumeration_not_group_id = nvconfig_update_record[:nv_enumeration_not_found].map{|group_ids|group_ids[:GroupID].to_i}.uniq
                    nv_value_out_of_group_id = nvconfig_update_record[:nv_value_out_of_range].map{|group_ids|group_ids[:GroupID].to_i}.uniq
                    nv_not_in_current_group_id = nvconfig_update_record[:nv_not_in_current_configuration].map{|group_ids|group_ids[:GroupID].to_i}.uniq
                    all_group_IDs = nv_not_in_group_id + nv_enumeration_not_group_id + nv_value_out_of_group_id + nv_not_in_current_group_id
                    group_ids = all_group_IDs.uniq
                    group_ids.each do |group_id|
                      nv_not_in_import_package_records =  nvconfig_update_record[:nv_not_in_import_package].select {|group_id_select_record| group_id_select_record[:GroupID].to_i == group_id.to_i}
                      nv_enumeration_not_found_records =  nvconfig_update_record[:nv_enumeration_not_found].select {|group_id_select_record| group_id_select_record[:GroupID].to_i == group_id.to_i}
                      nv_value_out_of_range_records =  nvconfig_update_record[:nv_value_out_of_range].select {|group_id_select_record| group_id_select_record[:GroupID].to_i == group_id.to_i}
                      nv_not_in_current_configuration_records =  nvconfig_update_record[:nv_not_in_current_configuration].select {|group_id_select_record| group_id_select_record[:GroupID].to_i == group_id.to_i}
                      if !nv_not_in_import_package_records.blank? || !nv_enumeration_not_found_records.blank? || !nv_value_out_of_range_records.blank? || !nv_not_in_current_configuration_records.blank? 
                           group_name = ""
                           if nv_not_in_import_package_records.length > 0
                              group_name = nv_not_in_import_package_records[0][:Group_Name].to_s
                           elsif nv_enumeration_not_found_records.length > 0
                              group_name = nv_enumeration_not_found_records[0][:Group_Name].to_s
                           elsif nv_value_out_of_range_records.length > 0
                              group_name = nv_value_out_of_range_records[0][:Group_Name].to_s
                           elsif nv_not_in_current_configuration_records.length > 0
                              group_name = nv_not_in_current_configuration_records[0][:Group_Name].to_s
                           end  
                           tr :style =>dark_bg  do
                              td group_name ,:colspan => 2,:style=>"font-weight:bold;color: #CFD638;"
                           end
                           
                           tr_count = 0
                           if !nv_not_in_import_package_records.blank?
                             nv_not_in_import_package_records.each do |nv_not_in_import_package_record|
                                bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                                tr  :style =>bg do
                                  value =  nv_not_in_import_package_record[:Value].blank? ? '" "' : nv_not_in_import_package_record[:Value]
                                  td "#{nv_not_in_import_package_record[:ParamsName]} = #{value} #{nv_not_in_import_package_record[:Unit]}" , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                                  td "Not in imported Package. Not Updated." , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                                end
                                tr_count+=1
                             end
                           end
                           
                           if !nv_enumeration_not_found_records.blank?
                             nv_enumeration_not_found_records.each do |nv_enumeration_not_found_record|
                                bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                                tr  :style =>bg do
                                  value =  nv_enumeration_not_found_record[:Value].blank? ? '" "' : nv_enumeration_not_found_record[:Value]
                                  td "#{nv_enumeration_not_found_record[:ParamsName]} = #{value} #{nv_enumeration_not_found_record[:Unit]}" , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                                  td "Enumeration not found. Not Updated." , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                                end
                                tr_count+=1
                             end
                           end
    
                           if !nv_value_out_of_range_records.blank?
                             nv_value_out_of_range_records.each do |nv_value_out_of_range_record|
                                bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                                tr  :style =>bg do
                                  value =  nv_value_out_of_range_record[:Value].blank? ? '" "' : nv_value_out_of_range_record[:Value]
                                  td "#{nv_value_out_of_range_record[:ParamsName]} = #{value} #{nv_value_out_of_range_record[:Unit]}" , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                                  td "Value out of range. Not Updated." , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                                end
                                tr_count+=1
                             end
                           end
    
                           if !nv_not_in_current_configuration_records.blank?
                             nv_not_in_current_configuration_records.each do |nv_not_in_current_configuration_record|
                                bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                                tr  :style =>bg do
                                  value =  nv_not_in_current_configuration_record[:Value].blank? ? '" "' : nv_not_in_current_configuration_record[:Value]
                                  td "#{nv_not_in_current_configuration_record[:ParamsName]} = #{value} #{nv_not_in_current_configuration_record[:Unit]}" , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                                  td "Not in current Configuration. Value  not imported." , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                                end
                                tr_count+=1
                             end
                           end
                      end
                    end
                  end
                  # #END -enum, int , binary , string params update records
                  
                  if !cdl_questions.blank?
                    tr :style =>dark_bg  do
                        td "CDL_Questions",:colspan => 2,:style=>"font-weight:bold;color: #CFD638;"
                    end
                    tr_count = 0
                    cdl_questions.each do | cdl_question |
                      bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                      tr  :style =>bg do
                        td "#{cdl_question[:ParamsName]} = #{cdl_question[:Value]}" , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                        td "" 
                      end
                      tr_count+=1
                    end
                  end # if !cdl_questions.blank?
                  
                  if !cdl_opParams.blank?
                    tr :style =>dark_bg  do
                        td "CDL_OpParams",:colspan => 2,:style=>"font-weight:bold;color: #CFD638;"
                    end
                    tr_count = 0
                    cdl_opParams.each do | cdl_opParam |
                      bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                      tr  :style =>bg do
                        td "#{cdl_opParam[:ParamsName]} = #{cdl_opParam[:Value]}" , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                        td "" 
                      end
                      tr_count+=1
                    end
                  end # if !cdl_opParams.blank?
                  
                  if !wizard_questions.blank?
                    tr :style =>dark_bg  do
                        td "Wizard_Questions",:colspan => 2,:style=>"font-weight:bold;color: #CFD638;"
                    end
                    tr_count = 0
                    wizard_questions.each do | wizard_question |
                      bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                      tr  :style =>bg do
                        td "#{wizard_question[:ParamsName]} = #{wizard_question[:Value]}" , :style=>"color: #F2F2F2;width:50%;font-family: Arial;font-size:13px;" 
                        td "" 
                      end
                      tr_count+=1
                    end
                  end # if !wizard_questions.blank?
                end
              end # table
            else
              table :style =>"width:97%;" do                
                   tr :style =>dark_bg  do
                      th "Non-Vital Configuration not found in imported PAC file.",:colspan => 2,:style=>"font-weight:bold;color: #CFD638;"
                   end
               end
            end
          end
        end # Body
      end #mab
      
      # Save the formated html reports to download 
      File.open(log_path,'w') do |f| 
          f.write("<div style='clear:both; padding-top:20px;width:auto;'></div>")
          f.write(mab.to_s)
      end
    rescue Exception => e
      File.open(log_path,'w') do |f| 
          f.write("<div style='clear:both; padding-top:20px;width:auto;'></div>")
          f.write(mab.to_s)
          f.write("<div style='padding-left:10px;color:#FF0000;font-family: Arial; font-size:13px;'>Error :#{e.message}</div>")
      end
      return "Exception raised while updating database\r\nError Message:\r\n#{e.message}"
    end 
    return "" 
  end
  
  ####################################################################
  # Function:      getfilename_for_tagname
  # Parameters:    mainxmlfilepath, tagname
  # Retrun:        filename
  # Renders:       None
  # Description:   Get the files name according to the tag name from the xml file 
  ####################################################################     
  def frame_space(columns)
    big_size_col = ["Question_Title", "Question_Text", "Param_Name" , "Param_Comment"]
    size = []
    add = []
    columns.each do | col_name |
      size << col_name.length
      if big_size_col.include?(col_name)
        add << "%-30s"
      else
        add << "%-#{col_name.length.to_i}s"
      end
    end
    add.collect! {|x| x + "|" }
    final_format = add.join(' ')
    return  "#{final_format}" , size
  end

  ####################################################################
  # Function:      get_report_file_name
  # Parameters:    report_type
  # Retrun:        format , file name
  # Renders:       None
  # Description:   Return the file name format and file name while downloading the GCP reports  
  ####################################################################     
  def get_report_file_name(report_type)
    case report_type.downcase
      when 'min' then return "min_report" , "Min Program Steps Report.txt"
      when 'template' then return "template_report" , "Template Report.txt"
      when 'program' then return "program_report" , "Programming Report.txt"
      when 'system' then return "system_report" , "Configuration Report.txt"
      when 'express' then return "express_report" , "Express Programming Report.txt"
      when 'nonvital' then return "nonvital_report" , "Non Vital Programming Report.txt"
      when 'relaylogic' then return "relaylogic" , "Relaylogic  Report.pdf"
      when 'version' then return "version" , "version Report.txt"
    end
  end 
  
  ####################################################################
  # Function:      copy_gcp_siteconfig_to_mcf_repository
  # Parameters:    source_path , destination_path
  # Retrun:        None
  # Renders:       None 
  # Description:   Copy the gcp site configuration into the gcp mcf repository folder - gcp >> <MCFCRC.
  ####################################################################
  def copy_gcp_siteconfig(source_path , destination_path)
    #check the files and folders available in the source_path
    error_message = ""
    if File.directory?("#{source_path}/AuxFiles")
      auxfiles_empty_flag = (Dir.entries("#{source_path}/AuxFiles") == [".", ".."])
      if File.exists?("#{source_path}/mcf.db") && File.exists?("#{source_path}/rt.db") && File.exists?("#{source_path}/AuxFiles")
        if ((File.size("#{source_path}/mcf.db") > 0) && (File.size("#{source_path}/rt.db") >0) && (auxfiles_empty_flag == false))
          #add the validation - if rt , mcf , Auxfiles available
          error_message = validate_vital_database(source_path)
          if error_message.blank?
            FileUtils.cp_r(Dir["#{source_path}/mcf.db", "#{source_path}/rt.db" , "#{source_path}/AuxFiles*"] , destination_path)  
          end
        else
          error_message = "Invalid MCF , RT database and AuxFiles"
        end
      else
        error_message = "MCF , RT database and AuxFiles are Not available in the source location"    
      end
    end
    return error_message
  end
  
  ####################################################################
  # Function:      validate_vital_database
  # Parameters:    source_path 
  # Retrun:        None
  # Renders:       None 
  # Description:   Validate the MCF and Rt database 
  ####################################################################
  def validate_vital_database(source_path)
    strmsg = ""
    db1_mcf = SQLite3::Database.new("#{source_path}/mcf.db")
    db1_rt = SQLite3::Database.new("#{source_path}/rt.db")
    db1_mcf_status = db1_mcf.execute('select mcf_status from mcfs').collect{|v|v[0]}
    db1_rt_ui_states_value = db1_rt.execute("Select value from rt_ui_states where name ='Database completed'").collect{|v|v[0]}
    if db1_mcf_status.blank? ||  db1_mcf_status[0].to_i != 1 || db1_rt_ui_states_value.blank? || db1_rt_ui_states_value[0].to_i != 1   
       strmsg = "MCF and RT database are not created properly"
    end
    return strmsg
  end
  
  ####################################################################
  # Function:      validate_gcp_supportfiles
  # Parameters:    source_path 
  # Retrun:        None
  # Renders:       None 
  # Description:   Validate the MCF and Rt database 
  ####################################################################
  def validate_gcp_supportfiles(source_path)
    error_message = ""
    auxfilepath = "#{source_path}/AuxFiles"
    if File.exists?(auxfilepath)
      auxfiles_empty_flag = (Dir.entries("#{source_path}/AuxFiles") == [".", ".."])
      if File.exists?("#{source_path}/mcf.db") && File.exists?("#{source_path}/rt.db") && auxfiles_empty_flag == false
        if ((File.size("#{source_path}/mcf.db") > 0) && (File.size("#{source_path}/rt.db") >0))
          strmsg = ""
          db1_mcf = SQLite3::Database.new("#{source_path}/mcf.db")
          db1_rt = SQLite3::Database.new("#{source_path}/rt.db")
          db1_mcf_status = db1_mcf.execute('select mcf_status from mcfs').collect{|v|v[0]}
          db1_rt_ui_states_value = db1_rt.execute("Select value from rt_ui_states where name ='Database completed'").collect{|v|v[0]}
          if db1_mcf_status.blank? ||  db1_mcf_status[0].to_i != 1 || db1_rt_ui_states_value.blank? || db1_rt_ui_states_value[0].to_i != 1   
            strmsg = "MCF and RT database are not created properly"
          end
        else
          strmsg = "Invalid Configuration Files"
        end
      else
        strmsg = (auxfiles_empty_flag == true) ? "AuxFiles Not available in the source location" : "MCF , RT database are Not available in the source location"
      end
    else
      strmsg = "AuxFiles folder is not present in the source location" 
    end
    return strmsg
  end
  
  def copy_gcp_template_files(site_location_path , template_directory , tpl_name)
    strmsg = ""
    if File.exists?("#{site_location_path}/mcf.db") && File.exists?("#{site_location_path}/rt.db") && File.exists?("#{site_location_path}/nvconfig.sql3") 
      if ((File.size("#{site_location_path}/mcf.db") > 0) && (File.size("#{site_location_path}/rt.db") >0) && (File.size("#{site_location_path}/nvconfig.sql3") >0))
        strmsg = validate_vital_database(site_location_path)
      else
        strmsg = "Invalid Configuration Files"
      end
    else
      strmsg = "MCF , RT database are Not available in the source location"    
    end
    if strmsg.blank?
      # Copy and move the PAC file
      pac_file_path = ""
      Dir["#{site_location_path}/*.PAC"].each do |site_pac_file|
        pac_file_path = site_pac_file
      end
      File.rename(pac_file_path, "#{site_location_path}/#{tpl_name}.TPL")
      Dir["#{site_location_path}/mcf.db", "#{site_location_path}/rt.db" , "#{site_location_path}/nvconfig.sql3"  , "#{site_location_path}/#{tpl_name}.TPL"].each do |support_file|
        FileUtils.cp(support_file, template_directory)
      end
    end
    return strmsg
  end

  def set_hidden_params_to_defaults
    current_mcfcrc = 0
    current_phy_layout = 0
    mtf_index = 0
    gwe_active = Gwe.get_mcfcrc(atcs_address)
    current_mcfcrc = gwe_active.mcfcrc
    current_phy_layout = gwe_active.active_physical_layout || 0
    mtf_index = 0        #gwe_active.active_mtf_index || 0
    all_paramtodefault = true
    hidden_params = []
    show_params = []
    set_alltohidden = []
    @expression_structure = {}
    set_ui_expr_variables
    get_gcp_type

    page_list = Page.all(:select => "page_name, page_index, enable",
        :conditions => ["mcfcrc = ? and layout_index = ? and mtf_index = ? and (target Not Like 'WebUI') and page_group Not Like 'express' and page_group Not Like 'template'  and page_group Not Like 'setup' ", 
            current_mcfcrc, current_phy_layout, mtf_index])

    if !page_list.blank?
      page_list.each do |page_rec|
        if eval_expression(page_rec.enable)
          all_paramtodefault = false
        else
          all_paramtodefault = true
        end
        
        page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and layout_index = ? and mtf_index = ? and (target Not Like 'WebUI') and page_name Like ? ", 
                  current_mcfcrc, current_phy_layout, mtf_index, page_rec.page_name.strip], :order => 'display_order asc')

        page_parameters.each do |param|
          set_alltohidden << param.mcfcrc.to_s + "." + param.card_index.to_s + "." + param.parameter_type.to_s + "." + param.parameter_name.to_s
          if (all_paramtodefault == false)
            show_value = eval_expression(param.show) ? true : false
            if (show_value)
              show_params << param.mcfcrc.to_s + "." + param.card_index.to_s + "." + param.parameter_type.to_s + "." + param.parameter_name.to_s
            end
          end
        end     #page_parameters do
      end       #page_list do
      
      hidden_params =  set_alltohidden - show_params
      
      diff_params = []
      rt_params =  RtParameter.all(:select => 'mcfcrc, card_index, parameter_type, parameter_name', :conditions => ["current_value != default_value"])
      rt_params.each do |rt_param|
        diff_params << rt_param.mcfcrc.to_s + "." + rt_param.card_index.to_s + "." + rt_param.parameter_type.to_s + "." + rt_param.parameter_name.to_s
      end
      
      #Get the common records from both the arrays
      tobe_update = hidden_params & diff_params
      if !tobe_update.blank?
        tobe_update.each do |upd_param|
          param_fields = upd_param.split('.')
          RtParameter.update_all("current_value = default_value", :mcfcrc => param_fields[0], :card_index => param_fields[1],
                                :parameter_type => param_fields[2], :parameter_name => param_fields[3])
        end
      end      
    end       #if !page_list.blank?
    
  end
  
  def validate_build(site_path)
    pac_time = 0
    mcfdb_time = 0
    rtdb_time = 0
    nvconfig_time = 0
    packfile_name = ""
    Dir.foreach(site_path) do |pac| 
      if (File.fnmatch("CIC.BIN", File.basename(pac).upcase) || File.fnmatch("*.PAC", File.basename(pac).upcase) || File.fnmatch("*.TPL", File.basename(pac).upcase))
        packfile_name = pac
      end
    end
    
    if (!packfile_name.blank?)
      pac_time = File.mtime(site_path + "/" + packfile_name).to_i
      mcfdb_time = File.mtime(site_path + "/mcf.db").to_i
      rtdb_time = File.mtime(site_path + "/rt.db").to_i
      nvconfig_time = File.mtime(site_path + "/nvconfig.sql3").to_i   if File.exists?(site_path + "/nvconfig.sql3")
      
      if ((pac_time >= mcfdb_time) && (pac_time >= rtdb_time) && (pac_time >= nvconfig_time))
        return true
      else
        return false
      end
    else
      return false
    end   
    
  end

  def get_product_sites
    @current_product = params[:product_type]
    content_html =""
    root_entries = []
    
    if @current_product == "ALL"
      root_entries = []
      root_entries = session[:iviu_ptc_geo].concat(session[:iviu]).concat(session[:viu]).concat(session[:geo]).concat(session[:gcp]).concat(session[:geo_cpu3])
      unless root_entries.blank?
        content_html += select_tag("selected_folder", options_for_select(root_entries.uniq.sort.map{|x|[File.basename(x),x]},root_entries[0]),:class=>"contentCSPselOpen" ,:disabled =>false)        
      end
    elsif @current_product == "IVIU PTC GEO"
      unless session[:iviu_ptc_geo].blank?
        content_html += select_tag("selected_folder", options_for_select(session[:iviu_ptc_geo].map{|x|[File.basename(x),x]},session[:iviu_ptc_geo][0]),:class=>"contentCSPselOpen" ,:disabled =>false)        
      end
    elsif @current_product == "IVIU"
      unless session[:iviu].blank?
        content_html += select_tag("selected_folder", options_for_select(session[:iviu].map{|x|[File.basename(x),x]},session[:iviu][0]),:class=>"contentCSPselOpen" ,:disabled =>false)
      end
    elsif @current_product == "VIU"
      unless session[:viu].blank?
        content_html += select_tag("selected_folder", options_for_select(session[:viu].map{|x|[File.basename(x),x]},session[:viu][0]),:class=>"contentCSPselOpen" ,:disabled =>false)
      end
    elsif @current_product == "GEO"
      unless session[:geo].blank?
        content_html += select_tag("selected_folder", options_for_select(session[:geo].map{|x|[File.basename(x),x]},session[:geo][0]),:class=>"contentCSPselOpen" ,:disabled =>false)
      end
    elsif @current_product == "GCP"
      unless session[:gcp].blank?
        content_html += select_tag("selected_folder", options_for_select(session[:gcp].map{|x|[File.basename(x),x]},session[:gcp][0]),:class=>"contentCSPselOpen" ,:disabled =>false)
      end
    elsif @current_product == "GEO CPU3"
      unless session[:geo_cpu3].blank?
        content_html += select_tag("selected_folder", options_for_select(session[:geo_cpu3].map{|x|[File.basename(x),x]},session[:gcp_cpu3][0]),:class=>"contentCSPselOpen" ,:disabled =>false)
      end
    end
    if (content_html.length == 0)
      content_html += select_tag("selected_folder", options_for_select("Select","Select"),:class=>"contentCSPselOpen" ,:disabled =>false)
    end
    content_html+= ''    
    return content_html
  end
  
  def get_valid_site(site_name)    
    if File.directory?(site_name)
      return false
    else
      return true
    end
  end

  def generate_gcp_configuration_files(create_pac = true)
    
    if create_pac == true
      Dir.foreach(session[:cfgsitelocation]) do |x| 
        if(File.fnmatch('*.PAC', File.basename(x)) || File.fnmatch('*.TPL', File.basename(x)) || File.fnmatch('*report*.txt', File.basename(x)) || File.fnmatch('*.XML', File.basename(x)) || File.fnmatch('relaylogic.*', File.basename(x)))
          File.delete("#{session[:cfgsitelocation]}/#{x}")
        end
      end
    else
      Dir.foreach(session[:cfgsitelocation]) do |x| 
        if(File.fnmatch('*report*.txt', File.basename(x)) || File.fnmatch('relaylogic.*', File.basename(x)))
          File.delete("#{session[:cfgsitelocation]}/#{x}")
        end
      end
    end
    
      atcs_addr =  Gwe.find(:first, :select => "sin").try(:sin)
      # Create the PAC file using the rt , mcf , nvconfig
      if create_pac == true
        simulator = "\"#{session[:OCE_ROOT]}\\GCP_OCE_Manager.exe\", \"#{1}\" \"#{session[:cfgsitelocation]}\" \"#{session[:OCE_ROOT]}\""
        puts  simulator
        if system(simulator)
          puts "------------------------------- Pass Compress ----------------------"        
        else
          puts "------------------------------- Failed Compress ----------------------"
          return "Configuration file creation failed."
        end
      end
      packfile_name = ""
      Dir.foreach(session[:cfgsitelocation]) do |pac| 
        if (File.fnmatch("*.PAC", File.basename(pac)) || File.fnmatch("*.pac", File.basename(pac)))
          packfile_name = pac
        end
      end
      get_gcp_type
      if !@gcp_4000_version
        #Create Relay Logic pdf file #
        glFileName = session[:cfgsitelocation] + "/relaylogic.gl"
        createGLfile(glFileName)
        if File.exists?(glFileName)
          puts "----------------------Creating Relay Logic Pdf file --------------------"
          begin
            site_details = open_site_details("#{session[:cfgsitelocation]}/site_details.yml")
            mcfName = site_details["MCF Name"].strip.to_s
            mcfcrc = site_details["MCFCRC"].strip.to_s
            out_file = session[:cfgsitelocation] + '/' + "relaylogic.pdf"
            simulator = "\"#{session[:OCE_ROOT]}\\OceRelayLogic.exe\", \"#{converttowindowspath(glFileName)}\" \"#{converttowindowspath(out_file)}\" \"#{mcfName}\" \"#{mcfcrc}\" \"#{session[:sitename]}\" \"#{atcs_addr}\" \"#{packfile_name}\" \"#{session[:dot_num]}\""
            puts  simulator
            if system(simulator)
              puts "--------------------------- Pass -------------------------------"
            else
              puts "------------------------------ Fail ----------------------"
              return "Relay logic report failed."
            end
          rescue Exception => e
            puts e.inspect
          end
        end
      end
      
      simulator = "\"#{session[:OCE_ROOT]}\\GCP_OCE_Manager.exe\", \"#{3}\" \"#{session[:cfgsitelocation]}\" \"#{session[:OCE_ROOT]}\" \"#{atcs_addr}\""
      puts  simulator
      if system(simulator)
        puts "------------------------------- Pass Report Creation ----------------------"
        systemreportfile = ""
        Dir.foreach(session[:cfgsitelocation]) do |x| 
          if File.fnmatch("system_report*", File.basename(x))
            systemreportfile = x
          end
        end
        File.open(session[:cfgsitelocation]+'/'+ systemreportfile, "a+"){|f|
          f.puts
          f.puts
          f.puts "Configuration Package File"
          f.puts "=========================="
          f.puts 'Filename          : '+ packfile_name
          f.puts 'Path              : '+ session[:cfgsitelocation].gsub('/','\\') + "\\"
          newtime = Time.new
          todaydatetime = newtime.strftime("%d/%m/%Y %H:%M:%S")
          f.puts 'Date/Time         : '+ todaydatetime.to_s
          f.puts "OCE Version       : " + session[:webui_version]
        }        
      else
        puts "------------------------------- Failed Report Creation ----------------------"
        return "Configuration reports creation failed."
      end
      
      return ''
  end
  
  def get_gcp_templates
    templates = "#{RAILS_ROOT}/oce_configuration/templates"
    Dir.mkdir(templates) unless File.exists?(templates) 
    template_directory_name = "#{RAILS_ROOT}/oce_configuration/templates/gcp"
    Dir.mkdir(template_directory_name) unless File.exists?(template_directory_name)   
    @templates = Pathname.new(template_directory_name).children.select { |c| c.directory? && !(Dir.entries(c) == [".", ".."]) }.collect { |p| p.to_s }
  end
  
  def get_pac_files
    @pac_files = []
    root_directory = File.join(RAILS_ROOT, "/oce_configuration/#{session[:user_id].to_s}")
    root_entries = Dir[root_directory + "/*"].reject{|f| [".", "..", "#{root_directory}/tmp" , "#{root_directory}/xmltemplate" , "#{root_directory}/DT2" , "#{root_directory}/pac"].include?f }.reject { |f| !File.directory? f}
    for i in 0..(root_entries.length.to_i - 1)
      Dir.foreach(root_entries[i]) do |filelist| 
        if ((File.extname(filelist) == '.pac') || (File.extname(filelist) == '.PAC'))
          @pac_files << root_entries[i] + "/" + filelist          
        end
      end
    end
  end
  
  def get_mcf_name_and_mcfcrc
    rootpath = mcf_root_path('gcp')
    root_directory = File.join(RAILS_ROOT, "/oce_configuration/mcf/#{rootpath}")
    Dir.mkdir(root_directory) unless File.exists? root_directory
    mcf_files = Dir["#{root_directory}/*.mcf"].reject{|f| [".", ".."].include?f }
    mcf_name_and_mcfcrc = ""
    mcf_files.each do |mcf_file|
      if File.exists?(mcf_file)
        mcf_name = File.basename(mcf_file, '.*')
        mcfcrc_log = "#{mcf_name}.log"
        log_path = "#{root_directory}/#{mcfcrc_log}"
        mcfcrc = ""
        File.open(log_path).readlines.each do |line|
           chomp_line_val = line.chomp
           if chomp_line_val.include?('MCF CRC')
              mcf_crc_val = chomp_line_val.split('MCF CRC')
              if (mcf_crc_val.length > 1)
                get_mcf_crc = mcf_crc_val[1].upcase.split('X')
                mcfcrc = (get_mcf_crc.length >1)? get_mcf_crc[1].strip : get_mcf_crc[0].strip
              end
           end
        end
        mcf_name_and_mcfcrc = mcf_name_and_mcfcrc+"#{File.basename(mcf_file)}|#{mcfcrc}||" 
      end 
    end
    @mcf_name_and_mcfcrc = mcf_name_and_mcfcrc
  end
  
  def get_menus_list(mcfdb, db_mcfcrc)
    
    @main_menu = {}    
    parent_used = false
    check_parent = mcfdb.execute("select * from menus where parent != '(NULL)'")
    unless check_parent.blank?
      parent_used = true
    end
    if parent_used
      menus = mcfdb.execute("select menu_name, link, parent, page_name, show, enable, display_order from menus where mcfcrc = #{db_mcfcrc} and(target Not Like 'LocalUI') order by display_order")
    else
      menus = mcfdb.execute("Select page_name, next, page_index from pages where mtf_index = 0  and cdf Like 'CFGVIEWDATA.XML' " +
                            "AND length(page_group) = 0 " + 
                            " And page_name Not Like 'express:%' and page_name Not Like 'template:%'  and page_name Not Like 'setup:%' Order by page_index") 
                          #" And page_group Not Like 'express' and page_group Not Like 'template'  and page_group Not Like 'setup' Order by page_index")
      
      #menus = mcfdb.execute("Select name as menu_name, link, '' as parent, parent_id as page_name, 'true' as enable from tree_menus " +
      #          " Where parent_id Not like 'Template:%' and parent_id Not like 'express:%'  and parent_id Not like 'setup:%' order by display_order")      
    end
    if parent_used
      menus.each_with_index do |menu, index|
        if parent_used
          parent_name = (menu[2] == '(NULL)' && menu[3].eql?('MAIN PROGRAM menu')) ? 'ROOT' : menu[2]
        else
          parent_name = (menu[3].eql?('MAIN PROGRAM menu')) ? 'ROOT' : menu[3]
        end
        if @main_menu.has_key?(parent_name)
          menu_item = @main_menu[parent_name]
          menu_item << menu
          @main_menu[parent_name] = menu_item
        elsif (!parent_used && parent_name != 'MAIN PROGRAM menu') || (parent_used && parent_name != 'Vital Configuration')
          @main_menu[parent_name] = [menu]
        end
      end
      @menu_pages = []
      @main_menu['ROOT'].each_with_index do |menu, index|
        @menu_pages << {:menu_name=> menu[0] , :link => menu[1]}
        build_oce_gcp_pages(menu, index,'')
      end unless @main_menu.blank?
    else
      @menu_pages = []      
      @menu_pages << {:menu_name=> "TEMPLATE:  selection" , :link => "TEMPLATE:  selection"}
      menus.each_with_index do |menu, index|
        @menu_pages << {:menu_name=> menu[0] , :link => menu[0]}
      end
    end
    return @menu_pages.uniq

  end
  
  def build_oce_gcp_pages(parent, main_index, items = '')
    if parent[2].match("::")
      parent_menu = parent[2].split("::").first
      menu_name = "#{parent[0]}::#{parent_menu}" if !parent_menu.blank?
    elsif @main_menu[parent[0]].nil? && parent[1] == '(NULL)'
      menu_name =  "#{parent[0]}::#{parent[2]}"
    else
       menu_name =  (parent[1].blank? || parent[1] == '(NULL)') ?  parent[0] : parent[1]
    end
    @main_menu[menu_name].each_with_index do |menu1, index|
      if menu1[0] != '[Line]'
        if ((menu1[1] != '(NULL)') && (menu1[1].strip != "Set to Default"))
          page_list = Page.find_by_page_name(menu1[1], :include => [:tabs])
          tab_list = page_list.tabs if page_list
          if !tab_list.blank?
            tab_list.each do |tab|
              if !tab.blank?
                @menu_pages << {:menu_name => tab.link,:link=>tab.link}
              end
            end
          else
            @menu_pages << {:menu_name=> menu1[0] , :link => menu1[1]}
          end
        end
        if (menu1[0] != menu1[3]) && (menu1[0] != menu1[2]) && (@main_menu[menu1[0]] || menu1[1] == '(NULL)')
          sub_menu = build_oce_gcp_pages(menu1, index ,'')
        end
      end
    end unless @main_menu[menu_name].blank?

  end
  
  def get_card_type_index(mcfdb)
    card_types = mcfdb.execute("Select distinct card_index, crd_type, crd_name from cards where parameter_type = 2 " +
            " Order by crd_type, card_index")
    card_type_index = {}
    card_index = []     
    
    card_types.each_with_index do |crd, index|
      crd_type = crd[1].to_s + "_" + crd[2]
      if card_type_index.has_key?(crd_type)
        card_index = card_type_index[crd_type]
        card_index << crd[0]
        card_type_index[crd_type] = card_index
      else
        card_type_index[crd_type] = [crd[0]]
      end
    end
    return card_type_index
  end
  
  def get_vitalconfig_compared_records(db1, db1_mcfcrc, db2, db2_mcfcrc, db1_rt, db2_rt, import_flg = true)
    
    db1_pages = get_menus_list(db1, db1_mcfcrc)
    db2_pages = get_menus_list(db2, db2_mcfcrc)
    #active_mtf_index = current_config_info[0][3]
    extra_menus_db2  = db2_pages - db1_pages
    all_pages = db1_pages + extra_menus_db2
    db1_card_type_index = get_card_type_index(db1)
    db2_card_type_index = get_card_type_index(db2)
    card_index_map = {}
    card_index_map_21 = {}
    min_len = 0
    db1_card_type_index.each do |crd|
      db1_card = crd[0]
      db1_index = crd[1]
      db2_index = db2_card_type_index[db1_card]
      db1_length = db1_index.length
      db2_length = (db2_index.blank? ? 0 : db2_index.length) 
      if (db1_length <= db2_length)
        min_len = db1_length
      else
        min_len = db2_length
      end
      for i in 0..(min_len-1)
        card_index_map[db1_index[i]] = db2_index[i]
      end
      for i in 0..(min_len-1)
        card_index_map_21[db2_index[i]] = db1_index[i]
      end
    end
    # puts "*********************************"
    # puts card_index_map.inspect
    # puts card_index_map_21.inspect
    ############card_types = [15,8,14,29,9,18,100,101,21,20,22,89,91,93]
    page_result_display = []
    pac_records_display = []
    check_for_signed = false
    lst_tables = {:parameters => ["layout_index", "layout_type","cardindex", "parameter_type" ,"parameter_index" , "name" , "param_long_name" , "context_string"]}
    lst_tables.each do |table_name, columns|
      all_pages.each do |menu_page|
          not_in_import_package = []
          enumeration_not_found = []
          value_out_of_range = []
          not_in_current_configuration = []
          updated_from_pac = []
          db1_page_name = ""
          # db2_page_name = ""
          # db2_page_name = menu_page[:page_name].strip
          if (!menu_page[:menu_name].blank?)
            db1_page_name = menu_page[:menu_name].strip
            db1_results_params = db1.execute("Select DISTINCT param.* from page_parameter page_param inner join parameters param " +
                            "on page_param.mcfcrc = param.mcfcrc And page_param.layout_index = param.layout_index " +
                            "And page_param.parameter_name = param.name And page_param.card_index = param.cardindex " +
                            "And page_param.parameter_type = 2 Where  (target Not Like 'LocalUI') and page_name Like '#{menu_page[:menu_name].strip}' " + 
                            "ORDER BY param.cardindex, param.parameter_index")
          end
          if db1_results_params.blank?
            if !menu_page[:link].blank?
              db1_page_name = menu_page[:link].strip
              db1_results_params = db1.execute("Select DISTINCT param.* from page_parameter page_param inner join parameters param " +
                            "on page_param.mcfcrc = param.mcfcrc And page_param.layout_index = param.layout_index " +
                            "And page_param.parameter_name = param.name And page_param.card_index = param.cardindex " +
                            "And page_param.parameter_type = 2 Where  (target Not Like 'LocalUI') and page_name Like '#{menu_page[:link].strip}' " + 
                            "ORDER BY param.cardindex, param.parameter_index")
            end
          end
          
          if (!menu_page[:menu_name].blank?)
            db2_results_params = db2.execute("Select DISTINCT param.* from page_parameter page_param inner join parameters param " +
                            "on page_param.mcfcrc = param.mcfcrc And page_param.layout_index = param.layout_index " +
                            "And page_param.parameter_name = param.name And page_param.card_index = param.cardindex " +
                            "And page_param.parameter_type = 2 Where  (target Not Like 'LocalUI') and page_name Like '#{menu_page[:menu_name].strip}' " + 
                            "ORDER BY param.cardindex, param.parameter_index")
          end
          if db2_results_params.blank?
            if !menu_page[:link].blank?
              db2_results_params = db2.execute("Select DISTINCT param.* from page_parameter page_param inner join parameters param " +
                            "on page_param.mcfcrc = param.mcfcrc And page_param.layout_index = param.layout_index " +
                            "And page_param.parameter_name = param.name And page_param.card_index = param.cardindex " +
                            "And page_param.parameter_type = 2 Where  (target Not Like 'LocalUI') and page_name Like '#{menu_page[:link].strip}' " + 
                            "ORDER BY param.cardindex, param.parameter_index")
            end
          end
          db1_v_results_formated = []
          db2_v_results_formated = []
          db1_results_params.each do |db1_res|
            # "layout_index"(1), "layout_type"(2),"cardindex"(3), "parameter_type"(4) ,"parameter_index"(5) , "name"(6) , "param_long_name"(7) , "context_string"(9) , int_type_name(20) , enum_type_name(21)
            db1_v_results_formated << [db1_res[1],db1_res[2], db1_res[3] , db1_res[4] , db1_res[5] , db1_res[6] , db1_res[7] ,db1_res[9], db1_res[20] , db1_res[21], db1_res[14]].join('_$$_')
          end

          db2_results_params.each do |db2_res|
            # "layout_index"(1), "layout_type"(2),"cardindex"(3), "parameter_type"(4) ,"parameter_index"(5) , "name"(6) , "param_long_name"(7) , "context_string"(9) , int_type_name(20) , enum_type_name(21)
            db2_v_results_formated << [db2_res[1],db2_res[2], db2_res[3] , db2_res[4] , db2_res[5] , db2_res[6] , db2_res[7] ,db2_res[9], db2_res[20] , db2_res[21], db2_res[14]].join('_$$_')
          end

          db1_v_results_formated.each do |res_db1_result_value|
            column_values = res_db1_result_value.split("_$$_")
            db2_card_index = card_index_map[column_values[2].to_i]
            
            rt_where_conditions = "parameter_type =2 and card_index= #{column_values[2]} and parameter_name Like '#{column_values[5]}'"              
            rt1_current_value = db1_rt.execute("Select current_value , default_value from rt_parameters where #{rt_where_conditions}")
            if !db2_card_index.blank?
              rt2_where_conditions = "parameter_type =2 and card_index= #{db2_card_index} and parameter_name Like '#{column_values[5]}'"
              rt2_current_value = db2_rt.execute("Select current_value , default_value from rt_parameters where #{rt2_where_conditions}")
              db2_where_condition = "parameter_type =2 and cardindex= #{db2_card_index} and name Like '#{column_values[5]}'"             
            else
              rt2_current_value = nil
            end
            
            if (db1_page_name == "TEMPLATE:  selection")
              puts "-------------------Template Selection------------------"
              if (rt1_current_value[0][0].to_i > 1)
                parameter_name = column_values[6] # Display long name
                parameter_name = column_values[5] if column_values[6].blank? # display the params name if long name not available
                enum_type_name = column_values[9]
                enum_long_name = db1.execute("select * from enumerators where layout_index = #{column_values[0]} and layout_type =#{column_values[1]} and enum_type_name like '#{enum_type_name}' and long_name NOT LIKE '%.xml' and value =#{rt2_current_value[0][0].to_i}")
                updated_from_pac << {:context_string => column_values[7] , :parameter_name => parameter_name, :value => enum_long_name[0][3] , :unit => "", :old_param_name => ""}
              end
              next
            end

            if rt2_current_value.blank?
              # Update current value to default value
              update_default_value_query = "update rt_parameters set current_value= #{rt1_current_value[0][1].to_i} Where #{rt_where_conditions}"
              db1_rt.execute(update_default_value_query)
              value = ""
              unit = ""
              parameter_name = column_values[6] # Display long name
              parameter_name = column_values[5] if column_values[6].blank? # display the params name if long name not available
              if (!column_values[9].blank? && column_values[10] == "Enumeration")    # ENUM type params
                enum_type_name = column_values[9]
                enum_long_name = db1.execute("select * from enumerators where layout_index = #{column_values[0]} and layout_type =#{column_values[1]} and enum_type_name like '#{enum_type_name}' and long_name NOT LIKE '%.xml' and value =#{rt1_current_value[0][1].to_i}")
                value = enum_long_name[0][3]
              else
                if !column_values[8].blank?
                  int_type_name = column_values[8]
                  value = rt1_current_value[0][1]
                  unit_rec = db1.execute("select imperial_unit from integertypes where layout_index = #{column_values[0]} and layout_type =#{column_values[1]} and int_type_name like '#{int_type_name}'")
                  unit = unit_rec[0][0] if !unit_rec.blank?
                else
                  value = rt1_current_value[0][1]
                end
              end
              #not_in_import_package << {:context_string => column_values[7] , :parameter_name => parameter_name, :value => value , :unit => unit}
            elsif (rt1_current_value[0][0].to_i == rt2_current_value[0][0].to_i )
              next
            elsif (rt1_current_value[0][0].to_i != rt2_current_value[0][0].to_i)
              unit = ""
              value_display_name = ""
              old_param_name = ""
              parameter_name = column_values[6] # Display long name
              parameter_name = column_values[5] if column_values[6].blank? # display the params name if long name not available
              
              param_long_name_result = db2.execute("Select param_long_name from parameters where #{db2_where_condition}")
              if !(param_long_name_result.blank?)
                old_param_long_name = param_long_name_result[0][0].to_s
                if (parameter_name != old_param_long_name)
                  old_param_name = "Old Name: #{old_param_long_name}"  
                end
              end
              if (!column_values[9].blank? && column_values[10] == "Enumeration")    # ENUM type params
                enum_type_name = column_values[9]
                enum_long_name = db1.execute("select * from enumerators where layout_index = #{column_values[0]} and layout_type =#{column_values[1]} and enum_type_name like '#{enum_type_name}' and long_name NOT LIKE '%.xml' and value =#{rt2_current_value[0][0].to_i}")
                db2_enum_long_name = db2.execute("select * from enumerators where layout_index = #{column_values[0]} and layout_type =#{column_values[1]} and enum_type_name like '#{enum_type_name}' and long_name NOT LIKE '%.xml' and value =#{rt2_current_value[0][0].to_i}")
                if (!db2_enum_long_name.blank? && !enum_long_name.blank? && (enum_long_name[0][3].to_s != db2_enum_long_name[0][3].to_s))
                  if (old_param_name.blank?)
                    old_param_name = "Old Value: #{db2_enum_long_name[0][3]}"
                  else
                    old_param_name = old_param_name + ", Old Value: #{db2_enum_long_name[0][3]}"
                  end
                end
                if !old_param_name.blank?
                  old_param_name = "(#{old_param_name})"
                end
                #if (enum_long_name.blank? || (enum_long_name[0][3].to_s != db2_enum_long_name[0][3].to_s))
                if (enum_long_name.blank?)
                  default_display_name = db1.execute("select * from enumerators where layout_index = #{column_values[0]} and layout_type =#{column_values[1]} and enum_type_name like '#{enum_type_name}' and long_name NOT LIKE '%.xml' and value =#{rt1_current_value[0][1].to_i}")
                  value_update = rt1_current_value[0][1]
                  value_display_name = default_display_name[0][3]
                  enumeration_not_found << {:context_string => column_values[7] , :parameter_name => parameter_name, :value => value_display_name , :unit => unit, :old_param_name => old_param_name}
                else
                  value_update = enum_long_name[0][5]
                  updated_from_pac << {:context_string => column_values[7] , :parameter_name => parameter_name, :value => enum_long_name[0][3] , :unit => unit, :old_param_name => old_param_name}
                end
              else
                if !old_param_name.blank?
                  old_param_name = "(#{old_param_name})"
                end
                if !column_values[8].blank? # Int type params
                  int_type_name = column_values[8]                  
                  #imperial_unit(0) ,size(1) , scale_factor(2) , lower_bound(3) , upper_bound(4) , signed_number(5)
                  integertypes_condition_val = db1.execute("select imperial_unit ,size , scale_factor , lower_bound , upper_bound , signed_number from integertypes where layout_index = #{column_values[0]} and layout_type =#{column_values[1]} and int_type_name like '#{int_type_name}'")
                  if !integertypes_condition_val.blank?
                    if !integertypes_condition_val[0][5].blank? && integertypes_condition_val[0][5] == 'Yes'
                      max = get_signed_value(integertypes_condition_val[0][4], integertypes_condition_val[0][1])
                      min = get_signed_value(integertypes_condition_val[0][3], integertypes_condition_val[0][1])
                      rt2_newval = get_signed_value(rt2_current_value[0][0], integertypes_condition_val[0][1])
                      check_for_signed == true
                    else
                      check_for_signed = false
                      max = integertypes_condition_val[0][4]
                      min = integertypes_condition_val[0][3]
                      rt2_newval = rt2_current_value[0][0]
                    end
                    
                    if ((rt2_newval.to_i >= min.to_i) && (rt2_newval.to_i <= max.to_i))
                      value_update = rt2_current_value[0][0]                                          
                      factor = (integertypes_condition_val[0][2].to_f / 1000).to_f
                      value_display_name = rt2_newval.to_f * factor
                      unit = integertypes_condition_val[0][0]
                      updated_from_pac << {:context_string => column_values[7] , :parameter_name => parameter_name, :value => value_display_name.to_i , :unit => unit, :old_param_name => old_param_name}
                    else
                      value_update = rt1_current_value[0][1]
                      factor = (integertypes_condition_val[0][2].to_f / 1000).to_f
                      value_display_name = value_update.to_f * factor
                      unit = integertypes_condition_val[0][0]
                      value_display_name = get_signed_value(value_display_name, integertypes_condition_val[0][1]) if check_for_signed == true
                      value_out_of_range << {:context_string => column_values[7] , :parameter_name => parameter_name, :value => value_display_name.to_i , :unit => unit}
                    end
                  else
                    unit = ""
                    value_display_name = rt2_newval
                    updated_from_pac << {:context_string => column_values[7] , :parameter_name => parameter_name, :value => value_display_name.to_i , :unit => unit, :old_param_name => ""}
                  end
                else # other than int/enum type name
                  value_update = rt1_current_value[0][0]
                end
              end
              
              # Update rt 2 current value to rt1 current value 
              update_default_value_query = "update rt_parameters set current_value = #{value_update.to_i} Where #{rt_where_conditions}"
              db1_rt.execute(update_default_value_query)
            end
          end #db1_v_results_formated.each
          
          db2_v_results_formated.each do |res_db2_result_value|
            column_values = res_db2_result_value.split("_$$_")
            db1_card_index = card_index_map_21[column_values[2].to_i]
            if !db1_card_index.blank?
              rt_where_conditions = "parameter_type =2 and card_index= #{db1_card_index} and parameter_name Like '#{column_values[5]}'"
              rt1_current_value = db1_rt.execute("Select current_value , default_value from rt_parameters where #{rt_where_conditions}")
            else
              rt1_current_value = nil
            end

            #rt2_where_conditions = "parameter_type =2 and card_index= #{column_values[2]} and parameter_name Like '#{column_values[5]}'"
            rt2_where_conditions = "parameter_type =2 and card_index= #{column_values[2]} and (current_value != default_value) and parameter_name Like '#{column_values[5]}'"
            rt2_current_value = db2_rt.execute("Select current_value , default_value from rt_parameters where #{rt2_where_conditions}")
            if (rt1_current_value.blank?) && (!rt2_current_value.blank?)
              value = ""
              unit = ""
              parameter_name = column_values[6] # Display long name
              parameter_name = column_values[5] if column_values[6].blank? # display the params name if long name not available
              if (!column_values[9].blank? && column_values[10] == "Enumeration")    # ENUM type params
                enum_type_name = column_values[9]
                enum_long_name = db2.execute("select * from enumerators where layout_index = #{column_values[0]} and layout_type =#{column_values[1]} and enum_type_name like '#{enum_type_name}' and long_name NOT LIKE '%.xml' and value =#{rt2_current_value[0][0].to_i}")
                value = enum_long_name[0][3]
              else
                if !column_values[8].blank?
                  int_type_name = column_values[8]
                  value = rt2_current_value[0][0]
                  unit = db2.execute("select imperial_unit from integertypes where layout_index = #{column_values[0]} and layout_type =#{column_values[1]} and int_type_name like '#{int_type_name}'").collect{|v|v[0]}
                else
                  value = rt2_current_value[0][1]
                end
              end
              not_in_current_configuration << {:context_string => column_values[7] , :parameter_name => parameter_name, :value => value , :unit => unit}
            end
          end # db2_v_results_formated.each
          
          if (db1_page_name == "SITE:  programming")
            if (!@location_params.blank?)
              @location_params.each do |loc|
                updated_from_pac << loc
              end
            end
          end
          if !not_in_import_package.blank? || !enumeration_not_found.blank? || !value_out_of_range.blank? || !updated_from_pac.blank?
            page_result_display << {:page_name => db1_page_name , :not_in_import_package => not_in_import_package ,:enumeration_not_found => enumeration_not_found , :value_out_of_range => value_out_of_range, :updated_from_pac => updated_from_pac}             
          end
          if !not_in_current_configuration.blank?
            pac_records_display << {:page_name => db1_page_name , :not_in_current_configuration => not_in_current_configuration}
          end
      end # card_types.each
    end # lst_tables.each
    
    return page_result_display, pac_records_display
    
  end

  def validate_pac_tpl_with_mcf(mcf_path, xml_path)
    mcf_location = ""
    pac_location = ""
    File.open(mcf_path).readlines.each do |mcf_line|
      if(mcf_line.start_with?("Location Name"))
        if(mcf_line.strip.end_with?("4000"))
          mcf_location = "4k"
        else
          mcf_location = "5k"
        end
        break
      end
    end
    
    if File.exists?(xml_path)
      doc = Document.new File.new(xml_path)
      cpu_versions = ""      
      doc.elements.each("MCFPackage/CardData/CPUVersion"){|element|
        cpu_versions = element.text
      }
      cpu_version = Document.new cpu_versions      
      cpu_version.elements.each("*/MCFLocation"){|ele|
        pac_location = ele.text.strip
      }
    end
    if(pac_location.upcase.start_with?("GCP"))
      if(pac_location.upcase.end_with?("4000"))
        pac_location = "4k"
      else
        pac_location = "5k"
      end
    end
    
    if (mcf_location == pac_location)
      return true
    else
      return false
    end   
    
  end
  
  def read_pac_tpl_cpuversion_details(directory, pac_path, xml_path)
    mcf_name = ""
    mcf_crc = ""
    mcf_location = ""    
    simulator = "\"#{session[:OCE_ROOT]}\\GCP_OCE_Manager.exe\", \"#{7}\" \"#{directory}\" \"#{session[:OCE_ROOT]}\" \"#{pac_path}\" \"#{xml_path}\""
    puts simulator.inspect
    if system(simulator)
      error_log = directory+'\oce_gcp_error.log'
      result,content = read_error_log_file(error_log)
      if(result == true)
        #render :json=>{:error=>true,:error_message => content}and return
        return mcf_name.strip , mcf_crc.upcase, mcf_location, "true", content
      end
      puts 'get_pac_details -PASS'
    else
      puts 'get_pac_details - FAIL'
    end
    if File.exists?(xml_path)
      doc = Document.new File.new(xml_path)
      cpu_versions = ""
      mcf_crc = ""
      doc.elements.each("MCFPackage/CardData/CPUVersion"){|element|
        cpu_versions = element.text
      }
      cpu_version = Document.new cpu_versions
      cpu_version.elements.each("*/MCFCRC"){|ele|
        mcf_crc = ele.text
      }
      cpu_version.elements.each("*/MCFName"){|ele|
        mcf_name = ele.text
      }
      cpu_version.elements.each("*/MCFLocation"){|ele|
        mcf_location = ele.text.strip
      }
    end
    if mcf_crc.to_i < 1
    mcf_crc = (mcf_crc.to_i % 2**32).to_s(16)
    else
    mcf_crc = (mcf_crc.to_i).to_s(16)
    end
    mcf_crc = mcf_crc.to_s.rjust(8,'0') if mcf_crc.length < 8    
    return mcf_name.strip , mcf_crc.upcase, mcf_location, "", ""
  end

end
