module DiagnosticTerminalHelper
  
  def find_rtparameters(id)
    RtParameter.find(:all, :conditions => {:channel_id => id}, :order=> "parameter_index")
  end
  
  def find_geo_parameter(val)
    GeoParameter.find(:first, :conditions => {:mcfcrc => val.mcfcrc, :card_index => val.card_index, :parameter_index => val.parameter_index})
  end
  
  def geo_enumerator(gpmeter, para_index)
    GeoEnumerator.find(:first, :conditions => ["short_label = ? and value =?", gpmeter.enum_type_name, para_index.current_value])
  end
  
  # Finding Channel Title
  def get_rt_channel_name(channel)
    channel.channel_name.blank? ? (channel.channel_name2.blank? ? channel.channel_type : channel.channel_name2) : (channel.channel_name + channel.channel_name2).upcase 
  end
  
  def include_config_javascript(mcfcrc)
    if Menu.count(:conditions => {:mcfcrc => mcfcrc}) == 0 || GeoParameter.count(:conditions => {:mcfcrc => mcfcrc}) == 0 
      javascript_include_tag("jquery.contextmenu", 'module_config_information_am')
    else
      javascript_include_tag("jquery.contextmenu", 'module_config_information')
    end
  end
end
