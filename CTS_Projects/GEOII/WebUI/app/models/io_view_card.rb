class IoViewCard < ActiveRecord::Base
  establish_connection :real_time_db
  set_table_name "rt_view_cards"  
  set_primary_key 'sin'
  
  class << self 
    # Finding all available cards based on sin
    def fetch_cards(atcs_address, mcfcrc, view_type)
      # View type check such that if condition applied only for IO View
      # if (GCP_PRODUCT == 1 || PRODUCT_TYPE == 2) && view_type == 1
        # consist_id = RtConsist.consist_id(atcs_address, mcfcrc).try(:consist_id)
        # used_cards = RtCardInformation.all(:conditions => {:card_used => 0, :consist_id => consist_id, :card_type => [8, 9, 14, 15, 29]})        
        # find(:all, 
        # :conditions => {:sin => atcs_address, :mcfcrc => mcfcrc, :card_index => used_cards.map(&:card_index), 
        # :card_type => used_cards.map(&:card_type), :view_type => view_type})
      # else
        find(:all, :conditions => ["sin = ? and mcfcrc = ? and view_type = ? and slot_name != ? and card_status != ?", atcs_address, mcfcrc, view_type, "", -1], :order => "slot_no")
      # end
    end
    
    # Iterating over the cards and getting the updated cards
    def get_updated_cards(timestamp, atcs_address, mcfcrc, view_type)
      cards = fetch_cards(atcs_address, mcfcrc, view_type)
      updated_cards = {}
      time_stamp_hash = {}
      card_number = init_card_type = 0
      
      cards.each do |card|
        if init_card_type == card.card_type
          card_number += 1
        else
          init_card_type = card.card_type
          card_number = 1
        end
        if timestamp["card_#{card.card_index}"].to_i <= card.update_timestamp.to_i          
          channels = IoViewChannel.all(:conditions => ["sin = ? and mcfcrc = ? and card_index = ? and view_type = ? and channel_index != 0", 
                        atcs_address, mcfcrc, card.card_index, view_type], 
                        :select => "channel_tile, channel_name, channel_index, card_index", :order => "rowid")
          updated_cards["card_#{card.card_index}"] = {:card => card, :comm_status => (card.card_status & (0X02)), :channels => channels, :card_number => card_number}
        end
        time_stamp_hash["card_#{card.card_index}"] = card.update_timestamp
      end
      return updated_cards, time_stamp_hash, cards.map(&:card_index)
    end
    
    # Finding comm status of all cards based on card indices
    def fetch_card_status(atcs_address, mcfcrc, card_indices)
      comm_status_set = Hash.new
      rt_cards = RtCard.all(:conditions => {:c_index => card_indices, :mcfcrc => mcfcrc, :sin => atcs_address, :parameter_type => 3},
               :select => "comm_status, c_index")
      
      rt_cards.each do |rt_card|
        # converting decimal to binary
        comm_status = rt_card.comm_status.to_s(2)
        comm_status_set["#{rt_card.c_index}"] = comm_status[(comm_status.size - 2), 1]      
      end
      
      comm_status_set
    end

    def get_cards_by_type(atcs_address, mcfcrc, view_type,card_types)
      card_types_str = '('
      card_types.each do |card_type|
        card_types_str += card_type.to_s+','
      end

      card_types_str = card_types_str[0..-2] + ')'

      logger.info "select * from rt_view_cards where sin = '#{atcs_address}' and mcfcrc = #{mcfcrc} and view_type = #{view_type} and card_type in #{card_types_str} and slot_name != ''"

      self.find_by_sql("select * from rt_view_cards where sin = '#{atcs_address}' and mcfcrc = #{mcfcrc} and view_type = #{view_type} and card_type in #{card_types_str} and slot_name != ''")
      
    end

    def get_cards(atcs_address, mcfcrc, view_type)
      self.find(:all, :conditions => ["sin = ? and mcfcrc = ? and view_type = ? and slot_name != ?", atcs_address, mcfcrc, view_type, ""])
    end

    def get_card_index_by_slot_number(atcs_address, mcfcrc, slot_number)
      self.find(:first, :conditions => ["sin = ? and mcfcrc = ? and slot_no == ?", atcs_address, mcfcrc, slot_number])
    end
  end
end
