class Parameter < ActiveRecord::Base
  set_table_name "parameters"
  establish_connection :mcf_db
  
  belongs_to :page_parameter, :primary_key => "name", :foreign_key => 'parameter_name'
  
  has_many :enumerator,
           :class_name => "ParamEnumerator",
           :finder_sql => 'select enumerators.* from enumerators where enumerators.enum_type_name = \'#{enum_type_name}\' and enumerators.mcfcrc = #{mcfcrc} and enumerators.layout_index = #{layout_index} Order by rowid'
  has_many :integertype,
           :class_name => "Integertype",
           :finder_sql => 'select integertypes.* from integertypes where integertypes.int_type_name = \'#{int_type_name}\' and integertypes.mcfcrc = #{mcfcrc}'
  
  
  def self.get_parameters(params)
    parameters = all(:conditions => {:name => params, :mcfcrc => Gwe.mcfcrc}, :select => "name, enum_type_name")
    rt_parameters = RtParameter.all(:select => "parameter_name, current_value", 
                    :conditions => {:parameter_name => params, :mcfcrc => Gwe.mcfcrc})
    enumerators = EnumeratorsMcf.all(:conditions => {:enum_type_name => parameters.map(&:enum_type_name)}, :select => "value, long_name")
    
    logic_states = {}
    parameters.each do |parameter|
      rt_parameter = rt_parameters.find{|rt_param| rt_param.parameter_name == parameter.name }
      enumerator = enumerators.find{|enumerator| enumerator.value == rt_parameter.current_value } if rt_parameter
      logic_states[parameter.name] = enumerator.long_name if enumerator      
    end
    logic_states
  end
  
  def getEnumerator(val)
    enumerator_name = ""
    if enumerator != nil 
      enumerator.each do |e|
        if e.long_name.index(".xml").nil? && e.value.to_i() == val.to_i() 
          enumerator_name = e.long_name
          return enumerator_name
        end
      end
    end
    return enumerator_name
  end
  
  def getEnumeratorValue(enumerator_name)
    if $enumerators_hash.blank?
      if enumerator != nil 
        if enumerator.size > 0
          enumerator.each do |e|
            if e.long_name == enumerator_name 
              return e.value.to_i
            end
          end
        end
      end
      return 0
    else
      return $enumerators_hash["#{self.enum_type_name}~#{enumerator_name}"]
    end
  end
  
  def is_valid(val)
    bValid = 0
    lbound = integertype.lower_bound
    ubound = integertype.upper_bound
    
    if val >= lbound && val <= ubound
      bValid = 1
    end
    return bValid
  end
  
  def fetchenum(pdata_type,pname,pindex,ptype,cindex,enum_type_name,parameter_obj)
    #@remote_val = []
    @cur_def_value = []
    @rt_info = []
    @rt_param_data = []
    @rt_pindex
    @rtparam_info =[]
    rtparam_info1 = RtParameter.find_by_parameter_index_and_card_index_and_parameter_type(pindex,cindex,ptype) || parameter_obj
    @rtparam_info << rtparam_info1
    @rtparam_info.each do |r|
      if r.instance_of?(RtParameter)
        @curval = r.current_value
      end
      if r.instance_of?(Parameter)
        @curval = r.default_value
      end
    end
    if parameter_obj.data_type == "Enumeration"
      parameter_obj.enumerator.each do |k|
        if k.value.to_i == @curval and k.enum_type_name == enum_type_name
          @remote_val = k.long_name
        end
      end
    end
    if pdata_type == "IntegerType"
      @remote_val = @curval
    end
    
    return @remote_val
  end
  
  def fetchCurVal(pindex,ptype,cindex,mcfcrc)
    return RtParameter.find_by_parameter_index_and_card_index_and_parameter_type_and_mcfcrc(pindex,cindex,ptype,mcfcrc) || 0
  end
  
  def self.oos_applicable?(mcfcrc)
    !(find_by_mcfcrc_and_name(mcfcrc, "PSO1App.RX1InService").nil?)
  end
end