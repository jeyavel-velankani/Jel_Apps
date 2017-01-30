module PtcHelper
  CommandSetEditMode = 3
  CommandIsEditMode = 4
  
  ####################################################################
  # Function:      setup
  # Parameters:    None
  # Return:        None
  # Renders:       message if error
  # Description:   Checked for existance of MCF & RT DB
  ####################################################################
  def ptc_setup
    if OCE_MODE == 1
      unless session[:cfgsitelocation].blank?
        validatemcfrtdatabase(session[:cfgsitelocation])
        if !(File.exists?(session[:cfgsitelocation] + '/mcf.db') && File.exists?(session[:cfgsitelocation] + '/rt.db'))        
          session[:error] = "Please create MCF DB and RT DB from configuration editor page by clicking save button, then try again."
          render :template => "/redirectpage/index" and return
        elsif session[:validmcfrtdb] == false
          session[:error] = "MCF DB and RT DB are not valid database , please create valid database from configuration editor page and try again. "
          render :template => "/redirectpage/index" and return
        end
        connectdatabase()
      else 
        session[:error] = "Please create/open the configuration from the configuration editor page and try again"
        render :template => "/redirectpage/index" and return
      end
    end
  end
  
  def get_ptc_data_style(signal_id, current_signal)
    signal_id == current_signal ? "style='background-color:#CFD638;color:#000;'" : ""
  end
   def delete_simple_request
    if session[:set_edit_mode_request]
      RrSimpleRequest.delete_all(["request_id = ?",session[:set_edit_mode_request]])
    end
  end
  
  def get_valid_wiuxml_objects
    if (File.exists?(session[:cfgsitelocation] + '/rt.db'))
      @signal_objects = RtParameter.find(:first, :conditions => ["mcfcrc = ? and (parameter_name Like 'G%_HA' OR parameter_name Like 'G%_HB' OR parameter_name Like 'G%_HC')",  Gwe.mcfcrc])
      @switch_objects = RtParameter.find(:first,:select => "current_value", :conditions => ["mcfcrc = ? and parameter_name Like 'W_Num'",  Gwe.mcfcrc])
      @hazard_objects = RtParameter.find(:first,:select => "current_value", :conditions => ["mcfcrc = ? and parameter_name Like 'HD_Num'",  Gwe.mcfcrc])
    end
  end
  
end
