class RtCard < ActiveRecord::Base
  establish_connection :real_time_db
  set_table_name "rt_cards"
  set_primary_key 'sin'

  class << self

    def get_card_parameters(card_type, card_number=1)
      case card_type
        when TRACK_CARD
          ['GCPStatus.EZValue', 'GCPStatus.EXValue', 'ComputedApproachDistance', 'LinearizationSteps',
                          'MainGCPCalDone', 'CompAppCalDone', 'LinCalDone', 'MainIPICalDone', 'GCPStatus.CalibReq',
                          'GCPStatus.AppCalibReq', 'GCPStatus.LinCalibReq', 'IPIStatus.CalibReq', 'GCPStatus.CalibrationPassed', 'IPIStatus.CalibrationPassed']
        when PSO_CARD
          ['PSORX1Status.CalibReq', 'PSORX2Status.CalibReq', 'PSOTXStatus.ModulationCode', 'PSORX1Status.Used', 'PSORX2Status.Used','IPIStatus.Used',
           'PSOTXStatus.Used', "GCPAppCPU.Island#{card_number}Occupied", "PSORX#{card_number}AnalogStatus.SignalLevel",
           "PSORX#{card_number}Status.PSOOccupancyWithPickupDelay", "PSORX#{card_number}Status.PSOOccupancy",
           "PSORX#{card_number}AnalogStatus.SignalLevel", "PSORX1Status.CalibrationPassed", "PSORX2Status.CalibrationPassed", "IPIStatus.CalibReq" ]
      end
    end

    def get_oos_parameters(card_number=1)
      ["GCPAppTrk#{card_number}.GCPInService", "GCPAppTrk#{card_number}.IPIInService", "OutOfServiceTimeoutUsed", "OutOfServiceTimeout", "OutOfServiceIPsUsed2"]
    end

    # To fetch track cards
    def fetch_track_cards
      consist_id = RtConsist.find(:last, :select => "consist_id")
      RtCardInformation.find(:all,
      :conditions => {:card_type => [TRACK_CARD, PSO_CARD],
      :consist_id => consist_id.consist_id},
      :select => "card_type, card_index, slot_atcs_devnumber, consist_id, card_used",
      :order => "card_index asc")
    end

    # To fetch count of cards based on card_type
    def fetch_count_of_track_cards
      consist_id = RtConsist.find(:last, :select => "consist_id")
      RtCardInformation.find(:all,
      :conditions => {:card_type => [TRACK_CARD],
      :card_used => 0, :consist_id => consist_id.consist_id}).size
    end
  end

  def self.find_value(c_indexs)
    collection_cards = find(:all,:select =>"c_index, comm_status" ,:conditions => ["parameter_type = 3"])
    cards_index = []

    collection_cards.each do |f|
      # Check for comm status bit being set
      if(f.comm_status & 4)
        # check for a card index match
        cards_index << f.c_index if c_indexs.include?f.c_index
      end
    end
    cards_index
  end
end
