class LsEnumerators < ActiveRecord::Base
  set_table_name "ls_enumerators"
  establish_connection :mcf_db

  def self.select_aspect_values()
    LsEnumerators.find(:all,:select=>"name,value",:conditions=>"enum_index==1")
  end
  
  def self.select_aspectname_and_values(name)
    name_val=name.to_s
    LsEnumerators.find(:all,:select=>"name,value",:conditions=>["enum_index=1 and name='#{name_val}'"]).map(&:value)
  end
end
