# ******************************************************************************
# 
# @file    : io_status_view_controller.rb
# 
# @author  : NNSV
# 
# @brief   : 
# 
# Copyright 2013-2014 ...
# ******************************************************************************
class IoStatusViewController < ApplicationController
  layout "general"
  include UdpCmdHelper
  include SessionHelper
  include IoStatusViewHelper
  
  before_filter :cpu_status_redirect  #session_helper

  def index
    @atcs_address = atcs_address
    session[:timestamp] = nil
  end

# ****************************************************************************
# Function Name   : fetch_view
# Description     : This function is used to display the Module IO View page
# Pre-Conditions  : None.
# Parameters      :
#     Local       : view_type, cards, channels, time_stamp_hash, io_status_request
#     Instance    : @gwe, @unconfig_page, @diagnostic_messages
#     Global      :
# Returns         : None
# References      : None
# ****************************************************************************
  def fetch_view    
    session[:timestamp] = nil
    view_type = 0
    io_view = nil
    cards = nil
    card_indices = []
    io_status_request = 0
    scale_factor = ""
    @gwe = Gwe.get_mcfcrc(params[:atcs_address])
    @unconfig_page = false
    view_type = get_view_type
    @scaled_parameters = {}
    if(view_type == 1)
      if(params[:get_scale_value] == "true")
        scale_factor = scale_factor_values(["VLPProc.BatteryVoltage","VLPProc.InternalVoltage","TRK_ANLG_1.VCOCurrent","TRK_ANLG_1.VCOVoltage","LIN_ANLG1.VCOCurrent","LIN_ANLG1.VCOVoltage","MTX_ANLG.VCOCurrent","MTX_ANLG.VCOVoltage", "LIN_ANLG1.VTICurrent", "TRK_ANLG_1.VTICurrent", "VLPProc.BatteryVoltage", "MTX_ANLG.VTICurrent"])
      else
        scale_factor = params[:scale_factor_values]
      end
      scale_factor.split("&&").each do |v|
        scale_params = v.split("==")
        @scaled_parameters[scale_params[0]] = scale_params[1]
      end
    end
    io_view = IoView.find_view(params[:atcs_address], @gwe.mcfcrc, view_type)
    if io_view && io_view.status == 1      
      cards = IoViewCard.fetch_cards(params[:atcs_address], @gwe.mcfcrc, view_type)   
      time_stamp_hash = {}
      # Initializing timestamp session
      if !cards.blank?
        cards.select{|card| time_stamp_hash["card_#{card.card_index}"] = card.update_timestamp }
        card_indices = cards.map(&:card_index)
      end
      session[:timestamp] = time_stamp_hash      
      @diagnostic_messages = RtParameter.all(:conditions => {:card_index => card_indices, :mcfcrc => Gwe.mcfcrc, :parameter_type => 6, :current_value => 1}, :select => "parameter_name, card_index")      
      channels = []
      channels = IoViewChannel.fetch_channels(card_indices, params[:atcs_address], @gwe, view_type) if params[:view_type] == "io"
      render_view(params[:view_type], cards, channels, scale_factor)
    elsif io_view && io_view.status == 0
      render :json => {:vlp_unconfigured => false, :view_exists => false, :poll => true, :mcfcrc => @gwe.mcfcrc}
    elsif io_view && io_view.status == -1
      render :json => {:vlp_unconfigured => false, :view => "<span style='color:#FFF;'>No Records available!!</span>", :view_exists => false, :poll => false, :record_exists => false, :geo_exists => true}
    else
      io_status_request = initiate_io_status_request
      render :json => {:vlp_unconfigured => false, :request_id => io_status_request, :mcfcrc => @gwe.mcfcrc, :view_exists => false, :poll => false, :geo_exists => true}
    end
  end
  
  def fetch_version
    @atcs_address = atcs_address
    @gwe = Gwe.get_mcfcrc(@atcs_address)
    @active_cards = {}
    if(@gwe)
      view_type = get_view_type
      io_view_cards = IoViewCard.fetch_cards(@atcs_address, @gwe.mcfcrc, view_type)
      
      io_view_cards.each do |iocard|
#        if iocard.card_status & (0X02) == 0
          if(iocard.slave_kind != 9)
            if iocard.slot_no == 1 && iocard.slave_kind == 7
              @active_cards[0] = iocard.slot_name + " VLP"
            end
            @active_cards[iocard.slot_no] = iocard.slot_name
          end
#        else
#          if iocard.slot_no == 1
#            @active_cards[1] = iocard.slot_name
#          end
#        end
      end
    end
  end
  
# ****************************************************************************
# Function Name   : initiate_io_status_request
# Description     : Initiating IO Status request if nothing exists in rt_views table
# Pre-Conditions  : None.
# Parameters      :
#     Local       : io_status_request
#     Instance    : 
#     Global      :
# Returns         : None
# References      : None
# ****************************************************************************
  def initiate_io_status_request
    if params[:card_ind]
      card_ind = params[:card_ind]
    else
      card_ind = (params[:view_type] == "atcs" ? -3 : -2)
    end
    io_status_request = RrGeoOnline.new
    io_status_request.request_state = 0
    io_status_request.atcs_address = params[:atcs_address] + ".01"
    io_status_request.mcf_type = params[:mcf_type] || 0
    io_status_request.information_type = params[:information_type] || 3
    io_status_request.card_index = card_ind
    io_status_request.save
    udp_send_cmd(REQUEST_COMMAND_GET_MODULES, io_status_request.request_id)
    return io_status_request.request_id
  end

