####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: GeoEventLogController.rb
# Description: Display the VLP/IO Cards Logs 
####################################################################
#History:
# Log: /wayside/GEOII/Trunk/Software/WebUI/app/controllers/geo_event_log_controller.rb
#
# Rev 4636   July 06 2013 06:00:00   Jeyavel
# Removed unwanted code and modify the code as per the GEOII requirements.

class GeoEventLogController < ApplicationController
  layout "general"
  require "socket"
  include UdpCmdHelper
  include GenericHelper
  include SessionHelper
  
  before_filter :cpu_status_redirect , :only => [:index]
  
  ####################################################################
  # Function:      index
  # Parameters:    PRODUCT_TYPE_GEO_WEBUI
  # Retrun:        @geoatcs_add
  # Renders:       render :text
  # Description:   Display the VLP/IO Card log page 
  ####################################################################
  def index
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI
      @page_title = params[:page_title]
      rt_sessions = RtSession.find(:first, :select => "atcs_address", :conditions => {:comm_status => 1, :status => 10, :task_description => "Ready"})
      @geoatcs_add = rt_sessions.atcs_address
      text = "geo_is_not_in_session"
    end
    if(@geoatcs_add.length > 0)
      ht = 12 * 18
      @iframe_height = ht > 0 ? ht : nil
    else
      # Enabled the layout parameter for the styles
      render :text => "<p>" + I18n.t(text) + "</p>", :layout => true
    end
  end
  
  ####################################################################
  # Function:      geo_event_slots
  # Parameters:    params[:atcs_addr]
  # Retrun:        @cards, @slots, @card_types
  # Renders:       render :partial => "geo_event_slots"
  # Description:   Get the GEO cards and slots & display in the page
  ####################################################################
  def geo_event_slots
    if !params[:card_slot].blank?
      if params[:card_slot].to_i == 1
        name = "%VLP Diagnostic Log Verbosity%"
      else
        name = "%Slot #{params[:card_slot]} Diagnostic Log Verbosity%"
      end
      @select_value = EnumParameter.find(
                        :first,
                        :select => "Enum_Values.Name as item, Enum_Parameters.*",
                        :conditions=>["Enum_Parameters.Name like ?",name],
                        :joins => ["join Enum_Values on Enum_Parameters.Selected_Value_ID = Enum_Values.ID"]
                                )

      @select_value = @select_value[:item]
    else
      select_value = -1
    end

    config = open_ui_configuration
    @log_download_timeout = config["log_download"]["log_download_timeout"]
    @atcs_sinaddress = params[:atcs_addr]
    render :partial => "geo_event_slots"
  end
  
  ####################################################################
  # Function:      vlp_io_log_menu
  # Parameters:    None
  # Return:        html_content
  # Renders:       JSON
  # Description:   Generate VLP IO Log menu menu options
  ####################################################################
  def vlp_io_log_menu
    rt_sessions = RtSession.find(:first, :select => "atcs_address", :conditions => {:comm_status => 1, :status => 10, :task_description => "Ready"})
    @cards = ""
    if !rt_sessions.blank?
      @cards = get_cardslots_details(rt_sessions.atcs_address)  
    end
    html_content = render_to_string(:partial => 'vlp_io_log_menu')
    render :json => {:html_content => html_content} and return
  end
  
  ####################################################################
  # Function:      set_geo_event_verbosity
  # Parameters:    params[:atcs_addr] , params[:log_verbo_level] ,params[:card_slot] 
  # Retrun:        set_log_verbo_rq
  # Renders:       render :json
  # Description:   Method to set the Log verbosity value.
  ####################################################################
  def set_geo_event_verbosity
    # make entry into the request/reply database
    set_log_verbo_rq = GeoLogVerbosity.new({:request_state   => REQUEST_STATE_START,
                                            :atcs_address    => params[:atcs_addr] + ".01",
                                            :log_verbo_level => params[:log_verbo_level].to_i,
                                            :slot            => params[:card_slot].to_i
    })
    if !params[:card_slot].blank?
      if params[:card_slot].to_i == 1
        name = "%VLP Diagnostic Log Verbosity%"
      else
        name = "%Slot #{params[:card_slot]} Diagnostic Log Verbosity%"
      end
      value_id = EnumValue.find_by_sql("Select ID from Enum_Values where ID in (Select Enum_To_Values.Value_ID from Enum_Parameters join Enum_To_Values on Enum_Parameters.ID = Enum_To_Values.Param_ID where Name like '#{name}') and Value = #{params[:log_verbo_level]} limit 1");

      value_id = value_id[0][:ID]

      EnumParameter.update_all "Selected_Value_ID =  #{value_id}", "Name  like '#{name}'"
    end
    if(set_log_verbo_rq.save)
      udp_send_cmd(REQUEST_COMMAND_SET_VERBOSITY, set_log_verbo_rq.request_id)
    end
    render :json => {:request_id => set_log_verbo_rq.request_id}
  end
  
  ####################################################################
  # Function:      set_geo_event_verbosity_status
  # Parameters:    params[:id]
  # Retrun:        @set_log_verbo_rq
  # Renders:       render :text
  # Description:   Method to check the request status.
  ####################################################################
  def set_geo_event_verbosity_status
    @set_log_verbo_rq = GeoLogVerbosity.find_by_request_id(params[:id])
    if(@set_log_verbo_rq)
      render :text => @set_log_verbo_rq.request_state
    else
      # render a value of zero to show no progress
      render :text => '0'
    end
  end
  
  ####################################################################
  # Function:      delete_logverbo_req
  # Parameters:    params[:request_id]
  # Retrun:        None
  # Renders:       render :json => {:statusdone => true}
  # Description:   Method to delete the request.
  ####################################################################
  def delete_logverbo_req
    if(params[:request_id])
      GeoLogVerbosity.delete_all(:request_id => params[:request_id])
    end
    render :json => {:statusdone => true}
  end
  
  ####################################################################
  # Function:      get_log_verbosity
  # Parameters:    params[:atcs_addr] , params[:card_index] , params[:information_type]
  # Retrun:        online
  # Renders:       render :json
  # Description:   Method to get the verbosity levels for a particular card.
  ####################################################################
  def get_log_verbosity
    if !params[:atcs_addr].blank? && !params[:card_index].blank? && !params[:information_type].blank?
      if !params[:card_slot].blank?
        if params[:card_slot].to_i == 1
          name = "%VLP Diagnostic Log Verbosity%"
        else
          name = "%Slot #{params[:card_slot]} Diagnostic Log Verbosity%"
        end
        @select_value = EnumParameter.find(
                      :first,
                      :select => "Enum_Values.Name as item, Enum_Parameters.*",
                      :conditions=>["Enum_Parameters.Name like ?",name],
                      :joins => ["join Enum_Values on Enum_Parameters.Selected_Value_ID = Enum_Values.ID"]
                              )

        @select_value = @select_value[:item]
      end
      # Check for Vital/NonVital Card type
      online = RrGeoOnline.new({:request_state    => REQUEST_STATE_START,
                                :atcs_address     => params[:atcs_addr] + ".01",
                                :mcf_type         => 0,
                                :card_index       => params[:card_index],
                                :information_type => params[:information_type].blank? ? 3 : params[:information_type]
      })
      if(online.save)
        # udp for get the verbosity levels
        udp_send_cmd(REQUEST_COMMAND_GET_MODULES, online.request_id)
      end
      render :json => {:request_id => online.request_id}
    else
      render :json => {:request_id => -1}
    end
  end
  
  ####################################################################
  # Function:      check_verbo_state
  # Parameters:    params[:card_index] , params[:card_type] , params[:id]
  # Retrun:        online
  # Renders:       render :text
  # Description:   Check the Verbosity state
  ####################################################################
  def check_verbo_state
    @card_index = params[:card_index]
    online = RrGeoOnline.find_by_request_id(params[:id])
    if !online.nil?
      if online.request_state == 2
        if !params[:card_slot].blank?
           if params[:card_slot].to_i == 1
             name = "%VLP Diagnostic Log Verbosity%"
           else
             name = "%Slot #{params[:card_slot]} Diagnostic Log Verbosity%"
           end
          slot_verbosity = EnumParameter.find(
                      :first,
                      :select => "Enum_Values.Name as item, Enum_Parameters.*",
                      :conditions=>["Enum_Parameters.Name like ?",name],
                      :joins => ["join Enum_Values on Enum_Parameters.Selected_Value_ID = Enum_Values.ID"]
                              )

          slot_verbosity = slot_verbosity[:item]
        else
          slot_verbosity = 1 
        end

        render :json => {:request_state => online.request_state , :slot_verbosity => slot_verbosity }
      else
        render :json => {:request_state => online.request_state}
      end
    else
      render :json => {:request_state => 2,:message => "Request id unknown. Please try again."}
    end
  end
  
  ####################################################################
  # Function:      delete_geo_io_status_req_rep_vals
  # Parameters:    params[:request_id]
  # Retrun:        None
  # Renders:       render :json => {:statusdone => true}
  # Description:   Method to delete the request/reply/values.
  ####################################################################
  def delete_geo_io_status_req_rep_vals
    if(params[:request_id])
      RrGeoOnline.delete_all(:request_id => params[:request_id])
      replies = Iostatusreply.find(:all, :conditions => {:request_id => params[:request_id]})
      for reply in replies
        Iostatusvalue.delete_all(:reply_id => reply.reply_id)
      end
      Iostatusreply.delete_all(:request_id => params[:request_id])
      render :json => {:statusdone => true}
    end
  end
  
  ####################################################################
  # Function:      UDP_call
  # Parameters:    params[:num_events] , params[:cmd]
  # Retrun:        newrequest
  # Renders:       render :json
  # Description:   Send the UDP Request to Backend for create Log 
  ####################################################################
  def geo_event_udp_call
    no_of_record = params[:num_events].to_i
    command_id   = params[:cmd].to_i
    if(command_id == 0)
      command_id = 4
    end
    newrequest = Georequestreplydb.new({:atcs_address    => params[:atcs_addr] + '.02',
                                       :command          => command_id,
                                       :request_state    => REQUEST_STATE_START,
                                       :number_of_events => no_of_record,
                                       :what_log         => params[:logtype].to_i,
                                       :format           => 1,
                                       :position         => 255,
                                       :slot             => params[:slot]
    })
    if(newrequest.save)
      udp_send_cmd(REQUEST_COMMAND_GEO_LOG, newrequest.request_id)
      Geologreply.delete_all
      render :json => {:request_id => newrequest.request_id}
    else
      render :json => {:request_id => -1}
    end
  end
  
  ####################################################################
  # Function:      check_UDP_req_state
  # Parameters:    params[:request_id]
  # Retrun:        georequest
  # Renders:       render :json
  # Description:   Check the Log creation status for requested UDP
  ####################################################################
  def check_UDP_req_state
    georequest = Georequestreplydb.find_by_request_id(params[:request_id])
    if(georequest)
      render :json => {:reqstate    => georequest.request_state,
                       :command     => georequest.command,
                       :result      => georequest.result,
                       :numofevents => georequest.number_of_events}
    else
      render :json => {:reqstate    => -1,
                       :command     => 4,
                       :numofevents => 0}
    end
  end
  
  ####################################################################
  # Function:      geo_event_logs
  # Parameters:    params[:request_id]
  # Retrun:        @number_of_events
  # Renders:       render :partial=>"replies_data"
  # Description:   Get the created logs 
  ####################################################################
  def geo_event_logs
    @geo_event_req    = Georequestreplydb.find_by_request_id(params[:request_id])
    @number_of_events = @geo_event_req.number_of_events unless @geo_event_req.nil?
    @command          = @geo_event_req.command unless @geo_event_req.nil?
    @failure          = nil
    if  @geo_event_req.command == 10
      @failure ="Logs have been created, to view/save please click Download button"
    end
    @logreplies = Geologreply.all
    remove_geoevent_req_rep()
    render :partial=>"replies_data", :locals => {:number_of_events => @number_of_events}
  end
  
  ####################################################################
  # Function:      remove_geoevent_req_rep
  # Parameters:    params[:request_id]
  # Retrun:        None
  # Renders:       None
  # Description:   Remove the all records from the Georequestreplydb ,Geologreply tables 
  ####################################################################
  def remove_geoevent_req_rep
    if(params[:request_id])
      Georequestreplydb.delete_all(:request_id => params[:request_id])
      Geologreply.delete_all(:request_id => params[:request_id])
    end
  end
  
  def delete_geo_event_log_request_reply
    remove_geoevent_req_rep()
    render :nothing =>true
  end
  
  ####################################################################
  # Function:      get_mile_post_val
  # Parameters:    None
  # Retrun:        mile_post
  # Renders:       render :json 
  # Description:   Get the mile post value from the String Parameters table
  ####################################################################
  def get_mile_post_val
    mile_post = StringParameter.find(:first , :select=>"String as str" , :conditions =>"Group_ID = 1 and Group_Channel = 0 and Name ='Mile Post'" ).try(:str)
    render :json => {:mile_post => mile_post}
  end
  
  ####################################################################
  # Function:      download_txtfile
  # Parameters:    params["logtype"]
  # Retrun:        file_name
  # Renders:       send_file
  # Description:   Download the displayed/all events for selected cards logs
  ####################################################################
  def download_txtfile
    begin
      file_name = (params["logtype"] == "0")? "StatLogSL" : "SumLogSL"
      file_name += (params["slot_number"].blank?)? "" : params["slot_number"].gsub(" ","")
      file_name += "-" + ((params["mile_post"].blank?)? "" : params["mile_post"].to_s)
      file_name += "-" + Time.now.strftime("%d-%b-%Y-%H-%M-%S")
      path = GEO_EVENT_LOG_FILE
      send_file(path,
                :filename    => "#{file_name}.txt",
                :type        => 'text/plain',
                :disposition => 'attachment',
                :encoding    => 'utf8',
                :stream      => 'true',
                :x_sendfile => true)
    rescue
      render :text => 'No File available for download'
    end
  end
  
  ####################################################################
  # Function:      get_cardslots_details
  # Parameters:    atcs_address
  # Retrun:        card_names
  # Renders:       None
  # Description:   get the VLP/IO all active Cards Details   
  ####################################################################
  def get_cardslots_details(atcs_address)
    begin
      return [] if atcs_address.blank?
      gwe = Gwe.get_mcfcrc(atcs_address)
      rt_consist =  RtConsist.consist_id(atcs_address, gwe.mcfcrc)
      rt_cards_informations =  RtCardInformation.find(:all,:conditions =>["consist_id = ? and (slave_kind = 0 or card_type = ?)", rt_consist.consist_id, rt_consist.cpu_card_id])
      card_names = Array.new
      for rtcard_info in rt_cards_informations
        rt_cards = Rtcards.find(:first, :conditions =>["parameter_type = 3  and mcfcrc = ? and sin = ? and c_index = ? ", gwe.mcfcrc , atcs_address , rtcard_info.card_index])
        unless rt_cards.blank?
          mcf_cards_info = Card.find(:all, :conditions => {:card_index => rtcard_info.card_index ,:crd_type => rtcard_info.card_type  ,:mcfcrc => gwe.mcfcrc })        
          unless mcf_cards_info.blank?
            name = "Slot " + rtcard_info.slot_atcs_devnumber.to_s + " - " + mcf_cards_info[0].crd_name
            # Save card info to array
            card_names << {"slot"  => rtcard_info.slot_atcs_devnumber, 
                     "index" => rtcard_info.card_index,
                     "type"  => mcf_cards_info[0].crd_type,
                     "comm_status" => rt_cards.comm_status,
                     "name"  => name} 
          end
        end
      end
      # Sort list by slot number
      card_names = card_names.sort_by { |card| card["slot"] }
      return card_names
    rescue Exception => e
      return []
    end
  end
  
  ####################################################################
  # Function:      cancel_all_event_request
  # Parameters:    None
  # Retrun:        true
  # Renders:       None
  # Description:   Cancel the VLP/IO Card all event download logs    
  ####################################################################
  def cancel_all_event_request
    atcs_addr = Gwe.find(:first, :select => "sin").try(:sin)
    simplerequest = RrSimpleRequest.create({:atcs_address => atcs_addr + ".01", :command => 16 , :request_state => 0, :result => ""})
    udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, simplerequest.request_id)
    render :nothing => true
  end
end