=begin
  Class: LogicView
  Description: To find out logical view and ladder logic view
=end

class LogicViewController < ApplicationController
  
  include ProgrammingHelper
  include McfHelper
  include UdpCmdHelper
  include ExpressionHelper 
  include SessionHelper
  
  before_filter :cpu_status_redirect  #session_helper
  
  # Method to load Logic state view
  def index
    parameter_names, internal_states = get_logic_state_parameter_names
    cards = Card.all(:conditions => {:crd_type => [18, 21, 93, 20], :cdf => ['GCPAPPLN.CDF', 'OPMAP.CDF', 'RDAX.CDF', 'IPMAP.CDF']}, 
                     :select => 'distinct card_index, crd_type')
    rt_parameters = RtParameter.all(:select => "parameter_name, current_value, card_index, parameter_type", 
                    :conditions => {:parameter_name => parameter_names, :mcfcrc => Gwe.mcfcrc, :card_index => cards.map(&:card_index)})
    @parameters = {}
    rt_parameters.each do |rt_parameter|
      @parameters[rt_parameter.parameter_name] = {:current_value => rt_parameter.current_value, :parameter => rt_parameter}
    end
    parameters = Parameter.all(:conditions => {:name => internal_states, :mcfcrc => Gwe.mcfcrc})
    @internal_states = {}   
    parameters.each do |parameter|
      rt_parameter_current_value = @parameters[parameter.name][:current_value]
      enum_long_name = EnumeratorsMcf.find(:first, :select =>"long_name", :conditions => {:enum_type_name => parameter.enum_type_name, :value => rt_parameter_current_value}).try(:long_name) || ""
      @internal_states[parameter.name] = {:long_label => parameter.param_long_name, :label => enum_long_name, :current_value => rt_parameter_current_value}
    end
    
    # 3 = advance prempt not used
    # 2 = advance prempt used
    # 1 = simult 
    @AdvancePreemptUsed = (@parameters["AdvancePreemptUsed"][:current_value]==2 ? true : false)
    @SimultaneousPreemptOutputUsed = (@parameters["AdvancePreemptUsed"][:current_value]==1? true : false)
    
    render :partial => 'logic_details' if request.xhr?
  end
  
  # method to get ladder logic view
  def detail_logic_view
    @@term_map_temp = {}
    @@equations_temp = {}
    @parent_name = ""
    
    if(params[:history_flag].blank?)
      if (params[:page_history].blank?)
        @prev_history = get_history
      else
        @prev_history = params[:page_history].to_s + "^^" + get_history  
      end
    else
      @prev_history = params[:page_history].to_s
    end
    
    if !(params[:logic_type].blank?)
      @display_logic_type = params[:logic_type].to_s
    else
        @display_logic_type = ""
    end
    
    if (@display_logic_type == "param")
      @rung = Rung.find_by_param(params[:parameter_name], :conditions => {:mcfcrc => Gwe.mcfcrc, :card_index => params[:card_index]})
      @parent_name = params[:parameter_name].to_s
    else
      @rung = Rung.find(:first, :conditions => {:mcfcrc => Gwe.mcfcrc, :term => params[:term_name], :card_index => params[:card_index]})
      @parent_name = params[:term_name].to_s
    end
    @term_map = {}
    @ls_numbers = {}
    if @rung
      @equations = @rung.equation.split(",").collect{|equation| equation.strip }
      terms = @equations.select{|i| i if i.match(/^[a-zA-Z0-9_@.-]*$/)}
      @terms = Term.get_terms(terms)
      mnemonics = Mnemonic.all(:conditions => {:mnemonic => terms, :mcfcrc => Gwe.mcfcrc})
      @term_map = evaluate_term_expression(mnemonics)
      parameters = Parameter.get_parameters(@terms.map(&:param))
      @term_state_lsno = []
      construct_term_map(parameters)
      # initiating LS number request for the terms
      ############## 0: for onload, 1: for refresh #####################
      if request.xhr?
        @ls_req_id = params[:req_id]
        ls_numbers = RrLsSpecificRequest.find(:all, :select => "ls_number", :conditions => {:request_id => @ls_req_id}, :order => "id").map(&:ls_number)
        @ls_numbers = load_ls_numbers(@ls_req_id, ls_numbers, 1)
      else
        @ls_req_id, ls_numbers = initiate_ls_no_request
        @ls_numbers = load_ls_numbers(@ls_req_id, ls_numbers, 0)
      end
      @@term_map_temp = @term_map
      @@equations_temp = @equations
    end
    
    if request.xhr?
      logic_view_content = render_to_string(:partial => 'detail_logic_view')
      render :json => { :logic_view_content => logic_view_content}
    end    
  end
  
  def refresh_detail_logic_view
    @term_map = @@term_map_temp
    @equations = @@equations_temp
    @ls_req_id = params[:req_id]
    ls_numbers = RrLsSpecificRequest.find(:all, :select => "ls_number", :conditions => {:request_id => @ls_req_id}, :order => "id").map(&:ls_number)
    @ls_numbers = load_ls_numbers(@ls_req_id, ls_numbers, 1)
    
    logic_view_content = render_to_string(:partial => 'detail_logic_view')
    render :json => { :logic_view_content => logic_view_content}
  end
  
  def get_history
    #parameter_name='+parameter_name+'&card_index='+card_index+'&parameter_type='+parameter_type + '&logic_type=param';
    #term_name='+term_name+'&card_index='+card_index + '&logic_type=term' + "&page_header=" + page_header;
    if !(params[:logic_type].blank?)
      logic_type = params[:logic_type].to_s
    else
      logic_type = ""
    end
    if (logic_type == "param")
      str_name = params[:parameter_name].to_s
    else
      str_name = params[:term_name].to_s
    end
    
    if(!params[:page_header].blank?)
      page_header = params[:page_header].to_s
    else
      page_header = ""
    end
    str_params =  params[:logic_type].to_s + "|" + str_name + "|" + params[:card_index].to_s + "|" + page_header
    return str_params
  end
  
  private
  
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
  
  # method to load ls numbers from RT database into a Hash object
  def load_ls_numbers(req_id, lsnumbers, req_type)
    ls_no = {}
    ls_index = 0
    if (req_type == 0)
      ls_number_values = RrIsReplies.find(:all, :select => "is_value", :conditions => {:request_id => req_id}, :order => "reply_id").map(&:is_value)
      if (ls_number_values.blank?)
        ls_number_values = RtLogicState.ls_number_values(atcs_address, req_id)
      end      
    elsif (req_type == 1)
      ls_number_values = RtLogicState.ls_number_values(atcs_address, req_id)
      if (ls_number_values.blank?)
        ls_number_values = RrIsReplies.find(:all, :select => "is_value", :conditions => {:request_id => req_id}, :order => "reply_id").map(&:is_value)
      end
    else
      ls_number_values = nil
    end
    if (!ls_number_values.blank?)
      ls_number_values.each do |number|
        ls_no[lsnumbers[ls_index]] = number
        ls_index = ls_index + 1
      end
    end    
    ls_no
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
  
  def get_state_params_lsno(state)
    str_param = ""
    term_state = {}    
    #state = "IntAND1EnableDropDelayRunning?green_timer:(IntAND1EnablePickupDelayRunning?timer:(IntAND1EnablePickup?green:red))"
    state_with_lsno = state
    state.split(//).each do |chr|
      case chr
      when "?"
        mnemonic = Mnemonic.find_by_mnemonic(str_param.strip, :conditions => {:mcfcrc => Gwe.mcfcrc}, :select => "lsno") 
        lsno = mnemonic ? mnemonic.lsno : 0
        #term_state[str_param.strip] = lsno
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
  
  # Method to get required parameter names for Logic view
  def get_logic_state_parameter_names
    parameter_names = []
    internal_states = []
    
     (1..16).each do |i|
      parameter_names << ["GCPAppCPU.AND#{i}", "GCPAppCPU2.AND#{i}", "GCPAppCPU.ANDEnable#{i}", "GCPAppCPU2.ANDEnable#{i}", "AND#{i}Used", "AND#{i}EnableUsed", "OR#{i}Used", "GCPOutputApplnMap.OR#{i}OP","AND#{i}WrapUsed", "GCPAppCPU.AND#{i}Wrap", "GCPAppCPU2.AND#{i}Wrap"]
      internal_states << ["InternalState#{i}Input", "InternalState#{i}Output", "GCPVPIMap.InternalIP#{i}", "GCPVPIMap.InternalIP#{i}Used",
                          "GCPOutputApplnMap.InternalOP#{i}", "GCPOutputApplnMap.InternalOP#{i}Used"]
    end
    parameter_names << internal_states
    parameter_names << ["GCPAppCPU.PreemptHealthIP", "GCPAppCPU.TrafficHealthIP", "GCPAppCPU.AdvPreemptInput", 
                       "GCPAppCPU.AdvPreemptOutput", "GCPAppCPU.SimPreemptOutput", "GCPAppCPU.AdvPreemptXRActivation", "GCPAppCPU.MaintCall",
                       "AdvancePreemptUsed","AdvancePreemptIPUsed", "TrfSysHealthIPUsed","PreemptHealthIPUsed"]
    return parameter_names.flatten, internal_states.flatten
  end
  
  # Method to initiate a request to update Logic state numbers
  def initiate_ls_no_request
    lsnumbers = []
    
    @term_map.each_value do |value|
      if value[:show]
        @term_state_lsno << value[:lsno]
      end
    end
    request_id = RrIsRequests.ladder_logic_ls_no_request(@term_state_lsno, atcs_address + ".01")
    udp_send_cmd(REQUEST_COMMAND_LS, request_id)
    request_state = check_request_state(request_id)
    timer = ZERO
    until request_state == REQUEST_STATE_COMPLETED
      timer += 1
      request_state = check_request_state(request_id)
      request_state = REQUEST_STATE_COMPLETED if timer == 10
    end
    @term_state_lsno.uniq.sort.each do |value|
        lsnumbers << value
    end
    return request_id, lsnumbers
    #@term_map.map{|k, v| v[:lsno] if v[:show] }
  end
  
  # Method to check the state of the logic state
  def check_request_state(request_id)
    sleep 1
    rr_is_request = RrIsRequests.find(request_id, :select => "request_state")
    return REQUEST_STATE_COMPLETED if rr_is_request.nil?
     (rr_is_request && rr_is_request.request_state == REQUEST_STATE_COMPLETED) ? REQUEST_STATE_COMPLETED : ZERO
  end
  
end
