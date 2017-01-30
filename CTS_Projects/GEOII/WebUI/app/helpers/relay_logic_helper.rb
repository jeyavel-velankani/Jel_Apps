module RelayLogicHelper
include ProgrammingHelper
  
 def createGLfile(fileName)
   relay_equations = generateRelayLogic
   File.open(fileName, "w+"){|fw|
        fw.puts " "
        fw.puts 'SAT GCP CPU3 Relay [desc="GCP CPU3 Relay Logic"]'
        fw.puts " "
        fw.puts '# CONNECTIONS'
        fw.puts 'CONNECTION ba [desc=""]'
        fw.puts '# EQUATIONS'
        fw.puts 'EXECUTE ONEVERYITERATION'
        fw.puts " "
        if !relay_equations.blank?
          relay_equations.uniq.each do |equ|
            if !equ.blank?
              fw.puts "   " + equ.gsub(',', '') + ";"
            end
          end
        end
        fw.puts "ENDSAT"
     }
 end
 def generateRelayLogic
   param_names = get_relay_logic_parameters
   gwe_mcfcrc = Gwe.mcfcrc
   cards = Card.all(:conditions => {:crd_type => [18, 21, 93, 20], :cdf => ['GCPAPPLN.CDF', 'OPMAP.CDF', 'RDAX.CDF', 'IPMAP.CDF']}, 
                     :select => 'distinct card_index, crd_type')
   #rt_parameters = RtParameter.all(:select => "parameter_name, current_value, card_index, parameter_type", 
   #                 :conditions => {:parameter_name => parameter_names, :mcfcrc => Gwe.mcfcrc, :card_index => cards.map(&:card_index)})
   
   # rt_parameters.each do |rt_parameter|
     # #relay_parameters[rt_parameter.parameter_name] = {:current_value => rt_parameter.current_value, :parameter => rt_parameter}
