module ExpressionHelper
    
  def clear
    @ParamInfo ||= Struct.new('ParameterInfo',:count, :param_name, :card_index, :param_type,:param_value) 
    @listExpr = Array.new;
    #@listExpr.clear();
  end
  
  def readPostfix(strExpr)  
    clear
    terms = strExpr.split(',')
    terms.each do |t|
      @listExpr.push(t.strip)
    end
    return true  
  end
  
  def evaluateExpr(getOperandValue)
    listExprStack = Array.new
    strTerm = ""
    for strTerm in @listExpr
      strTerm = strTerm.strip
      if (isOperator(strTerm))
        processOperator(strTerm, listExprStack, getOperandValue)
      else
        listExprStack.unshift(strTerm)
      end
    end
  
    if (listExprStack.size == 1)
      return listExprStack.pop
    else
      return INVALID_EXPR
    end
  end

  def evaluatePostfixExpr(strExpr, getOperandValue)
    if !readPostfix(strExpr)
      return INVALID_EXPR
    end
    return evaluateExpr(getOperandValue);
  end

  def processOperator(strTerm, listExprStack,getOperandValue)
    strRetVal = ""
  
    #puts "Processing operator: #{strTerm}"
    if strTerm.casecmp("++") == 0       # Add
      arg1 = listExprStack.shift()
      arg2 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      v2 = getOperandValue.call(arg2)
  
      strRetVal = v2.to_() + v1.to_i()
      #puts "Result: #{v1} + #{v2} = #{strRetVal}"
      listExprStack.unshift(strRetVal)
    elsif (strTerm.casecmp("-") == 0)     # Subtract
      arg1 = listExprStack.shift()
      arg2 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      v2 = getOperandValue.call(arg2)
  
      strRetVal = v2.to_i() - v1.to_i()
      #puts "Result: #{v1} - #{v2} = #{strRetVal}"
      listExprStack.unshift(strRetVal)
    elsif (strTerm.casecmp("**") == 0)      # Multiply
      arg1 = listExprStack.shift()
      arg2 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      v2 = getOperandValue.call(arg2)
  
      strRetVal = v2.to_i() * v1.to_i()
      #puts "Result: #{v1} ** #{v2} = #{strRetVal}"
      listExprStack.unshift(strRetVal);
    elsif (strTerm.casecmp("/") == 0)     # Divide
      arg1 = listExprStack.shift()
      arg2 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      v2 = getOperandValue.call(arg2)
  
      strRetVal = v2.to_i() / v1.to_i()
      #puts "Result: #{v1} / #{v2} = #{strRetVal}"
      listExprStack.unshift(strRetVal);
    elsif ((strTerm.casecmp("&&") == 0) || (strTerm.casecmp("*") == 0))   # Logical And
      arg1 = listExprStack.shift()
      arg2 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      v2 = getOperandValue.call(arg2)
  
      strRetVal = (((v2.to_i()!=0) && (v1.to_i()!=0))  ? 1 : 0).to_s
      #puts "Result: #{v1} && #{v2} = #{strRetVal}"
      listExprStack.unshift(strRetVal);
    elsif ((strTerm.casecmp("||") == 0) || (strTerm.casecmp("+") == 0))   # Logical Or
      arg1 = listExprStack.shift()
      arg2 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      v2 = getOperandValue.call(arg2)
      
      strRetVal = ((v2.to_i != 0 || v1.to_i != 0) ? 1 : 0).to_s
      #puts "Result: #{v1} || #{v2} = #{strRetVal}"
      listExprStack.unshift(strRetVal);
    elsif (strTerm.casecmp("!") == 0)     # Logical Not
      arg1 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      strRetVal = ((!v1.to_i())  ? 1 : 0).to_s
      listExprStack.unshift(strRetVal);
      #puts "Result: !#{v1} = #{strRetVal}"
    elsif ((strTerm.casecmp("&") == 0) || (strTerm.casecmp("^") == 0))      # Bitwise And
      arg1 = listExprStack.shift()
      arg2 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      v2 = getOperandValue.call(arg2)
  
      strRetVal = v2.to_i() & v1.to_i()
      listExprStack.unshift(strRetVal);
      #puts "Result: #{v1} & #{v2} = #{strRetVal}"
    elsif strTerm.casecmp("|") == 0    # Bitwise Or
      arg1 = listExprStack.shift()
      arg2 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      v2 = getOperandValue.call(arg2)
  
      strRetVal = v2.to_i() | v1.to_i()
      listExprStack.unshift(strRetVal);
      #puts "Result: #{v1} | #{v2} = #{strRetVal}"
    elsif (strTerm.casecmp("~") == 0)     # Bitwise Not
      arg1 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      strRetVal = ((~v1)  ? 1 : 0).to_s
      listExprStack.unshift(strRetVal);
      #puts "Result: ~#{v1} = #{strRetVal}"
    elsif (strTerm.casecmp("==") == 0)    # Logical Or
      arg1 = listExprStack.shift()
      arg2 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      v2 = getOperandValue.call(arg2)
  
      strRetVal = ((v2.to_i() == v1.to_i()) ? 1 : 0).to_s
      #puts "arg1=#{v1} == arg2=#{v2} = #{strRetVal}"
      listExprStack.unshift(strRetVal);
      #puts "unshift: #{strRetVal}"
    elsif (strTerm.casecmp("!=") == 0)    # Logical Or
      arg1 = listExprStack.shift()
      arg2 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      v2 = getOperandValue.call(arg2)
  
      strRetVal = ((v2.to_i() != v1.to_i())  ? 1 : 0).to_s
      listExprStack.unshift(strRetVal);      
      #puts "Result: #{v1} != #{v2} = #{strRetVal}"
    elsif ((strTerm.casecmp("<=") == 0) || (strTerm.casecmp("LE") == 0))    # Logical Or
      arg1 = listExprStack.shift()
      arg2 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      v2 = getOperandValue.call(arg2)
  
      strRetVal = ((v2.to_i() <= v1.to_i())  ? 1 : 0).to_s
      listExprStack.unshift(strRetVal);
      #puts "Result: #{v1} <= #{v2} = #{strRetVal}"
    elsif ((strTerm.casecmp(">=") == 0) || (strTerm.casecmp("GE") == 0))    # Logical Or
      arg1 = listExprStack.shift()
      arg2 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      v2 = getOperandValue.call(arg2)
  
      strRetVal = ((v2.to_i() >= v1.to_i())  ? 1 : 0).to_s
      listExprStack.unshift(strRetVal);
      #puts "Result: #{v1} >= #{v2} = #{strRetVal}"
    elsif ((strTerm.casecmp("<") == 0) || (strTerm.casecmp("LT") == 0))   # Logical Or
      arg1 = listExprStack.shift()
      arg2 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      v2 = getOperandValue.call(arg2)
  
      strRetVal = ((v2.to_i() < v1.to_i())  ? 1 : 0).to_s
      listExprStack.unshift(strRetVal);
      #puts "Result: #{v1} < #{v2} = #{strRetVal}"
    else ((strTerm.casecmp(">") == 0) || (strTerm.casecmp("GT") == 0))   # Logical Or
      arg1 = listExprStack.shift()
      arg2 = listExprStack.shift()
      v1 = getOperandValue.call(arg1)
      v2 = getOperandValue.call(arg2)
  
      strRetVal = ((v2.to_i() > v1.to_i())  ? 1 : 0).to_s
      listExprStack.unshift(strRetVal);
      #puts "Result: #{v1} > #{v2} = #{strRetVal}"
    end
  end

  def isOperator(strTerm)
    r = 
      strTerm.casecmp("=") == 0 || strTerm.casecmp("+") == 0 || strTerm.casecmp("-") == 0 || 
      strTerm.casecmp("^") == 0 || 
      strTerm.casecmp("++") == 0 || strTerm.casecmp("**") == 0 || 
      strTerm.casecmp("*") == 0 || strTerm.casecmp("/") == 0 || 
      strTerm.casecmp("!") == 0 || strTerm.casecmp("&") == 0 || 
      strTerm.casecmp("|") == 0 || strTerm.casecmp("~") == 0 || 
      strTerm.casecmp("&&") == 0 || strTerm.casecmp("||") == 0 || 
      strTerm.casecmp("==") == 0 || strTerm.casecmp("!=") == 0 || 
      strTerm.casecmp("<=") == 0 || strTerm.casecmp(">=") == 0 || 
      strTerm.casecmp("LE") == 0 || strTerm.casecmp("GE") == 0 || 
      strTerm.casecmp("<") == 0 || strTerm.casecmp(">") == 0 ||
      strTerm.casecmp("LT") == 0 || strTerm.casecmp("GT") == 0 ||
      strTerm.casecmp("AND") == 0 || strTerm.casecmp("OR") == 0 
    
    return r
  end
  
  #################################
  # input operand
  # returns number of operands
  #################################
  def extranctOperandInfo(sOperand)
    sParamName = ""
    nCardIndex = 0
    nParamType = 0
    sValName = ""
    
    sOperand.delete!("\n"," ")
    sOperand.delete!("\r"," ")
    sOperand.delete!("\t"," ")
    sOperand.strip!
    
    aOperands = sOperand.split('.')
    if aOperands.size > 0
      sParamName = aOperands[0].strip.gsub(" ", "")
    end
    if aOperands.size > 1
      nCardIndex = aOperands[1]
    end
    if aOperands.size > 2
      nParamType = parameter_type_to_s(aOperands[2])
    end
    if aOperands.size > 3
      sValName = aOperands[3].strip()
    end
    #@ParamInfo = Struct.new('ParameterInfo',:count, :param_name, :card_index, :param_type,:param_value)
    @ParamInfo.new(aOperands.size, sParamName, nCardIndex, nParamType,sValName)
  end
  
  def check_include_expr_helper()
    return "<b> Hello expression helper.</b>"
  end
  
  def parameter_type_to_s(sParamName)
    case sParamName
    when "VitalCardConfig"
      return 1
    when "CardConfig"
      return 2
    when "Status"
      return 3
    when "Command"
      return 4
    when "SWSettings"
      return 5
    when "CardDiag"
      return 6
    when "LocalConfig"
      return 7
    when "DefaultCardConfig"
      return 8
    when "HWConfig"
      return 9
    when "SWSettings2"
      return 10
    when "SATCommand"
      return 11
    when "SATStatus"
      return 12
    when "SATConfig"
      return 13
    when "RouteConfig"
      return 14
    end
  end
  
  def parameter_type_to_data_kind(nParamType)
    case nParamType.to_i
    when VitalConfiguration
      return DataKindVCfg
    when NonVitalConfiguration
      return DataKindNVCfg
    when Status
      return DataKindStatus
    when Command
      return DataKindCommand
    when LCfg
      return DataKindLocalCfg
    when SATCfg
      return DataKindSATCfg
    when SATRouteCfg
      return DataKindRouteCfg
    end
  end
  
end
