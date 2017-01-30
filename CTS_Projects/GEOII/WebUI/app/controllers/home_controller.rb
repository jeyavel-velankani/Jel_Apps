class HomeController < ApplicationController
  def index
    if session[:user_id].blank?
      redirect_to :controller => 'access', :action=> 'login_form'
  	else
  		if flash[:check_diag] == 1
  			@alrams = (get_alarms(false) == true ? 'alarms' : '')
  		else
  			@alrams = ''
  		end

      ptc_check = Generalststistics.isPTC?

      if ptc_check
        @ptc_status = 'enabled'
      else
        @ptc_status = 'disabled'
      end

      usb_check = Generalststistics.isUSB?

      if usb_check
        @usb_status = 'enabled'
      else
        @usb_status = 'disabled'
      end
      
      @cpu_3_menu_system = Menu.cpu_3_menu_system

      @product = VersionInformation.get_product

      if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
        @is_gcp_5k = Gwe.gcp5k?
      end
    end

  end

  def redirect_home
    redirect_to :action=>"index"
  end
end
