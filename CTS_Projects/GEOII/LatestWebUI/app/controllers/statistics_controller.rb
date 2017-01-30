####################################################################
# Company: Siemens 
# Author: 
# File: StatisticsController
# Description: Display Statistics
####################################################################

#-----------------------------------------------------------------------------------------------------
#History:
#*    Rev 1.0   Jul 05 2013 17:00:00   Gopu
#* Initial revision.
#-----------------------------------------------------------------------------------------------------

class StatisticsController < ApplicationController
  include UdpCmdHelper
  include SessionHelper
  
  before_filter :cpu_status_redirect  #session_helper
  
  layout "general", :except => ["loading", "set_filter"]
  
  ####################################################################
  # Function:      index
  # Parameters:    @atcs_address
  # Retrun:        none
  # Renders:       none
  # Description:   Default action used to render initial view.
  ####################################################################
  def index
    @atcs_address ||= Gwe.atcs_address
    @cpu_type = Menu.cpu_3_menu_system
  end
  
  ####################################################################
  # Function:      create_request
  # Parameters:    @newrequest
  # Retrun:        none
  # Renders:       text/json 
  # Description:   Creates an entry in the "request" database and sends a UDP command to backend.
  ####################################################################
 def create_request
    atcs_address = params[:atcs_add]
    stats_type   = params[:statistics_type].to_i
    statistics_cmd   = params[:statistics_cmd].to_i

    
    @newrequest = RrGeoStatsRequest.new({:atcs_address  => atcs_address,
                                         :request_state => REQUEST_STATE_START,
                                         :stat_type     => stats_type,
                                         :stat_cmd      => statistics_cmd
                                        })
    if(@newrequest.save)
      udp_send_cmd(REQUEST_COMMAND_GEO_STATISTICS,@newrequest.request_id)
      render :json => {:req_id    => @newrequest.request_id,
                       :req_state => @newrequest.request_state}
    else
      render :text => '<h1>Error creating request.</h1>'
    end
  end
  
  ####################################################################
  # Function:      check_request_status
  # Parameters:    currentrequest
  # Retrun:        none
  # Renders:       text/json
  # Description:   Gets the request status of the current request ID and send it back to caller
  ####################################################################
  def check_request_status
    curr_req_id = params[:requestid]
    currentrequest = RrGeoStatsRequest.find(curr_req_id) rescue nil
    if(currentrequest)
      delete_request(params[:request_id], REQUEST_COMMAND_GEO_STATISTICS) if(params[:delete_request] == "true" || currentrequest.request_state == 2)
      render :json => {:req_state => currentrequest.request_state}
    else
      render :text => '<h1>Error checking request status... Request does not exist</h1>'
    end
  end
  
  ####################################################################
  # Function:      get_stats_info
  # Parameters:    params[:requestid]
  # Retrun:        none
  # Renders:       partial/text 
  # Description:   Gets statistics data and preps it for rendering
  ####################################################################
  def get_stats_info
    curr_req_id = params[:requestid]
    no_stats_found_msg  = "<h1>No statistics data found</h1>"
    @currentrequest = RrGeoStatsRequest.find(curr_req_id) rescue nil
    if( @currentrequest )
      @cards = RrGeoStatsCardInfo.find(:all,:conditions => {:request_id => curr_req_id})
      case @currentrequest.stat_type
      when CARD_STATS_ID
        if(@cards)
          render :partial => 'card_stats', :content_type => 'text/html'
        else
          render :text => no_stats_found_msg
        end
      when VITAL_STATS_ID
        if(@cards)
          render :partial => 'vital_atcs_stats', :content_type => 'text/html'
        else
          render :text => no_stats_found_msg
        end
      when NONVITAL_STATS_ID
        if(@cards)
          render :partial => 'nonvital_atcs_stats', :content_type => 'text/html'
        else
          render :text => no_stats_found_msg
        end
      when TIME_STATS_ID
        if(@cards)
          render :partial => 'time_stats', :content_type => 'text/html'
        else
          render :text => no_stats_found_msg
        end
      when SIO_STATS_ID
        render :partial => 'sio_stats', :content_type => 'text/html'
      when CONSOLE_STATS_ID
        render :partial => 'console_stats', :content_type => 'text/html'
      when LAN_STATS_ID
        render :partial => 'lan_stats', :content_type => 'text/html'
      when VLP_STATS_ID
        render :partial => 'vlp_stats', :content_type => 'text/html'
      when PTC_STATS_ID
        @ptc_stats = RrGeoPtcStats.find(:first,:conditions => {:request_id => curr_req_id})
        render :partial => 'ptc_stats', :content_type => 'text/html'        
      else
        render :text => "<h2>Unknown Statistics Type Found</h2>"
      end
    else
      render :text => "<h2>Request ID not Found</h2>"
    end
  end
  
  ####################################################################
  # Function:      database_cleanup
  # Parameters:    params[:requestid]
  # Retrun:        none
  # Renders:       :text => "Database cleanup complete"
  # Description:   Clean up database enties
  ####################################################################
  def database_cleanup
    request_id = params[:requestid]
    RrGeoStatsRequest.delete_all(:request_id => request_id) rescue nil
    RrGeoStatsCardInfo.delete_all(:request_id => request_id)  rescue nil
    render :text => "Database cleanup complete"
  end

end 
