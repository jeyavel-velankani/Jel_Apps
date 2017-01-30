####################################################################
# Company: Siemens 
# Author: 
# File: RouteTableController
# Description: Display RouteTable 
####################################################################

#-----------------------------------------------------------------------------------------------------
#History:
#*    Rev 1.0   Jul 05 2013 17:00:00   Gopu
#* Initial revision.
#-----------------------------------------------------------------------------------------------------

class RouteTableController < ApplicationController
  
  layout 'general'

  ####################################################################
  # Function:      index
  # Parameters:    none
  # Retrun:        none
  # Renders:       :partial => "routes"
  # Description:   Displays RouteTable
  ####################################################################  
  def index
    @routes = AtcsRoute.all
    if params[:auto_refresh]
      render :partial => "routes"
    end
  end
  
end
