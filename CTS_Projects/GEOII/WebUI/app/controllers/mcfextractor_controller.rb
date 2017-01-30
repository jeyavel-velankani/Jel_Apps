####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: mcfextractor_controller.rb
# Description: This module will display the list of installed MCF informations and option have to add/delete  
#              File informations
####################################################################
#History:
# Log: /wayside/GEOII/Trunk/Software/WebUI/app/controllers/mcfextractor_controller.rb
#
# Rev 4707   July 16 2013 18:00:00   Jeyavel Natesan
# Initial version
class McfextractorController < ApplicationController
  require 'win32ole' if OCE_MODE == 1
  require "socket"
  require 'zlib'
  layout "general", :except => "process"
  include McfextractorHelper
  include ReportsHelper
  
  ####################################################################
  # Function:      mcfextractor
  # Parameters:    None
  # Retrun:        @approvalstatus ,@mdbfile , @mcf_files , @mcf_installation_collection
  # Renders:       None
  # Description:   Display the MCF Extractor page
  ####################################################################
  def mcfextractor
    if session[:user_id].blank?
      redirect_to :controller => 'access', :action=> 'login_form'
    elsif session[:user_id].to_s == 'oceadmin'
      path = session[:OCE_ConfigPath] + 'tmp' 
      @mdbfile = nil
      @mcf_files = nil
      if File.exists?(path) && File.directory?(path)
        dbfiles = Dir[path+"/*.db"]
        dbfiles.each do |db_file|
          FileUtils.rm_rf(db_file)
        end
        htmllists = Dir[path+"/*.html"]
        htmllists.each do |htmllist|
          File.delete htmllist
        end
        @mcf_files = Dir[path+"/*.*"]
        @mdbfile = Dir[path+"/*.mdb"]
        if params[:type] == 'save'
          @mcf_files.each do |mcf_file|
            File.delete mcf_file
          end
          flash[:notice_mcf] = "<div id='congif_top_icons' class='success_message text_font padding_left_10 padding_top_5'>MCF Extracted Successfully<BR> #{session[:failexception]}</div>"
        end
        if params[:type] == 'fail'
          flash[:notice_mcf] = "<div id='congif_top_icons' class='error_message text_font padding_left_10 padding_top_5'>Installation Failed : (#{session[:failexception]})</div>"
          session[:failexception] = nil
        elsif params[:type] == 'install_exists'
          flash[:notice_mcf] = "<div id='congif_top_icons' class='error_message text_font padding_left_10 padding_top_5'>Installation Failed : Installation name (#{session[:i_name]}) already exist!</div>"
          session[:i_name] = nil
        end
      else
        Dir.mkdir(path)
      end
      unless session[:mcf_installationname].blank?
        begin
          session[:log_fil] = "C:\\WINDOWS\\Temp\\#{session[:mcf_installationname]}\\#{session[:mcf_installationname]}.txt"  
        rescue Exception => e         
        end
      else
        session[:log_fil] = nil
      end  
      session[:node_value] = nil
      session[:node_value1] = 1
      if session[:mantmasterdblocation] != nil
        connectgeoptcmasterdb()
        @mcf_installation_collection = Installationtemplate.all.map(&:InstallationName)
        @parent_count= Geoptcmenu.find(:all, :select => 'Distinct InstallationName' , :order => 'InstallationName COLLATE NOCASE')
      else
        @mcf_installation_collection = nil
        @parent_count = nil
      end
    end
    session[:expires_at] = Time.now + 60.minutes
    @approvalstatus =["Not Approved","Approved"]
  end
  
  ####################################################################
  # Function:      get_installation_approve
  # Parameters:    session[:installationname]
  # Retrun:        stringapprove
  # Renders:       render :text 
  # Description:   Get the selected installation name for approve mcfcrc   
  ####################################################################
  def get_installation_approve
    if !session[:installationname].blank? || !params[:id].blank?
      if session[:installationname].blank?
        @installationname =  params[:id]
      elsif params[:id].blank?
        @installationname =  session[:installationname]
      end
      stringapprove =""
      session[:installationnameforvalidate] = nil
      if @installationname != nil
        session[:installationnameforvalidate] = @installationname
        installationexist = Approval.find(:last,:conditions=>{:InstallationName=>@installationname},:order=>'ApprovalDate, ApprovalTime ASC')
        if  installationexist != nil 
          appcrc =0
          if installationexist.ApprovalCRC != 0
            appcrc = installationexist.ApprovalCRC.to_s(16).upcase
          else
            appcrc = 0 
          end
          @approver = "" 
          unless installationexist.Approver.blank?
            @approver = installationexist.Approver 
          end
          time = installationexist.ApprovalTime.strftime("%H:%M:%S")
          stringapprove = installationexist.InstallationName + '|' + @approver + '|' + installationexist.ApprovalDate.to_s + '|' + time.to_s + '|' + appcrc.to_s + '|' + installationexist.ApprovalStatus
        else
          stringapprove = @installationname
        end
      else
        stringapprove =""
      end
      render :text => stringapprove
    else
      render :text => "Select Installation"
    end
  end
  
  ####################################################################
  # Function:      get_installation_approve_back
  # Parameters:    session[:btnbackinstallationname]
  # Retrun:        @installationname , stringapprove
  # Renders:       render :text
  # Description:   Display the selected installation approve mcfcrc 
  #                page while click back button from the page 
  ####################################################################
  def get_installation_approve_back
    unless session[:btnbackinstallationname].blank?
      @installationname = session[:btnbackinstallationname]
      if @installationname != nil
        session[:installationnameforvalidate] = @installationname
        installationexist = Approval.find(:last,:conditions=>{:InstallationName=>@installationname},:order=>'ApprovalDate, ApprovalTime ASC')
        if  installationexist != nil 
          appcrc = 0
          if installationexist.ApprovalCRC != 0
            appcrc = installationexist.ApprovalCRC.to_s(16).upcase
          else
            appcrc = 0 
          end
          @approver = "" 
          unless installationexist.Approver.blank?
            @approver = installationexist.Approver 
          end
          time = installationexist.ApprovalTime.strftime("%H:%M:%S")
          stringapprove = installationexist.InstallationName + '|' + @approver + '|' + installationexist.ApprovalDate.to_s + '|' + time.to_s + '|' + appcrc.to_s + '|' + installationexist.ApprovalStatus
        else
          stringapprove = @installationname
        end
      else
        stringapprove =""
      end
      render :text => stringapprove
    end
  end
  
  ####################################################################
  # Function:      gethistory
  # Parameters:    params[:installationname]
  # Retrun:        historydata
  # Renders:       render :text 
  # Description:   Get the installation approve/modify user history details  
  ####################################################################
  def gethistory
    session[:btnbackinstallationname] = params[:installationname]
    unless params[:installationname].blank?
      installationexist = Approval.find(:all,:conditions=>['InstallationName=?',params[:installationname]],:order=>"ApprovalDate , ApprovalTime ASC")
      unless installationexist.blank?            
        historydata = "<Table cellspacing='0' cellpadding = '0' border = '1' style='border:1px solid #98bf21;' id = 'tblInsHistory'> "
        historydata = historydata + "<tr style ='background-color:#A7C942; color:#000;'><th style='width:80px'>Approver</th><th style='width:100px'>Approval Date</th><th style='width:100px'>Approval Time</th><th style='width:80px'>CRC</th><th style='width:100px'>Status</th></tr>"
        installationexist.reverse.each{|x|    
          time = x.ApprovalTime.strftime("%H:%M:%S")
          historydata = historydata + "<tr>"
          historydata = historydata + "<td>" + x.Approver.to_s + "</td>"
          historydata = historydata + "<td>" + x.ApprovalDate.to_s + "</td>"
          historydata = historydata + "<td>" + time.to_s + "</td>"
          historydata = historydata + "<td>" + x.ApprovalCRC.to_i.to_s(16).upcase + "</td>"
          historydata = historydata + "<td>" + x.ApprovalStatus.to_s + "</td>"
          historydata = historydata + "</tr>"  
        }
        historydata = historydata + "</Table>"
      else
        historydata = "Approval history not available"
      end
      
    else
      historydata = "Approval history not available"
    end
    render :text => historydata
  end
  
  ####################################################################
  # Function:      ptcgeolog
  # Parameters:    None
  # Retrun:        session[:mcf_installationname]
  # Renders:       None
  # Description:   Display the mcf file extraction logs  
  ####################################################################
  def ptcgeolog
    session[:mcf_installationname] = nil
  end
  
  ####################################################################
  # Function:      page_node
  # Parameters:    params[:installation_name_delete]
  # Retrun:        @node_value
  # Renders:       None
  # Description:   Display the tree view in left side panel
  ####################################################################
  def page_node
    @node_value = params[:installation_name_delete]
    session[:installationname] = params[:installation_name_delete]
    render :nothing => true
  end
  
  ####################################################################
  # Function:      extractmcf
  # Parameters:    params[:userinstallationname]
  # Retrun:        flag
  # Renders:       redirect_to("/mcfextractor/mcfextractor?type=#{flag}")
  # Description:   Extract the selected mcf file and update the date with selected master db 
  ####################################################################
  def extractmcf
    session[:userinstallationname] = params[:userinstallationname]
    session[:log_fil] = nil
    session[:mcf_installationname] = nil
    time = Time.new
    strdatetime= time.strftime("%Y%m%d%H%M%S")
    session[:mcf_installationname] = params[:userinstallationname].to_s+'_'+strdatetime
    installation = Installationtemplate.select_installation(params[:userinstallationname]) 
    flag = nil
    if installation[0].blank? 
      mcfsDir =session[:OCE_ConfigPath]+'tmp' 
      mcf_files = Dir[mcfsDir+"/*.mcf"] 
      aspectlookup_path = converttowindowspath(session[:aspectfilepath])  
      ptcvalue_path = converttowindowspath(current_ptcaspectfile)
      configPath = "#{session[:OCE_ROOT]}\\ConfigPath.xml"
      puts "#{converttowindowspath(mcfsDir)}, #{converttowindowspath(session[:mantmasterdblocation])},#{ session[:mcf_installationname] },#{ aspectlookup_path },#{ ptcvalue_path},#{converttowindowspath(configPath)}"
      unless mcf_files.blank?        
        begin     
          unless session[:mcf_installationname].blank?
            lib = WIN32OLE.new('MCFPTCDataExtractor.MCFExtractor')
            returnvalue = lib.MCFDataExtractor(converttowindowspath(mcfsDir), converttowindowspath(session[:mantmasterdblocation]), session[:mcf_installationname] , aspectlookup_path , ptcvalue_path, converttowindowspath(configPath) )
            unless returnvalue.blank?
              session[:failexception]= returnvalue.to_s
              if returnvalue.include?("Error")                
                flag = 'fail'
              else                
                flag = 'save'
                session[:userinstallationname] = nil
              end
            else
              session[:failexception] = ""
              flag = 'save'  
              session[:userinstallationname] = nil
            end
            logfilepath = "C:/WINDOWS/Temp/#{session[:mcf_installationname]}/McfException.log"
            if File.exists?(logfilepath)
              file = File.new(logfilepath, "r")
              @data = ""
              while (line = file.gets)
                data << line
              end
              file.close
              session[:failexception]= data.to_s # read text file values
              flag = 'fail'              
            end
          end  
        rescue Exception => e  
          session[:failexception]= e.to_s
          flag = 'fail'       
        end
      end    
      session[:i_name] = nil
    else
      flag = 'install_exists'
      session[:i_name] = params[:userinstallationname]
    end
    redirect_to("/mcfextractor/mcfextractor?type=#{flag}")
  end
  
  ####################################################################
  # Function:      createreport
  # Parameters:    session[:installationname]
  # Retrun:        None
  # Renders:       render :text
  # Description:   Send the selected installation name 
  ####################################################################
  def createreport
    unless session[:installationname].blank?
      render :text =>session[:installationname]
    else
      render :text =>"Select Installation"
    end
  end
  
  ####################################################################
  # Function:      deletemcf
  # Parameters:    session[:installationname]
  # Retrun:        None
  # Renders:       redirect_to :controller =>'mcfextractor', :action=>'mcfextractor' 
  # Description:   Delete the selected installation from the master db 
  ####################################################################
  def deletemcf
    unless session[:installationname].blank?
      instname = session[:installationname]
      installation = Installationtemplate.find_by_InstallationName(instname, :include => [:ptcdevices])
      mcfs = Mcfphysicallayout.find(:all, :select =>"MCFName", :conditions => {:InstallationName => instname}).map(&:MCFName).uniq #ptcdevices.map(&:mcfname).uniq
      un = installation.ptcdevices.map(&:Id)
      un.each do |id|
        Signals.delete(id)
        Switch.delete(id)
        Hazarddetector.delete(id)
        Logicstate.destroy_all("Id like '#{id}'")
      end
      Installationtemplate.destroy_all("InstallationName like '#{session[:installationname]}'")
      mcfs.each {|mcf| Mcfptc.destroy_all("MCFName like '#{mcf}'")}
      Mcfphysicallayout.destroy_all("InstallationName like '#{session[:installationname]}'")
      Gcfile.destroy_all("InstallationName like '#{session[:installationname]}'")
      Aspect.destroy_all("InstallationName like '#{session[:installationname]}'")
      Ptcaspect.delete_installationname_ptcaspect(session[:installationname])
      Approval.destroy_all("InstallationName like '#{session[:installationname]}'")
      Atcsconfig.delete_all(['InstallationName=?',session[:installationname]])
      session[:log_fil] = nil
      redirect_to :controller =>'mcfextractor', :action=>'mcfextractor' 
      session[:installationname] = nil
    else
      render :text=>"Select Installation"
    end
    
  end
  
  ####################################################################
  # Function:      remove_mcf
  # Parameters:    params[:removestring]
  # Retrun:        mcffileresult
  # Renders:       render :text =>mcffileresult
  # Description:   Remove the selected mcf from the oce configuration tmp folder 
  ####################################################################
  def remove_mcf
    removemcffile = params[:removestring]
    session[:userinstallationname] = nil
    deletepath = session[:OCE_ConfigPath]+'tmp'
    if removemcffile == "All"
      if File.directory?(deletepath)
        Dir.foreach(deletepath) {|x| 
          fileextn = File.extname(x).downcase
          if fileextn == '.mdb' || fileextn == '.mcf' || fileextn == '.xml' || fileextn == '.log' || fileextn == '.html'
            File.delete(deletepath + '/' + x )
          end
        }
      end
    else
      unless removemcffile.blank?
        deletemcffilearray = removemcffile.split('|')
        deletemcffilearray.each do |mcf_file|
          if File.exist?(deletepath+'/'+mcf_file)
            File.delete(deletepath+'/'+mcf_file) 
            xmldeletecheck = mcf_file.split('.')
            if File.extname(mcf_file)=='.mcf' 
              deletexmlfilepath =deletepath+'/'+xmldeletecheck[0]+'.xml'
              if File.exist?(deletexmlfilepath)
                File.delete(deletexmlfilepath) 
              end
            elsif File.extname(mcf_file)=='.xml'
              deletemcffilepath = deletepath+'/'+xmldeletecheck[0]+'.mcf'
              if File.exist?(deletemcffilepath)
                File.delete(deletemcffilepath)
              end
            end
          end
        end
        
      end
    end
    path = session[:OCE_ConfigPath]+'tmp' 
    mcffiles = Dir[path+"/*.*"]
    mcffileresult =""
    mcffiles.each{|file|
      mcffileresult << File.basename(file) << '|'
    }
    render :text =>mcffileresult
  end
  
  ####################################################################
  # Function:      ptcgeodb_browse_folder
  # Parameters:    None
  # Retrun:        @root_entries
  # Renders:       render :layout => false
  # Description:   display the server master db files and select the master db file 
  ####################################################################
  def ptcgeodb_browse_folder
    get_route_entries_db
    render :layout => false
  end
  
  ####################################################################
  # Function:      create_new_masterdatabase
  # Parameters:    None
  # Retrun:        @root_entries
  # Renders:       render :layout => false
  # Description:   create the new master db in Masterdb location 
  ####################################################################
  def create_new_masterdatabase
    get_route_entries_db
    render :layout => false
  end
  
  ####################################################################
  # Function:      approve_installation_name
  # Parameters:    session[:installationnameforvalidate]
  # Retrun:        @validinstallationname
  # Renders:       render :layout => false
  # Description:   Open the geo ptc db approve page 
  ####################################################################
  def approve_installation_name
    @validinstallationname = session[:installationnameforvalidate]
    render :layout => false
  end
  
  ####################################################################
  # Function:      unapprove_installation_name
  # Parameters:    session[:installationnameforvalidate]
  # Retrun:        @validinstallationname
  # Renders:       render :layout => false
  # Description:   Open the geo ptc installation un-approve page
  ####################################################################
  def unapprove_installation_name
    @validinstallationname = session[:installationnameforvalidate]
    render :layout => false
  end
  
  ####################################################################
  # Function:      open_masterdatabase
  # Parameters:    None
  # Retrun:        @root_entries
  # Renders:       render :layout => false
  # Description:   Open master db file 
  ####################################################################
  def open_masterdatabase
    get_route_entries_db
    render :layout => false
  end
  
  ####################################################################
  # Function:      select_installation
  # Parameters:    session[:mantmasterdblocation]
  # Retrun:        None
  # Renders:       render :layout => false
  # Description:   Get the all installation from the selected master database 
  ####################################################################
  def select_installation_name_report
    get_installation_names(session[:mantmasterdblocation])
    render :layout => false
  end
  
  ####################################################################
  # Function:      get_installation_names
  # Parameters:    masterdbpath
  # Retrun:        @installation_names
  # Renders:       None
  # Description:   Get all the installation names from the database 
  ####################################################################
  def get_installation_names(masterdbpath)
    @installation_names = Installationtemplate.select_all_installations()
  end
  
  ####################################################################
  # Function:      select_installation_name_approve
  # Parameters:    session[:mantmasterdblocation]
  # Retrun:        @installation_names
  # Renders:       render :layout => false
  # Description:   select the installation name for approve 
  ####################################################################
  def select_installation_name_approve
    session[:installationname] = nil
    get_installation_names_approve(session[:mantmasterdblocation])
    render :layout => false
  end
  
  ####################################################################
  # Function:      get_installation_names_approve
  # Parameters:    masterdbpath
  # Retrun:        @installation_names
  # Renders:       None
  # Description:   Get the installation names for approve
  ####################################################################
  def get_installation_names_approve(masterdbpath)
    @installation_names = Installationtemplate.select_all_installations()
  end
  
  ####################################################################
  # Function:      rename_installationname
  # Parameters:    session[:installationname]
  # Retrun:        session[:selectedinstallationname] 
  # Renders:       render :layout => false
  # Description:   Open the Rename installation page  
  ####################################################################
  def rename_installationname
    session[:selectedinstallationname] = session[:installationname]
    render :layout => false
  end
  
  ####################################################################
  # Function:      rename_exist_inatallationname
  # Parameters:    params[:existinstallationname] , params[:newinstallationname]
  # Retrun:        returnresult
  # Renders:       render :text =>returnresult
  # Description:   Rename the seleceted installation names 
  ####################################################################
  def rename_exist_inatallationname
    exist_inst_name = params[:existinstallationname]
    new_inst_name =  params[:newinstallationname]
    returnresult = nil
    installationalreadyexist = Installationtemplate.find(:all, :conditions =>['InstallationName = ?',new_inst_name]).map(&:InstallationName)
    if (installationalreadyexist.length == 0)
      begin
        Installationtemplate.update_all("InstallationName = '#{new_inst_name}'", {:InstallationName => exist_inst_name})
        Mcfphysicallayout.update_all("InstallationName = '#{new_inst_name}'", {:InstallationName => exist_inst_name})
        Atcsconfig.update_all("InstallationName = '#{new_inst_name}'", {:InstallationName => exist_inst_name})
        Gcfile.update_all("InstallationName = '#{new_inst_name}'", {:InstallationName => exist_inst_name})
        Ptcdevice.update_all("InstallationName = '#{new_inst_name}'", {:InstallationName => exist_inst_name})
        Ptcaspect.update_all("InstallationName = '#{new_inst_name}'", {:InstallationName => exist_inst_name})
        Aspect.update_all("InstallationName = '#{new_inst_name}'", {:InstallationName => exist_inst_name})
        Approval.update_all("InstallationName = '#{new_inst_name}'", {:InstallationName => exist_inst_name})
        returnresult ="Installation renamed successfully."
      rescue Exception =>e
        puts e
        unless e.blank?
          returnresult = "Installation rename failed :"+e.to_s
        end
      end
    else
      returnresult = "Installation Name(#{new_inst_name}) already existed , Please enter another name. |"
    end
    render :text =>returnresult
  end
  
  ####################################################################
  # Function:      get_route_entries_db
  # Parameters:    None
  # Retrun:        @root_entries
  # Renders:       None
  # Description:   get the all files from Masterdb folder 
  ####################################################################
  def get_route_entries_db
    root_directory = File.join(RAILS_ROOT, "/Masterdb")
    Dir.mkdir(root_directory) unless File.exists? root_directory
    if Dir[root_directory + "/*"] !=nil
      @root_entries = Dir[root_directory + "/*.db"].reject{|f| [".", ".."].include? f}
    else
      @root_entries= nil
    end
  end
  
  ####################################################################
  # Function:      ptcgeodb_opengeoptcmasterdb
  # Parameters:    params[:open_masterdbfile_path_name]
  # Retrun:        None
  # Renders:       render :text => ""
  # Description:   Open master db file from Masterdb folder dialog
  ####################################################################
  def ptcgeodb_opengeoptcmasterdb
    session[:log_fil] = nil
    session[:installationname] = nil
    session[:mantmasterdblocation] = nil
    path = RAILS_ROOT + '/Masterdb/' + params[:open_masterdbfile_path_name]
    if File.exist?(path)
      session[:mantmasterdblocation] = path 
      connectgeoptcmasterdb()
    end
    render :text => ""
  end
  
  ####################################################################
  # Function:      ptcgeodb_createnewmastergeoptcdb
  # Parameters:    params[:file_name]
  # Retrun:        None
  # Renders:       render :text => ""
  # Description:   Create new master db in Masterdb folder
  ####################################################################
  def ptcgeodb_createnewmastergeoptcdb
    session[:log_fil] = nil
    session[:installationname] = nil
    session[:mantmasterdblocation] = nil
    to = RAILS_ROOT + '/Masterdb/' + params[:file_name]+'.db'
    if File.exists?(to)
      flash[:ptcdatabasemessage] = "Entered DB name already exist ,Please give different name."
    else
      from = RAILS_ROOT+'/db/InitialDB/iviu/GEOPTC.db'
      FileUtils.cp(from , to)
      session[:mantmasterdblocation] = to
      db = SQLite3::Database.new(session[:mantmasterdblocation])
      db.execute( "Insert into Versions (Id ,SchemaVersion , ApprovalCRCVersion) values(1,1,1)")
      db.close
      connectgeoptcmasterdb()
    end
    render :text => ""
  end
  
  ####################################################################
  # Function:      approvalcrc
  # Parameters:    params[:installationapprovalstatus]
  # Retrun:        @currentdate
  # Renders:       render :text =>""
  # Description:   Approve the crc for selected installation
  ####################################################################
  def approvalcrc    
    @currentdate = Date.today.strftime('%Y-%m-%d')
    newtime = Time.new
    user_time = newtime.strftime("%H:%M:%S")
    crc = 0
    if params[:installationapprovalstatus] == "Approved"
      crc = params[:installationapprovalcrc].hex.to_s
    end
    session[:installationname] = params[:installationname]
    db = SQLite3::Database.new(session[:mantmasterdblocation])
    if params[:installationapprovalstatus] == "Approved"
      db.execute("Insert into Approval values('#{params[:installationname]}','#{params[:installationapprover]}','#{@currentdate}','#{user_time}','#{crc}','#{params[:installationapprovalstatus]}')" )
    else
      db.execute("Insert into Approval values('#{params[:installationname]}','#{params[:installationapprover]}','#{@currentdate}','#{user_time}','#{crc}','#{params[:installationapprovalstatus]}')" )
    end
    db.close
    render :text =>""
  end
  
  ####################################################################
  # Function:      upload_am_non_am_mcf
  # Parameters:    session[:OCE_ConfigPath]
  # Retrun:        @mdbfiles
  # Renders:       render :layout => false
  # Description:   Select the non appliance model mcf list from the system 
  ####################################################################
  def upload_am_non_am_mcf
    path = session[:OCE_ConfigPath] + 'tmp'
    @mdbfiles = Dir[path+"/*.mdb"]
    @mdbfile = nil
    @mdbfiles.each do |mdb_file| 
      @mdbfile = File.basename(mdb_file)
    end
    render :layout => false
  end
  
  ####################################################################
  # Function:      checknonappliancemodelupload
  # Parameters:    params[:fileToUpload]
  # Retrun:        None
  # Renders:       render :text =>""
  # Description:   Upload the non appliance model mcf in the specified location
  ####################################################################
  def checknonappliancemodelupload
    cdl_file_directory = session[:OCE_ConfigPath] + 'tmp'
    begin
      unless params[:fileToUpload].blank?
        file1_name = params[:fileToUpload].original_filename
        Dir.mkdir(cdl_file_directory) unless File.exists? cdl_file_directory 
        path = File.join(cdl_file_directory, file1_name)
        File.open(path, "wb") do |f| 
          f.write(params[:fileToUpload].read)
          f.close;
        end 
      end
      mcffilename = nil
      unless params[:fileToUpload1].blank?
        file2_name = params[:fileToUpload1].original_filename
        Dir.mkdir(cdl_file_directory) unless File.exists? cdl_file_directory 
        path = File.join(cdl_file_directory, file2_name)
        File.open(path, "wb") do |f| 
          f.write(params[:fileToUpload1].read)
          f.close;
        end
        mcffilename = file2_name.split('.')
      end
      unless params[:fileToUpload3].blank?
        Dir.mkdir(cdl_file_directory) unless File.exists? cdl_file_directory 
        path = File.join(cdl_file_directory, mcffilename[0]+'.xml')
        File.open(path, "wb") do |f| 
          f.write(params[:fileToUpload3].read)
          f.close;
        end
      end
      unless params[:fileToUpload11].blank?
        nonapmmcf = params[:fileToUpload11].original_filename
        Dir.mkdir(cdl_file_directory) unless File.exists? cdl_file_directory 
        path = File.join(cdl_file_directory , nonapmmcf)
        File.open(path, "wb") do |f| 
          f.write(params[:fileToUpload11].read)
          f.close;
        end
      end
    rescue Exception => e
      puts 'Failed :'+e.to_s
    end
    render :text =>""
  end
end
