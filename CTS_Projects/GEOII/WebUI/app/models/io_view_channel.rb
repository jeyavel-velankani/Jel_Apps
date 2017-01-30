class IoViewChannel < ActiveRecord::Base
  establish_connection :real_time_db
  set_table_name "rt_view_channels"  
  set_primary_key 'sin'   
  
  # Ordering set of channels in to a hash object for all available cards
  def self.fetch_channels(card_indices, atcs_address, gwe, view_type)
    channels_set = Hash.new
    channels = find(:all, :conditions => ["sin = ? and mcfcrc = ? and card_index in (#{card_indices.join(',')}) and view_type = ? and channel_index != 0", atcs_address, gwe.mcfcrc, view_type], 
                    :select => "channel_tile, channel_name, channel_index, card_index", :order => "rowid")
    
    # Iterating over the existing card indices
    card_indices.each do |card_index|
      card_channels = channels.select{|channel| channel.card_index == card_index }
      channels_set["#{card_index}"] = card_channels
    end
    channels_set
  end
  
end
