class RtParameter < ActiveRecord::Base
  set_table_name "rt_parameters"
  set_primary_key 'card_index' 
  establish_connection :real_time_db
  
  class << self
    
    def parameter(parameter)
      find_by_mcfcrc(parameter.mcfcrc, :conditions => {:parameter_type => parameter.parameter_type, 
                  :parameter_index => parameter.parameter_index,
                  :card_index => parameter.cardindex}, :select => "current_value")  
    end 
    
    def get_status_cmd_parameters(atcs_addr, mcfcrc, card_index, card_type)
      card_index = card_type == 15 ? [card_index, 28] : [card_index]
      find(:all, 
           :conditions => ["parameter_name not like '%FILLER%' and parameter_type in (3, 4) and sin = ? and mcfcrc = ? and card_index in (?)", 
                            atcs_addr, mcfcrc, card_index],
           :select => "card_index, parameter_type, parameter_name, current_value")
    end 
    
    def get_nv_status_cmd_diag_parameters(atcs_addr, mcfcrc, card_index, parameter_type)      
      find(:all, 
           :conditions => ["parameter_name not like '%FILLER%' and parameter_name not Like '%INTERNAL%' and sin = ? and mcfcrc = ? and card_index in (?) and parameter_type in (?)", 
                            atcs_addr, mcfcrc, card_index, parameter_type],
           :select => "card_index, parameter_type, parameter_name, current_value")
    end
    
    def get_gcp_track_details(track_parameters, mcfcrc, sin, card_index)
      track_details = Hash.new 
      parameters = find(:all, 
      :conditions => {:parameter_name => track_parameters, :mcfcrc => mcfcrc, :sin => sin, :card_index => [card_index, 28], :parameter_type => [3, 2, 4]}, 
      :select => "parameter_name, parameter_type, current_value")
      parameters.each do |parameter|
        track_details["#{parameter.parameter_type}.#{parameter.parameter_name}"] = parameter.current_value
      end
      track_details
    end
    
  end
  
  def self.get_current_value (parameter_name, card_index)
    val = RtParameter.find(:first, :conditions => {:parameter_name => parameter_name, :card_index => card_index, :parameter_type => 3}, :select => :current_value)
    return val.current_value if !val.nil?
  end
  
  def self.password_match?(password)
    card_index = RtCardInformation.vlp_card_index
    if card_index > 0
      p = RtParameter.find(:first, :conditions => {:parameter_name => "Password4", :card_index => card_index, :parameter_type => 2})
      if p
        if /^[\d]+(\.[\d]+){0,1}$/ === password
          if p.current_value == password.to_i
            return true
          end
        end
      end
    end
    return false
  end
  
  def self.super_password_match?(password)
    card_index = RtCardInformation.vlp_card_index
    if card_index > 0
      p = RtParameter.find(:first, :conditions => {:parameter_name => "SuperPassword4", :card_index => card_index, :parameter_type => 2})
      if p
        if /^[\d]+(\.[\d]+){0,1}$/ === password
          if p.current_value == password.to_i
            return true
          end
        end
      end
    end
    return false
  end
  
  def self.password_enabled?
    card_index = RtCardInformation.vlp_card_index
    if card_index > 0
      p = RtParameter.find(:first, :conditions => {:parameter_name => "PasswordActive", :card_index => card_index, :parameter_type => 2})
      if p
        if p.current_value == PASSWORD_ON
          return true
        end
      end
    end
    return false
  end
  
  def self.super_password_enabled?
    card_index = RtCardInformation.vlp_card_index
    if card_index > 0
      p = RtParameter.find(:first, :conditions => {:parameter_name => "SuperPasswordActive", :card_index => card_index, :parameter_type => 2})
      if p
        if p.current_value == PASSWORD_ON
          return true
        end
      end
    end
    return false
  end
  
  def self.get_current_value_ex(parameter_name, card_index,param_type)
    val = RtParameter.find(:first, :conditions => {:parameter_name => parameter_name, :card_index => card_index, :parameter_type => param_type}, :select => :current_value)
    return val.current_value if !val.nil?
  end
  
  def self.super_permissions  
    card_info = RtCardInformation.find_by_sql('select rt_card_information.card_index as card_index from rt_consist  join rt_card_information on rt_consist.cpu_card_id = rt_card_information.card_type limit 1')

    supervisor = RtParameter.find_by_sql("select current_value from rt_parameters where card_index = #{card_info[0].card_index} and parameter_name = 'SuperPasswordActive'")

    if !supervisor.blank? 
      supervisor = supervisor[0].current_value
    else
      supervisor = 1
    end

    return  supervisor 
  end

  def self.maint_permissions  
    card_info = RtCardInformation.find_by_sql('select rt_card_information.card_index as card_index from rt_consist  join rt_card_information on rt_consist.cpu_card_id = rt_card_information.card_type limit 1')

    maintainer = RtParameter.find_by_sql("select current_value from rt_parameters where card_index = #{card_info[0].card_index} and parameter_name = 'PasswordActive'")

    if !maintainer.blank?
      maintainer = maintainer[0].current_value
    else
      maintainer = 1
    end

    return  maintainer 
  end
  
  def self.update_parameter(options)
    i=0
    while i<3
      begin
        RtParameter.update_all("current_value = #{options[:current_value]}", :mcfcrc => options[:mcfcrc], :card_index => options[:card_index], 
                              :parameter_type => options[:parameter_type], :parameter_name => options[:parameter_name])
        i = 3
      rescue Exception => e
       if(e)
        sleep(1)
        i += 1
       else
        i = 3
       end
      end  
    end
  end
  
  def self.update_current_to_dafault_vale(path)
    RtParameter.update_all("default_value = current_value")    
  end
  
  def self.update_default_to_current_vale(path)
    RtParameter.update_all("current_value = default_value")    
  end
  
  
end