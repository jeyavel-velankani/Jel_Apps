class Aspect < ActiveRecord::Base
  set_table_name "Aspect"
  set_primary_key "InstallationName"
  establish_connection :site_ptc_db if OCE_MODE == 1
  
  def self.delete_mcf_aspect(mcfname)
        Aspect.delete_all(['mcfname=?',mcfname])
  end
  
  def self.select_all_aspectsdetails(installationname)
    Aspect.find(:all, :select=>"[Index],AspectName", :conditions=>['InstallationName=?',installationname])
  end
  
end
