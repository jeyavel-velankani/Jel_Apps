module McfHelper
  CommandSetParameter = 1
  CommandScreenCRC = 2
  CommandSetEditMode = 3
  CommandIsEditMode = 4
  
  ParamPhysicalLayout = "PhysicalLayoutIndex"
  
  def delete_set_prop_iviu_request
    if session[:setproprequest]
      card = SetPropIviuCard.find_all_by_request_id(session[:setproprequest])
      card.each do |c|
        SetPropIviuParam.delete_all(["id_card = ?", c.id_card])
      end
      SetPropIviuCard.delete_all(["request_id = ?",session[:setproprequest]])
      SetCfgPropertyiviuRequest.delete_all(["request_id = ?",session[:setproprequest]])
    end
  end
  
  def delete_verify_screen_iviu_request
    if session[:verifyscreenrequest]
      VerifyDataIviuRequest.delete_all() #(["request_id = ?",session[:verifyscreenrequest]])
      VerifyScreenIviuRequest.delete_all() #(["request_id = ?",session[:verifyscreenrequest]])
    end
  end
  
  def delete_simple_request
    if session[:set_edit_mode_request]
      RrSimpleRequest.delete_all(["request_id = ?",session[:set_edit_mode_request]])
    end
  end
  
  def get_current_enum_value(page_param)
    val = 0
    if page_param
      p = RtParameter.find(:first, :conditions => ["mcfcrc = ? and card_index = ? and parameter_type = ? and parameter_index = ?",
      session[:mcfcrc],
      page_param.card_index,
      page_param.parameter_type,
      page_param.parameter[0].parameter_index])
      if p
        val = p.current_value
      else
        val = page_param.parameter[0].default_value
      end
    end
    return val
    # return page_param.parameter[0].getEnumerator(val)
  end
  
  def check_signed_value(size, pval)
    
    if pval < 0
      pval *= -1 
    else
      return pval
    end
    
    case size
      when 8
      pval = pval & 0x7FFF
      pval += 128
      return pval
      
      when 16
      pval = pval & 0x7FFF
      pval += 32768
      return pval
      
      when 32
      pval = pval & 0x7FFFFFFF
      pval += 2147483648
      return pval
    end
    
  end
  
  def get_current_integer_value(page_param)
    parameterindex = page_param.parameter[0].parameter_index
    if page_param
      p = RtParameter.find(:first, :conditions => ["mcfcrc = ? and card_index = ? and parameter_type = ? and parameter_index = ?",
      session[:mcfcrc],
      page_param.card_index,
      page_param.parameter_type,
      parameterindex])
      if p
        factor = 1
        check_for_signed = false
        if page_param.parameter[0].integertype[0] != nil
          factor = (page_param.parameter[0].integertype[0].scale_factor.to_f / 1000).to_f
          if page_param.parameter[0].integertype[0].signed_number == 'Yes'
            check_for_signed = true
          end
        end
        val = p.current_value.to_f * factor
        if check_for_signed == true
          val = get_signed_value(val.abs , page_param.parameter[0].integertype[0].size) 
        end
        
        #val = get_signed_value(val, page_param.parameter[0].integertype[0].size) if check_for_signed == true
        
        return val.to_i
      end
      return page_param.parameter[0].default_value
    end
  end
  
  def get_signed_valuegeo(value, size)
    value = value.to_i
    signed_num = (dec2bin(value).to_i && dec2bin(size).to_i).to_i
    if(signed_num < 0 )
      # convert the value to original value
      case size.to_i
        when 8
        value = value.to_i & 0x7F
        return value *= -1
        when 16
        value = value.to_i & 0x7FFF
        return value *= -1
        when 32
        value = value.to_i & 0x7FFFFFFF
        return value *= -1
      end
      return value *= -1
      # else
      #      return value
    end
  end
  

  
  def get_dispsigned_value(value, size)                                                     
    signed_num = (dec2bin(value).to_i && dec2bin(size).to_i).to_i
    if(signed_num > 0 )                                                                                        
      # convert the value to original value                      
      case size.to_i                      
        when 8                                                                                             
        value = value.to_i | 0x80         
        return value                                                     
        when 16                        
        value = value.to_i | 0x8000
        return value                   
        when 32                        
        value = value.to_i | 0x800000 
        return value   
      end                                                                          
      return value                                                                                                             
    else                                
      return value                                                        
    end                                    
  end        
  
  def to_signed(bits)
    mask = (1 << (bits - 1)) 
     (self & ~mask) - (self & mask)
  end
  
  def get_current_parameter_enum_value(param)
    val = 0
    if page_param
      p = RtParameter.find(:first, :conditions => ["mcfcrc = ? and card_index = ? and parameter_type = ? and parameter_index = ?",
      session[:mcfcrc],
      param.cardindex,
      param.parameter_type,
      param.parameter[0].parameter_index])
      if p
        val = p.current_value
      else
        val = param.parameter[0].default_value
      end
    end
    #return val
    return param.parameter[0].getEnumerator(val)
  end
  
  def page_name_to_url(page_name)
    s = page_name
    if page_name
      s = page_name.sub('.',"_____")
    end
    return s
  end
  
  def url_to_page_name(page_name)
    s = page_name
    if page_name
      s = page_name.sub("_____",'.')
    end
    return s
  end
  
  def next_page(page)
    if page
      return page_name_to_url(page.next)
    end
  end
  
  def prev_page(page)
    if page
      return page_name_to_url(page.prev)
    end
  end
  
  def alt_next_page(page)
    if page
      return page_name_to_url(page.alt_next)
    end
  end
  
  def alt_prev_page(page)
    if page
      return page_name_to_url(page.alt_prev)
    end
  end
  
  def get_page_name()
    if @page != nil
      return @page.page_name
    end
    return nil
  end
  
  def scale_value(value, param)
    val = value
    if param
      val = (value.to_f * (param.parameter[0].integertype[0].scale_factor.to_f/1000)).to_i
    end
    return val
  end
  
  def scale_down_value(value, param)
    val = value
    if param!=nil && param.integertype[0]!=nil
      val = (value.to_f * (1000 / param.integertype[0].scale_factor.to_f)).to_i
    end
    return val
  end
  
  def disable_parameter_update()
    if @rtsession
      if !(@rtsession.comm_status == 1 && @rtsession.status == 10)
        # disabled changes
        return true
      end
    end
    
    if @page
      if @page.page_parameter
        @page.page_parameter.each do |f|
          if f.parameter[0]
            if (f.parameter[0].enum_type_name != "") || (f.parameter[0].integertype[0])
              return false
            end
          end
        end
      end
    end
    return true
  end
  
  def display_ucn_protected(param)
   (param && param.include_in_ucn == "Yes") ? true : false
  end
  
  def display_appcrc_protected(param)
    if param
      if (param.IncludeInAppCRC == "Yes") && (OCE_MODE == 1)
        return true
      end
    end
    return false 
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
  
  def get_current_parameter_value(param)
    if param
      mcfcrc = (PRODUCT_TYPE == 2)? Gwe.mcfcrc : session[:mcfcrc]
      rt_parameter = RtParameter.find(:first, :conditions => ["mcfcrc = ? and card_index = ? and parameter_type = ? and parameter_name = ?",
      mcfcrc, param.card_index, param.param_type, param.param_name])
      rt_parameter.nil? ? 0 : rt_parameter.current_value
    end
  end
  
  
  def check_user_presence(geo)
    ui_state = geo ? Uistate.find_by_name_and_geo_value('local_user_present', 1) : Uistate.find_by_name_and_value('local_user_present', 1) 
    if(ui_state) 
      return true
    end
    return false
  end
  
  def get_enable_expr(page_param, ucn_protected=false)
    if session[:curr_atcs]
      @rtsession = RtSession.find_by_atcs_address(session[:curr_atcs])
    end
    return true if @rtsession.nil? || @rtsession.comm_status != 1 || @rtsession.status != 10
    if @is_in_safe_mode.blank?
      if(session[:cur_geo_atcs_addr].nil?)
        atcs_addr = (session[:curr_atcs].nil?)? nil : session[:curr_atcs][0, session[:curr_atcs].length-3]
      else
        atcs_addr = session[:cur_geo_atcs_addr]
      end
      @is_in_safe_mode = !Uistate.find_by_name_and_value_and_sin("local_user_present", 1, atcs_addr).nil?
    end
    
    #if OCE_MODE == 0
    e = Expression.find_by_expr_name(page_param.enable)
    if e
      session[:envvarmap]["$SafeMode"] = (@is_in_safe_mode)? 1:0
      r = evaluatePostfixExpr(e.expr, method(:getOperandValue)) 
      if OCE_MODE == 0
        return (r.to_i() == 1)? false:true
      else
        return (r.to_i() == 1)? false:true
        #        return false
      end  
    end
    #end
    return true
  end
   
  # cleaned up the code - Kalyan
  def get_show_exp(page_param)
    if page_param
      expr = page_param.show
      unless expr.blank?
        expression = Expression.find_by_expr_name(expr, :select => 'expr')
        return (expression && (evaluatePostfixExpr(expression.expr, method(:getOperandValue)).to_i != 0)) ? true : false
      else
        return false
      end
    end  
    return true
  end
  
  # cleaned up the code - Kalyan
  def get_showhide_exp(page_param)
    count = 0
    page_param.each do |page_parameter| 
      expr = page_parameter.show
      unless expr.blank?
        if expr.to_s == 'true'
          count += 1
        else
          expression = Expression.find_by_expr_name(expr)
          count += 1 if expression && evaluatePostfixExpr(expression.expr, method(:getOperandValue)).to_i != 0
        end
      end
    end unless page_param.blank?
    count
  end
  
  def show_expr_html(page_param)
    #return ""
    if get_show_exp(page_param)
      return "color:#FFFFFF;"    
    end
    return "display:none;"
  end
  
  def get_validate_exp(page_param)
    if page_param
      expr = page_param.validate
      e = Expression.find_by_expr_name(expr)
      if e
        r = evaluatePostfixExpr(e.expr, method(:getOperandValue))
        #        puts "Validate Expression(#{e.expr})= #{r}"
        if r.to_i() == 1
          return false
        end
        return true
      end
    end    
    return false    
  end
  
  def validate_expr_html(page_param)
    if get_validate_exp(page_param)
      return ""
    end
    return "display:none;"
  end
  
  def validate_options_for_select(page_param)
    if page_param
      expr = page_param.validate()
      if expr
        page_param.parameter[0].enumerator.map{|e| 
          enumexpr = EnumeratorExpression.find(:first, 
                  :conditions => ["mcfcrc = ? and expr_map_name = ? and enumerator_name = ?",session[:mcfcrc],expr.strip(),e.long_name.strip()])
          if enumexpr
            r = evaluatePostfixExpr(enumexpr.expr_name, method(:getOperandValue))
            #puts "Validate Expression(#{enumexpr.expr_name})= #{r}"
            if r.to_i() == 1
              [e.long_name, e.value]
            end
          end
        }
      end
      page_param.parameter[0].enumerator.map{|e| [e.long_name, e.value]}
    end
  end
  
  def set_enviroment_variables
    session[:envvarmap]  = {"$GEO" => 1, 
                            "$OffLine" => 0,
                            "$PasswordMatch" => 1,
                            "$SafeMode" => 0}
    
    session[:envvarmap]["$GEO"] = 1
    @cartridge = Cartridge.find_by_id(0) #Console VCPU.
    if @cartridge
      if @cartridge.configured_status.to_i == 1
        session[:envvarmap]["$SafeMode"] = 0
      else
        session[:envvarmap]["$SafeMode"] = 1
      end
      #puts "Console VCPU cartridge found. safe mode=#{session[:envvarmap]["$SafeMode"]}"
    end
    
  end
  
  
  def menu_enable(pagename)
    @pagename = pagename
    val =  Menu.find(:first,:conditions=>['link=?',@pagename ])
    # val =  Treemenu.find(:first,:conditions=>['name=?',@pagename ])
    return val
  end
  
  
end
