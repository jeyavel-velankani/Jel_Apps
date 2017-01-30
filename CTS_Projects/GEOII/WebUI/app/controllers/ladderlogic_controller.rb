####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: ladderlogic_controller.rb
# Description: Upload Lader logic file  
####################################################################
#History:
# Log: /wayside/GEOII/Trunk/Software/WebUI/app/controllers/ladderlogic_controller.rb
#
# Rev 4769   Jan 13 2014 17:00:00   Jeyavel Natesan
# Initial version
class LadderlogicController < ApplicationController
  layout 'general'
  include ReportsHelper
  include UdpCmdHelper
  include GenericHelper
  before_filter :setup

  ####################################################################
  # Function:      setup
  # Parameters:    None
  # Retrun:        None 
  # Renders:       None
  # Description:   Check the site configuration and display message
  ####################################################################
  def setup
    if OCE_MODE ==1
      unless session[:cfgsitelocation].blank?
         (ActiveRecord::Base.configurations["development"])["database"] = session[:cfgsitelocation]+'/nvconfig.sql3'
      else
        session[:error] = "Please create/open the configuration from the configuration editor page and try again"
        redirect_to :controller=>"redirectpage" , :action=>"index"
      end
    end
  end

  ####################################################################
  # Function:      index
  # Parameters:    None
  # Retrun:        @enabled 
  # Renders:       None
  # Description:   Get the Non-Vital Ladder Logic enabled flag value and display page
  ####################################################################
  def index
    nvladderlogic = EnumParameter.find(:all , :select =>"Selected_Value_ID", :conditions =>['Id=?',12]).map(&:Selected_Value_ID) 
    @enabled = (nvladderlogic[0].to_s == '100')? true:false
  end
  
  ####################################################################
  # Function:      ll_upload
  # Parameters:    None
  # Retrun:        None 
  # Renders:       Json
  # Description:   Upload the LLB , LLW file to the system
  ####################################################################
  def ll_upload
    llb, llw = 0, 0
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      cdl_file_directory = session[:cfgsitelocation] 
      llb_org_file_name = params[:llb_file_upload].original_filename
      llw_org_file_name = params[:llw_file_upload].original_filename
      if llb_org_file_name.to_s.end_with?(".llb") 
        llb = llb.to_i + 1
      elsif llb_org_file_name.to_s.end_with?(".llw")
        llw = llw.to_i + 1
      end
      if llw_org_file_name.to_s.end_with?(".llb") 
        llb = llb.to_i + 1
      elsif llw_org_file_name.to_s.end_with?(".llw")
        llw = llw.to_i + 1
      end
      if (llb.to_i == 1) && (llw.to_i == 1)
        begin
          Dir.chdir(cdl_file_directory)
          Dir.glob("*.llb") do |file_name|
            File.delete cdl_file_directory.to_s + "/" + file_name.to_s
          end
          Dir.glob("*.llw") do |file_name|
            File.delete cdl_file_directory.to_s + "/" + file_name.to_s
          end
        rescue Exception => e
          render :json => { :oce_mode => true, :error => true, :message => "An Error occured while uploading files" } and return
        end
        begin
          Dir.mkdir(cdl_file_directory) unless File.exists? cdl_file_directory 
          path = File.join(cdl_file_directory, llb_org_file_name)
          File.open(path, "wb") do |f| 
            f.write(params[:llb_file_upload].read)
            f.close;
          end
          Dir.mkdir(cdl_file_directory) unless File.exists? cdl_file_directory 
          path = File.join(cdl_file_directory, llw_org_file_name)
          File.open(path, "wb") do |f| 
            f.write(params[:llw_file_upload].read)
            f.close;
          end
          render :json => { :oce_mode => true, :error => false, :message => "Files Uploaded Successfully"}
        rescue Exception => e
          render :json => { :oce_mode => true, :error => true, :message => "An Error occured while uploading files"}
        end
      else
        render :json => { :oce_mode => true, :error => true, :message => "Invalid file upload. There should be 1 llb file and 1 llw file."}
      end
    else
      target, port, atcs_addr = 8, "", ""
      config = open_ui_configuration
      firm_type = config["upload_directory"]["iviu_ldr_logic"]
      llw_org_file_name = params[:llw_file_upload].original_filename
      llw_file_name = params[:llw_file_upload].read
      llb_org_file_name = params[:llb_file_upload].original_filename
      llb_org_file_name = params[:llb_file_upload].read
      render :json => savevalues(target, port, llw_org_file_name, firm_type, atcs_addr, 14, llb_org_file_name, 15)
    end
  end
  
  ####################################################################
  # Function:      savevalues
  # Parameters:    target, port, llw_file_name, path, atcs_addr, llw_file_type, llb_file_name, llb_file_type
  # Retrun:        hash values 
  # Renders:       None
  # Description:   create upload file record in the software upload table
  ####################################################################
  def savevalues(target, port, llw_file_name, path, atcs_addr, llw_file_type, llb_file_name, llb_file_type )       
    llw_upload = SoftwareUpload.new(:request_state => 0, :atcs_address => atcs_addr, 
                  :port => port, :target => target, :mcfcrc => 0,
                  :path => path, :file_name => llw_file_name, :file_type => llw_file_type)
    llw_upload.save
    llb_upload = SoftwareUpload.new(:request_state => 0, :atcs_address => atcs_addr, 
                  :port => port, :target => target, :mcfcrc => 0,
                  :path => path, :file_name => llb_file_name, :file_type => llb_file_type)
    llb_upload.save
    udp_send_cmd(REQUEST_COMMAND_UPLOAD_FILE, llw_upload.id)
    udp_send_cmd(REQUEST_COMMAND_UPLOAD_FILE, llb_upload.id)
    return { :oce_mode => false, :error => false, :llw_request_id => llw_upload.id, :llb_request_id => llb_upload.id }
  end

  ####################################################################
  # Function:      cancel_softwareupdate
  # Parameters:    None
  # Retrun:        None 
  # Renders:       JSON
  # Description:   Return the cancel ladder logic file success message
  ####################################################################
  def cancel_softwareupdate
    SoftwareUpload.update_req_repid(params[:llw_request_id],-1)
    SoftwareUpload.update_req_repid(params[:llb_request_id],-1)
    render :json => cancel_request(params[:llw_request_id], params[:llb_request_id], REQUEST_COMMAND_UPLOAD_FILE)
  end

  ####################################################################
  # Function:      cancel_request
  # Parameters:    None
  # Retrun:        llw_request_id, llb_request_id, command 
  # Renders:       NOne
  # Description:   Return success/Fail message to user
  ####################################################################
  def cancel_request(llw_request_id, llb_request_id, command)                                                                                                               
    llw_request = SoftwareUpload.find(:first, :conditions => ["request_state = ? and request_id = ?", -1, llw_request_id], :select => "request_id")
    llb_request = SoftwareUpload.find(:first, :conditions => ["request_state = ? and request_id = ?", -1, llb_request_id], :select => "request_id")
    if llw_request               
      udp_send_cmd(command, llw_request_id)                                                                                                 
      if llb_request               
        udp_send_cmd(command, llb_request_id)
        return { :error => false, :message => "Successfully canceled update process" }
      end
    end
    return { :error => true, :message => "Failed to canceled update process" }
  end

  ####################################################################
  # Function:      ll_update_process
  # Parameters:    None
  # Retrun:        llb_result 
  # Renders:       None
  # Description:   Get the upload ladder logic file process status
  ####################################################################
  def ll_update_process
    llw_status =  SoftwareUpload.find_by_request_id(params[:llw_request_id])  
    if llw_status.percentage_complete != 100 and llw_status.result != 0
      llw_result = { :llw_percentage => llw_status.percentage_complete, :llw_filename => llw_status.file_name.to_s,
                        :llw_message => llw_status.error_message, :llw_path => llw_status.path, :llw_error => false, :llw_process_done => false}      
    elsif llw_status.percentage_complete == 100 and llw_status.result == 200 and llw_status.request_state == 2
        llw_result = { :llw_percentage => llw_status.percentage_complete, :llw_filename => llw_status.file_name.to_s,
                        :llw_message => "file uploaded successfully. System going to Reboot", :llw_path => llw_status.path, :llw_error => false, :llw_process_done => true}
        SoftwareUpload.delete_requestid(params[:llw_request_id], state)
    elsif status.percentage_complete == 100 and status.result == 220 and status.request_state == 2
        llw_result = { :llw_percentage => llw_status.percentage_complete, :llw_filename => llw_status.file_name.to_s,
                        :llw_message => status.error_message, :llw_path => llw_status.path, :llw_error => true, :llw_process_done => true}
        SoftwareUpload.delete_requestid(params[:llw_request_id], state)
    end
    
    llb_status =  SoftwareUpload.find_by_request_id(params[:llb_request_id])  
    if llb_status.percentage_complete != 100 and llb_status.result != 0
      llb_result = { :llb_percentage => llb_status.percentage_complete, :llb_filename => llb_status.file_name.to_s,
                        :llb_message => llb_status.error_message, :llb_path => llb_status.path, :llb_error => false, :llb_process_done => false}      
    elsif llb_status.percentage_complete == 100 and llb_status.result == 200 and llb_status.request_state == 2
      llb_result = { :llb_percentage => llb_status.percentage_complete, :llb_filename => llb_status.file_name.to_s,
                        :llb_message => "File uploaded successfully. System going to Reboot", :llb_path => llb_status.path, :llb_error => false, :llb_process_done => true}
      SoftwareUpload.delete_requestid(params[:llb_request_id], state)
    elsif llb_status.percentage_complete == 100 and llb_status.result == 220 and llb_status.request_state == 2
      llb_result = { :llb_percentage => llb_status.percentage_complete, :llb_filename => llb_status.file_name.to_s,
                        :llb_message => status.error_message, :llb_path => llb_status.path, :llb_error => true, :llb_process_done => true}
      SoftwareUpload.delete_requestid(params[:llb_request_id], state)
    end
    render :json => llw_result.merge(llb_result)
  end

  ####################################################################
  # Function:      updatenvladderlogicstatus
  # Parameters:    None
  # Retrun:        params[:nvladderlogicstatus] 
  # Renders:       None
  # Description:   Update the non-vital ladder logic flag enable/disable
  ####################################################################
  def updatenvladderlogicstatus
    value = (params[:nvladderlogicstatus].to_s == 'true')? "100":"101"
    EnumParameter.enumparam_update_query(value,12) 
    render :nothing => true
  end
end
