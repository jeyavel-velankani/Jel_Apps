class RtCardInformation < ActiveRecord::Base
  set_table_name "rt_card_information"
  establish_connection :real_time_db
  set_primary_key :card_info_id

  has_one  :consist, :class_name => 'RtConsist', :foreign_key => "consist_id", :primary_key=>"consist_id"

  has_many :rt_parameters, :class_name => 'RtParameter', :foreign_key =>"card_index", :primary_key => "card_index"
  has_many :parameters, :class_name => 'Parameter', :foreign_key =>"cardindex", :primary_key => "card_index"

  def self.find_card_information(consist_id, view_type=nil, systype=nil)
    card_information = if view_type == "io" || view_type.nil?
      if (systype == "geo2")
        # Card type 9 is VLP and slave_kind should be 7
        cards = find(:all, :select => "card_index, card_type, slot_atcs_devnumber", 
              :conditions => ["card_used = 0 and consist_id = ? and (slave_kind = 0 or (card_type = 9 and slave_kind = 7))",consist_id],:order => "slot_atcs_devnumber asc")
        cards
      else
        find(:all, :select => "card_index, card_type, slot_atcs_devnumber",
                  :conditions => ["consist_id = ? and card_type in (?) and (slave_kind = 0 or slave_kind = 7)",
        consist_id, (1..10).to_a], :order => "slot_atcs_devnumber asc")
      end
    elsif view_type == "atcs"
      find(:all, :select => "card_index, card_type, slot_atcs_devnumber",
            :conditions => ["consist_id = ? and (slave_kind = 3 or slave_kind = 5)", consist_id], :order => "slot_atcs_devnumber asc")
    end
    cp_array_index, vlp_array_index = nil, nil
    card_information.each_with_index do |card_info, index|
      cp_array_index = index if card_info.card_type == 1 && card_info.card_index == 1
      vlp_array_index = index if card_info.card_type == 9
    end
    if(cp_array_index && vlp_array_index)
      tmp = card_information[vlp_array_index]
      card_information[vlp_array_index] = card_information[cp_array_index]
      card_information[cp_array_index] = tmp
    end
    return card_information
  end

  # Code from GCP

  Parameter_types = {:config => Param_Config, :status => Param_Status, :diagnostics => Param_Diagnostics, :command=>Param_Command }

  def fetch_calibration_status(pname)
      mcf_calib_params = Parameter.find_by_name(pname, :conditions => ["cardindex = ?", @param_id])
      return RtParameter.find_by_parameter_index_and_card_index(mcf_calib_params.parameter_index,mcf_calib_params.cardindex).current_value
  end


  def consist_mcfcrc # For getting the consist details
    @consist_mcfcrc  ||= consist
  end

  def mcf_status # For getting the mcf status
    @mcf_status ||= consist_mcfcrc.mcf.mcf_status
  end

  def all_parameters # For gettinng the Parameters based on the parameter type.
    @all_parameters = parameters.find_all_by_parameter_type(@parameter_type)
  end

  def has_parameters # For getting the rt_parameter details based on the mcfcrc, parameter type.
    @has_parameters = rt_parameters.find_all_by_mcfcrc_and_parameter_type(consist_mcfcrc.mcfcrc, @parameter_type)
  end

  def fetch_value(v) #For get parameter current values.
    @param_det = Parameter.find_all_by_name_and_mcfcrc(v,Gwe.mcfcrc)
    @param_det.each do |p|
      rt_info = RtParameter.find_all_by_parameter_index_and_parameter_type_and_card_index_and_mcfcrc(p.parameter_index,p.parameter_type,p.cardindex, p.mcfcrc) || p
      rt_info.each do |r|
        if r.instance_of?(RtParameter)
          @curval = r.current_value
        end
        if r.instance_of?(Parameter)
          @curval = r.default_value
        end
      end
      if p.data_type == "Enumeration"
        return final_value = p.getEnumerator(@curval)
      end

      if p.data_type == "IntegerType"
        return  final_value = @curval
      end

      if p.data_type == "" or nil
        return  final_value = @curval
      end
    end
  end

  def method_missing(method_sym)#For getting parameter values.
    if ["ez", "ex", "speed","rx1","rx2","tx","flash","hwfail","GCPFrequency","GCPXmitFrequency","ApproachDistance","GCPStatus.EZValue","GCPStatus.TrainSpeed","GCPStatus.EXValue","XLO1.HWFAIL","XLO2.HWFAIL","XLO1.FLASH","XLO2.FLASH","GCPAppCPU.Island1Occupied","GCPAppCPU.Island2Occupied","GCPAppCPU.Island3Occupied","GCPAppCPU.Island4Occupied","GCPAppCPU.Island5Occupied","GCPAppCPU.Island6Occupied","PSORX1Freq","PSORX2Freq","PSORX1Used","OutOfServiceIPsUsed2",
      "GCPAppTrk1.GCPInService","GCPAppTrk2.GCPInService","GCPAppTrk3.GCPInService","GCPAppTrk4.GCPInService","GCPAppTrk5.GCPInService","GCPAppTrk6.GCPInService",
      "P1WarningTime","Directionality","TrackWrap","AdvancePreemptUsed","AdvancePrimeused","IslandIsOccupied","OOSTimeout_YesNo","GCPOutOfService","ISLOutOfService","OOSTimeout",
      "GCPStatus.CalibReq",
      "PCN","InternalParameter","DateTime","Rx1Frequency","Rx2Frequency","TxFrequency","TxTransmitLevel","IslandDistance",
      "TCN","InternalParameters","DateTimes","CompensationValue","WarnTimeBalance","UniBiSimBidirnl","GCPTransmitLevel",
      "PUsed","TPUaxUsed","IPIXmitFrequency","SignalLevelz","VPI1.ON","VPI2.ON","VRO1.GPO_ON","VRO2.GPO_ON","GCPCalibrated","IslandCalibrated","PSOCalibrated",
      "ComputedApproachDistance","LinearizationSteps","Island","GCPAppTrkGCPInService","PSO_VRO1","PSO_VRO2","PSO_VRO3","PSO_VPI1","PSO_VPI2",
      "OutofServiceIPUsed2","gcpappcpumaintcall","DiagFlagsGCPIPSMode","GCPAppTrkMSGCPCtrlOP","VLPProc.BatteryVoltage","VLPProc.InternalVoltage","VLPProc.Temperature","gcpappcpuadvancepreemptused","gcpappcpuadvancepreemptinput","gcpappcpuadvancepreemptoutput","gcpappcpuadvancepreemptxractivation","gcpappcputraffichealthip","gcpappcpusimpreemptoutput","gcpappcpupreempthealthip",
      "GCPAppTrk1.TrkWrap","GCPAppTrk2.TrkWrap","GCPAppTrk3.TrkWrap","GCPAppTrk4.TrkWrap","GCPAppTrk5.TrkWrap","GCPAppTrk6.TrkWrap",
      "GCPAppTrk1.MSGCPCtrlOP","GCPAppTrk2.MSGCPCtrlOP","GCPAppTrk3.MSGCPCtrlOP","GCPAppTrk4.MSGCPCtrlOP","GCPAppTrk5.MSGCPCtrlOP","GCPAppTrk6.MSGCPCtrlOP",
      "P1Used","P2Used","P3Used","P4Used","P5Used","P6Used",
      "T1P1UAXUsed","T1P2UAXUsed","T1P3UAXUsed","T1P4UAXUsed","T1P5UAXUsed","T1P6UAXUsed","T1P7UAXUsed","T1P8UAXUsed","T1P9UAXUsed",
      "T2P1UAXUsed","T2P2UAXUsed","T2P3UAXUsed","T2P4UAXUsed","T2P5UAXUsed","T2P6UAXUsed","T2P7UAXUsed","T2P8UAXUsed","T2P9UAXUsed",
      "T3P1UAXUsed","T3P2UAXUsed","T3P3UAXUsed","T3P4UAXUsed","T3P5UAXUsed","T3P6UAXUsed","T3P7UAXUsed","T3P8UAXUsed","T3P9UAXUsed",
      "T4P1UAXUsed","T4P2UAXUsed","T4P3UAXUsed","T4P4UAXUsed","T4P5UAXUsed","T4P6UAXUsed","T4P7UAXUsed","T4P8UAXUsed","T4P9UAXUsed",
      "T5P1UAXUsed","T5P2UAXUsed","T5P3UAXUsed","T5P4UAXUsed","T5P5UAXUsed","T5P6UAXUsed","T5P7UAXUsed","T5P8UAXUsed","T5P9UAXUsed",
      "T6P1UAXUsed","T6P2UAXUsed","T6P3UAXUsed","T6P4UAXUsed","T6P5UAXUsed","T6P6UAXUsed","T6P7UAXUsed","T6P8UAXUsed","T6P9UAXUsed",
      "IPIStatus.SignalLevel","GCPStatus.ChkEZValue","GCP1Status.EZSteps","DiagFlags1","IPIStatus.CalibReq","GCPXmitLevel","DiagFlags1.GCPIPSMode","T1GCPOutOfService","T2GCPOutOfService","T3GCPOutOfService","T4GCPOutOfService","T5GCPOutOfService","T6GCPOutOfService"].include?(s=method_sym.to_s.gsub('__','.'))

      @parameter_type = ((s.eql?("flash") || s.eql?("hwfail")|| s.eql?("SignalLevelz")) ? Parameter_types[:status] : Parameter_types[:config])

      if s.eql?("GCPStatus.EZSteps") || s.eql?("GCPStatus.EZValue") ||s.eql?("GCPStatus.TrainSpeed")|| s.eql?("GCPStatus.EXValue")||s.eql?("XLO1.HWFAIL")||s.eql?("XLO2.HWFAIL")||s.eql?("XLO1.FLASH") || s.eql?("XLO2.FLASH") || s.eql?("T1GCPOutOfService") || s.eql?("T2GCPOutOfService") || s.eql?("T3GCPOutOfService") || s.eql?("T4GCPOutOfService") || s.eql?("T5GCPOutOfService") || s.eql?("T6GCPOutOfService")
        @parameter_type = Parameter_types[:status]
      end

      if s.eql?("GCPAppTrk1.GCPInService") ||s.eql?("GCPAppTrk2.GCPInService")|| s.eql?("GCPAppTrk3.GCPInService")||s.eql?("GCPAppTrk4.GCPInService")||s.eql?("GCPAppTrk5.GCPInService")||s.eql?("GCPAppTrk6.GCPInService") || s.eql?("OutOfServiceIPsUsed2") || s.eql?("DiagFlagsGCPIPSMode") || s.eql?("GCPAppTrkMSGCPCtrlOP")|| s.eql?("GCPAppCPU.Island1Occupied")|| s.eql?("GCPAppCPU.Island2Occupied") || s.eql?("GCPAppCPU.Island3Occupied") || s.eql?("GCPAppCPU.Island4Occupied") || s.eql?("GCPAppCPU.Island5Occupied") || s.eql?("GCPAppCPU.Island6Occupied") || s.eql?("PSORX1Freq") || s.eql?("PSORX2Freq") || s.eql?("GCPAppTrk1.TrkWrap")  || s.eql?("GCPAppTrk2.TrkWrap") || s.eql?("GCPAppTrk3.TrkWrap") || s.eql?("GCPAppTrk4.TrkWrap") || s.eql?("GCPAppTrk5.TrkWrap")|| s.eql?("GCPAppTrk6.TrkWrap") || s.eql?("GCPAppTrk1.MSGCPCtrlOP") || s.eql?("GCPAppTrk2.MSGCPCtrlOP")|| s.eql?("GCPAppTrk3.MSGCPCtrlOP")|| s.eql?("GCPAppTrk4.MSGCPCtrlOP")|| s.eql?("GCPAppTrk5.MSGCPCtrlOP")|| s.eql?("GCPAppTrk6.MSGCPCtrlOP") || s.eql?("VRO1.GPO_ON") || s.eql?("VRO2.GPO_ON")
        @parameter_type = Parameter_types[:command]
      end
      if s.eql?("PSORX1Used") ||  s.eql?("ApproachDistance") || s.eql?("GCPXmitFrequency") || s.eql?("P1WarningTime") || s.eql?("Directionality") || s.eql?("P1Used")|| s.eql?("P2Used")|| s.eql?("P3Used")|| s.eql?("P4Used")|| s.eql?("P5Used")|| s.eql?("P6Used") ||
        s.eql?("T1P1UAXUsed") || s.eql?("T1P2UAXUsed") || s.eql?("T1P3UAXUsed") || s.eql?("T1P4UAXUsed") || s.eql?("T1P5UAXUsed") || s.eql?("T1P6UAXUsed") || s.eql?("T1P7UAXUsed") || s.eql?("T1P8UAXUsed") || s.eql?("T1P9UAXUsed") ||
        s.eql?("T2P1UAXUsed") || s.eql?("T2P2UAXUsed") || s.eql?("T2P3UAXUsed") || s.eql?("T2P4UAXUsed") || s.eql?("T2P5UAXUsed") || s.eql?("T2P6UAXUsed") || s.eql?("T2P7UAXUsed") || s.eql?("T2P8UAXUsed") || s.eql?("T2P9UAXUsed") ||
        s.eql?("T3P1UAXUsed") || s.eql?("T3P2UAXUsed") || s.eql?("T3P3UAXUsed") || s.eql?("T3P4UAXUsed") || s.eql?("T3P5UAXUsed") || s.eql?("T3P6UAXUsed") || s.eql?("T3P7UAXUsed") || s.eql?("T3P8UAXUsed") || s.eql?("T3P9UAXUsed") ||
        s.eql?("T4P1UAXUsed") || s.eql?("T4P2UAXUsed") || s.eql?("T4P3UAXUsed") || s.eql?("T4P4UAXUsed") || s.eql?("T4P5UAXUsed") || s.eql?("T4P6UAXUsed") || s.eql?("T4P7UAXUsed") || s.eql?("T4P8UAXUsed") || s.eql?("T4P9UAXUsed") ||
        s.eql?("T5P1UAXUsed") || s.eql?("T5P2UAXUsed") || s.eql?("T5P3UAXUsed") || s.eql?("T5P4UAXUsed") || s.eql?("T5P5UAXUsed") || s.eql?("T5P6UAXUsed") || s.eql?("T5P7UAXUsed") || s.eql?("T5P8UAXUsed") || s.eql?("T5P9UAXUsed") ||
        s.eql?("T6P1UAXUsed") || s.eql?("T6P2UAXUsed") || s.eql?("T6P3UAXUsed") || s.eql?("T6P4UAXUsed") || s.eql?("T6P5UAXUsed") || s.eql?("T6P6UAXUsed") || s.eql?("T6P7UAXUsed") || s.eql?("T6P8UAXUsed") || s.eql?("T6P9UAXUsed") ||
        s.eql?("DiagFlags1") ||  s.eql?("CompensationValue") || s.eql?("GCPXmitLevel")
        @parameter_type = Parameter_types[:config]
      end
      if s.eql?("DiagFlags1.GCPIPSMode")
        @parameter_type = Parameter_types[:diagnostics]
      end
      fetch_value(s)
    else
      super
    end
  end

  def refetch_value(v) #For get parameter current values.
    @all_params ||= all_parameters
    if idx = @all_params.find{|a| a.name.eql?(v)}
      @has_param ||= has_parameters
      @has_param.each do |p|
        return p.current_value  if p.parameter_index == idx.parameter_index
      end
    end
  end

