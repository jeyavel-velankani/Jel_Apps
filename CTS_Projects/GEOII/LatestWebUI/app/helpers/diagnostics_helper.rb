module DiagnosticsHelper
  def led_and_detail(i)#getting and_detail values for and_details view
    @and_detail.led_info_and_detail(i)
  end
  def led_and_enable(i)#getting and_enable values for and_details view
    @and_detail.led_info_and_enable(i)
  end
  def maintcall#getting maint call value for and_details view
    @and_detail.gcpappcpumaintcall.eql?(1) ? "green" : "red"
  end
  def led_info_display#getting remaing value of and_details view
    if @and_detail.gcpappcpuadvancepreemptused.eql?(1)||@and_detail.gcpappcpuadvancepreemptused.eql?(2)
      @lamp1=@and_detail.gcpappcpuadvancepreemptinput.eql?(1) ? "green" : "red"
      @lamp2=@and_detail.gcpappcpuadvancepreemptoutput.eql?(1) ? "green" : "red"
      @lamp3=@and_detail.gcpappcpuadvancepreemptxractivation.eql?(1) ? "green" : "red"
      @lamp4=@and_detail.gcpappcputraffichealthip.eql?(1)? "green" : "red"
      @lamp6=@and_detail.gcpappcpupreempthealthip.eql?(1)? "green" : "red"
      tmpvar ="<img src='../../../images/#{@lamp1}.gif' /> Advance Preempt Input<br />"+
        "<img src='../../../images/#{@lamp2}.gif' /> Advance Preempt Output<br />"+
        "<img src='../../../images/#{@lamp3}.gif' /> Advance Preempt AND 1<br />"+
        "<img src='../../../images/#{@lamp4}.gif' /> Traffic Health Input<br />"+
        "<img src='../../../images/#{@lamp6}.gif' /> Preempt Health Input<br />"
    elsif @and_detail.gcpappcpuadvancepreemptused.eql?(3)
      @lamp5=@and_detail.gcpappcpusimpreemptoutput.eql?(1) ? "green" : "red"
      @lamp6=@and_detail.gcpappcpupreempthealthip.eql?(1) ? "green" : "red"
      tmpvar="<img src='../../../images/#{@lamp5}.gif' /> Simultaneous Preempt Output<br />"+
        "<img src='../../../images/#{@lamp6}.gif'/> Preempt Health Input<br />"
    end

    return tmpvar
  end
  
  def internal_states
      @ip_map.each do |v|
      temp_map = {};temp_eq_array={}
      counter_val=0

      @op_map.each do |p|
        if v[:name] == p[:name]
          temp_map["bulp"] = v[:value]==1 && p[:value]==1?"green":"red"
          temp_map["label"]=  " : #{v[:evalue]}  Sets #{p[:evalue]}"
          temp_map["name"] = v[:name].to_s
          @op_map.delete(p)
          @final_array << temp_map
          counter_val = counter_val+1
          break
        end
      end

      if counter_val==0
        temp_eq_array={}
        temp_eq_array["bulp"] = v[:value]==1?"green":"red"
        temp_eq_array["label"]= " : #{v[:evalue]}"
        temp_eq_array["name"] = v[:name]
        @final_array << temp_eq_array
      end
    end
    @op_map.each do |t|
      temp_eq_array={}
      temp_eq_array["bulp"] = t[:value]==1?"green":"red"
      temp_eq_array["label"] = " : #{t[:evalue]}"
      temp_eq_array["name"] = t[:name].to_s
      @final_array << temp_eq_array
    end
  end


end
