####################################################################
# Company: Siemens 
# Author: Vijay Anand G
# File: object_name_controller.rb
# Description: This controller is used to SET the UCN value.
####################################################################
class UcnController < ApplicationController
  include UdpCmdHelper
  
  def index
    if Generalststistics.isUSB?
      @ucn = get_ucn (ECD_DIR + "/UCN.TXT")
      @ptcucn = get_ucn (ECD_DIR + "/PTCUCN.TXT")
    else
      @ucn = ""
      @ptcucn = ""
    end

    render :partial => "ucn"
  end
  
 ###################################################################
 # Function:      set_ucn
 # Parameters:    None
 # Return:        None
 # Renders:       none
 # Description:   This function is used to set the UCN value
 ###################################################################
  def set_ucn
    begin
      @sin_value = Gwe.find(:first, :select => "sin").try(:sin) || "" 
      # make entry into the request/reply database.Apend .02 to atcs address to send the request.
      if Generalststistics.isUSB?
        simplerequest = RrSimpleRequest.create(:request_state => 0, :command => 18, :value => params[:ucn].to_i(16))
        udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, simplerequest.request_id)
        render :json => { :request_id => simplerequest.request_id }
      else
        set_ucn_rq = SetUcnRequest.new
        set_ucn_rq.request_state = 0
        set_ucn_rq.atcs_address = @sin_value + ".02"
        set_ucn_rq.command = 2
        set_ucn_rq.ucn = params[:ucn]
        set_ucn_rq.save

        udp_send_cmd(REQUEST_COMMAND_SET_UCN, set_ucn_rq.request_id)
        render :json => { :request_id => set_ucn_rq.request_id }
      end
    rescue Exception => e
        render :json => {:error => true, :message => e.message}
    end   
  end

 ###################################################################
 # Function:       check_state
 # Parameters:    None
 # Return:        None
 # Renders:       none
 # Description:   This function is used to check the request state.
 ###################################################################
  def check_state
    begin
      set_ucn_rq = SetUcnRequest.find_by_request_id(params[:id])
      saved = true
      message = ""
      if set_ucn_rq.request_state == 2
        if set_ucn_rq.key_not_pressed_flag == 1
          message = I18n.t("key_not_pressed_ucn")
          saved = false
        elsif set_ucn_rq.ucn_incorrect_flag == 1
          message = I18n.t("wrong_ucn")
          saved = false
        elsif set_ucn_rq.saved == 0
          message = I18n.t("changes_saved_successfully")
        end
        delete_request(params[:id], REQUEST_COMMAND_SET_UCN)
        render :json => { :request_state => 2, :saved => saved, :message => message }
      else
        delete_request(params[:id], REQUEST_COMMAND_SET_UCN) if(params[:delete_request] == "true")
        render :json => { :request_state => set_ucn_rq.request_state }
      end
    rescue Exception => e
        render :json => {:error => true, :message => e.message}
    end    
  end

 ###################################################################
 # Function:       check_simple_request_state
 # Parameters:    None
 # Return:        None
 # Renders:       none
 # Description:   This function is used to check the request state for sismple request.
 ###################################################################
  def check_simple_request_state
    begin
      simplerequest = RrSimpleRequest.find_by_request_id(params[:id])
      saved = true
      message = ""
      if simplerequest.request_state == 2       
        delete_request(params[:id], REQUEST_COMMAND_SET_UCN)
        render :json => { :request_state => 2, :saved => saved, :message => "changes_saved_successfully" }
      else
        delete_request(params[:id], REQUEST_COMMAND_SET_UCN) if(params[:delete_request] == "true")
        render :json => { :request_state => simplerequest.request_state }
      end
    rescue Exception => e
        render :json => {:error => true, :message => e.message}
    end    
  end

 ###################################################################
 # Function:      set_ptc_ucn
 # Parameters:    None
 # Return:        None
 # Renders:       none
 # Description:   This function is used to set the PTC UCN value
 ###################################################################
  def set_ptc_ucn
    begin
      # make entry into the request/reply database.Apend .02 to atcs address to send the request.
      simplerequest = RrSimpleRequest.create(:request_state => 0, :command => 19, :value => params[:ptc_ucn].to_i(16))
      udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, simplerequest.request_id)
      render :json => { :request_id => simplerequest.request_id }
    rescue Exception => e
        render :json => {:error => true, :message => e.message}
    end   
  end
 
 ###################################################################
 # Function:      reset_vlp
 # Parameters:    None
 # Return:        None
 # Renders:       json => request_id
 # Description:   This function is used to reset_vlp.
 ###################################################################    
  def reset_vlp
    begin
      rr_simple_request = RrSimpleRequest.create({:atcs_address => atcs_address+".02", :command => 5, :request_state => 0, :result => ""})
      udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, rr_simple_request.id)
      render :json => {:request_id => rr_simple_request.id}
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end     
  end
 
 ###################################################################
 # Function:      check_reset_vlp_state
 # Parameters:    params[:request_id]
 # Return:        None
 # Renders:       json
 # Description:   This function is used to check the request state.
 ###################################################################  
  def check_reset_vlp_state
    begin
      rr_simple_request = RrSimpleRequest.find(params[:request_id]) if !params[:request_id].blank?
      if(rr_simple_request)
        delete_request(params[:request_id], REQUEST_COMMAND_SIMPLE_REQUEST) if(params[:delete_request] == "true" || rr_simple_request.request_state == 2)
        render :json => {:request_state => rr_simple_request.request_state, :result => rr_simple_request.result}
      else
        render :json => {:request_state => 2, :result => 1}
      end
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end     
  end

private
  def get_ucn(ucn_file)
      if File.exist?(ucn_file)
        File.open(ucn_file) do |fp|
          fp.each do |line|
            value  = line.split(":")
            if (value[0].strip == "UCN" || value[0].strip == "PTCUCN")
              ucn = value[1].strip.to_s.upcase.split("X")
              if ucn.length == 2
                return ucn[1]
              end
            end
          end
        end
      end
      return ""
  end

 
end