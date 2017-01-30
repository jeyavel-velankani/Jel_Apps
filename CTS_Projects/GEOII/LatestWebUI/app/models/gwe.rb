class Gwe < ActiveRecord::Base
  # set_table_name "rt_gwe"
  # set_primary_key "sin"
  establish_connection :real_time_db

  @@mcfcrc = nil
  @@physical_layout = nil

  def self.mcfcrc
    return @@mcfcrc || Gwe.refresh_mcfcrc
  end

  def self.refresh_mcfcrc
    # @@mcfcrc = Gwe.find(:first, :select => "mcfcrc").try(:mcfcrc) || 0
  end

  def self.reset_mcfcrc
    @@mcfcrc = 0
  end

  def self.getmcfcrc(atcsaddress)
    Gwe.find(:first, :select=>'mcfcrc', :conditions=>['sin = ?',atcsaddress])
  end

  def self.get_mcfcrc(atcs_address)
    Gwe.find(:last, :conditions => ["sin = ?", atcs_address],
             :select => "mcfcrc, active_physical_layout, active_logical_layout, active_mtf_index") unless atcs_address.blank?
  end

  def self.atcs_address
    find_by_sql("select atcs_address from rt_sessions INNER JOIN rt_gwe on rt_sessions.atcs_address = rt_gwe.sin where rt_sessions.comm_status = 1 and rt_sessions.task_description like '%Ready%'").first.try(:atcs_address)
  end

  def self.physical_layout
    return Gwe.find(:first, :select => "active_physical_layout").try(:active_physical_layout) || 0
  end

  def self.refresh_physical_layout
    @@physical_layout = Gwe.find(:first, :select => "active_physical_layout").try(:active_physical_layout) || 0
  end

  def self.gcp_4000?
    # Look for GCP5000 type:
    # product == 1 => GCP5000
    # product != 1 => GCP4000 (all other conditions: ""," ",0, etc. will be treated as 4000)
    gcp5000 = find(:last, :conditions => {:product => 1})

    # Check if we have a GCP5000
    return gcp5000.blank?
  end

  def self.gcp5k?
     gcp5000 = find(:last, :conditions => ["mcf_location Like ? ", "%4000%"])

    # Check if we have a GCP5000
    return gcp5000.blank?
    
  end

  def self.is_GOL_app?
    return true   #true for cpu II, false cpu III
  end

  def self.is_GEO_II_chassis
    return true   #true for cpu II, false cpu III
  end

  def self.get_product
    retunr 0
  end

end