# Method to display to get the current_value and display the images in the Calibration page
  def self.fetch_calib_image_status_display(parameter_names,ptype,cindex)
    param_info = Parameter.find_all_by_parameter_type_and_cardindex_and_mcfcrc(ptype,cindex,Gwe.mcfcrc, :conditions => ["name in (?)", parameter_names])
    RtParameter.find_all_by_card_index_and_mcfcrc(cindex,Gwe.mcfcrc, :conditions => ["parameter_index in (?) and parameter_type in (?)", param_info.collect{|x| x.parameter_index}, param_info.collect{|x| x.parameter_type}])
  end

  def self.fetch_calib_current_value(pname,ptype,cindex)
    param_info = Parameter.find_by_name_and_parameter_type_and_cardindex_and_mcfcrc(pname,ptype,cindex,Gwe.mcfcrc)
    RtParameter.find_by_parameter_index_and_parameter_type_and_card_index(param_info.parameter_index,param_info.parameter_type,cindex)
  end

  def led_info_and_detail(numb) # This method is used to get the AND Details of AND column
    @parameter_type = Parameter_types[:config]
    if refetch_value("gcpappcpuand#{numb}")!= 1
      "grey"
    elsif refetch_value("gcpappcpuand#{numb}used") ==1
      if refetch_value("gcpappcpuand#{numb}wrap") == 1 && refetch_value("gcpappcpuand#{numb}") ==0
        "blue"
      elsif refetch_value("gcpappcpuand#{numb}wrap") == 1
        "green"
      else
        "red"
      end
    end
  end

  def led_info_and_enable(numb) # This method is used to get the AND Details of ENABLE column
    @parameter_type = Parameter_types[:config]
    if refetch_value("gcpappcpuand#{numb}enableused")!= 1
      "grey"
    elsif refetch_value("gcpappcpuand#{numb}enableused") ==1
      if refetch_value("gcpappcpuandenable#{numb}") == 1
        "green"
      else
        "red"
      end
    end
  end

  def self.get_all_information(all_cards = false)
    consist_id = RtConsist.find(:last, :select => "consist_id")
    if(all_cards)
      tracks = RtCardInformation.find(:all,
        :conditions => {:card_type => [TRACK_CARD, PSO_CARD, MAIN_SSCC_CARD, AND_CARD, VLP_CARD],
        :consist_id => consist_id.consist_id})
    else
      tracks = RtCardInformation.find(:all,
        :conditions => {:card_type => [TRACK_CARD, PSO_CARD, MAIN_SSCC_CARD, AND_CARD, VLP_CARD],
        :card_used => 0, :consist_id => consist_id.consist_id})
    end
    card_indexes, trk_indexes, pso_indexes, pso_details, sscc_details, and_details, vlp_details, trk_numbers, pso_numbers, sscc_numbers = [], [], [], [], [], [], [], {}, {}, {}
    trk_incr_number = pso_incr_number = sscc_incr_number = 0
    tracks.each do |p|
      if p.card_used == 0
        card_indexes << p.card_index
        if p.card_type == TRACK_CARD
          trk_indexes << p.card_index
          trk_incr_number += 1
          trk_numbers[p.card_index] = trk_incr_number
        end
        if p.card_type == PSO_CARD
          pso_indexes << p.card_index
          pso_incr_number += 1
          pso_numbers[p.card_index] = pso_incr_number
          pso_details << p
        end
        if p.card_type == MAIN_SSCC_CARD
          sscc_incr_number += 1
          sscc_numbers[p.card_index] = sscc_incr_number
          sscc_details << p
        end
        and_details << p if p.card_type == AND_CARD
        vlp_details << p if p.card_type == VLP_CARD
      else
        trk_incr_number += 1 if p.card_type == TRACK_CARD
        pso_incr_number += 1 if p.card_type == PSO_CARD
        sscc_incr_number += 1 if p.card_type == MAIN_SSCC_CARD
      end
    end
    {:card_indexes => card_indexes.uniq, :trk_indexes => trk_indexes.uniq, :pso_indexes => pso_indexes.uniq, :tracks => tracks, :pso => pso_details, :sscc => sscc_details,:and => and_details,:vlp => vlp_details, :consist_id => consist_id.consist_id, :trk_numbers => trk_numbers, :pso_numbers => pso_numbers, :sscc_numbers => sscc_numbers }
  end

  def self.get_alarm_slots
    consist_id = RtConsist.find(:last, :select => "consist_id")
    slots = RtCardInformation.find(:all, :select => "slot_atcs_devnumber",
      :conditions => {:card_type => [TRACK_CARD, PSO_CARD, MAIN_SSCC_CARD, AND_CARD, VLP_CARD],
      :card_used => 0, :consist_id => consist_id.consist_id})
  end

  def fetch_rtcurrentvalue(test)
    @cvalue=[]
    param_info = parameters.find_all_by_name_and_mcfcrc(test,Gwe.mcfcrc)
    param_info.each do |p|
      pindex << p.parameter_index
    end
    @cvalue << RtParameter.find_all_by_parameter_index(pindex)
    return @cvalue

  end

  def fetch_main_view_current_value(pname,cdx)
    @cvalue=[]
    param_info = Parameter.find_by_name(pname, :conditions=>["mcfcrc=? AND cardindex=?",Gwe.mcfcrc,cdx])
    curObj = RtParameter.find_all_by_parameter_index_and_card_index_and_parameter_type(param_info.parameter_index,param_info.cardindex,param_info.parameter_type)
    cur_val = 0
    cur_val =  curObj[0].current_value if curObj
  end

  def fetch_main_view_current_enumerator_value(pname,cdx)
    @cvalue=[]
    param_info = Parameter.find_by_name(pname, :conditions=>["mcfcrc=? AND cardindex=?",Gwe.mcfcrc,cdx])
    curObj = RtParameter.find_all_by_parameter_index_and_card_index_and_parameter_type(param_info.parameter_index,param_info.cardindex,param_info.parameter_type)
    cur_val = 0
    cur_val =  curObj[0].current_value if curObj
    return param_info.getEnumerator(cur_val)
  end

  #function to fetch rt_parameters(current_value) using parameters(name),rt_parameters for sscc
  def self.fetch_rtcurrentvaluesscc(sscctestcard,test)
    card_Index  =[]
    param_Index  =[]
    pindex = []
    @cvalue=[]
    cindex = RtCardInformation.find(:all,:select=>'card_index',:conditions=>{:card_type=>sscctestcard})
    cindex.each do |c|
      card_Index << c.card_index
    end
    param_info = Parameter.find_all_by_name_and_cardindex_and_mcfcrc(test,card_Index,Gwe.mcfcrc)
    param_info.each do |p|
      @currentvalue = RtParameter.find_by_parameter_index(p.parameter_index) || p
      @cvalue<<@currentvalue
    end
    return @cvalue
  end

  #function to fetch currentvalue using parameters(cardindex),rt_parameters
  def fetch_currentvalue(cardindex)
    @cvalue=[]
    @pname=[]
    @temparray = []
    @currentvalue = []

    param_info = parameters
    param_info.each do |p|
      @paramindex = p.parameter_index
      @pname=p.name
      if @pname=="XngLamp1Voltage"
        @pindex1=p.parameter_index
      elsif @pname=="XngLamp2Voltage"
        @pindex2=p.parameter_index
      end
      @current_val = RtParameter.find_by_parameter_index_and_card_index(p.parameter_index,cardindex)|| p
      @currentvalue << @current_val
      @currentvalue.each do |c|
        if c.is_a?(RtParameter)
          @cvalue = c.current_value
        else
          @cvalue = c.default_value
        end
        @temparray.push({:key=>@pname,:value=>@cvalue})
      end
    end
    return @temparray,@pindex1,@pindex2
  end


  def self.get_card_details(cards,*args)
    RtCardInformation.find_all_by_card_type(cards,args.join(','))
  end

  #temporary function to fetch sscc test(lampteston,lamptestdelay,lamptestcancel current values from rt.db) according to new databases
  def fetch_cvalue(cindex)
    @lname=[]
    @rt_info = []

    parameters.each do |param|
      @rtparam_info = RtParameter.find_by_parameter_index(param.parameter_index) || param
      @rt_info << @rtparam_info
    end
  end

  #Get current value from rt_parameters
  def self.get_parameter_values(card_indexes, parameter_names, mcfcrc)
    p_names = []
    parameter_names.each do |x|
      p_names << "'" + x + "'"
    end
    parameter_values = Parameter.find_all_by_mcfcrc(mcfcrc, :conditions=>["cardindex in (#{card_indexes.join(',')}) AND name in (#{p_names.join(',')})"], :select => "parameter_index, parameter_type")
    parameter_types, parameter_indexes = [], []
    parameter_values.each do |p|
      parameter_types <<  p.parameter_type
      parameter_indexes << p.parameter_index
    end
    return parameter_indexes.uniq, parameter_types.uniq
  end

  #Get current value from rt_parameters
  def self.get_rt_parameter_values(card_indexes, parameter_names, parameter_types, mcfcrc)
    rt_parameter_cur_values = {}
    p_names = []
    parameter_names.each do |x|
      p_names << "'" + x + "'"
    end
    rt_parameters = RtParameter.find_all_by_mcfcrc(mcfcrc, :conditions => ["card_index in (#{card_indexes.join(',')}) AND parameter_name in (#{p_names.join(',')}) AND parameter_type in (#{parameter_types.join(',')})"])
    rt_parameters.each do |p|
      rt_parameter_cur_values["#{p.card_index}.#{p.parameter_type}.#{p.parameter_name}"] = p.current_value
    end
    rt_parameter_cur_values
  end

  #Get SSCC card details
  def self.get_sscc_cards_information
    consist_id = RtConsist.find(:last, :select => "consist_id")
    RtCardInformation.find(:all,
      :conditions => {:card_type => [MAIN_SSCC_CARD], :consist_id => consist_id.consist_id})
  end

  def self.get_card(card_index)
    rt_consist = RtConsist.find(:last, :select => "consist_id")
    RtCardInformation.find(:first,
      :conditions => {:card_index => card_index, :card_used => 0, :consist_id => rt_consist.consist_id})
  end

  def self.get_available_tracks(card_type = TRACK_CARD)
    consist_id = RtConsist.find(:last, :select => "consist_id")
    RtCardInformation.find(:all,
      :conditions => {:card_type => [card_type],
      :card_used => 0, :consist_id => consist_id.consist_id})
  end

  def self.gcp?
    consist_id = RtConsist.find(:last, :select => "consist_id")
    if consist_id
      app_card = RtCardInformation.find(:all,
        :conditions => {:card_type => NGCP_APP_CARD,
        :card_used => 0, :consist_id => consist_id.consist_id})
      if app_card
        return true
      end
    end
    return false
  end

  def self.vlp_card_index
    consist_id = RtConsist.find(:last, :select => "consist_id")
    if consist_id
      vlp_card = RtCardInformation.find(:last,
        :conditions => {:card_type => VLP_CARD,
        :card_used => 0, :consist_id => consist_id.consist_id})
      if vlp_card
        return vlp_card.card_index
      end
    end
    return 0
  end

  @@app_card_index = nil

  def self.app_card_index
    if @@app_card_index
      @@app_card_index.card_index
    end
  end

  def self.refresh_app_card_index
      @@app_card_index = RtCardInformation.find(:first, :select => "card_index", :conditions => {:card_type => NGCP_APP_CARD,:card_used => 0})
  end

end