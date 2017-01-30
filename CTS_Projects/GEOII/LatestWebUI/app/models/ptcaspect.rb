class Ptcaspect < ActiveRecord::Base
  set_table_name "PTCAspect"
  set_primary_key "PTCCode"
  establish_connection :site_ptc_db if OCE_MODE == 1
  def self.delete_installationname_ptcaspect(installationname)
        Ptcaspect.delete_all(['InstallationName=?',installationname])
  end

  def self.select_all_aspectsdetails(installationname)
    Ptcaspect.find(:all, :select=>"PTCCode,AspectName", :conditions=>['InstallationName=?',installationname] ,:order => "AspectName asc")
  end
  
  def self.delete_ptcaspect(id , installationame)
    Ptcaspect.delete_all({:PTCCode => id , :InstallationName=>installationame})
  end
  
  def self.insert_ptcaspect_details_check(id , installationame)
    Ptcaspect.find(:all, :select=>"PTCCode", :conditions=>['InstallationName= ? AND PTCCode=?',installationame,id]).map(&:PTCCode)
  end
  
  def self.insert_ptcaspect_details_insert(path, id , aspectname , installationame)
     db = SQLite3::Database.new(path)
     db.execute( "Insert into PTCAspect values('#{id}','#{aspectname}','#{installationame}')" )
  end
  
end
