module LogrepliesHelper
  
  def verbosity_to_s(verbosity)
    ['Basic', 'Error', 'Warning', 'Info', 'Debug'][verbosity.to_i] || "Unknown"
  end
  
  def log_data_variables(search_box = false)
    l = []
    if (@log_type || params[:id]).to_i != 6
        l= [["Time Stamp", 'timestamp', 140], ['Card/Slot', 'card_and_slot', 80],
            ['Event Text','entry_text',280, 'left']]
    else
        l= [["Time Stamp", 'timestamp', 140], ['Card/Slot', 'card_and_slot', 80],
        ['Verbosity', 'verbosity_level', 60], ['Event Type', 'entry_type', 60], 
        ['Event Text','entry_text',280, 'left']]
    end
    l.map{|n| {:display=>n[0], :name =>n[1], :width => n[2], :sortable=>true, :align=> n[3] || 'center'}}.to_json
  end

  #To get the cause and remedy value for the alarm
  def get_cause_remedy(slot, card_id, byte, bit, mcfcrc, sin, layout_index)
    card_index = RtCardInformation.find_by_card_type(card_id, :select => "card_index", :conditions => {:slot_atcs_devnumber => slot}).try(:card_index)

    param_name = Parameter.find_by_cardindex(card_index, :select => "name",
    :conditions => {:mcfcrc => mcfcrc, :layout_index => layout_index, :parameter_type => 6, :start_byte => byte, :start_bit => bit}).try(:name) if card_index

    cdf_name = Card.find_by_card_index(card_index, :select => "cdf", :conditions => {:mcfcrc => mcfcrc, :layout_index => layout_index, :crd_type => card_id}).try(:cdf) if param_name

    cause_remedy = DiagnosticMessages.find_by_cdf(cdf_name, :select => "cause_remedy",
      :conditions => {:mcfcrc => mcfcrc, :name => param_name.split(".").last}).try(:cause_remedy) if cdf_name
 
    cause_remedy.blank? ? '' : cause_remedy.chomp.strip.gsub("\n", "<BR>")
  end
end