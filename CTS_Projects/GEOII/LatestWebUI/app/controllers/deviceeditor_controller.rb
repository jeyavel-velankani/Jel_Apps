####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: deviceeditor_controller.rb
# Description: This module will display the selected GEO PTC Database installation device details  
####################################################################
#History:
# Log: /wayside/GEOII/Trunk/Software/WebUI/app/controllers/deviceeditor_controller.rb
#
# Rev 4881   July 30 2013 18:00:00   Jeyavel
# Added the get_goltype method to get the GOL Type
#
# Rev 4707   July 15 2013 18:00:00   Jeyavel
# Initial version
class DeviceeditorController < ApplicationController
  layout "general"

  ####################################################################
  # Function:      index
  # Parameters:    session[:mantmasterdblocation]
  # Retrun:        None
  # Renders:       None
  # Description:   Display the Device editor page
  ####################################################################
  def index
    if session[:user_id] == nil
      redirect_to :controller => 'access', :action=> 'login_form'
    else
      unless session[:mantmasterdblocation].blank?
        @mcf_installations =Installationtemplate.find(:all , :order => 'InstallationName COLLATE NOCASE').map(&:InstallationName)
      else
        @mcf_installations = ""
        session[:selectedins] = ""
      end
      @ATCSConfig = ""
      session[:ATCSConfig] = ""
      @device = ""
      @gol_type = ""
      session[:device] = ""
      unless session[:message_deviceeditor].blank?
        flash[:editornotice] = session[:message_deviceeditor]
        session[:message_deviceeditor] = ""
        @mcf_installations = Installationtemplate.find(:all , :order => 'InstallationName COLLATE NOCASE').map(&:InstallationName)
        session[:selectedins] = session[:displayinstallation]
        @ATCSConfig = Atcsconfig.find(:all,:select =>"Distinct(Subnode)" ,:conditions => ['InstallationName=?',session[:selectedins]] ,:order => 'Subnode' ).map(&:Subnode)
        session[:ATCSConfig] = session[:displayatcs].to_i
        @device = Ptcdevice.find(:all,:select =>"PTCDeviceName ,Id" ,:conditions => ['InstallationName=? and Subnode=?',session[:selectedins],session[:ATCSConfig]] )
        session[:device] = session[:displaydevice].to_i
        @gol_type =  get_goltype(session[:selectedins])
      else
        flash[:editornotice]=""
        session[:message_deviceeditor] = nil
        session[:selectedins] = ""
        session[:displayinstallation] =""
        session[:displayatcs]=""
        session[:displaydevice] =""
      end
    end
  end
  
  ####################################################################
  # Function:      inserlogicstatevalues
  # Parameters:    nooflogicstate , arrayvalues , newrowid
  # Retrun:        None
  # Renders:       None
  # Description:   Insert the logic state values
  ####################################################################  
  def inserlogicstatevalues(nooflogicstate , arrayvalues , newrowid)
    @count = nooflogicstate
    @updatearrayvalue = arrayvalues
    newid = newrowid
    for i in 1...(@count.to_i+1)
      case i
        when 1
        unless getfieldvalue(@updatearrayvalue , 16).blank?
          db = SQLite3::Database.new(session[:mantmasterdblocation])
          db.execute( "Insert into LogicState values('#{getfieldvalue(@updatearrayvalue , 16)}','#{getfieldvalue(@updatearrayvalue , 17)}','#{getfieldvalue(@updatearrayvalue , 18)}','#{newid}')" )
          db.close
        end
        when 2
        unless getfieldvalue(@updatearrayvalue , 19).blank?
          db = SQLite3::Database.new(session[:mantmasterdblocation])
          db.execute( "Insert into LogicState values('#{getfieldvalue(@updatearrayvalue , 19)}','#{getfieldvalue(@updatearrayvalue , 20)}','#{getfieldvalue(@updatearrayvalue , 21)}','#{newid}')" )
          db.close
        end
        
        when 3
        unless getfieldvalue(@updatearrayvalue , 22).blank?
          db = SQLite3::Database.new(session[:mantmasterdblocation])
          db.execute( "Insert into LogicState values('#{getfieldvalue(@updatearrayvalue , 22)}','#{getfieldvalue(@updatearrayvalue , 23)}','#{getfieldvalue(@updatearrayvalue , 24)}','#{newid}')" )
          db.close
        end
        when 4
        unless getfieldvalue(@updatearrayvalue , 25).blank?
          db = SQLite3::Database.new(session[:mantmasterdblocation])
          db.execute( "Insert into LogicState values('#{getfieldvalue(@updatearrayvalue , 25)}','#{getfieldvalue(@updatearrayvalue, 26)}','#{getfieldvalue(@updatearrayvalue , 27)}','#{newid}')" )
          db.close
        end
        when 5
        unless getfieldvalue(@updatearrayvalue , 36).blank?
          db = SQLite3::Database.new(session[:mantmasterdblocation])
          db.execute( "Insert into LogicState values('#{getfieldvalue(@updatearrayvalue , 36)}','#{getfieldvalue(@updatearrayvalue, 37)}','#{getfieldvalue(@updatearrayvalue , 38)}','#{newid}')" )
          db.close
        end
        when 6
        unless getfieldvalue(@updatearrayvalue , 39).blank?
          db = SQLite3::Database.new(session[:mantmasterdblocation])
          db.execute( "Insert into LogicState values('#{getfieldvalue(@updatearrayvalue , 39)}','#{getfieldvalue(@updatearrayvalue, 40)}','#{getfieldvalue(@updatearrayvalue , 41)}','#{newid}')" )
          db.close
        end
      end
    end
  end
  
  ####################################################################
  # Function:      update_device_details
  # Parameters:    params[:result]
  # Retrun:        None
  # Renders:       render :text=>""
  # Description:   Update/Insert the PTCDevice details 
  ####################################################################  
  def update_device_details
    @updatevalue = params[:result]
    @updatearrayvalue = @updatevalue.split(',')
    i=1
    @updatearrayvalue.each do |devicevalue|
      i =i+1
    end
    if (getfieldvalue(@updatearrayvalue,0)== "new")
      @devices = Ptcdevice.find(:all,:select =>"Id").sort{|device1, device2| device2.Id <=> device1.Id }
      unless @devices.blank?
        newid = @devices[0].Id.to_i+1
      else
        newid = 1
      end
      maxbitpostion = Ptcdevice.find(:all,:select=>"WSMBitPosition",:conditions =>"WSMBitPosition IN(select max(WSMBitPosition) from PTCDevice  where InstallationName='#{getfieldvalue(@updatearrayvalue,2)}')").map(&:WSMBitPosition)
      db = SQLite3::Database.new(session[:mantmasterdblocation])
      tracknumber = getintegervalue(getfieldvalue(@updatearrayvalue,4))
      devicebitpos = 0
      if getfieldvalue(@updatearrayvalue,5)=="Signal"
        devicebitpos = maxbitpostion[0].to_i+5
      elsif getfieldvalue(@updatearrayvalue,5)=="Switch"
        devicebitpos = maxbitpostion[0].to_i+2
      elsif getfieldvalue(@updatearrayvalue,5)=="Hazard Detector"
        devicebitpos = maxbitpostion[0].to_i+1
      end
      maxmsgpostion = Ptcdevice.find(:all,:select=>"WSMMsgPosition",:conditions =>"WSMMsgPosition IN(select max(WSMMsgPosition) from PTCDevice  where InstallationName='#{getfieldvalue(@updatearrayvalue,2)}')").map(&:WSMMsgPosition)
      db.execute( "Insert into PTCDevice (Id ,TrackNumber , WSMMsgPosition , WSMBitPosition , PTCDeviceName , InstallationName , SiteDeviceID , Subnode , Direction , Milepost , SubdivisionNumber , SiteName , GCName) values('#{newid}',#{tracknumber},'#{maxmsgpostion[0].to_i+1}','#{devicebitpos}','#{getfieldvalue(@updatearrayvalue,3)}','#{getfieldvalue(@updatearrayvalue,2)}',null,'#{getfieldvalue(@updatearrayvalue,1)}' , null , null , null , null , null)" )
      db.close
      if getfieldvalue(@updatearrayvalue,5) == "Signal"
        db = SQLite3::Database.new(session[:mantmasterdblocation])
        aspectid1 = getintegervalue(getfieldvalue(@updatearrayvalue,29))
        aspectid2 = getintegervalue(getfieldvalue(@updatearrayvalue,31))
        aspectid3 = getintegervalue(getfieldvalue(@updatearrayvalue,33))
        stopaspect = getintegervalue(getfieldvalue(@updatearrayvalue,8))
        db.execute( "Insert into Signal (Id , NumberOfLogicStates , Conditions , StopAspect , HeadA , HeadB , HeadC , AspectId1 , AltAspect1 , AspectId2 , AltAspect2 , AspectId3 , AltAspect3) values('#{newid}','#{getfieldvalue(@updatearrayvalue,12)}','#{getfieldvalue(@updatearrayvalue,7)}',#{stopaspect},'#{getfieldvalue(@updatearrayvalue,9)}','#{getfieldvalue(@updatearrayvalue,10)}','#{getfieldvalue(@updatearrayvalue,11)}',#{aspectid1},'#{getfieldvalue(@updatearrayvalue,30)}', #{aspectid2} ,'#{getfieldvalue(@updatearrayvalue,32)}', #{aspectid3} ,'#{getfieldvalue(@updatearrayvalue,34)}')" )
        db.close
        if getfieldvalue(@updatearrayvalue,12)
          @count = getfieldvalue(@updatearrayvalue,12)
          inserlogicstatevalues(@count ,@updatearrayvalue ,newid)
        end
      elsif getfieldvalue(@updatearrayvalue,5) == "Switch"
        db = SQLite3::Database.new(session[:mantmasterdblocation])
        db.execute( "Insert into Switch values('#{newid}','#{getfieldvalue(@updatearrayvalue,13)}','#{getfieldvalue(@updatearrayvalue,14)}')" )
        db.close
        if getfieldvalue(@updatearrayvalue,14)
          @count1 = getfieldvalue(@updatearrayvalue,14)
          inserlogicstatevalues(@count1 ,@updatearrayvalue ,newid)
        end
      elsif getfieldvalue(@updatearrayvalue,5) == "Hazard Detector"
        db = SQLite3::Database.new(session[:mantmasterdblocation])
        db.execute( "Insert into HazardDetector values('#{newid}','#{getfieldvalue(@updatearrayvalue,15)}')" )
        db.close
        if getfieldvalue(@updatearrayvalue,15)
          @count2 = getfieldvalue(@updatearrayvalue,15)
          inserlogicstatevalues(@count2 ,@updatearrayvalue ,newid)
        end
      end
      session[:displayinstallation] = getfieldvalue(@updatearrayvalue,2)
      session[:displayatcs] = getfieldvalue(@updatearrayvalue,1)
      session[:displaydevice] = newid
      order_element_msgposition_bitposition(getfieldvalue(@updatearrayvalue,2))
      session[:message_deviceeditor] ="Successfully updated device values."
      
    elsif (getfieldvalue(@updatearrayvalue,0)== "edit")
      
      exist_nooflogic_state =  getfieldvalue(@updatearrayvalue,35)
      device_name = getfieldvalue(@updatearrayvalue,3)
      track_number = getintegervalue(getfieldvalue(@updatearrayvalue,4))
      @device_id = getfieldvalue(@updatearrayvalue,28)
      Ptcdevice.update_all("TrackNumber = #{track_number},PTCDeviceName = \"#{device_name}\"", {:id => @device_id})
      mcf_names = Mcfphysicallayout.find(:all, :select =>"MCFName", :conditions => {:InstallationName => getfieldvalue(@updatearrayvalue,2)}).map(&:MCFName).uniq #ptcdevices.map(&:mcfname).uniq
      goltype = Mcfptc.find_by_MCFName(mcf_names[0], :select => "GOLType").try(:GOLType).to_s == "1" ? "Non Appliance Model" : "Appliance Model"
      
      signals = Signals.find(:all ,:conditions =>['Id=?',@device_id])
      unless signals.blank?
        aspectid1 = getintegervalue(getfieldvalue(@updatearrayvalue,29))
        aspectid2 = getintegervalue(getfieldvalue(@updatearrayvalue,31))
        aspectid3 = getintegervalue(getfieldvalue(@updatearrayvalue,33))
        stopaspect = getintegervalue(getfieldvalue(@updatearrayvalue,8))
        add_nooflogicstate = getfieldvalue(@updatearrayvalue,12)
        nooflogicstate = 0
        unless add_nooflogicstate.blank?
          nooflogicstate = exist_nooflogic_state.to_i + add_nooflogicstate.to_i
        else
          nooflogicstate = exist_nooflogic_state.to_i
        end
        if goltype == "Non Appliance Model"
          Signals.update_all("NumberOfLogicStates = #{nooflogicstate},HeadA = \"#{getfieldvalue(@updatearrayvalue,9)}\",HeadB = \"#{getfieldvalue(@updatearrayvalue,10)}\",HeadC = \"#{getfieldvalue(@updatearrayvalue,11)}\", AspectId1 = #{aspectid1},AltAspect1 = \"#{getfieldvalue(@updatearrayvalue,30)}\",AspectId2 = #{aspectid2},AltAspect2 = \"#{getfieldvalue(@updatearrayvalue,32)}\",AspectId3 = #{aspectid3},AltAspect3 = \"#{getfieldvalue(@updatearrayvalue,34)}\"", {:id => @device_id})
        else
          Signals.update_all("NumberOfLogicStates = #{nooflogicstate},Conditions = \"#{getfieldvalue(@updatearrayvalue,7)}\",StopAspect = #{stopaspect} , AspectId1 = #{aspectid1}, AltAspect1 = \"#{getfieldvalue(@updatearrayvalue,30)}\", AspectId2 = #{aspectid2}, AltAspect2 = \"#{getfieldvalue(@updatearrayvalue,32)}\", AspectId3 = #{aspectid3}, AltAspect3 = \"#{getfieldvalue(@updatearrayvalue,34)}\"", {:id => @device_id})                 
        end
        updatelogicstatevalues(@updatearrayvalue , nooflogicstate , @device_id)
      end
      switch = Switch.find(:all ,:conditions =>['Id=?',@device_id])
      unless switch.blank?
        add_nooflogicstate = getfieldvalue(@updatearrayvalue,14)
        nooflogicstate = 0
        unless add_nooflogicstate.blank?
          nooflogicstate = exist_nooflogic_state.to_i + add_nooflogicstate.to_i
        else
          nooflogicstate = exist_nooflogic_state.to_i
        end
        Switch.update_all("SwitchType = #{nooflogicstate},NumberOfLogicStates = #{nooflogicstate}", {:id => @device_id})
        updatelogicstatevalues(@updatearrayvalue , nooflogicstate , @device_id)
      end
      
      hazarddetector = Hazarddetector.find(:all ,:conditions =>['Id=?',@device_id])
      unless hazarddetector.blank?
        add_nooflogicstate = getfieldvalue(@updatearrayvalue,15)
        nooflogicstate = 0
        unless add_nooflogicstate.blank?
          nooflogicstate = exist_nooflogic_state.to_i + add_nooflogicstate.to_i
        else
          nooflogicstate = exist_nooflogic_state.to_i
        end
        Hazarddetector.update_all("NumberOfLogicStates = #{nooflogicstate}", {:id => @device_id})
        updatelogicstatevalues(@updatearrayvalue , nooflogicstate , @device_id)
      end
      session[:displayinstallation] = getfieldvalue(@updatearrayvalue,2)
      session[:displayatcs] = getfieldvalue(@updatearrayvalue,1)
      session[:displaydevice] = @device_id
      session[:message_deviceeditor] ="Successfully updated device values."
    end
    render :text=>""
  end
  
  ####################################################################
  # Function:      updatelogicstatevalues
  # Parameters:    arrayvalues , nooflogicstate , deviceid
  # Retrun:        None
  # Renders:       None
  # Description:   Insert the logic state values according to the input values
  ####################################################################  
  def updatelogicstatevalues(arrayvalues , nooflogicstate , deviceid)
    @updatearrayvalue = arrayvalues
    @deviceid = deviceid
    currentvalue = Logicstate.find(:all,:conditions =>{:Id=>@deviceid.to_i})
    ctcount = currentvalue.length
    #   No of logic state value are equal or not if it's equal will update existing values , not means will insert the new record in Logicstate table. 
    if ((ctcount.to_i == nooflogicstate.to_i) || (ctcount.to_i > nooflogicstate.to_i) || (ctcount.to_i < nooflogicstate.to_i))
      Logicstate.delete_logicstate_id(@device_id)
      for i in 1...(nooflogicstate.to_i+1)
        case i
          when 1
          db = SQLite3::Database.new(session[:mantmasterdblocation])
          db.execute( "Insert into LogicState values('#{getfieldvalue(@updatearrayvalue , 16)}','#{getfieldvalue(@updatearrayvalue , 17)}','#{getfieldvalue(@updatearrayvalue , 18)}','#{@deviceid}')" )
          db.close
          when 2
          db = SQLite3::Database.new(session[:mantmasterdblocation])
          db.execute( "Insert into LogicState values('#{getfieldvalue(@updatearrayvalue , 19)}','#{getfieldvalue(@updatearrayvalue , 20)}','#{getfieldvalue(@updatearrayvalue , 21)}','#{@deviceid}')" )
          db.close
          when 3
          db = SQLite3::Database.new(session[:mantmasterdblocation])
          db.execute( "Insert into LogicState values('#{getfieldvalue(@updatearrayvalue , 22)}','#{getfieldvalue(@updatearrayvalue , 23)}','#{getfieldvalue(@updatearrayvalue , 24)}','#{@deviceid}')" )
          db.close
          when 4
          db = SQLite3::Database.new(session[:mantmasterdblocation])
          db.execute( "Insert into LogicState values('#{getfieldvalue(@updatearrayvalue , 25)}','#{getfieldvalue(@updatearrayvalue, 26)}','#{ getfieldvalue(@updatearrayvalue , 27)}','#{@deviceid}')" )
          db.close
          when 5
          db = SQLite3::Database.new(session[:mantmasterdblocation])
          db.execute( "Insert into LogicState values('#{getfieldvalue(@updatearrayvalue , 36)}','#{getfieldvalue(@updatearrayvalue , 37)}','#{getfieldvalue(@updatearrayvalue , 38)}','#{@deviceid}')" )
          db.close
          when 6
          db = SQLite3::Database.new(session[:mantmasterdblocation])
          db.execute( "Insert into LogicState values('#{getfieldvalue(@updatearrayvalue , 39)}','#{getfieldvalue(@updatearrayvalue, 40)}','#{ getfieldvalue(@updatearrayvalue , 41)}','#{@deviceid}')" )
          db.close
        end
      end
    end
  end
  
  ####################################################################
  # Function:      getfieldvalue
  # Parameters:    values ,position
  # Retrun:        result
  # Renders:       None
  # Description:   Get the field value from the string
  ####################################################################  
  def getfieldvalue(values ,position)
    @values = values
    result =  @values[position.to_i].split('=')[1]
    return result
  end
  
  ####################################################################
  # Function:      installationnameselect
  # Parameters:    params[:InstallationName]
  # Retrun:        atcsvalues
  # Renders:       render :text
  # Description:   Get the ATCS sub node value for selected installation name
  ####################################################################  
  def installationnameselect
    approvedcrc = ""
    gol_type = ""
    if params[:InstallationName]
      atcs_config = Atcsconfig.find(:all,:select =>"Distinct(Subnode)" ,:conditions => ['InstallationName=?',params[:InstallationName]] ).map(&:Subnode)
      gol_type = get_goltype(params[:InstallationName])
    else
      atcs_config = ""
      session[:ATCSConfig] = ""
    end
    atcsvalues =""
    unless atcs_config.blank?
      atcs_config.each do |atcs|
        atcsvalues <<'|'<< atcs.to_s
      end
    end
    installationexist = Approval.find(:last,:conditions=>{:InstallationName => params[:InstallationName] },:order=>'ApprovalDate, ApprovalTime ASC') 
    unless installationexist.blank?
      if installationexist.ApprovalStatus == "Approved"
        approvedcrc = '0x'+installationexist.ApprovalCRC.to_i.to_s(16).upcase
      else
        approvedcrc = ""
      end 
    else
      approvedcrc = ""
    end
    atcsvalues << '|' << approvedcrc << '|' << gol_type
    render :text =>atcsvalues
  end
  
  ####################################################################
  # Function:      selatcsconfig
  # Parameters:    params[:InstallationName] , params[:atcsconfig]
  # Retrun:        None
  # Renders:       render :text
  # Description:   Get device details using the ATCS sub node and installationname
  ####################################################################  
  def selatcsconfig
    if params[:atcsconfig] && params[:InstallationName]
      @device = Ptcdevice.find(:all,:select =>"PTCDeviceName ,Id" ,:conditions => ['InstallationName=? and Subnode=?',params[:InstallationName],params[:atcsconfig]] )
    end
    devicevalues = ""
    unless @device.blank?
      @device.each do |device|
        devicevalues << '|' << device.Id.to_s << ','<< device.PTCDeviceName 
      end
    end
    render :text =>devicevalues
  end
  
  ####################################################################
  # Function:      getdevicedetails
  # Parameters:    params[:Id]
  # Retrun:        returnvalue
  # Renders:       None
  # Description:   Get the device details
  ####################################################################  
  def getdevicedetails
    devicedetails = ""
    devicetype = ""
    session[:selecteddeviceid] = params[:Id]
    unless session[:mantmasterdblocation].blank?
      devicedetails = Ptcdevice.find(:all,:conditions =>['Id=?',params[:Id]])
      signals = Signals.find(:all ,:conditions =>['Id=?',devicedetails[0].Id])
      switch = Switch.find(:all ,:conditions =>['Id=?',devicedetails[0].Id])
      hazarddetector = Hazarddetector.find(:all ,:conditions =>['Id=?',devicedetails[0].Id])
      unless signals.blank?
        devicetype = "Signal"
      end
      unless switch.blank?
        devicetype = "Switch"
      end
      unless hazarddetector.blank?
        devicetype = "Hazard Detector"
      end
    end
    returnvalue = ""
    if (devicetype == "Signal")
      signals = Signals.find(:all , :conditions =>['Id=?',devicedetails[0].Id])
      returnvalue << '|' << devicetype << '|' << devicedetails[0].PTCDeviceName << '|' <<  if devicedetails[0].TrackNumber then devicedetails[0].TrackNumber.to_s else " " end<< '|' <<  if signals[0].Conditions then signals[0].Conditions.to_s else " " end << '|' << if signals[0].StopAspect then signals[0].StopAspect.to_s else " " end << '|' << if signals[0].HeadA then signals[0].HeadA.to_s else " " end << '|' << if signals[0].HeadB then signals[0].HeadB.to_s else " " end << '|' << if signals[0].HeadC then signals[0].HeadC.to_s else " " end << '|' << if signals[0].NumberOfLogicStates then signals[0].NumberOfLogicStates.to_s else " " end << '|' << if signals[0].AspectId1 then signals[0].AspectId1.to_s else " " end << '|'<< if signals[0].AltAspect1 then signals[0].AltAspect1.to_s else " " end << '|' << if signals[0].AspectId2 then signals[0].AspectId2.to_s else " " end << '|' << if signals[0].AltAspect2 then signals[0].AltAspect2.to_s else " " end << '|' << if signals[0].AspectId3 then signals[0].AspectId3.to_s else " " end << '|'<< if signals[0].AltAspect3 then signals[0].AltAspect3.to_s else " " end
    end
    if (devicetype == "Switch")
        switch = Switch.find(:all , :conditions =>['Id=?',devicedetails[0].Id])
        returnvalue << '|' << devicetype << '|' << devicedetails[0].PTCDeviceName << '|' <<  if devicedetails[0].TrackNumber then devicedetails[0].TrackNumber.to_s else " " end<< '|' <<  if switch[0].SwitchType then switch[0].SwitchType.to_s else " " end << '|' << if switch[0].NumberOfLogicStates then switch[0].NumberOfLogicStates.to_s else " " end    
    end
    if (devicetype == "Hazard Detector")
          hazarddetectors = Hazarddetector.find(:all , :conditions =>['Id=?',devicedetails[0].Id])
          returnvalue << '|' << devicetype << '|' << devicedetails[0].PTCDeviceName << '|' <<  if devicedetails[0].TrackNumber then devicedetails[0].TrackNumber.to_s else " " end<< '|' << if hazarddetectors[0].NumberOfLogicStates then hazarddetectors[0].NumberOfLogicStates.to_s else " " end   
    end
    render :text =>returnvalue
  end

  ####################################################################
  # Function:      logicstates
  # Parameters:    params[:DeviceId]
  # Retrun:        returnlogicstates
  # Renders:       None
  # Description:   Get the Logic states values for selected device id
  ####################################################################
  def logicstates
    returnlogicstates = ""
    @logicstates = Logicstate.find(:all , :conditions =>{:Id => params[:DeviceId].to_i}).sort{|card1, card2| card1.BitPosn <=> card2.BitPosn }
    @logicstates.each do |logicstate|
      returnlogicstates << "#{logicstate.LogicStateNumber.to_s},#{logicstate.BitPosn.to_s},#{logicstate.ContiguousCount.to_s}|"
    end
    render :text => returnlogicstates
  end
  
  ####################################################################
  # Function:      removedevice
  # Parameters:    params[:selecteddeviceid] 
  # Retrun:        None
  # Renders:       None
  # Description:   Remove the selected device from the installation
  ####################################################################
  def removedevice
    installationame = Ptcdevice.find(:all,:conditions=>["Id=?",params[:selecteddeviceid]]).map(&:InstallationName)
    Ptcdevice.destroy_all("Id like '#{params[:selecteddeviceid]}'")
    signals = Signals.find(:all ,:conditions =>['Id=?',params[:selecteddeviceid]])
    unless signals.blank?
      Signals.delete_all("Id like '#{params[:selecteddeviceid]}'")
    end
    switch = Switch.find(:all ,:conditions =>['Id=?',params[:selecteddeviceid]])
    unless switch.blank?
      Switch.delete_all("Id like '#{params[:selecteddeviceid]}'")
    end
    hazarddetector = Hazarddetector.find(:all ,:conditions =>['Id=?',params[:selecteddeviceid]])
    unless hazarddetector.blank?
      Hazarddetector.delete_all("Id like '#{params[:selecteddeviceid]}'")
    end
    order_element_msgposition_bitposition(installationame[0].to_s)
    render :text => "Removed device successfully"
  end

  ####################################################################
  # Function:      order_element_msgposition_bitposition
  # Parameters:    installationname
  # Retrun:        None
  # Renders:       None
  # Description:   Update the device msg_position , bit_position values
  ####################################################################
  def order_element_msgposition_bitposition(installationname)
    installationname = installationname.blank? ? Installationtemplate.find(:first).try(:InstallationName) : installationname
    @sig = Ptcdevice.find(:all , :conditions =>"Id IN(select p.Id from PTCDevice p, Signal h where p.InstallationName='#{installationname}' and p.WSMMsgPosition >0 and p.id=h.id order by p.Id)")
    @swi = Ptcdevice.find(:all , :conditions =>"Id IN(select p.Id from PTCDevice p, Switch h where p.InstallationName='#{installationname}' and p.WSMMsgPosition >0 and p.id=h.id order by p.Id)")
    @hd = Ptcdevice.find(:all , :conditions =>"Id IN(select p.Id from PTCDevice p, HazardDetector h where p.InstallationName='#{installationname}' and p.WSMMsgPosition >0 and p.id=h.id order by p.Id)")
    @count =1
    iStartBitPos = 0;
    @elementorder = [["Signal" ,1],["Switch" ,2],["Hazard Detector" ,3]] #session[:elementorder]
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
  end

  ####################################################################
  # Function:      getintegervalue
  # Parameters:    values
  # Retrun:        returnvalue
  # Renders:       None
  # Description:   check confirm field
  ####################################################################        
  def getintegervalue(values)
    unless values.blank?
      returnvalue = values.to_i
    else
      returnvalue = "null"
    end
    return returnvalue            
  end
  
  ####################################################################
  # Function:      deletelogicstate
  # Parameters:    params[:deviceid] , params[:logicstatenumber] , params[:devicetype]
  # Retrun:        successmessage
  # Renders:       render :text
  # Description:   Delete the selected logic state from the device
  ####################################################################        
  def deletelogicstate
    deviceid = params[:deviceid]
    removelogicstateno = params[:logicstatenumber]
    devicetype = params[:devicetype]
    removedidflag = Logicstate.delete_all(['Id = ? and LogicStateNumber = ?', deviceid , removelogicstateno])
    successmessage = "Success"
    nooflogicstate = 0
    if removedidflag == 1 
      if (devicetype == "Signal")  
        logicstate_count = Signals.find(:all,:select => "NumberOfLogicStates" ,:conditions =>["Id = ?",deviceid]).map(&:NumberOfLogicStates)
        nooflogicstate = logicstate_count[0] - 1
        Signals.update_all("NumberOfLogicStates = #{nooflogicstate}", {:id => deviceid })
      elsif (devicetype == "Switch")
        logicstate_count = Switch.find(:all,:select =>"NumberOfLogicStates",:conditions =>["Id = ?",deviceid]).map(&:NumberOfLogicStates)
        nooflogicstate = logicstate_count[0] - 1
        Switch.update_all("NumberOfLogicStates = #{nooflogicstate}", {:id => deviceid })
      elsif (devicetype == "Hazard Detector")
        logicstate_count = Hazarddetector.find(:all,:select => "NumberOfLogicStates" , :conditions =>["Id = ?",deviceid]).map(&:NumberOfLogicStates)
        nooflogicstate = logicstate_count[0] - 1
        Hazarddetector.update_all("NumberOfLogicStates = #{nooflogicstate}", {:id => deviceid })
      end
    else
      successmessage = "Failed"
    end
    render :text => successmessage
  end 
  
  ####################################################################
  # Function:      get_goltype
  # Parameters:    installation_name
  # Retrun:        goltype
  # Renders:       None
  # Description:   Get the Gol Type using the installation name
  ####################################################################  
  def get_goltype(installation_name)
      mcf_names = Mcfphysicallayout.find(:all, :select =>"MCFName", :conditions => {:InstallationName => installation_name.to_s}).map(&:MCFName).uniq 
      goltype = Mcfptc.find_by_MCFName(mcf_names[0], :select => "GOLType").try(:GOLType).to_s == "1" ? "NONAM" : "AM"
      return goltype
  end
end