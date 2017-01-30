class VersionInformation < ActiveRecord::Base
  set_table_name "Version_Information"
  establish_connection :development
  
def self.get_product
  	begin
	    product = self.find(:first)

	    unless product.blank? && product[:Platform_Name].blank?
	    	return product[:Platform_Name]
	    else
	    	return 'unknown'
	    end
	rescue Exception => err
		return 'unknown'
	end
  end
  
end
