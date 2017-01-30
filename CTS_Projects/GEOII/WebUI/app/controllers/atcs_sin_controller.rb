####################################################################
# Company: Siemens 
# Author: Vijay Anand G
# File: atcs_sin_controller.rb
# Description: This controller is used to GET the sin settings from GEO and 
#               to update sin values in database.
####################################################################
class AtcsSinController < ApplicationController
  layout "general"
  include UdpCmdHelper  
   
 ###################################################################
 # Function:      check_state
 # Parameters:    None
 # Return:        None
 # Renders:       none
 # Description:   This function is used to check the request state for both sin and pending Sin.
 ###################################################################
  #Method to check the request status.
  def check_state
    @set_atcs_sin_rq = AtcsSin.find_by_request_id(params[:id])
    @get_sin_value = AtcsSinValue.find_by_request_id(@set_atcs_sin_rq.id)
    sin = @get_sin_value.sin
    sin0 = sin.insert 1, "."
    sin1 = sin0.insert 5, "."
    sin2 = sin1.insert 9, "."
    final_sin = sin2.insert 13, "."
    @get_pending_value = AtcsSinValue.find(:last, :conditions => ['id != ? and request_id = ?', @get_sin_value.id, @set_atcs_sin_rq.request_id])
    pending_value = @get_pending_value.sin unless @get_pending_value.blank?
    if pending_value != nil
      final_pending0 = pending_value.insert 1, "."
      final_pending1 = final_pending0.insert 5, "."
      final_pending2 = final_pending1.insert 9, "."
      final_pending = final_pending2.insert 13, "."
    end
    if (@set_atcs_sin_rq.request_state == 2 && @set_atcs_sin_rq.result == 0 && (@set_atcs_sin_rq.command == 1 || @set_atcs_sin_rq.command == 2))
      if @set_atcs_sin_rq.command == 2 
        sleep 2
        if PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI
          #split the sin and update in integer parameter table 1- Railroad RRR  , 2- Line LLL ,3- Group GGG , 5- CPU2+ Subnode SS
          unless final_sin.blank?
            split_sin = final_sin.split('.')
            sin_ids  = {}
            subnode_val = nil
            if (split_sin[4].length == 1)
                subnode_val = "0#{split_sin[4]}"
            else
                subnode_val = split_sin[4]
            end  
            sin_ids = {1=>split_sin[1] ,2=>split_sin[2],3=>split_sin[3], 5=> subnode_val}
            sin_ids.each do |key , value|
              IntegerParameter.integerparam_update_query(value.to_i , key.to_i)
            end
          end
        end
      end
      user_presence = Uistate.find_by_name_and_value_and_sin("local_user_present", 1, @set_atcs_sin_rq.atcs_address.split(".")[0,5].join("."))
      @editmode = user_presence ? true : false      
      @geo_non_am = geo_non_am(final_sin)
      
      if @set_atcs_sin_rq.command == 2
        render :json => { :request_id => @set_atcs_sin_rq.request_id, :request_state => @set_atcs_sin_rq.request_state, :result => @set_atcs_sin_rq.result}
      else
        render :partial => "atcs_sin_settings", :locals => {:sin => final_sin, :pending => final_pending}  
      end      
    else
      #render :text => @set_atcs_sin_rq.request_state
      render :json => { :request_id => @set_atcs_sin_rq.request_id, :request_state => @set_atcs_sin_rq.request_state, :result => @set_atcs_sin_rq.result}
    end
  end
   
 ###################################################################
 # Function:      check_pending
 # Parameters:    None
 # Return:        None
 # Renders:       none
 # Description:   This function is used to check pending sin
 ###################################################################
  def check_pending
    set_atcs_sin_rq = AtcsSin.find_by_request_id(params[:id])
    render :json => { :request_id => set_atcs_sin_rq.id, :request_state => set_atcs_sin_rq.request_state }
  end
   
 ###################################################################
 # Function:      check_state
 # Parameters:    None
 # Return:        None
 # Renders:       none
 # Description:   This function is used to check the request state for 2 and render a page.
 ###################################################################
  def sin_pending
    set_atcs_sin_rq = AtcsSin.find_by_request_id(params[:id])
    set_atcs_sin_rq.update_attributes(:request_state => 0, :command => 1, :sub_command => 0, :iviu_command => 0)
    udp_send_cmd(101, set_atcs_sin_rq.id)
    render :json => { :request_id => set_atcs_sin_rq.id }
  end
   
 ###################################################################
 # Function:      get_sin
 # Parameters:    None
 # Return:        None
 # Renders:       none
 # Description:   This function is used to get the sin address by putting an request.
 ###################################################################
  #Method to get the available sin settings from the GEO.
  def get_sin
    # make entry into the request/reply database
    gwe_info = Gwe.find(:first, :select => "sin")
    if gwe_info      
      @sin_value = gwe_info[:sin].to_s
    else
      @sin_value = ""
    end
    
    set_atcs_sin_rq = AtcsSin.new
    set_atcs_sin_rq.request_state = 0
    set_atcs_sin_rq.atcs_address = @sin_value + ".02"
    set_atcs_sin_rq.command = 0
    set_atcs_sin_rq.sub_command = 0
    set_atcs_sin_rq.iviu_command = 0
    set_atcs_sin_rq.save
    udp_send_cmd(101, set_atcs_sin_rq.id)
    render :json => { :request_id => set_atcs_sin_rq.id, :atcs_address => @sin_value }
  end
   
 ###################################################################
 # Function:      sin_update
 # Parameters:    None
 # Return:        None
 # Renders:       none
 # Description:   This function is used to update the sin
 ###################################################################
  def sin_update
    @set_atcs_sin_rq = AtcsSin.find_by_request_id(params[:request_id])
    @set_atcs_sin_rq.update_attributes(:request_state => 0, :command => 2, :sub_command => 6, :iviu_command => 0, :data_kind => 0, :card_number =>0)
    @set_atcs_sin_rq.save
    
    @get_sin_value = AtcsSinValue.find_by_request_id(@set_atcs_sin_rq.id)
    sin1 = @get_sin_value.sin
    final_sin = params[:sin].gsub('.', '')
    @get_pending_value = AtcsSinValue.find(:last, :conditions => ['id != ? and request_id = ?', @get_sin_value.id, @set_atcs_sin_rq.request_id])
    final_pending = @get_pending_value.sin unless @get_pending_value.blank?   
    @get_sin_value.update_attribute("sin", final_sin)
    @geo_non_am = geo_non_am(final_sin)
    AtcsSinValue.delete_all(['id != ? and request_id = ?', @get_sin_value.id, @set_atcs_sin_rq.request_id])
    udp_send_cmd(101, @set_atcs_sin_rq.id)
    render :partial => "atcs_sin_settings", :locals => {:sin => final_sin, :pending => final_pending}
  end
   
 ###################################################################
 # Function:      set_user_presence_atcs_sin
 # Parameters:    None
 # Return:        None
 # Renders:       none
 # Description:   This function is used to set the user presence
 ###################################################################
  def set_user_presence_atcs_sin
    if(is_user_presence(params[:atcs_address]))
      render :json => { :user_presence => 1, :error => false }
    else
      if(params[:atcs_address])
        geo = (PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI)? false:true
        request_id = set_user_presence(params[:atcs_address], geo)
        render :json => { :request_id => request_id, :user_presence => 0, :error => false }  
      else
        render :json => { :request_id => request_id, :user_presence => 0, :error => true }
      end
    end
  end
   
 ###################################################################
 # Function:      check_user_presence_req_state
 # Parameters:    None
 # Return:        None
 # Renders:       none
 # Description:   This function is used to check the request state for 2 and render a page.
 ###################################################################
  def check_user_presence_req_state
    simple_request = RrSimpleRequest.find_by_request_id(params[:request_id], :select => "request_id, request_state, result")
    if params[:atcs_address] && simple_request && simple_request.request_state == 2 
      if(is_user_presence(params[:atcs_address]))
        render :json => { :request_state => simple_request.request_state, :user_presence => 1, :error => false }
      else
        render :json => { :request_state => simple_request.request_state, :user_presence => 0 }
      end
    else
      render :json => { :request_state => simple_request.request_state, :user_presence => 0 }
    end
  end
  
end