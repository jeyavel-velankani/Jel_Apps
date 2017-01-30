# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include UdpCmdHelper
  include GenericHelper
  
####################################################################
# Function:      site_info
# Parameters:    N/A
# Retrun:       @sname, @dotnum, @mpost, @atcs, session[:s_name], session[:atcs_address], session[:m_post] = @mpost.String, session[:dot_num]
# Renders:       N/A
# Description:   Gets the sire info
####################################################################
  def site_info
    string_param = StringParameter.string_group(1, 0)
    @sname = string_param.select{|parameter| parameter.Name == "Site Name"}.first
    @dotnum = string_param.select{|parameter| parameter.Name == "DOT Number"}.first
    @mpost = string_param.select{|parameter| parameter.Name == "Mile Post"}.first
    @atcs = string_param.select{|parameter| parameter.Name == "ATCS Address" and parameter.DisplayOrder != -1}.first
    if @atcs.blank?
      #@atcs = IntegerParameter.get_display_atcs_address
      @atcs = IntegerParameter.get_atcs_address
    else
      @atcs = @atcs.String
    end
    if @atcs.blank?
      @atcs = (string_param.select{|parameter| parameter.Name == "ATCS Address"}.first).String
    end
    
    session[:s_name] =  @sname.String
    session[:atcs_address] = @atcs
    session[:m_post] = @mpost.String
    session[:dot_num] = @dotnum.String
  end

