class Signals < ActiveRecord::Base
  set_table_name "Signal"
  establish_connection :site_ptc_db if OCE_MODE == 1
  belongs_to "ptcdevice", :foreign_key => "Id"
  has_many "logicstates", :foreign_key => "Id", :dependent => :destroy
  before_destroy :destroy_logic_states
    
  def self.select_logicstate_query(id)
    Signals.find(:all,:select=>"NumberOfLogicStates",:conditions=>['Id=?',id]).map(&:NumberOfLogicStates)
  end
  
  def self.Update_numberoflogic_states(numberoflogicstates,id)
      Signals.update_all "NumberOfLogicStates =  '#{numberoflogicstates}'", "Id = '#{id}'"
  end
  
  def self.select_all_signal(installationname)
    Signals.find_by_sql("Select s.Id from Signal s inner join PTCDevice p on s.Id = p.Id and p.WSMMsgPosition >0 and p.InstallationName='#{installationname}' Order by p.WSMBitPosition")
  end
  
  def self.select_all_signalsdetails()
    Signals.find_by_sql("Select p.Id as ID,p.PTCDeviceName as Name ,p.Subnode as Subnode,p.TrackNumber as Tracknumber from Signal s inner join PTCDevice p on s.Id = p.Id Order by p.WSMBitPosition")
  end

  def self.select_signals_id()
      Signals.find(:all,:select=>"Id").map(&:id)
  end
  def destroy_logic_states
     Logicstate.delete_all({:Id => self.id})
  end
      
  def self.create_signal(newid,number_of_logic_states,stop_aspect)
    new_signal = Signals.new

    new_signal.Id = newid

    if number_of_logic_states
       new_signal.NumberOfLogicStates = number_of_logic_states
    end

    if stop_aspect
      new_signal.StopAspect = stop_aspect
    end

    new_signal.save
  end
end
