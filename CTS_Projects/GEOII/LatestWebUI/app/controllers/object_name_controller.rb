####################################################################
# Company: Siemens 
# Author: Vijay Anand G
# File: object_name_controller.rb
# Description: This controller is used to GET the available object names from the GEo
#              and to update the objects names in the datbase.
####################################################################

class ObjectNameController < ApplicationController
  layout "general"
  include UdpCmdHelper

 ###################################################################
 # Function:      get_object_name
 # Parameters:    None
 # Return:        None
 # Renders:       none
 # Description:   This function will put a request for object names.
 ###################################################################
  #Method to get the available object names from the GEO.
  def get_object_name
    begin
      sin_value = Gwe.find(:first, :select => "sin").try(:sin) || ""
      if (params[:object_type_name] == "Object")
        sat_names = RtSatName.find(:all, :conditions => ["sin =?", sin_value])
        @obj_names = sat_names.collect{|u| {:id => u.sat_index, :obj_name => u.sat_name, :def_obj_name => u.default_sat_name}}
      else
        card_names = CardName.find(:all, :conditions => ["sin =?", sin_value])
        @obj_names = card_names.collect{|u| {:id => u.card_index, :obj_name => u.card_name, :def_obj_name => u.default_card_name}}
      end
      html_content = render_to_string(:partial => 'get_object_name')
      render :json => {:error => false, :html_content => html_content} and return
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end
  end

 ###################################################################
 # Function:      check_state
 # Parameters:    None
 # Return:        None
 # Renders:       none
 # Description:   This function is used to check the request state for 2 and render a page.
 ###################################################################
  #Method to check the request status.
  def check_state
    begin
      object_name_rq = ObjectName.find(params[:id])
      if(object_name_rq)
        if object_name_rq.request_state == 2
          delete_request(params[:id], REQUEST_GEO_OBJ_MSG)
          if(object_name_rq.result == 0)
            render :json => {:error => false, :request_state => object_name_rq.request_state, :message => "Successfully updated " + params[:object_type_name] + " Name"} and return
          else
            render :json => {:error => true, :request_state => object_name_rq.request_state, :message => "Failed to save " + params[:object_type_name] + " Name"} and return
          end
        else
          delete_request(params[:id], REQUEST_GEO_OBJ_MSG) if(params[:delete_request] == "true")
          render :json => {:error => false, :request_state => object_name_rq.request_state } and return
        end
      else
        render :json => {:error => true, :message => "Record not found" } and return
      end
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end
  end
  
 ###################################################################
 # Function:      object_name_update
 # Parameters:    None
 # Return:        None
 # Renders:       none
 # Description:   This function is used to update the card name.
 ###################################################################
  #Updating the object names in request/reply database.
  def object_name_update
    begin
      sin_value = Gwe.find(:first, :select => "sin").try(:sin) || ""
      object_name_rq = ObjectName.new(:request_state => 0, 
                                      :atcs_address => sin_value,
                                      :command => 2, 
                                      :name_type => params[:name_type], 
                                      :card_index => params[:obj_index], 
                                      :def_obj_name => params[:def_obj_name], 
                                      :new_obj_name => params[:new_obj_name])
      if(object_name_rq.save)
        udp_send_cmd(REQUEST_GEO_OBJ_MSG, object_name_rq.request_id)
        render :json => {:error => false, :request_id => object_name_rq.request_id} and return
      else
        render :json => {:error => true, :message => "Failed to create request record" } and return
      end
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end
  end
  
end
