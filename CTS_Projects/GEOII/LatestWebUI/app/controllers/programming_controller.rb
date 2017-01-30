####################################################################
# Company: Siemens 
# Author: Ashwin
# File: programming_controller.rb
# Description: Builds, validates, updates and controls all vital config
####################################################################
class ProgrammingController < ApplicationController
  include ProgrammingHelper
  include ExpressionHelper
  include ReportsHelper
  include SessionHelper
  layout "general"
  
  before_filter :cpu_status_redirect if PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI #session_helper

  ####################################################################
  # Function:      vital_config_menu
  # Parameters:    None
  # Return:        html_content
  # Renders:       JSON
  # Description:   Generate vital configuration menu options
  ####################################################################
  def vital_config_menu
    html_content = ""
    oceflag = false
    parent_used = false
    @expression_structure = {}
    set_ui_expr_variables()
    if true #RtSession.ready? # TODO: check for ready session
      if !session[:cfgsitelocation].blank? && ((File.exists?(session[:cfgsitelocation] + '/mcf.db') && File.exists?(session[:cfgsitelocation] + '/rt.db')))
        oceflag = true
        connectdatabase()
      end
      if ((PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE && oceflag) || PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI)
          Gwe.refresh_mcfcrc
          @main_menu = {}
          @ucn_in_mcf = false
          parent_used = Menu.cpu_3_menu_system
          if parent_used
            if (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP") && (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE && oceflag))
              # OCE GCP MENU System
              menus = Menu.all(:conditions => ["mcfcrc = ? and (target Not Like 'LocalUI')", Gwe.mcfcrc],:order => 'rowid', :select => "menu_name, link, parent, page_name, show, enable")
            else
              menus = Menu.all(:select => "menu_name, link, parent, page_name, show, enable", :conditions => ["mcfcrc = ? and layout_index = ? and page_name Like 'Vital Configuration'", Gwe.mcfcrc, Gwe.physical_layout],:order => 'rowid')  
            end
            # puts menus.inspect
          else
            menus = Treemenu.all(:select => "name as menu_name, link, '' as parent, parent_id as page_name, 'true' as enable",:conditions => ["mcfcrc = ? and layout_index = ?", Gwe.mcfcrc, Gwe.physical_layout],:order => 'display_order')        
          end
          
          if parent_used && PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI
            menus << Menu.new(:menu_name => "Name Editors", :page_name => "Vital Configuration", :show => "true", :enable => "true", :link => "(NULL)", :parent => "(NULL)")
            menus << Menu.new(:menu_name => "Object Names", :page_name => "Vital Configuration", :show => "true", :enable => "true", :link => "{OBJECTNAMEEDITOR/SAT}", :parent => "Name Editors")
            menus << Menu.new(:menu_name => "Card Names", :page_name => "Vital Configuration", :show => "true", :enable => "true", :link => "{OBJECTNAMEEDITOR/CARD}", :parent => "Name Editors")
          end
          
          menus.each_with_index do |menu, index|
            if parent_used
              show_value = eval_expression(menu.show) ? true : false
            else
              menu_show = true
              menu_enable = true
              menu_show, menu_enable = Treemenu.get_menu_show_value(menu) if !menu.link.empty?
              show_value = eval_expression(menu_show.to_s) ? true : false if !menu_show.blank?            
              menu.enable = menu_enable.to_s
            end          
             if show_value
              if parent_used
                if (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP") && (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE && oceflag))
                  parent_name = (menu.parent == '(NULL)' && menu.page_name.eql?('MAIN PROGRAM menu')) ? 'ROOT' : menu.parent
                else
                  parent_name = (menu.parent == '(NULL)' && menu.page_name.eql?('Vital Configuration')) ? 'ROOT' : menu.parent    
                end
              else
                parent_name = (menu.page_name.eql?('MAIN PROGRAM menu')) ? 'ROOT' : menu.page_name
              end
              if @main_menu.has_key?(parent_name)
                menu_item = @main_menu[parent_name]
                menu_item << menu
                @main_menu[parent_name] = menu_item
              elsif (!parent_used && parent_name != 'MAIN PROGRAM menu') || (parent_used && parent_name != 'Vital Configuration')
                @main_menu[parent_name] = [menu]
              end
              #@ucn_in_mcf = true if menu.menu_name == "Unique Check Number (UCN)"
            end
            @ucn_in_mcf = true if menu.menu_name == "Unique Check Number (UCN)"
          end
          if !@ucn_in_mcf && parent_used && PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI
            @main_menu["ROOT"] << Menu.new(:menu_name => "Unique Check Number (UCN)", :page_name => "Vital Configuration", :show => "true", :enable => "true", :link => "{UCN}")
          end
          
          html_content = render_to_string(:partial => 'vital_config_menu')
      end
    end
    render :json => {:html_content => html_content} and return
  end

  ####################################################################
  # Function:      page_parameters
  # Parameters:    menu_link, page_name
  # Return:        html_content
  # Renders:       JSON
  # Description:   Generate parameters for a given page
  ####################################################################
  def page_parameters
    set_ui_expr_variables()
    atcs_addr = atcs_address
    @atcs_address = atcs_addr
    $expression_mapper = {}
    @expression_structure = {}
    @verify_screen = true
    @user_presence = GenericHelper.check_user_presence
    result, html_content = get_parameters
    screen_verify_flag = true
    screen_verify_flag = false if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
    render :json => {:error => result, :html_content => html_content, :screen_verification => screen_verify_flag} and return
  end

  ####################################################################
  # Function:      get_parameters
  # Parameters:    menu_link, page_name
  # Return:        html_content
  # Renders:       JSON
  # Description:   Generate parameters for a given page
  ####################################################################
  def get_parameters
    html_content = ""
    @expression_structure = {}
    atcs_addr = atcs_address
    @ui_state = Uistate.vital_user_present?(atcs_addr)
    @mtf_index = 0
    @template_disable = import_site
    if(!params[:setup_wizard].blank?)
      @sel_template = get_active_template(params[:page_name])
      expression = eval_expression(@sel_template.enable)
      next_template = @sel_template
      while !expression && next_template.prev != "LAST PAGE"
        next_template_page_name = (params[:page_type] == "prev")? next_template.prev : next_template.next
        next_template = get_active_template(next_template_page_name)
        if next_template
          expression = eval_expression(next_template.enable)
        else
          expression = true
        end
      end
      @sel_template = next_template
      @mtf_index = @sel_template.mtf_index
      params[:page_name] = @sel_template.page_name
    else
      if (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP") && (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE)) 
        @page = Page.find_by_page_name(params[:menu_link], :include => [:tabs])
        @tabs = @page.tabs if @page
      end
    end
    current_mcfcrc = Gwe.mcfcrc
    current_phy_layout = Gwe.physical_layout
    if (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP") && (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE))
      @page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and layout_index = ? and mtf_index = ? and (target Not Like 'LocalUI') and page_name Like ? ", current_mcfcrc, current_phy_layout, @mtf_index, params[:page_name].strip], :order => 'display_order asc')
      if @page_parameters.blank?
        @page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and layout_index = ? and mtf_index = ? and (target Not Like 'LocalUI') and  page_name Like ? ", current_mcfcrc, current_phy_layout, @mtf_index, params[:menu_link].strip], :order => 'display_order asc')
      end
    else
      @page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and layout_index = ? and page_name Like ? ", current_mcfcrc, current_phy_layout, params[:page_name].strip], :order => 'display_order asc')
      if @page_parameters.blank?
        @page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and layout_index = ? and page_name Like ? ", current_mcfcrc, current_phy_layout, params[:menu_link].strip], :order => 'display_order asc')
      end
    end
    @parameters = {}
    if !@page_parameters.blank?
      @card_index = @page_parameters.map(&:card_index).uniq
      mcf_parameters = Parameter.all(:conditions => {:mcfcrc => current_mcfcrc, :layout_index => current_phy_layout, :cardindex => @card_index,
                         :name => @page_parameters.map(&:parameter_name), :parameter_type => @page_parameters.map(&:parameter_type)})
      mcf_parameters.each do |parameter|
        @parameters["#{parameter.cardindex}.#{parameter.name.strip}"] = parameter
      end
    end
    if Menu.cpu_3_menu_system
      if PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI || (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s != "GCP") && (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE))
        @sub_menus = Menu.all(:conditions => ["mcfcrc = ?  and layout_index = ? and page_name Like ? ", current_mcfcrc, current_phy_layout, params[:page_name].strip], :order => 'rowid', :select => "menu_name, link, show, enable")        
      end
    end 
    html_content = render_to_string(:partial => 'build_generic')
    return false, html_content
  end

  ####################################################################
  # Function:      save_page_parameters
  # Parameters:    menu_link, page_name, card_index
  # Return:        None
  # Renders:       JSON
  # Description:   Save parameters using setCfgPropertyiviu request
  ####################################################################
  def save_page_parameters
    begin
      setcfgproprq_id = -1
      #page = Page.find(:first, :conditions => ["cdf like \'CONFIGVIEW.%\' and page_name like ? and mcfcrc = ? and layout_index = ?", params[:menu_link], Gwe.mcfcrc, Gwe.physical_layout])
      number_of_cards, number_of_params = 0, 0
      param_change_count = 0
      prop_card_id = nil
      parameters_values = {}
      templateSelected = 0
      unit_measure = 0
      gwe = Gwe.get_mcfcrc(atcs_address)
      if gwe.blank?
        gwe = Gwe.find(:first)
      end
      current_mcfcrc = gwe.mcfcrc
      current_phy_layout = gwe.active_physical_layout || 0
      current_mtf_index = gwe.active_mtf_index || 0
      params[:menu_link] = params[:page_name] if params[:menu_link].blank?
      if ((PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE ) && (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP")))
        unit_measure = (EnumValue.units_of_measure).Value
        @sel_template = get_active_template(params[:page_name])
        if !@sel_template.blank?
          templateSelected = @sel_template.mtf_index
        end
      end
      active_card_index = eval(params[:card_index])
      card_count =0
      if PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE
        setcfgproprq = SetCfgPropertyiviuRequest.new(:request_state => 0, :mcf_type => 0, :atcs_address => atcs_address,:command => 12)
        render :json => {:error => true} and return if !setcfgproprq.save
        setcfgproprq_id = setcfgproprq.id
      end

      ########################################################
          # OCE-GCP SetupWizard and SEt Template page MTFINDEX value change need to update the corresponding rt_parameters table values using OCE C#.Net component
          if ((params[:page_name].to_s == "TEMPLATE:  selection") || (params[:menu_link].to_s == "TEMPLATE:  selection") || (params[:page_name].to_s == "Set Template") || (params[:menu_link].to_s == "Set Template"))
            if !params[:MTFIndex].blank? && ((PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE ) && (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP")))
              selected_mtfindex = params[:MTFIndex].to_i
              if (current_mtf_index != selected_mtfindex)
                simulator = "\"#{session[:OCE_ROOT]}\\GCP_OCE_Manager.exe\", \"#{5}\" \"#{session[:cfgsitelocation]}\" \"#{session[:OCE_ROOT]}\" \"#{selected_mtfindex}\""
                puts  simulator
                message_str = ""
                if system(simulator)
                  error_log_path = "#{session[:cfgsitelocation]}+'\oce_gcp_error.log'"
                  result,content = read_error_log_file(error_log_path)
                  if(result == true || result == 'true')
                    message_str = content
                  end
                  puts "------------------------------------ Setup Wizard Pass ----------------------------"
                else
                  puts "------------------------------------ Setup Wizard Failed ----------------------------"
                  message_str = "Decompress Failed"
                end
                if !message_str.blank?
                  raise Exception, message_str
                end
              end
            end
          end          
      #########################################################       
      
        active_card_index.each do |crd|
          number_of_cards = 0
          number_of_params = 0
          card_ind = crd.to_i # crd[:card_index].to_i
          if (!session[:typeOfSystem].blank? && (session[:typeOfSystem].to_s == "GCP") && (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE))   
            page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and layout_index = ? and card_index = ? and mtf_index = ? and (target Not Like 'LocalUI') and page_name Like ? ", current_mcfcrc, current_phy_layout, card_ind, templateSelected, params[:page_name].strip], :order => 'display_order asc')
            if page_parameters.blank?
              page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and layout_index = ? and card_index = ? and mtf_index = ? and (target Not Like 'LocalUI') and  page_name Like ? ", current_mcfcrc, current_phy_layout, card_ind, templateSelected, params[:menu_link].strip], :order => 'display_order asc')
            end
          else
            page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and layout_index = ? and card_index = ? and page_name Like ? ", current_mcfcrc, current_phy_layout, card_ind, params[:page_name].strip], :order => 'display_order asc')
            if page_parameters.blank?
              page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and layout_index = ? and card_index = ? and page_name Like ? ", current_mcfcrc, current_phy_layout, card_ind, params[:menu_link].strip], :order => 'display_order asc')
            end
          end
          next if page_parameters.blank?
          #render :json => {:error => true} and return if page_parameters.blank?
          page_parameters.each do |page_parameter|
            parameter = Parameter.find(:first, :conditions => {:mcfcrc => current_mcfcrc, :layout_index => current_phy_layout, :cardindex => page_parameter.card_index, :name => page_parameter.parameter_name, :parameter_type => page_parameter.parameter_type})
            next if(parameter.nil? || params[parameter.name].nil?)
            curval = get_current_value(parameter)
            newval = params[parameter.name]
            newval_rt = newval
            value_name = nil
            unitstr = ""
            integertype = parameter.integertype[0]
            if(parameter.data_type == "IntegerType" && (parameter.integertype[0].metric_unit == "mA" || parameter.integertype[0].metric_unit == "mV"))
              newval = (newval.to_f * 1000).to_i
            end
            if parameter.data_type == "IntegerType" && newval.to_i < 0
              newval = get_signed_to_unsigned(newval.to_i, parameter.integertype[0].size)  
              value_name = params[parameter.name]
            end
            
            unless integertype.blank?
              unit_imp = integertype.imperial_unit
              if((unit_measure == 1) && (!unit_imp.blank?))
                unitstr =  integertype.metric_unit.strip
                newval = metric_to_imperial(integertype,  newval.to_i)
              else
                unitstr = integertype.imperial_unit.strip
              end
            end

            temp_val = newval
            old_value_name = ""
            new_value_name = ""
            measurement = ""
            next if params[parameter.name] == nil || curval.to_i == temp_val.to_i #|| (parameter.include_in_ucn == "Yes" && !is_user_presence(atcs_address))
            number_of_params += 1
            param_change_count += 1

            if PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE
              if number_of_cards == 0
                number_of_cards += 1
                card_count +=1
                propcards = SetPropIviuCard.new(:request_id => setcfgproprq_id, :card_number => parameter.cardindex,
                            :data_kind => parameter_type_to_data_kind(parameter.parameter_type), :number_of_parameters => 1)
                card = Card.find(:first, :select => 'pci_ci, crd_type, pci_ci_ver', :conditions => {:card_index => parameter.cardindex, :parameter_type => parameter.parameter_type, :layout_index =>current_phy_layout, :mcfcrc => current_mcfcrc})
                pci_ci = pci_ci_version = 1
                if card
                  propcards.card_type =  card.crd_type
                  pci_ci = (card.crd_type == 130) ? 1 : card.pci_ci
                  pci_ci_version = card.pci_ci_ver
                else
                  c_index = Card.find(:first, :select => 'card_index', :conditions => { :crd_type => page_parameter.parameter_type, :mcfcrc => current_mcfcrc, :layout_index =>current_phy_layout}).try(:card_index)
                  rt_card = RtCard.find(:first, :select => 'pci_ci, pci_ci_version', :conditions => {:c_index => c_index, :parameter_type => parameter.parameter_type, :mcfcrc => current_mcfcrc}) if c_index
                  if(c_index && rt_card)
                    propcards.card_type =  page_parameter.parameter_type
                    pci_ci = rt_card.pci_ci
                    pci_ci_version = rt_card.pci_ci_version
                  end
                end
                propcards.pci_ci = pci_ci
                propcards.pci_ci_version = pci_ci_version
                render :json => {:error => true} and return if !propcards.save
                prop_card_id = propcards.id
              end
              propcardparams = SetPropIviuParam.new(:id_card => prop_card_id, :parameter_index => parameter.parameter_index + 1,
                                                   :context_string => parameter.context_string.strip)
              propcardparams.parameter_name = parameter.param_long_name.strip if parameter.param_long_name != nil
              
              if integertype != nil
                newval = check_signed_value(integertype.size, newval.to_i)
                newval_rt = (newval.to_f * (1000 / integertype.scale_factor.to_f)).to_i
                propcardparams.value = newval
                propcardparams.unit =  unitstr
                measurement = unitstr
                old_value_name = curval
                new_value_name = newval
              else
                propcardparams.value = newval.strip
              end
              if parameter.enumerator[0]
                get_enum = parameter.getEnumerator(newval)
                propcardparams.value_name = get_enum
                old_value_name = parameter.getEnumerator(curval)
                new_value_name = get_enum
              else
                propcardparams.value_name = value_name || new_value_name.to_i #params[parameter.name].to_i
              end
              render :json => {:error => true} and return if !propcardparams.save
            else
              integertype = parameter.integertype[0]
              if integertype != nil
                newval = check_signed_value(integertype.size, newval.to_i)
                newval_rt = (newval.to_f * (1000 / integertype.scale_factor.to_f)).to_i
              end
            end
  
            parameters_values[parameter.name] = {:card_index => parameter.cardindex,
                                                 :param_type => parameter.parameter_type,
                                                 :param_index => parameter.parameter_index,
                                                 :new_value => newval_rt
                                                 }
          end
          if number_of_params > 1 && PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE
            SetPropIviuCard.update_all "number_of_parameters = #{number_of_params}", "request_id = #{setcfgproprq_id} and id_card = #{prop_card_id}"
          end
        end
        
        if PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE
          SetCfgPropertyiviuRequest.update_all "number_of_cards =  #{card_count.to_i}", "request_id = #{setcfgproprq_id}"
          #
          # if no changes then nothing to save
          #
          if param_change_count == 0
             SetCfgPropertyiviuRequest.update_all "confirmed =  400, request_state = 2", "request_id = #{setcfgproprq_id}"
          else
            udp_send_cmd(REQUEST_COMMAND_SET_PROP_IVIU, setcfgproprq_id)
          end
        end
      
      render :json => {:error => false, :request_id => setcfgproprq_id, :parameters_values => parameters_values } and return
      
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end
  end

  ####################################################################
  # Function:      save_atcs_sin
  # Parameters:    new_atcs_sin
  # Return:        None
  # Renders:       JSON
  # Description:   Update atcs sin
  ####################################################################
  def save_atcs_sin
    begin
      new_sin_value = params[:atcs_address]
      type = params[:atcs_id].split('_')[0]
      sin_id = params[:atcs_id].split('_')[1]
      render :json => {:error => true, :message => "Invalid ATCS SIN"} and return if new_sin_value.blank?      
      if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
        update_rt_sin_values(sin_id, new_sin_value)
        render :json => {:error => false, :request_id => 0, :sin_id => sin_id, :new_sin_value => new_sin_value } and return
      else
        setcfgproprq = SetCfgPropertyiviuRequest.new(:request_state => 0, :mcf_type => 0, :atcs_address => atcs_address,
                        :command => 12, :number_of_cards => 1)
        if(setcfgproprq.save)
          propcards = SetPropIviuCard.new(:request_id => setcfgproprq.id, :card_number => 0, :card_type => 0,
                        :data_kind => 100, :pci_ci => 1, :pci_ci_version => 1, :number_of_parameters => 12)
          if(propcards.save)              
            new_sin_value.gsub(".", '').split(//).each_with_index do |value, index|
              propcardparams = SetPropIviuParam.new(:id_card => propcards.id, :parameter_index => index + 1, 
                                :value => value)
              propcardparams.save
            end
            udp_send_cmd(REQUEST_COMMAND_SET_PROP_IVIU, setcfgproprq.id)
            render :json => {:error => false, :request_id => setcfgproprq.id, :sin_id => sin_id, :new_sin_value => new_sin_value } and return
          else
            render :json => {:error => true, :message => "Failed to save ATCS SIN"}
          end
        else
          render :json => {:error => true, :message => "Failed to save ATCS SIN"}
        end
      end
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end
  end
  
  ####################################################################
  # Function:      check_save_atcs_sin_req
  # Parameters:    request_id
  # Return:        None
  # Renders:       JSON
  # Description:   Check request state
  ####################################################################
  def check_save_atcs_sin_req
    begin
      if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
        header_str = "Site Name: " + session[:s_name].to_s + "| ATCS Address: " + session[:atcs_address].to_s + "| Mile Post: " + session[:m_post].to_s + "| DOT Number: " + session[:dot_num].to_s
        render :json => { :error => false, :request_state => 2, :html => header_str}
      else
        setcfgproprq = SetCfgPropertyiviuRequest.find_by_request_id(params[:request_id])
        if(setcfgproprq && setcfgproprq.request_state == 2)
          result, message = true, "Failed to save ATCS SIN"
          if(setcfgproprq.confirmed == 0)
            result, message = false, "ATCS SIN saved successfully"
            StringParameter.update(params[:sin_id],params[:new_sin_value])
          elsif(setcfgproprq.confirmed == 400)
            result, message = false, "No changes observed in the ATCS SIN"
          end
          delete_request(params[:request_id], REQUEST_COMMAND_SET_PROP_IVIU)
          render :json => {:error => result, :request_state => setcfgproprq.request_state , :html => "", :message => message, :confirmed => setcfgproprq.confirmed}
        else
          delete_request(params[:request_id], REQUEST_COMMAND_SET_PROP_IVIU) if(params[:delete_request] == "true")
          render :json => { :error => false, :request_state => setcfgproprq.request_state }
        end
      end
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end
  end
  
  ####################################################################
  # Function:      get_current_value
  # Parameters:    menu_link, page_name, card_index
  # Return:        None
  # Renders:       JSON
  # Description:   Get integer value of related mcf parameter
  ####################################################################
  def get_current_value(parameter, rt_parameter=nil) #TODO: move this to private method
    return nil if parameter.nil?
    rt_parameter = RtParameter.find(:first, :conditions => {:mcfcrc => Gwe.mcfcrc, :card_index => parameter.cardindex, :parameter_name => parameter.name, :parameter_index => parameter.parameter_index})
    if rt_parameter
      factor = 1
      check_for_signed = nil
      integer_parameter = parameter.integertype[0]
      unless integer_parameter.nil?
        factor = (integer_parameter.scale_factor.to_f / 1000).to_f
        check_for_signed = true if integer_parameter.signed_number == 'Yes'
      end
      value = rt_parameter.current_value.to_f * factor
      value = get_signed_value(value, parameter.integertype[0].size) if !check_for_signed.nil?
      value.to_i
    else
      parameter.default_value
    end
  end

  ####################################################################
  # Function:      check_v_save_req
  # Parameters:    menu_link, page_name, card_index
  # Return:        None
  # Renders:       JSON
  # Description:   Check request state
  ####################################################################
  def check_v_save_req
    parameters_hash = {}
    flg_signal = false
    flg_switch = false
    flg_hazd = false
    begin
      if PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE
        setcfgproprq = SetCfgPropertyiviuRequest.find_by_request_id(params[:request_id])
        if(setcfgproprq && setcfgproprq.request_state == 2)
          result, message = true, "Failed to save parameters"
          if(setcfgproprq.confirmed == 0)
            if params[:page_name].strip == "PHYSICAL configuration"
              result, message = false, "Saved parameters successfully. VLP is rebooting..."
            else
              result, message = false, "Saved parameters successfully"
            end
            if(params[:parameters_values])
              parameters_hash = params[:parameters_values]
              parameters_hash.each do |parameter, param_prop|
                update_rt_parameter(parameter, param_prop[:card_index].to_i, param_prop[:param_type].to_i, param_prop[:param_index].to_i, param_prop[:new_value].to_i)
              end
            end
          elsif(setcfgproprq.confirmed == 400)
            result, message = false, "No changes observed in the parameters"
          end
          @expression_structure = {}
          @verify_screen = false
          @user_presence = GenericHelper.check_user_presence
          load_result, html_content = get_parameters
          delete_request(params[:request_id], REQUEST_COMMAND_SET_PROP_IVIU)
          render :json => {:error => result, :request_state => setcfgproprq.request_state , :html => html_content, :message => message, :reload_menu => false, :confirmed => setcfgproprq.confirmed}
        else
          delete_request(params[:request_id], REQUEST_COMMAND_SET_PROP_IVIU) if(params[:delete_request] == "true")
          render :json => { :error => false, :request_state => setcfgproprq.request_state }
        end
      else
        result = false
        reload_menu = false
        if(params[:parameters_values])
          parameters_hash = params[:parameters_values]
          parameters_hash.each do |parameter, param_prop|
            if (parameter == "PhysicalLayoutIndex")
                rt_param_current_value = RtParameter.find(:first ,:select => "current_value" ,:conditions => ["parameter_name = ? and card_index = ? and parameter_type =? and parameter_index =?",parameter , param_prop[:card_index].to_i ,param_prop[:param_type].to_i , param_prop[:param_index].to_i])
                if rt_param_current_value.current_value.to_i != param_prop[:new_value].to_i
                  phy_layout_changes_oce_update(param_prop[:new_value].to_i)
                  reload_menu = true
                end
            end
            update_rt_parameter(parameter, param_prop[:card_index].to_i, param_prop[:param_type].to_i, param_prop[:param_index].to_i, param_prop[:new_value].to_i)
            if(session[:typeOfSystem] == "VIU" && param_prop[:param_type].to_i == 13)
              if (parameter.to_s.upcase == "W_NUM")
                flg_switch = true
              elsif(parameter.to_s.upcase == "HD_NUM")
                flg_hazd= true
              elsif(parameter.to_s.upcase.start_with?("G") && parameter.to_s.upcase.end_with?("_HA", "_HB", "_HC"))
                flg_signal = true
              end              
            end
          end
          #***Update PTC Devices***#
          if (flg_signal == true || flg_switch == true || flg_hazd == true)
            update_PTC_Devices(flg_signal, flg_switch, flg_hazd)
          end
        end
        @expression_structure = {}
        @verify_screen = false
        @user_presence = GenericHelper.check_user_presence
        load_result, html_content = get_parameters
        render :json => {:error => result, :request_state => 2 , :html => html_content, :message => "Saved parameters successfully", :reload_menu => reload_menu, :confirmed => 0}   
      end
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end
  end
  
  ####################################################################
  # Function:      phy_layout_changes_oce_update
  # Parameters:    newval
  # Return:        None
  # Renders:       None
  # Description:   OCE: Recreate the Rt database and update the corresponding values  
  #################################################################### 
  def phy_layout_changes_oce_update(newval)
    instalationname = ""
    geoptc_path = ""
    activeinstallation = newval.to_i
    phy_lay_and_default_type = 2
    
    Gwe.update_all("active_physical_layout = '#{newval.to_s}'")
    
    mcf_installations = Installationtemplate.all.map(&:InstallationName)
    if (mcf_installations.length >1)
      installation_name_default = mcf_installations[activeinstallation.to_i-1]
    else
      installation_name_default = mcf_installations[0].to_s
    end
    instalationname = installation_name_default.to_s  
    if session[:siteptcdblocation].blank?
      if File.exist?(session[:cfgsitelocation]+'/site_ptc_db.db')
        session[:siteptcdblocation] = File.join(session[:cfgsitelocation] , 'site_ptc_db.db')
      end
    end
    geoptc_db = session[:siteptcdblocation]
    geoptc_path = converttowindowspath(geoptc_db)
    mcfpath = session[:cfgsitelocation]+'/'+session[:mcfnamefromselected].to_s
    out_dir =  RAILS_ROOT+"/oce_configuration/"+session[:user_id].to_s+'/DT2'
    aspectlookuptxtfilepath = session[:aspectfilepath]
    nv_template_flag = "false"
    simulator = "\"#{session[:OCE_ROOT]}\\UIConnector.exe\", \"#{converttowindowspath(mcfpath)}\" \"#{converttowindowspath(out_dir)}\" \"#{geoptc_path}\" \"#{instalationname}\" \"#{session[:typeOfSystem]}\" \"#{newval}\" \"#{phy_lay_and_default_type.to_i}\" \"#{converttowindowspath(aspectlookuptxtfilepath)}\" \"#{nv_template_flag}\" "
    puts simulator.inspect
    system(simulator)
    RtParameter.update_current_to_dafault_vale(session[:cfgsitelocation]+'/rt.db')
  end

  ####################################################################
  # Function:      verify_screen
  # Parameters:    menu_link, page_name, card_index
  # Return:        None
  # Renders:       JSON
  # Description:   method to verify screen parameters
  #################################################################### 
  def verify_screen
    begin
      @page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and layout_index = ? and page_name Like ? ", Gwe.mcfcrc, Gwe.physical_layout, params[:page_name].strip], :order => 'display_order asc')
      if @page_parameters.blank?
        @page_parameters = PageParameter.all(:conditions => ["mcfcrc = ? and layout_index = ? and page_name Like ? ", Gwe.mcfcrc, Gwe.physical_layout, params[:menu_link].strip], :order => 'display_order asc')
      end
      if(@page_parameters.length > 0)
        @mcf_parameters = Parameter.all(:conditions => {:mcfcrc => Gwe.mcfcrc, :layout_index => Gwe.physical_layout, :cardindex => @page_parameters.map(&:card_index),
                             :name => @page_parameters.map(&:parameter_name), :parameter_type => @page_parameters.map(&:parameter_type)})
        number_of_parameters = evalute_showhide_exp(@page_parameters)
        screen_iviu_request = VerifyScreenIviuRequest.initiate_verify_request(atcs_address || "", number_of_parameters)#TODO: handle atcs_address nil case
        screen_verification(screen_iviu_request)
        render :json => {:error => false, :request_id => screen_iviu_request.request_id}
      else
        render :json => {:error => true, :message => "No parameters found"}
      end
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end
  end

  ####################################################################
  # Function:      check_screen_verification_state
  # Parameters:    menu_link, page_name, card_index
  # Return:        None
  # Renders:       JSON
  # Description:   method to check request state for screen verification
  #################################################################### 
  def screen_verification_req_state
    begin
      verifyscreenrq = VerifyScreenIviuRequest.find_by_request_id(params[:request_id])
      if(verifyscreenrq && verifyscreenrq.request_state == 2)
        delete_request(params[:request_id], REQUEST_COMMAND_VERIFY_SCREEN_IVIU)
        render :json => {:error => (verifyscreenrq.crc_confirmed == 0)? false:true, :request_state => verifyscreenrq.request_state}
      else
        delete_request(params[:request_id], REQUEST_COMMAND_VERIFY_SCREEN_IVIU) if(params[:delete_request] == "true")
        render :json => { :error => false, :request_state => verifyscreenrq.request_state }
      end
    rescue Exception => e
      render :json => {:error => true, :message => e.message}
    end
  end

  ####################################################################
  # Function:      cleanup_verify_screen_request
  # Parameters:    request_id
  # Return:        None
  # Renders:       JSON
  # Description:   clearing screen verification request
  #################################################################### 
  def cleanup_verify_screen_request
    request_id = params[:request_id].to_i
    if request_id
      VerifyDataIviuRequest.delete_all(:request_id => request_id) rescue nil
      VerifyScreenIviuRequest.delete_all(:request_id => request_id) rescue nil
    end
    render :json => {:cleanupOK => true}
  end
  
  ####################################################################
  # Function:      screen_verification
  # Parameters:    screen_iviu_request
  # Return:        request_id
  # Renders:       None
  # Description:   creating screen verification record and sending UDP
  ####################################################################  
  def screen_verification(screen_iviu_request)#TODO: move this to private method
	  @page_parameters.each do |page_parameter|
		parameter = @mcf_parameters.find{|mcf_parameter| page_parameter.card_index == mcf_parameter.cardindex && page_parameter.parameter_name == mcf_parameter.name && page_parameter.parameter_type == mcf_parameter.parameter_type }
		if parameter && $expression_mapper[page_parameter.parameter_name.strip + "_" + page_parameter.card_index.to_s]
		  data_verify_request = VerifyDataIviuRequest.new
		  data_verify_request.request_id = screen_iviu_request.request_id
		  data_verify_request.parameter_index = (parameter.parameter_index + 1)
		  data_verify_request.parameter_name = parameter.param_long_name
		  parameter_long_name = params[parameter.name + "_" + parameter.cardindex.to_s]
		  current_value = nil
		  if(parameter_long_name == parameter.param_long_name)
			current_value = params[parameter.name]
		  end
		  data_verify_request.parameter_type = parameter_type_to_data_kind(parameter.parameter_type)
		  data_verify_request.card_number = parameter.cardindex

		  if parameter.enumerator[0]
			rt_parameter =  RtParameter.parameter(parameter) if current_value.blank?
			current_value = rt_parameter.current_value if rt_parameter
			data_verify_request.value = parameter.getEnumerator(current_value) if !current_value.blank?
		  else
			data_verify_request.value = get_current_value(parameter)
		  end
		  data_verify_request.context_string = parameter.context_string.strip
		  integer_type = parameter.integertype[0]
		  data_verify_request.unit =  integer_type.imperial_unit.strip if integer_type
		  data_verify_request.save
		end
	  end
	  udp_send_cmd(REQUEST_COMMAND_VERIFY_SCREEN_IVIU, screen_iviu_request.request_id)
	  $expression_mapper = {}
  end
  
  ####################################################################
  # Function:      set_to_default
  # Parameters:    none
  # Return:        request_id
  # Renders:       None
  # Description:   Initial call for set to default 
  ####################################################################    
  def set_to_default
    @user_presence = GenericHelper.check_user_presence
    if(params[:send_request] == 'true')
      send_default_request
    end
    html_content = render_to_string(:partial => "set_to_default")
    render :json => {:error => false, :html_content => html_content} 
  end

  ####################################################################
  # Function:      send_default_request
  # Parameters:    none
  # Return:        request_id
  # Renders:       None
  # Description:   creating request for set_to_default
  ####################################################################  
  def send_default_request
    if PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE     
      simple_request = RrSimpleRequest.create(:request_state => ZERO , :atcs_address => atcs_address + ".02", :command => REQUEST_SET_TO_DEFAULT)
      udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST,simple_request.request_id) 
    else
      #       ONLY FOR OCE - START DEFAULT
      RtParameter.update_default_to_current_vale(session[:cfgsitelocation]+'/rt.db')
      update_PTC_Devices(true, true, true)
    end  
  end
  
  ####################################################################
  # Function:      check_set_to_default
  # Parameters:    none
  # Return:        none
  # Renders:       geo_session
  # Description:   checking geo_session for set_to_default
  ####################################################################    
  def check_set_to_default
    if PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE   
      if is_geo_in_session(atcs_address)
        render :json => { :geo_session => true, :message => "Set to default successfully completed" } and return
      else
        render :json => { :geo_session => false} and return    
      end
    else
        render :json => { :geo_session => true, :message => "Set to default successfully completed" } and return
    end
  end
    
  # method to check user session
  def check_supervisor_session
    rt_parameter = RtParameter.find_by_parameter_name("SuperPassword4",
                    :conditions => {:mcfcrc => Gwe.mcfcrc, :sin => atcs_address, :parameter_type => 2}, :select => "current_value")
    session[:supervisor] = if(rt_parameter && !params[:user][:password].blank? && (rt_parameter.current_value.to_s.strip == params[:user][:password].strip))
      true
    else
      false
    end
    redirect_to("/programming/page_parameters?page_name=#{params[:page_name]}&menu_link=#{params[:menu_link]}")
  end

  def set_to_default_index
    @enable, @show = false, false
    @ui_state = Uistate.vital_user_present
    set_template_menu = Menu.find(:first, :conditions => ["menu_name = 'Set Template Defaults' and page_name = 'TEMPLATE:  selection' "], :select => "enable, show")
    if(set_template_menu && get_exp_value(set_template_menu.show))
      handle_security
      @show = true
     @expression_structure = {}
     @enable = eval_expression(set_template_menu.enable)
    end
  end

  def link_parameter
    @menu_param_name = params[:menu_name].to_s
    if !params[:link_name].blank?
      @link_name = params[:link_name].gsub("{","").gsub("}","").downcase
    end
    @sin_value = Gwe.find(:first, :select => "sin").try(:sin) || ""
  end

  def check_user_presence
    @user_presence = (Uistate.vital_user_present)? "true" : "false"
    render :text => @user_presence
  end

  #*****************************************************************
  #*****************************************************************
  # 4/8/2013
  # module_reset method does not appear to be used.
  # FIXME: Delete in a future build.
  #*****************************************************************
  #*****************************************************************
  def module_reset
    reboot_request = RebootRequest.new
    reboot_request.request_state = 0
    reboot_request.atcs_address = atcs_address + ".01"
    reboot_request.slot_number = 1
    reboot_request.save!
    udp_send_cmd(REQUEST_COMMAND_RESET, reboot_request.request_id)
    sleep 2
    render :text => "Vital CPU rebooted"
  end
  #*****************************************************************
  #*****************************************************************

  def reset_vlp
    #do nothing

   render :layout => false
  end

  def load_template_details
    template = Template.get_template(params[:mtf_index])
    render :partial => 'template_details', :locals => {:template => template}
  end
  
  def setup_wizard
    @expression_structure = {}
    @templates_list = []
    @selected_template = nil
    first_menu_link = nil
    # get first menu link
    gwe = Gwe.get_mcfcrc(atcs_address)
    first_menu_link = Page.find(:first, :conditions => ["page_group = ? and mcfcrc = ? and page_name like '%TEMPLATE:%' and page_name like '%selection%'", "template", gwe.mcfcrc])
    
    # get first template of active_mtf_index
    next_template = Page.find(:first, :conditions => ["page_index = 0 and page_group = ? and mcfcrc = ? and mtf_index = ? ", "template", gwe.mcfcrc, gwe.active_mtf_index])
    if(next_template.nil? || (first_menu_link && next_template.page_name != first_menu_link.page_name))
      if first_menu_link && eval_expression(first_menu_link.enable)
        @templates_list << first_menu_link
        @selected_template = first_menu_link
        first_template_page_name = first_menu_link.page_name
      end
    end
    if next_template && eval_expression(next_template.enable)
      @templates_list << next_template
      if(@selected_template.nil?)
        @templates_list << next_template
        @selected_template = next_template
        first_template_page_name = next_template.page_name
      end
    end
    while (next_template && next_template.next != first_template_page_name)
      #get ative template
      tmp_template = Page.find(:first, :conditions => ["page_group = ? and mcfcrc = ? and mtf_index = ? and page_name = ?", "template", gwe.mcfcrc, gwe.active_mtf_index, next_template.next])
      #if active template not available get common template with mtf_index 0
      if(tmp_template.nil?)
        next_template = Page.find(:first, :conditions => ["page_group = ? and mcfcrc = ? and mtf_index = ? and page_name = ?", "template", gwe.mcfcrc, 0, next_template.next])
      else
        next_template = tmp_template
      end
      expression = eval_expression(next_template.enable)
      @templates_list << next_template if expression
    end
    params[:setup_wizard] = true
  end

  #***********************************************************************************************************************
  private
  #***********************************************************************************************************************

  def get_page_object(menu_link, page_type='next')
    page = Page.find_by_page_name(menu_link)

    if(menu_link == "MAIN PROGRAM menu")
      expression = false
    else
      expression = eval_expression(page.enable)
    end
    if expression
      params[:menu_link] = page.page_name
      return page
    else
      link = get_page_link(page, page_type)
      # calling recursively if page is disabled
      get_page_object(link, page_type)
    end
  end

  def get_page_link(page, page_type)
    case page_type
      when 'alt_prev' then page.alt_prev
      when 'alt_next' then page.alt_next
      when 'prev' then page.prev
      when 'next' then page.next
      end
  end

  def get_parent_used
    begin
      menu_parents = Menu.all(:select => "parent", :conditions => ["mcfcrc = ? and layout_index = ? and parent != '(NULL)'", Gwe.mcfcrc, Gwe.physical_layout],:order => 'rowid')
      if (menu_parents && (menu_parents.length>0))
        return true
      else
        return false
      end
    rescue Exception => e
      return false   
    end
  end

  # This method is used to get the current value of the parameter from rt_parameter table of RT database
  def get_current_integer_value(page_param)
    temp_card_index = page_param.card_index
    RtParameter.find_by_mcfcrc_and_card_index_and_parameter_type_and_parameter_index(Gwe.mcfcrc,temp_card_index,page_param.parameter_type,page_param.parameter_index) || 0
  end

  def scale_down_value(value, integertype)
    integertype.nil? ? value : (value.to_f * (1000 / integertype.scale_factor.to_f)).to_i
  end

  def get_enumerators
    if !RtSession.ready?
      return false
    end
    if $enumerators_hash.blank?
      $enumerators_hash = {}
      enumerators = ParamEnumerator.all(:conditions => {:mcfcrc => Gwe.mcfcrc})
      enumerators.each do |enumerator|
        $enumerators_hash["#{enumerator.enum_type_name}~#{enumerator.long_name}"] = enumerator.value
      end
    end
  end

  def handle_security
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      session[:envvarmap] = {"$WebUI" => 1, "$PasswordMatch" => 1, "$SuperPasswordMatch" =>  1, "$DTSupportsSuperPassword" => 1, "$GEO" => 1}
    end
  end

end