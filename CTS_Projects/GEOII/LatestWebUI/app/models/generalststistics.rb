class Generalststistics < ActiveRecord::Base
  set_table_name "General_Statistics"
  establish_connection :real_time_status_db

  
  def self.vcpu_ptc_ucn
    Generalststistics.find(:all,:select=>'stat_text', :conditions=>['stat_name= ?','VCPU_PTC_UCN'])
  end
  
  def self.get_ethernet_status # can make it more generic but passing more parameters, for nw not required
    if Generalststistics.isUSB?
      Generalststistics.find(:all, :conditions=>['stat_name like ?','%ETH%'], :order=>"stat_name")
    else 
      Generalststistics.find(:all, :conditions=>['stat_name like ?','%ETH0%'], :order=>"stat_name")
    end
  end

  def self.isPTC?
  	ptc = Generalststistics.find(:first,:conditions=>['stat_name = ?','PTC-WIU'])

  	if ptc 
      if ptc.stat_value == 1
  		  return true
      end
  	end

    return false
  end

  def self.isUSB?
    usb = Generalststistics.find(:first,:conditions=>['stat_name = ?','USBPresent'])

    if usb 
      if usb.stat_value == 1
         return true
      end      
    end

    return false
  end
  
  def self.update_ptc_enable
    Generalststistics.update_all("stat_value=1","stat_name='PTC-WIU'")
  end
  
  def self.vlp_sin
    sin = Generalststistics.find(:first,:conditions=>['stat_name = ?','VLPSIN'])
    if sin 
      return sin.stat_text
    end
    return "7.000.000.000.00"
  end

end
