class RtSession < ActiveRecord::Base
  set_table_name "rt_sessions"
  set_primary_key 'request_id'
  establish_connection :real_time_db
  
  def self.find_rt_atcs
    rt_sessions = self.all(:conditions => ["comm_status =1 and task_description like ?", "%Ready%"])
    sparameter = []
    rt_sessions.each {|rtd| sparameter += StringParameter.find(:all, :select => "Description, ID, String, Name, Group_Channel", :conditions => ["String = ?", rtd.atcs_address], :limit => 1)}
    return sparameter
  end
  
  # Added for Geo log verbosity   
  def self.find_rt_atcs_new
    rt_sessions = self.all(:conditions => ["comm_status =1 and task_description like ?", "%Ready%"])
    sparameter = []
    rt_sessions.each {|rtd| sparameter += StringParameter.find(:all,  :select => "Description, ID, String, Name, Group_Channel", :conditions => ["String = ?", rtd.atcs_address], :limit => 1)}
    return sparameter
  end  
  
  def self.find_rt_atcs_addr
    rt_sessions = self.all(:conditions => ["comm_status =1 and status =10 and task_description like ?", "%Ready%"])
  end  
  
  # Code Optimized and modified by Kalyan
  def self.find_atcs_addrs
    
    sub_nodes = IntegerParameter.all(:select => "Group_Channel, Value", :conditions => ["Group_ID = ? and Name like 'ATCS Subnode%'", 1007501])
    enum_parameters = EnumParameter.all(:select => "Group_Channel, Selected_Value_ID", :conditions => ["Group_Id = ? and Name like 'Type'", 25], :include => [:enum_value])
    site_info = NvConfig.find(:all,:select => "Group_ID, String as str2, Default_String", :conditions => ["Group_id = ? AND Name like 'ATCS%'", 1]).map(&:str2)
    strings = StringParameter.all(:select => "Description, ID, String as str1, Name, Group_Channel", :conditions => ["Group_ID = ? and Name =?", 25, 'Name']).map(&:str1)
    
    unless sub_nodes.blank? && site_info.nil? && strings.blank? && enum_parameters.blank?
      atcs_address = site_info[0].split(".")
      atcs_address.delete(atcs_address.last)
      atcs_address = atcs_address.join(".")
      nodes = []
      sub_nodes.each do |node|
        enum_parameter = enum_parameters.find{|parameter| parameter.Group_Channel == node.Group_Channel }
        nodes << (node.Value < 10 ? (atcs_address + ".0" + node.Value.to_s) : (atcs_address + "." + node.Value.to_s)) if enum_parameter.enum_value.Name == "GEO" 
      end
      rt_sessions = RtSession.all(:select => "atcs_address", :conditions => {:comm_status => 1, :status => 10, :task_description => "Ready"}).map(&:atcs_address)
      results = []
      
      nodes.uniq.each_with_index do |node, i|
        results << [(node + ' |' + ' ' + strings[i]), node] if rt_sessions.include?(node)
      end
      return results
    else
      return []
    end
  end
  
  def self.find_atcs_addrsupload
    sub_nodes = IntegerParameter.all(:select => "Value", :conditions => ["Group_ID = ? and Name like 'ATCS Subnode%'", 1007501]).map(&:Value)
    site_info = NvConfig.find(:first, :select => "Group_ID, String as str2, Default_String", :conditions => ["Group_id = ? AND Name like 'ATCS%'", 1])
    strings = StringParameter.all(:select => "Description, ID, String as str1, Name, Group_Channel", :conditions => ["Group_ID = ? and Name =?", 25, 'Name']).map(&:str1)
    unless sub_nodes.blank? && site_info.nil? && strings.blank? 
      atcs_address = site_info.str2.split(".")
      atcs_address.delete(atcs_address.last)
      atcs_address = atcs_address.join(".")
      nodes = []
      sub_nodes.each do |node|
        nodes << (node < 10 ? (atcs_address + ".0" + node.to_s) : (atcs_address + "." + node.to_s))   
      end
      rt_sessions = RtSession.all(:select => "atcs_address", :conditions => {:comm_status => 1, :status => 10, :task_description => "Ready"}).map(&:atcs_address)
      results = []
      nodes.uniq.each_with_index do |node, i|
        results << [(node + '.01'), node] if rt_sessions.include?(node)
      end
      return results
    else
      return []
    end
  end
  
  def self.find_all_atcs_addresses
    sub_nodes = IntegerParameter.all(:select => "Group_Channel, Value", :conditions => ["Group_ID = ? and Name like 'ATCS Subnode%'", 1007501])
    site_info = NvConfig.find(:first, :select => "Group_ID, String as str2, Default_String", :conditions => ["Group_id = ? AND Name like 'ATCS%'", 1])
    strings = StringParameter.all(:select => "Description, ID, String as str1, Name, Group_Channel", :conditions => ["Group_ID = ? and Name =?", 25, 'Name']).map(&:str1)
    enum_parameters = EnumParameter.all(:select => "Group_Channel, Selected_Value_ID", :conditions => ["Group_Id = ? and Name like 'Type'", 25], :include => [:enum_value])
    
    unless sub_nodes.blank? && site_info.nil? && strings.blank? && enum_parameters.blank? 
      atcs_address = site_info.str2.split(".")
      console_vcpu_atcs_address = site_info.str2 #.split(".")
      atcs_address.delete(atcs_address.last)
      atcs_address = atcs_address.join(".")
      nodes = []
      sub_nodes.each do |node|
        enum_parameter = enum_parameters.find{|parameter| parameter.Group_Channel == node.Group_Channel }
        nodes << (node.Value < 10 ? (atcs_address + ".0" + node.Value.to_s) : (atcs_address + "." + node.Value.to_s)) if enum_parameter.enum_value.Name == "GEO"   
      end
      rt_sessions = RtSession.all(:select => "atcs_address", :conditions => {:comm_status => 1, :status => 10, :task_description => "Ready"}).map(&:atcs_address)
      results = []
      nodes.uniq.each_with_index do |node, i|
        results << [(node + ' |' + ' ' + strings[i]), node] if rt_sessions.include?(node)
      end
      node =  console_vcpu_atcs_address  + ' | Console VCPU'
      results << node
      return results
    else
      return []
    end
  end
  
  def self.find_atcs_gcp
    dest_address  = Gwe.find(:first)
    rtsession = RtSession.find_by_atcs_address(dest_address.sin)
    if rtsession.comm_status == 1 && rtsession.status == 10
     return [rtsession.atcs_address]
    else
     return []
    end
  end
  
  def self.ready?
    dest_address  = Gwe.find(:first)
    if dest_address
      rtsession = RtSession.find_by_atcs_address(dest_address.sin)
      if rtsession
        if rtsession.comm_status == 1 && rtsession.status == 10
         return true
        end
      end
    end
    return false
  end
end
