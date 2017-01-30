class SystemstateViewController < ApplicationController
  layout "general", :except=>"loading"
  include UdpCmdHelper
  require "socket"
  
  def index
    
    @satname = RtSatName.find(:all, :select => 'id,sat_name')
    
    @current_page_name =  params[:id]
    
    if @current_page_name == nil
      #@node = LsCategories.find_by_sql "Select DISTINCT parent FROM ls_categories order by parent"
    end
  end
  
  def page_node
    if params[:node_value]
      session[:node_value]=params[:node_value]
      #@page = LsCategories.find_by_name(session[:node_value])
      render :partial=>'systemstateviewparams'
    end
  end
  
  def UDP_call 
    @cur_id = params[:id]
    @cur_name = params[:name]
    @start = LsCategories.find(:first, :select => 'min', :conditions => ['parent = ? AND name = ?',@cur_id,@cur_name])
    @end = LsCategories.find(:first, :select => 'max', :conditions => ['parent = ? AND name = ?',@cur_id,@cur_name])
    @rrisreq = IsRequest.new()
    @rrisreq.request_state = 0
    @rrisreq.atcs_address = @atcs_addr
    @rrisreq.command = 14
    @rrisreq.start_is_number = @start.min
    @rrisreq.end_is_number = @end.max
    @rrisreq.save
    @id = @rrisreq.request_id                                                                                                                   
    session[:event_log]=@id
    session[:start]= @rrisreq.start_is_number
    session[:end]= @rrisreq.end_is_number
    sync_eventlog(@id, @rrisreq.command)         
  end                                                                                                                                         
  
  def sync_eventlog(id,command)  
    @command = command                                                                                                                        
    @id = id                                                                                                                                  
    #@state = state                                                                                                                           
    @request_state = 2                                                                                                                    
    
    flash[:notice]=@id                                                                                                               
    @check_status = IsRequest.find(:all, :select=>'request_id', :conditions=>['request_state = ? AND request_id=?', @request_state, @id])
    if @check_status               
      session[:event_id]= @id                                                                                               
      session[:signal]= 0
      @flag=1;
      redirect_to :controller=>"systemstate_view", :action=>'loading' , :id => @check_status, :event_id=>session[:event_id], :signal=>session[:signal]
    end                                                                                                                      
  end  
  
  def loading
    if params[:signal]
      session[:signal] = params[:signal]
    end
    if session[:signal]!=0
      @signal=session[:signal]
    end
    if session[:signal]==0
      @signal=session[:signal]
    end
  end
  
  def systemstate_process                                                                                                                         
    @id=session[:event_id]                                                                                                                      
    @state=2                                                                                                                                   
    
    status = IsRequest.find(:all, :conditions => ['request_id = ? AND request_state = ?',@id,@state]);                                    
    if status                                                                                                                             
      flash[:notice]= status
      IsRequest.delete_requestid(@id)                                                                                           
      # remove_record(@id) 
      session[:signal]=2                                                                                                                  
      @signal = 2 
      
      render :update do |page|
        page.replace_html  'systemstateviewparams', :partial=>'systemstateview'
      end                                                                                                                                  
      IsReply.delete_requestid(session[:event_id])
      
    end                                                                                                                                    
  end  
end
