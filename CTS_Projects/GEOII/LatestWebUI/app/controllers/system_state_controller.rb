class SystemStateController < ApplicationController
  layout "general"
  include UdpCmdHelper
  include SessionHelper
    
  before_filter :cpu_status_redirect
  
  def index
    atcs_addr = RtSession.find_all_atcs_addresses   # RtSession.find_atcs_addrs
    if !atcs_addr.blank?
      @atcs_addr = atcs_addr[0].strip
    else
      @atcs_addr = ""
    end
  end
  
  def download_logic_state
    send_file("/usr/safetran/WebUI/doc/logic_state.txt", :filename=>"logic_state#{Time.now.strftime("%d-%b-%Y %H_%M_%S")}.txt",:type=>'text/plain',:disposition=>'attachment',:encoding=>'utf8',:stream=>'true',:x_sendfile => true)
  end
  def system_states
    @is_non_am = geo_non_am(params[:atcs_addr])
    if(@is_non_am)
      @atcs_addr = params[:atcs_addr]
      content = render_to_string(:partial => "set_range_partial").strip
      render_json(@is_non_am, content)
    else
      atcs_addr_info = params[:atcs_addr].split("|")
      atcs_addr = atcs_addr_info[0].strip()
      device_name = atcs_addr_info[1]
      if device_name
        device_name = device_name.strip()
      end
      
      @gwe = Gwe.find(:last, :conditions => ["sin = ?", atcs_addr])
      @satname = RtSatName.all(:conditions => {:sin => atcs_addr})
      if @satname.size == 0
        @object_name_rq = ObjectName.new
        @object_name_rq.request_state = 0
        if device_name == "Console VCPU"
          @object_name_rq.atcs_address = atcs_addr + ".02"
        else
          @object_name_rq.atcs_address = atcs_addr + ".01"
        end
        @object_name_rq.command = 0
        @object_name_rq.name_type = 0
        @object_name_rq.save
        @request_id = @object_name_rq.id    
        udp_send_cmd(REQUEST_GEO_OBJ_MSG, @request_id)
        
        check_sat_name_request_state @object_name_rq
        
        names = ObjSatReply.all(:conditions => {:request_id => @request_id})
        k = 1
        names.each do |name|
          obj = RtSatName.new
          obj.sat_name = name.obj_name
          obj.default_sat_name = name.obj_name
          obj.sat_index = k
          obj.sin = atcs_addr
          obj.save
          k += 1
        end
        @satname = RtSatName.all(:conditions => {:sin => atcs_addr})
      end
      content = render_to_string(:partial => "systemstates")
      render_json(@is_non_am, content)
    end  
  end
  
  def check_sat_name_request_state(sat_name_rq)
    request_state = 0
    timer = 0
    until request_state == 2
      sleep 2
      request = ObjectName.find_by_request_id(sat_name_rq.id)
      timer += 1
      if request.request_state == 2
        request_state = 2
      end
      if timer == 30
        request_state = 2
      end
    end
  end
 
  def check_state
    @object_name_rq = ObjectName.find_by_request_id(params[:id])
    @satname = ObjSatReply.all(:conditions => {:request_id => @object_name_rq.id})
    if @object_name_rq.request_state == 2      
      @is_non_am = geo_non_am(params[:atcs_addr])
      render :partial => "systemstates"
    else
      render :text => @object_name_rq.request_state
    end    
  end
    
 def get_system_replies
    atcs_addr_info = params[:atcs_addr].split("|")
    atcs_addr = atcs_addr_info[0].strip()
    device_name = atcs_addr_info[1]
    if device_name
    device_name = device_name.strip()
    end
    @gwe = Gwe.find(:last, :conditions => ["sin = ?", atcs_addr])
    ls_names = LsCategories.find(:all, :select => 'name, min, max, parent', :conditions => ['mcfcrc = ? AND sat_index = ? AND name = ? and layout_index = ?', @gwe.mcfcrc, params[:sat_index], params[:name], @gwe.active_physical_layout])
    min_val = 0
    max_val = 0
    if(ls_names.length > 1)
      ls_names.each do |l_name|
        if(l_name.parent == params[:parent_name])
        min_val = l_name.min
        max_val = l_name.max
        end
      end
    else
    min_val = ls_names[0].min
    max_val = ls_names[0].max
    end
    if(params[:auto_refresh])
      if device_name != "Console VCPU"
        rt_session = RtSession.find_by_atcs_address(atcs_addr, :conditions => {:comm_status => 1, :status => 10})
        render :text => "<h4 class='no_record'>Geo is not in session!!</h4>" and return if rt_session.blank?
      end
      new_system_state_replies = SystemStatesLogicstate.find(:all, :conditions => ['isno >= ? and isno <= ? and mcfcrc = ? and sin = ?', min_val, max_val, @gwe.mcfcrc, atcs_addr], :order => "isno asc")
      new_is_replies_values = []
      new_system_state_replies.each do |s_value|
        new_is_replies_values << s_value.value
      end
      if(new_is_replies_values.length == 0)
        render :text => "No Change" and return
      else
        if session[:system_states_is_reply_values].split(',') == new_is_replies_values
          render :text => "No Change" and return
        else
          session[:system_states_is_reply_values] = new_is_replies_values.join(",")
          @is_non_am = geo_non_am(atcs_addr)
          render :partial => "systemdata", :locals => {:select_enable => false, :system_state_rq_id => nil, :min => min_val, :max => max_val} and return
        end
      end
    else
      session[:system_states_is_reply_values] = nil
    end
    system_state_rq = IsRequest.new
    system_state_rq.request_state = 0
    if device_name == "Console VCPU"
      system_state_rq.atcs_address = atcs_addr + ".02"
    else
      system_state_rq.atcs_address = atcs_addr + ".01"
    end
    system_state_rq.command = 1
    system_state_rq.start_is_number = min_val
    system_state_rq.end_is_number = max_val
    system_state_rq.save
    udp_send_cmd(REQUEST_COMMAND_LS, system_state_rq.request_id)
    check_system_state(system_state_rq, false)
  end
  
  def set_range
    @atcs_addr = params[:atcs_addr]
    render :partial => "set_range_partial"
  end
  
  def set_range_values
    atcs_addr_info = params[:atcs_addr].split("|")
    atcs_addr = atcs_addr_info[0].strip()
    device_name = atcs_addr_info[1]
    if device_name
      device_name = device_name.strip()
    end
    @is_non_am = geo_non_am(atcs_addr)
    system_state_rq = IsRequest.new
    system_state_rq.request_state = 0
    if device_name == "Console VCPU"
      system_state_rq.atcs_address = atcs_addr + ".02"
    else
      system_state_rq.atcs_address = atcs_addr + ".01"
    end
    system_state_rq.command = 1
    system_state_rq.start_is_number = params[:min]
    system_state_rq.end_is_number = params[:max]
    system_state_rq.save
    if @is_non_am
		udp_send_cmd(106, system_state_rq.request_id)
	else
		udp_send_cmd(REQUEST_COMMAND_LS, system_state_rq.request_id)
	end
    session[:system_states_is_reply_values] = nil
    check_system_state(system_state_rq, true)
  end
  
  private
  
  def check_system_state(system_state_rq, select_enable)
    request_state = 0
    timer = 0
    until request_state == 2
      sleep 2
      system_state_rq = IsRequest.find_by_request_id(system_state_rq.id)
      timer += 1
      if system_state_rq.request_state == 2
        request_state = 2
        atcs_addr_info = params[:atcs_addr].split("|")
        atcs_addr = atcs_addr_info[0].strip()
        @is_non_am = geo_non_am(atcs_addr)        
          render :partial => "systemdata", :locals => {:select_enable => select_enable, :system_state_rq_id => system_state_rq.id, :min => system_state_rq.start_is_number, :max => system_state_rq.end_is_number}
      end
      if timer == 20
        request_state = 2
        render :text => "<span class='error_message'>Request Timed Out!!</span>"
      end
    end
  end
  
  def render_json(non_am, content)
    respond_to do |format|
      format.json do
        render :json => {:non_am => non_am, :data => content}
      end
    end
  end
   
end