class SetupController < ApplicationController
  layout "general"

  include UdpCmdHelper
  include IoStatusViewHelper
  include SessionHelper
  
  before_filter :cpu_status_redirect  #session_helper

	  def lamps 
      @method_name = 'lamps';
      card_type = [2,3]

      @parameter_names = []
      @parameter_names[2] = ['LampVoltage','PCO1CorrespondenceTime','PCO2CorrespondenceTime']
      @parameter_names[3] = ['LampVoltage']

      @setup_type = []
      @setup_type[2] = 'source_light';
      @setup_type[3] = 'lamps';

      build_track_cards('io',card_type)  #in IoStatusViewHelper

      render :template => 'setup/cards'
  	end

    def refresh_lamps_table
      build_track_cards('io',[2,3])  #in IoStatusViewHelper

      render :json => @tracks
    end

    def save_lamp_data
      parameters_values = {}

      parameter_type = 2

      card_index = params[:card_index]
      card_type = params[:card_type]
      
      if card_index 
        save(card_index,card_type,parameter_type,params)
      else
        render :json => {:error => true, :message => "card index is not set"}
      end
    end

    def tracks 
      @method_name = 'tracks';
      card_type = [1,4,48]
      @parameter_names = []
      @parameter_names[1] = ['VCOVoltage2','CurrentLimit']
      @parameter_names[4] =  ['TransmitVoltage','ReceiveThreshold']
      @parameter_names[48] =  ['GTTrkLength']

      @setup_type = []
      @setup_type[1] = 'tracks';
      @setup_type[4] = 'line';
      @setup_type[48] = 'geo_tracks';
      build_track_cards('io',card_type)  #in IoStatusViewHelper

      render :template => 'setup/cards'
    end

    def save_track_data
      parameters_values = {}

      parameter_type = 2

      card_index = params[:card_index]
      card_type = params[:card_type]
      
      if card_index 
        save(card_index,card_type,parameter_type,params)
      else
        render :json => {:error => true, :message => "card index is not set"}
      end
    end

    def refresh_tracks_table
      build_track_cards('io',[1,4,48])  #in IoStatusViewHelper

      render :json => @tracks
    end
    

    def save(card_index,card_type,parameter_type,parameters)
      out_range = ''

      if Gwe.mcfcrc != 0
        card_info = Card.find(:first, :conditions =>['card_index = ? and crd_type = ? and parameter_type = ? and mcfcrc = ?',card_index,card_type,parameter_type,Gwe.mcfcrc])

        if !card_info.blank?
          values_valid = true

          number_of_parameters = 0

          #indexes through all parameters and 
          parameters.each_with_index  do |value,parameter_index|
            parameter_name = value[0]
            value = value[1]


            if parameter_name != 'card_index' && parameter_name != 'controller' && parameter_name != 'action' && parameter_name != 'card_type'
            
              parameter_info = Parameter.find(:first, :conditions =>['cardindex = ? and name = ? and parameter_type = ?',card_index,parameter_name,parameter_type])

              if parameter_info 
                #gets data to validate the value
                integertypes_info  = Integertype.find(:first, :conditions => ['int_type_name = ?',parameter_info.int_type_name])

                scaled_value = (value.to_i*1000) / integertypes_info.scale_factor

                if integertypes_info.lower_bound > scaled_value || scaled_value > integertypes_info.upper_bound
                  out_range += parameter_name+'=> should be between '+(integertypes_info.lower_bound.to_i*integertypes_info.scale_factor.to_i/1000).to_s+' and '+(integertypes_info.upper_bound.to_i*integertypes_info.scale_factor.to_i/1000).to_s+','
                  values_valid = false
                end
              end

              number_of_parameters += 1
            end
          end
          #*1000/scale
          if out_range != ''
            out_range = out_range[0..-1]
          end

          if values_valid

            # table_name "rr_set_prop_iviu_requests"
            rr_set_prop_iviu_requests = SetCfgPropertyiviuRequest.new(:request_state => 0,:atcs_address => Gwe.atcs_address,:command => 12,:mcf_type => 0,:number_of_cards => 1)
            rr_set_prop_iviu_requests.save

            #table_name "rr_set_prop_iviu_cards"
            rr_set_prop_iviu_cards = SetPropIviuCard.new(:request_id =>rr_set_prop_iviu_requests.id, :card_number => card_index, :card_type => card_type, :data_kind => 0, :pci_ci => card_info.pci_ci, :pci_ci_version => card_info.pci_ci_ver, :number_of_parameters => number_of_parameters)
            rr_set_prop_iviu_cards.save

            parameters.each  do |value|
              parameter_name = value[0]
              value = value[1]        

              if parameter_name != 'card_index' && parameter_name != 'controller' && parameter_name != 'action' && parameter_name != 'card_type'
                 parameter_info = Parameter.find(:first, :conditions =>['mcfcrc =? and layout_index =? and cardindex = ? and name = ? and parameter_type = ?',Gwe.mcfcrc,Gwe.physical_layout,card_index,parameter_name,parameter_type])

                if parameter_info 


                  #gets data to validate the value
                  integertypes_info = Integertype.find(:first, :conditions => ['int_type_name = ?',parameter_info.int_type_name])

                  # table_name "rr_set_prop_iviu_params"
                  rr_set_prop_iviu_params = SetPropIviuParam.new(:id_card => rr_set_prop_iviu_cards.id, :parameter_index => (parameter_info.parameter_index+1), :parameter_name => parameter_info.param_long_name, :value => value, :value_name => value, :context_string => parameter_info.context_string, :unit => integertypes_info.metric_unit)
                  rr_set_prop_iviu_params.save
                end
              end
            end
            
            #sends udp command to save the mcf parameter
            udp_send_cmd(12, rr_set_prop_iviu_requests.id)

            render :json => {:error => false, :request_id => rr_set_prop_iviu_requests.id }
          else
            render :json => {:error => true, :message => '',:errors => out_range }
          end
        else
          render :json => {:error => true, :message => 'Card information is unknown',:errors => out_range }
        end
      else
        render :json => {:error => true, :message => 'MCFCRC is unknown',:errors => out_range }
      end
    end

    def check_save
      rr_set_prop_iviu_requests = SetCfgPropertyiviuRequest.find(:first,:conditions=>['request_id = ?',params[:request_id]])

      if rr_set_prop_iviu_requests.request_state == 2
        
        #checks if the request was good
        if rr_set_prop_iviu_requests.confirmed == 0
          parameter_type = 2

          card_index = params[:card_index]
          card_type = params[:card_type]

          parameters = params
          parameters.each_with_index  do |value,parameter_index|
            parameter_name = value[0]
            value = value[1]


            if parameter_name != 'card_index' && parameter_name != 'controller' && parameter_name != 'action' && parameter_name != 'card_type' && parameter_name != 'request_id'
            
              parameter_info = Parameter.find(:first, :conditions =>['cardindex = ? and name = ? and parameter_type = ?',card_index,parameter_name,parameter_type])

              integertypes_info  = Integertype.find(:first, :conditions => ['int_type_name = ?',parameter_info.int_type_name])

              scaled_value = (value.to_i*1000) / integertypes_info.scale_factor
                
              if parameter_info 

                RtParameter.update_all("current_value = #{scaled_value.to_i}", :mcfcrc => Gwe.mcfcrc, :card_index => card_index,:parameter_type => parameter_type, :parameter_name => parameter_name)
              end
            end
          end

          json_var =  {:error => false, :message => "Saved Successfully.",:request_state =>2, :confirmed => 200}
        else
          json_var =  {:error => true, :message => "Error Saving.",:request_state =>2, :confirmed => 400}
        end

        #delete all 
        SetCfgPropertyiviuRequest.delete_all "request_id = #{params[:request_id]}"
        SetPropIviuCard.delete_all "request_id = #{params[:request_id]}"
        SetPropIviuParam.delete_all "id_card = #{params[:request_id]}"

        render :json => json_var
      else
        render :json => {:request_state =>rr_set_prop_iviu_requests.request_state, :confirmed => 100}
      end
    end

    def get_cards
      @atcs_addresses = atcs_address        #in application helper

      session[:timestamp] = nil

      io_status_request = 0
      @gwe = Gwe.get_mcfcrc(@atcs_addresses)
      @unconfig_page = false
      
      #determines view_type from 
      @view_type = get_view_type_helper

      #gets 
      io_view = IoView.find_view(@atcs_addresses, @gwe.mcfcrc, @view_type)
      if io_view && io_view.status == 1  

        #gets all pf the cards    
        @cards = IoViewCard.get_cards(@atcs_addresses, @gwe.mcfcrc, @view_type)   

        @active_cards = []

        @cards.each do |card|
          if !@active_cards.include?(card.card_type)
            @active_cards << card.card_type;
          end
        end
      end

      render :template => '/setup/left_menu', :layout => false
    end

    def no_cards
      render :text => ""
    end
end
           