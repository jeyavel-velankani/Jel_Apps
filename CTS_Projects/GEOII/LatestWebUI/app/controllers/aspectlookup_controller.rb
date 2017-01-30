####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: aspectlookup_controller.rb
# Description: This module will show up the AspectlookupTable.txt 
#              information and then can add/edit/delete aspect Informations  
####################################################################
class AspectlookupController < ApplicationController
  require 'fileutils'
  layout "general"
  include AspectlookupHelper
  include ReportsHelper
  require 'find'
  if OCE_MODE == 1
    require 'zip/zipfilesystem'
    require 'zip/zip'
  end
  
  ####################################################################
  # Function:      index
  # Parameters:    params[:errorflag] , params[:errorflag] ,params[:success]
  # Retrun:        @selected_geoaspectfile , @selected_ptcaspectfile
  # Renders:       None
  # Description:   Get the available ptc/geo aspect files and display the already selected files
  ####################################################################
  def index
    @aspectlookGEO=""
    @aspectlookPTC=""
    if session[:user_id] == nil
      session[:val]=0
      redirect_to :controller => 'access', :action=> 'login_form' 
    else
      download_file = nil
      unless params[:errorflag].blank?
        download_file =   params[:errorflag]
      end
      success_msg = nil
      unless params[:success].blank?
        success_msg =   params[:success]
        if success_msg == 'true'
          flash[:aspectlookupsuccess] ="Aspect table files updated successfully"
        end
      else
        flash[:aspectlookupsuccess] = nil
      end
      #     Specify the apectlookup table text file path
      session[:aspectfilepath] = nil
      aspectfilesfolderpath = RAILS_ROOT+'/doc'
      session[:aspectfilepath]= current_geoaspectfile
      
      # Validate the format of geoaspect files
      geoaspect_files = Dir[aspectfilesfolderpath+"/geo_aspects/*.txt"]
      @geoaspect_files = validate_aspectlookup_ptcaspect_file_format("geo_aspects" ,geoaspect_files)
      
      selected_geoaspectfile = current_geoaspectfile
      @selected_geoaspectfile = (selected_geoaspectfile.blank?) ? "" : selected_geoaspectfile
      
      # Validate the format of ptcaspect files
      ptcaspect_files = Dir[aspectfilesfolderpath+"/ptc_aspects/*.txt"]
      @ptcaspect_files = validate_aspectlookup_ptcaspect_file_format("ptc_aspects" ,ptcaspect_files)
      selected_ptcaspectfile = current_ptcaspectfile
      @selected_ptcaspectfile = (selected_ptcaspectfile.blank?) ? "" : selected_ptcaspectfile
      @validationflag = nil
      Dir["#{RAILS_ROOT}/tmp/*.zip"].each do |x|
        File.delete(x) if File.exists?(x)
      end
      unless download_file.blank?
        @validationflag = download_file
      else
        if @geoaspect_files.blank? && @ptcaspect_files.blank?
          @validationflag = "GEO Aspect lookup and PTC Aspect text files are not available, please load and try again"
        elsif @geoaspect_files.blank?
          @validationflag = "GEO Aspect lookup text file is not available, please load and try again"
        elsif @ptcaspect_files.blank?
          @validationflag = "PTC Aspect text file is not available, please load and try again"
          validate_selected_aspect() 
        else
          validate_selected_aspect()
        end
      end
    end
  end

  ####################################################################
  # Function:      validate_selected_aspect
  # Parameters:    None
  # Retrun:        @validationflag
  # Renders:       None
  # Description:   Validate the selected aspectlookuptable.txt file 
  ####################################################################
  def validate_selected_aspect
    validate_val = validate_aspect_textfile 
    if validate_val.to_s == 'false'
      @validationflag = "Selected GEO Aspect Lookup text file is invalid, please select diffenernt and save"
    elsif validate_val.blank?
      @validationflag = "No GEO Aspect Lookup text file selected, please select available file and save"
    end
  end
  
  ####################################################################
  # Function:      save
  # Parameters:    params[:selectedfilename1] ,params[:selectedfilename2]
  # Retrun:        None
  # Renders:       render :text => ""
  # Description:   Validate the selected aspectlookuptable.txt file and moved to doc\aspectlookuptable.txt
  ####################################################################
  def save
    config = YAML.load_file(RAILS_ROOT+"/config/ui_configuration.yml")
    config["oce"]["geo_aspect_file"] = params[:selectedfilename1]
    config["oce"]["ptc_aspect_file"] = params[:selectedfilename2]
    File.open("#{RAILS_ROOT}/config/ui_configuration.yml", 'w') { |f| YAML.dump(config, f) }
    session[:aspectfilepath] = nil
    render :text => ""
  end
  
  ####################################################################
  # Function:      import_geoaspectsfile
  # Parameters:    params[:upload]
  # Retrun:        None
  # Renders:       render :text => ""
  # Description:   Import the aspect lookuptable file
  ####################################################################
  def import_geoaspectsfile
    unless params[:upload].blank?
      directory = RAILS_ROOT+'/doc/geo_aspects'
      Dir.mkdir(directory) unless File.exists? directory
      file_name = params[:upload].original_filename
      session[:geotxtfilename] = directory+'/'+file_name
      content = params[:upload].read
      unless content.blank?
        path = File.join(directory, file_name)
        File.open(path, "wb") { |f| f.write(content) }
        if File.extname(session[:geotxtfilename])=='.txt' && File.exist?(session[:geotxtfilename])
          counter = 1
          @txtfilepath = session[:geotxtfilename]
          file = File.new(@txtfilepath, "r")
          #            validation format & example [APPROACH2              , "Approach"]
          begin
            while (line = file.gets)
              result=[]
              @data = "#{line}"
              result = @data.split(',')
              restrim=[]
              restrim = result[1].split('"')
              counter = counter + 1
            end
            file.close
            session[:geotxtfilename]=nil
            flash[:aspectlookupsuccess] ="GEO AspectLookupTable file uploaded successfully"
            update_default_filename(file_name , nil)
          rescue => err
            puts "Exception: #{err}"
            file.close
            flash[:aspectlookupsuccess] = nil
            flash[:aspectlookupvalid] = "Invalid GEO Aspect Lookup text file"
            File.delete(session[:geotxtfilename])
            session[:geotxtfilename] = nil
          end
        else
          flash[:aspectlookupvalid] ="Invalid file format or file not available "
          session[:geotxtfilename]=nil
        end
      else
        flash[:aspectlookupvalid] = "Invalid GEO Aspect Lookup text file"
        session[:geotxtfilename] = nil
      end
    end
    render :text => ""
  end
  
  ####################################################################
  # Function:      import_ptcaspectsfile
  # Parameters:    params[:upload1]
  # Retrun:        None
  # Renders:       render :text => ""
  # Description:   Import the ptc aspect file
  ####################################################################
  def import_ptcaspectsfile
    unless params[:upload1].blank?
      directory = RAILS_ROOT+'/doc/ptc_aspects'
      Dir.mkdir(directory) unless File.exists? directory
      file_name = params[:upload1].original_filename
      session[:ptctxtfilename] = directory+'/'+file_name
      content = params[:upload1].read
      unless content.blank?
        path = File.join(directory, file_name)
        File.open(path, "wb") { |f| f.write(content) }
        if File.extname(session[:ptctxtfilename])=='.txt' && File.exist?(session[:ptctxtfilename])
          counter = 1
          @txtfilepath = session[:ptctxtfilename]
          file = File.new(@txtfilepath, "r")
          #            validation format & example ["Invalid",    0]
          begin
            while (line = file.gets)
              result=[]
              @data = "#{line}"
              result = @data.split(',')
              restrim = []
              restrim = result[0].split('"')
              if (restrim.length.to_i != 2)
                raise Exception, "Invalid format in line no :"+counter.to_s  
              end
              counter = counter + 1
            end
            file.close
            session[:ptctxtfilename]=nil
            flash[:aspectlookupsuccess] ="PTC Aspect file uploaded successfully"
            update_default_filename(nil , file_name)
          rescue Exception => err
            puts "Exception: #{err}"
            file.close
            flash[:aspectlookupvalid] ="Invalid PTC Aspect Lookup text file"
            File.delete(session[:ptctxtfilename])
            session[:ptctxtfilename]=nil
          end
        else
          flash[:aspectlookupvalid] ="Invalid file format or file not available "
          session[:ptctxtfilename]=nil
        end
      else
        flash[:aspectlookupvalid] ="Invalid PTC Aspect Lookup text file"
        session[:ptctxtfilename]=nil
      end
    end
    render :text => ""
  end
  
  ####################################################################
  # Function:      delete
  # Parameters:    params[:deletelineno_val]
  # Retrun:        None
  # Renders:       render :partial => "table", :layout => false
  # Description:   Delete aspect name from aspect lookup table text file
  ####################################################################
  def delete
    deletelineno = params[:deletelineno_val].to_i
    delete_lines_from_file(session[:aspectfilepath].to_s , deletelineno-1)
    render :partial => "table", :layout => false
  end
  
  ####################################################################
  # Function:      update
  # Parameters:    params[:actiontype] , params[:aspectvalPTC_val] , params[:aspectvalGEO_val] ,params[:lineno_val]
  # Retrun:        None
  # Renders:       render :partial => "table", :layout => false
  # Description:   Update aspect values
  ####################################################################
  def update
    if params[:actiontype]=='edit' # editing existing values
      deletelineno = params[:lineno_val].to_i
      delete_lines_from_file(session[:aspectfilepath].to_s , deletelineno - 1)
      insertvalue = params[:aspectvalGEO_val].to_s + "\t\t ,"+' "'+params[:aspectvalPTC_val].to_s+'"'
      File.open(session[:aspectfilepath].to_s, 'a+') do |aFile|
        aFile.puts(insertvalue)
        aFile.close
      end   
    elsif params[:actiontype]=='add'   # adding new values
      insertvalue = params[:aspectlookGEO_val].to_s + "\t\t ,"+' "'+params[:aspectlookPTC_val].to_s+'"'
      File.open(session[:aspectfilepath].to_s, 'a+') do |aFile|
        aFile.puts(insertvalue)
        aFile.close
      end    
    end
    session[:val]=0
    session[:editline]=0
    render :partial => "table", :layout => false
  end
  
  ####################################################################
  # Function:      update_aspect_position
  # Parameters:    params[:current_ele] , params[:alternate_ele]
  # Retrun:        @current_aspect
  # Renders:       render :partial => "table", :layout => false
  # Description:   Update the aspectlookup changes
  ####################################################################
  def update_aspect_position
    unless params[:current_ele].blank? && params[:alternate_ele].blank?
      @current_aspect = params[:current_ele]
      alt_aspect = params[:alternate_ele]
      if @current_aspect.to_i > alt_aspect.to_i
        swap_line_with_above_from_file(session[:aspectfilepath].to_s , alt_aspect.to_i)
      else
        swap_line_with_above_from_file(session[:aspectfilepath].to_s , @current_aspect.to_i)
      end
      @current_aspect = params[:alternate_ele]
      render :partial => "table", :layout => false
    end
  end
  
  ####################################################################
  # Function:      update_default_filename
  # Parameters:    selectedfilename1 , selectedfilename2
  # Retrun:        None
  # Renders:       None
  # Description:   Update the default text filename in  config/ui_configuration.yml
  ####################################################################
  def update_default_filename(selectedfilename1 , selectedfilename2)
    config = YAML.load_file(RAILS_ROOT+"/config/ui_configuration.yml")
    unless selectedfilename1.blank?
      config["oce"]["geo_aspect_file"] = selectedfilename1  
    end
    unless selectedfilename2.blank?
      config["oce"]["ptc_aspect_file"] = selectedfilename2
    end
    File.open("#{RAILS_ROOT}/config/ui_configuration.yml", 'w') { |f| YAML.dump(config, f) }
    session[:aspectfilepath] = nil
  end

  ####################################################################
  # Function:      check_downloadfile_exists
  # Parameters:    None
  # Retrun:        errorflag
  # Renders:       render :json
  # Description:   Check the download files available in the path or Not
  ####################################################################
  def check_downloadfile_exists
    geoaspectfilespath = RAILS_ROOT+'/doc/geo_aspects'
    ptcaspectfilespath = RAILS_ROOT+'/doc/ptc_aspects'
    geoaspect = Dir[geoaspectfilespath+"/*.txt"]
    ptcaspect = Dir[ptcaspectfilespath+"/*.txt"]
    if geoaspect.blank? && ptcaspect.blank?
      render :json=>{:errorflag => "Aspect lookup and PTC Aspect text files are not available for download" }
    else
      render :text => ""
    end
  end
  
  ####################################################################
  # Function:      download_aspecttextfiles
  # Parameters:    None
  # Retrun:        bundle_filename
  # Renders:       send_file
  # Description:   download the all geo & ptc Aspect text files into one zip file
  ####################################################################
  def download_aspecttextfiles
    zipfilename = 'Aspect_Text_files'
    bundle_filename = "#{RAILS_ROOT}/tmp/#{zipfilename}.zip"
    geoaspectfilespath = RAILS_ROOT+'/doc/geo_aspects'
    ptcaspectfilespath = RAILS_ROOT+'/doc/ptc_aspects'
    File.delete(bundle_filename) if File.exists?(bundle_filename)
    Zip::ZipFile.open(bundle_filename, Zip::ZipFile::CREATE) do |zf|
      zf.mkdir("geo_aspects")
      zf.mkdir("ptc_aspects")
      Dir.foreach(geoaspectfilespath) do |x| 
        if ((File.extname(x)=='.txt') || (File.extname(x)=='.TXT'))
          zf.add("geo_aspects/"+x, geoaspectfilespath+'/'+x)
        end
      end
      Dir.foreach(ptcaspectfilespath) do |y| 
        if ((File.extname(y)=='.txt') || (File.extname(y)=='.TXT'))
          zf.add("ptc_aspects/"+y, ptcaspectfilespath+'/'+y)
        end
      end
    end
    send_file(bundle_filename ,:disposition => 'inline' ,:stream => false)
  end
  
  ####################################################################
  # Function:      check_uploadfile_exists
  # Parameters:    params[:upload_filename] ,params[:typeoffile] 
  # Retrun:        message
  # Renders:       render :text => message
  # Description:   Check the upload file already exist or not
  ####################################################################
  def check_uploadfile_exists
    file_name  = params[:upload_filename]
    folder_path = params[:typeoffile]
    upload_file_path = "#{RAILS_ROOT}/doc/#{folder_path}/#{file_name}" 
    message = nil
    if File.exists?(upload_file_path)
      message = "overwrite"
    end
    render :text => message
  end

  ####################################################################
  # Function:      validate_aspectlookup_ptcaspect_file_format
  # Parameters:    geo_ptc_flag ,aspect_files
  # Retrun:        valid_aspect_files
  # Renders:       None
  # Description:   Validate the aspectlookuptable , ptcaspectvalues text file name format
  ####################################################################
  def validate_aspectlookup_ptcaspect_file_format(geo_ptc_flag ,aspect_files)
    search_string = ""
    valid_aspect_files = []
    if geo_ptc_flag == "geo_aspects"
      search_string = "aspectlookuptable"
    elsif  geo_ptc_flag == "ptc_aspects" 
      search_string = "ptcaspectvalues"
    end
    unless aspect_files.blank?
      aspect_files.each do | aspect_file |
        file_name =  File.basename(aspect_file)
        aspect_split = file_name.split('.')
        if((aspect_split[0].downcase == search_string) && aspect_split[aspect_split.length-1].downcase == "txt" && aspect_split.length == 4)
          valid_aspect_files << aspect_file
        end
      end
    end
    return valid_aspect_files
  end
end