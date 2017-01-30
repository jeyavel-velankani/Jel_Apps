#*********************************************************************************
#File name    : diagnostic_termianl_controller.rb

#Author       : Kalyan

#Description  : This controller is used to get the available IO Modules

#Project Name : iVIU - WebUI Project

#Copyright    : Safetran Systems Corporation, U.S.A. 
#                   Research and Development

#*********************************************************************************

class DiagnosticTerminalController < ApplicationController
  
  layout false, :except => ['show']
  include UdpCmdHelper
  
  def index
    @atcs_addresses = RtSession.find_atcs_addrs
  end
  
  def check_non_am
    gwe = Gwe.find(:last, :conditions => ["sin = ?", params[:atcs_add]], :select => "mcfcrc")
    menus = Menu.find_by_sql "select * from menus where mcfcrc = #{gwe.mcfcrc}"
    render :text => menus.blank? ? "1" : "0"
  end
  
  def io_nav_tab; end
  
  def get_online
    # make entry into the request/reply database
    online = RrGeoOnline.new
    online.request_state = 0
    online.atcs_address = params[:atcs_addr] + ".01"
    online.mcf_type = params[:mcf_type] || 0
    online.information_type = params[:information_type].blank? ? 3 : params[:information_type]
    online.card_index = params[:type].to_i
    online.save
    @request_id = online.id
    udp_send_cmd(105, @request_id)
    render :text => @request_id and return    
  end
  
  def fetch_module_information
    @online = RrGeoOnline.find_by_request_id(params[:id])
    @card_type = params[:card_type]
    if @online.request_state == 2
      @mcf_params = Parameter.all(:conditions => {:cardindex => @online.card_index, :parameter_type => 5}, :select => "name").map(&:name).uniq
      @io_status_reply = Iostatusreply.find_by_request_id(@online.request_id)
      @io_status_values = @io_status_reply.iostatusvalues unless @io_status_reply.blank?
      render :partial => "module_information"
    else
      render :text => @online.request_state
    end
  end
  
  def get_operating_parameters
    @online = RrGeoOnline.find_by_request_id(params[:id])
    @card_type = params[:card_type]
    if @online && @online.request_state == 2
      @mcf_params = Parameter.all(:conditions => {:cardindex => @online.card_index, :parameter_type => 2, :mcfcrc => params[:mcfcrc]})
      render :partial => "operating_parameters"
    else
      render :text => @online.request_state
    end
  end
  
  # Updating operational parameters
  def update_operating_parameters
    atcs = params[:atcs][:addr].split('.01')
    
    nvitaltimer = Nonvitaltimer.new
    nvitaltimer.request_state = 0
    nvitaltimer.command = 2
    nvitaltimer.sub_command = 6
    
    nvitaltimer.atcs_address = atcs[0] + ".02"
    nvitaltimer.data_kind = 2
    nvitaltimer.card_number = params[:card][:index]
    nvitaltimer.request_type = 3
    nvitaltimer.save    
    insert_nvital_cfg_values(params, nvitaltimer)
    udp_send_cmd(100, nvitaltimer.request_id)
    render :text => nvitaltimer.request_id
  end
  
  
  def module_reset
    reboot_request = RebootRequest.new
    reboot_request.request_state = 0
    reboot_request.atcs_address = params[:atcs_addr] + ".01"
    reboot_request.slot_number = params[:slot_number].to_i
    reboot_request.save!
    udp_send_cmd(REQUEST_COMMAND_RESET, reboot_request.request_id)
    render :text => "Module rebooted"
  end
  
  def configuration_parameters
    card_type = params[:card_type]
    render :text => "<div style='padding:15px;color:#FFF;'>Configuration Parameters not found!!</div>"
  end
  
  def check_vlp_state
    @online = RrGeoOnline.find_by_request_id(params[:id])
    if @online.request_state == 2
      @slot_parameters = ['Battery', 'Internal', 'Temperature']
      card_health = params[:slot_health].blank? ? nil : params[:slot_health]
      slot_cp_health = params[:slot_cp_health].blank? ? nil : params[:slot_cp_health]
      @mcfcrc = params[:mcfcrc]
      @card_type = params[:card_type]
      @slot_atcs_devnumber = params[:slot_atcs_devnumber]
      # @rt_parameters = RtParameter.find(:all, :conditions => ["sin = ? and mcfcrc = ? and card_index = ?", params[:atcs_addr], params[:mcfcrc], @online.card_index], :limit => 3)
      slot_content = render_to_string(:partial => params[:tab_name], :locals => {:atcs_addr => params[:atcs_addr], :slot_name => params[:slot_name], :card_health => card_health, :cp_slot_health => slot_cp_health})
      render :json => {:request_state => 2, :slot_content => slot_content}
    else
      render :json => {:request_state => @online.request_state}
    end
  end
  
  
  #Method to check the request status.
  def check_state    
    online = RrGeoOnline.find_by_request_id(params[:id])
    render :text => online.request_state
  end
  
  def check_sec_state
    @online = RrGeoOnline.find_by_request_id(params[:id])
    if @online.request_state == 2
      atcs_addr = params[:atcs_addr]
      gwe = Gwe.find(:last, :conditions => ["sin = ?", params[:atcs_addr]], :select => "mcfcrc")
      @mcfcrc = gwe.mcfcrc      
      name_type = is_am?(@mcfcrc) ? 3 : 0
      
      if params[:tab_name] == "rio"
        @channel_titles =  RtChannelName.find(:all, :select => "distinct channel_index, channel_type, channel_name, channel_name2", :conditions => {:card_index => @online.card_index, :sin => atcs_addr}, :order => "rowid")        
      else      
        @channel_titles =  RtChannelName.find(:all, :conditions => {:card_index => @online.card_index, :sin => atcs_addr, :name_type => name_type})
        @channel_titles = Cardview.find(:all, :conditions => {:mcfcrc => params[:mcfcrc], :cdf => params[:slot_cdf].try(:upcase)}) if @channel_titles.blank?
      end
      card_health = params[:slot_health].blank? ? nil : params[:slot_health]
      @parameter_type = params[:slot_param_type]
      @slot_atcs_devnumber = params[:slot_atcs_devnumber]
      @card_type = params[:card_type]
      
      slot_content = render_to_string(:partial => params[:tab_name], :locals => {:atcs_addr => atcs_addr, :slot_name => params[:slot_name], :card_health => card_health, :mcfcrc => @mcfcrc})
      render :json => {:request_state => 2, :slot_content => slot_content}
    else
      render :json => {:request_state => @online.request_state}
    end
  end
  
  def io_nav_tab   
    @card_names = {}
    
    object_replies = ObjSatReply.all(:conditions => {:request_id => params[:id]})
    object_replies.each {|reply| @card_names.merge!(reply.def_obj_name => reply.obj_name)}
    gwe = Gwe.find(:last, :conditions => ["sin = ?", params[:atcs_add]], :select => "mcfcrc")    
    rt_consist = RtConsist.find(:last, :select => "consist_id, mcfcrc", :conditions => ["sin = ? AND mcfcrc = ?", params[:atcs_add], gwe.mcfcrc])
    card_information = RtCardInformation.find(:all, :select => "card_index, card_type, slot_atcs_devnumber", :conditions => ["consist_id = ? and card_type in (?) and (slave_kind = 0 or slave_kind = 7)", rt_consist.consist_id, (1..10).to_a])
    cp_card_info = card_information.select {|card_info| card_info.card_type == 10}.first
    cp_card = get_cp_card_info(cp_card_info, gwe)
    
    render :update do |page|
      if params[:atcs_add].blank?
        page.replace_html  'testnav', :partial => "iomodule_nav_default"
      else
        page.replace_html  'testnav', :partial => params[:type], :locals => {:mcfcrc => gwe.mcfcrc, :cp_card_info => cp_card_info, :cp_card => cp_card, :card_information => card_information.sort!{|a, b| a.slot_atcs_devnumber <=> b.slot_atcs_devnumber}, :gwe => gwe, :sin_addr => params[:atcs_add], :selected_tab => params[:selected_tab]}
      end
    end
  end
  
  private
  
  def get_cp_card_info(cp_card_info, gwe)
    slot_card = Card.find_by_crd_type_and_mcfcrc(cp_card_info.card_type, gwe.mcfcrc, :select => "crd_name, card_index, cdf, parameter_type") if cp_card_info
    if slot_card
      
    end
  end
  
  def insert_nvital_cfg_values(params, nvitaltimer)
    unless params[:card][:type].blank?
      if params[:card][:type] == "Colorlight" 
        lamp_voltage_msb = params[:parameter]['lamp_voltage'].to_i >> 8
        lamp_voltage_lsb = params[:parameter]['lamp_voltage'].to_i & 0XFF
        Nvconfigprop.create({:request_id => nvitaltimer.request_id, :value => lamp_voltage_msb})
        Nvconfigprop.create({:request_id => nvitaltimer.request_id, :value => lamp_voltage_lsb})
        
        create_nvitaltimer(nvitaltimer.request_id, (params[:parameter]['lamp_filament'].to_i / 10))
        
        cold_filament_test = params[:parameter]['cold_filament'].to_i == 0 ? 0XFF : 0 
        create_nvitaltimer(nvitaltimer.request_id, cold_filament_test)        
        create_nvitaltimer(nvitaltimer.request_id, (params[:parameter]['vpi_bounce'].to_i / 2))
        
      elsif params[:card][:type] == "SearchLight"  
        lamp_voltage_msb = params[:parameter]['lamp_voltage'].to_i >> 8
        lamp_voltage_lsb = params[:parameter]['lamp_voltage'].to_i & 0XFF
        Nvconfigprop.create({:request_id => nvitaltimer.request_id, :value => lamp_voltage_msb})
        Nvconfigprop.create({:request_id => nvitaltimer.request_id, :value => lamp_voltage_lsb})
        
        # VPI Debounce - Search light
        create_nvitaltimer(nvitaltimer.request_id, (params[:parameter]['vpi_bounce'].to_i / 2))
        
        # PCO Options starts here
        create_nvitaltimer(nvitaltimer.request_id, (params[:parameter][:pco_1_debounce].to_i / 2))
        create_nvitaltimer(nvitaltimer.request_id, (params[:parameter][:pco_1_correspondance].to_i / 5))
        create_nvitaltimer(nvitaltimer.request_id, (params[:parameter][:pco_2_debounce].to_i / 2))
        create_nvitaltimer(nvitaltimer.request_id, (params[:parameter][:pco_2_correspondance].to_i / 5))
        pco_options = params[:parameter][:pco_options].to_i == 0 ? 0XFF : 0
        create_nvitaltimer(nvitaltimer.request_id, pco_options)
        
      elsif params[:card][:type] == "CodedTrack" 
        vco_voltage = params[:parameter]['0'].to_i / 20
        create_nvitaltimer(nvitaltimer.request_id, vco_voltage)
        
        transmit = params[:parameter][:transmit].to_i
        code5 = params[:parameter][:code5].to_i
        receive = params[:parameter][:receive].to_i
        ec4 = params[:parameter][:ec4_compatibility].to_i
        track_parameters = nil
        byte = 0X00
        # Manipulating enum types (Receive, Transmit, Code5 & EC4) for track parameters
        track_parameters = (receive | byte) << 1
        track_parameters = (track_parameters | transmit) << 2
        track_parameters = (track_parameters | code5) << 5
        track_parameters = (track_parameters | ec4) << 7
        create_nvitaltimer(nvitaltimer.request_id, track_parameters)
        
        # creating nvital timer for change cycles
        change_cycle_bit_operation(nvitaltimer, params[:parameter]['non_vital_code_change_cycle'].to_i, params[:parameter]['vital_code_change_cycle'].to_i)
        # creating nvital timer for shunt cycles
        change_cycle_bit_operation(nvitaltimer, params[:parameter]['shunt_drop_cycles'].to_i, params[:parameter]['shunt_pick_cycles'].to_i)
        
        # calculating current limit
        current_limit = params[:parameter]['current_limit'].to_i/ 50
        create_nvitaltimer(nvitaltimer.request_id, current_limit)
      elsif params[:card][:type] == "Rio"
        rio_vpi_bounce = params[:parameter]['vpi_bounce'].to_i/2
        create_nvitaltimer(nvitaltimer.request_id, rio_vpi_bounce)
      end
    end
  end
  
  def change_cycle_bit_operation(nvitaltimer, nvital_cycle, vital_cycle)
    byte = 0X00
    nvital_result = (nvital_cycle | byte) << 4
    final_result = nvital_result | vital_cycle
    create_nvitaltimer(nvitaltimer.request_id, final_result)        
  end
  
  def create_nvitaltimer(request_id, value)
    Nvconfigprop.create({:request_id => request_id, :value => value})
  end
  
  def is_am?(mcfcrc)
    if Menu.count(:conditions => {:mcfcrc => mcfcrc}) == 0 || GeoParameter.count(:conditions => {:mcfcrc => mcfcrc}) == 0 
      true
    else
      false
    end    
  end
  
end