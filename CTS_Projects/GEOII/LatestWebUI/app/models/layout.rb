class Layout < ActiveRecord::Base
  
  establish_connection :mcf_db
  set_table_name "layout"
  set_primary_key "mcfcrc"
  
  def self.number_of_slots(gwe, num_slots, geo_type)
    if geo_type == "AM"
      find_by_mcfcrc_and_layout_index(gwe.mcfcrc, gwe.active_physical_layout, :select => "number_of_slots").try(:number_of_slots)
    else
      num_slots
    end  
  end
end