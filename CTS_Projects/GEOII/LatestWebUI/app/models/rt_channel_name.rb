class RtChannelName < ActiveRecord::Base
  set_table_name  "rt_channel_names"
  set_primary_key 'card_index'
  establish_connection :real_time_db
  
  def self.channel_names(card_info, atcs_address, mcfcrc, name_type=3)
    channel_titles =  find(:all, :conditions => {:card_index => card_info.card_index, :sin => atcs_address, :name_type => name_type})
    channel_titles = Cardview.find(:all, :conditions => {:mcfcrc => mcfcrc, :cdf => card_info.cdf}) if channel_titles.blank?
    channel_titles
  end
end
