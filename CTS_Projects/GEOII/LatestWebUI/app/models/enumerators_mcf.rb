class EnumeratorsMcf < ActiveRecord::Base
  set_table_name "enumerators"
  establish_connection :mcf_db

  def self.enum_values(mcfcrc, enum_type_name, layout_index)
    self.all(:conditions => {:mcfcrc => mcfcrc, :enum_type_name => enum_type_name, :layout_index => layout_index}, 
                           :select => "long_name, value").collect{|enum| [enum.long_name, enum.value] }
  end
  
  def self.enumerator_values(parameter_names)
    mcf_param_names = []
    parameter_names.each do |x|
      mcf_param_names << "'" + x + "'"
    end
    mcf_parameters = Parameter.find(:all, :conditions => [" name in (#{mcf_param_names.join(',')}) and data_type = 'Enumeration'"])
    enumerator_names = []
    param_name_to_enum_name = {}
    mcf_parameters.each do |p|
      enumerator_names << "'" + p.enum_type_name + "'"
      param_name_to_enum_name[p.name] = p.enum_type_name
    end
    enum_parameter_values = {}
    enumerators = EnumeratorsMcf.find(:all, :conditions => ["enum_type_name in (#{enumerator_names.join(',')})"])
    enumerators.each do |e|
      enum_parameter_values["#{e.enum_type_name}.#{e.value}"] = e.long_name
    end
    return param_name_to_enum_name, enum_parameter_values
  end
end
