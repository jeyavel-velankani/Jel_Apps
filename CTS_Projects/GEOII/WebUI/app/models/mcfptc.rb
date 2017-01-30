class Mcfptc < ActiveRecord::Base
   set_table_name "MCF"
   set_primary_key "MCFName"
   establish_connection :site_ptc_db if OCE_MODE == 1
   
    def self.select_mcf_details()
      Mcfptc.find(:all,:select=>"MCFName,CRC")
    end
    
    def self.select_gol_type(installationname)
      Mcfptc.find_by_sql("select distinct(m.GOLType) from MCF as m , MCFPhysicalLayout as mp where mp.MCFName = m.MCFName and mp.InstallationName Like '#{installationname}'")
    end
end
