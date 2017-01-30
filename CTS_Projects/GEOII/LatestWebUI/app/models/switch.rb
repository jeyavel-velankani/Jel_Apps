class Switch < ActiveRecord::Base
  set_table_name "Switch"
  establish_connection :site_ptc_db if OCE_MODE == 1
  belongs_to "ptcdevice", :foreign_key => "Id"
  has_many "logicstates", :foreign_key => "Id", :dependent => :destroy
  before_destroy :destroy_logic_states
  def destroy_logic_states
     Logicstate.delete_all({:Id => self.id})
  end
  
  def self.select_logicstate_query(id)
    Switch.find(:all,:select=>"NumberOfLogicStates",:conditions=>['Id=?',id])
  end
  
  def self.Update_numberoflogic_states(numberoflogicstates,id)
      Switch.update_all "NumberOfLogicStates =  '#{numberoflogicstates}'", "Id = '#{id}'"
  end
  
  def self.select_switch_id()
        Switch.find(:all,:select=>"Id")
  end
  
   def self.select_all_switch(installationname)
     Switch.find_by_sql("Select s.Id from Switch s inner join PTCDevice p on s.Id = p.Id and p.WSMMsgPosition >0 and p.InstallationName='#{installationname}' Order by p.WSMBitPosition")
  end
  
  def self.select_all_switchdetails()
    Switch.find_by_sql("Select p.Id as ID,p.PTCDeviceName as Name ,p.Subnode as Subnode,p.TrackNumber as Tracknumber from Switch s inner join PTCDevice p on s.Id = p.Id Order by p.WSMBitPosition")
  end

  def self.create_switch(newid,switch_type,number_of_logic_states)
    new_signal = Switch.new

    new_signal.Id = newid

    if switch_type
      new_signal.SwitchType = switch_type
    end

    if number_of_logic_states
      new_signal.NumberOfLogicStates = number_of_logic_states
    end
    
    new_signal.save
  end
  
end
