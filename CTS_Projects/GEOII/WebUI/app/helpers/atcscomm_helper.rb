module AtcscommHelper
  include ActionView::Helpers::FormOptionsHelper
  
  def cardlist(cardinfo)
    
     card_health = get_card_health(@card_index,  session[:sin], session[:mcfcrc])
     card_health_status = dec2bin(card_health).to_s.split("")
     card_health_status_bit = card_health_status[card_health_status.size - 2] unless card_health_status.empty?
        
     ret = "<div style='text-align: center; margin:0;color:#FFF;"
     ret += card_health == '1' || card_health == nil  ? 'background-color:#9D0F10;' : ''
     ret += "'>&nbsp;"
     ret += "<table>"
       cardinfo.each do |crdname|
          ret += "<tr><td style='cursor:pointer;' id="
          ret += crdname.card_index.blank? ? '0' : crdname.try(:card_index).to_s
          ret += " class="
          ret += card_health_status_bit == '1' || card_health_status_bit.blank? ? 'contenttaboff' : 'contenttabon'
          ret += ">"
          session[:cname] = crdname.crd_name
          session[:card_index] = crdname.card_index
          session[:card_type] = crdname.crd_type
          session[:card_name] = crdname.crd_name
          ret += crdname.crd_name
          ret += "</td></tr>"
       end
       ret += "</table>"
       ret += "</div>"
end
  def get_atcs_header(parameter_names)
      arr1 = []      
      parameter_names.each{|parameter| arr1 << parameter.split('.') }
      flatten_array = arr1.flatten
      return flatten_array[0] == flatten_array[2] ? flatten_array.first : flatten_array.last
  end
  
  def get_select_options(atcs_addresses)
    atcs_addresses.blank? ? "" : options_for_select(atcs_addresses)
  end
  
end
