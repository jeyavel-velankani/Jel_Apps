class Stringtype < ActiveRecord::Base
  set_table_name "String_Types"
  set_primary_key "ID"
  establish_connection :development
  has_many :string_parameters, :class_name => 'StringParameter', :foreign_key =>"ID"

  def self.string_type_id(id)
       Stringtype.find(:all,:select=>'Min_Length, Max_Length',:conditions=>['ID=?',id])
  end
  
  def self.length_min(typeid)
     Stringtype.find(:all, :select=>'Min_Length', :conditions=>['ID=?',typeid])
 end
 
 def self.length_max(typeid)
     Stringtype.find(:all, :select=>'Max_Length', :conditions=>['ID=?',typeid])
 end
  
end
