module GcpProgrammingHelper
  
  def fetch_sub_menus(menu_link)
    Menu.find(:all, :select => "menu_name, page_name, link, show, enable", 
                :conditions => {:mcfcrc => Gwe.mcfcrc, :parent => menu_link}, :order => "rowid")
  end
  
  def get_page_name(menu)
    menu.link.blank? ? menu.page_name : menu.link
  end
  
  def build_ancestry_gcp(parent, main_index, items = '')
    parent_used = Menu.cpu_3_menu_system
    menu_name = if (!parent_used)      
      parent.link
    elsif parent.parent.match("::")
      parent_menu = parent.parent.split("::").first
      "#{parent.menu_name}::#{parent_menu}" if parent_menu
    elsif @main_menu[parent.menu_name].nil? && parent.link == '(NULL)'
      "#{parent.menu_name}::#{parent.parent}"
    else
       (parent.link.blank?) ?  parent.menu_name : parent.link
    end
    if (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP") && (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE))
      controller_name = "gcp_programming"
    else
      controller_name = "programming"
    end

    @main_menu[menu_name].each_with_index do |menu, index|
      if menu.menu_name != '[Line]'
        enable_param = eval_expression(menu.enable)
        child_count = (@main_menu[menu.menu_name] || menu.link == '(NULL)')
        if((menu.menu_name == "ATCS SIN") || (menu.menu_name.upcase == "ATCS SITE ID"))
          page_href = "/nv_config/site_configuration?atcs_address_only=true"
        elsif(menu.menu_name == "Unique Check Number (UCN)")
          page_href = "/ucn/index"
        elsif(menu.menu_name == "Location")
          if((PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE) && ((session[:typeOfSystem] == "GEO") || (session[:typeOfSystem] == "GCP")))
            page_href = "/nv_config/site_location"
          else
            page_href = "/location/get_location"
          end
        elsif(menu.menu_name == "Time")
          page_href = "/geo_time/get_geo_time?get_time=false"
        elsif(menu.menu_name == "Object Names")
          page_href = "/object_name/get_object_name?object_type_name=Object&name_type=0"
        elsif(menu.menu_name == "Card Names")
          page_href = "/object_name/get_object_name?object_type_name=Card&name_type=1"
        elsif(menu.menu_name == "Set to Defaults" || menu.menu_name == "Set Default")
          page_href = "/#{controller_name}/set_to_default"
        else
          page_href = url_for(:controller => "#{controller_name}", :action => "page_parameters", :page_name => menu.menu_name, :menu_link => menu.link)          
        end
        disable_menu_item = ""
        if(menu.menu_name && (menu.menu_name.index("EMPTY") || (!enable_param)))
          disable_menu_item = "disable"
        end
        
        items += "<li class='leftnavtext_U #{disable_menu_item}' page_href='#{page_href}' >"
        items += "<span class='v_config_menu_item'>" + menu.menu_name+'</span>'
        if (menu.menu_name != menu.page_name) && (menu.menu_name != menu.parent) && (@main_menu[menu.menu_name] || menu.link == '(NULL)')
          sub_menu = build_ancestry_gcp(menu, index, '')
          if (!sub_menu.blank?)
            items += "<ul>"
            items += sub_menu
            items += "</ul>"
          end
        end
        items += "</li>"
      end
    end unless @main_menu[menu_name].blank?
    items
  end

  
  # Constructing wizard page menu structure
  def build_wizard(parent, main_index, items = '')
    menu_name = if @gcp_4000_version
      parent.link
    elsif @main_menu[parent.menu_name].nil? && parent.link == '(NULL)'
      "#{parent.menu_name}::#{parent.parent}"     
    else      
      parent.menu_name
    end
    
    @main_menu[menu_name].each_with_index do |menu, index|
      
      if menu.menu_name != '[Line]' && eval_expression(menu.show)
        enable_param = !eval_expression(menu.enable)
        child_count = (@main_menu[menu.menu_name] || menu.link == '(NULL)')
        #items += "<li class='leftnavtext_U #{"disable" if enable_param} #{"parent_expandable" if child_count}' pagename='#{menu.menu_name}' menulink='#{menu.link}' style='list-style-type:none;'>"
        #items += "<div class='hitarea expandable-hitarea #{"disable" if enable_param}'></div>" if child_count
        items += "<input type='checkbox' />" + menu.menu_name
        if @main_menu[menu.menu_name] || menu.link == '(NULL)'
          items += "<ul id='programming_menu' class='menu_child #{"disable" if enable_param}''>"        
          items += build_wizard(menu, index, '')
          items += '</ul>'
        else
          @menu_items << menu.menu_name + "_&_" + menu.link
        end
        items += '<br />'
      end
    end unless @main_menu[menu_name].blank?
    items
  end
  
  # Fetching expression result from existing hash object else calculation new
  def eval_expression(expression)  
   if PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE
      if @expression_structure[expression.to_s].nil?
        r = RtExprResult.expr_result(expression)
        if r && r.ui_specific == 0 && r.dirty == 0
          v =  (r.value == 1? true : false)
          @expression_structure[expression.to_s] = v 
          return v
        end
      end
    end
    @expression_structure[expression.to_s] = get_exp_value(expression) if @expression_structure[expression.to_s].nil?
    @expression_structure[expression.to_s]
  end
  
  ####################################################################
  # Function:      getOperandValue
  # Parameters:    operand
  # Return:        operand value
  # Renders:       None
  # Description:   get operand value
  ####################################################################
  def getOperandValue(sOperand)
    nReturnValue = 0
    return nReturnValue if sOperand.blank?
    bEnvVar = sOperand.include?("$")
    if (bEnvVar)
      op = sOperand
      op.sub!("\n"," ")
      op.sub!("\r"," ")
      op.sub("\t"," ")
      op.strip!
      return session[:envvarmap][op] if (session[:envvarmap] && session[:envvarmap][op])
      return nReturnValue
    end
    param_info =  extranctOperandInfo(sOperand)
    if (param_info.count >= 3)
      mcfcrc = Gwe.mcfcrc
      case param_info.count.to_i
        when 3
          rt_parameter = RtParameter.find(:first, :conditions => ["mcfcrc = ? and card_index = ? and parameter_type = ? and parameter_name = ?",
                          Gwe.mcfcrc, param_info.card_index, param_info.param_type, param_info.param_name])
          nReturnValue = rt_parameter.nil? ? 0 : rt_parameter.current_value
        when 4
          mcf_parameter = Parameter.find(:first, :conditions => ["mcfcrc = ? and layout_index = ? and cardindex = ? and parameter_type = ? and name = ?", 
            mcfcrc, Gwe.physical_layout, param_info.card_index, param_info.param_type, param_info.param_name])  
          sValName = param_info.param_value
          if mcf_parameter.nil?
            nReturnValue = 0
          elsif mcf_parameter.enum_type_name != ""
            nReturnValue = mcf_parameter.getEnumeratorValue(sValName)
          elsif (mcf_parameter.int_type_name != "")
            nReturnValue = sValName.to_i
          end
      end
    else
      nReturnValue = sOperand.to_i
    end
    return nReturnValue
  end
  
  
  def set_security_env(all=false)
        if session[:default_password] != DEFAULT_GCP_PASSWORD
          if all
                session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 1, "$SuperPasswordMatch" =>  1, "$DTSupportsSuperPassword" => 1}
          else

            case session[:user_id]
              when "Maintainer"
                session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 1, "$SuperPasswordMatch" =>  0, "$DTSupportsSuperPassword" => 1}
              when "Supervisor"
                session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 0, "$SuperPasswordMatch" =>  1, "$DTSupportsSuperPassword" => 1}
              when "Admin"
                session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 1, "$SuperPasswordMatch" =>  1, "$DTSupportsSuperPassword" => 1}
              else
                session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 0, "$SuperPasswordMatch" =>  1, "$DTSupportsSuperPassword" => 1}
            end
          end
        end
  end

  def handle_security_gcp4k
    case session[:gcp4000_password]
    when PASSWORD_MATCH
      session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 1, "$SuperPasswordMatch" =>  0, "$DTSupportsSuperPassword" => 1}
      return true
    when PASSWORD_SUPER_MATCH
      session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 0, "$SuperPasswordMatch" =>  1, "$DTSupportsSuperPassword" => 1}
      # logger.info "*************************** superpassword enabled when login ******************************************************"
      # if RtParameter.password_enabled?
        # session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 1, "$SuperPasswordMatch" =>  1, "$DTSupportsSuperPassword" => 1}
      # end
      return true
    when PASSWORD_MATCH_BOTH
      session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 1, "$SuperPasswordMatch" =>  1, "$DTSupportsSuperPassword" => 1}
      return true
    when PASSWORD_NOMATCH
      session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 0, "$SuperPasswordMatch" =>  0, "$DTSupportsSuperPassword" => 1}
      return true
    when PASSWORD_4K_DISABLED
      if RtParameter.password_enabled? &&  RtParameter.super_password_enabled?
        session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 1, "$SuperPasswordMatch" =>  1, "$DTSupportsSuperPassword" => 1}
      elsif RtParameter.password_enabled? 
        session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 1, "$SuperPasswordMatch" =>  0, "$DTSupportsSuperPassword" => 1}
      elsif RtParameter.super_password_enabled?
        session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 0, "$SuperPasswordMatch" =>  1, "$DTSupportsSuperPassword" => 1}
      else
        session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 0, "$SuperPasswordMatch" =>  0, "$DTSupportsSuperPassword" => 1}
      end
      return true
    end
    return false
  end

  def handle_security
    if handle_security_gcp4k()
      return
    end    
    if(PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE)
      session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 1, "$OffLine" => 1, "$SuperPasswordMatch" =>  1, "$DTSupportsSuperPassword" => 1}
      return
    else
      session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 0, "$SuperPasswordMatch" =>  0, "$DTSupportsSuperPassword" => 1}
    end
    # Security
    # If the user logs in with the default password and security set to None, then they can edit all parameters.
    # The WebUI shall set $PasswordMatch to 1 . The WebUI shall set ?$SuperPasswordMatch? to 1
    security_enabled = EnumParameter.find_by_Name(SECURITY_ENABLED)

    if security_enabled != nil
      case security_enabled.Selected_Value_ID
        when SECURITY_ENABLED_NONE
          session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 1, "$SuperPasswordMatch" =>  1, "$DTSupportsSuperPassword" => 1}
        when SECURITY_ENABLED_MAINTAINER_ONLY
          set_security_env
        when SECURITY_ENABLED_SUPERVISOR_ONLY
          set_security_env
        when SECURITY_ENABLED_MAINT_AND_SUPER
          set_security_env
      end

    else
    end

  end
  
  def get_parameters
    #Uistate.refresh_is_expr_thread_running()
    return "" if @page_parameters.blank?
    content_html = ""
    enable_count = 0
    rrr_offset = 0
    lll_offset = 0
    ggg_offset = 0
    ss_offset = 0
    vital_link = ""
    rdax_link = ""
    dax_link = ""
    remote_sin_flag = false
    actual_sin = ""
    actual_rrr = 0
    actual_lll = 0
    actual_ggg = 0
    actual_ss = 0
    lower_bound = 0
    upper_bound = 0
    unsigned_lower = 0
    unsigned_upper = 0
    int_param_type = ""
    remote_sin_cardindex = 0;
    
    #handle_security
    @valid_expr_params = {}
    @valid_expr_options = {}
    ###--------- Remoter SIN ---------###
    if @gcp_4000_version
      vital_link = "BASIC:  VITAL COMMS LINK "
      vital_link1 = "BASIC:  VITAL LINK " 
      rdax_link = "BASIC:  RDAX LINK"
      dax_link = "BASIC:  DAX LINK"
    else
      vital_link = "VITAL COMMS LINK"
      rdax_link = "No RDAX LINK FOR 5k"
      vital_link1 = "VITAL LINK"
      dax_link = "NO BASIC:  DAX LINK"
    end
    if (((!params[:page_name].blank?) && (params[:page_name].upcase.include?(vital_link) || params[:page_name].upcase.include?(vital_link1))) || ((!params[:menu_link].blank?) && (params[:menu_link].upcase.include?(vital_link) || params[:menu_link].upcase.include?(vital_link1))))
      remote_sin_flag = true
    elsif (((!params[:page_name].blank?) && params[:page_name].upcase.include?(rdax_link)) || ((!params[:menu_link].blank?) && params[:menu_link].upcase.include?(rdax_link)))
      remote_sin_flag = true
    elsif(((!params[:page_name].blank?) && params[:page_name].upcase.include?(dax_link))|| ((!params[:menu_link].blank?) && params[:menu_link].upcase.include?(dax_link)))
      remote_sin_flag = true
    else
      remote_sin_flag = false
    end
    gwe = Gwe.find(:first)
    actual_sin = gwe.sin    
    
    if (!actual_sin.blank?)
      if (actual_sin.size > 0)
        sin_arr = actual_sin.split('.')
        actual_rrr = sin_arr[1].to_i
        actual_lll = sin_arr[2].to_i
        actual_ggg = sin_arr[3].to_i
        actual_ss = sin_arr[4].to_i
      end
    end
    error_html = "<div id='error_explanation' style='display:block;'></div>" 
    unit_measure = (EnumValue.units_of_measure).Value    
    @page_parameters.each do |page_parameter|
      next if page_parameter.blank?
      if (page_parameter.default_params)
        flag = page_parameter.default_params.strip.upcase
        case flag 
         when "(NULL)"
            flag = ""
         when "YES"
            flag = "+"
        end
      end
      if (flag.length() > 0)
        sub_param = "<span><B>+</B>&nbsp;</span>"
      else  
        sub_param = "<span>&nbsp;&nbsp;&nbsp;</span>"
      end
      parameter = @parameters["#{page_parameter.card_index}.#{page_parameter.parameter_name.strip}"]
      if(parameter)
        #content_html += '<div id="serial_outer" style="color:red;" class="serial_outer">' + DateTime.now.to_s + '</div>'
        show_value = eval_expression(page_parameter.show) ? true : false
        $expression_mapper[page_parameter.parameter_name.strip + "_" + page_parameter.card_index.to_s] = show_value
        if show_value
          rt_parameter = RtParameter.find(:first, :conditions => ["mcfcrc = ? and card_index = ? and parameter_name = ?",  Gwe.mcfcrc, parameter.cardindex, parameter.name.strip])
          menu_expression = ''
          sub_menu = ''
          if @gcp_4000_version
            sub_menu = @sub_menus.find{|sub_menu| sub_menu.menu_name == page_parameter.menu_name }
            menu_expression = eval_expression(sub_menu.enable) if sub_menu         
          end
          content_html += '<div id="serial_outer" class="serial_outer">'
          content_html += '<div class="serialleft contentCSPlabel text_type">' + sub_param + (@gcp_4000_version ? contruct_parameter_name(parameter.param_long_name, sub_menu, menu_expression) : ((page_parameter.page_name == "Module Selection")? page_parameter.menu_name : parameter.param_long_name)) + display_units(parameter, unit_measure)+ "</div>"
          content_html += "<span class='ucn_protected'>&nbsp;"
          is_ucn_protected = false
          if check_appcrc_protected(parameter)
            content_html += image_tag('ProtectedApprovalCrc.gif')          
          end
          content_html += "</span>"
          content_html += "<div class='serialright text_type'>"
          disable_value = (is_ucn_protected)? check_user_presence_state(page_parameter, is_ucn_protected) : (!eval_expression(page_parameter.enable))
          
          if (rt_parameter.current_value == rt_parameter.default_value)
            default_flag = true
          else
            default_flag = false
          end
          
          if (parameter.enum_type_name != "" && parameter.data_type == "Enumeration")
            val_in = parameter.name
            current_value = get_current_enum(parameter, rt_parameter)
            # Since name is not unique given the combination of name & cardindex for the attribute value   
            #puts "-------------------------------------------------------------------------"            
            valid_enum_type = page_parameter.validate + "-" + parameter.enum_type_name
            #puts valid_enum_type.inspect
            #puts parameter.inspect
            if (@valid_expr_options[valid_enum_type].blank?)
              options = validate_select_options(parameter, page_parameter.validate, rt_parameter)
              @valid_expr_options[valid_enum_type] = options
            else
              options = @valid_expr_options[valid_enum_type]
            end
            #puts "options: " + options.inspect
            invalidbackground_val = false 
            unless options.rassoc(current_value).blank?
               invalidbackground_val = false
            else
                invalidbackground_val = true
                ivalid_option = []
                unless current_value.blank?
                    parameter.enumerator.each do |enumerator|
                      if (current_value.to_i == enumerator.value.to_i)
                        ivalid_option << [enumerator.long_name + " !" , current_value]
                        append = val_in.to_s+','+current_value.to_s
                        #unless @error_field.blank?
                        #  @error_field = @error_field.to_s + '|' + append.to_s
                        #else
                        #  @error_field = append
                        #end
                      end
                    end
                end
                unless ivalid_option.blank?
                  options = ivalid_option + options
                end
            end
            current_options = []
            options.each do |op|
              if (op[1].to_i == rt_parameter.default_value)
                if default_flag
                  current_options << [op[0].to_s, op[1]]
                else
                  current_options << [op[0].to_s + " *", op[1]]
                end
              else
                current_options << [op[0].to_s, op[1]]
              end
            end
                          #if (parameter.param_long_name == 'Template' && @template_disable== true) || (parameter.param_long_name == 'Chassis Type' && @template_disable == true)
            if ((parameter.param_long_name == 'Template') || (parameter.param_long_name == 'Chassis Type'))
              if (@template_disable== true)
                content_html += select_tag(parameter.name, options_for_select(current_options , current_value),:name => "#{parameter.name}" , :modified_field => "#{parameter.name}_#{parameter.cardindex}",  :style =>"#{'border: 1px solid #FF0000 !important;' if invalidbackground_val}" , :class => "contentCSPsel disabled_field", :disabled => "disabled")
              else
                content_html += select_tag(parameter.name, options_for_select(current_options , current_value), :name => "#{parameter.name}" , :modified_field => "#{parameter.name}_#{parameter.cardindex}", :style =>"#{'border: 1px solid #FF0000 !important;' if invalidbackground_val}" , :class => "contentCSPsel #{'disabled_field' if disable_value} #{'no_presence' if @ui_state.blank?} #{'invalid_select' if invalidbackground_val}", :current_value => current_value)
              end
            else
              content_html += select_tag(parameter.name, options_for_select(current_options , current_value), :name => "#{parameter.name}_#{parameter.cardindex}" , :modified_field => "#{parameter.name}_#{parameter.cardindex}", :style =>"#{'border: 1px solid #FF0000 !important;' if invalidbackground_val}" , :class => "contentCSPsel #{'disabled_field' if disable_value} #{'no_presence' if @ui_state.blank?} #{'invalid_select' if invalidbackground_val}", :current_value => current_value)
            end
            if default_flag
              content_html += "<span style='color:#FFFFFF;'>&nbsp;*</span>"
            end
            #content_html += '<input type="hidden" name="' + parameter.name + '_' + parameter.cardindex.to_s + '" value="' + parameter.param_long_name + '" />'
          else
            integer_parameter = parameter.integertype[0]
            if integer_parameter
              upper_bound = scale_integer_value(integer_parameter.upper_bound, integer_parameter)
              lower_bound = scale_integer_value(integer_parameter.lower_bound, integer_parameter)
              lower_bound = get_signed_value(lower_bound, integer_parameter.size).to_s if integer_parameter.signed_number == 'Yes'
              current_value = get_current_int_value(parameter, integer_parameter, rt_parameter)
              unit_imp = integer_parameter.imperial_unit
         
              if((unit_measure == 1) && (unit_imp != nil))
                  current_value = imperial_to_metric(integer_parameter, current_value)                  
                  upper_bound   =  imperial_to_metric(integer_parameter, upper_bound)
                  lower_bound   = imperial_to_metric(integer_parameter, lower_bound)
              end
              
              if (integer_parameter.signed_number.downcase != "yes")
                int_param_type = "unsigned"
              else
                int_param_type = "signed"
              end
              
              if ((unit_measure == 0) && (parameter.name.to_s.upcase == "RRROFFSET" || parameter.name.to_s.upcase == "LLLOFFSET" || parameter.name.to_s.upcase == "GGGOFFSET" || parameter.name.to_s.upcase == "SSOFFSET"))
                enable_count = enable_count + 1
                remote_sin_cardindex = parameter.cardindex
                if (integer_parameter.signed_number.downcase != "yes")
                  if (integer_parameter.upper_bound.to_i > 32768)
                    unsigned_lower = 32769
                  else
                    unsigned_lower = 0
                  end
                  unsigned_upper = 0                          
                  if (parameter.name.to_s.upcase == "RRROFFSET")
                    if (current_value > 32767)
                      rrr_offset = 32768 - current_value
                    else
                      rrr_offset = current_value  
                    end
                    upper_bound = 999 - actual_rrr
                    unsigned_upper = 32768 + actual_rrr
                  elsif (parameter.name.to_s.upcase == "LLLOFFSET")
                    if (current_value > 32767)
                      lll_offset = 32768 - current_value
                    else
                      lll_offset = current_value  
                    end
                    upper_bound = 999 - actual_lll
                    unsigned_upper = 32768 + actual_lll
                  elsif (parameter.name.to_s.upcase == "GGGOFFSET")
                    if (current_value > 32767)
                      ggg_offset = 32768 - current_value
                    else
                      ggg_offset = current_value  
                    end
                    upper_bound = 999 - actual_ggg
                    unsigned_upper = 32768 + actual_ggg
                  elsif (parameter.name.to_s.upcase == "SSOFFSET")
                    if (current_value > 32767)
                      ss_offset = 32768 - current_value
                    else
                      ss_offset = current_value  
                    end
                    upper_bound = 99 - actual_ss
                    unsigned_upper = 32768 + actual_ss
                  end
                else
                  if (parameter.name.to_s.upcase == "RRROFFSET")
                    rrr_offset = current_value
                    lower_bound = 0 - actual_rrr
                    upper_bound = 999 - actual_rrr
                  elsif (parameter.name.to_s.upcase == "LLLOFFSET")
                    lll_offset = current_value
                    lower_bound = 0 - actual_lll
                    upper_bound = 999 - actual_lll
                  elsif (parameter.name.to_s.upcase == "GGGOFFSET")
                    ggg_offset = current_value
                    lower_bound = 0 - actual_ggg
                    upper_bound = 999 - actual_ggg
                  elsif (parameter.name.to_s.upcase == "SSOFFSET")
                    ss_offset = current_value
                    lower_bound = 0 - actual_ss
                    upper_bound = 99 - actual_ss
                  end
                end
                content_html += text_field_tag(parameter.name, current_value, :unit_measure => unit_measure ,:min => lower_bound, :max => upper_bound, :int_param_type => int_param_type, :unsigned_lower =>unsigned_lower, :unsigned_upper => unsigned_upper, :current_value => current_value, :name => "#{parameter.name}_#{parameter.cardindex}" , :modified_field => "#{parameter.name}_#{parameter.cardindex}", :class => "contentCSPsel required integer_only #{'disabled_field' if disable_value} #{'no_presence' if @ui_state.blank?}", :id => parameter.name, :readonly => disable_value)
              else
                content_html += text_field_tag(parameter.name, current_value,:unit_measure => unit_measure ,:min => lower_bound, :max => upper_bound, :int_param_type => int_param_type, :current_value => current_value, :name => "#{parameter.name}_#{parameter.cardindex}" , :modified_field => "#{parameter.name}_#{parameter.cardindex}", :class => "contentCSPsel required integer_only #{'disabled_field' if disable_value} #{'no_presence' if @ui_state.blank?}", :id => parameter.name, :readonly => disable_value)  
              end
              
              if default_flag
                content_html += "<span style='color:#FFFFFF;'>&nbsp;*</span>"
              end
             # content_html += '<input type="hidden" name="' + parameter.name + '_' + parameter.cardindex.to_s + '" value="' + parameter.param_long_name + '" />'
            end          
          end
          content_html +="</div>"
          # if @gcp_4000_version
            # content_html += "<div class='programming_action_buttons' id='buttons_#{parameter.name}_#{parameter.cardindex}'><span class='save_mcf_parameter'>#{link_to(image_tag('/images/savemouseover.png'), 'javascript:', :name => "#{parameter.name}", :modified_field => "#{parameter.name}_#{parameter.cardindex}", :class => 'save_parameter', :param_name => parameter.name, :param_long_name => parameter.param_long_name, :param_type => parameter.parameter_type, :card_index => parameter.cardindex, :param_index => (parameter.parameter_index + 1), :current_value => current_value)}</span><span class='disacrd_mcf_parameter'>#{link_to(image_tag('/images/discard_changes.png'), 'javascript:', :class => 'discard_changes', :param_name => parameter.name, :param_long_name => parameter.param_long_name, :current_value => current_value, :name => "#{parameter.name}", :modified_field => "#{parameter.name}_#{parameter.cardindex}")}</span></div>"
          # end
          content_html += "<div width='200px' class='div_integer_only v_error' id = 'prog_warning_msg_#{parameter.name}_#{parameter.cardindex}'></div>"
          content_html += "</div>"
          
          if parameter.param_long_name == 'Template'
            template = Template.get_template(current_value)
            if template
              template.picture = template.picture.gsub(/\n/,"<br/>")
              template.picture = template.picture.gsub(/\s/, "&nbsp;")
              content_html += '<div id="template_details"><div id="serial_outer" class="serial_outer" style = "height: 180px !important"><div class="serialleft contentCSPlabel text_type"></div>' 
              content_html += "<span class='ucn_protected'>&nbsp;</span><div class='serialright text_type template_picture'><div id='template_picture'>#{simple_format(template.picture, :class => 'mtf_index_picture', :sanitize => false)}</div></div></div>"
              content_html += '<div id="serial_outer" class="serial_outer"><div class="serialleft contentCSPlabel text_type"><span>&nbsp;&nbsp;&nbsp;</span>Description</div>'
              content_html += "<span class='ucn_protected'>&nbsp;</span><div class='serialright text_type'><div id='template_description'><p>#{template.description}</p></div></div></div></div>"
            end
          end
          if @gcp_4000_version && params[:menu_link] && params[:menu_link].match('TEMPLATE:') && params[:menu_link].match('selection')
            if (@sub_menus.length > 0 && eval_expression(@sub_menus[0].show))
              content_html += "<div>"
              content_html += "<div id='serial_outer' class='serial_outer'>"
              if eval_expression(@sub_menus[0].enable)
                content_html += "<div id='template_set_to_defaults' class = 'set_template_defaults'>"
                content_html += "<span class='label'>Set Template Defaults</span>"
                content_html += "</div>"
              else
                content_html += "<div id='template_set_to_defaults_disable' class = 'set_template_defaults' style = 'cursor: default !important; opacity: 0.4'>"
                content_html += "<span class='label' style = 'color:#AFAFAF !important'>Set Template Defaults</span>"
                content_html += "</div>"
              end
              content_html += "</div>"
              content_html += "</div>"
            end
          end
        end        
      end
    end      
  if @gcp_4000_version
    if (remote_sin_flag && (enable_count > 1))
       remote_sin = cal_remote_sin(actual_sin, rrr_offset, lll_offset, ggg_offset, ss_offset)
       content_html += '<div id="serial_outer" class="serial_outer">'
       content_html += '<div class="serialleft contentCSPlabel text_type"><span>&nbsp;&nbsp;&nbsp;</span>Remote SIN</div>'
       content_html += "<span class='ucn_protected'>&nbsp;</span>"
       content_html += "<div class='serialright text_type'>"
       content_html += text_field_tag("remote_sin", remote_sin, :min => "", :max => "", :current_value => remote_sin, :name => "remote_sin" , :modified_field => "remote_sin_" + remote_sin_cardindex.to_s, :class => "contentCSPsel required #{'no_presence' if @ui_state.blank?} atcs_sin_only", :id => "remote_sin")
       content_html += '<input type="hidden" id="remote_sin_' + remote_sin_cardindex.to_s + '" name="remote_sin_' + remote_sin_cardindex.to_s + '" value="' + remote_sin.to_s + '" />'
       content_html += '<input type="hidden" id="hd_actual_sin" name="hd_actual_sin" value="' + actual_sin.to_s + '" />'
       content_html += "</div>"
       content_html += "<div width='200px' class='div_integer_only' id = 'prog_warning_msg_remote_sin_16'></div>"
       content_html += "</div>"
    end
  end
    return error_html + content_html
  end
  
  def cal_remote_sin(actual_sin, rrr_offset, lll_offset, ggg_offset, ss_offset)
    remote_sin = ""    
    if actual_sin
      atcs = actual_sin.split('.')
      remote_sin = "7"
      remote_sin = remote_sin + "." + "%03d" % (atcs[1].to_i + rrr_offset).to_s
      remote_sin = remote_sin + "." + "%03d" % (atcs[2].to_i + lll_offset).to_s
      remote_sin = remote_sin + "." + "%03d" % (atcs[3].to_i + ggg_offset).to_s
      remote_sin = remote_sin + "." + "%02d" % (atcs[4].to_i + ss_offset).to_s
    end
    return remote_sin
  end
  
  def get_links_4k(page_name)
    temp_mtf_ind = 0
    if !page_name.blank?
      gwe = Gwe.get_mcfcrc(@atcs_address)
      page = Page.find_by_page_name_and_mcfcrc(page_name, gwe.mcfcrc)
      if(page && page.page_group == "template")
        temp_mtf_ind = gwe.active_mtf_index
        page = Page.find(:first, :conditions => ["page_group = ? and mcfcrc = ? and mtf_index = ? and page_name = ?", "template", gwe.mcfcrc, gwe.active_mtf_index, page_name])
        if(page.nil?)
          temp_mtf_ind = 0
        end
      end      
      page_links = Menu.all(:conditions => ["mcfcrc = ? and page_name Like ? and link Like '{%' and target Not Like 'LocalUI' and link Not Like '{SEAR}' and mtf_index = ?", gwe.mcfcrc, page_name, temp_mtf_ind],
                       :order => 'display_order', :select => "menu_name, link, parent, page_name, show, enable")
    end
    content_html = ""
    link_menu_name = ""
    link_name = ""
    menulink_id = ""
    page_href = ""
    count = 0
    if !page_links.blank?
      content_html += image_tag('u170_line.png')
      page_links.each do |link_parm|
        link_menu_name = link_parm.menu_name
        link_name = link_parm.link    
        show_value = eval_expression(link_parm.show) ? true : false        
        if(show_value)
          if((link_menu_name.upcase == "ATCS SIN") || (link_menu_name.upcase == "ATCS SITE ID"))
            page_href = "/nv_config/site_configuration?atcs_address_only=true"
          elsif(link_menu_name == "Location")
            if((PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE) && ((session[:typeOfSystem] == "GEO") || (session[:typeOfSystem] == "GCP")))
              page_href = "/nv_config/site_location"
            else
              page_href = "/location/get_location"
            end            
          elsif(link_menu_name == "Time")
            page_href = "/geo_time/get_geo_time?get_time=false"
          end
          content_html += '<div id="serial_outer" class="serial_outer">'
          content_html += "<div class='serialleft contentCSPlabel text_type'><span>"
          content_html += "<a page_href='" + page_href + "' class='parameter_menu_link' href='javascript:'>" + link_menu_name + "</a></span>"
          content_html += "</div></div>"
                             
        end
        
        # link_menu_name = '"' + link_parm.menu_name + '"'
        # link_name = '"' + link_parm.link + '"'    
        # show_value = eval_expression(link_parm.show) ? true : false
        # puts link_menu_name.inspect
        # puts link_name.inspect
        # if(show_value)
          # count = count + 1
          # menulink_id = '"menulink_' + count.to_s + '"'
          # content_html += '<div id="serial_outer" class="serial_outer">'
          # if @ui_state.blank? && eval_expression(link_parm.enable)
            # content_html += "<div class='serialleft contentCSPlabel text_type'><span id=" + menulink_id.to_s + " class='no_param_menu_link' onclick = 'open_newwindow(" + link_menu_name + ',' + link_name + ',' + menulink_id.to_s + ");'>" + link_parm.menu_name + "</span></div>"
          # elsif !eval_expression(link_parm.enable)
              # content_html += "<div class='serialleft contentCSPlabel text_type'><span class='param_menu_link_disabled'>" + link_parm.menu_name + "</span></div>"
          # else
              # content_html += "<div class='serialleft contentCSPlabel text_type'><span id=" + menulink_id.to_s + " class='param_menu_link' onclick = 'open_newwindow(" + link_menu_name + ',' + link_name +  ',' + menulink_id.to_s + ");'>" + link_parm.menu_name + "</span></div>"
          # end
          # content_html += "<span class='ucn_protected'>&nbsp;"      
          # content_html += "</span>"
          # content_html += "<div class='serialright text_type'>" + "</div>"
          # content_html +="</div>"
        # end
      end
      if @ui_state.blank?
        content_html +="<div id='div_link_ui_state' class='no_presence'></div>"
      end
    end
    return content_html
  end
  
  def gcp_populate_menu_links
    page_content = ''
    @sub_menus.each do |menu|
      menu_expression = eval_expression(menu.show)
      if menu_expression
        page_content += '<div id="serial_outer" class="serial_outer">'
        if(menu.menu_name == "Set Template Defaults" && menu.link == "")
          page_content += "<div class='serialleft contentCSPlabel text_type'>"+link_to(menu.menu_name, 'javascript:', :page_href => '/gcp_programming/page_parameters?menu_link=set_template_defaults', :class => 'parameter_menu_link')+"</div>"
        else
          page_content += "<div class='serialleft contentCSPlabel text_type'>"+link_to(menu.menu_name, 'javascript:', :page_href => '/gcp_programming/page_parameters?menu_link='+menu.link, :class => 'parameter_menu_link')+"</div>"
        end
        page_content += '</div>'
      end
    end
    page_content
  end
  
  def contruct_parameter_name(parameter_name, sub_menu, menu_expression)
    menu_name = sub_menu ? sub_menu.menu_name : parameter_name
     (menu_expression && sub_menu) ? link_to(sub_menu.menu_name, 'javascript:', :page_href => '/gcp_programming/page_parameters?menu_link='+sub_menu.link, :class => 'parameter_menu_link') : menu_name
  end
  
  def check_appcrc_protected(parameter)
    parameter.IncludeInAppCRC == "Yes" ? true : false
  end
  
  def check_user_presence_state(page_parameter, is_ucn_protected)
    # @ui_state.blank? ? true : !eval_expression(page_parameter.enable)
    !eval_expression(page_parameter.enable)
  end
  
  def check_ucn_protected(parameter)
    parameter.include_in_ucn == "Yes" ? true : false    
  end
  
  # To get integer value of related mcf parameter
  def get_current_int_value(parameter, integer_parameter, rt_parameter)
    if rt_parameter
      factor = 1
      check_for_signed = false
      unless integer_parameter.blank?
        factor = (integer_parameter.scale_factor.to_f / 1000).to_f
        check_for_signed = true if integer_parameter.signed_number == 'Yes'
      end
      current_value = rt_parameter.current_value.to_f * factor
      current_value = get_signed_value(current_value, integer_parameter.size) if check_for_signed == true
      return current_value.to_i
    end
    parameter.default_value
  end
  
  # To get enum value of related mcf parameter
  def get_current_enum(parameter, rt_parameter)
    rt_parameter.blank? ? parameter.default_value : rt_parameter.current_value    
  end
  
  # Scaling integer value depends upon integer bounds
  def scale_integer_value(bound, integer_parameter)
   (bound.to_f * (integer_parameter.scale_factor.to_f/1000)).to_i if integer_parameter
  end
  
  # cleaned up the code - Kalyan
  def evalute_showhide_exp(page_param)
    count = 0
    page_param.each do |page_parameter|
      expr = page_parameter.show
      unless expr.blank?
        if expr.to_s == 'true'
          count += 1
        else
          expression = get_exp_value(expr)
          count += 1 if expression
        end
      end
    end unless page_param.blank?
    count
  end
  
  # To get expression value
  def get_exp_value(expr)
    if(expr.downcase == 'true' || expr.blank?)
      return true
    elsif(expr.downcase == 'false')
      return false
    elsif(!expr.index('(').nil? && !expr.index(')').nil? && expr != '(NULL)' && expr != '(LINE)')
      dynamic_expr = true
      expr_name = expr.split('(')[0]
      expression = Expression.find(:first, :conditions => ['mcfcrc = ? and expr_name like ?', Gwe.mcfcrc, "#{expr_name}%"], :select => 'expr, expr_name')
    else
      expression = Expression.find_by_expr_name(expr, :select => 'expr, expr_name')
    end
    
    if expression
      if(dynamic_expr)
        new_expr = get_expression(expression.expr_name, expr, expression.expr).strip
        result = evaluatePostfixExpr(new_expr, method(:getOperandValue))
      else
        result = evaluatePostfixExpr(expression.expr, method(:getOperandValue))
      end
      return (result.to_i() == 1) ? true : false
    else
      return false
    end
  end
  
  # get expression with dynamic values
  def get_expression (expr_param_names, expr_param_values, expr)
    param_names = expr_param_names.split("(")[1].split(")")[0].split(",")
    param_values = expr_param_values.split("(")[1].split(")")[0].split(",")
    param_names.each_with_index do |p, index|
      expr.gsub!("{" + p.strip + "}", param_values[index])
    end
    expr
  end
  
  # validate select options based on expression
  def validate_select_options(parameter, expr, rt_paramter=nil)
    options = []
    flag = true
    parameter.enumerator.each do |enumerator|
      # fetching selected enumerator to show picture for Template Programming
      if parameter.param_long_name == 'Template' && flag
        @selected_template = (enumerator.value.to_i == rt_paramter.current_value.to_i ? enumerator : nil)
        flag = false if @selected_template 
      end
      
      if expr.downcase == "true" || expr.blank? || expr == '(NULL)'
        valid_option = true
      elsif expr.downcase == 'false'
        valid_option = false
      else
        enum_expr = EnumeratorExpression.find_by_sql("select expr_name from enumerator_expression where mcfcrc = '#{Gwe.mcfcrc}' and expr_map_name = '#{expr}' and enumerator_name = '#{enumerator.long_name}' COLLATE NOCASE LIMIT 1")
        if (!enum_expr[0].blank?)
          if (@valid_expr_params[enum_expr[0].expr_name].blank?)
            evl = eval_expression(enum_expr[0].expr_name)
            @valid_expr_params[enum_expr[0].expr_name] = evl
          else
            evl = @valid_expr_params[enum_expr[0].expr_name]
          end
        else
          evl = false  
        end 
        #evl = eval_expression(enum_expr.expr_name)        
        valid_option  = enum_expr[0] && evl
      end
      if(valid_option && enumerator.long_name != 'Unidirectional' && enumerator.long_name != 'Bidirectional' && enumerator.long_name != 'See ENUMTYPES.xml')
        # Bug: 6934: As per the description commented for now ###
        # if(rt_paramter.default_value.to_s == enumerator.value.to_s)
          # options << [enumerator.long_name + " *", enumerator.value]
        # else
          # options << [enumerator.long_name, enumerator.value]
        # end
        options << [enumerator.long_name, enumerator.value]
      end
    end
    options
  end
  
  def get_signed_value(value, size)
    signed_num = (dec2bin(value).to_i && dec2bin(size).to_i).to_i
    flag = false
    if(signed_num > 0 )
      # convert the value to original value
      case size.to_i
        when 8
        if ((value.to_i & 0x80) != 0 )
          value = value & 0x7F
          return value *= -1
          flag = true
        end
        when 16
        if ((value.to_i & 0x8000) != 0)
          value = value.to_i & 0x7FFF
          return value *= -1
          flag = true
        end
        when 32
        if ((value.to_i & 0x80000000) != 0)
          value = value & 0x7FFFFFFF
          return value *= -1
          flag = true
        end
      end 
      if (flag == true)
        return value *= -1
      else
        return value
      end
    else
      return value
    end
  end

  def get_rgls_offset(page_name)
    rrr_offset = 0
    lll_offset = 0
    ggg_offset = 0
    ss_offset = 0
    
    actual_sin = ""
    actual_rrr = 0
    actual_lll = 0
    actual_ggg = 0
    actual_ss = 0
    lower_bound = 0
    upper_bound = 0
    unsigned_lower = 0
    unsigned_upper = 0
    card_index = 0

    sin_params = PageParameter.all(:conditions => ["mcfcrc = ? and page_name = ? and parameter_name Like \'%offset\'", Gwe.mcfcrc, page_name], :order => 'display_order')
    parameters_values = {}
    
    @parameters = {}

    gwe = Gwe.find(:first)
    actual_sin = gwe.sin  

    if (!actual_sin.blank?)
      if (actual_sin.size > 0)
        sin_arr = actual_sin.split('.')
        actual_rrr = sin_arr[1].to_i
        actual_lll = sin_arr[2].to_i
        actual_ggg = sin_arr[3].to_i
        actual_ss = sin_arr[4].to_i
      end
    end

    unit_measure = (EnumValue.units_of_measure).Value    

    @page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and page_name = ? and target not like 'LocalUI'", Gwe.mcfcrc , page_name], :order => 'display_order asc')

    @mcf_parameters = Parameter.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :cardindex => @page_parameters.map(&:card_index).uniq,:name => @page_parameters.map(&:parameter_name), :parameter_type => @page_parameters.map(&:parameter_type).uniq})

    @mcf_parameters.each do |parameter|
      @parameters["#{parameter.cardindex}.#{parameter.name.strip}"] = parameter
    end


      sin_params.each do |page_parameter|
        next if page_parameter.blank?
        
        parameter = @parameters["#{page_parameter.card_index}.#{page_parameter.parameter_name.strip}"]
        if(parameter)

          rt_parameter = RtParameter.find(:first, :conditions => ["mcfcrc = ? and card_index = ? and parameter_name = ?",  Gwe.mcfcrc, parameter.cardindex, parameter.name.strip])

          integer_parameter = parameter.integertype[0]

          if integer_parameter
            upper_bound = scale_integer_value(integer_parameter.upper_bound, integer_parameter)
            lower_bound = scale_integer_value(integer_parameter.lower_bound, integer_parameter)
            lower_bound = get_signed_value(lower_bound, integer_parameter.size).to_s if integer_parameter.signed_number == 'Yes'
            current_value = get_current_int_value(parameter, integer_parameter, rt_parameter)
            unit_imp = integer_parameter.imperial_unit
       
            if((unit_measure == 1) && (unit_imp != nil))
                current_value = imperial_to_metric(integer_parameter, current_value)                  
                upper_bound   =  imperial_to_metric(integer_parameter, upper_bound)
                lower_bound   = imperial_to_metric(integer_parameter, lower_bound)
            end
           
            if ((unit_measure == 0) && (parameter.name.to_s.upcase == "RRROFFSET" || parameter.name.to_s.upcase == "LLLOFFSET" || parameter.name.to_s.upcase == "GGGOFFSET" || parameter.name.to_s.upcase == "SSOFFSET"))

              remote_sin_cardindex = parameter.cardindex
              if (integer_parameter.signed_number.downcase != "yes")
                if (integer_parameter.upper_bound.to_i > 32768)
                  unsigned_lower = 32769
                else
                  unsigned_lower = 0
                end
                unsigned_upper = 0                          
                if (parameter.name.to_s.upcase == "RRROFFSET")
                  if (current_value > 32767)
                    rrr_offset = 32768 - current_value
                  else
                    rrr_offset = current_value  
                  end
                  upper_bound = 999 - actual_rrr
                  unsigned_upper = 32768 + actual_rrr
                elsif (parameter.name.to_s.upcase == "LLLOFFSET")
                  if (current_value > 32767)
                    lll_offset = 32768 - current_value
                  else
                    lll_offset = current_value  
                  end
                  upper_bound = 999 - actual_lll
                  unsigned_upper = 32768 + actual_lll
                elsif (parameter.name.to_s.upcase == "GGGOFFSET")
                  if (current_value > 32767)
                    ggg_offset = 32768 - current_value
                  else
                    ggg_offset = current_value  
                  end
                  upper_bound = 999 - actual_ggg
                  unsigned_upper = 32768 + actual_ggg
                elsif (parameter.name.to_s.upcase == "SSOFFSET")
                  if (current_value > 32767)
                    ss_offset = 32768 - current_value
                  else
                    ss_offset = current_value  
                  end
                  upper_bound = 99 - actual_ss
                  unsigned_upper = 32768 + actual_ss
                end
              else
                if (parameter.name.to_s.upcase == "RRROFFSET")
                  rrr_offset = current_value
                  lower_bound = 0 - actual_rrr
                  upper_bound = 999 - actual_rrr
                elsif (parameter.name.to_s.upcase == "LLLOFFSET")
                  lll_offset = current_value
                  lower_bound = 0 - actual_lll
                  upper_bound = 999 - actual_lll
                elsif (parameter.name.to_s.upcase == "GGGOFFSET")
                  ggg_offset = current_value
                  lower_bound = 0 - actual_ggg
                  upper_bound = 999 - actual_ggg
                elsif (parameter.name.to_s.upcase == "SSOFFSET")
                  ss_offset = current_value
                  lower_bound = 0 - actual_ss
                  upper_bound = 99 - actual_ss
                end
              end

              if parameter.name.to_s.upcase == "SSOFFSET" || parameter.name.to_s.upcase == "GGGOFFSET" || parameter.name.to_s.upcase == "LLLOFFSET"
                card_index = page_parameter.card_index
              end
            end
          end        
        end
      end
    return [rrr_offset,lll_offset,ggg_offset,ss_offset]
  end

  def get_hd_atcs(atcs_addr,page_name)
    rgls_offset = get_rgls_offset(page_name)

    rrr_offset = rgls_offset[0]
    lll_offset = rgls_offset[1]
    ggg_offset = rgls_offset[2]
    ss_offset = rgls_offset[3]

    #@rgls_offset = rgls_offset

    return cal_remote_sin(atcs_addr, rrr_offset, lll_offset, ggg_offset, ss_offset)
  end
end
