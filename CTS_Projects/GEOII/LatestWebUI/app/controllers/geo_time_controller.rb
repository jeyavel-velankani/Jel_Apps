####################################################################
# Company: Siemens 
# Author: Gopu
# File: geo_time_controller.rb
# Description: This controller is used for GET and SET the Time Settings of the GEO
####################################################################

class GeoTimeController < ApplicationController
  
  include UdpCmdHelper
  
 ###################################################################
 # Function:      get_geo_time
 # Parameters:    none
 # Return:        None
 # Renders:       json
 # Description:   This function is to get the available Time Settings of the GEO.
 ###################################################################
  #Method to get the available Time Settings of the GEO. 
  def get_geo_time
    begin
      @site_time = Time.now
      html_content = render_to_string(:partial => "get_geo_time")
      render :json => {:error => false, :html_content => html_content} and return          
    rescue Exception => e
        render :json => {:error => true, :message => e.message}
    end
  end
  
 ###################################################################
 # Function:      check_state
 # Parameters:    params[:id]
 # Return:        None
 # Renders:       partial/text
 # Description:   This function is to check the request status.
 ###################################################################  
  #Method to check the request status.
  def check_state
    if (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE )
      @site_time = Time.now
      html_content = render_to_string(:partial => "time_settings")
      render :json => {:error => false, :req_state => 2, :html_content => html_content} and return
    end
    begin
      @set_time_rq = SetTimeRequest.find_by_request_id(params[:id])
      if(!@set_time_rq.blank?)
        if @set_time_rq.request_state == 2
          year = @set_time_rq.year.to_s
          day = @set_time_rq.day.to_s
          month = @set_time_rq.month.to_s
          calculate_time(year, day, month)
          @set_time_rq.destroy
          @site_time = Time.now
          html_content = render_to_string(:partial => "time_settings")
          render :json => {:error => false, :req_state => @set_time_rq.request_state, :html_content => html_content} and return
        else
          render :json => {:error => false, :req_state => @set_time_rq.request_state} and return
        end
      else
        render :json => {:error => false, :req_state => ""} and return
      end
    rescue Exception => e
        render :json => {:error => true, :message => e.message}
    end
  end
  
 ###################################################################
 # Function:      geo_time_update
 # Parameters:    site_date,request_id,date
 # Return:        None
 # Renders:       text
 # Description:   This function is for Updating the time and date values in request/reply database.
 ###################################################################  
  #Updating the time and date values in request/reply database.
  def geo_time_update
    #Update the vital CPU time
    if (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE )
      if (params[:hd_time_zone] != params["enum"][:"1"])
          EnumParameter.update_io_assignment_parameters(params["enum"]) if params["enum"]
      end
      render :json => {:error => false, :req_id => 0}
    else
      begin
        selected_date = params[:site_date].split('/')
        @set_time_rq = SetTimeRequest.new(:request_state => 0, :atcs_address => atcs_address + ".01",
                        :command => 1, :hours => params[:date][:"hour"].to_i, :minutes => params[:date][:"minute"].to_i, :seconds => params[:date][:"second"].to_i,
                        :year => selected_date[2], :day => selected_date[1], :month => selected_date[0])
        @set_time_rq.save                
        calculate_time(@set_time_rq.year, @set_time_rq.day, @set_time_rq.month)                
        udp_send_cmd(REQUEST_COMMAND_TIME, @set_time_rq.request_id)
        if (params[:hd_time_zone] != params["enum"][:"1"])
            EnumParameter.update_io_assignment_parameters(params["enum"]) if params["enum"]
        end
        #Update the Non vital CPU time
        # Making time, Time.mktime(year, month, day, hour, min, sec_with_frac) => time  
        mk_time = Time.mktime(selected_date[2], selected_date[0], selected_date[1], params[:date][:"hour"].to_i, params[:date][:"minute"].to_i , params[:date][:"second"].to_i) rescue Time.now
        simple_rq_set_date = RrSimpleRequest.new()
        simple_rq_set_date.atcs_address = "#{Gwe.atcs_address}.02"
        simple_rq_set_date.request_state = 0
        simple_rq_set_date.command = 10
        simple_rq_set_date.subcommand = 0
        simple_rq_set_date.value = mk_time.to_i
        simple_rq_set_date.save
        udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST,  simple_rq_set_date.request_id)
        render :json => {:error => false, :req_id => @set_time_rq.request_id}
      rescue Exception => e
          render :json => {:error => true, :message => e.message}
      end
    end
  end

 ###################################################################
 # Function:      calculate_time
 # Parameters:    none
 # Return:        None
 # Renders:       none
 # Description:   This function is to calculate_time
 ###################################################################
  def calculate_time(year, day, month)
#    @site_date = "#{year}-#{day}-#{month}"
    begin
      @site_date = "#{month}/#{day}/#{year}"
      @hours = @set_time_rq.hours
      @minutes = @set_time_rq.minutes
      @seconds = @set_time_rq.seconds
      @request_id = @set_time_rq.request_id
    rescue Exception => e
        render :json => {:error => true, :message => e.message}
    end
  end
  
end