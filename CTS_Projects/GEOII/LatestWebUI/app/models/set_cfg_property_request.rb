class SetCfgPropertyRequest < ActiveRecord::Base
  establish_connection :request_reply_db

  set_primary_key "request_id"
  set_table_name "rr_set_cfg_prop_requests"

  class << self

    # Initiate calibration request
    def initiate_calibration(atcs_address, card_index, rt_parameter, text_value, pci_ci, atcs_dev_number, calib_command)
      create({:request_state => ZERO, :atcs_address => atcs_address,
      :command => calib_command, :subcommand => CALIBRATION_SUBCMD, :data_kind => CALIB_DATA_KIND, :card_index => card_index,
      :pci_ci => pci_ci, :text_value => text_value, :value => CALIB_VALUE, :confirmed => CALIB_CONFIRMED,
      :slave_kind => CALIB_SLAVE_KIND, :parameter_type => 3, :slot_or_atcs_device_no => atcs_dev_number,
      :parameter_name => rt_parameter.parameter_name, :property_index => (rt_parameter.parameter_index + 1), :card_type => CALIB_CARD_TYPE})
    end

    def create_request(options = {})
      consist_id = RtConsist.last(:conditions => {:mcfcrc => Gwe.mcfcrc, :sin => options[:atcs_address]}, :select => 'consist_id').try(:consist_id)
      if(options[:card_index].nil?)
        parameter = Parameter.find_by_mcfcrc(Gwe.mcfcrc, :conditions => {:name => options[:parameter_name], :parameter_type => options[:parameter_type]})
        card_info = RtCardInformation.find_by_consist_id_and_card_index(consist_id, parameter.cardindex)
        card = Card.find(:first, :select => "pci_ci", :conditions => {:card_index => parameter.cardindex, :crd_type => card_info.card_type, :mcfcrc => Gwe.mcfcrc})
      else
        if(options[:card_type])
          card_info = RtCardInformation.find(:last, :conditions => ["consist_id = ? and card_type = ?", consist_id, options[:card_type]])
            card = Card.find(:first, :select => "pci_ci", :conditions => {:card_index => card_info.card_index, :crd_type => card_info.card_type, :mcfcrc => Gwe.mcfcrc})
            parameter = Parameter.find_by_mcfcrc(Gwe.mcfcrc, :conditions => {:cardindex => card_info.card_index, :name => options[:parameter_name], :parameter_type => options[:parameter_type]})
        else
          card_info = RtCardInformation.find_by_consist_id_and_card_index(consist_id, options[:card_index])
            card = Card.find(:first, :select => "pci_ci", :conditions => {:card_index => options[:card_index], :crd_type => card_info.card_type, :mcfcrc => Gwe.mcfcrc})
          parameter = Parameter.find_by_mcfcrc(Gwe.mcfcrc, :conditions => {:cardindex => options[:card_index], :name => options[:parameter_name], :parameter_type => options[:parameter_type]})
        end
      end
      if(options[:force_text_value])
        text_value = options[:force_text_value]
      elsif(parameter.data_type == "Enumeration")
        enumerator = EnumeratorsMcf.find_by_enum_type_name_and_value(parameter.enum_type_name, options[:value])
        text_value = (enumerator)? enumerator.long_name : options[:value]
      else
        text_value = options[:value]
      end
      create({:request_state => ZERO, :atcs_address => options[:atcs_address] + ".02",
      :command => options[:command], :subcommand => options[:subcommand], :data_kind => options[:data_kind], :card_index => parameter.cardindex,
      :pci_ci => card.pci_ci, :text_value => text_value, :value => options[:value], :confirmed => 0, :context_string => parameter.context_string,
      :slave_kind => card_info.slave_kind, :parameter_type => parameter.parameter_type, :slot_or_atcs_device_no => card_info.slot_atcs_devnumber,
      :parameter_name => parameter.name, :property_index => (parameter.parameter_index + 1), :card_type => card_info.card_type})
    end

    # cleanup request
    def delete_request(id)
        SetCfgPropertyRequest.delete_all(:request_id => id.to_i) rescue nil
    end

  end

end