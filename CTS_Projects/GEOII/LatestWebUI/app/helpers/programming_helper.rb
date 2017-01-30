####################################################################
# Company: Siemens 
# Author: Ashwin
# File: programming_helper.rb
# Description: Methods used in the views for vital configurations
####################################################################
module ProgrammingHelper
  
  ####################################################################
  # Function:      build_ancestry
  # Parameters:    parent, main_index, items
  # Return:        tree menu
  # Renders:       None
  # Description:   Constructing tree menu structure
  ####################################################################
  def build_ancestry(parent, main_index, items = '')

    menu_name = if parent.parent.match("::")
      parent_menu = parent.parent.split("::").first
      "#{parent.menu_name}::#{parent_menu}" if parent_menu
    elsif @main_menu[parent.menu_name].nil? && parent.link == '(NULL)'
      "#{parent.menu_name}::#{parent.parent}"
    else
       (parent.link.blank? || parent.link == '(NULL)') ?  parent.menu_name : parent.link
    end

    @main_menu[menu_name].each_with_index do |menu, index|
      if menu.menu_name != '[Line]'
        enable_param = eval_expression(menu.enable)
        child_count = (@main_menu[menu.menu_name] || menu.link == '(NULL)')
        if(menu.menu_name == "ATCS SIN")
          page_href = "/nv_config/site_configuration?atcs_address_only=true"
        elsif(menu.menu_name == "Unique Check Number (UCN)")
          page_href = "/ucn/index"
        elsif(menu.menu_name == "Location")
          if((PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE) && (session[:typeOfSystem] == "GEO"))
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
        elsif(menu.menu_name == "Set to Defaults" || menu.menu_name == "Set Default" || menu.menu_name == "Set to Default")
          page_href = "/programming/set_to_default"
        else
          page_href = url_for(:controller => "programming", :action => "page_parameters", :page_name => menu.menu_name, :menu_link => menu.link)          
        end
        disable_menu_item = ""
        if(menu.menu_name && (menu.menu_name.index("EMPTY") || (!enable_param)))
          disable_menu_item = "disable"
        end
        
        items += "<li class='leftnavtext_U #{disable_menu_item}' page_href='#{page_href}' >"
        items += "<span class='v_config_menu_item'>" + menu.menu_name+'</span>'
        if (menu.menu_name != menu.page_name) && (menu.menu_name != menu.parent) && (@main_menu[menu.menu_name] || menu.link == '(NULL)')
          sub_menu = build_ancestry(menu, index, '')
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

  ####################################################################
  # Function:      build_parameters
  # Parameters:    None
  # Return:        html fields as string
  # Renders:       None
  # Description:   Constructing parameters
  ####################################################################
  def build_parameters
    elements = ''
    parameter_count, rt_parameters_missing = 0, 0
    @valid_expr_params = {}
    @valid_expr_options = {}
    rrr_offset = 0
    lll_offset = 0
    ggg_offset = 0
    ss_offset = 0
    actual_sin = ""
    actual_rrr = 0
    actual_lll = 0
    actual_ggg = 0
    actual_ss = 0
    enable_count = 0
    remote_sin_flag = false
    unit_measure = 0
    protected_img = ""
    remote_sin_cardindex = 0
    inc = ""
    mask = ""
    card_index = []
    sub_param = "<span>&nbsp;&nbsp;&nbsp;</span>"
    if (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP") && (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE))
      remote_sin_flag = remotesin_enabled
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
    end
    
    @page_parameters.each do |page_parameter| 
      parameter = @parameters["#{page_parameter.card_index}.#{page_parameter.parameter_name.strip}"]
      flag_param = ""
      sub_param = ""
      if(parameter)
        if (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP") && (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE))
          if (page_parameter.default_params)
            flag_param = page_parameter.default_params.strip.upcase
            case flag_param
             when "(NULL)"
                flag_param = ""
             when "YES"
                flag_param = "+"
            end
          end
          if (flag_param.length() > 0)
            sub_param = "<span><B>+</B>&nbsp;</span>"
          else  
            sub_param = "<span>&nbsp;&nbsp;&nbsp;</span>"
          end
        end
        show_value = eval_expression(page_parameter.show) ? true : false
        $expression_mapper[page_parameter.parameter_name.strip + "_" + page_parameter.card_index.to_s] = show_value
        if show_value
          rt_parameter = RtParameter.find(:first, :conditions => ["mcfcrc = ? and card_index = ? and parameter_name = ?",  Gwe.mcfcrc, parameter.cardindex, parameter.name.strip])
          if rt_parameter.nil?
            rt_parameters_missing = rt_parameters_missing + 1
            next
          end
          card_index << parameter.cardindex
          parameter_count += 1;
          is_protected = false
          protected_img = "&nbsp;"
          default_indicator = "&nbsp"
          locked = false
          if check_appcrc_protected(parameter)
            protected_img = image_tag('ProtectedApprovalCrc.gif')
          elsif check_ptc_ucn_protected(parameter)
            protected_img = image_tag('ptc.png')
          elsif (check_ucn_protected(parameter)) 
            protected_img = image_tag('ProtectedMethods.gif') 
            is_protected = true
            locked = !@user_presence
          end
          if !locked
            locked = (is_protected)? check_user_presence_state(page_parameter, is_protected) : (!eval_expression(page_parameter.enable))
          end
          case parameter.data_type
            when "IntegerType"
              integer_parameter = parameter.integertype[0]
              if integer_parameter
                id = parameter.name.strip
                title = parameter.param_long_name.strip
                value = get_current_int_value(parameter, integer_parameter, rt_parameter)
                
                max = scale_integer_value(integer_parameter.upper_bound, integer_parameter)
                min = scale_integer_value(integer_parameter.lower_bound, integer_parameter)
                min = get_signed_value(integer_parameter.lower_bound, integer_parameter.size).to_s if integer_parameter.signed_number == 'Yes'

                if(unit_measure == 1)
                  units = integer_parameter.metric_unit
                  if (!units.blank?)
                    value = imperial_to_metric(integer_parameter, value)
                    max   =  imperial_to_metric(integer_parameter, max)
                    min   = imperial_to_metric(integer_parameter, min)
                  end
                else
                  units = integer_parameter.imperial_unit
                end
                
                inc = integer_parameter.step
                mask = ""
                #if default is set
                value = rt_parameter.default_value if params[:default_value] 
                default_indicator = "*" if value == rt_parameter.default_value
                numeric_only = 'numeric_only'
                param_type = 'int'
                if(units == "mA" || units == "mV")
                  max = (max/1000.to_f).round(1)
                  min = (min/1000.to_f).round(1)
                  value = value/1000.to_f
                  param_type = 'float_single_digit'
                  numeric_only = 'float_single_digit'
                  units.slice!(0)
                end
                
                if remote_sin_flag
                  ##################################################################################################################
                  if ((parameter.name.to_s.upcase == "RRROFFSET" || parameter.name.to_s.upcase == "LLLOFFSET" || parameter.name.to_s.upcase == "GGGOFFSET" || parameter.name.to_s.upcase == "SSOFFSET"))
                    enable_count = enable_count + 1
                    current_value = value
                    puts "Enabled: " +  enable_count.inspect
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
                    elements += '<div class="v_row"><div class="v_title">' + sub_param + title + (units && units.strip.length > 0 ? ' ('+units+')': '')+'</div><div class="v_protected">' + 
                        protected_img + '</div><div class="dv_input"><input id="'+id.to_s+'" param_type="' + param_type + '" value="'+value.to_s+'" class="'+(locked  ? 'locked readonly' : '') + 
                        ' '+numeric_only+'" '+(locked ? 'disabled="disabled"' : '')+' min = "'+lower_bound.to_s+'" max = "'+upper_bound.to_s+'" inc="'+inc.to_s+'"  mask="'+mask+'" /></div><div class="v_default_indicator">' + 
                        default_indicator + '</div>'+(locked ? '<div class="locked"></div>' : '')+'<div class="v_error"></div></div>'
                  else
                    elements += '<div class="v_row"><div class="v_title">' + sub_param + title + (units && units.strip.length > 0 ? ' ('+units+')': '')+'</div><div class="v_protected">' + protected_img + '</div><div class="dv_input"><input id="'+id.to_s+'" param_type="' + param_type + '" value="'+value.to_s+'" class="'+(locked  ? 'locked readonly' : '')+' '+numeric_only+'" '+(locked ? 'disabled="disabled"' : '')+' min = "'+min.to_s+'" max = "'+max.to_s+'" inc="'+inc.to_s+'"  mask="'+mask+'" /></div><div class="v_default_indicator">' + default_indicator + '</div>'+(locked ? '<div class="locked"></div>' : '')+'<div class="v_error"></div></div>'
                  end
                else
                  elements += '<div class="v_row"><div class="v_title">' + sub_param + title + (units && units.strip.length > 0 ? ' ('+units+')': '')+'</div><div class="v_protected">' + protected_img + '</div><div class="dv_input"><input id="'+id.to_s+'" param_type="' + param_type + '" value="'+value.to_s+'" class="'+(locked  ? 'locked readonly' : '')+' '+numeric_only+'" '+(locked ? 'disabled="disabled"' : '')+' min = "'+min.to_s+'" max = "'+max.to_s+'" inc="'+inc.to_s+'"  mask="'+mask+'" /></div><div class="v_default_indicator">' + default_indicator + '</div>'+(locked ? '<div class="locked"></div>' : '')+'<div class="v_error"></div></div>'  
                end
                
              end
            when "Enumeration"
              val_in = parameter.name
              current_value = get_current_enum(parameter, rt_parameter)
              current_value = rt_parameter.default_value if params[:default_value]
              # Since name is not unique given the combination of name & cardindex for the attribute value   
              valid_enum_type = page_parameter.validate + "-" + parameter.enum_type_name
              if (@valid_expr_options[valid_enum_type].blank?)
                options = validate_options(parameter, page_parameter.validate, rt_parameter)
                @valid_expr_options[valid_enum_type] = options
              else
                options = @valid_expr_options[valid_enum_type]
              end
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
                        end
                      end
                  end
                  unless ivalid_option.blank?
                    options = ivalid_option + options
                  end
              end
              current_options = []
              options.each do |op|
                if (op[1].to_i == rt_parameter.default_value && current_value != rt_parameter.default_value)
                  current_options << [op[0].to_s + " *", op[1]]
                else
                  current_options << [op[0].to_s, op[1]]
                end
              end
  
              id = parameter.name.strip
              title = parameter.param_long_name.strip
              value = ""
              default_indicator = (current_value == rt_parameter.default_value)? "*":""
              if locked
                select_tag = select_tag(parameter.name, options_for_select(current_options , current_value), :id => id.to_s , :param_type => "enum", :style =>"#{'border: 1px solid #FF0000 !important;' if invalidbackground_val}" , :class => 'disabled', :disabled => 'disabled')
              else
                if ((PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE ) && (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP")))
                  if (parameter.param_long_name == 'Template' && @template_disable== true) || (parameter.param_long_name == 'Chassis Type' && @template_disable == true)
                    select_tag = select_tag(parameter.name, options_for_select(current_options , current_value), :id => id.to_s , :param_type => "enum", :style =>"#{'border: 1px solid #FF0000 !important;' if invalidbackground_val}" , :class => 'disabled', :disabled => 'disabled')
                  else
                    select_tag = select_tag(parameter.name, options_for_select(current_options , current_value), :id => id.to_s , :param_type => "enum", :style =>"#{'border: 1px solid #FF0000 !important;' if invalidbackground_val}")
                  end
                else
                  select_tag = select_tag(parameter.name, options_for_select(current_options , current_value), :id => id.to_s , :param_type => "enum", :style =>"#{'border: 1px solid #FF0000 !important;' if invalidbackground_val}")
                end
              end 
              elements += '<div class="v_row"><div class="v_title">' + sub_param + title + '</div><div class="v_protected">' + protected_img + '</div><div class="dv_input">'+select_tag+'</div><div class="v_default_indicator">' + default_indicator + '</div>'+(locked ? '<div class="locked"></div>' : '')+'<div class="v_error"></div></div>'
          end
        end

        if parameter.param_long_name == 'Template'
          template = Template.get_template(current_value)
          if template
            elements += '<div id="template_details">'+render(:partial => "programming/template_details", :locals => {:template => template})+'</div>'
          end
        end
      end
    end

    #
    # Pages may have links
    #
    
    if (remote_sin_flag && (enable_count > 1))
      puts "------------------------------------ Remote SIN ----------------------------"
       remote_sin = cal_remote_sin(actual_sin, rrr_offset, lll_offset, ggg_offset, ss_offset)
       elements += '<div class="v_row"><div class="v_title">' + sub_param + 'Remote SIN'  +  
            '</div><div class="v_protected">' + protected_img + '</div><div class="dv_input"><input id="remote_sin" ' + 
            'modified_field = ' + 'remote_sin_' + remote_sin_cardindex.to_s + ' name = "remote_sin"' +
            '" value="'+remote_sin.to_s+'" class="atcs_sin_only"' + ' min = "" max = "" inc="'+inc.to_s+'"  mask="'+mask+'" param_type = "atcs_sin" /></div>' + 
            '<div class="v_error"></div></div>'
            
       elements += '<input type="hidden" id="remote_sin_' + remote_sin_cardindex.to_s + '" name="remote_sin_' + remote_sin_cardindex.to_s + '" value="' + remote_sin.to_s + '" />'
       elements += '<input type="hidden" id="hd_actual_sin" name="hd_actual_sin" value="' + actual_sin.to_s + '" />'
       elements += '</div>'
       
       # elements += "<div class='programming_action_buttons' id='buttons_remote_sin_" + remote_sin_cardindex.to_s + "'>
          # <span class='save_mcf_parameter'>#{link_to(image_tag('/images/savemouseover.png'), 'javascript:', :name => 'remote_sin', :modified_field => 'remote_sin_' + remote_sin_cardindex.to_s , :class => 'save_parameter', :param_name => 'remote_sin', :param_long_name => 'remote_sin', :param_type => 2, :card_index => remote_sin_cardindex, :param_index => 999, :current_value => remote_sin.to_s)}</span>
          # <span class='disacrd_mcf_parameter'>#{link_to(image_tag('/images/discard_changes.png'), 'javascript:', :class => 'discard_changes', :param_name => 'remote_sin', :param_long_name => 'remote_sin', :current_value => remote_sin.to_s , :name => 'remote_sin', :modified_field => 'remote_sin_' + remote_sin_cardindex.to_s)}</span></div>"
       # elements += "<div width='200px' class='div_integer_only' id = 'prog_warning_msg_remote_sin_16'></div>"
       #elements += "</div>"
    end
    @card_index = card_index.uniq
    elements += populate_menu_links
    elements += '<input type="hidden" id="parameter_count" value="' + parameter_count.to_s + '" />'
    elements += '<input type="hidden" id="parameters_missing" value="' + rt_parameters_missing.to_s + '" />'
    return elements
  end

def populate_menu_links 
    page_content = ""   
    if @sub_menus
      page_content = '<div id="leftnavtree" class="leftnav leftnavtree treeview" width="100">'
      page_content += "<ul style= 'display: block;'>"
      @sub_menus.each do |menu|
        menu_expression = eval_expression(menu.show)
        if menu_expression
          disable_menu_item = ""
          page_href = url_for(:controller => "programming", :action => "page_parameters", :page_name => menu.menu_name, :menu_link => menu.link)

          page_content += "<li class='leftnavtext_U submenu_click' page_href='#{page_href}' title ='#{menu.menu_name}'>"
          page_content += "<span class='parameter_menu_link'>" + menu.menu_name+'</span>'
          page_content += "</li>"
        end
      end
      page_content += '</ul>'
      page_content += '</div>'
    end
    page_content
  end
  ####################################################################
  # Function:      get_current_int_value
  # Parameters:    parameter, integer_parameter, rt_parameter
  # Return:        current value or default value
  # Renders:       None
  # Description:   To get integer value of related mcf parameter
  ####################################################################
  def get_current_int_value(parameter, integer_parameter, rt_parameter)
    if rt_parameter
      factor, check_for_signed = 1, false
      unless integer_parameter.blank?
        factor = (integer_parameter.scale_factor.to_f / 1000).to_f
        check_for_signed = true if integer_parameter.signed_number == 'Yes'
      end
      current_value = rt_parameter.current_value.to_f * factor
      current_value = get_signed_value(current_value, integer_parameter.size) if check_for_signed == true
      if (integer_parameter.metric_unit == "mA" || integer_parameter.metric_unit == "mV")
        return current_value
      else
        return current_value.to_i
      end
    end
    parameter.default_value
  end
  
  ####################################################################
  # Function:      get_current_enum
  # Parameters:    parameter, rt_parameter
  # Return:        current value or default value
  # Renders:       None
  # Description:   To get enum value of related mcf parameter
  ####################################################################
  def get_current_enum(parameter, rt_parameter)
    rt_parameter.blank? ? parameter.default_value : rt_parameter.current_value    
  end

  ####################################################################
  # Function:      check_appcrc_protected
  # Parameters:    parameter
  # Return:        true or false
  # Renders:       None
  # Description:   To check appcrc protected parameter
  ####################################################################
  def check_appcrc_protected(parameter)
    parameter.IncludeInAppCRC == "Yes" ? true : false
  end
  
  ####################################################################
  # Function:      check_ucn_protected
  # Parameters:    parameter
  # Return:        true or false
  # Renders:       None
  # Description:   To check ucn protected parameter
  ####################################################################
  def check_ucn_protected(parameter)
    parameter.include_in_ucn == "Yes" ? true : false
  end

  ####################################################################
  # Function:      check_ptc_ucn_protected
  # Parameters:    parameter
  # Return:        true or false
  # Renders:       None
  # Description:   To check appcrc protected parameter
  ####################################################################
  def check_ptc_ucn_protected(parameter)
    parameter.include_in_ptc_ucn == "Yes" ? true : false
  end
  
  ####################################################################
  # Function:      evalute_showhide_exp
  # Parameters:    page_param
  # Return:        count
  # Renders:       None
  # Description:   Evaluating show or hide expression
  ####################################################################
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
  
  ####################################################################
  # Function:      get_exp_value
  # Parameters:    expression
  # Return:        expression value
  # Renders:       None
  # Description:   To get expression value
  ####################################################################
  def get_exp_value(expr)
    if(expr.downcase == 'true')
      return true
    elsif(expr.downcase == 'false')
      return false
    elsif(!expr.index('(').nil? && !expr.index(')').nil? && expr != '(NULL)' && expr != '(LINE)')
      dynamic_expr = true
      expr_name = expr.split('(')[0]
      expression = Expression.find(:first, :conditions => ['mcfcrc = ? and layout_index =? and expr_name like ?', Gwe.mcfcrc, Gwe.physical_layout, "#{expr_name}%"], :select => 'expr, expr_name')
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
      return (result.to_i() == 1 || result.to_i() == -1) ? true : false
    else
      return false
    end
  end

  ####################################################################
  # Function:      get_expression
  # Parameters:    expression
  # Return:        expression
  # Renders:       None
  # Description:   get expression with dynamic values
  ####################################################################
  def get_expression (expr_param_names, expr_param_values, expr)
    param_names = expr_param_names.split("(")[1].split(")")[0].split(",")
    param_values = expr_param_values.split("(")[1].split(")")[0].split(",")
    param_names.each_with_index do |p, index|      
      expr.gsub!("{" + p.strip + "}", param_values[index])  if !p.blank? && !param_values[index].blank?
    end
    expr
  end  

  ####################################################################
  # Function:      eval_expression
  # Parameters:    expression
  # Return:        true/false
  # Renders:       None
  # Description:   Fetching expression result from existing hash object else calculation new
  ####################################################################
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
  
  ####################################################################
  # Function:      scale_integer_value
  # Parameters:    bound, integer parameter object
  # Return:        bound value
  # Renders:       None
  # Description:   scale integer value
  ####################################################################
  def scale_integer_value(bound, integer_parameter)
   (bound.to_f * (integer_parameter.scale_factor.to_f/1000)).to_i if integer_parameter
  end

  ####################################################################
  # Function:      dec2bin
  # Parameters:    number
  # Return:        binary value
  # Renders:       None
  # Description:   convert decimal to binary
  ####################################################################
  def dec2bin(number)
    number = Integer(number);
    if(number == 0)
      return 0;
    end
    ret_bin = "";
    ## Untill val is zero, convert it into binary format
    while(number > 0)
      ret_bin = String(number % 2) + ret_bin;
      number = number / 2;
    end
    return ret_bin;
  end
  
  ####################################################################
  # Function:      get_signed_value
  # Parameters:    value, size
  # Return:        signed value
  # Renders:       None
  # Description:   Get signed value
  ####################################################################
  def get_signed_value(value, size)
    signed_num = (dec2bin(value).to_i && dec2bin(size).to_i).to_i
    flag = false
    if(signed_num > 0 )
      # convert the value to original value
      case size.to_i
        when 8
        if ((value.to_i & 0x80) != 0 )
          value = value & 0x7F
          flag = true
          return value *= -1          
        end
        when 16
        if ((value.to_i & 0x8000) != 0)
          value = value.to_i & 0x7FFF
          flag = true
          return value *= -1
        end
        when 32
        if ((value.to_i & 0x80000000) != 0)
          value = value & 0x7FFFFFFF
          flag = true
          return value *= -1
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
  
  ####################################################################
  # Function:      get_signed_to_unsigned
  # Parameters:    value, size
  # Return:        unsigned value
  # Renders:       None
  # Description:   Get unsigned value
  ####################################################################
  def get_signed_to_unsigned(value, size)    
    if(value < 0 )
      case size.to_i
        when 8
          return (value * -1) + 0x80
        when 16
          return (value * -1) + 0x8000
        when 32
          return (value * -1) + 0x80000000
        else
          return (value * -1) + 0x8000
      end
    else
      return value
    end
  end
  
  def get_page_name(menu)
    menu.link.blank? ? menu.page_name : menu.link
  end  
  
  def get_links(page_name)
    if !page_name.blank?
      page_links = Menu.all(:conditions => ["mcfcrc = ? and page_name Like ? and link Like '{%' and enable Not Like 'false' and target Not Like 'LocalUI' and link Not Like '{SEAR}'", Gwe.mcfcrc, page_name], 
                       :order => 'display_order', :select => "menu_name, link, parent, page_name, show, enable")
    end
    content_html = ""
    link_menu_name = ""
    link_name = ""
    if !page_links.blank?
      content_html += image_tag('u170_line.png')
      page_links.each do |link_parm|
        link_menu_name = '"' + link_parm.menu_name + '"'
        link_name = '"' + link_parm.link + '"'    
        content_html += '<div id="serial_outer" class="serial_outer">'
        if @ui_state.blank?
          content_html += "<div class='serialleft contentCSPlabel text_type'><span class='no_param_menu_link' onclick = 'open_newwindow(" + link_menu_name + ',' + link_name + ");'>" + link_parm.menu_name + "</span></div>"
        else
          content_html += "<div class='serialleft contentCSPlabel text_type'><span class='param_menu_link' onclick = 'open_newwindow(" + link_menu_name + ',' + link_name + ");'>" + link_parm.menu_name + "</span></div>"
        end
        content_html += "<span class='ucn_protected'>&nbsp;"      
        content_html += "</span>"
        content_html += "<div class='serialright text_type'>" + "</div>"
      content_html +="</div>"
      end
      if @ui_state.blank?
        content_html +="<div id='div_link_ui_state' class='no_presence'></div>"
      end
    end
    return content_html
  end
    
  def check_user_presence_state(page_parameter, is_ucn_protected)
    # @ui_state.blank? ? true : !eval_expression(page_parameter.enable)
    !eval_expression(page_parameter.enable)
  end
  
  def check_ucn_protected(parameter)
    parameter.include_in_ucn == "Yes" ? true : false    
  end
  
  ####################################################################
  # Function:      update_rt_parameter
  # Parameters:    parameters
  # Return:        None
  # Renders:       JSON
  # Description:   Updating RT parameters based on user input
  #################################################################### 
  def update_rt_parameter(parameter_name, card_index, parameter_type, parameter_index, current_value)
      value = ""
      parameter_mcf = Parameter.find(:first, :conditions => {:mcfcrc => Gwe.mcfcrc, :cardindex => card_index, :name => parameter_name, :parameter_type => parameter_type})
      if(parameter_mcf.data_type == "IntegerType")
        integer_params = parameter_mcf.integertype[0]
        if integer_params.signed_number.to_s == 'Yes' && current_value < 0
          factor = 1
          unless integer_params.nil?
            factor = (integer_params.scale_factor.to_f / 1000).to_f
          end
          factor_value = (current_value.abs.to_f * factor).to_f
          value = get_dispsigned_value(factor_value, integer_params.size)
        else
          value = current_value
        end
      else
        value = current_value
      end
      RtParameter.update_all("current_value = #{value.to_i}", :mcfcrc => Gwe.mcfcrc, :card_index => card_index,
                              :parameter_type => parameter_type, :parameter_index => parameter_index)
  end

  # validate select options based on expression
  def validate_options(parameter, expr, rt_paramter=nil)
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
        enum_expr = EnumeratorExpression.find(:first, :select => 'expr_name',
                  :conditions => {:mcfcrc => Gwe.mcfcrc, :expr_map_name => expr, :enumerator_name => enumerator.long_name})
        if (!enum_expr.blank?)
          if (@valid_expr_params[enum_expr.expr_name].blank?)
            evl = eval_expression(enum_expr.expr_name)
            @valid_expr_params[enum_expr.expr_name] = evl
          else
            evl = @valid_expr_params[enum_expr.expr_name]
          end
        else
          evl = false  
        end 
        #evl = eval_expression(enum_expr.expr_name)        
        valid_option  = enum_expr && evl
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
  
  def update_PTC_Devices(flg_signal, flg_switch, flg_hazd)
    siteptcdb = session[:cfgsitelocation]+"/site_ptc_db.db"
    if (File.exist?(siteptcdb))
      (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = siteptcdb
      inst_name = Installationtemplate.find(:first).try(:InstallationName)      
      gc_name = ""
      if (!inst_name.blank?)
        gc_name = Gcfile.find(:first, :conditions =>"InstallationName Like '#{inst_name}'").try(:GCName)
        if (flg_signal)
          #***update signals***
          flg_signal = update_signal(inst_name, gc_name)
        end
        if (flg_switch)
          #update switches
          flg_switch = update_switch(inst_name, gc_name)
        end
        if (flg_hazd)
          #update hazard detectors
          flg_hazd = update_hazard(inst_name, gc_name)
        end
        if (flg_signal || flg_switch || flg_hazd)
          order_elements_positions
        end
      end
    end
  end
  
  def update_signal(inst_name, gc_name)
    prev_sig_id = ""
    signal_count = 0
    flg_update = false
    device_name = ""
    sig_heads = RtParameter.find(:all, :conditions => ["mcfcrc = ? and Current_value >0 and (parameter_name Like 'G%_HA' OR parameter_name Like 'G%_HB' OR parameter_name Like 'G%_HC')",  Gwe.mcfcrc])
    if !sig_heads.blank?
      sig_heads.each do |sigHead|
        sig_id = sigHead.parameter_name.split("_")[0].gsub("G","")
        if (prev_sig_id != sig_id)
          signal_count = signal_count + 1
        end
        prev_sig_id = sig_id 
      end
    end  
    ptc_sig_count = Signals.find_by_sql("select Count(s.Id) as count from PTCDevice as p , Signal as s where s.Id = p.Id and p.InstallationName='#{inst_name}'")
    if signal_count > ptc_sig_count[0].count.to_i
      add_sig_count = signal_count - ptc_sig_count[0].count.to_i
      for ind in 1..add_sig_count
        device_name = "Signal" + (ptc_sig_count[0].count.to_i + ind).to_s
        newid = Ptcdevice.create_ptc_device(999,0,device_name,inst_name,device_name,3,"Increasing",gc_name, (ptc_sig_count[0].count.to_i + ind).to_s)
        Signals.create_signal(newid,4,0)
      end
      flg_update = true
    elsif signal_count < ptc_sig_count[0].count.to_i
      del_sig_count = ptc_sig_count[0].count.to_i - signal_count
      for ind in 1..del_sig_count
        max_id = Ptcdevice.find(:first,:select=>"Id",:conditions =>"Id =(select max(Id) from Signal)").try(:Id)
        Ptcdevice.destroy_all("Id = #{max_id.to_i}")
        Signals.delete_all("Id = #{max_id.to_i}")
      end
      flg_update = true
    end
    # if (flg_update)
      # order_elements_positions
    # end
    return flg_update
  end
  
  def update_switch(inst_name, gc_name)
    switch_count = 0
    flg_update = false
    rt_switch_count = RtParameter.find(:first,:select => "current_value", :conditions => ["mcfcrc = ? and parameter_name Like 'W_Num'",  Gwe.mcfcrc])
    if (!rt_switch_count.blank?)
      switch_count = rt_switch_count["current_value"].to_i/2
      ptc_switch_count = Switch.find_by_sql("select Count(s.Id) as count from PTCDevice as p , Switch as s where s.Id = p.Id and p.InstallationName='#{inst_name}'")
      
      if (switch_count > ptc_switch_count[0].count.to_i)
        add_switch_count = switch_count - ptc_switch_count[0].count.to_i
        for ind in 1..add_switch_count
          device_name = "Switch" + (ptc_switch_count[0].count.to_i + ind).to_s
          newid = Ptcdevice.create_ptc_device(999,0,device_name,inst_name,device_name,3,"LF",gc_name, (ptc_switch_count[0].count.to_i + ind).to_s)
          Switch.create_switch(newid,1,2)
        end
        flg_update = true
      elsif (switch_count < ptc_switch_count[0].count.to_i)
        del_switch_count = ptc_switch_count[0].count.to_i - switch_count
        for ind in 1..del_switch_count
          max_id = Ptcdevice.find(:first,:select=>"Id",:conditions =>"Id =(select max(Id) from Switch)").try(:Id)
          Ptcdevice.destroy_all("Id = #{max_id.to_i}")
          Switch.delete_all("Id = #{max_id.to_i}")
        end
        flg_update = true
      end      
    end
    return flg_update
  end
  
  def update_hazard(inst_name, gc_name)
    hazard_count = 0
    flg_update = false
    rt_hazard_count = RtParameter.find(:first,:select => "current_value", :conditions => ["mcfcrc = ? and parameter_name Like 'HD_Num'",  Gwe.mcfcrc])
    if (!rt_hazard_count.blank?)
      hazard_count = rt_hazard_count["current_value"].to_i
      ptc_hazard_count = Hazarddetector.find_by_sql("select Count(s.Id) as count from PTCDevice as p , HazardDetector as s where s.Id = p.Id and p.InstallationName='#{inst_name}'")
      
      if (hazard_count > ptc_hazard_count[0].count.to_i)
        add_hazard_count = hazard_count - ptc_hazard_count[0].count.to_i
        for ind in 1..add_hazard_count
          device_name = "HzDetector" + (ptc_hazard_count[0].count.to_i + ind).to_s
          newid = Ptcdevice.create_ptc_device(999,0,device_name,inst_name,device_name,3,"Increasing",gc_name, (ptc_hazard_count[0].count.to_i + ind).to_s)
          Hazarddetector.create_hazard(newid,1)
        end
        flg_update = true
      elsif (hazard_count < ptc_hazard_count[0].count.to_i)
        del_hazard_count = ptc_hazard_count[0].count.to_i - hazard_count
        for ind in 1..del_hazard_count
          max_id = Ptcdevice.find(:first,:select=>"Id",:conditions =>"Id =(select max(Id) from HazardDetector)").try(:Id)
          Ptcdevice.destroy_all("Id = #{max_id.to_i}")
          Hazarddetector.delete_all("Id = #{max_id.to_i}")
        end
        flg_update = true
      end      
    end
    return flg_update
  end
  
  def get_GEO_expr
    if ((session[:typeOfSystem].to_s == 'iVIU') || (session[:typeOfSystem].to_s == 'iVIU PTC GEO') || (session[:typeOfSystem].to_s == 'VIU'))
      return 1
    else
      return 0
    end
  end

  def set_ui_expr_variables()
   if(PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE)
      val = 0
      p = RtParameter.find(:first, :conditions => { :parameter_name => "PasswordActive" })
      if p
       val = p.current_value
      end
      if (session[:typeOfSystem].to_s == 'GCP')
        session[:envvarmap] = {"$WebUI" => 1, "$GEO" => (get_GEO_expr), "$OffLine" => 1, "$SuperPasswordMatch" => 1, "$DTSupportsSuperPassword" => 1, "$SafeMode" => 0, "$PasswordMatch" => 1}
      else
        if val == 2 # Password Active
          session[:envvarmap] = {"$WebUI" => 0, "$GEO" => (get_GEO_expr), "$OffLine" => 1, "$SafeMode" => 0, "$PasswordMatch" => 1}
        else
          session[:envvarmap] = {"$WebUI" => 0, "$GEO" => (get_GEO_expr), "$OffLine" => 1, "$SafeMode" => 0, "$PasswordMatch" => 0}
        end  
      end
    else
      session[:envvarmap]  = {"$WebUI" => 1, "$GEO" => 0, "$OffLine" => 0, "$SafeMode" => 1, "$PasswordMatch" => 1}
    end
  end
  
  def remotesin_enabled    
    vital_link = ""
    rdax_link = ""
    dax_link = ""
    vital_link1 = ""
    remote_sin_flag = false
    
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
    
    return remote_sin_flag    
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
  
end
