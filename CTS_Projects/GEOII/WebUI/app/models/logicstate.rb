class Logicstate < ActiveRecord::Base
  
  set_table_name "LogicState"
  set_primary_key "Id"  
#  belongs_to "PTCDevice", :class_name => "Ptcdevice"
  establish_connection :site_ptc_db if OCE_MODE == 1
  
   def self.select_logicstate_id()
        Logicstate.find(:all,:select=>"Distinct id")
  end
  def self.delete_logicstate_id(id)
        Logicstate.delete_all(['id=?',id])
  end
  
end
