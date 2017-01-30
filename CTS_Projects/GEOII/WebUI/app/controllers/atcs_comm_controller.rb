class AtcsCommController < ApplicationController
  layout "general"
  include AtcscommHelper
  include UdpCmdHelper
  
  def index
    @sin = params[:atcs_add] 
    @gwe = Gwe.find(:last, :conditions => ["sin = ?", params[:atcs_add]], :select => "mcfcrc")
    if @gwe
      #session[:mcfcrc] = @gwe.mcfcrc
      rt_consist = RtConsist.find(:last, :select => "consist_id, mcfcrc", :conditions => ["sin = ? AND mcfcrc = ?", params[:atcs_add], @gwe.mcfcrc])
      @card_information = RtCardInformation.find(:all, :select => "card_index, card_type", :conditions => ["consist_id = ? and (slave_kind = 3 or slave_kind = 5)", rt_consist.consist_id])
      render :partial => "cardlist"
    end 
  end
  
  def get_online #(card_index,card_type,card_name,sin,mcfcrc,p_type)
    # make entry into the request/reply database
    online = RrGeoOnline.new
    online.request_state = 0
    online.atcs_address = params[:atcs_addr] + ".01"
    online.mcf_type = 0
    online.information_type = 3
    online.card_index = params[:type]
    online.save
    udp_send_cmd(105, online.request_id)
    render :text => online.request_id and return    
  end
  
  def check_state   
    online = RrGeoOnline.find_by_request_id(params[:id])
    if online.request_state == 2
      online_object = RrGeoOnline.create({:request_state => 0, :atcs_address => online.atcs_address, :mcf_type => 0, :information_type => 4, :card_index => online.card_index})
      udp_send_cmd(105, online_object.request_id)      
      render :json => {:request_state => 2, :request_id => online_object.request_id}
    else
      render :json => {:request_state => online.request_state}
    end
  end
  
  def check_sec_state
    @card_index = params[:cardindex]  
    @card_type = params[:card_type]
    @card_name = params[:cardname]
    @mcfcrc = params[:mcfcrc]
    @atcs_address = params[:atcs_addr]
    @online = RrGeoOnline.find_by_request_id(params[:id])
    
    if @online.request_state == 2
      @parameters = Parameter.all(:select => "DISTINCT name, parameter_type, parameter_index", :conditions => {:cardindex => params[:cardindex], :mcfcrc => params[:mcfcrc], :parameter_type => [3, 4]}, :order => "rowid")
      #render :text => "<span style='color:#FFF;'>#{@parameters.inspect}</span>"
      render :partial => 'cardinformation'
    else
      render :text => @online.request_state 
    end
  end
  
  def atcsaddress    
    @atcs_addresses = RtSession.find_atcs_addrs
    render :text => get_select_options(@atcs_addresses)
  end
  

  
  
end
