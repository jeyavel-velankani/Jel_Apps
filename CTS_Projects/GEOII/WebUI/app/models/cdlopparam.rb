class Cdlopparam < ActiveRecord::Base
  set_table_name "CDL_OpParams"
  establish_connection :development
  
  def self.get_value
    self.find(:all,:order=>'ID')
  end
  
  def self.drop_down_values(id)
    Cdlopparamoption.find(:all,:select=>"Option_Value, Option_Text" ,:conditions =>["OpParam_ID=?",id],:order =>"Option_Value")
  end
  
  def self.get_min_and_max(id)
     self.find(:all, :select=>'Min_Value , Max_Value', :conditions=>['ID=?',id])
 end
  
end