def initiate_io_card_req
  if(params[:force_update_request])
    begin
      reqid = initiate_io_status_request
      render :json  => { :error => false, :request_id => reqid}
    rescue
      render :json  => { :error => true}
    end
  else
    reqid = initiate_io_status_request
    render :text => reqid
  end
end

# ****************************************************************************
# Function Name   : check_view_status
# Description     : Checking the status from rt_view table
# Pre-Conditions  : None
# Parameters      :
#     Local       : io_view
#     Instance    : 
#     Global      :
# Returns         : None
# References      : None
# ****************************************************************************
  def check_view_status
    io_view = IoView.find_view(params[:atcs_address], params[:mcfcrc], get_view_type)
    if(io_view)
      render :text => io_view.status and return
    else
      render :text => -1 and return
    end
  end

# ****************************************************************************
# Function Name   : render_view
# Description     : Redering JSON view based on the view type (either ATCS or IO Module)
# Pre-Conditions  : None
# Parameters      :
#     Local       : view_partial, num_slots, number_of_slots
#     Instance    : @geo_type
#     Global      :
# Returns         : None
# References      : None
# ****************************************************************************  
  def render_view(view_type, cards, channel_set, scale_factor)
    RtCardInformation.refresh_app_card_index
    if params[:view_type] == "atcs"
      if !(cards.blank?)
        cards_temp = []
        cards.each do |card|
          rt_card_info = Rtcardinformation.first(:select =>'card_used', :conditions=>['card_type = ? AND card_index = ?', card.card_type, card.card_index], :order => 'consist_id desc')
          if rt_card_info && rt_card_info.card_used == 0
            cards_temp << card
          end
        end
        cards = cards_temp
      end
      view_partial = render_to_string(:partial => "atcs_comm_view", :locals => {:cards => cards, :atcs_address => params[:atcs_address], 
                      :view_type => params[:view_type]})
    else
      begin
        @geo_type = ((@gwe.active_physical_layout == 0) && (@gwe.active_logical_layout == 0) && (@gwe.active_mtf_index == 0)) ? "Non-AM" : "AM"
        num_slots = RtConsist.consist_id(params[:atcs_address], @gwe.mcfcrc).try(:num_slots)
        
        number_of_slots = Layout.number_of_slots(@gwe, num_slots, @geo_type)
      
        view_partial = render_to_string(:partial => "io_view", :locals => {:cards => cards, :channel_set => channel_set, :number_of_slots => number_of_slots,
                :atcs_address => params[:atcs_address], :view_type => params[:view_type]})
      rescue Exception => e
        view_partial = ""
      end
    end
    render :json => {:vlp_unconfigured => false, :view => view_partial, :view_exists => true, :poll => false, :mcfcrc => @gwe.mcfcrc, :scale_factor => scale_factor}
  end
  
  def get_view_type
    params[:view_type].eql?("atcs") ? 2 : 1
  end
  
  #Method to check the request status.
  def check_state    
    online = RrGeoOnline.find_by_request_id(params[:id])
    delete_request(params[:id], REQUEST_COMMAND_GET_MODULES) if(online && online.request_state == 2)
    if(params[:force_update_request])
      if(online.nil?)
        render :json  => { :error => true }
      else
        render :json  => { :error => false, :request_state => online.request_state }
      end
    else
      render :text => (!online.nil?)? online.request_state : -1
    end
  end
 
# ****************************************************************************
# Function Name   : fetch_module_information
# Description     : This function display detailed module inforamtion
# Pre-Conditions  : None
# Parameters      :
#     Local       : 
#     Instance    : @online, @card_type, @mcf_params, @io_status_reply, @io_status_values
#     Global      :
# Returns         : None
# References      : None
# ****************************************************************************  
  def fetch_module_information
    slot_number = 0
    @module_card_name = params[:card_name]
    if (@module_card_name.downcase == "vlp")
      slot_number = 0
    else
      slot_number = params[:slot_number]
    end
    @sw_version = fetch_sw_version(slot_number)
  end
 
 
# ****************************************************************************
# Function Name   : module_reset
# Description     : This function will reboot the module
# Pre-Conditions  : None
# Parameters      :
#     Local       : 
#     Instance    : 
#     Global      :
# Returns         : None
# References      : None
# ****************************************************************************  
  def module_reset
    reboot_request = RebootRequest.new
    reboot_request.request_state = 0
    reboot_request.atcs_address = params[:atcs_addr] + ".02"
    reboot_request.slot_number = params[:slot_number].to_i
    reboot_request.save!
    udp_send_cmd(REQUEST_COMMAND_RESET, reboot_request.request_id)
    render :text => "Module rebooted"
  end
  
  def module_refresh
    @atcs_address = atcs_address
  end
  
end
