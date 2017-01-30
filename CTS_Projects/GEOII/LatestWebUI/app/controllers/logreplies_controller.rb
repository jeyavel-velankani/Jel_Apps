####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: LogrepliesController.rb
# Description: Display Event log , Diagnostic log 
####################################################################
#History:
# Log: /wayside/GEOII/Trunk/Software/WebUI/app/controllers/logreplies_controller.rb
#
# Rev 4668   July 09 2013 19:20:00   Jeyavel
# Removed unused session variables.
class LogrepliesController < ApplicationController
  include LogrepliesHelper
  include UdpCmdHelper
  include GenericHelper
  include SessionHelper
  
  layout "general", :except => ["loading", "set_filter", "alarms"]
  require "socket"
  
  ####################################################################
  # Function:      index
  # Parameters:    params[:id]
  # Retrun:        @logtype
  # Renders:       None
  # Description:   Display the event/Diag log in the page
  ####################################################################
  def index
    # clear databases
    if session[:logreplies_id] != nil
      RequestReplydb.delete_all("request_id = '"+session[:logreplies_id].to_s+"'")
      Logreply.delete_all("request_id = '"+session[:logreplies_id].to_s+"'")
      LogFilter.delete_all("request_id = '"+session[:logreplies_id].to_s+"'")

      session[:logreplies_id] = nil
    end

    config = open_ui_configuration
    @log_download_timeout = config["log_download"]["log_download_timeout"]
    @logtype = ""
    case(params[:id].to_i)
      when STATUS_LOG_T
        @logtype = 'status'
      when DIAG_LOG_T
        @logtype = 'diagnosticeventlog'
    end
    
    session[:filter] = nil
  end
  
  ####################################################################
  # Function:      set_filter
  # Parameters:    None
  # Retrun:        @filter , @filters
  # Renders:       None
  # Description:   Rendering basic grid view for filters
  ####################################################################
  def set_filter
    @filter = LogFilter.new
    @filters = LogFilter.find(:all,:conditions=>["request_id = ?",session[:logreplies_id]]) if LogFilter.filter_exists?
  end
  
  ####################################################################
  # Function:      apply_filter
  # Parameters:    params[:log_filter][:request_id]
  # Retrun:        session[:filter] = true
  # Renders:       render :nothing => true
  # Description:   Iterating over user input and updating/creating new filters
  ####################################################################
  def apply_filter
    params.each_pair do |key, value|
      if key.match("log_filter") && value.has_key?('filter_operation')
        if value.has_key?('filter_id')
          filter = LogFilter.find(value['filter_id'])
          filter.update_attributes!(value) if filter
        else
          filter = LogFilter.new(value)
          filter.request_id = session[:logreplies_id]
          filter.save
        end
      end
    end
    session[:filter] = true
    render :nothing => true
  end
  
  ####################################################################
  # Function:      delete_fiter
  # Parameters:    params['filter_id']
  # Retrun:        None
  # Renders:       render :text => "Filter deleted successfully!!"
  # Description:   deleting filter based on the filter id
  ####################################################################
  def delete_fiter
    unless params['filter_id'].blank?
      filter = LogFilter.find(params['filter_id'])
      filter.destroy
      render :text => "Filter deleted successfully!!"
    end
  end
  
  ####################################################################
  # Function:      clear_filters
  # Parameters:    None
  # Retrun:        session[:filter]
  # Renders:       render :nothing => true
  # Description:   Clear the log filters
  ####################################################################
  def clear_filters
    logger.info session[:logreplies_id].to_s

    if session[:logreplies_id] != nil
      LogFilter.delete_all("request_id = '"+session[:logreplies_id].to_s+"'")
      create_filter(params[:log_filter], session[:logreplies_id])
    end
    session[:filter] = nil
    render :nothing => true
  end
  
  ####################################################################
  # Function:      check_filter_state
  # Parameters:    params[:request_id]
  # Retrun:        log_request
  # Renders:       render :text => log_request.request_state
  # Description:   check the log filter state
  ####################################################################
  def check_filter_state
    log_request = RequestReplydb.find_by_request_id(params[:request_id])
    @iframe_height = 15*25
    if log_request && log_request.request_state == 2
      params[:rp] = 50
      params[:sortorder] = "asc"
      params[:sortname] = "timestamp"
      render :partial => "replies_data"
    else
      render :text => log_request.request_state
    end
  end
  
  ####################################################################
  # Function:      get_event_data
  # Parameters:    session[:request_id]
  # Retrun:        @rows
  # Renders:       render :partial => 'event_details'
  # Description:   get the event data
  ####################################################################
  def get_event_data
    condition_string = nil
    log_type_id = params[:log_type_id]
    request_id  = params[:requestid]
    unless params[:query].blank?
        condition_string = ["request_id= ? AND #{params[:qtype]} like ?", request_id, "%#{params[:query]}%"]
    else
        condition_string =   ["request_id= ?", request_id]
    end
    logs = Logreply.find(:all,:conditions=>condition_string)
    if(logs)
      @rows = logs.map{|x| {:id => x.id, :cell => [Time.at(x.timestamp).strftime("%d-%b-%Y %H:%M:%S")+ "." +x.hundreths.to_s,
          x.card_and_slot,
          x.entry_text,
          verbosity_to_s(x.verbosity_level),
          x.entry_type]}}
          @log_type_val = log_type_id
    end
    render :partial => 'event_details' 
  end
  
  ####################################################################
  # Function:      udp_call
  # Parameters:    params[:number_of_entries] , params[:start_date] ,
  #                params[:end_date] ,params[:cmd] ,params[:log_type_id]
  # Retrun:        @log_requestreply
  # Renders:       render :json
  # Description:   Send the UDP command for log create
  ####################################################################
  def udp_call
    if session[:logreplies_id] 
      RequestReplydb.delete_all("request_id = '"+session[:logreplies_id].to_s+"'")
      Logreply.delete_all("request_id = '"+session[:logreplies_id].to_s+"'")
      
      if params[:clear_logs] == 'true'
       LogFilter.delete_all("request_id = "+session[:logreplies_id].to_s)
      end
    end

    report_entry = params[:number_of_entries]
    startdate    = params[:start_date]
    enddate      = params[:end_date]
    command_id   = params[:cmd]
    logtypeID    = params[:log_type_id].to_i
    log_filter   = params[:log_filter]
    
    # Using the term journal to identify whether it's a Display(Diaglog) log or a type of EVENT(train, cpu, maint, etc) log
    journal_id = (logtypeID == DISP_LOG_T)? DIAG_JRNL_T : EVENT_JRNL_T
    path = get_path(logtypeID)
    
    if report_entry == "All" || command_id.to_i == 5
      @request_for_all = true
      report_entry     = 80
      date_time_convertor
    end
    date_time_convertor unless params[:search_type] == "basic"
    @log_requestreply = RequestReplydb.new({:log_type_id   => journal_id,
                                         :start         => (@startd || 0),
                                         :end           => (@endd || 0xFFFFFFFF),
                                         :max_entries   => report_entry,
                                         :command       => command_id,
                                         :request_state => 0,
                                         :full_path     => path})
    if @log_requestreply.save

      if session[:logreplies_id] &&  params[:clear_logs] == 'false'
        LogFilter.update_all("request_id = "+@log_requestreply.request_id.to_s,"request_id = "+session[:logreplies_id].to_s)
      else 
        create_filter(log_filter, @log_requestreply.request_id)
      end
      
      udp_send_cmd(REQUEST_COMMAND_LOG,@log_requestreply.request_id)

      session[:logreplies_id] = @log_requestreply.request_id
      render :json => {:request_id => @log_requestreply.request_id}
    else
      render :json => {:request_id => -1}
    end
  end
  
  ####################################################################
  # Function:      create_filter
  # Parameters:    logtypeid, request_id
  # Retrun:        filter
  # Renders:       render :text
  # Description:   Create filter
  ####################################################################
  def create_filter(log_filter, request_id)
    if (PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI)
      #clear exsisting logs
      LogFilter.delete_all("request_id = #{request_id}")

      if log_filter == "STAT"
        LogFilter.create(:request_id       => request_id,
                        :filter_logic     => LOGLOGIC_OR,
                        :filter_field     => LOGFLD_TYPE,
                        :filter_operation => LOGOP_CONTAINS,
                        :filter_text      => log_filter)
        LogFilter.create(:request_id       => request_id,
                        :filter_logic     => LOGLOGIC_OR,
                        :filter_field     => LOGFLD_TYPE,
                        :filter_operation => LOGOP_CONTAINS,
                        :filter_text      => "SUMR")
        LogFilter.create(:request_id       => request_id,
                        :filter_logic     => LOGLOGIC_OR,
                        :filter_field     => LOGFLD_TYPE,
                        :filter_operation => LOGOP_CONTAINS,
                        :filter_text      => "SDWN") 
      elsif log_filter == "SUMR"
       LogFilter.create(:request_id       => request_id,
                          :filter_logic     => LOGLOGIC_OR,
                          :filter_field     => LOGFLD_TYPE,
                          :filter_operation => LOGOP_CONTAINS,
                          :filter_text      => log_filter) 
         LogFilter.create(:request_id       => request_id,
                          :filter_logic     => LOGLOGIC_OR,
                          :filter_field     => LOGFLD_TYPE,
                          :filter_operation => LOGOP_CONTAINS,
                          :filter_text      => "SDWN")
      elsif log_filter == "SDWN"
       LogFilter.create(:request_id       => request_id,
                          :filter_logic     => LOGLOGIC_AND,
                          :filter_field     => LOGFLD_TYPE,
                          :filter_operation => LOGOP_CONTAINS,
                          :filter_text      => log_filter) unless log_filter.blank?
      else 
       LogFilter.create(:request_id       => request_id,
                          :filter_logic     => LOGLOGIC_AND,
                          :filter_field     => LOGFLD_TYPE,
                          :filter_operation => LOGOP_CONTAINS,
                          :filter_text      => log_filter) unless log_filter.blank?
      end
      else
      LogFilter.update_all("request_id = #{request_id}") if session[:filter]

      if session[:logreplies_id] != nil
        Logreply.delete_all("request_id = '"+session[:logreplies_id].to_s+"'")
      end
    end
    return
  end
  
  ####################################################################
  # Function:      get_path
  # Parameters:    logtypeid
  # Retrun:        path
  # Renders:       None
  # Description:   Get the path of corresponding log type
  ####################################################################
  def get_path(logtypeid)
    unless logtypeid.blank?
      if logtypeid.to_i == DISP_LOG_T
        path   = DISP_LOG_FILE
      else
        path   = EVENT_LOG_FILE
      end
    end
    return path
  end

  ####################################################################
  # Function:      get_path
  # Parameters:    logtypeid
  # Retrun:        path
  # Renders:       None
  # Description:   Get the path of corresponding log type
  ####################################################################
  def get_filename(logtypeid)
    unless logtypeid.blank?
      if logtypeid.to_i == DISP_LOG_T
        path   = DISP_LOG_FILE
      else
        path   = EVENT_LOG_FILE
      end

      filename = path.split('/')
      filename = filename[-1]
    end
    return filename
  end
  
  ####################################################################
  # Function:      check_log_status
  # Parameters:    params[:request_id] , params[:log_type_id]
  # Retrun:        filter
  # Renders:       render :json
  # Description:   Check the log status
  ####################################################################
  def check_log_status
    log_requestreply = RequestReplydb.find_by_request_id(params[:request_id])
    unless log_requestreply.blank?
      logs_size = 0
      filter = nil
      unless params[:log_type_id].blank?
        if params[:log_type_id].to_i == STATUS_LOG_T
          filter = 'VCore'
        elsif params[:log_type_id].to_i == DIAG_LOG_T
          filter = 'NVCPU'
        end
        logs_size = Logreply.count(:all,:conditions => ["request_id= ? AND card_and_slot =?", params[:request_id], filter ] )
      end
      render :json => {:req_state  => log_requestreply.request_state,
                         :request_id => params[:request_id],
                         :diag       => params[:diag],
                         :logs_size  => logs_size,
                         :event_count => (log_requestreply.event_count)? log_requestreply.event_count : 0  ,
                         :filter     => filter,
                         :req_all    => (log_requestreply.command == 5 && log_requestreply.max_entries == 80)}
    else
      render :text =>""
    end
  end
  
  ####################################################################
  # Function:      start_trace_events
  # Parameters:    params[:id]
  # Retrun:        log_requestreply
  # Renders:       render :template => "/logreplies/traceevents"
  # Description:   Start trace events
  ####################################################################
  def start_trace_events
    # clear databases
    if session[:logreplies_id] != nil
      RequestReplydb.delete_all("request_id = '"+session[:logreplies_id].to_s+"'")
      Logreply.delete_all("request_id = '"+session[:logreplies_id].to_s+"'")
    end
    unless params[:id].blank?
      logtypeID = params[:id].to_i 
      journal_id = (logtypeID == DISP_LOG_T)? DIAG_JRNL_T : EVENT_JRNL_T
      
      # Get starttime and log path
      tracestarttime = Time.now
      path = (@log_type = params[:id]).to_i == 1 ? EVENT_LOG_FILE : DISP_LOG_FILE

      session[:log_reply_start] = tracestarttime
      
      # Create request
      log_requestreply = RequestReplydb.new({:log_type_id    => journal_id,
                                           :start         => tracestarttime,
                                           :end           => 0,
                                           :max_entries   => 0,
                                           :event_count   => 50,
                                           :request_state => 0,
                                           :command       => 4,
                                           :full_path     => path})
        if(log_requestreply.save)
           session[:logreplies_id] = log_requestreply.request_id

          create_filter('', log_requestreply.request_id)
          udp_send_cmd(REQUEST_COMMAND_LOG,log_requestreply.request_id)
          html_content = render_to_string(:template => "/logreplies/traceevents", :locals => { :request_id => log_requestreply.request_id })
          render :json => {:html_content => html_content}
        else
          render :json => {:request_id => -1}
        end
      else
        render :json => {:request_id => -1} 
    end
  end
  
  ####################################################################
  # Function:      check_trace_events
  # Parameters:    session[:request_id]
  # Retrun:        @new_events
  # Renders:       render :text
  # Description:   Check the trace event status
  ####################################################################
  def check_trace_events
    unless params[:request_id].blank?
      request_id = params[:request_id]
      log_requestreply = RequestReplydb.find_by_request_id(request_id)
      
      # Verify a request exists
      if(log_requestreply)
        # Check if current request is complete
        if log_requestreply.request_state == 2
          
          # it's complete, prep for an update with same request ID.
          log_requestreply.request_state = 0

          new_events_flag = false
          
          # only need events that are newer than last event received
          last_event = Logreply.find(:last,:conditions =>["request_id = ?", request_id ])
          if(last_event)
            if session[:log_reply_start] != (last_event.timestamp + 1)
              new_events_flag = true
              session[:log_reply_start] = (last_event.timestamp + 1)
            end 
            log_requestreply.start = (last_event.timestamp + 1)
          end
          log_requestreply.save
          
          # get events
          @new_events = Logreply.find(:all,:conditions =>["request_id = ?", request_id ])
          
          udp_send_cmd(REQUEST_COMMAND_LOG,log_requestreply.request_id)
          
          clear_excess_logs(request_id)
          
          if (@new_events && !@new_events.blank?)
            session[:last_event_time] = @new_events.last.timestamp
            params[:log_type_id] = params[:id]
            params[:requestid] = request_id
            session[:logreplies_id] = request_id
            if new_events_flag
              get_event_data()
            else
              render :text => "no new events"
            end
            
          else
            render :text => "no new events"
          end
          
        else
          render :text => "request not complete yet"
        end
      else
        render :text => "<h1>Request does not exist</h1>"
      end
    else
      render :text => "-1"
    end
  end
  
  ####################################################################
  # Function:      clear_excess_logs
  # Parameters:    session[:request_id]
  # Retrun:        log_at_offset
  # Renders:       None
  # Description:   Clear Excess Logs
  ####################################################################
  def clear_excess_logs(request_id)
    no_of_events = Logreply.count(:conditions=>["request_id=?", request_id])
    if no_of_events > 500
      _offset = no_of_events - 500
      log_at_offset = Logreply.find(:first, :conditions=>["request_id=?", request_id], :offset => _offset)
      Logreply.delete_all(["request_id=? AND reply_id < ?", request_id, log_at_offset.reply_id]) if log_at_offset
    end
  end
  
  ####################################################################
  # Function:      system_diagnostics
  # Parameters:    None
  # Retrun:        @log_events
  # Renders:       None
  # Description:   Get the log events from table
  ####################################################################
  def system_diagnostics
    @log_events = VcpuDiagnostic.all
  end
  
  ####################################################################
  # Function:      check_diagnostic_messages
  # Parameters:    None
  # Retrun:        None
  # Renders:       render :json
  # Description:   Check the diagnostic messages
  ####################################################################
  def check_diagnostic_messages
    render :json => {:status => (get_alarms(false) == true), :active =>  logged_in?}
  end
  
  ####################################################################
  # Function:      detail_diagnostics
  # Parameters:    params[:byte], params[:bit]
  # Retrun:        @cause_remedy
  # Renders:       render :partial => "detail_diagnostics"
  # Description:   Get detail diagnostics
  ####################################################################
  def detail_diagnostics
    if ( params[:byte] && params[:bit] )
      if sys_diag = VcpuDiagnostic.find_by_byte_and_bit(params[:byte], params[:bit])
        gwe = Gwe.first
        rt_card = Rtcardinformation.find_by_slot_atcs_devnumber_and_card_type((sys_diag.slot.to_i+1), sys_diag.card_id) if sys_diag
        parameter = Parameter.find(:first,
                                    :conditions => ["cardindex =? AND parameter_type =? AND start_bit =? AND start_byte =? AND layout_index =?", rt_card.card_index, 6, sys_diag.bit, (sys_diag.byte.to_i+1), 1]) if rt_card
        card = Card.find_by_card_index_and_crd_type(rt_card.card_index, sys_diag.card_id) if parameter
        @cause_remedy = McfDiagnostic.find_by_name_and_cdf_and_mcfcrc(parameter.name.split('.')[1], card.cdf.upcase, gwe.mcfcrc) if parameter && card
      end
    end
    render :partial => "detail_diagnostics"
  end
  
  ####################################################################
  # Function:      sort_diagnostics
  # Parameters:    params[:sort_by] && params[:direction]
  # Retrun:        @sort_order
  # Renders:       render :action => :system_diagnostics
  # Description:   sort diagnostics
  ####################################################################
  def sort_diagnostics
    if params[:sort_by] && params[:direction]
      @log_events = VcpuDiagnostic.find(:all, :order=>"#{params[:sort_by]} #{params[:direction]}")
      @sort_by = params[:sort_by]
    end
    @sort_order = {"asc"=>"desc", "desc"=>"asc"}[params[:direction]]  || 'asc'
    render :action => :system_diagnostics
  end
  
  ####################################################################
  # Function:      download_txtfile
  # Parameters:    params[:id]
  # Retrun:        file_name , path
  # Renders:       send_file 
  # Description:   Download the logs
  ####################################################################
  def download_txtfile
    logtype = params[:id].to_i
    path = get_path(logtype)
    file_name = get_filename(logtype)

    file_name.gsub!(/\.txt/,"")

    send_file(path, :filename    =>"#{file_name}_#{Time.now.strftime("%d-%b-%Y %H_%M_%S")}.txt",
                    :type        =>'text/plain',
                    :disposition =>'attachment',
                    :encoding    =>'utf8',
                    :stream      =>'true',
                    :x_sendfile => true)
  end
  
  ####################################################################
  # Function:      download_all_logs
  # Parameters:    None
  # Retrun:        @log_requestreply , session[:request_ids]
  # Renders:       None
  # Description:   Download all logs
  ####################################################################
  def download_all_logs
    if request.post?
      @request_ids = []
      date_time_parser
      date_time_convertor
      2.times do |i|
        @log_requestreply = RequestReplydb.new({:log_type_id => (i+1), :start => (@startd || 0), :end => (@endd || 0xFFFFFFFF),
                                            :max_entries => 80, :command => 5, :request_state => 0,
                                            :full_path => [EVENT_LOG_FILE, DISP_LOG_FILE][i]})
        
        if @log_requestreply.save
          udp_send_cmd(REQUEST_COMMAND_LOG,@log_requestreply.request_id)
          session[:request_ids] = (@request_ids << {:id=> "#{@log_requestreply.id}", :type => @log_requestreply.log_type_id })
        end
      end
    end
  end
  
  ####################################################################
  # Function:      download_logs_status
  # Parameters:    session[:request_ids]
  # Retrun:        @request_ids
  # Renders:       render :json
  # Description:   Download log status
  ####################################################################
  def download_logs_status
    @request_ids = []
    2.times do |i|
      if (req_rep = RequestReplydb.find_by_request_id(session[:request_ids][i][:id]) rescue nil)
        @state = true
        @request_ids << {:id =>"#{req_rep.id}", :type => req_rep.log_type_id, :status => req_rep.request_state}
        session[:request_ids].delete_at(i) && req_rep.delete if req_rep.request_state == 2
      end
    end
    render :json => {:records => @request_ids, :status => !!@state}
  end
  
  ####################################################################
  # Function:      delete_log_request
  # Parameters:    params[:request_id]
  # Retrun:        None
  # Renders:       None
  # Description:   Delete the log request and reply table record
  ####################################################################
  def delete_log_request    
    RequestReplydb.delete_all("request_id = '"+params[:request_id].to_s+"'")
    Logreply.delete_all("request_id = '"+params[:request_id].to_s+"'")
    LogFilter.delete_all("request_id = '"+params[:request_id].to_s+"'")

    session[:logreplies_id] = nil
    render :nothing =>true
  end
  
  private
  ####################################################################
  # Function:      date_time_parser
  # Parameters:    params[:end_time][:begin][:hour], params[:end_time][:begin][:minute], params[:end_time][:begin][:second]
  # Retrun:        params[:end_hour], params[:end_minute], params[:end_second]
  # Renders:       None
  # Description:   Date time parser
  ####################################################################
  def date_time_parser
    params[:start_hour], params[:start_minute], params[:start_second] = params[:start_time][:begin][:hour], params[:start_time][:begin][:minute], params[:start_time][:begin][:second]
    params[:end_hour], params[:end_minute], params[:end_second] = params[:end_time][:begin][:hour], params[:end_time][:begin][:minute], params[:end_time][:begin][:second]
  end
  
  ####################################################################
  # Function:      date_time_convertor
  # Parameters:    params[:start_date]
  # Retrun:        @startd , @endd
  # Renders:       None
  # Description:   Date time converter
  ####################################################################
  def date_time_convertor
    if (((x = Date.strptime(params[:start_date],"%m/%d/%Y")) && (y = Date.strptime(params[:end_date],"%m/%d/%Y"))) rescue nil)
      @startd = Time.mktime(x.year, x.month, x.day, params[:start_hour], params[:start_minute], params[:start_second], +0100).to_i
      @endd   = Time.mktime(y.year, y.month, y.day, params[:end_hour], params[:end_minute], params[:end_second], +0100).to_i
    else
      @startd = 0
      @endd   = 0xFFFFFFFF
    end
  end
end