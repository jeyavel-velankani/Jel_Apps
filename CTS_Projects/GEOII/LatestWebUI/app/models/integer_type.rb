class IntegerType < ActiveRecord::Base
  establish_connection :development
  set_table_name "Integer_Types"
  set_primary_key 'ID'
   # belongs_to :Integer_Parameters
   
  has_many :int_parameters, :class_name => 'IntegerParameter', :foreign_key =>"ID"
  
  def self.param_units(typeid)
     IntegerType.find(:all, :select=>'Units', :conditions=>['ID=?',typeid])
 end
 
 def self.param_minval(typeid)
     IntegerType.find(:all, :select=>'Min_Value', :conditions=>['ID=?',typeid])
 end
 
 def self.param_maxval(typeid)
     IntegerType.find(:all, :select=>'Max_Value', :conditions=>['ID=?',typeid])
 end
 
  def self.integer_type_id(id)
       IntegerType.find(:all,:select=>'Min_Value, Max_Value',:conditions=>['ID=?',id])
  end
 
end
