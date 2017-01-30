  class SessionsController < ApplicationController
  layout "general"

  include UdpCmdHelper


  def index 
    #not used
  end

  def get_sessions
    cpu_session = check_cpu_session
    alarms_session = check_alarms_status
    cdl_status = check_cdl_status

    if cpu_session[0] == 'ready'
      Gwe.refresh_mcfcrc
    end
    
    render :json => {:cpu => cpu_session,:alrams => alarms_session,:cdl => cdl_status}
  end

  def check_cdl_status
    status = CdlStatus.is_running? ? '1' : '0'
  end
  
  #*********************************************************************************************************
  # Gets CPU Session
  #*********************************************************************************************************
  def check_cpu_session
    session = RtSession.find(:first, :select=>"comm_status,status")

    if session
      if session.comm_status == 0
        return 'out_of_session'
      else
        if session.status == 0
          return 'connecting'
        elsif  session.status == 1
          return 'aux'
        elsif  session.status == 2
          return 'mcf'
        elsif  session.status == 3
          return 'rt'
        elsif  session.status == 4
          return 'pac'  #download
        elsif  session.status == 5
          return 'pac'  #upload
        elsif  session.status == 6
          return 'cal'
        elsif  session.status == 10
          return 'ready'
        else
          return 'out_of_session' #error
        end  
      end
    else
      return 'out_of_session'
    end
  end

  def cpu_out_of_session

    if params[:comm_status].to_i == 1

      if (params[:status].to_i >=0 && params[:status].to_i <=3)
        if ActiveRecord::Base.connection.tables.include?("Gwe")
          Gwe.reset_mcfcrc
        end
      end
       case  params[:status].to_i
          when 0
            @text = "Connecting To CPU..."
          when 1
           @text = "Processing Aux Files..."
           @text = @text + "#{params[:task_percent_completed].to_i}%" if !params[:task_percent_completed].blank?
         when 2
           @text = "Creating MCF Database..."
           @text = @text + "#{params[:task_percent_completed].to_i}%" if !params[:task_percent_completed].blank?
          when 3
           @text = "Creating Real Time Database..."
           @text = @text + "#{params[:task_percent_completed].to_i}%" if !params[:task_percent_completed].blank?
          when 4
           @text = "Downloading PAC Files..."
          when 5
           @text = "Uploading PAC Files..."
          when 6
           @text = "Calibrating..."
          else
            if ActiveRecord::Base.connection.tables.include?("Gwe")
              if Gwe.mcfcrc == 0
                Gwe.refresh_mcfcrc
                logger.info "*************** udating MCFCRC Class variable [#{Gwe.mcfcrc}] ***************"
              end
            end  
            @text = ""
        end
    else
      if ActiveRecord::Base.connection.tables.include?("Gwe")
        Gwe.reset_mcfcrc
      end
      
      @text = "CP is Out Of Session with VLP."
    end

    render :partial => "out_of_session"
  end

  #*********************************************************************************************************
  # alarms
  #*********************************************************************************************************
  def check_alarms_status
    return (get_alarms(false) == true ? 'alarms' : '')
  end

  def get_alarms_status
    render :text => (get_alarms(false) == true ? 'alarms' : '')
  end
  #*********************************************************************************************************
  # vlp
  #*********************************************************************************************************
   def vlp_unconfig
    @text = "VLP Unconfigured. Please try 'Set to Default'" if params[:cp_unconfig_status] && params[:cp_unconfig_status] != "0"
    render :partial => "out_of_session", :layout => true
  end

end