#*********************************************************************************
#File name    : dt_statistics_controller.rb

#Author       : Cognizant Technology Solutions

#Description  : This controller is used for diagnostic of statistics types.


#Project Name : iVIU - WebUI Project

#Copyright    : Safetran Systems Corporation, U.S.A. 
#                   Research and Development

#*********************************************************************************
class DtStatisticsController < ApplicationController
  
  layout 'general', :except=> [:loading, :index]
  include UdpCmdHelper
  require "socket"
  
  def index
    #RrGeoStatsRequest.delete_all
    #RrGeoStatsCardInfo.delete_all
    @atcs_addresses = RtSession.find_atcs_addrs
  end
  
  def UDP_call
    statsreq = RrGeoStatsRequest.new                                                                                                                
    statsreq.atcs_address = params[:atcs_add] + ".01"
    statsreq.stat_type = params[:statistics_type]
    statsreq.request_state=0                                                                                                      
    statsreq.save!
    udp_send_cmd(102, statsreq.request_id)
    render :text => statsreq.request_id    
  end
  
  def dtstatistics_process
    status = RrGeoStatsRequest.first(:conditions => ['request_id = ? AND request_state = ?', params[:id], 2])
    if status.blank?
      render :text => ""
    else
      @card_infos =  status.rr_geo_stats_card_infos.select{|card_info| card_info.vital_msgs_tx !=0}
      render :partial => RrGeoStatsRequest::STAT_TYPE[status.stat_type], :locals => {:statistic => status, :request_id => status.id }, :collection => {:card_infos => @card_infos} 
    end
  end
  
  def stats_clear
    statsreq = RrGeoStatsRequest.first(:conditions => ['request_id = ?', params[:id]])
    statsreq.update_attributes(:request_state => 0, :stat_cmd => 1)
    statsreq.save
    render :text => statsreq.request_id
    udp_send_cmd(102, statsreq.request_id)
  end
  
  def dtstatistics_update_process
    status = RrGeoStatsRequest.first(:conditions => ['request_id = ? AND request_state = ?', params[:id], 2])
    respond_to do |format|
      format.js do
        if status.blank?
          render :text => ""
        else
          @card_infos =  status.rr_geo_stats_card_infos.select{|card_info| card_info.vital_msgs_tx !=0}
          if status.stat_type == 4
            @card_infos.each do |card_info|
              card_info.update_attributes(:mean => 0, :max => 0, :min => 0)
              card_info.save
            end
          elsif status.stat_type == 0
            @card_infos.each do |card_info|
              card_info.update_attributes(:bad_crcs => 0, :lost_sessions => 0, :reboots => 0)
              card_info.save
            end
          elsif status.stat_type == 6
            status.update_attributes(:invalid_pkts_recvd => 0, :valid_pkts_recvd => 0, :pkts_transmitted => 0)
          elsif status.stat_type == 1
            @card_infos.each do |card_info|
              card_info.update_attributes(:out_of_order => 0, :stale => 0, :lost_sessions => 0, :vital_msgs_tx => 0, :vital_msgs_rx => 0)
              card_info.save
            end
          elsif status.stat_type == 2
            @card_infos.each do |card_info|
              card_info.update_attributes(:out_of_order => 0, :lost_sessions => 0, :indication_msgs_transmitted => 0, :recall_msgs_recvd  => 0, :control_msgs_recvd => 0)
              card_info.save
            end
          elsif status.stat_type == 5
            status.update_attributes(:bad_sio_pkt_cnt => 0, :sio_tx_pkt_cnt => 0, :sio_rx_pkt_cnt => 0, :spi_tx_q_full_cnt  => 0, :spi_rx_q_full_cnt => 0)
            status.save
          elsif status.stat_type == 7
            status.update_attributes(:invalid_lan_pkts => 0, :valid_lan_rx_pkts => 0, :valid_lan_tx_pkts => 0)
          elsif status.stat_type == 8
              status.update_attributes(:vlp_reboots => 0)
          end
          render :partial => RrGeoStatsRequest::STAT_TYPE[status.stat_type], :locals => {:statistic => status, :request_id => status.id}, :collection => {:card_infos => @card_infos}
        end
      end
    end
  end
  
  def renew
    statsreq = RrGeoStatsRequest.new                                                                                                                
    statsreq.atcs_address = params[:atcs_add] + ".01"
    statsreq.stat_type = params[:statistics_type]
    statsreq.request_state=0                                                                                                      
    statsreq.save!
    render :text => statsreq.request_id
    udp_send_cmd(102, statsreq.request_id)
  end
end