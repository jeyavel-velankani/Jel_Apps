class Installationtemplate < ActiveRecord::Base
  set_table_name "InstallationTemplate"
  set_primary_key "InstallationName"
  establish_connection :site_ptc_db if OCE_MODE == 1
  #  establish_connection :geoptc_db
  has_many :ptcdevices, :foreign_key => "InstallationName", :dependent => :destroy
  has_many :ptcaspects, :foreign_key => "InstallationName"
  has_many :atcsconfigs, :foreign_key => "InstallationName"
  
  has_many :aspects, :foreign_key => "InstallationName"
  
  def self.select_installation(installationname)
    Installationtemplate.find(:all,:select=>'InstallationName',:conditions => ["InstallationName like ?",installationname] , :order => 'InstallationName COLLATE NOCASE').map(&:InstallationName)
  end
  
  def self.select_all_installations()
    Installationtemplate.find(:all,:select=>'InstallationName',:order => 'InstallationName COLLATE NOCASE').map(&:InstallationName)
  end
end
