ActionController::Routing::Routes.draw do |map|
  
  map.resources :log_requests
  
  map.resources :log_types
  
  map.resources :integer_parameters
  
  map.resources :string_parameters
  
  map.resources :enum_parameters
  
  map.resources :parameter_groups
  
  map.resources :enum_to_values
  
  map.resources :enum_values
  
  map.resources :configures
  
  map.resources :users
  
  map.resources :cdl_status, :only => [:index], :collection => {:check_status => :post}
  
  map.connect "/safemode/check_confirm_field", :controller => "safemode", :action => "check_confirm_field"
  
  map.resources :reports, :collection => {:report_pdf => :any}, :member => {:generate_csv => :get}
  
  
  # Configuration Editor
  map.connect "/open_site_config", :controller => "Selectsite", :action => "open_site_config"
  map.connect "/select_import_site", :controller => "Selectsite", :action => "select_import_site"
  map.connect "/saveas_site", :controller => "Selectsite", :action => "saveas_site"
  map.connect "/create_gcp_template", :controller => "Selectsite", :action => "create_gcp_template"
  map.connect "/global_verbosity", :controller => "logverbosity", :action => "global_verbosity"
  map.connect "/site/selectsiteconfig", :controller => "Selectsite", :action => "selectsiteconfig"
  
  
  # Maintenance 
  
  map.connect "/aspectlookup/import", :controller => "aspectlookup", :action => "import"
  #Create database
  map.connect "/site/ptcgeodb_create_new_geoptcdb", :controller => "mcfextractor", :action => "ptcgeodb_createnewmastergeoptcdb"
  #Open Database
  map.connect "/site/ptcgeodb_opengeoptcmasterdb", :controller => "mcfextractor", :action => "ptcgeodb_opengeoptcmasterdb"
  #Select Installation name for approve
  map.connect "/site/select_installationname_approve", :controller => "mcfextractor", :action => "get_installation_approve"
  # Generate Report
  map.connect "/site/select_installationname", :controller => "reports", :action => "generate_csv"
  # Back Button functionality link
  map.connect "/site/get_installation_approve_back", :controller => "mcfextractor", :action => "get_installation_approve_back"
  #Rename Installation Name
  map.connect "/renameinstallationname", :controller => "mcfextractor", :action => "rename_installationname"
  
  map.connect "/remove_gcp_template", :controller => "filemanager", :action => "remove_gcp_template"
  
  map.root :controller => "access", :action => "login_form"
  
  map.login "/login", :controller => "access", :action => "authenticate"
  
  map.connect "/system_state/get_system_replies", :controller => "system_state", :action => "get_system_replies"
  map.connect "/system_state/set_range", :controller => "system_state", :action => "set_range"
  map.connect "/system_state/set_range_values", :controller => "system_state", :action => "set_range_values"  
  
  #map.resources :io_status_view, :collection => {:populate_slots => :any, :get_online => :post, :check_state => :post}
  
  map.connect "/programming/check_supervisor_session", :controller => "programming", :action => "check_supervisor_session"
  map.connect "/programming/link_parameter", :controller => "programming", :action => "link_parameter"
  
  map.connect "/logreplies/add_comments_maintlog", :controller => "logreplies", :action => "add_comments_maintlog"
  
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
