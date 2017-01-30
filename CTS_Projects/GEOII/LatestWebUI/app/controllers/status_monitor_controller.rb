class StatusMonitorController < ApplicationController
  layout 'general'
  require 'date'
  include UdpCmdHelper

  before_filter :cpu_status_redirect_local   #in SessionHelper

  def cpu_status_redirect_local

    @url = request.url 
    @url = @url.split(params[:controller])
    @url = @url[1]
    @url = @url.split('?')
    @method = @url[0] 



    #/status_monitor/io_view
    if(@method == "/io_view")
      @redirect_flag = false
      @session = RtSession.find(:first, :select=>"comm_status,status,task_percent_completed")

      if(@session == nil )
        redirect_to "/sessions/cpu_out_of_session?comm_status=0&status=10"
      else
        if @session.comm_status.to_i != 1 || @session.status.to_i != 10
          @redirect_flag = true
        end
        redirect_to "/sessions/cpu_out_of_session?comm_status="+@session.comm_status.to_s+"&status="+@session.status.to_s+"&task_percent_completed="+@session.task_percent_completed.to_s  unless !@redirect_flag  
      end
    end
  end
  
  def echelon_status
    node = 0
    @statuses = EchelonStatistics.find(:all,:conditions=>["node_number = ?",node])
    @headers = (EchelonStatistics.column_names)
    @headers.delete('protocol_id')
    @headers.delete('ack_fails')
    if request.xhr?
      render :partial => "echelon_status"
    end
  end

  def echelon_clear
    simplerequest = RrSimpleRequest.create({:atcs_address => atcs_address + ".02", :command => 23, :subcommand => 0, :request_state => 0, :result => ""})
    udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, simplerequest.request_id)
    render :text => simplerequest.request_id.to_s
  end

  def check_echelon_clear
    simple_req_resp = RrSimpleRequest.find(:first,:conditions=>["request_id = ?",params[:request_id]])

    if simple_req_resp
      if simple_req_resp.request_state == 2
        delete_request(params[:request_id],REQUEST_COMMAND_SIMPLE_REQUEST)
      end

      render :json => {:error => false,:request_state => simple_req_resp.request_state,:result => simple_req_resp.result} 
    else
      render :json => {:error => true} 
    end
  end

  def ethernet_status
    @statuses = Generalststistics.get_ethernet_status
    @fields_hash = {:BCAST=>"Broadcast", :IP => "IP Address", 
                    :LINK => "Link", :MAC => "Mac Address",
                    :MASK => "Subnet Mask"}
  end

  def ui_sessions
    @rt_sessions = RtSession.all
    if request.xhr?
      render :partial => "ui_sessions"
    end
  end
  
  # Renders & Display Vital IO view information
  def io_view
    @input_params = get_io_input_output_params("I")
    @output_params = get_io_input_output_params("O")
    if request.xhr?
      io_content = render_to_string(:partial => 'io_view')
      render :json => { :io_req_content => io_content}
    end    
  end
  
  #Return input and output parameters.
  def get_io_input_output_params(params_type)    
    cfg_params = []
    io_cards = nil
    
    gwe_info = Gwe.find(:first, :select => "mcfcrc, sin, active_physical_layout")
    if gwe_info
      mcfcrc = gwe_info[:mcfcrc].to_i
      sin = gwe_info[:sin].to_s
      layout_index = gwe_info[:active_physical_layout].to_i
    else
      mcfcrc = Gwe.mcfcrc
      sin = ""
      layout_index = 0      
    end     
    rt_consist = RtConsist.consist_id(sin, mcfcrc).try(:consist_id) || 0
    if (params_type == "I")
      io_cards = Card.find_by_sql("Select Distinct card_index from cards Where mcfcrc = #{mcfcrc} AND layout_index = #{layout_index} AND cdf Like '%IPMAP.CDF%'")
    elsif (params_type == "O")
      #input_cards = Card.find(:all, :select => "card_index, Parameter_type", :conditions => {:mcfcrc => "{#mcfcrc}", :layout_index => "{#layout_index}", :cdf Like '%IPMAP.CDF%' })      
      io_cards = Card.find_by_sql("Select Distinct card_index from cards Where mcfcrc = #{mcfcrc} AND layout_index = #{layout_index} AND cdf Like '%OPMAP.CDF%'")
      out_status_params = Parameter.find_by_sql("Select parameter_index, name from parameters Where mcfcrc = #{mcfcrc} AND name like '%GCPVROMap%' and parameter_type = 3 Order by parameter_index")              
    end
     
    if io_cards
      io_cards.each do |iocard|
        config_params = Parameter.find_by_sql("Select parameter_index, name, enum_type_name from parameters Where mcfcrc = #{mcfcrc} AND cardindex = #{iocard[:card_index].to_i}  and parameter_type = 2 and 
              name Not Like '%Internal%' and name Not Like '%Filler%' Order by parameter_index")              
        if config_params 
          config_params.each do |con_params|
            current_val = RtParameter.find(:first, :select => "current_value", :conditions =>{:mcfcrc => mcfcrc, :card_index => iocard[:card_index].to_i,
              :parameter_type => 2, :parameter_index => con_params[:parameter_index].to_i})
                              
            if (current_val && (current_val[:current_value].to_i > 0) && (con_params[:name].upcase[0] == "T" || con_params[:name].upcase[0] == "P" || con_params[:name].upcase[0] == "R" || con_params[:name].upcase[0] == "X"))
              long_name = EnumeratorsMcf.find(:first, :select => "long_name", :conditions =>{:mcfcrc => mcfcrc, :layout_index => layout_index,
                :enum_type_name => con_params[:enum_type_name], :value => current_val[:current_value].to_i})
                
              if long_name
                slot_channel = get_slot_channel(con_params[:name], rt_consist)  
                if slot_channel != "not used"
                  if slot_channel.length > 0
                    desc = (params_type == 'I'? "IN " : "OUT ") + slot_channel + ": " + long_name[:long_name].to_s
                  else
                    desc = long_name[:long_name].to_s
                  end
                  if (params_type == "I")
                    state_index = con_params[:parameter_index].to_i * 2
                    param_type = 4
                  else
                    # add prefix to out name
                    i = desc.index(":")
                    if i == nil
                      i = con_params[:parameter_index].to_i
                      if out_status_params
                        if i < out_status_params.length
                          t = out_status_params[i].name.split(".")
                          if t.length == 2
                            desc = t[1] + ": " + desc
                          end
                        end
                      end
                    end
                    
                    state_index = con_params[:parameter_index].to_i
                    param_type = 3  
                  end                
                  io_state = RtParameter.find(:first, :select => "current_value", :conditions =>{:mcfcrc => mcfcrc, :card_index => iocard[:card_index].to_i,
                              :parameter_type => param_type, :parameter_index => state_index}).try(:current_value)  
                  #TODO: Used is only for input not for output
                  if (params_type == "I")
                    io_state_display = RtParameter.find(:first, :select => "current_value", :conditions =>{:mcfcrc => mcfcrc, :card_index => iocard[:card_index].to_i,
                              :parameter_type => param_type, :parameter_index => state_index + 1}).try(:current_value)
                  else
                    io_state_display = 0
                  end
                  
                  cfg_params.push({:index => con_params[:parameter_index] , :name => con_params[:name], :enum_type_name => con_params[:enum_type_name], 
                  :current_value => current_val[:current_value].to_i, :long_name => desc, :io_state => io_state, :state_display => io_state_display})
                end     #if slot_channel != "not used"                
              end   #if long_name               
            end   #if current_val[:current_value].to_i > 0
          end     #do |params|  
        end   #if config_params          
      end     #do |iocard|
    end     #if io_cards
    return cfg_params
  end
  
  #Returns Slot and Channel numbers
  def get_slot_channel(param_name, consist_id)
    c_type = 0
    c_number = 0
    c_channel = nil
    label_first = param_name.upcase[0]
    case label_first
      when "T" then c_type = TRACK_CARD
      when "P" then c_type = PSO_CARD
      when "R" then c_type = RIO_CARD
      when "X" then c_type = MAIN_SSCC_CARD
    end
    if (label_first == "T" || label_first == "P" || label_first == "R")
      c_number =  param_name[3,2]
    elsif (label_first == "X")
      c_number =  param_name[1,2]
    end
    if (!c_number.to_s.match(/^[0-9]+$/))      
      c_number = c_number[0]
    end
    c_number = c_number.to_i
    
    if(param_name.length >= 8)
      if (label_first == "T" || label_first == "P" || label_first == "R")
        c_channel =  param_name[7, 2]
      elsif (label_first == "X")
        c_channel =  param_name[5, 2]
      end
      if (!c_channel.blank?)
        if (!c_channel.to_s.match(/^[0-9]+$/))
          c_channel = c_channel[0]
          if(!c_channel[0].match(/^[0-9]+$/))
            c_channel = nil
          end
        end
      end
    end

    card_info = RtCardInformation.find(:all, :select => "card_used, slot_atcs_devnumber, card_info_id", :conditions => {:card_type => c_type, :consist_id => consist_id}, :order => "card_index" )
    if c_number > 0
      if card_info[c_number - 1][:card_used].to_i == 0
        if c_channel
          slot_channel = (card_info[c_number - 1][:slot_atcs_devnumber].to_i - 1).to_s + "." +  c_channel
        else
          slot_channel = ""
        end  
      else
        slot_channel = "not used"
      end      
    end
    return slot_channel
  end
  
end