class SoftwareInformationController < ApplicationController
  layout false
  include ApplicationHelper
  include UdpCmdHelper
  
  def index
    @atcs_addr = RtSession.find_atcs_addrs
  end
  
  def soft_info
    gwe = Gwe.find(:last, :conditions => ["sin = ?", params[:atcs_addr]])
    rt_consist = RtConsist.consist_id(params[:atcs_addr], gwe.mcfcrc)
    card_information = RtCardInformation.find_card_information(rt_consist.consist_id).sort{|a, b| a.slot_atcs_devnumber <=> b.slot_atcs_devnumber }
    cp_card = nil
    card_information.each_with_index{|card,index| 
      cp_card = [index, card] if(card.card_type == 10)
    }
    
    @soft_info = Array.new
    initialize_rt_comm_status(card_information, params[:atcs_addr], gwe.mcfcrc)
    
    generate_report(gwe)
    
    # here create request to get Cp details
    if !cp_card.nil?
      insert_io_request(cp_card[1], params[:atcs_addr], gwe, 10)
      card_information.delete_at(cp_card[0])
    else
      cp_info = Card.find_by_mcfcrc(gwe.mcfcrc, :last, :conditions => ["layout_index = ? and crd_type = 10 and crd_name like 'CP%'", gwe.active_physical_layout])  
      insert_io_request({:card_index => cp_info.card_index}, params[:atcs_addr], gwe, 10) if(cp_info)
    end
    # For each RT Card Information
    card_information.each do |card_info|
      active_card = get_card_health(card_info.card_index, params[:atcs_addr], gwe.mcfcrc)
      
      # Insert IO request for each card
      insert_io_request(card_info, params[:atcs_addr], gwe, card_info.card_type) if active_card && active_card == "0"
    end
    @file.close
    render :partial => "card_information", :locals => {:sw_info => @soft_info, :gwe => gwe}
  end
  
  def download_report
    begin
      send_file("doc/software_information.txt", :filename => "geo_version_report_#{Time.now.to_i}.txt", :type => "application/octet-stream", :disposition => "attachment", :encoding => "utf8")
    rescue Exception => e
      render :text => "<p style='color:#FFF'>Exception Raised: #{e.message}</p>"
    end
  end
  
  private
  
  def generate_report(gwe)
    @file = File.open("doc/software_information.txt", "w")    
    @file.chmod(777)
    
    @file.puts "\r\n*********************************************************************\r\n"
    @file.puts "\r\n  Geo Version Report - #{Time.now.strftime('%A, %b %d %Y %H:%M %p')}\r\n"
    @file.puts "\r\n*********************************************************************\r\n"
    @file.write("\r\n\r\n--- System Information ---\r\n")
    @file.write("\r\n Module Type:            #{mod_type(gwe.try(:mef_version))}")
    @file.write("\r\n MEF Version:            #{gwe.try(:mef_version)}")
    @file.write("\r\n MEF/MCF CI:             #{gwe.try(:mef_mcf_ci)}")
    @file.write("\r\n MEF/HW CI:              #{gwe.try(:mef_hw_ci)}")
    @file.write("\r\n UCN:                    #{gwe.try(:ucn)}")
    @file.write("\r\n MEFCRC:                 #{dec2hex(gwe.try(:mefcrc))}")
    @file.write("\r\n In/Out Serv. Check No:  #{dec2hex(gwe.try(:in_out_service_check_number))}")
    @file.write("\r\n MCF Name:               #{gwe.try(:mcf_name)}")
    @file.write("\r\n Location:               #{gwe.try(:mcf_location)}")
    @file.write("\r\n MCFCRC:                 #{dec2hex(gwe.try(:mcfcrc))}")
    @file.write("\r\n MCF Revision:           #{gwe.try(:mcf_revision)}")
    @file.write("\r\n Config Check Number:    #{ccn_swap(dec2hex(gwe.try(:config_check_word)))} \r\n\r\n")
  end  
  
  # Inserting IO Request for selected ATCS Address and related card
  def insert_io_request(card_info, atcs_address, gwe, card_type=nil)
    online = RrGeoOnline.new
    online.request_state = 0
    online.atcs_address = (atcs_address + ".01")      
    online.mcf_type = card_type == 10 ? 1 : 0  # If Card type is 10(means CP card) mcf type is 1 else 0
    online.information_type = 10
    online.card_index = card_type == 10 ? card_info[:card_index] : card_info.card_index
    online.save
    # Sending UDP Request
    udp_send_cmd(105,online.request_id)
    flag = 0
    counter = 0
    
    until flag == 2
      sleep 1 # Stopping process for 1 second
      io_request = RrGeoOnline.find_by_request_id(online.request_id)
      if io_request.request_state == 2
        flag = 2 # If request is 2 assigning flag = 2 to break the until loop.
        card = get_card(card_type, gwe)
        io_status_reply = Iostatusreply.find_by_request_id(online.request_id)
        parameters = Parameter.all(:conditions => {:cardindex => online.card_index, :mcfcrc => gwe.mcfcrc, :parameter_type => 5}, :select => "distinct name", :order => "rowid" )
        @replies = get_replies(gwe.try(:mef_version), io_status_reply)
        io_status_reply.try(:iostatusvalues).try(:each) do |status_val|
          @replies << status_val.sw_id
          @replies << status_val.mef_crc
        end
        slot_num = card_type == 10 ? 1 : card_info.slot_atcs_devnumber
        @file.write("\r\n\r\n\r\n\r\n Slot #{slot_num}:  #{card.crd_name}\r\n")
        info = render_to_string(:partial => "software_information", :locals => {:parameters => parameters, :card_name => card.crd_name, :slot_num => slot_num})
        @soft_info << info
      end
      if counter == 4
        flag = 2
      end
      counter += 1
    end
    
  end
  
  def get_card(card_type, gwe)
    Card.find_by_mcfcrc(gwe.mcfcrc, :conditions => {:layout_index => gwe.active_physical_layout, :crd_type => card_type}, :select => "crd_name")
  end
  
  def get_replies(mef_version, io_status_reply)
    replies = []
    replies << io_status_reply.try(:verbosity)
    #replies << mef_version
    replies << io_status_reply.try(:version)
    replies << io_status_reply.try(:number_of_ids)
  end
  
end