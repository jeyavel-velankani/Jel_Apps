####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: filemanager_controller.rb
# Description: Using this module user can able to upload/download 
#              the site configuration mcf, aspect lookup file , master database
####################################################################
#History:
# Log: /wayside/GEOII/Trunk/Software/WebUI/app/controllers/filemanager_controller.rb
#
# Rev 4769   July 17 2013 17:00:00   Jeyavel Natesan
# Initial version
class FilemanagerController < ApplicationController
  include FilemanagerHelper
  include ReportsHelper
  require 'zlib'
  if OCE_MODE == 1
    require 'win32ole'
    require 'zip/zipfilesystem'
    require 'zip/zip'
    require "rexml/document"
    include REXML
  end
  layout "general"
  require 'fileutils'
  
  ####################################################################
  # Function:      index
  # Parameters:    None
  # Retrun:        None 
  # Renders:       None
  # Description:   Display the file manager page
  ####################################################################
  def index
    if session[:user_id].blank?
      redirect_to :controller => 'access', :action=> 'login_form'
    else
      @remove_msg_template = params[:remove_msg_template] unless params[:remove_msg_template].blank?
      @successmsg = params[:successmsg]
      @import_flag = false
      
      # Read the imported and not imported files list from the temp xml and delete it (Bug#9761)
      @imported_files , @not_import_files = readImportNotImportFilesList() 
      unless @imported_files.blank?
        @import_flag = true
        update_default_aspects
      end
      if @not_import_files.blank?
        @importmsg = params[:importmsg].to_s
      end 
      find_duplicate_files()
      @get_template_list = get_template_list()
    end
  end
  
  ####################################################################
  # Function:      readImportNotImportFilesList
  # Parameters:    None
  # Retrun:        import_file_list , non_import_file_list
  # Renders:       None
  # Description:   Read Import and Not import files list from the import_supportfile.xml
  ####################################################################  
  def readImportNotImportFilesList()
    import_file_list = []
    non_import_file_list = []
    if File.exist?("#{RAILS_ROOT}/tmp/import_supportfile.xml")
      begin
        file_import_nonimp = File.new("#{RAILS_ROOT}/tmp/import_supportfile.xml")
        doc = Document.new(file_import_nonimp)
        doc.elements.each("SupportFiles/ImportSupportFile") do |element| 
          import_file_list << "#{element.attributes["filename"]}*#{element.attributes["path"]}"
        end
        
        doc.elements.each("SupportFiles/NotImportSupportFile") do |element| 
          non_import_file_list << "#{element.attributes["filename"]}"
        end
        file_import_nonimp.close
        FileUtils.mv "#{RAILS_ROOT}/tmp/import_supportfile.xml", "#{RAILS_ROOT}/tmp/import_supportfile_tmp.xml"
        File.delete("#{RAILS_ROOT}/tmp/import_supportfile_tmp.xml")
      rescue Exception => e  
        puts e.inspect
      end
    end
    return import_file_list , non_import_file_list
  end
  
  ####################################################################
  # Function:      import_files
  # Parameters:    params[:upload_zip_input]
  # Retrun:        importmsg 
  # Renders:       render :text => importmsg
  # Description:   Import the selected zip file and update in the corresponding system path
  ####################################################################
  def import_files
    file_name = params[:upload_zip_input].original_filename    
    not_import_files = ""
    imported_files = ""
    basefile_name = ""
    db_files_path = "#{RAILS_ROOT}/Masterdb/"
    geo_asp_path = "#{RAILS_ROOT}/doc/geo_aspects/"
    ptc_asp_path = "#{RAILS_ROOT}/doc/ptc_aspects/"
    mcf_files_path = "#{RAILS_ROOT}/oce_configuration/"
    gcp_template_path = "#{RAILS_ROOT}/oce_configuration/templates/gcp"
    iviu_template_path = "#{RAILS_ROOT}/oce_configuration/templates/iviu"
    iviu_ptc_geo_template_path = "#{RAILS_ROOT}/oce_configuration/templates/iviu ptc geo"
    viu_template_path = "#{RAILS_ROOT}/oce_configuration/templates/viu"
    cpu_3_template_path = "#{RAILS_ROOT}/oce_configuration/templates/cpu-iii"
    tmp_directory = "#{RAILS_ROOT}/tmp/" 
    zip_content = params[:upload_zip_input].read
    zip_path = File.join(tmp_directory, file_name)
    if File.exists?(zip_path)
      puts 'Already exist', zip_path.inspect
    else
      File.open(zip_path, "wb") { |fl| fl.write(zip_content) }
    end
    if File.exists?(zip_path)
      tmp_fld_name = File.basename(zip_path,".zip")
      Zip::ZipFile.open(zip_path) do |zip_file|
        zip_file.each do |fl|  
          fld_struct = fl.name.split("/")
          tmp_fld_name = fld_struct[0]
          tmp_file_name = fl.name.sub(tmp_fld_name + "/","")           
          basefile_name = File.basename(fl.name)
          if (tmp_file_name.length > 0)            
            if (tmp_file_name.start_with?("mcf/"))
              subdir = tmp_file_name.sub("mcf/","")
              if (subdir.strip.length > 0)
                if ((subdir.downcase.start_with?("geo/")) || (subdir.downcase.start_with?("gcp/")) || (subdir.downcase.start_with?("iviu/")) || (subdir.downcase.start_with?("viu/")))
                  tmp_directory = mcf_files_path
                else
                  tmp_directory = ""
                end
              end              
            elsif (tmp_file_name.start_with?("templates/gcp"))
              tmp_file_name = tmp_file_name.split("templates/gcp")
              tmp_directory = gcp_template_path
            elsif (tmp_file_name.include?("templates/iviu_ptc_geo"))
              tmp_file_name = tmp_file_name.split("templates/iviu_ptc_geo")
              tmp_directory = iviu_ptc_geo_template_path
            elsif (tmp_file_name.start_with?("templates/iviu"))
              tmp_file_name = tmp_file_name.split("templates/iviu")
              tmp_directory = iviu_template_path
            elsif (tmp_file_name.start_with?("templates/viu"))
              tmp_file_name = tmp_file_name.split("templates/viu")
              tmp_directory = viu_template_path
            elsif (tmp_file_name.start_with?("templates/cpu-iii"))
              tmp_file_name = tmp_file_name.split("templates/cpu-iii")
              tmp_directory = cpu_3_template_path
            elsif (File.extname(basefile_name).downcase == ".tpl")
              file_name_val = File.basename(tmp_file_name, File.extname(tmp_file_name))
              create_template_dir_path = "#{gcp_template_path}/#{file_name_val}"
              Dir.mkdir(create_template_dir_path) unless File.exists?(create_template_dir_path)   
              tmp_directory = create_template_dir_path
            elsif ((tmp_file_name.downcase.start_with?("aspectlookuptable")) && (File.extname(fl.name).downcase == ".txt"))
              validate = tmp_file_name.split('.')
              if validate.length == 4
                tmp_directory = geo_asp_path
              else
                not_import_files = not_import_files + "|" + basefile_name
                tmp_directory = ""  
              end
            elsif ((tmp_file_name.downcase.start_with?("ptcaspectvalues")) && (File.extname(fl.name).downcase == ".txt"))
              validate = tmp_file_name.split('.')
              if validate.length == 4
                tmp_directory = ptc_asp_path
              else
                not_import_files = not_import_files + "|" + basefile_name
                tmp_directory = ""  
              end
            elsif ((!tmp_file_name.include?("/")) && (File.extname(fl.name) == ".db"))
              tmp_directory = db_files_path
            elsif (tmp_file_name.include?("/"))
              tmp_directory = ""
            else
              not_import_files = not_import_files + "|" + basefile_name
              tmp_directory = ""
            end            
            if ((File.extname(fl.name).length > 0) && (fl.size == 0))
              not_import_files = not_import_files + "|" + basefile_name
              tmp_directory = ""
            end
            
            flgbak = false
            if(tmp_directory.length > 0)
              f_path = File.join(tmp_directory, tmp_file_name)
              FileUtils.mkdir_p(File.dirname(f_path))
              if ((!File.extname(f_path).blank?) && File.exist?(f_path))
                File.rename(f_path, f_path+".bak")
              end
              zip_file.extract(fl, f_path)              
              if(File.extname(fl.name).length > 0)                
                imported_files = imported_files + "|" + basefile_name + "*" + f_path
              end
              tmp_directory = ""
            end   #if(tmp_directory.length > 0)
          end   #if (tmp_file_name.length > 0)
        end
      end      
      FileUtils.rm(zip_path)
      importmsg = "Files imported successfully."
    end
    
    # Below code written to identify imported and not imported file list 
    #   - previously we used session variable to store values(session we can't store more data,limit is 2KB) 
    import_list_array = imported_files.split('|')
    not_import_list_array = not_import_files.split('|')
    xml = Builder::XmlMarkup.new(:target=> output_string = "" ,:indent => 2 )
    xml.SupportFiles {
      import_list_array.each do |sup_file , index|
        file_details = sup_file.split('*')
        xml.ImportSupportFile(:filename => file_details[0],:path=>file_details[1]) if !sup_file.blank?
      end
      
      not_import_list_array.each do |not_sup_file |
        xml.NotImportSupportFile(:filename => not_sup_file) if !not_sup_file.blank?
      end
    }
    Dir.mkdir("#{RAILS_ROOT}/tmp") unless File.exists?("#{RAILS_ROOT}/tmp")
    f = File.new("#{RAILS_ROOT}/tmp/import_supportfile.xml", "w")
    f.write(output_string)
    f.close
    
    render :text => importmsg
  end
  
  ####################################################################
  # Function:      check_export_exists
  # Parameters:    None
  # Retrun:        errorflag
  # Renders:       render :json
  # Description:   Check the export files available in the path or Not
  ####################################################################
  def check_export_exists
    geoaspectfilespath = RAILS_ROOT+'/doc/geo_aspects'
    ptcaspectfilespath = RAILS_ROOT+'/doc/ptc_aspects'
    masterdbfilespath = RAILS_ROOT + "/Masterdb"
    mcffilespath = RAILS_ROOT + "/oce_configuration/mcf" 
    geoaspect = Dir[geoaspectfilespath+"/*.txt"]
    ptcaspect = Dir[ptcaspectfilespath+"/*.txt"]
    masterdbs = Dir[masterdbfilespath+"/*.db"]
    mcf_count=0
    if File.directory?(mcffilespath)
      Dir.chdir(mcffilespath)
      dir_list = Dir["*"].reject{|subfld| not File.directory?(subfld)}        
      sub_dir_name=""
      unless dir_list.blank?
        for subdir in 0...(dir_list.length)
          sub_dir_name = mcffilespath + "/" + dir_list[subdir]             
          unless Dir[sub_dir_name+"/*.*"].blank?
            Dir.foreach(sub_dir_name) do |sfile|                  
              mcf_count = mcf_count+1                 
            end
          end
        end
      end
    end
    if geoaspect.blank? && ptcaspect.blank? && masterdbs.blank? && mcf_count == 0
      render :json=>{:errorflag => true}
    else
      render :text => ""
    end
  end
  
  ####################################################################
  # Function:      export_files
  # Parameters:    None
  # Retrun:        None 
  # Renders:       send_file
  # Description:   Export the configuration , aspectlookup , master database files as a zip format
  ####################################################################
  def export_files
    zipfilename = "oceconfig_files_" + Time.now.strftime('%m-%d-%Y_%H%M%S')
    bundle_filename = "#{RAILS_ROOT}/tmp/#{zipfilename}.zip"
    geoaspectfilespath = "#{RAILS_ROOT}/doc/geo_aspects"
    ptcaspectfilespath = "#{RAILS_ROOT}/doc/ptc_aspects"
    masterdbfilespath = "#{RAILS_ROOT}/Masterdb"
    mcffilespath = "#{RAILS_ROOT}/oce_configuration/mcf"
    gcp_template_path = "#{RAILS_ROOT}/oce_configuration/templates/gcp"
    iviu_template_path = "#{RAILS_ROOT}/oce_configuration/templates/iviu"
    iviu_ptc_geo_template_path = "#{RAILS_ROOT}/oce_configuration/templates/iviu ptc geo"
    viu_template_path = "#{RAILS_ROOT}/oce_configuration/templates/viu"
    geo_cpu3_template_path = "#{RAILS_ROOT}/oce_configuration/templates/cpu-iii"
       
    
    begin
      File.delete(bundle_filename) if File.exists?(bundle_filename)
      geoaspect = Dir[geoaspectfilespath+"/*.txt"]
      ptcaspect = Dir[ptcaspectfilespath+"/*.txt"]
      masterdbs = Dir[masterdbfilespath+"/*.db"]
      Zip::ZipFile.open(bundle_filename, Zip::ZipFile::CREATE) do |zf|
        zf.mkdir(zipfilename)
        zf.mkdir(zipfilename + "/mcf")
        zf.mkdir(zipfilename + "/mcf/geo")
        zf.mkdir(zipfilename + "/mcf/iviu")
        zf.mkdir(zipfilename + "/mcf/viu")
        zf.mkdir(zipfilename + "/mcf/gcp")
        
        # Geo aspect add
        unless geoaspect.blank?
          Dir.foreach(geoaspectfilespath) do |geoaspfile| 
            if ((File.extname(geoaspfile)=='.txt') || (File.extname(geoaspfile)=='.TXT'))
              zf.add(zipfilename + "/"+geoaspfile, geoaspectfilespath+'/'+geoaspfile)
            end
          end
        end
        
        #PTC Aspect add
        unless ptcaspect.blank?
          Dir.foreach(ptcaspectfilespath) do |ptcaspfile| 
            if ((File.extname(ptcaspfile)=='.txt') || (File.extname(ptcaspfile)=='.TXT'))
              zf.add(zipfilename + "/"+ptcaspfile, ptcaspectfilespath+'/'+ptcaspfile)
            end
          end
        end   #unless ptcaspect.blank?
        
        #Master database add
        unless masterdbs.blank?
          Dir.foreach(masterdbfilespath) do |masterdb_file| 
            if ((File.extname(masterdb_file)=='.db') || (File.extname(masterdb_file)=='.DB'))
              zf.add(zipfilename + "/" + masterdb_file, masterdbfilespath + '/' + masterdb_file)
            end
          end
        end   #masterdbs.blank?
        
        # Mcf files add
        Dir.chdir(mcffilespath)
        dir_list = Dir["*"].reject{|subfld| not File.directory?(subfld)}  
        sub_dir_name=""
        unless dir_list.blank?
          for subdir in 0...(dir_list.length)
            sub_dir_name = mcffilespath + "/" + dir_list[subdir]             
            unless Dir[sub_dir_name+"/*.*"].blank?
              Dir.foreach(sub_dir_name) do |sfile|  
                next if File.directory?("#{sub_dir_name}/#{sfile}")               
                zf.add("#{zipfilename}/mcf/#{dir_list[subdir]}/#{sfile}" , "#{sub_dir_name}/#{sfile}")                 
              end
            end
          end  #for subdir
        end     #unless dir_list.blank?  
        
        if (File.exists?(gcp_template_path) || File.exists?(iviu_template_path) || File.exists?(iviu_ptc_geo_template_path) || File.exists?(geo_cpu3_template_path) || File.exists?(viu_template_path))  
          zf.mkdir("#{zipfilename}/templates")
        end
        #GCP template add if available
        if File.directory?(gcp_template_path)
          template_empty_flag = (Dir.entries(gcp_template_path) == [".", ".."])
          if template_empty_flag == false
            zf.mkdir("#{zipfilename}/templates/gcp")
            Dir["#{gcp_template_path}/**/*.*"].each do |file| 
              path_file = file.split(gcp_template_path)
              if (path_file[1].split('/').length > 2) # export only template folders not current set template files
                zf.add("#{zipfilename}/templates/gcp/#{path_file[1]}" , file)  
              end
            end
          end
        end  #File.directory?(gcp_template_path)  
        
        #template add if available viu,iviu , iviu geo ptc , CPU-III
        
        if File.directory?(iviu_template_path)
          template_empty_flag = (Dir.entries(iviu_template_path) == [".", ".."])
          if template_empty_flag == false
            zf.mkdir("#{zipfilename}/templates/iviu")
            Dir["#{iviu_template_path}/*.*"].each do |file| 
                file_name = File.basename(file)
                zf.add("#{zipfilename}/templates/iviu/#{file_name}" , file)  
            end
          end
        end  #File.directory?(iviu_template_path)
        
        if File.directory?(iviu_ptc_geo_template_path)
          template_empty_flag = (Dir.entries(iviu_ptc_geo_template_path) == [".", ".."])
          if template_empty_flag == false
            zf.mkdir("#{zipfilename}/templates/iviu_ptc_geo")
            Dir["#{iviu_ptc_geo_template_path}/*.*"].each do |file| 
                file_name = File.basename(file)
                zf.add("#{zipfilename}/templates/iviu_ptc_geo/#{file_name}" , file)  
            end
          end
        end  #File.directory?(iviu_ptc_geo_template_path)
        
        if File.directory?(viu_template_path)
          template_empty_flag = (Dir.entries(viu_template_path) == [".", ".."])
          if template_empty_flag == false
            zf.mkdir("#{zipfilename}/templates/viu")
            Dir["#{viu_template_path}/*.*"].each do |file| 
                file_name = File.basename(file)
                zf.add("#{zipfilename}/templates/viu/#{file_name}" , file)  
            end
          end
        end  #File.directory?(viu_template_path)
        
        if File.directory?(geo_cpu3_template_path)
          template_empty_flag = (Dir.entries(geo_cpu3_template_path) == [".", ".."])
          if template_empty_flag == false
            zf.mkdir("#{zipfilename}/templates/cpu-iii")
            Dir["#{geo_cpu3_template_path}/*.*"].each do |file| 
                file_name = File.basename(file)
                zf.add("#{zipfilename}/templates/cpu-iii/#{file_name}" , file)  
            end
          end
        end  #File.directory?(geo_cpu3_template_path)
         
      end   #Zip::ZipFile.open
    rescue Exception => e
      session[:failexception]= "Export files failed. " + e.to_s
    end
    send_file  bundle_filename ,:disposition => 'inline' ,:stream => false
  end
  
  ####################################################################
  # Function:      unzip
  # Parameters:    zip, unzip_dir,remove_after = false
  # Retrun:        None 
  # Renders:       None
  # Description:   Unzip the selected zip file
  ####################################################################
  def unzip(zip, unzip_dir,remove_after = false)
    Zip::ZipFile.open(zip) do |zip_file|
      zip_file.each do |f|
        f_path = File.join(unzip_dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)        
      end
    end
    FileUtils.rm(zip) if remove_after
  end
  
  ####################################################################
  # Function:      save_selected_files
  # Parameters:    params[:sel_files]
  # Retrun:        None 
  # Renders:       None
  # Description:   Save the selected file's 
  ####################################################################
  def save_selected_files
    file_to_delete = ""
    begin
      unless params[:sel_files].blank?
        fl_list = params[:sel_files].split("|")    
        for fl_ind in 0...(fl_list.length)
          if(fl_list[fl_ind].length > 0)
            fl_name = fl_list[fl_ind].split("*")         
            if fl_name[0] == "checked"
              file_to_delete = fl_name[1] + ".bak"
              if File.exist?(file_to_delete)
                File.delete(file_to_delete)
              end                
            else
              file_to_delete = fl_name[1]
              if File.exist?(file_to_delete)
                File.delete(file_to_delete)
              end
              File.rename(fl_name[1] + ".bak",file_to_delete)
            end          
          end   #if(fl_list[fl_ind].length > 0)
        end   #for fl_ind in 0...(fl_list.length)
      end     #unless params[:sel_files].blank?
      msg = "Successfully override imported files."
    rescue Exception => e
      msg = e
    end
    render :text => msg
  end
  
  ####################################################################
  # Function:      cancel_import
  # Parameters:    None
  # Retrun:        None 
  # Renders:       None
  # Description:   Cancel the import file operation
  ####################################################################
  def cancel_import
    msg = ""
    file_to_delete = ""
    begin
      unless params[:cancel_files].blank?
        fl_list = params[:cancel_files].split("|")    
        for fl_ind in 0...(fl_list.length)
          if(fl_list[fl_ind].length > 0)
            file_to_delete = fl_list[fl_ind]
            if File.exist?(file_to_delete)
              File.delete(file_to_delete)
            end
            if File.exist?(file_to_delete + ".bak")
              File.rename(file_to_delete + ".bak", file_to_delete)
            end      
          end   #if(fl_list[fl_ind].length > 0)
        end   #for fl_ind in 0...(fl_list.length)
      end   #unless params[:cal_files].blank?
      msg = "Successfully revert back imported files."
    rescue Exception => e
      msg = e      
    end
    update_default_aspects
    render :text => msg 
  end
  
  ####################################################################
  # Function:      update_default_aspects
  # Parameters:    None
  # Retrun:        None 
  # Renders:       None
  # Description:   Update the default aspect file
  ####################################################################
  def update_default_aspects
    geo_aspect_path = "#{RAILS_ROOT}/doc/geo_aspects/"
    ptc_aspect_path = "#{RAILS_ROOT}/doc/ptc_aspects/"
    geoaspect = Dir[geo_aspect_path + "*.txt"]
    ptcaspect = Dir[ptc_aspect_path + "*.txt"]
    geo_format = "aspectlookuptable"
    ptc_format = "ptcaspectvalues"
    geoarray = Array.new
    ptcarray = Array.new
    geoaspect.each do |file|
      geoasp_file = File.basename file
      geo = []
      file = geoasp_file.split('.')
      if ((file[0].downcase == geo_format) && (file.length == 4))
        geo[0] = geoasp_file
        geo[1] = file[2]
      end
      unless geo.blank?
        geoarray << geo   
      end
    end
    ptcaspect.each do |file|
      ptcasp_file = File.basename file
      ptc = []
      file = ptcasp_file.split('.')
      if ((file[0].downcase == ptc_format) && (file.length == 4))
        ptc[0] = ptcasp_file
        ptc[1] = file[2]
      end
      unless ptc.blank?
        ptcarray << ptc   
      end
    end
    if ((geoarray.length >= 1) && (ptcarray.length >= 1))
      geo_aspect_file_update = geoarray.max_by {|geo| geo[1]}
      ptc_aspect_file_update = ptcarray.max_by {|ptc| ptc[1]}
      if ((geo_aspect_file_update.length >= 1) && (ptc_aspect_file_update.length >= 1))
        config = YAML.load_file(RAILS_ROOT+"/config/ui_configuration.yml")
        flag  = false
        if (geo_aspect_file_update[0].downcase != current_geoaspectfile.downcase)
          config["oce"]["geo_aspect_file"] = geo_aspect_file_update[0].to_s
          flag  = true
        end
        if (ptc_aspect_file_update[0].downcase != current_ptcaspectfile.downcase)
          config["oce"]["ptc_aspect_file"] = ptc_aspect_file_update[0].to_s
          flag  = true
        end
        if flag == true
          File.open("#{RAILS_ROOT}/config/ui_configuration.yml", 'w') { |f| YAML.dump(config, f) }
        end
      end
    end
  end

  ####################################################################
  # Function:      remove_template
  # Parameters:    params[:type]
  # Retrun:        mess 
  # Renders:       render :json
  # Description:   Remove the selected site type template from the template repo
  ####################################################################  
  def remove_template
    flg = false
    begin
      template_path = ""
      if !params[:type].blank?
        if params[:type].to_s.downcase == "viu"
          template_path = "#{RAILS_ROOT}/oce_configuration/templates/#{params[:type].to_s.downcase}/nvconfig.bin"
        elsif params[:type].to_s.downcase == "gcp"
          template_path = "#{RAILS_ROOT}/oce_configuration/templates/#{params[:type].to_s.downcase}/rt.db"
        else
          template_path = "#{RAILS_ROOT}/oce_configuration/templates/#{params[:type].to_s.downcase}/nvconfig.sql3"
        end
          
        if File.exists?(template_path)
          FileUtils.rm_rf("#{RAILS_ROOT}/oce_configuration/templates/#{params[:type].to_s.downcase}/nvconfig.sql3") if params[:type].to_s.downcase == "viu" 
          FileUtils.rm_rf(template_path) if params[:type].to_s.downcase != "gcp"
          if (params[:type].to_s.downcase == "gcp") && File.directory?("#{RAILS_ROOT}/oce_configuration/templates/gcp")
            Dir["#{RAILS_ROOT}/oce_configuration/templates/gcp/*.*"].each do |files|
              file_flag = File.directory?(files)
              if (file_flag == false)  && File.exists?(files)
                FileUtils.rm_rf(files)
                # Update the ui_configuration.yml file "Template: GCP Site Template : Config-2014Jul21(PAC/TPL/Template folder name)" 
                ui_config_yml_path = "#{RAILS_ROOT}/config/ui_configuration.yml"
                config = YAML.load_file(ui_config_yml_path)
                config["oce"]["GCPSiteTemplate"] = ""
                File.open(ui_config_yml_path, 'w') { |f| YAML.dump(config, f) }
              end
            end
          end 
          if File.exists?(template_path)
            mess = "<span style = 'color:#FF0000'>Error: Unable to delete the template file. If it is open close and try again.</span>"
            flg = true
          else
            mess = "#{params[:type]} Template removed successfully."
          end
        else
          mess = "#{params[:type]} Template file not available."
        end
      else
        mess = "<span style = 'color:#FF0000'>Error: Unable to find the template file.</span>"
        flg = true
      end
    rescue Exception => e
      mess = "<span style = 'color:#FF0000'>Error: While removing " + params[:type].to_s + " template file, #{e.to_s}.</span>"
      flg = true
    end
    render :json =>{:error => flg, :mess => mess}
  end

  ####################################################################
  # Function:      get_template_list
  # Parameters:    None
  # Retrun:        template_list 
  # Renders:       None
  # Description:   Get the template available site type
  ####################################################################
  def get_template_list
    template_directory = File.join(RAILS_ROOT, "/oce_configuration/templates/")
    template_list = []
    if File.exists?(template_directory)
      Dir.foreach(template_directory) do |fl|
        template_path = ""
        if fl == "viu"
          template_path = "#{template_directory}#{fl}/nvconfig.bin"
        elsif fl == "gcp"
          template_directory_name = "#{template_directory}#{fl}"
          @templates = Pathname.new(template_directory_name).children.select { |c| c.directory? && !(Dir.entries(c) == [".", ".."]) }.collect { |p| p.to_s }
          if !@templates.blank?
            template_path = @templates[0]
          end
        else
          template_path = "#{template_directory}#{fl}/nvconfig.sql3"    
        end
        if !template_path.blank? && File.exists?(template_path) 
          template_list << fl
        end
      end
    end
    return template_list
  end
  
  ####################################################################
  # Function:      remove_gcp_template
  # Parameters:    None
  # Retrun:        @templates
  # Renders:       render :layout 
  # Description:   Remove the gcp templates
  ####################################################################
  def remove_gcp_template
      @templates = nil
      template_directory_name = "#{RAILS_ROOT}/oce_configuration/templates/gcp"
      Dir.mkdir(template_directory_name) unless File.exists?(template_directory_name)   
      @templates = Pathname.new(template_directory_name).children.select { |c| c.directory? && !(Dir.entries(c) == [".", ".."]) }.collect { |p| p.to_s }   
    render :layout => false
  end
  
  ####################################################################
  # Function:      remove_gcptemplate_files
  # Parameters:    params
  # Retrun:        strmsg
  # Renders:       render :json 
  # Description:   Remove the gcp template files
  ####################################################################
  def remove_gcptemplate_files
    current_template_name = ""
    destination_loc = "#{RAILS_ROOT}/oce_configuration/templates/gcp"
    selected_template = params[:selected_template]    
    gcp_current_template = "" 
    config = open_ui_configuration
    current_template = config["oce"]["GCPSiteTemplate"]
    gcp_current_template = current_template unless current_template.blank?
    select_template_name = selected_template.split('/')
    template_name = select_template_name[select_template_name.length-1]
    template_path = "#{RAILS_ROOT}/oce_configuration/templates/gcp/rt.db" 
    if ((template_name == gcp_current_template) && !gcp_current_template.blank? && !template_name.blank?)
      # Create the template decompress temp directory if not available in the tmp folder
      FileUtils.rm_rf(selected_template)
      if File.exists?(template_path)
        if File.directory?("#{RAILS_ROOT}/oce_configuration/templates/gcp")
          Dir["#{RAILS_ROOT}/oce_configuration/templates/gcp/*.*"].each do |files|
            file_flag = File.directory?(files)
            if (file_flag == false)  && File.exists?(files)
              FileUtils.rm_rf(files)
              # Update the ui_configuration.yml file "Template: GCP Site Template : Config-2014Jul21(PAC/TPL/Template folder name)" 
              ui_config_yml_path = "#{RAILS_ROOT}/config/ui_configuration.yml"
              config = YAML.load_file(ui_config_yml_path)
              config["oce"]["GCPSiteTemplate"] = ""
              File.open(ui_config_yml_path, 'w') { |f| YAML.dump(config, f) }
            end
          end
        end 
        if File.exists?(template_path)|| File.directory?(selected_template)
          strmsg = "<span style = 'color:#FF0000'>Error: Unable to delete the template file</span>"
        else
          strmsg = "GCP Template removed successfully"
        end
      else
        strmsg = " GCP Template file not available."
      end
    else
      if !selected_template.blank?
        FileUtils.rm_rf(selected_template)
      end
      if File.directory?(selected_template)
        strmsg = "<span style = 'color:#FF0000'>Error: Unable to delete the template file</span>"
      else
        strmsg = "GCP Template removed successfully"
      end            
    end
    render :text => strmsg
  end
  
end
