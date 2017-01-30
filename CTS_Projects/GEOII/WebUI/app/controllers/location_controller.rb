
####################################################################
# Company: Siemens 
# Author: Gopu
# File: location_controller.rb
# Description: This controller is used for GET and SET the Location Settings for the GEO
####################################################################

class LocationController < ApplicationController
  include UdpCmdHelper

 ###################################################################
 # Function:      check_state
 # Parameters:    params[:id]
 # Return:        None
 # Renders:       json
 # Description:   This function is Method to check the request status.
 ###################################################################
  #Method to check the request status.
  def check_state
    begin
        set_location_rq = Location.find_by_request_id(params[:id])
        if(!set_location_rq.blank?)
            if set_location_rq.try(:request_state) == 2
                if(!set_location_rq.dot_number.nil?)
                  dot_number = set_location_rq.dot_number.strip[0..6]
                else
                  dot_number = "" 
                end
                location = set_location_rq.dup
                mile_post = ''
                site_name = ''
                mile_post = location.mile_post.strip[0..10] if(!location.mile_post.nil?)
                site_name = location.site_name.strip[0..24] if(!location.site_name.nil?)
                locals =  {:dot_number => dot_number, :mile_post => mile_post,  :site_name => site_name, :location => location,:atcs_address =>set_location_rq.atcs_address,:request_id => set_location_rq.request_id}
                delete_request(params[:id], REQUEST_COMMAND_LOCATION)
                html_content = render_to_string(:partial => "location_settings", :locals => locals)
                render :json => {:error => false, :request_state => set_location_rq.request_state, :html_content => html_content} and return
            else
                delete_request(params[:id], REQUEST_COMMAND_LOCATION) if(params[:delete_request] == "true")
                render :json => {:error => false, :request_state => set_location_rq.request_state } and return
            end
        else
             render :json => {:error => true, :message => "Record not found" } and return
        end
    rescue Exception => e
        render :json => {:error => true, :message => e.message}
    end
  end

 ###################################################################
 # Function:      get_location
 # Parameters:    None
 # Return:        None
 # Renders:       json
 # Description:   This Method to get the available location settings from the GEO.
 ###################################################################
  #Method to get the available location settings from the GEO.
  def get_location
    begin
        gwe_info = Gwe.find(:first, :select => "sin")
        if gwe_info      
          @sin_value = gwe_info[:sin].to_s
        else
          @sin_value = ""
        end
        @set_location_rq = Location.create_location(@sin_value)
        if @set_location_rq
          udp_send_cmd(REQUEST_COMMAND_LOCATION, @set_location_rq.request_id)
          html_content = render_to_string(:partial => "get_location")
          render :json => {:error => false, :html_content => html_content, :location_request => true} and return
        else
           render :json => {:error => true, :message => "Failed to get Location parameters" } and return
        end
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end
  end
  
 ###################################################################
 # Function:      location_update
 # Parameters:    params[:dot_number],params[:site_name],params[:mile_post],
 # Return:        None
 # Renders:       json :request_id
 # Description:   This function is for Updating the location values in request/reply database.
 ###################################################################
  #Updating the location values in request/reply database.
  def location_update
    begin   
        dot_number = params[:dot_number]
        
        # Appending leading zero's to the dot number if dot number size is less than 6 
        dot_number = ("0"*(7 - dot_number.size)) + dot_number  if dot_number.size < 7
        
        site_name = params[:site_name]
        site_name_length = params[:site_name].size    
        if site_name_length < 25
         (25 - site_name_length).times do
            site_name += " "
          end
        end
        
        mile_post = params[:mile_post]
        mile_post_size = params[:mile_post].size
        if mile_post_size < 11
         (11 - mile_post_size).times do
            mile_post += " "
          end
        end    
        
        geo_dotnumber = dot_number
        
        location = Location.new(:request_state => 0, :command => 2, 
              :dot_number => geo_dotnumber, :atcs_address => params[:atcs_address])
              
        location.mile_post = mile_post      
        location.site_name = site_name      
        location.request_id = params[:request_id]
        location.ci = params[:ci]
        location.ci_version = params[:ci_version]
        location.filler = " "
        location.latitude_filler = " "
        location.longitude_filler = " "
        location.latitude_degrees = params[:latitude_degrees].split('-').first || 0
        location.longitude_degrees = params[:latitude_degrees].split('-').last || 0
        location.latitude_min = params[:latitude_min].split('-').first || 0
        location.longitude_min = params[:latitude_min].split('-').last || 0
        location.latitude_sec = params[:latitude_sec].split('-').first || 0
        location.longitude_sec = params[:latitude_sec].split('-').last || 0
        location.latitude_tenths = params[:latitude_tenths].split('-').first || 0
        location.longitude_tenths = params[:latitude_tenths].split('-').last || 0
        location.latitude_direction = params[:latitude_direction].split('-').first || 0
        location.longitude_direction = params[:latitude_direction].split('-').last || 0
        
        location.save!
        
        if location
          udp_send_cmd(REQUEST_COMMAND_LOCATION, location.id)
          render :json => {:error => false, :request_id => location.request_id} and return
        else
           render :json => {:error => true, :message => "Error creating request" } and return
        end 
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end
  end  
  
end
