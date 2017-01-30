module IoparamsHelper
  include McfHelper
  #####  Generalized  Method to Load Parameters  #####
  
  def IOparameters_def(page)
    @page = page
    ret =""
    if @page.page_parameter 
      ret += "<div id='error_explanation2_header' style='display:none;'><h3>Parameter Invalid:</h3></div>"
      ret += "<div id='error_explanation2' style='display:block;'>"
      @page.page_parameter.each do |e| 
        if e.parameter[0].name               
          ret +="<div id="
          ret += "err_"+e.parameter[0].name
          ret += "></div>"
        end
      end
      ret +="</div>"
    end
    
    ret += "<table class='mytable' width='100%'><tr><td>"
    
    if @page      
      if @page.page_parameter 
        if session[:cur_geo_atcs_addr]
          @page.page_parameter.each do |f| 
            if f.parameter.size > 0 && f!= nil 
              ret +="<tr  style="
              ret+= show_expr_html(f)
              ret +="><td width='20'>"
              is_ucn_protected = false
              if display_appcrc_protected(f.parameter[0])
                ret += image_tag('ProtectedApprovalCrc.gif')
              elsif display_ucn_protected(f.parameter[0])
                ret += image_tag('ProtectedMethods.gif')
                is_ucn_protected = true              
              end
              #   ucncheck(f.parameter[0])
              
              ret += "</td>"
              ret += "<td>"
              ret += f.parameter[0].param_long_name
              ret += display_units(f.parameter[0])
              ret += "</td>" 
              if f.parameter[0].enum_type_name != ""
                ret += "<td>"
                if session[:cur_geo_atcs_addr]
                  ret += select_tag(f.parameter[0].name, options_for_select(set_legend_for_default_value_from_enum(f.parameter[0].enumerator, f.parameter[0]), get_current_enum_value(f).to_i),:class=>'contentCSPsel',:disabled => get_enable_expr(f, is_ucn_protected))
                else
                  ret += select_tag(f.parameter[0].name, options_for_select(f.parameter[0].enumerator.map{|e| [e.long_name, e.value]},get_current_enum_value(f).to_i),:class=>'contentCSPsel',:disabled => get_enable_expr(f, is_ucn_protected))
                end
                ret += "</td><td>"
                ret +=  image_submit_tag '../images/update_arte.png', :class => "update_geo_mcf", :onclick => "loadingscreen(); on_update_enum_param_value("+f.parameter[0].layout_index.to_s+","+f.parameter[0].layout_type.to_s+","+"'"+f.parameter[0].name+"',"+f.parameter[0].cardindex.to_s+","+f.parameter[0].parameter_index.to_s+","+f.parameter[0].parameter_type.to_s+"); start_set_prop_request('" + f.parameter[0].name + "');" ,:id => get_page_name(), :page_name => get_page_name(), :ui_command => '1', :saving=>'yes', :editmode => 2
                ret+= "</td>"
              else
                if f.parameter[0].integertype[0]
                  ret += "<td>"
                  
                  upper_bound = scale_value(f.parameter[0].integertype[0].upper_bound,f)
                  
                  #upper_bound = get_signed_value(upper_bound, f.parameter[0].integertype[0].size)
                  upper_bound = upper_bound.to_s
                  
                  lower_bound = scale_value(f.parameter[0].integertype[0].lower_bound,f)
                  
                  if f.parameter[0].integertype[0].signed_number == 'Yes' 
                    lower_bound = get_signed_value(lower_bound, f.parameter[0].integertype[0].size)
                  end
                  
                  lower_bound = lower_bound.to_s
                  
                  ret += text_field_tag f.parameter[0].name, get_current_integer_value(f), :id=>f.parameter[0].name,:p=>f, :style=>"width:196px;", :disabled => get_enable_expr(f, is_ucn_protected) , :onblur => "validate_int_param('"+f.parameter[0].name + "','" + f.parameter[0].param_long_name + "'," + lower_bound + "," + upper_bound + ");", :class=>'contentCSPsel', :id => f.parameter[0].name
                  
                  #ret += text_field_tag f.parameter[0].name, get_current_integer_value(f), :id=>f.parameter[0].name,:p=>f, :style=>"width:196px;", :disabled => get_enable_expr(f, is_ucn_protected) , :onblur => "validate_int_param('"+f.parameter[0].name + "','" + f.parameter[0].param_long_name + "'," + scale_value(f.parameter[0].integertype[0].lower_bound,f).to_s + "," + scale_value(f.parameter[0].integertype[0].upper_bound,f).to_s + ");", :class=>'contentCSPsel', :id => f.parameter[0].name
                  ret += "</td><td>"
                  ret += image_submit_tag('../images/update_arte.png', :class => "update_geo_mcf", :id => f.parameter[0].name+'control', :name=>'submit', :onclick => "loadingscreen(); get_int_param_value("+f.parameter[0].layout_index.to_s+","+f.parameter[0].layout_type.to_s+","+"'"+f.parameter[0].name+"',"+f.parameter[0].cardindex.to_s+","+f.parameter[0].parameter_index.to_s+","+f.parameter[0].parameter_type.to_s+"); start_set_prop_request('" + f.parameter[0].name + "')" , :ui_command => '1', :editmode => 2)
                  ret += "</td>"
                end
                ret +="</tr>"
              end
            end   
          end
        else
          @page.page_parameter.each do |f| 
            if f.parameter.size > 0 && f!= nil 
              ret +="<tr  style="
              ret += show_expr_html(f)
              ret +="><td width='20'>"
              is_ucn_protected = false              
              if display_appcrc_protected(f.parameter[0])
                ret += image_tag('ProtectedApprovalCrc.gif')
              elsif display_ucn_protected(f.parameter[0])
                ret += image_tag('ProtectedMethods.gif')
                is_ucn_protected = true
              end
              #   ucncheck(f.parameter[0])
              
              ret += "</td>"
              ret += "<td>"
              ret += f.parameter[0].param_long_name
              ret += display_units(f.parameter[0])
              ret += "</td>" 
              if f.parameter[0].enum_type_name != ""
                ret += "<td>"
                if session[:cur_geo_atcs_addr]
                  ret += select_tag(f.parameter[0].name, options_for_select(set_legend_for_default_value_from_enum(f.parameter[0].enumerator, f.parameter[0]), get_current_enum_value(f).to_i), :class=>'contentCSPsel', :disabled => get_enable_expr(f, is_ucn_protected))
                else
                  ret += select_tag(f.parameter[0].name, options_for_select(f.parameter[0].enumerator.map{|e| [e.long_name, e.value]},get_current_enum_value(f).to_i), :class=>'contentCSPsel', :disabled => get_enable_expr(f, is_ucn_protected))
                end
                ret += "</td>"
              else
                if f.parameter[0].integertype[0]
                  ret += "<td>"
                  
                  upper_bound = scale_value(f.parameter[0].integertype[0].upper_bound,f).to_s
                  lower_bound = scale_value(f.parameter[0].integertype[0].lower_bound,f).to_s
                  if f.parameter[0].integertype[0].signed_number == 'Yes' 
                    lower_bound = get_signed_value(lower_bound, f.parameter[0].integertype[0].size)
                    upper_bound = get_signed_value(upper_bound, f.parameter[0].integertype[0].size)
                  end
                  lower_bound = lower_bound.to_s
                  upper_bound = upper_bound.to_s
                  # Capturing the user activity and validating onblur
                  # Respective javascript function can be found in public/javascripts/mcf_script.js
                  ret += text_field_tag f.parameter[0].name, get_current_integer_value(f),:onblur => "validate_int_param('"+f.parameter[0].name + "','" + f.parameter[0].param_long_name + "'," + lower_bound + "," + upper_bound + ");", :id => f.parameter[0].name, :class=>'contentCSPsel', :disabled => get_enable_expr(f, is_ucn_protected)
                  ret += "</td><td>"
                  
                  ret += "</td>"
                end
                ret +="</tr>"
              end
            end   
          end
        end
        
      end
    end
    
    if @request_id 
      if @verify_screen || session[:verify_screen] 
        if OCE_MODE == 0
          # ret += periodically_call_remote(:url => {:controller => "mcfiviu", :action =>  "check_verify_screen_state", :id => @request_id}, :update => "check_screen", :frequency => 3, :condition => "check_verify_screen_condition()") 
        end
      elsif @set_edit_mode
        ret += periodically_call_remote(:url => {:controller => "mcfiviu", :action =>  "check_set_edit_mode_state", :id => @request_id}, :update => "check_set_edit_mode", :frequency => 3, :condition => "check_set_edit_mode_condition()") 
      elsif @set_to_default 
        ret += periodically_call_remote(:url => {:controller => "mcfiviu", :action =>  "check_set_to_default", :id => @request_id}, :frequency => 3, :condition => "check_set_to_default()")
      else 
        if OCE_MODE == 0
          ret += periodically_call_remote(:url => {:controller => "mcfiviu", :action =>  "check_state", :id => @request_id}, :update => "check", :frequency => 3, :condition => "check_condition()") 
        end
      end
    end
    
    
    if flash[:notice] 
      ret += "<div id='notice'>"
      ret += flash[:notice]
      ret += "</div>"
    end
    
    ret += "</table>"
  end
  #####  Generalized  Method to Load Parameters Ends  #####
  
  def set_legend_for_default_value_from_enum(enum, parameter)
    sel_values = enum.map do |e|
      if(parameter.default_value.to_s == e.value.to_s)
        [e.long_name + "  *  ", e.value]
      else
        [e.long_name, e.value]
      end
    end
    return sel_values
  end                
end