#      
   # end

    relay_parameters = Rung.find(:all, :conditions => {:mcfcrc => gwe_mcfcrc, :card_index => cards.map(&:card_index)})
    temp_equation = []
   # puts "***********************************************"
     if !relay_parameters.blank?
        relay_parameters.each do |relay_equ|
    #      puts relay_equ.equation.inspect
          temp_equation << get_logic_equation(relay_equ.equation, gwe_mcfcrc)  
        end
     end
    return temp_equation
 end
  
 def get_relay_logic_parameters
    parameter_names = []
    
    (1..16).each do |i|
      parameter_names << ["GCPAppCPU.AND#{i}", "GCPAppCPU2.AND#{i}", "GCPOutputApplnMap.OR#{i}OP"]
    end
    
    return parameter_names.flatten
    
 end
 
 def get_logic_equation(rung_equation, gwe_mcfcrc)
   term_map = {}
   ls_numbers = {}
   @expression_structure ={}
    if rung_equation
      @equations = rung_equation.split(",").collect{|equation| equation.strip }
      #puts equations.inspect
      temp_term = Term.get_terms(@equations[0], gwe_mcfcrc)
      if !temp_term.blank?
        show_value = eval_expression(temp_term[0][:show]) ? true : false
      end
      return if (show_value == false || show_value == "false")
      temp_terms = @equations.select{|i| i if i.match(/^[a-zA-Z0-9_@.-]*$/)}
      #puts "********************************************"
      #puts temp_terms.inspect
      @terms = Term.get_terms(temp_terms, gwe_mcfcrc)
      #puts "terms: " + @terms.inspect
      mnemonics = Mnemonic.all(:conditions => {:mnemonic => temp_terms, :mcfcrc => Gwe.mcfcrc})
      @term_map = evaluate_term_expression(mnemonics)
      parameters = Parameter.get_parameters(@terms.map(&:param))
      #puts "parameters: " + parameters.inspect
      @term_state_lsno = []
      construct_term_map(parameters)
      #puts "@term_map: " + @term_map.inspect      
      #puts ls_numbers.inspect
      #puts @ls_numbers.inspect
      #puts "Equation: " + @equations.inspect
    end
    #puts @equations.inspect
    
    postFixEquation = post_to_infix
    long_equ = ""
    if !postFixEquation.blank?
      postFixEquation.split(',').each do |trm|
        long_equ = long_equ + ((@term_map[trm].blank? || @term_map[trm][:label].blank?) ? trm : @term_map[trm][:label].strip.gsub(' ', '_'))
      end 
      main_term = ((@term_map[@equations[0]].blank? || @term_map[@equations[0]][:label].blank?) ? trm : @term_map[@equations[0]][:label].strip.gsub(' ', '_'))
      
      relay_equation = main_term + " = " + long_equ
    else
      main_term = ((@term_map[@equations[0]].blank? || @term_map[@equations[0]][:label].blank?) ? trm : @term_map[@equations[0]][:label].strip.gsub(' ', '_'))      
      relay_equation = main_term + " = False"
    end
    return relay_equation
   
 end
 
 def post_to_infix
    stack = []
    expr = ""
    #expr = IntAND1,   nvcAND1Used,!, IntAND1EnablePickup, IntAND1T1,*,IntAND1T2,*, IntAND1T3,*,IntAND1T4,*, IntAND1T5,*,IntAND1T6,*, IntAND1Wrap,+, IntXngOutOfService,+, IntEmergencyCutout,*,*,IntAND1XngTestNo,*, IntPreemptHlth ,*,=
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
                  # if (x.strip == "+")
                    # stack.push "(,empty_or,#{x},#{op2},)"
                  # else
                     stack.push "#{op2}"
                  # end
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
  
  # Method to update the show status of the term by evaluating When Clause expression
  def construct_term_map(parameters)
    @term_map.each_pair do |key, term|
      if term && term[:state].upcase == "(NULL)" && term[:term_map].upcase != "(NULL)" && term[:show]     
        begin
          term[:enum_long_name] = parameters[term[:param]]
        rescue Exception
          term[:enum_long_name] = nil
        end
        
        clause = Clause.when_clause(term[:term_map], term[:enum_long_name])
        clause_term = Term.find_by_name(clause.term, :conditions => {:mcfcrc => Gwe.mcfcrc}) if clause
        if clause_term
          mnemonic = Mnemonic.find_by_mnemonic(clause_term.name, :conditions => {:mcfcrc => Gwe.mcfcrc}, :select => "lsno")  
          term[:show] = (eval_expression(clause_term.show) ? true : false)
          term[:state] = clause_term.state
          term[:name] = clause_term.name
          term[:long_name] = clause_term.long_name
          term[:label] = clause_term.label
          term[:lsno] = mnemonic ? mnemonic.lsno : clause_term.lsno
        else
          term[:show] = false
        end
        term[:state] = get_state_params_lsno(term[:state].to_s)
      elsif term && term[:show] && term[:state].upcase != "(NULL)"
        term[:state] = get_state_params_lsno(term[:state].to_s)
      end
    end
  end
  
  
  def get_state_params_lsno(state)
    str_param = ""
    term_state = {}    
    #state = "IntAND1EnableDropDelayRunning?green_timer:(IntAND1EnablePickupDelayRunning?timer:(IntAND1EnablePickup?green:red))"
    #puts "state: " + state.inspect
    state_with_lsno = state
    state.split(//).each do |chr|
      case chr
      when "?"
        #puts "str_param: " + str_param.inspect
        mnemonic = Mnemonic.find_by_mnemonic(str_param.strip, :conditions => {:mcfcrc => Gwe.mcfcrc}, :select => "lsno") 
        lsno = mnemonic ? mnemonic.lsno : 0
        #term_state[str_param.strip] = lsno
        #puts lsno.inspect
        if lsno > 0
          @term_state_lsno << lsno
          state_with_lsno = state_with_lsno.gsub(str_param.strip+"?", lsno.to_s+"?")
        end
        str_param = ""
      when "("
        str_param = ""
      when ")"
        str_param = ""
      else
          str_param = str_param + chr
      end
    end
    return state_with_lsno
  end

  # Method to load all required terms into a Hash object if expression evaluation of each term is true
  def evaluate_term_expression(mnemonics)
    @expression_structure = {}
    term_map = {}
    @terms.each do |term|      
      show_value = eval_expression(term.show) ? true : false
      mnemonic = mnemonics.find{|m| m.mnemonic == term.name }     
      lsno = mnemonic ? mnemonic.lsno : term.lsno
      term_map[term.name] = {:show => show_value, :long_name => term.long_name, :label => term.label,      
                            :param => term.param, :state => term.state, :term_map => term.term_map, :lsno => lsno, :name => term.name, :card_index =>term.card_index, :enum_long_name =>""}
    end
    term_map
  end
  
  def is_equation(str_param)
    if ((str_param).include?("+") || (str_param).include?("*") || (str_param).include?("!"))
      return true
    else
      return false
    end
  end

end
