module IoStatusViewHelper
  
  # Fetching MCF parameters based on mcfcrc & card index
  def mcf_parameters(mcfcrc, card_index)
    Parameter.find(:all,
         :conditions => ["mcfcrc = ? and cardindex = ? and (parameter_type = 3 or 4)", mcfcrc, card_index],
         :select => "name, default_value, mcfcrc, parameter_type, parameter_index, cardindex")
  end
  
  # Finding a data structure which contains info about rt parameter value for a give card index
  def fetch_channel_parameters(atcs_addr,mcfcrc, card_index, card_type, view_type=nil)    
    rt_parameters = RtParameter.get_status_cmd_parameters(atcs_addr, mcfcrc, card_index, card_type)    
    return rt_parameters if view_type == "atcs" # If view type is atcs communication, return rt parameters
    
    parameter_hash = Hash.new
    rt_parameters.each do |parameter|
      parameter_hash["#{parameter.parameter_type}.#{parameter.parameter_name}"] = parameter.current_value
    end
    return parameter_hash
  end
  
  def gcp_and_ipi_used?(card_index, atcs_address)
    parameters = Parameter.all(:conditions => {:cardindex => card_index, :mcfcrc => Gwe.mcfcrc, :name => ["GCPUsed", "IPIUsed"], :parameter_type => 2}, :select => "name, enum_type_name")
    rt_parameters = RtParameter.all(:conditions => {:card_index => card_index, :sin => atcs_address, :parameter_name => ["GCPUsed", "IPIUsed"], :parameter_type => 2, :mcfcrc => Gwe.mcfcrc}, :select => "parameter_name, current_value")
    used_parameters = {}
    unless rt_parameters.blank?
      parameters.each do |parameter| 
        rt_parameter = rt_parameters.find{|rt| rt.parameter_name == parameter.name }
        enumerator = Mcfenumerator.find_by_enum_type_name_and_value(parameter.enum_type_name, rt_parameter.current_value, :select => "long_name")
        used_parameters[parameter.name] = (enumerator && enumerator.long_name.downcase == 'no') ? false : true 
      end
    end
    used_parameters
  end
  
  # parameter type to fetch rt parameters for a given card type
  def parameter_type(card_type)
    case card_type
      when 8 then 4
      when 3 then 3
      when 9 then 3
    else
      nil
    end
  end
  
  # Finding RT parameter current value for a given MCF parameter
  def rt_parameter(parameter)    
    RtParameter.parameter(parameter).try(:current_value) unless parameter.blank?
  end
  
  def named_mcf_parameters(mcfcrc, card_index, name)
    Parameter.find(:all,
         :conditions => ["mcfcrc = ? and cardindex = ? and (parameter_type = 3 or parameter_type = 4) and name like ?", mcfcrc, card_index, "%#{name}%"],
         :select => "name, default_value, mcfcrc, parameter_type, parameter_index, cardindex")
  end
  
  def get_channel_types(card_info, mcfcrc)
    card = Card.find_by_mcfcrc(mcfcrc, 
                :conditions => {:crd_type => card_info.card_type, :layout_index => @gwe.active_physical_layout, :card_index => card_info.card_index}, :select => "distinct cdf, parameter_type")
    
    channels = Cardview.all(:conditions => {:mcfcrc => mcfcrc, :cdf => card.cdf.try(:upcase)}, :select => "channel_index, channel_title", 
      :order => "rowid").map(&:channel_title)
    begin
      if channels.size <= 3
        channel_types = []
        channels.each { |element| channel_types << element.split(".")[1] } 
        channels.delete("ChannelTileServer.VTI.1") if channel_types.include?("VTI") && channel_types.include?("LineAnalog")
      end
    rescue Exception => e
      puts e.message
    end
    return channels
  end
  
  def get_card_name(card, mcfcrc, card_index, card_type)
    if card
      card_name = card.card_name.blank? ? card.default_card_name : card.card_name
      card_name.blank? ? Card.card_name(mcfcrc, card_index, card_type, @gwe.active_physical_layout) : card_name
    else
      card_name = Card.card_name(mcfcrc, card_index, card_type, @gwe.active_physical_layout)
      card_name.blank? ? "< Empty >" : card_name
    end
  end
  
  def get_cp_card_info(mcfcrc, atcs_address)
    active_physical_layout = Gwe.find_by_sin(atcs_address, :conditions => {:mcfcrc => mcfcrc}, :select => "active_physical_layout")
    Card.find_by_mcfcrc(mcfcrc, :conditions => {:layout_index => active_physical_layout, :crd_type => 10}, :select => "card_index")
  end
  
  def fetch_sw_version(slot_number)
    return SoftwareVersions.find(:all, :conditions => ["slot_number = ? ", slot_number], :order => "id")
  end
  
  # Drawing channels based on channel type
  def draw_channel(channel_type, channel_path=nil)
    channel_path = channel_path || "io_status_view"
    
    case
      when channel_type == "ChannelTileServer.Atcs.1" then "/#{channel_path}/channels/atcs_channel"
      when channel_type == "ChannelTileServer.iCode.1" then "/#{channel_path}/channels/mtx_code_channel"
      when channel_type.match("VLPProc") then "/#{channel_path}/channels/vlp_channel"
      when channel_type.match("PSOStatusTXCtrl") then "/#{channel_path}/channels/pso_transmitter_control_channel"
      when channel_type.match("PSOStatusCtrl") then "/#{channel_path}/channels/pso_status_control_channel"
      when channel_type.match("PSOIslandCtrl") then "/#{channel_path}/channels/pso_island_control_channel"
      
      when channel_type.match("Code") then "/#{channel_path}/channels/code_channel"
      when channel_type.match("LineAnalog") then "/#{channel_path}/channels/line_analog"
      when channel_type.match("LED") then "/#{channel_path}/channels/led_channel"
      
      when channel_type.match("VRO") then "/#{channel_path}/channels/vro_channel"
      when channel_type.match("VCO") then "/#{channel_path}/channels/vco_channel"
      when channel_type.match("VTI") then "/#{channel_path}/channels/vti_channel"
      when channel_type.match("Colorlight") then "/#{channel_path}/channels/vlo_channel"
      when channel_type.match("VPI") then "/#{channel_path}/channels/vpi_channel"
      when channel_type.downcase.eql?("ngcpstatusserver.ngcpstatusctrl.ngcpstatusserver.iodatactrl.1") then "/#{channel_path}/channels/ngcp_status_server_control_channel"
      when channel_type.downcase.eql?("ngcpstatusserver.iodatactrl.1") then "/#{channel_path}/channels/io_data_control_channel"
      when channel_type.match("XLO") then "/#{channel_path}/channels/xlo_channel"
      when channel_type.match("RBO") then "/#{channel_path}/channels/rbo_channel"
      when channel_type.match("HPO") then "/#{channel_path}/channels/hpo_channel"
      when channel_type.match("Searchlight") || channel_type.match("PCO")  then "/#{channel_path}/channels/pco_channel"
    else
    "/#{channel_path}/channels/empty"
    end
  end
  
  # Fetching Coded Track parameters
  def get_track_parameters(parameters, param_name, channel_index)
    track1 = track2 = track3 = track4 = ""
    
    parameters.each_pair do |key, value|
      if key.match("#{param_name}#{channel_index}")
        if key == "#{param_name}#{channel_index}.C1" && value == 1
          track1 = "C1"
        end
        if (key == "#{param_name}#{channel_index}.C2" || key == "#{param_name}#{channel_index}.C3" || key == "#{param_name}#{channel_index}.C4" || key == "#{param_name}#{channel_index}.C7" || key == "#{param_name}#{channel_index}.C8" || key == "#{param_name}#{channel_index}.C9") && value == 1
          track2 = key.split(".").last
        end
        if (key == "#{param_name}#{channel_index}.C5" || key == "#{param_name}#{channel_index}.C6" || key == "#{param_name}#{channel_index}.CM") && value == 1
          if track3 == ""
            track3 = key.split(".").last
          else
            track4 = key.split(".").last
          end
        end
      end
    end
    
    {:track1 => track1, :track2 => track2, :track3 => track3, :track4 => track4}    
  end

  def get_mtx_track_parameters(parameters, param_name, channel_index)
    mtx_code = ""
    parameters.sort.map do |key,value|
      if key.match("#{param_name}.Code") && value == 1
        mtx_code = key.split(".").last
        break
      end
    end
    
    {:mtx_code => mtx_code}
  end

  def get_mtx_error_track_parameters(card_index)
    rx_hw_fail = RtParameter.find(:all,:conditions => ['card_index = ? and parameter_name = "MTX.RxFail" and parameter_type = 3',card_index])
    tx_hw_fail = RtParameter.find(:all,:conditions => ['card_index = ? and parameter_name = "MTX.TxFail" and parameter_type = 3',card_index])

    if rx_hw_fail && rx_hw_fail[0] && rx_hw_fail[0]['current_value'] &&  rx_hw_fail[0]['current_value'] == 1
      rx = 'Fail'
    else
      rx = ''
    end

    if tx_hw_fail && tx_hw_fail[0] && tx_hw_fail[0]['current_value'] &&  tx_hw_fail[0]['current_value'] == 1
      tx = 'Fail'
    else
      tx = ''
    end
    
    {:rx => rx, :tx => tx}
  end
  
  def get_track_parameters_hash(parameters, param_name, channel_index)
    track1 = track2 = track3 = track4 = hw_error = "" 
    
    parameters.each_pair do |key, value|
      if key.match("#{param_name}#{channel_index}")
        if key == "#{param_name}#{channel_index}.C1" && value == 1
          track1 = "C1"
        elsif (key == "#{param_name}#{channel_index}.C2" || key == "#{param_name}#{channel_index}.C3" || key == "#{param_name}#{channel_index}.C4" || key == "#{param_name}#{channel_index}.C7" || key == "#{param_name}#{channel_index}.C8" || key == "#{param_name}#{channel_index}.C9") && value == 1
          track2 = key.split(".").last
        elsif (key == "#{param_name}#{channel_index}.C5" || key == "#{param_name}#{channel_index}.C6" || key == "#{param_name}#{channel_index}.CM") && value == 1
          track3 = key.split(".").last
        elsif (key == "#{param_name}#{channel_index}.C5" || key == "#{param_name}#{channel_index}.C6" || key == "#{param_name}#{channel_index}.CM") && value == 1 && !key.match(track3)
          track4 = key.split(".").last 
        elsif (key == "#{param_name}#{channel_index}.TxFail" || key == "#{param_name}#{channel_index}.RxFail")
          hw_error = (value == 1 ? 'true' : 'false')
        end
      end
    end

    track_hash = Hash.new
    
     track_hash['track1'] = track1
     track_hash['track2'] = track2
     track_hash['track3'] = track3
     track_hash['track4'] = track4
     track_hash['hw_error'] = hw_error

     return track_hash
  end
  
  def get_vro_output_mnemonic(parameters, channel_index, channel_name)
    color_codes = {}
    #color_codes = find_vro_cmd_status_parameters(color_codes, parameters, channel_index, channel_name, 4)
    color_codes = find_vro_cmd_status_parameters(color_codes, parameters, channel_index, channel_name, 3)
    color_codes
  end
  
  # Fetch XLO channel parameters for GCP
  def get_xlo_parameters(parameters, channel_index, channel_name, param_type=3)
    xlo_codes = {}
    
    if parameters["#{param_type}.#{channel_name}#{channel_index}.HWFAIL"] == 0
      xlo_codes["status"] = 'HWFail'
      xlo_codes["lamp_image"] = image_tag("dt/black_circle.png")
    elsif parameters["#{param_type}.#{channel_name}#{channel_index}.FLASH"] == 1
      xlo_codes["status"] = 'Flash'
      xlo_codes["lamp_image"] = image_tag("dt/flashing.gif")
    elsif parameters["#{param_type}.#{channel_name}#{channel_index}.ON"] == 1
      xlo_codes["status"] = 'On'
      xlo_codes["lamp_image"] = image_tag("dt/plaingreencircle.png")
    else
      xlo_codes["status"] = 'Off'
      xlo_codes["lamp_image"] = image_tag("dt/black_circle.png")
    end
    
    xlo_codes
  end
  
  def get_rbo_parameters(parameters, channel_index, channel_name, param_type=3)
    params = {}    
    if parameters["#{param_type}.#{channel_name}#{channel_index}.HWFAIL"] == 0
      params["status"] = "HWFail"
      params["image"] = image_tag("dt/hwfail_bell.png")
    elsif (parameters["#{param_type}.#{channel_name}#{channel_index}.HWFAIL"] == 1 && 
      parameters["#{param_type}.#{channel_name}#{channel_index}.ON"] == 1)
      params["status"] = "Ring"    
      params["image"] = image_tag("dt/bell_ring.gif")
    else
      params["status"] = "Off"
      params["image"] = image_tag("dt/bell.png")
    end
    
    params
  end
  
  def get_hpo_parameters(parameters, channel_index, channel_name, param_type=3)
    local_params = {}
    
    if parameters["#{param_type}.#{channel_name}#{channel_index}.HWFAIL"] == 0
      local_params["status"] = "HWFail"
      local_params["image"] = image_tag("dt/crossing_error.png")
    elsif parameters["#{param_type}.#{channel_name}#{channel_index}.ON"] == 1
      local_params["status"] = "Up"
      local_params["image"] = image_tag("dt/crossing_up.png")
    else
      local_params["status"] = "Down"
      local_params["image"] = image_tag("dt/crossing_down.png")
    end 
    
    local_params
  end
  
  # PSO Status channel calculation for status messages
  def psorx_status_modulation_code(parameters, channel_index, param_type, card_index, mcfcrc, atcs_address, short_code  = false)
    local_params = {}
    
    local_params["modulation_code"] = modulation_code(parameters["#{param_type}.PSORX#{channel_index}Status.ModulationCode"], short_code)
    
    local_params["cal_required"] = "Cal Req" if parameters["#{param_type}.PSORX#{channel_index}Status.CalibReq"] == 1
    
    if parameters["#{param_type}.PSORX#{channel_index}Status.CalibReq"] != 1
      pso_occupancy_with_pickup_delay = parameters["#{param_type}.PSORX#{channel_index}Status.PSOOccupancyWithPickupDelay"]
      pso_occupancy = parameters["#{param_type}.PSORX#{channel_index}Status.PSOOccupancy"]
      
      local_params["modulation_code"] = "Flash" if((pso_occupancy_with_pickup_delay == 0 && pso_occupancy == 1) || (pso_occupancy_with_pickup_delay == 1 && pso_occupancy == 0))
      local_params["modulation_code"] = "O" if pso_occupancy_with_pickup_delay == 0 || pso_occupancy == 0
      
      channel_health = RtParameter.find_by_parameter_name("PSORX#{channel_index}Used", 
      :conditions => {:mcfcrc => mcfcrc, :sin => atcs_address, :card_index => card_index}, :select => "current_value").try(:current_value)
    end
    
    local_params["health"] = if parameters["#{param_type}.PSORX#{channel_index}Status.Used"] == 0
      local_params["modulation_code"] = "Not Used"
      "gray"
    elsif parameters["#{param_type}.PSORX#{channel_index}Status.PSORXHealth"] == 1
      "#809818"  # color code for green shade
    else  
      "#B7280A" # color code for red shade
    end
    
    local_params
  end
  
  def modulation_code(current_value, short_code = false)
    return case current_value
      when 0 then "No Code"
      when 1 then short_code ? "A" : "Code A"
      when 2 then short_code ? "C" : "Code C"
      when 4 then short_code ? "D" : "Code D"
      when 8 then short_code ? "E" : "Code E"
      when 16 then short_code ? "F" : "Code F"
    end
  end
  def pso_transmission_modulation_code(parameters, param_type, short_code=false)
    local_params = {}
    
    local_params["modulation_code"] = modulation_code(parameters["#{param_type}.PSOTXStatus.ModulationCode"], short_code)
    
    local_params['health'] = if parameters["#{param_type}.PSOTXStatus.Used"] == 0
      local_params['modulation_code'] = 'Not Used'
      "gray"
    elsif local_params["#{param_type}.PSOTXStatus.PSOTXHealth"] == 1
      "#809818"
    elsif local_params["#{param_type}.PSOTXStatus.PSOTXHealth"] == 0
      "#B7280A" # color code for red shade
    else
      "gray"
    end
    
    local_params
  end
  
  def pso_island_control(parameters, channel_index, param_type, card_index, mcfcrc, atcs_address)
    local_params = Hash.new
    
    isl_occupied_with_pickup = parameters["#{param_type}.IPIStatus.IPIOccupiedWithPickup"]
    isl_occupied = parameters["#{param_type}.IPIStatus.IPIOccupied"]
    
    local_params['modulation_code'] = 'O' if isl_occupied == 1 
    local_params['modulation_code'] = 'Flash' if isl_occupied == 1 && isl_occupied_with_pickup == 0
    
    island_status = RtParameter.find_by_parameter_name("IPIStatus.Used", 
      :conditions => {:mcfcrc => mcfcrc, :sin => atcs_address, :card_index => card_index}, :select => "current_value").try(:current_value)
    
    local_params['health'] = if island_status && island_status == 0
      local_params['modulation_code'] = 'Not Used'
      "gray"
    elsif parameters["#{param_type}.IPIStatus.IPIHealth"] == 1
      "#809818"  # color code for green shade
    else
      "#B7280A"  # color code for red shade
    end
    local_params["cal_required"] = "Cal Req" if parameters["#{param_type}.IPIStatus.CalibReq"] == 1
    local_params
  end
  
  def find_vro_cmd_status_parameters(color_codes, parameters, channel_index, channel_name, param_type)
    case 1
      when parameters["#{param_type}.#{channel_name}#{channel_index}.HWFAIL"]
      color_codes["status"] = 'HWFail'
      color_codes["lamp_image"] = image_tag("dt/red_arrow.png")
      when parameters["#{param_type}.#{channel_name}#{channel_index}.FLASH"]
      color_codes["status"] = 'Flash'
      color_codes["lamp_image"] = image_tag("dt/green_arrow.png")
      when parameters["#{param_type}.#{channel_name}#{channel_index}.GPO_ON"]
      color_codes["status"] = 'On'
      color_codes["lamp_image"] = image_tag("dt/green_arrow.png")
      when parameters["#{param_type}.#{channel_name}#{channel_index}.ON"]
      color_codes["status"] = 'On'
      color_codes["lamp_image"] = image_tag("dt/green_arrow.png")
      when parameters["#{param_type}.#{channel_name}#{channel_index}.CAB1"]
      color_codes["status"] = '75'
      color_codes["lamp_image"] = image_tag("dt/green_arrow.png")
      when parameters["#{param_type}.#{channel_name}#{channel_index}.CAB2"]
      color_codes["status"] = '120'
      color_codes["lamp_image"] = image_tag("dt/green_arrow.png")
      when parameters["#{param_type}.#{channel_name}#{channel_index}.CAB3"]
      color_codes["status"] = '180'
      color_codes["lamp_image"] = image_tag("dt/green_arrow.png")
      when parameters["#{param_type}.#{channel_name}#{channel_index}.CAB4"]
      color_codes["status"] = '270'
      color_codes["lamp_image"] = image_tag("dt/green_arrow.png")
      when parameters["#{param_type}.#{channel_name}#{channel_index}.CAB5"]
      color_codes["status"] = '420'
      color_codes["lamp_image"] = image_tag("dt/green_arrow.png")
    else
      color_codes["status"] = "Off"
      color_codes["lamp_image"] = image_tag("dt/black_arrow.png")
    end  
    return color_codes
  end

  def get_vro_cmd_status_params(parameters, channel_index, channel_name, param_type)
    color_codes = {}
    case 1
      when parameters["#{param_type}.#{channel_name}#{channel_index}.HWFAIL"]
      color_codes["status"] = 'HWFail'
      color_codes["lamp_image"] = "/images/dt/red_arrow.png"
      when parameters["#{param_type}.#{channel_name}#{channel_index}.FLASH"]
      color_codes["status"] = 'Flash'
      color_codes["lamp_image"] = "/images/dt/green_arrow.png"
      when parameters["#{param_type}.#{channel_name}#{channel_index}.GPO_ON"]
      color_codes["status"] = 'On'
      color_codes["lamp_image"] = "/images/dt/green_arrow.png"
      when parameters["#{param_type}.#{channel_name}#{channel_index}.ON"]
      color_codes["status"] = 'On'
      color_codes["lamp_image"] = "/images/dt/green_arrow.png"
      when parameters["#{param_type}.#{channel_name}#{channel_index}.CAB1"]
      color_codes["status"] = '75'
      color_codes["lamp_image"] = "/images/dt/green_arrow.png"
      when parameters["#{param_type}.#{channel_name}#{channel_index}.CAB2"]
      color_codes["status"] = '120'
      color_codes["lamp_image"] = "/images/dt/green_arrow.png"
      when parameters["#{param_type}.#{channel_name}#{channel_index}.CAB3"]
      color_codes["status"] = '180'
      color_codes["lamp_image"] = "/images/dt/green_arrow.png"
      when parameters["#{param_type}.#{channel_name}#{channel_index}.CAB4"]
      color_codes["status"] = '270'
      color_codes["lamp_image"] = "/images/dt/green_arrow.png"
      when parameters["#{param_type}.#{channel_name}#{channel_index}.CAB5"]
      color_codes["status"] = '420'
      color_codes["lamp_image"] = "/images/dt/green_arrow.png"
    else
      color_codes["status"] = "Off"
      color_codes["lamp_image"] = "/images/dt/black_arrow.png"
    end  
    return color_codes
  end
  
  # Fetching parameter name in coded track channel
  def parameter_name(param)
    param.name.split('.').last
  end
  
  def get_cp_card_health(atcs_address, mcfcrc)
    cp_card_info = RtCardInformation.find_by_mcfcrc(mcfcrc, :conditions => {:card_type => 10}, :select => "card_index")
    get_card_health(cp_card_info.card_index, atcs_address, mcfcrc)
  end
  
  # Finding track parameters for VCO and VTI Channel (Eg: C1, C2, C3..)
  def fetch_track_parameter(parameters, names)
    matched_parameter = "" #parameters.select{|param| parameter_name(param) == name }.first
    parameters.each do |parameter|
      names.each do |name|
        matched_parameter = parameter if name == parameter_name(parameter)
      end
    end
    rt_parameter = rt_parameter(matched_parameter)
    parameter_name(matched_parameter) if !rt_parameter.blank? && rt_parameter == 1
  end
  
  # Finding VTI Code present or Vital Code present parameter
  def find_code_present_parameter(vcp_param, cp_param)
    vcp_param.blank? ? (cp_param.blank? ? "NC" : "CP") : "VCP"     
  end
  
  # Finding led parameters for LED channel type
  def led_command_parameters(led_parameters, param_name, channel_index)
    led_codes = {}
    led_parameters(led_codes, 4, led_parameters, param_name, channel_index)
    #   led_parameters(led_codes, 3, led_parameters, param_name, channel_index)
    return led_codes
  end
  
  def led_parameters(led_codes, param_type, led_parameters, param_name, channel_index)
    if led_parameters["#{param_type}.#{param_name}#{channel_index}.LedOn"] == 1
      led_codes["led_status"] = "On" 
      led_codes["led_image"] = image_tag "dt/plaingreencircle.png"
    elsif led_parameters["#{param_type}.#{param_name}#{channel_index}.ON"] == 1 || led_parameters["#{param_type}.#{param_name}#{channel_index}.On"] == 1
      led_codes["led_status"] = "On" 
      led_codes["led_image"] = image_tag "dt/plaingreencircle.png"  
    else
      led_codes["led_status"] = "Off" 
      led_codes["led_image"] = image_tag "dt/lunar_circle.png"
    end 
  end

  def get_led_params(param_type, led_parameters, param_name, channel_index)
    led_codes = {}
    if led_parameters["#{param_type}.#{param_name}#{channel_index}.LedOn"] == 1
      led_codes["led_status"] = "On" 
      led_codes["led_image"] =  "dt/plaingreencircle.png"
    elsif led_parameters["#{param_type}.#{param_name}#{channel_index}.ON"] == 1 || led_parameters["#{param_type}.#{param_name}#{channel_index}.On"] == 1
      led_codes["led_status"] = "On" 
      led_codes["led_image"] =  "dt/plaingreencircle.png"  
    else
      led_codes["led_status"] = "Off" 
      led_codes["led_image"] =  "dt/lunar_circle.png"
    end 
    return led_codes
  end
  
  # Finding channel name for each channel type 
  def channel_name(channel_index, atcs_address, card_index, default_name)
    rt_channel_name = RtChannelName.find_by_sin(atcs_address, 
      :conditions => ["channel_index = ? and card_index = ? and channel_type like ?", channel_index, card_index, "%#{default_name}%"], 
      :order => "rowid",
      :select => "distinct channel_index, channel_type, channel_name, channel_name2")
    
    channel = rt_channel_name.blank? ? "" : (rt_channel_name.channel_name + rt_channel_name.channel_name2)
    channel_name = channel.blank? ?  default_name : channel
  end
  
  def get_tx_track_fail_parameter(parameters, param_name, channel_index)
    "Fail" if parameters["#{param_name}#{channel_index}.TxFail"] == 1
  end
  
  # Finding card health of each card
  def get_card_health(card_index, atcs_addr, mcfcrc)    
    card_health = Rtcards.find_by_c_index(card_index, :conditions => {:mcfcrc => mcfcrc, :sin => atcs_addr, :parameter_type => 3}, :select => "comm_status").try(:comm_status)
    if card_health.nil?
      #card_health = Rtcards.find_by_c_index(card_index, :conditions => {:mcfcrc => mcfcrc, :sin => atcs_addr, :parameter_type => 2}, :select => "comm_status").try(:comm_status)
    end
    card_health_status = dec2bin(card_health).to_s.split("") unless card_health.blank?
    return card_health_status.blank? ? nil : card_health_status[card_health_status.size - 2]
  end
  
  def dec2bin(number)
    number = Integer(number);
    return 0 if number == 0
    
    ret_bin = ""    
    # until val is zero, convert it into binary format
    while(number > 0)
      ret_bin = String(number % 2) + ret_bin
      number /= 2
    end
    return ret_bin
  end
  
  # Finding status images for color light card  
  def get_colour_code_images(channel_parameters, channel_index, param_name, channel_name = nil, codes = nil, type=nil)
    color_codes = codes || Hash.new

    
