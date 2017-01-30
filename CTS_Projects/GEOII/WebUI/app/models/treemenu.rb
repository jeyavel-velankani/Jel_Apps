class Treemenu < ActiveRecord::Base
  set_table_name "tree_menus"
  establish_connection :mcf_db
  
   def self.get_menu_show_value(menu)
     menus_show_val = Menu.find(:first, :select => "show, enable", :conditions => ["layout_index = ? and mcfcrc = ? and page_name = ? and menu_name = ? ",  Gwe.physical_layout, Gwe.mcfcrc, menu.page_name, menu.menu_name])
       if !menus_show_val.blank?
        return menus_show_val.show, menus_show_val.enable
       else
        return false, false
       end
   end
    
end
