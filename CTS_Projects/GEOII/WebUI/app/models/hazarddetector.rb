class Hazarddetector < ActiveRecord::Base
  
  set_table_name "HazardDetector"
  establish_connection :site_ptc_db if OCE_MODE == 1
  belongs_to "ptcdevice", :foreign_key => "Id"
    
  def self.select_logicstate_query(id)
    Hazarddetector.find(:all,:select=>"NumberOfLogicStates",:conditions=>['Id=?',id])
  end

  def self.Update_numberoflogic_states(numberoflogicstates,id)
      Hazarddetector.update_all "NumberOfLogicStates = '#{numberoflogicstates}'", "Id = '#{id}'"
  end
  
  def self.select_hazarddetector_id()
        Hazarddetector.find(:all,:select=>"Id")
  end
  
  def self.select_all_hd(installationname)
    Hazarddetector.find_by_sql("Select s.Id from HazardDetector s inner join PTCDevice p on s.Id = p.Id and p.WSMMsgPosition >0 and p.InstallationName='#{installationname}' Order by p.WSMBitPosition")
  end
  
  def self.select_all_hazarddetectordetails()
    Hazarddetector.find_by_sql("Select p.Id as ID,p.PTCDeviceName as Name ,p.Subnode as Subnode,p.TrackNumber as Tracknumber from HazardDetector s inner join PTCDevice p on s.Id = p.Id Order by p.WSMBitPosition")
  end

  def self.create_hazard(newid,number_of_logic_states)
    new_signal = Hazarddetector.new

    new_signal.Id = newid

    if number_of_logic_states
      new_signal.NumberOfLogicStates = number_of_logic_states
    end

    new_signal.save
  end
end
