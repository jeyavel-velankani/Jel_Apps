class SetCfgPropertyiviuRequest < ActiveRecord::Base
  establish_connection :request_reply_db
  set_table_name "rr_set_prop_iviu_requests"
  set_primary_key :request_id

  def self.create_request(options = {})
    consist_id = RtConsist.last(:conditions => {:mcfcrc => Gwe.mcfcrc, :sin => options[:atcs_address]}, :select => 'consist_id').try(:consist_id)

    set_cfg_request = create({:request_state => ZERO, :atcs_address => options[:atcs_address],
    :command => options[:command], :mcf_type => options[:mcf_type], :number_of_cards => options[:number_of_cards]})

    if(options[:card_index].nil?)
      parameter = Parameter.find_all_by_mcfcrc(Gwe.mcfcrc, :conditions => {:name => options[:parameter_name], :parameter_type => options[:parameter_type]})
      parameter.each do |p|
        current_value = get_current_value(p)
        if(current_value.to_s != options[:value][p.name])
          card_info = RtCardInformation.find_by_consist_id_and_card_index(consist_id, p.cardindex)
          card = Card.find(:first, :select => "pci_ci, pci_ci_ver, crd_type", :conditions => {:card_index => p.cardindex, :crd_type => card_info.card_type, :mcfcrc => Gwe.mcfcrc})
          prop_iviu_card = SetPropIviuCard.create({:request_id => set_cfg_request.id, :card_number => p.cardindex,
                          :data_kind => options[:data_kind], :number_of_parameters => options[:number_of_parameters],
                          :pci_ci => card.pci_ci, :pci_ci_version => card.pci_ci_ver, :card_type =>  card.crd_type})
          param_long_name = (p.param_long_name != nil)? p.param_long_name.strip : ""
          value = value_name = options[:value][p.name]
          unit = ""
          if(p.data_type == "Enumeration")
            enumerator = EnumeratorsMcf.find_by_enum_type_name_and_value(p.enum_type_name, value)
            value_name = (enumerator)? enumerator.long_name : options[:value]
          elsif(p.data_type == "IntegerType")
            integertype = Integertype.find_by_int_type_name(p.int_type_name)
            unit = (integertype)? integertype.imperial_unit : ""
          end
          prop_card_params = SetPropIviuParam.create(:id_card => prop_iviu_card.id, :parameter_index => p.parameter_index + 1,
                          :context_string => p.context_string.strip, :parameter_name => param_long_name,
                          :value => value, :value_name => value_name, :unit => unit)
        end
      end
    else
      if(options[:card_type])
        card_info = RtCardInformation.find(:last, :conditions => ["consist_id = ? and card_type = ?", consist_id, options[:card_type]])
        parameter = Parameter.find_by_mcfcrc(Gwe.mcfcrc, :conditions => {:cardindex => card_info.card_index, :name => options[:parameter_name], :parameter_type => options[:parameter_type], :mcfcrc => Gwe.mcfcrc })
        card = Card.find(:first, :select => "pci_ci, pci_ci_ver, crd_type", :conditions => {:card_index => card_info.card_index, :crd_type => card_info.card_type, :mcfcrc => Gwe.mcfcrc})
      else
        card_info = RtCardInformation.find_by_consist_id_and_card_index(consist_id, options[:card_index])
        parameter = Parameter.find_by_mcfcrc(Gwe.mcfcrc, :conditions => {:cardindex => options[:card_index], :name => options[:parameter_name], :parameter_type => options[:parameter_type], :mcfcrc => Gwe.mcfcrc })
        card = Card.find(:first, :select => "pci_ci, pci_ci_ver, crd_type", :conditions => {:card_index => options[:card_index], :crd_type => card_info.card_type, :mcfcrc => Gwe.mcfcrc})
      end
      prop_iviu_card = SetPropIviuCard.create({:request_id => set_cfg_request.id, :card_number => parameter.cardindex,
                      :data_kind => options[:data_kind], :number_of_parameters => options[:number_of_parameters],
                      :pci_ci => card.pci_ci, :pci_ci_version => card.pci_ci_ver, :card_type =>  card.crd_type})
      param_long_name = (parameter.param_long_name != nil)? parameter.param_long_name.strip : ""
      value = value_name = options[:value]
      unit = ""
      if(parameter.data_type == "Enumeration")
        enumerator = EnumeratorsMcf.find_by_enum_type_name_and_value(parameter.enum_type_name, options[:value])
        value_name = (enumerator)? enumerator.long_name : options[:value]
      elsif(parameter.data_type == "IntegerType")
        integertype = Integertype.find_by_int_type_name(parameter.int_type_name)
        unit = (integertype)? integertype.imperial_unit : ""
        value_name = options[:value]
      end
      prop_card_params = SetPropIviuParam.create(:id_card => prop_iviu_card.id, :parameter_index => parameter.parameter_index + 1,
                      :context_string => parameter.context_string.strip, :parameter_name => param_long_name,
                      :value => options[:value], :value_name => value_name, :unit => unit)

    end
    set_cfg_request
  end

  def self.get_current_value(parameter)
    rt_parameter = RtParameter.find_by_mcfcrc(Gwe.mcfcrc, :conditions => {:parameter_name => parameter.name, :parameter_type => parameter.parameter_type, :card_index => parameter.cardindex})
    (rt_parameter.nil?)? nil: rt_parameter.current_value
  end

  # cleanup request
  def self.delete_request(id)
      req_id = id.to_i

      # Get all cards associated with request ID
      cards = SetPropIviuCard.find(:all, :conditions => {:request_id => req_id})

      # Delete all Parameters associated with each card
      for card in cards
        SetPropIviuParam.delete_all(:id_card => card.id_card) rescue nil
      end

      # Now delete request and associated cards
      SetCfgPropertyiviuRequest.delete_all(:request_id => req_id) rescue nil
      SetPropIviuCard.delete_all(:request_id => req_id) rescue nil

  end
end