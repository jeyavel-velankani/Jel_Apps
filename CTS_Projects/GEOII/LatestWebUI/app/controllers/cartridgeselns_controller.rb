class CartridgeselnsController < ApplicationController  
  layout "general", :except=>"loading"
  require "socket"
  include ReportsHelper
  include UdpCmdHelper
  before_filter :setup

  def setup
  params[:act_type] = 'sel_val' if params[:act_type]=='' 
  @disable_signal = !logged_in?
  @type = 'sel_val'
  @channeldefault =''
  if params[:act_type] == 'default'
     @channeldefault = 0
     @type='default'
   end
   
   if OCE_MODE == 1
        unless session[:cfgsitelocation].blank?
            if !(File.exists?(session[:cfgsitelocation] + '/mcf.db') && File.exists?(session[:cfgsitelocation] + '/rt.db'))        
              session[:error] = "Please create MCF DB and RT DB from configuration editor page by clicking save button, then try again."
              redirect_to :controller=>"redirectpage" , :action=>"index"
            elsif session[:validmcfrtdb] == false
              session[:error] = "MCF DB and RT DB are not valid database , please create valid database from configuration editor page and try again. "
              redirect_to :controller=>"redirectpage" , :action=>"index"
            end
            connectdatabase()
        else 
          session[:error] = "Please create/open the configuration from the configuration editor page and try again"
          redirect_to :controller=>"redirectpage" , :action=>"index"
        end
    end
  end


  def pre_index
   @catridges = ParameterGroup.find_all_by_ID(27)
  end

  def edit
   if (@slot_id = params[:id]) && !params[:unused_slots]
     @ucn_disable_signal = !(Uistate.find_by_name_and_value_and_sin('local_user_present', 1, StringParameter.string_select_query(4)))
     flash.now[:notice] =  if params[:res_state].to_i == 0 && params[:command].to_i == 2
       "User Presence is successfully authenticated"
     elsif params[:command].to_i == 7 
       "Successfully updated the Slot Information"
     else
       "User Presence verification failed"
     end if params[:res_state] && params[:command]
     
     get_values
     if request.xhr?
       render :partial => "form"
    end
   elsif params[:unused_slots].size > 0
     @unused_slots = params[:unused_slots].scan(/\d+/)
     @slot_id = @unused_slots[0]
   else
     redirect_to :action => :index
   end
  end

  def get_values
    session[:cur_geo_atcs_addr] = nil
    session[:current_page] = nil                       
    session[:page_name] = nil  
   @group_id = @slot_id.to_i
   @enum_values = EnumValue.tempenum_dropdownbox_values.map{|u| [u.Name,u.ID]}
   @enum_values = @enum_values - [["Console NVCPU", 185], ["Console VCPU", 186]] if @slot_id.to_i > 1
   @enum_type = ParameterGroup.enum_value(@group_id) # Channel number need to be changed to 27 once the database is rectified
   
   @int_type = IntegerParameter.find_by_Group_ID_and_Group_Channel(27, @group_id)
   @string_type = StringParameter.find_by_Group_ID_and_Group_Channel(27, @group_id)
   @mcf_group = (Dir["/mnt/ecd/mcf/mcfs/*.mcf"].map{|m| File.basename(m).split(/ /)} rescue "")
    @sin = StringParameter.string_select_query(ATCS_Address)
    @atcs_addr = @sin + ".02" 
    @gwe = Gwe.find(:first,:select=>'mcf_name', :conditions=>["sin = ?",@sin])
    @rtsession = RtSession.find(:first, :conditions=>["atcs_address = ?","#{@atcs_addr}"])
    @ucn = get_ucn_value
  end

  def get_ucn_value
    begin
      txtfilepath = "/mnt/ecd/#{@group_id}/ucn.txt"
      file = File.new(txtfilepath, "r")
      while (line = file.gets)
        a = "#{line}".split(/['x','X']/)
        @data = a[1] if a.size() >= 2
      end
    rescue => err
      @data = ""
    end
    @data
  end

  def update_ucn
    @errors ||= []
    if params[:UCN].length <= 8 && params[:UCN].match(/^-{0,1}[a-fA-F0-9]*?$/)
        begin
          ucn_value = params[:UCN]
          (8 - params[:UCN].length).times{ucn_value = "0" + ucn_value}
          txtfilepath = "/mnt/ecd/#{@slot_id}"
          # txtfilepath = "db/#{@slot_id}"
          unless File.directory?(txtfilepath)
            File.makedirs(txtfilepath)
          end
          File.open("#{txtfilepath}/ucn.txt", 'w') {|f| f.write("UCN : 0x#{ucn_value}") }
          # need to make an UDP call
        rescue => err
          @errors << ["Saving UCN Failed"]
        end
    else
      @errors << "UCN is not in valid format"
    end
    @errors.empty? ? nil : @errors
  end

  def pre_update
   if (@slot_id = params[:id]) && logged_in?
     unless (@errors = ParameterGroup.group_parameter_values_update(params[:results])) || update_ucn # means no errors saving was successfull!
       atcs = StringParameter.string_select_query(4)
       rr_simple_request = RrSimpleRequest.create({:atcs_address => atcs + '.01', :command => 7, :request_state => 0, :result => ""})
       udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, rr_simple_request.id)
       session[:request_id] = rr_simple_request.id
     end
     render :edit
   end
  end
  

  def cat_index
   catridges_type = EnumParameter.get_enum_value(50, "Type")
   catridges_connection = EnumParameter.get_enum_value(50, "Connection")
   @catridges = catridges_type.map{|e| catridges_connection.map{|f| 
     {:type => e.item, :slot=>e.Group_Channel, :added_by=> cat_added_by(e.isLocked),
      :isLocked => e.isLocked, :comms=> f.item} if f.Group_Channel == e.Group_Channel }.compact}.flatten
  end

  def cat_edit
   if params[:slot_id] && !params[:unused_slots]
     @slot_id = params[:slot_id]
     @type = ParameterGroup.enum_value(@slot_id , :all)
     @type_values = EnumValue.tempenum_dropdownbox_values.map{|u| [u.Name,u.ID]}
     @type_values = @type_values - [["Console NVCPU", 185], ["Console VCPU", 186]] if @slot_id.to_i > 1
     @connection_values = EnumValue.connections_values.map{|u| [u.Name, u.ID]}
     if request.xhr?
       render :partial => "cat_form"
    end
   elsif params[:unused_slots] && params[:unused_slots].size > 0
     @unused_slots = params[:unused_slots].scan(/\d+/)
     @slot_id = @unused_slots[0]
   else
     redirect_to :action => :cat_index
   end
  end

  def cat_mode
   @cat_type_name =  EnumValue.find_by_ID(params[:type_id])
   @cat_modes = EnumParameter.get_cartridge_io_points(params[:slot_id], params[:type_id])
   render :partial => "cat_mode"
  end

  def cat_param_mode
   if request.xhr?
     @group_parameters = EnumParameter.get_mode_params(params[:slot_id], params[:mode_id])
     render :partial=>"cat_param_mode"
   else
      EnumParameter.save_comm_cartridge(params[:slot_id], params[:cat_comm])
      @cat_mode_options = EnumParameter.get_cartridge_enum_values(params[:slot_id], params[:type_id]).map{|u| [u.Name,u.ID]}
      @cat_mode = EnumParameter.find_by_ID(params[:cat_mode_id])
   end
  end

  def cat_param_update
  if logged_in?
    unless @errors = ParameterGroup.group_parameter_values_update(params[:cat_results])
      flash[:notice] = "Successfully saved the Cartridge Information"
      redirect_to :action => :cat_edit, :slot_id => params[:slot_id]
    else
      @cat_mode_options = EnumParameter.get_cartridge_enum_values(params[:slot_id], params[:type_id]).map{|u| [u.Name,u.ID]}
      @cat_mode = EnumParameter.find_by_ID(params[:cat_mode_id])
      render :action=> :cat_param_mode
    end
  end
  end

  def cat_added_by(isLocked)
     if (i = isLocked.to_i) == 0
       "not locked"
     elsif i == 1
       "CDL" #"locked by CDL"
     elsif i == 2
        "MCF" #"locked by MCF"
     else i == 3
       "User" #"user"
    end
  end
  
  def unlock_ucn
    atcs = StringParameter.string_select_query(4)
    rr_simple_request = RrSimpleRequest.create({:atcs_address => atcs + '.01', :command => 1, :request_state => 0, :result => "", :subcommand => 1})
    udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, rr_simple_request.id)
    session[:request_id] = rr_simple_request.id
    render :nothing => true
  end
  
  def check_unlock_ucn_status
    if rr_simple = RrSimpleRequest.find(session[:request_id])
      render :json => {:request_state => rr_simple.request_state, :result => (rr_simple.result || 9), :command => rr_simple.command}
    else
      render :nothing => true
    end
  end
  
  def reset_vcpu
    string_param = StringParameter.string_group(1, 0)
    atcs = string_param.select{|parameter| parameter.Name == "ATCS Address"}.first
    atcs =  atcs.String
    rr_simple_request = RrSimpleRequest.create({:atcs_address => atcs+".02", :command => 5, :request_state => 0, :result => ""})
    udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, rr_simple_request.id)
    render :json => {:request_id => rr_simple_request.id}
  end
  
  def check_reset_vcpu_state
    rr_simple_request = RrSimpleRequest.find(params[:request_id]) if !params[:request_id].blank?
    if(rr_simple_request)
      render :json => {:request_state => rr_simple_request.request_state, :result => rr_simple_request.result, :command => rr_simple_request.command}
    else
      render :json => {:request_state => 2, :result => 1}
    end
  end
  
end