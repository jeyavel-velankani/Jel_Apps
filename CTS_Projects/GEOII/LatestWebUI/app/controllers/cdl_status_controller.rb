class CdlStatusController < ApplicationController
####################################################################
# Company: Siemens 
# Author: 
# File: CdlStatusController.rb
# Description: Display CDL Messages
####################################################################
  layout 'general'

  ####################################################################
  # Function:      index
  # Parameters:    none
  # Retrun:        none
  # Renders:       cdl_messages--partial
  # Description:   Display CDL Messages
  ####################################################################  
  def index
    begin
      @text_messages = CdlTextMessage.all
      @txt_color =  CdlStatus.is_running? ? 'white_text' : 'grey_text'
      respond_to do |format|
        format.html
        format.js do
          status = @txt_color == 'white_text' ? '1' : '0'
          render :json => {:error => false, :html => render_to_string(:partial => "cdl_messages"), :status => status}
        end
      end
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end
  end
  ####################################################################
  # Function:      clear_cdl_messages
  # Parameters:    none
  # Retrun:        none
  # Renders:       none
  # Description:   Clear CDL Messages
  ####################################################################  
  def clear_cdl_messages
    begin
      cdl_clear_request = CDLCompilerReq.create()
      udp_send_cmd(REQUEST_COMMAND_CDL_COMPILER, cdl_clear_request.request_id)
      render :json => {:error => false} and return
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end
  end
  
end
