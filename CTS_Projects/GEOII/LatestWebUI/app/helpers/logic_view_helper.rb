module LogicViewHelper
  
  def get_term_name(rung)
    term_name = '&nbsp;'
    term_name = @term_map[rung[:name]][:label].strip if (rung && @term_map.has_key?(rung[:name]) && @term_map[rung[:name]][:show])    
    term_name
  end
  
  def get_term_state(rung, equation)
    state_val = ""
    lsno = ""
    color_code = ""
    img_state = ""
    if (rung && @term_map.has_key?(rung[:name]))
      lsno = @term_map[rung[:name]][:lsno]
      term_state = @term_map[rung[:name]][:state]
      state_val = eval_state(term_state)   #...Temporarily Commented this code...
      #state_val = ""
    else
      lsno = ""
      term_state = ""
      state_val = ""
    end
    if ((state_val.strip == "red") || (state_val.strip == "green"))
      color_code = state_val.strip + "_"
    else
      color_code = ""
    end
    
    if equation.eql?("*") || equation.eql?("+")
     img_state = (@ls_numbers[lsno] == "1" ? "url(/images/ladder_logic/" + color_code + "normal-relay-energised.png)" : "url(/images/ladder_logic/" + color_code + "normal-relay-denergised.png)")
    elsif equation.eql?("!")
     img_state = (@ls_numbers[lsno] == "1" ? "url(/images/ladder_logic/" + color_code + "not_relay_energised.png)" : "url(/images/ladder_logic/" + color_code + "not_relay_de_energised.png)")
    end
    return img_state, state_val
    
  end
  
  def eval_state(term_state)
    #state = "IntAND1EnableDropDelayRunning?green_timer:(IntAND1EnablePickupDelayRunning?timer:(IntAND1EnablePickup?green:red))"
    # if term_state.include?("(")
      # sub_states = term_state.split("(")
      # sub_term = sub_states[sub_states.length - 1]
      # sub_term = sub_term[0..(sub_term.index(')') - 1)]
    # end
    sub_term_value = ""
    while term_state.include?('(')
      sub_states = term_state.split('(')
      sub_term = sub_states[sub_states.length - 1]
      sub_term = sub_term[0..(sub_term.index(')') - 1)]
      sub_term_value = validate_sub_state(sub_term)
      term_state = term_state.gsub("(" + sub_term + ")", sub_term_value)
    end
    
    sub_term_value = validate_sub_state(term_state)
    return sub_term_value      
  end
  
  def validate_sub_state(sub_state)
    state = ""
    str_lsno = ""
    if (sub_state.include?("?"))
      str_lsno = sub_state[0..(sub_state.index("?") - 1)]
    end
    
    if(str_lsno.length > 0)
      state_value = sub_state[sub_state.index("?")+1..sub_state.length].split(":")
      if (@ls_numbers[str_lsno.to_i] == "1")
        state = state_value[0]
      else
        state = state_value[1]
      end
    end
    return state
  end
  
  def post_to_infix
    stack = []
    expr = ""
    #puts @term_map.inspect
    #expr = "nvcT1P1Used,!, SttT1P1P,      IntT1P1UAXR,*, IntT1ADVPreemptAND1,*, IntT1GCPInactive,TET1WrapPickup,+,+, IntT1PredictorOverrideR   ,+, nvcT1P1Offset, IntT1Island,+, IntT1IslInactive, IntT1IslWrap,+,+,*,*"
    for i in 1..@equations.size - 2
      if(expr.length > 0)
        expr = expr + "," + @equations[i]
      else
        expr = @equations[i]
      end 
    end    
    
    if (@equations.size == 3)
      if (!@term_map[expr].blank? && @term_map[expr][:show])
        stack.push "#{expr}"
      end
    else      
      expr.split(',').each do |x|
        case x.strip
          when *%w{+ *}
            st_size = stack.size
            op2 = stack.pop
            op1 = stack.pop
            if !op1.blank?
              op1 = op1.strip
              if op1.include?('!')
                term_arr = op1.split(',')
                if (term_arr[1] == '!')
                  if (!(!@term_map[term_arr[2]].blank? && @term_map[term_arr[2]][:show]))
                    op1 = ""
                  end
                end
              end
            end
            if !op2.blank?
              op2 = op2.strip
              if op2.include?('!')
                term_arr = op2.split(',')
                if (term_arr[1] == '!')
                  if (!(!@term_map[term_arr[2]].blank? && @term_map[term_arr[2]][:show]))
                    op2 = ""
                  end
                end
              end 
            end
            if st_size >=  2
              if(is_equation(op1) && is_equation(op2))
                stack.push "(,#{op1},#{x},#{op2},)"
              elsif ((is_equation(op1) == false) && is_equation(op2))
                if (!@term_map[op1].blank? && @term_map[op1][:show])
                  stack.push "(,#{op1},#{x},#{op2},)"
                else
                  stack.push "#{op2}"
                end
              elsif (is_equation(op1) && (is_equation(op2) == false))
                if (!@term_map[op2].blank? && @term_map[op2][:show])
                  stack.push "(,#{op1},#{x},#{op2},)"
                else
                  stack.push "#{op1}"
                end
              else
                if (!@term_map[op1].blank? && !@term_map[op2].blank? && @term_map[op1][:show] && @term_map[op2][:show])
                  stack.push "(,#{op1},#{x},#{op2},)"
                elsif (!@term_map[op1].blank? && @term_map[op1][:show])
                  stack.push "#{op1}"
                elsif (!@term_map[op2].blank? && @term_map[op2][:show])
                  stack.push "#{op2}"
                end
              end
            elsif st_size == 1
              if  (is_equation(op2))
                stack.push "#{op2}"
              else
                if (!@term_map[op2].blank? && @term_map[op2][:show])
                  if (x.strip == "+")
                    stack.push "(,empty_or,#{x},#{op2},)"
                  else
                    stack.push "#{op2}"
                  end
                  
                end            
              end
            end
          when *%w{!}            
            if stack.size == 2
              op = stack.pop.strip
              op1 = stack.pop.strip
              stack.push op1
              #if (!@term_map[op].blank? && @term_map[op][:show])                
                stack.push "(,#{x},#{op},)"
              #end
            else
              op = stack.pop.strip
              #if (!@term_map[op].blank? && @term_map[op][:show])
               stack.push "(,#{x},#{op},)"
              #end
            end
          else
            stack.push x
          end
        end
      end
      stack.pop
  end
  
  def is_equation(str_param)
    if ((str_param).include?("+") || (str_param).include?("*") || (str_param).include?("!"))
      return true
    else
      return false
    end
  end
  
  def draw_logic_view
    elements_hash = design_logic_view
    row_num = -1
    tr_id = ""
    term_name = ""    
    state = ""
    state_val = ""
    sub_eq = ""
    equ = ""
    str_table = ""
    title = ""
    @max_row = 0
    @max_col = 0
    @logic_params = ""
    if(!elements_hash.blank?)
      elements_hash.each do |element|
        if (element[:name].length > 0)
          #term_name = element[:name].to_s
          term_name = get_term_name(element)
          if (element[:type].to_s == "and")
            equ = "*"
          elsif(element[:type].to_s == "or")
            equ = "+"
          elsif(element[:type].to_s == "not")
            equ = "!"
          else
            equ = ""
          end
          if (element[:name].to_s == "empty_or")
            state = "url(/images/ladder_logic/bar.png)"
            state_val = "green"
          else
            state, state_val = get_term_state(element, equ)  
          end
          
          if((element[:name].to_s != "(") && (element[:name].to_s != ")") && (element[:name].to_s != "empty_or"))
            sub_eq = sub_equation_available(@term_map[element[:name].to_s][:name], @term_map[element[:name].to_s][:card_index])
            title = @term_map[element[:name].to_s][:long_name].to_s
          elsif (element[:name].to_s == "empty_or")            
            term_name = ""
            sub_eq =  ""
            title = ""
          else
            sub_eq =  ""
            title = ""
          end          
        else
          term_name = ""        
          sub_eq =  ""
          state = ""     
          title = ""
        end
        if (@logic_params.length > 0)
          @logic_params = @logic_params + "^^" + "#{element[:key].to_s}|#{term_name.to_s}|#{state}|#{element[:type].to_s}|#{sub_eq}|#{title}|#{state_val}"
        else
          @logic_params =   "#{element[:key].to_s}|#{term_name.to_s}|#{state}|#{element[:type].to_s}|#{sub_eq}|#{title}|#{state_val}"
        end
        
        if (@max_row < element[:row].to_i)
          @max_row = element[:row].to_i
        end
        if (@max_col < element[:col].to_i)
          @max_col = element[:col].to_i
        end
      end
    end
    
    if (!@equations.blank?)
      term_name = ""
      state = "url(/images/ladder_logic/bar.png)"
      if (@logic_params.length > 0)
        @logic_params = @logic_params + "^^" + "0-#{(@max_col+1)}|#{term_name.to_s}|#{state}|blank_sp|||"
      else
        @logic_params =   "0-#{(@max_col+1)}|#{term_name.to_s}|#{state}|blank_sp|||"
        end
      term_name = @term_map[@equations[0]][:label].strip
      title = @term_map[@equations[0]][:long_name].to_s
              
      term_state = @term_map[@equations[0]][:state].strip
      state_val = eval_state(term_state)
      if ((state_val.strip == "red") || (state_val.strip == "green"))
        state = "url(/images/ladder_logic/" + state_val.strip + "_output.png)"
      else
        state = "url(/images/ladder_logic/output.png)"
      end
      
      if (@logic_params.length > 0)
        @logic_params = @logic_params + "^^" + "0-#{(@max_col+2)}|#{term_name.to_s}|#{state}|output||#{title}|#{state_val}"
      else
        @logic_params =   "0-#{(@max_col+2)}|#{term_name.to_s}|#{state}|output||#{title}|#{state_val}"
      end
    end
    #str_table = str_table + "</tr>"
    str_table    
  end
  
  def design_logic_view
    v_col = 0
    v_row = 0
    m_row = 0
    opt_type = ""
    loc_elements = []
    open_brc = []
    close_brc = []
    bln_close_or = false
    infix_str = post_to_infix
    #puts "infix_str: " + infix_str.inspect 
    if (!infix_str.blank?)
      #equation =  "(,(,a,*,b,),+,(,c,+,d,),)"
      #equation = "(,(,SttT1P1P,*,IntT1P1UAXR,),*,(,(,nvcT1P1Offset,+,IntT1Island,),+,IntT1IslInactive,),)"
      #equation = "(,(,(,(,SttT1P1P,*,IntT1P1UAXR,),+,IntT1GCPInactive,),*,(,(,nvcT1P1Offset,+,IntT1Island,),+,IntT1IslInactive,),),)"
      equation = "(," + infix_str + ",)"
      bln_skip = false;
      bln_brace = false;
      prev_operator = ""
      current_operator = ""
      #puts "infix_str1: " + equation.inspect 
      str_arr = equation.split(',')
      if (str_arr.length == 3)
        for i in 0..(str_arr.length-1)
          str = str_arr[i].to_s
          case str
          when "("
            opt_type = "open_brc"
            v_col = v_col.to_i + 1
            skey =  v_row.to_s + "-" + v_col.to_s
            loc_elements << {:name => "", :col => v_col.to_s, :row => v_row, :key => skey, :type =>opt_type}
          when ")"
            opt_type = "close_brc"
            v_col = v_col.to_i + 1
            skey =  v_row.to_s + "-" + v_col.to_s
            loc_elements << {:name => "", :col => v_col.to_s, :row => v_row, :key => skey, :type =>opt_type}
          else
            v_col = v_col.to_i + 1
            skey =  v_row.to_s + "-" + v_col.to_s
            loc_elements << {:name => str_arr[i].to_s, :col => v_col.to_s, :row => v_row, :key => skey, :type =>"and"}
          end
        end
      else
        for i in 0..(str_arr.length-1)
          str = str_arr[i].to_s
          if (!bln_skip && str.length > 0)
            case str
            when "*"
              opt_type = "and"
                if(!bln_brace)
                  v_col = v_col.to_i + 1
                  skey =  v_row.to_s + "-" + v_col.to_s
                  loc_elements << {:name => str_arr[i-1].to_s , :col => v_col, :row => v_row, :key => skey, :type =>opt_type}
                else
                  block_begin = open_brc[open_brc.size-1]
                  dim = block_begin.split("-")
                  v_row = dim[0]
                  
                end
                if (!((str_arr[i+1].to_s == "(") || (str_arr[i+1].to_s == ")")))
                  v_col = v_col.to_i + 1
                  skey =  v_row.to_s + "-" + v_col.to_s
                  loc_elements << {:name => str_arr[i+1].to_s , :col => v_col, :row => v_row, :key => skey, :type =>opt_type}
                  bln_skip = true
                else
                  block_begin = open_brc[open_brc.size-1]
                  dim = block_begin.split("-")
                  v_row = dim[0]
                  #tmp_col_open = dim[1] 
                end                
                # if prev_operator == "*"
                  # open_brc.delete_at(open_brc.size-1)
                  # close_brc.delete_at(close_brc.size-1)
                # end
                
              prev_operator = "*"
            when "+"
              opt_type = "or"
              if(!bln_brace)
                if (prev_operator == "+")
                  open_brc.delete_at(open_brc.size-1)
                end
                block_begin = open_brc[open_brc.size-1]
                dim = block_begin.split("-")
                tmp_row_open = dim[0]
                tmp_col_open = dim[1]
                v_col = tmp_col_open.to_i
                if (prev_operator == "+")
                  v_row = tmp_row_open.to_i + 1 
                end
                skey =  v_row.to_s + "-" + v_col.to_s
                loc_elements << {:name => "" , :col => v_col, :row => v_row, :key => skey, :type =>"left_or"}
                
                v_col = v_col.to_i + 1
                skey =  v_row.to_s + "-" + v_col.to_s
                loc_elements << {:name => str_arr[i-1].to_s , :col => v_col, :row => v_row, :key => skey, :type =>opt_type}
                if (prev_operator == "+")
                  if(!close_brc.blank?)
                    end_begin = close_brc[close_brc.size-1]
                    dim = end_begin.split("-")
                    tmp_row_close = dim[0]
                    tmp_col_close = dim[1]
                    v_col = tmp_col_close.to_i
                    v_row = tmp_row_close.to_i + 1
                  else
                    v_col = v_col.to_i + 1
                  end
                else
                  v_col = v_col.to_i + 1
                end
                skey =  v_row.to_s + "-" + v_col.to_s
                #loc_elements << {:name => "" , :col => v_col, :row => v_row, :key => skey, :type =>"right_or"}
                #####################################################################################################
                if (str_arr[i+1].to_s != "(")
                  loc_elements << {:name => "" , :col => v_col, :row => v_row, :key => skey, :type =>"right_or"}
                  v_col = tmp_col_open.to_i
                  v_row = v_row.to_i + 1            
                  skey =  v_row.to_s + "-" + v_col.to_s
                  loc_elements << {:name => "" , :col => v_col, :row => v_row, :key => skey, :type =>"left_or"}
                  
                  v_col = v_col.to_i + 1
                  skey =  v_row.to_s + "-" + v_col.to_s
                  loc_elements << {:name => str_arr[i+1].to_s , :col => v_col, :row => v_row, :key => skey, :type =>opt_type}
                  if (prev_operator == "+" && tmp_col_close.to_i > 0)
                    v_col = tmp_col_close.to_i  
                  else
                    v_col = v_col.to_i + 1
                  end          
                  skey =  v_row.to_s + "-" + v_col.to_s
                  loc_elements << {:name => "" , :col => v_col, :row => v_row, :key => skey, :type =>"right_or"}
                  bln_skip = true                
                else
                  v_col = tmp_col_open.to_i
                  v_row = v_row.to_i + 1 
                  skey =  v_row.to_s + "-" + v_col.to_s
                  loc_elements << {:name => "" , :col => v_col, :row => v_row, :key => skey, :type =>"left_or"}
                  bln_close_or = true
                end
              else
                if (prev_operator != "+")
                  block_begin = open_brc[open_brc.size-1]
                  dim = block_begin.split("-")
                  tmp_row_open = dim[0]
                  tmp_col_open = dim[1]
                  loc_elements << {:name => "" , :col => tmp_col_open, :row => tmp_row_open, :key => block_begin, :type =>opt_type}
  
                  if(!close_brc.blank?)
                    end_begin = close_brc[close_brc.size-1]
                    dim = end_begin.split("-")
                    tmp_row_close = dim[0]
                    tmp_col_close = dim[1]
                    loc_elements << {:name => "" , :col => tmp_col_close, :row => tmp_row_close, :key => end_begin, :type =>opt_type}
                    # if(close_brc.size > 1)
                      # open_brc.delete_at(open_brc.size-2)
                      # close_brc.delete_at(close_brc.size-2)
                    # end
                  else
                    
                  end
                  v_col = tmp_col_open.to_i
                  v_row = m_row.to_i + 1  
                  if(!(str_arr[i+1].to_s == "(" || str_arr[i+1].to_s == ")"))
                    # v_col = tmp_col_open.to_i
                    # v_row = tmp_row_open.to_i + 1            
                    skey =  v_row.to_s + "-" + v_col.to_s
                    loc_elements << {:name => "" , :col => v_col, :row => v_row, :key => skey, :type =>"left_or"}
                    
                    v_col = v_col.to_i + 1
                    skey =  v_row.to_s + "-" + v_col.to_s
                  
                    loc_elements << {:name => str_arr[i+1].to_s , :col => v_col, :row => v_row, :key => skey, :type =>opt_type}
                    v_col = tmp_col_close.to_i
                    v_row = m_row.to_i + 1
                    skey =  v_row.to_s + "-" + v_col.to_s
                    loc_elements << {:name => "" , :col => v_col, :row => v_row, :key => skey, :type =>"right_or"}
                    bln_skip = true
                  end
                else
                  if(!(str_arr[i+1].to_s == "(" || str_arr[i+1].to_s == ")"))
                    block_begin = open_brc[open_brc.size-1]
                    dim = block_begin.split("-")
                    tmp_row_open = dim[0]
                    tmp_col_open = dim[1]                
                    v_col = tmp_col_open.to_i
                    v_row = v_row.to_i + 1
                    skey =  v_row.to_s + "-" + v_col.to_s
                    loc_elements << {:name => "" , :col => v_col, :row => v_row, :key => skey, :type =>"left_or"}
                    
                    v_col = v_col.to_i + 1
                    skey =  v_row.to_s + "-" + v_col.to_s
                    loc_elements << {:name => str_arr[i+1].to_s , :col => v_col, :row => v_row, :key => skey, :type =>opt_type}
                    
                    if(bln_brace)
                      if(!close_brc.blank?)
                        close_brc.delete_at(close_brc.size-1)
                      end
                    end
                    
                    if(!close_brc.blank?)
                      end_begin = close_brc[close_brc.size-1]
                      dim = end_begin.split("-")
                      tmp_row_close = dim[0]
                      tmp_col_close = dim[1]
                      if (tmp_col_close.to_i < v_col)
                        v_col = v_col + 1
                      else
                        v_col = tmp_col_close.to_i  
                      end
                      
                      #v_row = tmp_row_close.to_i + 1
                      skey =  "0-" + v_col.to_s
                      loc_elements << {:name => "" , :col => v_col, :row => "0", :key => skey, :type =>"right_or"}
                      for i_row in 1..(v_row.to_i - 1)
                        skey =  i_row.to_s + "-" + v_col.to_s
                        loc_elements << {:name => "" , :col => v_col.to_s, :row => i_row.to_s, :key => skey, :type =>"vbar"}
                      end
                    else
                      v_col = v_col.to_i + 1
                    end
                    
                    #v_col = v_col.to_i + 1
                    skey =  v_row.to_s + "-" + v_col.to_s
                    loc_elements << {:name => "" , :col => v_col, :row => v_row, :key => skey, :type =>"right_or"}
                  else
                    open_brc.delete_at(open_brc.size-1)                  
                    block_begin = open_brc[open_brc.size-1]
                    dim = block_begin.split("-")
                    tmp_row_open = dim[0]
                    tmp_col_open = dim[1]   
                    v_row = v_row + 1               
                    for i_row in tmp_row_open.to_i..v_row
                      if ((i_row > tmp_row_open.to_i) && (i_row < v_row))
                        skey =  i_row.to_s + "-" + tmp_col_open.to_s
                        loc_elements << {:name => "" , :col => tmp_col_open.to_s, :row => i_row.to_s, :key => skey, :type =>"vbar"}
                      else
                        skey =  i_row.to_s + "-" + tmp_col_open.to_s
                        loc_elements << {:name => "" , :col => tmp_col_open.to_s, :row => i_row.to_s, :key => skey, :type =>"left_or"}
                      end
                    end
                    bln_close_or = true
                    v_col = tmp_col_open.to_i
                  end
                end
              end
              prev_operator = "+"
              m_row = v_row.to_i
            when "!"
              opt_type = "not"
              v_col = v_col.to_i + 1
              skey =  v_row.to_s + "-" + v_col.to_s
              loc_elements << {:name => str_arr[i+1].to_s , :col => v_col, :row => v_row, :key => skey, :type =>opt_type}
              bln_skip = true
              prev_operator = "!"
            when "("
              opt_type = "open_brc"
              v_col = v_col.to_i + 1
              skey =  v_row.to_s + "-" + v_col.to_s
              loc_elements << {:name => "", :col => v_col.to_s, :row => v_row, :key => skey, :type =>opt_type}
              open_brc << skey
              bln_brace = false
              m_row = v_row.to_i
            when ")"
              opt_type = "close_brc"
              bln_brace =  true
              #v_col = v_col.to_i + 1
              #skey =  v_row.to_s + "-" + v_col.to_s
              if (bln_close_or)
                #v_col = v_col.to_i + 1
                skey =  v_row.to_s + "-" + v_col.to_s
                loc_elements << {:name => "" , :col => v_col.to_s, :row => 0, :key => "0-" + v_col.to_s, :type =>"right_or"}
                loc_elements << {:name => "" , :col => v_col.to_s, :row => v_row.to_s, :key => skey, :type =>"right_or"}
                bln_close_or = false
              else
                v_col = v_col.to_i + 1
                skey =  v_row.to_s + "-" + v_col.to_s
                loc_elements << {:name => "", :col => v_col.to_s, :row => v_row.to_s, :key => skey, :type =>opt_type}
              end
              close_brc << skey
            end
          else
            bln_skip = false
          end     #if (!bln_skip)          
        end        #for i in 0..(str_arr.length-1)
      end
    end
    # puts "loc_elements:..."
    # loc_elements.each do |loc|      
      # puts loc.inspect
    # end
    return loc_elements
  end
    
  def current_value(parameter)
    return nil if parameter.nil?
    parameter.has_key?(:current_value) ? parameter[:current_value] : nil
  end
  
  def get_parameter(parameter)
    return nil if parameter.nil?
    parameter.has_key?(:parameter) ? parameter[:parameter] : nil
  end
  
  def get_internal_states(i)
    if @internal_states["InternalState#{i}Input"] && (@internal_states["InternalState#{i}Input"][:label] != 'Not Used' || @internal_states["InternalState#{i}Output"][:label] != 'Not Used')
      "<td id='status_image'>"+get_status_image(@internal_states["GCPVPIMap.InternalIP#{i}"])+"</td><td id='internal_state_enabled' style = 'text-align:left;'>#{internal_state_label(i)}</td>"
    else
      "<td id='status_image'></td><td id='internal_state_enabled'></td>"
    end
  end
  
  def logic_and_state_image(used, state, enabled_used, enabled, wrap_used,wrap)
    if(enabled_used == 1)
      enabled = image_tag("/images/dt/whitecircle_blank_border.png")
    else
      enabled = (enabled == 1) ? image_tag("/images/ladder_logic/green.png", :border => '0') : image_tag("/images/ladder_logic/gray.png", :border => '0') if used && enabled
    end
 
    # AND used = 0 (Yes)
    # Wrap Used = 1 (Yes)
    # And Wrap Used = 0 (Yes)
    
    if used == 0
      and_image = (wrap_used==0 && wrap==1 && state == 1)? image_tag("/images/dt/plainyellowcircle.png", :border => '0') : (state == 1)? image_tag("/images/ladder_logic/green.png", :border => '0') : image_tag("/images/ladder_logic/gray.png", :border => '0')
    else 
      and_image = image_tag("/images/dt/whitecircle_blank_border.png")
    end
    
    if used.nil?
      if @gcp_4000_version
          "<td id='mid1' style='height:25px;'></td><td id='mid2' style='height:25px;'></td>"
      else
          "<td id='mid' style='height:25px;'></td><td id='mid2' style='height:25px;'></td><td id='mid3' style='height:25px;'></td>"
      end
    else
      "<td id='status_image' style='height:25px;'>"+"#{and_image}"+"</td><td id='enabled'>#{enabled}</td>"
    end
    
    #elsif used == 1
    #  enabled = image_tag("/images/dt/whitecircle_blank_border.png")
    #  "<td id='status_image' style='height:25px;'>"+image_tag('/images/dt/whitecircle_blank_border.png')+"</td><td id='enabled'>"+enabled.to_s+"</td>"
    #elsif state == 1
    #  "<td id='status_image' style='height:25px;'>"+"#{and_image}"+"</td><td id='enabled'>#{enabled}</td>"
    #else
    #  enabled = image_tag("/images/ladder_logic/gray.png", :border => '0')
    #  "<td id='status_image' style='height:25px;'>"+image_tag('/images/ladder_logic/gray.png')+"</td><td id='enabled'>#{enabled}</td>"      
    #end
  end
  
  def logic_or_states(used, status, index)   
    if used
      parameter = get_parameter(@parameters["GCPOutputApplnMap.OR#{index}OP"])
      status = (used == 0)? image_tag("/images/dt/whitecircle_blank_border.png", :border => '0') : ((status == 1) ? image_tag("/images/ladder_logic/green.png", :border => '0') : image_tag("/images/ladder_logic/gray.png", :border => '0'))
      if @gcp_4000_version
        "<td id='status_image' style='height:25px;'>#{status}</td><td id='enabled' style='text-align:left;padding-left:3px;'>OR-#{index}</td>"
      else
        if used == 0
        "<td id='status_image'>#{status}</td><td id='enabled' style='text-align:left;padding-left:3px;'>OR-#{index}</td><td id='arrow'>"+link_to(image_tag('/images/ladder_logic/arrow.png', :border => '0', :class => 'disable'), "javascript:", :card_index => parameter.card_index, :parameter_name => "GCPOutputApplnMap.OR#{index}OP", :class => 'detail_logic')+"</td>"  
        else
          "<td id='status_image'>#{status}</td><td id='enabled' style='text-align:left;padding-left:3px;'>OR-#{index}</td><td id='arrow'>"+link_to(image_tag('/images/ladder_logic/arrow.png', :border => '0'), "javascript:", :card_index => parameter.card_index, :parameter_name => "GCPOutputApplnMap.OR#{index}OP", :class => 'detail_logic')+"</td>"
        end
      end
    else
      if @gcp_4000_version
        "<td id='status_image'></td><td id='enabled' style='height:25px;'></td>"
      else
       "<td id='status_image'></td><td id='enabled'></td><td id='arrow'></td>"   
      end
    end
  end
  
  def get_status_image(status)
    if(status.class == Hash)
      status[:current_value] == 1 ? image_tag("/images/ladder_logic/green.png", :border => '0') : image_tag("/images/ladder_logic/gray.png", :border => '0')
    else
      status == 1 ? image_tag("/images/ladder_logic/green.png", :border => '0') : image_tag("/images/ladder_logic/gray.png", :border => '0')
    end
  end
  
  def get_status_image_ex(status, used)
    if used
      if(status.class == Hash)
        status[:current_value] == 1 ? image_tag("/images/ladder_logic/green.png", :border => '0') : image_tag("/images/ladder_logic/gray.png", :border => '0')
      else
        status == 1 ? image_tag("/images/ladder_logic/green.png", :border => '0') : image_tag("/images/ladder_logic/gray.png", :border => '0')
      end
    else
        image_tag("/images/dt/whitecircle_blank_border.png", :border => '0')
    end
  end
  
  def internal_state_label(i)
    long_label = @internal_states["InternalState#{i}Input"][:long_label].split(" ").first
    out_label = @internal_states["InternalState#{i}Output"][:label]
    in_label = @internal_states["InternalState#{i}Input"][:label]
    "#{long_label}: #{out_label} Sets #{in_label}"    
  end
  
  def sub_equation_available(t_name, c_index)
    sub_equation = false
    rungs = Rung.find(:first, :conditions => {:mcfcrc => Gwe.mcfcrc, :term => t_name, :card_index => c_index})
    if rungs.blank?
      rungs = Rung.find(:first, :conditions => {:mcfcrc => Gwe.mcfcrc, :term => t_name})
    end
    
    if(rungs.blank?)
      sub_equation = false
    else
      if(rungs[:equation].blank?)
        sub_equation = false
      else
        sub_equation = true
        c_index = rungs[:card_index]
      end
    end
    
    if (sub_equation)
      # return "class = 'link_sub_equation' term_name = '#{t_name}' card_index = '#{c_index}'"
      return "#{t_name},#{c_index}"
    else
      return ""
    end
    
  end
  
end
