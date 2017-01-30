class Menu < ActiveRecord::Base
  set_table_name "menus"
  establish_connection :mcf_db

  def self.cpu_3_menu_system
  	begin
	    check = Menu.find(:all,:conditions => ["parent != '(NULL)'"])

	    unless check.blank?
	    	return true # CPU3 Menu System (Read the menus from menu table)  -NEW MCF SYSTEM(parent col- ! NULL)
	    else
	    	return false #(Read the treemenus from menu table) -OLD MCF SYSTEM(parent col- NULL)
	    end
	rescue Exception => err
		return false
	end
  end
end