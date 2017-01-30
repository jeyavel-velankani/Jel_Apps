module SessionHelper  
  ####################################################################
  # Function:      cpu_status_redirect
  # Parameters:    none
  # Retrun:        none
  # Renders:       none
  # Description:   cpu_status_redirect
  ####################################################################  
  #there are also local versions of this in controllers: 
  def cpu_status_redirect
    @redirect_flag = false
    @session = RtSession.find(:last, :select=>"comm_status,status,task_percent_completed")

    #if(@session.comm_status == nil )
      #redirect_to "/sessions/cpu_out_of_session?comm_status=0&status=10"
    if @session
        if @session.comm_status.to_i != 1 || @session.status.to_i != 10 || @session.comm_status == nil
          @redirect_flag = true
        end
        redirect_to "/sessions/cpu_out_of_session?comm_status="+@session.comm_status.to_s+"&status="+@session.status.to_s+"&task_percent_completed="+@session.task_percent_completed.to_s  unless !@redirect_flag
    else
        redirect_to "/sessions/cpu_out_of_session?comm_status=0"+"&status=0"
    end
  end
  
end