=begin
    case 1
      when channel_parameters["4.#{param_name}#{channel_index}.LAMP_LOR"]
      color_codes["lamp_status"] = "LOR"
      color_codes["lamp_image"] = get_color_light_images(channel_index, channel_name, 'LOR') if type.nil?
      when channel_parameters["4.#{param_name}#{channel_index}.LAMP_FLASH"]
      color_codes["lamp_status"] = "Flash"
      color_codes["lamp_image"] = get_color_light_images(channel_index, channel_name, 'flash') if type.nil?
      when channel_parameters["4.#{param_name}#{channel_index}.LAMP_ON"]
      color_codes["lamp_status"] = "On"
      color_codes["lamp_image"] = get_color_light_images(channel_index, channel_name, 'On') if type.nil?
    end
=end
    
    case 1
      when channel_parameters["3.#{param_name}#{channel_index}.LAMP_LOR"]
      color_codes["lamp_status"] = "LOR"
      color_codes["lamp_image"] = get_color_light_images(channel_index, param_name, 'LOR') if type.nil?
      when channel_parameters["3.#{param_name}#{channel_index}.LAMP_FLASH"]
      color_codes["lamp_status"] = "Flash"
      color_codes["lamp_image"] = get_color_light_images(channel_index, param_name, 'flash') if type.nil?
      when channel_parameters["3.#{param_name}#{channel_index}.LAMP_ON"]
      color_codes["lamp_status"] = "On"
      color_codes["lamp_image"] = get_color_light_images(channel_index, param_name, 'On') if type.nil?  
    end
    
    if color_codes.blank?
      color_codes["lamp_status"] = "Off"
      color_codes["lamp_image"] = image_tag("dt/black_circle.png")
    end
    
    if channel_parameters["4.#{param_name}#{channel_index}.ForeignEnergyDetected"] == 1 || channel_parameters["3.#{param_name}#{channel_index}.ForeignEnergyDetected"] == 1
      color_codes["foreign_energy"] = true
    end 
    
    return color_codes
  end

 def get_vlo_colour_code_images(channel_parameters, channel_index, param_name, channel_name)
    color_codes = Hash.new
    
    case 1
      when channel_parameters["3.#{param_name}#{channel_index}.LAMP_LOR"]
      color_codes["lamp_status"] = "LOR"
      color_codes["lamp_image"] = get_color_light_images(channel_index, channel_name, 'LOR') 
      when channel_parameters["3.#{param_name}#{channel_index}.LAMP_FLASH"]
      color_codes["lamp_status"] = "Flash"
      color_codes["lamp_image"] = get_color_light_images(channel_index, channel_name, 'flash') 
      when channel_parameters["3.#{param_name}#{channel_index}.LAMP_ON"]
      color_codes["lamp_status"] = "On"
      color_codes["lamp_image"] = get_color_light_images(channel_index, channel_name, 'On')  
    end
    
    if color_codes.blank?
      color_codes["lamp_status"] = "Off"
      color_codes["lamp_image"] = image_tag("dt/black_circle.png")
    end
    
    if channel_parameters["4.#{param_name}#{channel_index}.ForeignEnergyDetected"] == 1 || channel_parameters["3.#{param_name}#{channel_index}.ForeignEnergyDetected"] == 1
      color_codes["foreign_energy"] = true
    end 
    
    return color_codes
  end


    # Finding status images for color light card  
  def get_colour_code_images_path(channel_parameters, channel_index, param_name, channel_name = nil, codes = nil, type=nil)
    color_codes = codes || Hash.new
       
    case 1
      when channel_parameters["3.#{param_name}#{channel_index}.LAMP_LOR"]
      color_codes["lamp_status"] = "LOR"
      color_codes["lamp_image"] = get_color_light_images_path(channel_index, channel_name, 'LOR') if type.nil?
      when channel_parameters["3.#{param_name}#{channel_index}.LAMP_FLASH"]
      color_codes["lamp_status"] = "Flash"
      color_codes["lamp_image"] = get_color_light_images_path(channel_index, channel_name, 'flash') if type.nil?
      when channel_parameters["3.#{param_name}#{channel_index}.LAMP_ON"]
      color_codes["lamp_status"] = "On"
      color_codes["lamp_image"] = get_color_light_images_path(channel_index, channel_name, 'On') if type.nil?  
    end
    
    if color_codes.blank?
      color_codes["lamp_status"] = "Off"
      color_codes["lamp_image"] = "dt/black_circle.png"
    end
    
    if channel_parameters["4.#{param_name}#{channel_index}.ForeignEnergyDetected"] == 1 || channel_parameters["3.#{param_name}#{channel_index}.ForeignEnergyDetected"] == 1
      color_codes["foreign_energy"] = true
    end 
    
    return color_codes
  end


  def get_colour_code(channel_parameters, channel_index, param_name, channel_name = nil, codes = nil, type=nil)
    color_codes = codes || Hash.new

    case 1
      when channel_parameters["3.#{param_name}#{channel_index}.LAMP_LOR"]
      color_codes["lamp_status"] = "LOR"
      color_codes["lamp_image"] = get_color_light(channel_index, channel_name, 'LOR') if type.nil?
      when channel_parameters["3.#{param_name}#{channel_index}.LAMP_FLASH"]
      color_codes["lamp_status"] = "Flash"
      color_codes["lamp_image"] = get_color_light(channel_index, channel_name, 'flash') if type.nil?
      when channel_parameters["3.#{param_name}#{channel_index}.LAMP_ON"]
      color_codes["lamp_status"] = "On"
      color_codes["lamp_image"] = get_color_light(channel_index, channel_name, 'On') if type.nil?  
    end
    
    if color_codes.blank?
      color_codes["lamp_status"] = "Off"
      color_codes["lamp_image"] = "/images/dt/black_circle.png"
    end
    
    if channel_parameters["4.#{param_name}#{channel_index}.ForeignEnergyDetected"] == 1 || channel_parameters["3.#{param_name}#{channel_index}.ForeignEnergyDetected"] == 1
      color_codes["foreign_energy"] = true
    end 
    
    return color_codes
  end
  
  
  def get_color_light_images(channel_id, channel_name, image_type=nil)
    image_color = ""
    
    image_color = if channel_id == 1 || channel_id == 4
      draw_image("G", image_type)
    elsif channel_id == 2 || channel_id == 5
      draw_image("Y", image_type)
    elsif channel_id == 3 || channel_id == 6
      draw_image("R", image_type)
    else
      draw_image("L", image_type)
    end

    if !channel_name.nil?
      image_color = case channel_name.split(//).last 
        when "G" then draw_image("G", image_type)
        when "Y" then draw_image("Y", image_type)
        when "R" then draw_image("R", image_type)
        when "L" then draw_image("L", image_type)
        when "B" then draw_image("B", image_type)
      else
        draw_image("L", image_type)
      end
    end
    
    return image_color
  end

   def get_color_light_images_path(channel_id, channel_name, image_type=nil)
    image_color = []
    
    image_color = if channel_id == 1 || channel_id == 4
      image_color << "G"
    elsif channel_id == 2 || channel_id == 5
      image_color << "Y"
    elsif channel_id == 3 || channel_id == 6
      image_color << "R"
    else
      image_color << "L"
    end
    
    if !channel_name.nil? && channel_name != "VLO"
      image_color = case channel_name.split(//).last 
        when "G" then image_color << "G"
        when "Y" then image_color << "Y"
        when "R" then image_color << "R"
        when "L" then image_color << "L"
      else
        image_color << "L"
      end
    end  
    
    return image_color
  end
  
  def get_color_light(channel_id, channel_name, image_type=nil)
    image_color = ""
    
    image_color = if channel_id == 1 || channel_id == 4
      get_image_path("G", image_type)
    elsif channel_id == 2 || channel_id == 5
      get_image_path("Y", image_type)
    elsif channel_id == 3 || channel_id == 6
      get_image_path("R", image_type)
    else
      get_image_path("L", image_type)
    end
    
    if !channel_name.nil? && channel_name != "VLO"
      image_color = case channel_name.split(//).last 
        when "G" then get_image_path("G", image_type)
        when "Y" then get_image_path("Y", image_type)
        when "R" then get_image_path("R", image_type)
        when "L" then get_image_path("L", image_type)
      else
        get_image_path("L", image_type)
      end
    end  
    
    return image_color
  end

  # drawing images based on the status colors of color light card
  def draw_image(color, image_type)
    
    if image_type.eql?("Off")
      image_tag("/images/dt/black_circle.png")
    elsif image_type.eql?("LOR")
      case
        when color.eql?("G") then image_tag("/images/dt/greencircle.png")
        when color.eql?("Y") then image_tag("/images/dt/yellowcircle.png") 
        when color.eql?("R") then image_tag( "/images/dt/redcircle.png")
        when color.eql?("M") then image_tag("/images/dt/redcircle.png")
        when color.eql?("L") then image_tag("/images/dt/circle.png")
      end
    else #image_type.eql?("On")
      case
        when color.eql?("G") then image_tag("/images/dt/plaingreencircle.png")
        when color.eql?("Y") then image_tag("/images/dt/plainyellowcircle.png") 
        when color.eql?("R") then image_tag( "/images/dt/plainredcircle.png")
        when color.eql?("M") then image_tag("/images/dt/magenta.png")
        when color.eql?("L") then image_tag("/images/dt/whitecircle_blank_border.png")
        when color.eql?("B") then image_tag("/images/dt/black_circle.png")
      end
    end    
  end
  # drawing images based on the status colors of color light card
  def get_image_path(color, image_type)
    
    if image_type.eql?("Off")
      return "/images/dt/black_circle.png"
    elsif image_type.eql?("LOR")
      case
        when color.eql?("G") then return("/images/dt/greencircle.png")
        when color.eql?("Y") then return("/images/dt/yellowcircle.png") 
        when color.eql?("R") then return( "/images/dt/redcircle.png")
        when color.eql?("M") then return("/images/dt/redcircle.png")
        when color.eql?("L") then return("/images/dt/circle.png")
      end
    else #image_type.eql?("On")
      case
        when color.eql?("G") then return("/images/dt/plaingreencircle.png")
        when color.eql?("Y") then return("/images/dt/plainyellowcircle.png") 
        when color.eql?("R") then return( "/images/dt/plainredcircle.png")
        when color.eql?("M") then return("/images/dt/magenta.png")
        when color.eql?("L") then return("/images/dt/whitecircle_blank_border.png")
      end
    end    
  end  
  
  # Fetching status images/messages for PCO channel
  def get_pco_status_message(channel_parameters, channel_index, param_name, channel_name = nil)
    color_codes = {}
    get_colour_code_images(channel_parameters, channel_index, "VLO", channel_name, color_codes, "search_light")
    pco_command_parameter(color_codes, channel_parameters, channel_index)
    pco_status_parameter(color_codes, channel_parameters, channel_index)    
    if channel_parameters["3.PCO#{channel_index}.MechFailure"] == 1
      color_codes["mech_failure"] = image_tag("dt/red_arrow.png")
    else
      color_codes["mech_failure"] = image_tag("dt/white-arrow.png")
    end
    return color_codes
  end

  def get_pco_status_message_img_path(channel_parameters, channel_index, param_name, channel_name = nil)
    color_codes = {}
    get_colour_code_images_path(channel_parameters, channel_index, "VLO", channel_name, color_codes, "search_light")
    pco_command_parameter(color_codes, channel_parameters, channel_index)
    pco_status_parameter_path(color_codes, channel_parameters, channel_index)    
    if channel_parameters["3.PCO#{channel_index}.MechFailure"] == 1
      color_codes["mech_failure"] = ("dt/red_arrow.png")
    else
      color_codes["mech_failure"] = ("dt/white-arrow.png")
    end
    return color_codes
  end
  
  def pco_status_parameter(color_codes, channel_parameters, channel_index)
    if channel_parameters["3.PCO#{channel_index}.SL_MDI1_ON"] == 1 && channel_parameters["3.PCO#{channel_index}.SL_MDI2_ON"] == 0 && channel_parameters["3.PCO#{channel_index}.SL_MDI3_ON"] == 0 
      color_codes["lamp_image"] = draw_image("G", color_codes["lamp_status"])
      color_codes["status_armature"] = "DG"
    elsif channel_parameters["3.PCO#{channel_index}.SL_MDI1_ON"] == 0 && channel_parameters["3.PCO#{channel_index}.SL_MDI2_ON"] == 1  && channel_parameters["3.PCO#{channel_index}.SL_MDI3_ON"] == 0
      color_codes["lamp_image"] = draw_image("Y", color_codes["lamp_status"])
      color_codes["status_armature"] = "HG"
    elsif channel_parameters["3.PCO#{channel_index}.SL_MDI1_ON"] == 0 && channel_parameters["3.PCO#{channel_index}.SL_MDI2_ON"] == 0  && channel_parameters["3.PCO#{channel_index}.SL_MDI3_ON"] == 1
      color_codes["lamp_image"] = draw_image("R", color_codes["lamp_status"])
      color_codes["status_armature"] = "RG"
    else
      color_codes["lamp_image"] = draw_image("M", color_codes["lamp_status"])
      color_codes["status_armature"] = "??"
    end
  end

  def pco_status_parameter_path(color_codes, channel_parameters, channel_index)
    if channel_parameters["3.PCO#{channel_index}.SL_MDI1_ON"] == 1 && channel_parameters["3.PCO#{channel_index}.SL_MDI2_ON"] == 0 && channel_parameters["3.PCO#{channel_index}.SL_MDI3_ON"] == 0 
      color_codes["lamp_image"] = get_image_path("G", color_codes["lamp_status"])
      color_codes["status_armature"] = "DG"
    elsif channel_parameters["3.PCO#{channel_index}.SL_MDI1_ON"] == 0 && channel_parameters["3.PCO#{channel_index}.SL_MDI2_ON"] == 1  && channel_parameters["3.PCO#{channel_index}.SL_MDI3_ON"] == 0
      color_codes["lamp_image"] = get_image_path("Y", color_codes["lamp_status"])
      color_codes["status_armature"] = "HG"
    elsif channel_parameters["3.PCO#{channel_index}.SL_MDI1_ON"] == 0 && channel_parameters["3.PCO#{channel_index}.SL_MDI2_ON"] == 0  && channel_parameters["3.PCO#{channel_index}.SL_MDI3_ON"] == 1
      color_codes["lamp_image"] = get_image_path("R", color_codes["lamp_status"])
      color_codes["status_armature"] = "RG"
    else
      color_codes["lamp_image"] = get_image_path("M", color_codes["lamp_status"])
      color_codes["status_armature"] = "??"
    end
  end
  
  
  def pco_command_parameter(color_codes, channel_parameters, channel_index)
    if channel_parameters["4.PCO#{channel_index}.SL_PCOA_ON"] == 1 && channel_parameters["4.PCO#{channel_index}.SL_PCOB_ON"] == 0
      color_codes["cmd_armature"] = "DG"
    elsif channel_parameters["4.PCO#{channel_index}.SL_PCOA_ON"] == 0 && channel_parameters["4.PCO#{channel_index}.SL_PCOB_ON"] == 1
      color_codes["cmd_armature"] = "HG"
    elsif channel_parameters["4.PCO#{channel_index}.SL_PCOA_ON"] == 0 && channel_parameters["4.PCO#{channel_index}.SL_PCOB_ON"] == 0
      color_codes["cmd_armature"] = "RG"
    else
      color_codes["cmd_armature"] = "??"
    end
  end
  
  # Fetching ATCS comm headers
  def get_atcs_header(parameter_names)
    arr1 = []      
    parameter_names.each{|parameter| arr1 << parameter.split('.') }
    flatten_array = arr1.flatten
    return flatten_array[0] == flatten_array[2] ? flatten_array.first : flatten_array.last
  end
  
  def get_track_current_and_voltage(card_type, channel_parameters, card_index)
    parameters, c_name, v_name = {}, "", ""
    if card_type.to_i == 1
      c_name = "3.TRK_ANLG_1.VCOCurrent"
      v_name = "3.TRK_ANLG_1.VCOVoltage"
    elsif card_type.to_i == 4
      c_name = "3.LIN_ANLG1.VCOCurrent"
      v_name = "3.LIN_ANLG1.VCOVoltage"
    elsif card_type.to_i == 48
      c_name = "3.MTX_ANLG.VCOCurrent"
      v_name = "3.MTX_ANLG.VCOVoltage"
      parameters["margin"] = channel_parameters["3.MTX_ANLG.Margin"].blank? ? "" : channel_parameters['3.MTX_ANLG.VCOVoltage']
    end
    
    if(@scaled_parameters.nil? || @scaled_parameters["#{card_index}.#{c_name}"].blank?)
      parameters["current"] = channel_parameters[c_name].blank? ? "0 A" : ( '%g' % "#{sprintf('%.4f', channel_parameters[c_name].to_f * 0.0500)}" + " A")
    else
      scaled_value = channel_parameters[c_name].blank? ? "0.0000" : ((channel_parameters[c_name].to_f * @scaled_parameters["#{card_index}.#{c_name}"].to_f/1000)/1000)
      parameters["current"] = ( '%g' % "#{sprintf('%.4f', scaled_value)}" + " A")
    end
    
    if(@scaled_parameters.nil? || @scaled_parameters["#{card_index}.#{v_name}"].blank?)
      parameters["voltage"] = channel_parameters[v_name].blank? ? "0 V" : ( '%g' % "#{sprintf('%.4f', channel_parameters[v_name].to_f * 0.0200)}" + " V")
    else
      scaled_value = channel_parameters[v_name].blank? ? "0.0000" : ((channel_parameters[v_name].to_f * @scaled_parameters["#{card_index}.#{v_name}"].to_f/1000)/1000)
      parameters["voltage"] = ( '%g' % "#{sprintf('%.4f', scaled_value)}" + " V")
    end
    parameters
  end
  
  def get_track_vti_current_and_margin(card_type, channel_parameters, card_index)
    parameters = {}
    if card_type.to_i == 48
      if(@scaled_parameters.nil? || @scaled_parameters["#{card_index}.3.MTX_ANLG.VTICurrent"].blank?)
        parameters["vti_current"] = channel_parameters["3.MTX_ANLG.VTICurrent"].blank? ? "0 A" : ('%g' % "#{sprintf('%.4f', channel_parameters["3.MTX_ANLG.VTICurrent"].to_f * 0.0200)}" + " A")
      else
        scaled_value = channel_parameters["3.MTX_ANLG.VTICurrent"].blank? ? "0.0000" : ((channel_parameters["3.MTX_ANLG.VTICurrent"].to_f * @scaled_parameters["#{card_index}.3.MTX_ANLG.VTICurrent"].to_f/1000)/1000)
        parameters["vti_current"] = ('%g' % "#{sprintf('%.4f', scaled_value)}" + " A")
      end
      parameters["margin"] = channel_parameters["3.MTX_ANLG.Margin"].blank? ? "" : channel_parameters['3.MTX_ANLG.Margin']
    end
    parameters
  end
  
  # finding out the card name for atcs comm view
  def get_atcs_card_name(card)
    io_channels = IoViewChannel.all(:conditions => {:mcfcrc => card.mcfcrc, :sin => card.sin, :view_type => card.view_type, :card_index => card.card_index}, :select => "channel_name")
    if !io_channels.blank? && io_channels.size == 2 && (io_channels.first.channel_name == io_channels.last.channel_name)
      return io_channels.first.channel_name
    else
      return card.slot_name
    end
  end
  
  # method to find out the  calibration message in GCP Module view
  def get_calibration_message(channel_parameters, param_type, card_number)
    message = []
    status_message = ""
    message << "GCP" if channel_parameters["#{param_type}.GCPStatus.CalibReq"]    == 1
    message << "APP" if channel_parameters["#{param_type}.GCPStatus.AppCalibReq"] == 1
    message << "LIN" if channel_parameters["#{param_type}.GCPStatus.LinCalibReq"] == 1
    status_message += message.join(", ") + " Cal Req<br />" unless message.blank?
    status_message = 'GCP<br /> Out Of Service' if(channel_parameters["4.GCPAppTrk#{card_number}.GCPInService"] == 1)
    status_message = 'GCP - ISL<br /> Out Of Service' if(channel_parameters["4.GCPAppTrk#{card_number}.GCPInService"] == 1 && channel_parameters["4.GCPAppTrk#{card_number}.IPIInService"] == 1)
    status_message
  end
  
  # To get GCP track card status parameters
  def get_track_status_params(parameters, card_number, mcfcrc, atcs_address, card_index)
    status = ""
    status += '<span id="island" class="trk_bottom">ed</span>' if gcp_ips_mode(mcfcrc, atcs_address, card_index) == 1
    status += '<span id="island" class="trk_bottom">m</span>'  if parameters["4.GCPAppTrk#{card_number}.MSGCPCtrlOP"] == 0
    status += '<span id="island" class="trk_bottom">w</span>'  if parameters["4.GCPAppTrk#{card_number}TrkWrap"] == 1
    status += '<span id="island" class="trk_bottom">po</span>' if gcp_predictor_override(mcfcrc, atcs_address, 28, card_number) == 1  
    status
  end
  
  def gcp_predictor_override(mcfcrc, atcs_address, card_index, card_number)
    RtParameter.find_by_mcfcrc(mcfcrc, 
      :conditions => {:sin => atcs_address, :card_index => card_index, :parameter_type => 2, :parameter_name => "T#{card_number}PredictorOverride"},
      :select => 'current_value').try(:current_value) || 0
  end
  
  def gcp_ips_mode(mcfcrc, atcs_address, card_index)
    RtParameter.find_by_mcfcrc(mcfcrc, 
      :conditions => {:sin => atcs_address, :card_index => card_index, :parameter_type => 6, :parameter_name => 'DiagFlags1.GCPIPSMode'},
      :select => 'current_value').try(:current_value) || 0
  end
  
  def get_track_bg_color(parameters, card_index, card_number, gcp_used, channel_index=1)
    return "gray !important;color:#000;" if !gcp_used
    
    dmessage = @diagnostic_messages.find{|card| card.card_index == card_index }
    color = ''
    if parameters["4.GCPAppTrk#{card_number}.GCPInService"] == 0
      if dmessage.nil?
        color = 'gray !important; color:#000;' if parameters["4.GCPAppTrk#{card_number}.GCPInService"] == 0
        color = '#FFF !important; color:#000;' if parameters['3.GCPStatus.TrainSpeed'] && parameters['3.GCPStatus.TrainSpeed'] > 0 && parameters['3.GCPStatus.TrainOnApproach'] == 0
      else
        color = '#B7280A !important;color:#FFF;'
        #color = 'gray !important; color:#000;' if parameters["4.GCPAppTrk#{card_number}.GCPInService"] == 0
      end   
    end  
    color
  end
  
  def atcs_parameter_name(parameter_name, three_type_header, four_type_header)
    p_name = if(parameter_name.first == three_type_header || parameter_name.first == four_type_header)
      parameter_name.last.nil? ? "" : parameter_name.last
    else
      parameter_name.first
    end
     (p_name || "")
 end
 
 # Fetching background color for island based on real time value
 def island_status(channel_parameters, ipi_used, card_index)
   app_card_index = RtCardInformation.app_card_index
   status = RtParameter.get_current_value_ex("GCPAppCPU.Island#{card_index}Occupied",app_card_index,4)
   return "background-color: gray;" unless ipi_used
   #"background-color:#{channel_parameters['3.IPIStatus.IPIOccupied'] == 1 ? '#809818; color:#FFF;' : '#B7280A;'}"
   "background-color:#{status == 1 ? '#809818; color:#FFF;' : '#B7280A;'}"
 end

 def get_IO_Status(card_number)
    card_ind = Card.find_all_by_mcfcrc(Gwe.mcfcrc, :select=>"card_index", :conditions =>["parameter_type = 2 and (cdf LIKE 'OPMAP.CDF' OR cdf LIKE 'IPMAP.CDF')"], :order => "card_index")
    cards = []
    @io_param_values = []
    card_ind.each do |indx|
       cards << indx.card_index
    end
    io_parameters = Parameter.find_by_sql("Select cardindex, parameter_type, parameter_index, name, param_long_name from parameters Where mcfcrc = #{Gwe.mcfcrc} AND cardindex in (#{cards.join(',')}) and parameter_type = 2 and (name Like 'Trk#{card_number}VRO%Assign' OR name Like 'Trk#{card_number}VPI%Assign') Order by cardindex, parameter_index")   
    io_parameters.each do |io_param|
      curr_val = RtParameter.find(:all, :select => "current_value", :conditions => {:card_index => io_param.cardindex, :parameter_type => io_param.parameter_type,
                :parameter_index => io_param.parameter_index})

      @io_param_values.push({:param_long_name => io_param.param_long_name, :parameter_index => io_param.parameter_index, :current_value => curr_val[0].current_value})
    end
 end


 ####################################################################
  # Function:      build_track_cards
  # Parameters:    type
  # Return:        @gwe, @atcs_addresses, @view_type, @tracks
  # Renders:       N/A
  # Description:   Gets all of the card information for a specfic card type
  # Example indexing:
  #   @tracks.each do |track|
  #     
  #   end
  #################################################################### 
    def build_track_cards(view_type,card_types)
      @atcs_addresses = atcs_address        #in application helper

      session[:timestamp] = nil

      io_status_request = 0
      @gwe = Gwe.get_mcfcrc(@atcs_addresses)
      @unconfig_page = false
      
      #checks state of vlp
      # if !check_vlp_state  #in application helper
         # @error_msg = "VLP Unconfigured. Please try 'Set to Default'"
        # return false
      # end

      #determines view_type from 
      @view_type = get_view_type_helper
      @card_type = card_types

      #gets 
      io_view = IoView.find_view(@atcs_addresses, @gwe.mcfcrc, @view_type)
      if io_view && io_view.status == 1  
        #gets all pf the cards    
        @cards = IoViewCard.get_cards_by_type(@atcs_addresses, @gwe.mcfcrc, @view_type,@card_type)   

        # Initializing timestamp session
        time_stamp_hash = {}
        @cards.select{|card| time_stamp_hash["card_#{card.card_index}"] = card.update_timestamp }
        session[:timestamp] = time_stamp_hash

        #gets all of the indices for the cards
        card_indices = @cards.map(&:card_index)
        
        #gets all of the chanels for all of the indices
        @channel_set = IoViewChannel.fetch_channels(card_indices, @atcs_addresses, @gwe, @view_type)

        #gets all of the data for tracks and stores it in @tracks
        @tracks = build_init_tracks(@atcs_address,@gwe.mcfcrc,@cards,@view_type,@channel_set)
      elsif io_view && io_view.status == 0
        #render :json => {:vlp_unconfigured => false, :view_exists => false, :poll => true, :mcfcrc => @gwe.mcfcrc}
        @msg =  "VLP Unconfigured"
      elsif io_view && io_view.status == -1
         @msg =   "No Records available!!"
      else
        # this is used to send a request if it the database is empty
        #io_status_request = initiate_io_status_request
        #render :json => {:vlp_unconfigured => false, :request_id => io_status_request, :mcfcrc => @gwe.mcfcrc, :view_exists => false, :poll => false, :geo_exists => true}
         @msg =  "Database is empty"
      end


    end

  ####################################################################
  # Function:      build_init_tracks
  # Parameters:    @atcs_address, @gwe.mcfcrc, card.card_index, card.card_type, @view_type, card.slot_no
  # Return:        @tracks
  # Renders:       N/A
  # Description:   builds a hash for track specfic card type
  #################################################################### 
     def build_init_tracks(atcs_address,mcfcrc,cards,view_type,channel_set)
      @scaled_parameters = {}
      if(view_type == 1)
        
        scale_factor = scale_factor_values(["VLPProc.BatteryVoltage","VLPProc.InternalVoltage","TRK_ANLG_1.VCOCurrent","TRK_ANLG_1.VCOVoltage","LIN_ANLG1.VCOCurrent","LIN_ANLG1.VCOVoltage","MTX_ANLG.VCOCurrent","MTX_ANLG.VCOVoltage", "LIN_ANLG1.VTICurrent", "TRK_ANLG_1.VTICurrent", "VLPProc.BatteryVoltage", "MTX_ANLG.VTICurrent"])
        
        scale_factor.split("&&").each do |v|
          scale_params = v.split("==")
          @scaled_parameters[scale_params[0]] = scale_params[1]
        end
      end

      RtCardInformation.refresh_app_card_index
      tracks = []
      cards.each do |card| 
        channels =  channel_set["#{card.card_index}"]

        tracks << get_slot_values(atcs_address, mcfcrc, card, view_type,channels)
        
      end

      return tracks
    end
  ####################################################################
  # Function:      get_slot_values
  # Parameters:    atcs_address, mcfcrc, card_index, card_type, view_type,slot_no,channels
  # Return:        track hash
  # Renders:       N/A
  # Description:   gets track info for a single slot
  #################################################################### 
    def get_slot_values(atcs_address, mcfcrc, card, view_type,channels)
      card_type = card.card_type
      card_index = card.card_index
      name = card.slot_name
      slot_no = card.slot_no
      card_health = ((card.card_status & (0X02)) == 0 ? 'active' : 'inactive')

      channel_parameters = fetch_channel_parameters(atcs_address, mcfcrc, card_index, card_type, view_type)

      channel_data = Hash.new
      channel_data['name'] =  name
      channel_data['health'] = card_health
      channel_data['slot_no'] = slot_no
      channel_data['card_index'] = card_index
      channel_data['card_type'] = card_type

      data_array = []

      channels.each do |channel|
        channel_type = channel.channel_tile
        
        channel_name = channel.channel_name
        channel_index = channel.channel_index
        temp = Hash.new

        if channel_type == "ChannelTileServer.Atcs.1"
          temp['ChannelTileServer.Atcs.1'] = ''
        elsif channel_type.match("VLPProc") 
          vlpprco_hash = Hash.new

          vlpprco_hash['BatteryVoltage'] = channel_parameters["3.VLPProc.BatteryVoltage"].blank? ? "0.00" : sprintf('%.2f', (channel_parameters["3.VLPProc.BatteryVoltage"]/10.0))
          vlpprco_hash['InternalVoltage'] = channel_parameters["3.VLPProc.InternalVoltage"].blank? ? "0.00" : sprintf('%.2f', (channel_parameters["3.VLPProc.InternalVoltage"]/10.0))
          vlpprco_hash['Temperature'] = channel_parameters["3.VLPProc.Temperature"].blank? || channel_parameters["3.VLPProc.Temperature"] == 0 ? "0.00" : sprintf('%.2f', (channel_parameters["3.VLPProc.Temperature"] - 50.0))
        
          temp['VLPProc'] = vlpprco_hash
        elsif channel_type.match("PSOStatusTXCtrl")
          temp['PSOStatusTXCtrl'] = pso_transmission_modulation_code(channel_parameters, 3)
        elsif channel_type.match("PSOStatusCtrl") 
          temp['PSOStatusCtrl'] = psorx_status_modulation_code(channel_parameters, channel_index, 3, card_index, mcfcrc, atcs_address)
        elsif channel_type.match("PSOIslandCtrl") 
          temp['PSOIslandCtrl'] = pso_island_control(channel_parameters, channel_index, 3, card_index, mcfcrc, atcs_address)
        elsif channel_type.match("Code") 
          code_hash = Hash.new
          
          vco_hash = Hash.new
          vco_hash['name'] = (channel_name.blank? ? (card_type && card_type == 1 ? "VCO" : "VTI") : channel_name)
          vco_hash['track_params'] = get_track_parameters_hash(channel_parameters, "4.VCO", channel_index)
          vco_hash['track_values'] = get_track_current_and_voltage(card_type, channel_parameters, card_index)

          code_hash['vco'] = vco_hash

          vti_hash = Hash.new

          if channel_parameters["3.VTI#{channel_index}.VitalCodePresent"] == 1
            title = 'VCP'
          elsif channel_parameters["3.VTI#{channel_index}.CodePresent"] == 1 
            title = 'CP'
          else
            title = 'NC'
          end
          vti_hash['title'] == title
          vti_hash['track_params'] =  get_track_parameters_hash(channel_parameters, "3.VTI", channel_index)

          if card_type.to_i == 4
            if channel_parameters["3.LIN_ANLG1.VTICurrent"].blank? 
              vti_hash['current'] = "0 " +' A'
            else 
              vti_hash['current'] = ( '%g' % sprintf('%.4f', channel_parameters["3.LIN_ANLG1.VTICurrent"].to_f * 0.01) +' A')
            end 
          else
            if channel_parameters["3.TRK_ANLG_1.VTICurrent"].blank?
              vti_hash['current'] = "0 " +' A'
            else 
              vti_hash['current'] = ( '%g' % sprintf('%.4f', channel_parameters["3.TRK_ANLG_1.VTICurrent"].to_f * 0.01)+' A')
            end
          end

          code_hash['Vti'] = vti_hash

          temp['Code'] = code_hash

        elsif channel_type.match("LineAnalog") 
          line_analog_hash = Hash.new
          #vco
          vco_hash = Hash.new

          vco_hash['name'] = (channel_name.blank? ? (card_type && card_type == 1 ? "VCO" : "VTI") : channel_name).to_s
          vco_hash['track_params'] = get_track_parameters_hash(channel_parameters, "4.VCO", channel_index)
          vco_hash['track_values'] = get_track_current_and_voltage(card_type, channel_parameters, card_index)

          line_analog_hash['vco'] = vco_hash

          vti_hash = Hash.new

          #vti
          if channel_parameters["3.VTI#{channel_index}.VitalCodePresent"] == 1
            title = 'VCP'
          elsif channel_parameters["3.VTI#{channel_index}.CodePresent"] == 1 
            title = 'CP'
          else
            title = 'NC'
          end

          vti_hash['name'] = title
          vti_hash['track_params'] = get_track_parameters_hash(channel_parameters, "3.VTI", channel_index)

          if card_type.to_i == 4
            if channel_parameters["3.LIN_ANLG1.VTICurrent"].blank? 
              vti_hash['current'] = "0 " +' A'
            else 
              vti_hash['current'] = ( '%g' % sprintf('%.4f', channel_parameters["3.LIN_ANLG1.VTICurrent"].to_f * 0.01) +' A')
            end 
          else
            if channel_parameters["3.LIN_ANLG1.VTICurrent"].blank?
              vti_hash['current'] = "0 " +' A'
            else 
              vti_hash['current'] = ( '%g' % sprintf('%.4f', channel_parameters["3.LIN_ANLG1.VTICurrent"].to_f * 0.01)+' A')
            end
          end

          line_analog_hash['vti'] = vti_hash

          temp['LineAnalog'] = line_analog_hash
        elsif channel_type.match("LED") 
          led_hash = Hash.new

          led_hash['name'] = (channel_name.blank? ? "LED" : channel_name)
          led_hash['params'] = get_led_params(4, channel_parameters, "LED", channel_index) 

          temp['LED'] = led_hash
        elsif channel_type.match("VRO") 
          vro_hash = Hash.new
          
          vro_hash['name'] = (channel_name.blank? ? "VRO" : channel_name)
          vro_hash['params'] = get_vro_cmd_status_params(channel_parameters, channel_index, "VRO",3) 

          temp['VRO'] = vro_hash
        elsif channel_type.match("VCO") 
          vco_hash = Hash.new

          vco_hash['name'] =  (channel_name.blank? ? (card_type && card_type == 1 ? "VCO" : "VTI") : channel_name)
          vco_hash['track_params'] =  get_track_parameters_hash(channel_parameters, "4.VCO", channel_index)
          vco_hash['track_values'] =  get_track_current_and_voltage(card_type, channel_parameters, card_index)

          temp['VCO'] = vco_hash
        elsif channel_type.match("VTI") 
          vti_hash = Hash.new
          
          if channel_parameters["3.VTI#{channel_index}.VitalCodePresent"] == 1
            title = 'VCP'
          elsif channel_parameters["3.VTI#{channel_index}.CodePresent"] == 1 
            title = 'CP'
          else
            title = 'NC'
          end

          vti_hash['name'] = title
          vti_hash['track_params'] = get_track_parameters_hash(channel_parameters, "3.VTI", channel_index)

          if card_type.to_i == 4
            if channel_parameters["3.LIN_ANLG1.VTICurrent"].blank? 
              vti_hash['current'] = "0 " +' A'
            else 
              vti_hash['current'] = ( '%g' % sprintf('%.4f', channel_parameters["3.LIN_ANLG1.VTICurrent"].to_f * 0.01) +' A')
            end 
          else
            if channel_parameters["3.TRK_ANLG_1.VTICurrent"].blank?
              vti_hash['current'] = "0 " +' A'
            else 
              vti_hash['current'] = ( '%g' % sprintf('%.4f', channel_parameters["3.TRK_ANLG_1.VTICurrent"].to_f * 0.01)+' A')
            end
          end

          temp['VTI'] = vti_hash
        elsif channel_type.match("Colorlight")
          color_light_hash = Hash.new
          
          color_light_hash['name'] = (channel_name.blank? ? "VLO" : channel_name)
          color_light_hash['code'] = get_colour_code(channel_parameters, channel_index, "VLO", channel_name)

          temp['Colorlight'] = color_light_hash
        elsif channel_type.match("VPI") 
          vpi_hash = Hash.new

          vpi_hash['name'] =  (channel_name.blank? ? "VPI" : channel_name)
          vpi_hash['params'] = get_vro_cmd_status_params(channel_parameters, channel_index, "VPI", 3)

          temp['VPI'] = vpi_hash
        elsif channel_type.downcase.eql?("ngcpstatusserver.ngcpstatusctrl.ngcpstatusserver.iodatactrl.1") 
          #from /app/views/io_status/channels/_ngcp_status_sever_control_channel.html.erb
          status_hash = Hash.new
          status_hash['used'] = gcp_and_ipi_used?(card_index, params[:atcs_address])
          status_hash['status'] =  get_track_status_params(channel_parameters, card_number, mcfcrc, atcs_address, card_index)

          temp['sever_status'] = status_hash
        elsif channel_type.downcase.eql?("ngcpstatusserver.iodatactrl.1") 
          #from /app/views/io_status/channels/_io_data_control_channel.html.erb
          temp['ngcpstatusserver.iodatactrl.1'] = ''
        elsif channel_type.match("XLO") 
          #from /app/views/io_status/channels/_xlo_channel.html.erb
          temp['XLO'] = get_xlo_parameters(channel_parameters, channel_index, "XLO")
        elsif channel_type.match("RBO") 
          #from /app/views/io_status/channels/_rbo_channel.html.erb
          temp['RBO'] = et_rbo_parameters(channel_parameters, channel_index, "RBO", 3)
        elsif channel_type.match("HPO") 
          #from /app/views/io_status/channels/_hpo_channel.html.erb
          temp['HPO'] = get_hpo_parameters(channel_parameters, channel_index, "HPO", 3)
        elsif channel_type.match("Searchlight") || channel_type.match("PCO")  
          #from /app/views/io_status/channels/_pco_channel.html.erb
          pco_hash = Hash.new 
          pco_hash['name'] = channel_name.blank? ? "SRCHLT#{channel_index}" : channel_name
          pco_hash['param'] = get_pco_status_message_img_path(channel_parameters, channel_index, "PCO", channel_name) 

          temp['PCO'] = pco_hash
        end 
         
        data_array << temp
      end

      if card_type == 48
        rx_hw_fail = RtParameter.find(:all,:conditions => ['card_index = ? and parameter_name = "MTX.RxFail" and parameter_type = 3',card_index])
        tx_hw_fail = RtParameter.find(:all,:conditions => ['card_index = ? and parameter_name = "MTX.TxFail" and parameter_type = 3',card_index])
        
        rx_paramter = RtParameter.find(:all,:conditions => ['card_index = ? and parameter_type = ? and current_value = ? and parameter_name like "MTX.Code%"',card_index,3,1])
        tx_paramter = RtParameter.find(:all,:conditions => ['card_index = ? and parameter_type = ? and current_value = ? and parameter_name like "MTX.Code%"',card_index,4,1])

        if rx_hw_fail && rx_hw_fail[0] && rx_hw_fail[0]['current_value'] &&  rx_hw_fail[0]['current_value'] == 1
          rx = 'HW Fail'
        elsif rx_paramter && rx_paramter[0]&& rx_paramter[0]['parameter_name']
          rx = rx_paramter[0]['parameter_name']
          rx = rx[rx.length-1]
        else
          rx = ''
        end

        if tx_hw_fail && tx_hw_fail[0] && tx_hw_fail[0]['current_value'] &&  tx_hw_fail[0]['current_value'] == 1
          tx = 'HW Fail'
        elsif tx_paramter && tx_paramter[0] && tx_paramter[0]['parameter_name']
          tx = tx_paramter[0]['parameter_name']
          tx = tx[tx.length-1]
        else
          tx = ''
        end

        rx_tx_hash = Hash.new
        rx_tx_hash['rx'] = rx
        rx_tx_hash['tx'] = tx

        data_array << rx_tx_hash
      end

      channel_data['data'] = data_array

      return channel_data
    end  

    def get_view_type_helper
      params[:view_type].eql?("atcs") ? 2 : 1
    end

    def isCPVersionInfo?(sVersionType)
      r = false
      case sVersionType
      when "MEF"
        r = true
      when "Linux Kernel"
        r = true
      when "FPGA"
        r = true
      when "CDL"
        r = true
      end
      return r
    end

    def fix_cp_slot_name(old_name)
      r = "SL1:CP"
      if old_name.length > 0
        t = old_name.split(':')
        if t.length >= 1
          r = t[0].rstrip() + ":CP"
        end
      end
      return r
    end
    
    def get_channel_name_rtviewchannels(channels_name)
      #Bug 11787 - when labelling i/o on module i/o (system) view don't show object name if there is only 1 object in the MCF 
      sin_value = Gwe.find(:first, :select => "sin").try(:sin)
      sat_names = RtSatName.find(:all, :conditions => ["sin =?", sin_value])
      channel_name = channels_name
      if(sat_names.length ==1)
        ch_name = channels_name.split(sat_names[0].sat_name)
        channel_name = ch_name[1] if ch_name.length == 2
        channel_name = channel_name[0,9]
      else
        channel_name = channel_name[0,9]
      end
      return channel_name
    end
end
