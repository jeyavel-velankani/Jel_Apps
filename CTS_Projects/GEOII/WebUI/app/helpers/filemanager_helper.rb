module FilemanagerHelper
  def find_duplicate_files()
    db_files_path = "#{RAILS_ROOT}/Masterdb/"
    geo_asp_path = "#{RAILS_ROOT}/doc/geo_aspects/"
    ptc_asp_path = "#{RAILS_ROOT}/doc/ptc_aspects/"
    geo_files_path = "#{RAILS_ROOT}/oce_configuration/mcf/geo/"
    gcp_files_path = "#{RAILS_ROOT}/oce_configuration/mcf/gcp/"
    iviu_files_path = "#{RAILS_ROOT}/oce_configuration/mcf/iviu/"
    viu_files_path = "#{RAILS_ROOT}/oce_configuration/mcf/viu/"
    gcp_template_path = "#{RAILS_ROOT}/oce_configuration/templates/gcp/"

    geoaspect = Dir[geo_asp_path + "*.bak"]
    ptcaspect = Dir[ptc_asp_path + "*.bak"]
    dbfiles = Dir[db_files_path + "*.bak"]
    geofiles = Dir[geo_files_path + "*.bak"]
    gcpfiles = Dir[gcp_files_path + "*.bak"]
    iviufiles = Dir[iviu_files_path + "*.bak"]
    viufiles = Dir[viu_files_path + "*.bak"]
    gcp_template_files = Dir["#{gcp_template_path}**/*.bak"]
    
    dupfiles_list = Hash.new()
    
    unless geoaspect.blank?
      for fl_ind in 0...(geoaspect.length)
        fl_name = geoaspect[fl_ind].sub(".bak","")
        new_file = File.basename(fl_name)
        dupfiles_list[fl_name] = {:new_name => new_file, :file_path =>fl_name}         
      end            
    end
    unless ptcaspect.blank?
      for fl_ind in 0...(ptcaspect.length)
        fl_name = ptcaspect[fl_ind].sub(".bak","")
        new_file = File.basename(fl_name)
        dupfiles_list[fl_name] = {:new_name => new_file, :file_path =>fl_name}
      end
    end
    unless dbfiles.blank?      
      for fl_ind in 0...(dbfiles.length)
        fl_name = dbfiles[fl_ind].sub(".bak","")
        new_file = File.basename(fl_name)
        dupfiles_list[fl_name] = {:new_name => new_file, :file_path =>fl_name} 
      end      
    end
    unless geofiles.blank?
      for fl_ind in 0...(geofiles.length)
        fl_name = geofiles[fl_ind].sub(".bak","")
        new_file = File.basename(fl_name)
        dupfiles_list[fl_name] = {:new_name => new_file, :file_path =>fl_name} 
      end   
    end
    unless gcpfiles.blank?
      for fl_ind in 0...(gcpfiles.length)
        fl_name = gcpfiles[fl_ind].sub(".bak","")
        new_file = File.basename(fl_name)
        dupfiles_list[fl_name] = {:new_name => new_file, :file_path =>fl_name} 
      end
    end
    unless iviufiles.blank?
      for fl_ind in 0...(iviufiles.length)
        fl_name = iviufiles[fl_ind].sub(".bak","")
        new_file = File.basename(fl_name)
        dupfiles_list[fl_name] = {:new_name => new_file, :file_path =>fl_name} 
      end
    end
    
    unless viufiles.blank?
      for fl_ind in 0...(viufiles.length)
        fl_name = viufiles[fl_ind].sub(".bak","")
        new_file = File.basename(fl_name)
        dupfiles_list[fl_name] = {:new_name => new_file, :file_path =>fl_name} 
      end
    end
    
    unless gcp_template_files.blank?
      gcp_template_files.each do |file| 
         path_file = file.split(gcp_template_path)
         fl_name = file.sub(".bak","")
         new_file = File.basename(fl_name)
         dupfiles_list[fl_name] = {:new_name => new_file, :file_path =>fl_name} 
      end
    end

    @hash_dup_fileslist = dupfiles_list    
  end
    
  def get_dupfile_details(dup_file)
    old_size = (File.size?(dup_file))/1024
    old_mod_date = File.mtime(dup_file).strftime("%m-%d-%Y %H:%M:%S")
    new_file = dup_file.sub(".bak","")
    if File.exist?(new_file)
      new_size = (File.size?(new_file))/1024
      new_mod_date = File.mtime(new_file).strftime("%m-%d-%Y %H:%M:%S")
    else
      new_size = 0;
      new_mod_date = ""
    end
    filehash = {:new_name => new_file.sub(RAILS_ROOT,""), :new_size => new_size.to_s, :new_date => new_mod_date.to_s, :old_name => dup_file.sub(RAILS_ROOT,""), :old_size => old_size.to_s, :old_date => old_mod_date.to_s}
    return filehash
  end
end
