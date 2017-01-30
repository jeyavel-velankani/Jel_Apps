####################################################################
# Company: Siemens 
# Author: 
# File: ViewptcstatusController
# Description: Display PTC Status
####################################################################
class ViewptcstatusController < ApplicationController  
 layout "general" 
 
  ####################################################################
  # Function:      index
  # Parameters:    none
  # Retrun:        none
  # Renders:       :partial => "view_ptc"
  # Description:   Displays PTC Status Table
  ####################################################################
 def index
    @ptc_status = RtStatus.find_by_sql("SELECT ot.type_name, o.object_name, o.object_state, o.ptc_msg_code, o.subnode_slot_name, o.subnode_slot_number, o.track_name, o.time 
                                        FROM PTC_Objects o, PTC_Object_Types ot WHERE o.type_id = ot.id;")
    @ptc_gen_stat =  { "HB-BEACON" => nil,"HB-BTTL" => nil, "PTC-GPS" => nil, "PTC-CLASSD" => nil}
    @ptc_gen_stat_obj = Generalststistics.find(:all,:conditions => ["stat_name in('HB-BEACON','HB-BTTL','PTC-GPS','PTC-CLASSD')"])
          
      @ptc_gen_stat_obj.each do |r|
      @ptc_gen_stat['HB-BEACON'] = r if r.stat_name == "HB-BEACON"
      @ptc_gen_stat['HB-BTTL'] = r if r.stat_name == "HB-BTTL"  
      @ptc_gen_stat['PTC-GPS'] = r if r.stat_name == "PTC-GPS"
      @ptc_gen_stat['PTC-CLASSD'] = r if r.stat_name == "PTC-CLASSD"
    end
    if params[:auto_refresh]
      render :partial => "view_ptc"
    end
 end
end
