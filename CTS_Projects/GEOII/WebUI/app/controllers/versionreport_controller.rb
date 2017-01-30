####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: versionreport_controller.rb
# Description: Create/Download the Configuration/Version reports from the system 
####################################################################
class VersionreportController < ApplicationController  
  layout "general"
  include UdpCmdHelper
  include SessionHelper

  before_filter :cpu_status_redirect , :only => [:configuration]
  
  ####################################################################
  # Function:      index
  # Parameters:    params[:report_id]
  # Retrun:        @selected_report_type
  # Renders:       none
  # Description:   Display the reports create/download for corresponding selected report type 
  ####################################################################
  def index(report_id)
    @selected_report_type = report_id
  end

  def version
    index(1)

    render :template =>'versionreport/index', :layout => nil
  end

  def configuration
    index(2)

    render :template =>'versionreport/index', :layout => nil
  end
  
  ####################################################################
  # Function:      get_type_report
  # Parameters:    type
  # Retrun:        string
  # Renders:       None
  # Description:   Get the name for downloading for selected report type
  ####################################################################
  def get_type_report(type)
    case(type.to_i)
      when VERSION_REPORT
      return  create_file_name("Version")
      when CONFIG_REPORT
      return create_file_name("Configuration")
    end
  end
  
  ####################################################################
  # Function:      UDP_call
  # Parameters:    params[:report_type]
  # Retrun:        requestID
  # Renders:       :text => requestID 
  # Description:   Send the UDP message to backend to create the selected type report
  ####################################################################
  def UDP_call  
    processing_report_status = ReportsDb.find(:last,:conditions =>['request_state=1'])
    if processing_report_status.blank?
      @r_type = params[:report_type].to_i
      atcs_addrs = RtSession.find_rt_atcs_addr
      if atcs_addrs.any?
        atcs_value =  atcs_addrs[0].atcs_address+'.01'
      end
      requestID = create_report_request(atcs_value, @r_type)
      udp_send_cmd(REQUEST_COMMAND_REPORT,requestID)
      render :text => requestID 
    else
      render :text => ""
    end
  end
  
  ####################################################################
  # Function:      check_report_state
  # Parameters:    params[:request_id]
  # Retrun:        status
  # Renders:       render :json
  # Description:   Check the UDP message state for create report 
  ####################################################################
  def check_report_state
    request_id  = params[:request_id].to_i
    status = ReportsDb.find_by_request_id(request_id)
    if(status)    
      complete = 0
      if(status.percent_complete)
        complete = status.percent_complete
      end
      render :json => {:requeststate => status.request_state, :PercentComplete => complete}   
    else
      render :json => {:requeststate => -1,  :PercentComplete => 0}
    end
  end
  
  ####################################################################
  # Function:      render_report
  # Parameters:    params[:request_id]
  # Retrun:        @filep
  # Renders:       :partial => 'report'
  # Description:   Display the created report in the page
  ####################################################################
  def render_report
    request_id  = params[:request_id].to_i
    status = ReportsDb.find_by_request_id(request_id)
    @filep = status.full_path 
    ReportsDb.delete_all(:request_id=> request_id )  
    if(status)
      render :partial => 'report', :content_type => 'text/html'      
    else
      render :json => {:invalidinfo => true}
    end
  end
  
  ####################################################################
  # Function:      download_txt_file
  # Parameters:    params[:download_path]
  # Retrun:        path
  # Renders:       send_file(path)
  # Description:   Download the created report file from the system
  ####################################################################
  def download_txt_file
    path = params[:download_path]
    unless path.blank?
      report_name = get_type_report(params[:report_type])
      send_file(path, :filename    => "#{report_name}.txt", 
                      :type        =>'text/plain',
                      :disposition =>'attachment',
                      :encoding    =>'utf8',
                      :stream      =>'true',
                      :x_sendfile => true) 
    else
      redirect_to :action => "index", :type => session[:r_type]
    end
  end
  
  ####################################################################
  # Function:      create_report_request
  # Parameters:    atcs_address, report_type
  # Retrun:        new_req.request_id
  # Renders:       None
  # Description:   create ReportsDb object
  ####################################################################
  def create_report_request(atcs_address, report_type)
    report_name =  get_type_report(report_type)
    new_req = ReportsDb.new({:atcs_address     => atcs_address, 
                             :report_name      => report_name, 
                             :report_type      => report_type,
                             :percent_complete => 0, 
                             :request_state    => REQUEST_STATE_START})
    new_req.save
    return new_req.request_id
  end
  
end