####################################################################
# Function:      get_date_type
# Parameters:    N/A
# Retrun:        date_type
# Renders:       N/A
# Description:   Gets the date type
####################################################################
  def get_date_type

    default_date_type = 'mm-dd-yyyy'

    date_type = EnumParameter.get_selected_text(3);
    if date_type != nil
      date_type = ( date_type.split('(') != nil ? date_type.split('(')[1] : nil)
      date_type = (date_type != nil && date_type[0..date_type.length-2] != nil ? date_type[0..date_type.length-2] : default_date_type)

      return date_type
    else
      return default_date_type
    end
  end
  
  def header_function
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI
      if (session[:s_name].blank? || session[:atcs_address].blank? || session[:m_post].blank? || session[:dot_num].blank?)
        site_info
      end
      @sname = session[:s_name]
      @atcs_address = session[:atcs_address]
      @m_post = session[:m_post]
      @dot_num = session[:dot_num]      
    else
      if !session[:cfgsitelocation].blank?
        site_info
        
        @sname = session[:s_name]
        @atcs_address = session[:atcs_address]
        @m_post = session[:m_post]
        @dot_num = session[:dot_num]
      else
        session[:s_name] =  nil
        session[:atcs_address] = nil
        session[:m_post] = nil
        session[:dot_num] = nil
        @sname =  nil
        @atcs_address = nil
        @m_post = nil
        @dot_num = nil
      end
    end
  end
  
   def clear_Header_values
    session[:s_name] =  nil
    session[:atcs_address] = nil
    session[:m_post] = nil
    session[:dot_num] = nil
   end
  # Helper to include stylesheets
  def stylesheets(*args)
    stylesheet_link_tag(*args)  
  end
  
  # Helper to include javascripts
  def javascripts(*args)
    javascript_include_tag(*args)
  end
  
  
  def get_rt_parameter(parameters)
    RtParameter.find(:all, :select => "current_value", :conditions => {:mcfcrc => parameters.first.mcfcrc, :parameter_type => parameters.first.parameter_type, :parameter_index => parameters.first.parameter_index, :card_index => parameters.first.cardindex})
  end
  
  # Initializing RT comm status for the first time populating tabs
  def initialize_rt_comm_status(card_information, atcs_addr, mcfcrc)
    card_information.each do |card_info|
      #if rt_card.nil? 
      mcf_type = card_info.card_type == 10 ? 1 : 0
      online_object = RrGeoOnline.create({:request_state => 0, :atcs_address => (atcs_addr + ".01"), :mcf_type => mcf_type, :information_type => 3, :card_index => card_info.card_index})
      udp_send_cmd(105, online_object.request_id)
      request_state = 0
      counter = 0
      until request_state == 2
        online = RrGeoOnline.find_by_request_id(online_object.id, :select => "request_state")
        request_state = 2 if online.request_state == 2
        counter += 1
        request_state = 2 if counter == 4
        sleep 1
      end
      #end
    end
  end
   
  def get_slot_name(slot_name)
    if slot_name.size > 6
      display_card_name = slot_name.size > 15 ? truncate(slot_name, :length => 16).split(//) : slot_name.split(//)
      slot_name = display_card_name[0..7].to_s + "<br />" + display_card_name[8..15].to_s
      return slot_name
    else
      slot_name
    end
    
  end
  
  def vlp_parameters(parameters)
    rt_param = []
    parameters.each do |parameter|
      rt_param = get_rt_parameter(parameter)
    end
    return rt_param.first.current_value unless rt_param.blank?
    
  end
  
  def get_real_parameter(parameters)
    parameters.each do |parameter|
      rt_param = get_rt_parameter(parameter)
      if !rt_param.blank?
        if rt_param.first.current_value == 1
          return parameter.name.split('.').last  
        else
          return ""
        end  
      else
        return ""
      end  
    end unless parameters.blank?              
  end
  
  def get_nc_param(cp_param, vcp_param)
    vcp_param.blank? ? (cp_param.blank? ? "NC" : "CP") : "VCP"     
  end
  
  def get_rt_parameter(param)
    RtParameter.find(:all, :select => "current_value", 
                      :conditions => {:mcfcrc => param.mcfcrc, :parameter_type => param.parameter_type, 
                      :parameter_index => param.parameter_index, :card_index => param.cardindex})
  end
  
  def get_color_mcf_parameters(mcfcrc, card_index, name)
    Parameter.find(:all, 
         :conditions => ["mcfcrc = ? and cardindex = ? and name like '%#{name}%' and parameter_type = 3", mcfcrc, card_index], 
         :select => "name, default_value, mcfcrc, parameter_type, parameter_index, cardindex")
  end
  
  def get_mcf_parameter(mcfcrc, card_index)
    Parameter.find(:all, 
         :conditions => ["mcfcrc = ? and cardindex = ? and parameter_type = 3", mcfcrc, card_index], 
         :select => "name, default_value, mcfcrc, parameter_type, parameter_index, cardindex")
  end
  
  def get_coded_line_track_tx(mcf_params, elements)
    parameters = mcf_params.select{|param| param_name = param.name.split('.').last; elements.include?(param_name) }
    return get_real_parameter(parameters)
  end
  
  def get_vro_output_mnemonic(mcf_params)
    color_codes = {}
    mcf_params.each do |param|
      param_name = param.name.split('.').last
      rt_param = get_rt_parameter(param).first
      if rt_param && rt_param.current_value == 1
        color_codes["status"] = "On"
        color_codes["lamp_image"] = image_tag("dt/green_arrow.png", :size=> "10x10")
        return color_codes
      else
        color_codes["status"] = "Off"
        color_codes["lamp_image"] = image_tag("dt/black_arrow.png", :size=> "10x10")
      end  
    end
    return color_codes if color_codes.blank? || color_codes["status"] == "Off"
  end
  
  def  get_vro_param_name(param_name)
    case param_name
      when "CAB1" then return "75"
      when "CAB2" then return "120"
      when "CAB3" then return "180"
      when "CAB4" then return "270"
      when "CAB5" then return "420"
    else 
      return param_name 
    end
  end
  
  def get_colour_code_rt_param(mcf_params, channel_index, channel_name = nil)
    color_codes = {}
    mcf_params.each do |param|
      param_name = param.name.split('.').last
      rt_param = get_rt_parameter(param).first
      if param.name.match("VLO")        
        unless rt_param.blank?        
          if param_name == "LAMP_LOR" && rt_param.current_value == 1
            color_codes["lamp_status"] = "LOR"
            color_codes["lamp_image"] = get_color_light_images(channel_index, channel_name)
          elsif param_name == "LAMP_FLASH" && rt_param.current_value == 1
            color_codes["lamp_status"] = "Flash"
            color_codes["lamp_image"] = get_color_light_images(channel_index, channel_name, true)
          elsif param_name == "LAMP_ON" && rt_param.current_value == 1
            color_codes["lamp_status"] = "On"
            color_codes["lamp_image"] = get_color_light_images(channel_index, channel_name)
          elsif param_name == "ForeignEnergyDetected" && rt_param.current_value == 1
            color_codes["foreign_energy"] = true              
          end
        end
      end
    end   
    if(color_codes.size == 0)
      color_codes["lamp_status"] = "Off" 
      color_codes["lamp_image"] = image_tag "dt/black_circle.png", :size=> "10x10"
    end
    return color_codes
  end
  
  def get_color_light_images(channel_id, channel_name, flash_parameter=nil)
    image_color = ""
    if channel_id == 1 || channel_id == 4
      image_color = image_tag((flash_parameter.nil? ? "dt/greencircle.png" : "dt/plaingreencircle.png"), :size => "10x10")
    elsif channel_id == 2 || channel_id == 5
      image_color = image_tag((flash_parameter.nil? ? "dt/yellowcircle.png" : "dt/plainyellowcircle.png"), :size => "10x10")
    elsif channel_id == 3 || channel_id == 6
      image_color = image_tag((flash_parameter.nil? ? "dt/redcircle.png" : "plainredcircle.png"), :size => "10x10")
    else
      image_color = image_tag("dt/black_circle.png", :size=> "10x10")
    end
    
    unless channel_name.nil?
      case channel_name.split(//).last 
        when "G" then image_color = image_tag("dt/greencircle.png", :size => "10x10")
        when "Y" then image_color = image_tag("dt/yellowcircle.png", :size => "10x10")
        when "R" then image_color = image_tag("dt/redcircle.png", :size => "10x10")
      else
        image_color = image_tag("dt/black_circle.png", :size=> "10x10")
      end
    end
    return image_color
  end
  
  def get_coded_track_led(led_parameters)
    led_codes = {}
    led_parameters.each do |param|
      param_name = param.name.split('.').first
      rt_param = RtParameter.find_by_mcfcrc_and_parameter_type(param.mcfcrc, param.parameter_type, 
      :select => "current_value", 
      :conditions => {:parameter_index => param.parameter_index, :card_index => param.cardindex}) 
      
      unless rt_param.blank?
        if param.name.match("LED1.ON") && rt_param.current_value == 1    
          led_codes["led_status"] = "On" 
          led_codes["led_image"] = image_tag "dt/greencircle.png", :size=> "10x10"
        end  
      end
    end
    
    if(led_codes.size == 0)
      led_codes["led_status"] = "Off" 
      led_codes["led_image"] = image_tag "dt/black_circle.png", :size=> "10x10"
    end    
    return led_codes
  end
  
  
  def dec2bin(number)
    number = Integer(number);
    if(number == 0)
      return 0;
    end
    ret_bin = "";
    #Untill val is zero, convert it into binary format
    while(number > 0)
      ret_bin = String(number % 2) + ret_bin;
      number /= 2;
    end
    return ret_bin;
  end
  
  def get_card_health(card_index, atcs_addr, mcfcrc)    
    card_health = Rtcards.find_by_c_index(card_index, :conditions => {:mcfcrc => mcfcrc, :sin => atcs_addr, :parameter_type => 3..4}, :select => "comm_status").try(:comm_status)
    (card_health & 0X02)
  end
  
  def online_status_view(slot_number, slot_name, value)
    "<b>#{Time.now.strftime('%d%b%y %H:%M:%S')} Slot #{slot_number} #{slot_name} - #{value}<br/><b>"
  end
  
  def online_date_status_view(slot_number, value)
    "<b>#{Time.now.strftime('%d%b%y %H:%M:%S')} Slot #{slot_number}: #{value}<b><br />"
  end
  
  def online_status_view_write(slot_number, slot_name, value)
    "#{Time.now.strftime('%d%b%y %H:%M:%S')} Slot #{slot_number} #{slot_name}: #{value}"
  end
  
  def online_date_status_view_write(slot_number, value)
    "#{Time.now.strftime('%d%b%y %H:%M:%S')} Slot #{slot_number}: #{value}"
  end 
  
  def get_card_information_links(card_health)
    card_health == "1" || card_health == nil  ? "<span style='color:#fff;' id='module_information_links'>Module Information</span><br /><span style='color:#fff;' id='module_information_links'>Module Reset</span><br /><span style='color:#fff;' id='module_information_links'>Configuration Parameters</span><br /><span style='color:#fff;' id='module_information_links'>Operating Parameters</span>" : "#{link_to('Module Information', '#', :class => 'module_information', :id => 'module_information_links', :style => 'color:#fff;')}<br />#{link_to('Module Reset', '#', :class => 'module_reset', :id => 'module_information_links', :style => 'color:#fff;')}<br />#{link_to('Configuration Parameters', '/diagnostic_terminal/configuration_parameters', :class => 'configuration_parameters', :id => 'module_information_links', :style => 'color:#fff;')}<br />#{link_to('Operating Parameters', '#', :class => 'operating_parameters', :id => 'module_information_links', :style => 'color:#fff;')}"
  end
  
  def get_parameter_integer_value(integer_value, rt_parameter)
    integer_value.blank? || rt_parameter.blank? ? 0 : "#{(rt_parameter.current_value * integer_value.factor)}"
  end
  
  def get_parameter_enum_value(parameter, rt_parameter)
    enumerator = Mcfenumerator.find_by_enum_type_name(parameter.enum_type_name)
    return (enumerator.blank? || rt_parameter.blank?) ? 0 : enumerator.value
  end
  
  def get_geo_timer_value(integer_value, rt_parameter)
    integer_value.blank? || rt_parameter.blank? ? 0 : "#{(rt_parameter.current_value * integer_value.factor)}"
  end
  
  def get_property_names(prop_index, mcfcrc)
    prop_indexes = []
    prop_index.each do |prop|
      prop_indexes << LsProperties.find(:all, :select => 'distinct prop_name, enum_index', :conditions => ['prop_index = ? and mcfcrc =? ', prop.prop_index, mcfcrc])
    end
    return prop_indexes
  end
  
  def dec2hex(number)
    hexnum = Float(Array(number).pack('V').unpack('I')[0]).to_i.to_s(16)

    while hexnum.length < 8 do
      hexnum = "0" + hexnum
    end 
    
    return hexnum.to_s.upcase 
  end
  
  def ccn_swap(hex_number)
    #1.upto(8 - hex_number.size) { hex_number = "0" + hex_number } if hex_number.size < 8
    hex_number = (("0" * (8 - hex_number.size)) + hex_number) if hex_number.size < 8
    hex_number = hex_number[6,2] + hex_number[4,2] + hex_number[2,2] + hex_number[0,2]
    return  hex_number;
  end
  
  def mod_type(version)
   (version[0, 1].strip == "N" || version[0, 1].strip == "n")? 10 : (version[0, 1].strip == "G" || version[0, 1].strip == "g") ? 7 : 9 unless version.blank?
  end
  
  def rt_sessions_comm_status(c_status)
    c_status == 1 ? "Yes" : "No"
  end
  
  def rt_sessions_status(status)
    case status
      when 0
        "Connecting"
      when 1
        "Processing AUX files"
      when 2
        "Creating/Updating mcf database"
      when 3
        "Creating/Updating real time database"
      when 10
        "Ready"
    end
  end
  
  # Logic to disable the input fileds based on codition
  # Being called from operating parameters form
  def get_options(status)
    if status.to_i == 1
      {:class => "operating_field", :style => "height:28px;width:100%;"}
    else
      {:class => "operating_field", :style => "height:28px;width:100%;", :disabled => 'disabled'}
    end
  end
  
  def filter_title
    LogFilter.count == 0 ? 'Filter not set' : 'Filter is set'
  end
  
  def get_type_report_text(type)
    case(type.to_i)
      when 6
            return "Version Report"
      when 8
            return "Min Program Report"
      when 9
            return "Template Report"
      when 10
            return "Program Report"
      when 11
            return "Configuration Report"
    end
  end
 
  def check_for_module_install(channel = 0, slot = 0)
    #:TODO: Need to test this code NNSV
    if(PRODUCT_TYPE == PRODUCT_TYPE_GCP_WEBUI)
      module_type = nil
      enum_parameter = EnumParameter.find(:first,
              :conditions=>['Group_Channel= ? AND Group_ID=? AND Name = ? AND DisplayOrder!= ?', channel, ECHELON_MODULE_GROUP_ID , "Type", -1],
              :order => 'DisplayOrder')
      if(enum_parameter)        
        configure = EnumParameter.enum_dropdownbox_values(enum_parameter.ID)      
        configure.each do |conf|
          module_type = conf.Value if enum_parameter.Selected_Value_ID == conf.ID
        end
      end
      if module_type && (module_type.to_i == 3 || module_type.to_i == 6)
        @sear_module_status = get_sear_module_status(1, module_type) 
        @sear_module = true
      end
    end 
  end
  
  def get_sear_module_status(slot = 0, module_type = nil)
    return nil if !module_type
    SearModuleInstallStatus.find_by_slot_and_module_type(slot, module_type)
  end
  
  def get_and_counts
    RtParameter.count(:conditions => ["mcfcrc = ? and 
          (parameter_name LIKE 'AND%Used' OR parameter_name LIKE 'GCPAPPCPU%.AND%') and 
          (parameter_name NOT LIKE '%Wrap%') and 
          (parameter_name NOT LIKE '%Enable%')", Gwe.mcfcrc])
  end
  
  
    
#  Based on the PSO type used RX/SL/TX information will be displayed
  def pso_details
    tx_rx_pso_number = RtParameter.find_by_sql("select parameter_name, current_value from rt_parameters where parameter_name like '%PSOUsed' and current_value !=0")
    if(tx_rx_pso_number.length > 0)
      @active_pso_details = {}
       tx_rx_pso_number.each do |tx_rx_pso_number|
         if tx_rx_pso_number.current_value != 0
           active_pso = tx_rx_pso_number.current_value
           active_pso_parameter_name = tx_rx_pso_number.parameter_name
           @active_pso_details[active_pso] =  active_pso_parameter_name
          end
      end
      @pso_current_value = []
      @active_pso_details.each do |k, v|
          track_number = v[1,1]
          bidax_method = v[2,2]
          if bidax_method == "RX"
            parameter_name = "RXBiDAXMethod"
          else 
            parameter_name = "TXBiDAXMethod"
          end
          pso_current_val = type_of_pso(parameter_name, track_number)
          @pso_current_value << pso_current_val.current_value if pso_current_val
      end
    else
      @pso_current_value = []
      @rx1status = RtParameter.find(:first, :conditions => ["parameter_name = 'PSORX1Status.Used' and card_index = ?", params[:card_index]])
      @rx2status = RtParameter.find(:first, :conditions => ["parameter_name = 'PSORX2Status.Used' and card_index = ?", params[:card_index]])
      @ipistatus = RtParameter.find(:first, :conditions => ["parameter_name = 'IPIStatus.Used' and card_index = ?", params[:card_index]])
    end  
  end

#  To know type of PSO (i.e., vitalI/O, internal, External, Center fed)
  def type_of_pso(parameter_name, card_index)
 # RtParameter.find_by_sql("select current_value from rt_parameters where parameter_name = '#{parameter_name}' and card_index = #{card_index} limit 1").map(&:current_value)
    RtParameter.find(:first, :conditions => ["parameter_name = '#{parameter_name}' and card_index = #{card_index}"], :select => :current_value)
  end
  
  def scale_factor_single_parameter(value, card_index, parameter_name)
    parameter = Parameter.find(:first, :conditions => {:mcfcrc => Gwe.mcfcrc, :cardindex => card_index, :name => parameter_name })
    return value if !parameter
    integertype = parameter.integertype[0]
    integertype.nil? ? value : (value.to_f * integertype.scale_factor.to_f/1000).to_i
  end
  
  def scale_factor_values(parameter_names)
    scale_factors = []
    if(!parameter_names.blank?)
      p_names = []
      parameter_names.each do |x|
        p_names << "'" + x + "'"
      end
      parameters = Parameter.find(:all, :conditions => ["mcfcrc = ? and name in (#{p_names.join(',')}) and int_type_name != ''", Gwe.mcfcrc])
      parameters.each do |p|
        integertype = p.integertype[0]
        if(!integertype.nil?)
          scale_factors << "#{p.cardindex}.#{p.parameter_type}.#{p.name}==#{integertype.scale_factor}"
        end
      end
    end
    return scale_factors.join("&&")
  end
  
  def get_page(page_name)
    Page.find(:first, :conditions => {:page_name => page_name})
  end

  def get_session_logout
    time_db = IntegerParameter.find(:first,:select=>"Value,Default_Value",:conditions=>["Group_ID = ? and Group_Channel = ? and Name like ?",17,0,"%Session Inactivity Timeout%"])
    
    if time_db != nil
      if time_db.Value != nil
        time_db = time_db.Value
      else
        time_db = time_db.Default_Value
      end
    else
      time_db = 20
    end

    return time_db
  end

  def reset_session_logout
    time_db = get_session_logout

    session[:expires_at] = time_db.minute.from_now

    if session[:session_id] != nil && (PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI)
      CurrentUsers.update_all("keep_alive = '#{time_db.minute.from_now}'","session_id = '#{session[:session_id]}'")
    end
  end

  def check_session(reset)  
    if  session[:expires_at] != nil && session[:expires_at]

      if ( Time.now < session[:expires_at])
        if(reset != nil && (reset == "true" || reset == true))

          reset_session_logout

          return false
        else
          return check_user_database
        end
      else
        temp = session[:expires_at]
        session.delete(:user_id)
        session.delete(:expires_at)
        
        return true
      end
    else
      if(reset != nil && (reset == "true" || reset == true))
        reset_session_logout
      else
        return check_user_database
      end
    end
  end

  def check_user_database
    time_db = get_session_logout
    if session[:session_id] != nil 
      single_user = single_user?

      if single_user
        check_user = CurrentUsers.find(:all,:conditions=>["session_id = '#{session[:session_id]}'"])

        if check_user && check_user.length > 0
          return false
        else
          CurrentUsers.delete_all "session_id = '#{session[:session_id]}'"

          temp = session[:expires_at]
          session.delete(:user_id)
          session.delete(:expires_at)
          
          return true
        end
      else      
        return false
      end
    else
      temp = session[:expires_at]
      session.delete(:user_id)
      session.delete(:expires_at)
      
      return true
    end
  end

  def single_user?
    if OCE_MODE == 1
      return false
    else
      config = open_ui_configuration                         #Load ui_configuration.yml
     
      if config["WebUI"] && config["WebUI"]["single_user"]
        single_user = config["WebUI"]["single_user"]

        if single_user && single_user == 1
          return true
        else
          return false
        end
      else 
        return false
      end
    end
  end

  def build_utc_icon(ucn_protected_code)
    if ucn_protected_code == 1
      return '<div class="ptc_icon"><img src="/images/user_presence.gif"/></div>'
    elsif ucn_protected_code == 2
      return '<div class="ptc_icon"><img src="/images/ptc.png"/></div>'
    elsif ucn_protected_code == 3
      return '<div class="ptc_icon"><img src="/images/vcpu_editmode.gif"/></div>'
    else
      return '<div class="ptc_icon"></div>'
    end
  end
  
  def create_file_name(prefix)
    return prefix +'_' + Time.now.strftime('%m%d%Y_%H%M%S')
  end

  def convert_8_bit(s)
    new_s = ''
    string_bytes_array =  s.bytes.to_a

    value_8_bit = true
    string_post = 0
    string_bytes_array.each do |sb|
      if sb < 126
        new_s += s[string_post].to_s
      end
      string_post += 1
    end
  
    return new_s
  end
  
  def read_pac_xml_file(xml_file_path)
    sin = ""
    location_details = ""
    if File.exist?(xml_file_path)
      xmlfile = File.new(xml_file_path)
      doc = Document.new xmlfile
      
      doc.elements.each("MCFPackage/ConfigData/SIN"){|element|
        sin = element.text
      }
      sin = sin.insert(1, '.').insert(5, '.').insert(9,'.').insert(13,'.')
      
      doc.elements.each("MCFPackage/CardData/LocationSettings"){|element|
        location_details = element.text
      }
      dotnumber = ""
      milepost = ""
      site_name = ""
      loc = Document.new location_details
      loc.elements.each("LocationSettings/DOTNumber"){|ele|
        dotnumber = ele.text
      }
      loc.elements.each("LocationSettings/MilepostNumber"){|ele|
        milepost = ele.text
      }
      loc.elements.each("LocationSettings/SiteName"){|ele|
        site_name = ele.text.strip
      }
      xmlfile = nil
      doc = nil
      loc = nil
      return sin, dotnumber, milepost, site_name
      
    end
  end

  def read_error_log_file(path)
    site_path = path
    if File.exist?(site_path)
      file = File.open(site_path, "r")
      content = file.read
      unless content.blank?
        if content.include?('Error')
          error_flag = true
        else
          error_flag = false
          content = nil
        end 
      else
        content = nil
        error_flag = false
      end
    else
      content = nil
      error_flag = false
  end
  return error_flag,content
end
  def display_units(param, unit_measure = 0)
    if param
      if param.integertype[0]
        if param.integertype[0].imperial_unit != "" && param.integertype[0].imperial_unit != "No_Units"  && param.integertype[0].imperial_unit != " "
          if (unit_measure == 1)
            return " (" + param.integertype[0].metric_unit + ") "
          else
            return " (" + param.integertype[0].imperial_unit + ") "
          end
        end
      end
    end
    return "" 
  end

  def metric_to_imperial(integertype, float_value)
    begin
      if (integertype.imperial_unit == integertype.metric_unit)
        return float_value.to_f.round
      else
        float_value = float_value.to_f
        # Get the imperial units(imperial_unit) and standard units(metric_unit),
        # lower_boud,upper_bound,scale_factor
        local_units = Units.find(:first,:select => "mul_factor, div_factor", :conditions =>  {:from_unit => integertype.metric_unit, :to_unit => integertype.imperial_unit})
        if((!local_units.blank?) && (integertype.imperial_unit != integertype.metric_unit) && (!integertype.imperial_unit.blank?))
          #convert value to the metric units from imperial units.
          float_value = float_value.to_f * (local_units.mul_factor.to_f/local_units.div_factor.to_f)
        end
        #return float_value.round
        #Following are the conditions to set the value
        #eg: if the value is max.02 or max.06, then the value should be ceiled
        #eg: if the vlaue is (min-1).02, then it should be round and checked with min-1.
        if(float_value.ceil == (integertype.upper_bound + 1 ))
          value = integertype.upper_bound
        elsif (float_value.round == (integertype.lower_bound - 1 ))
          value = integertype.lower_bound
        else
          value = float_value.round
        end
        return value
      end
    rescue Exception => e
      return float_value.to_f.round
    end
  end
  
  def imperial_to_metric(integertype, int_value)
    # Get the imperial units(imperial_unit) and standard units(metric_unit),
    # lower_boud,upper_bound,scale_factor
    begin
      if (integertype.imperial_unit == integertype.metric_unit)
        return int_value
      else
        local_units = Units.find(:first,:select => "mul_factor, div_factor", :conditions =>  {:from_unit => integertype.imperial_unit, :to_unit => integertype.metric_unit})
        value = int_value
       #convert value to the metric units from imperial units.
        if((!local_units.blank?) && (integertype.imperial_unit != integertype.metric_unit) && (!integertype.imperial_unit.blank?))    
          value = int_value.to_f * ( local_units.mul_factor.to_f/local_units.div_factor.to_f )      
        end
        metric_val = metric_to_imperial(integertype, value.round)
        #puts "metric_val: " + metric_val.inspect
        if metric_val > integertype.upper_bound
          value = value.round - 1
        elsif ((value.round <= integertype.lower_bound.to_i) && (metric_val <= integertype.lower_bound.to_i))
          value = integertype.lower_bound  
        end
        return value.round
      end
    rescue Exception => e
      return int_value
    end
  end

end  
