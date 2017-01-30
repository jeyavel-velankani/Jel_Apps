class Ptcdevice < ActiveRecord::Base
  
  set_table_name "PTCDevice"
  set_primary_key "Id"
  establish_connection :site_ptc_db if OCE_MODE == 1
  # Associations between model Ptcdevice and other models
  belongs_to "installationtemplate"
  has_one "signal", :class_name => "Signals", :dependent => :destroy, :foreign_key => "Id"
  has_one "switch", :class_name => "Switch", :dependent => :destroy, :foreign_key => "Id"
  has_one "hazarddetector", :class_name => "Hazarddetector", :dependent => :destroy, :foreign_key => "Id"
  has_many "logicstates", :foreign_key => "Id", :dependent => :destroy
  
  def self.Update_ptcdevicedetails_all(id,devicename,trackname,subnode)
    Ptcdevice.update_all "PTCDeviceName = '#{devicename}' , Subnode =  '#{subnode}' , TrackNumber =  '#{trackname}'" ,"Id = '#{id}'"
  end
  
  def self.Getdevicedetails_select_query(id)
    Ptcdevice.find_by_id(id)
  end
  
  def self.sigl_select_query(id)
    Signal.find_by_id(id)
  end
  
  def self.select_distinctinstallation_name()
    Ptcdevice.find(:all,:select=>"Distinct InstallationName")
  end
  
  def self.select_ptcdevice_value(id)
    Ptcdevice.find(:all, :conditions=>['Id=?',id])
  end
  
  def self.Update_Device_Tracknumber(id,tracknumber)
    Ptcdevice.update_all "TrackNumber =  '#{tracknumber}'", "Id = '#{id}'"
  end

  def self.create_device(newid,tracknumber,trackname,device_name,inst_name,sitedeviceid,subnode,direction,milepost,subdivnumber,sitename,description)
    new_device = Ptcdevice.new

    new_device.Id = newid
    new_device.WSMMsgPosition = 999
    new_device.WSMBitPosition = 0

    if tracknumber
      new_device.TrackNumber = tracknumber
    end 

    if trackname
      new_device.TrackName = "#{trackname}"
    end

    if device_name
      new_device.PTCDeviceName = "#{device_name}"
    end

    if inst_name
     new_device.InstallationName = "#{inst_name}"
    end

    if sitedeviceid
      new_device.SiteDeviceID = "#{sitedeviceid}"
    end

    if subnode
      new_device.Subnode = subnode
    end

    if direction
      new_device.Direction = "#{direction}"
    end

    if milepost
      new_device.Milepost = "#{milepost}"
    end

    if subdivnumber
      new_device.SubdivisionNumber = "#{subdivnumber}"
    end

    if sitename
      new_device.SiteName = "#{sitename}"
    end

    if description
      new_device.Description = "#{description}"
    end
    
    new_device.save
  end

  def self.create_ptc_device(msgpos,bitpos,device_name,inst_name,sitedeviceid,subnode,direction,gc_name,track_num)
    new_device = Ptcdevice.new
    new_device.WSMMsgPosition = msgpos
    new_device.WSMBitPosition = bitpos   
    new_device.PTCDeviceName = "#{device_name}"
    new_device.InstallationName = "#{inst_name}"
    new_device.SiteDeviceID = "#{sitedeviceid}"
    new_device.Subnode = subnode
    new_device.Direction = direction
    new_device.GCName = "#{gc_name}"
    new_device.TrackName = "Track " + track_num.to_s
    new_device.save
    return new_device.Id
  end
  
  #update msgpos, bitpos with device id
  def self.update_device_msgpos_and_bitpos(msgpos , bitpos , deviceid)
    Ptcdevice.update_all("WSMMsgPosition = #{msgpos}, WSMBitPosition = \"#{bitpos}\"", {:id => deviceid.to_i })
  end
  
  def self.Update_ptcsitedeviceid_all
    Ptcdevice.update_all "SiteDeviceID = PTCDeviceName Where SiteDeviceID is NULL"
  end
  
end
