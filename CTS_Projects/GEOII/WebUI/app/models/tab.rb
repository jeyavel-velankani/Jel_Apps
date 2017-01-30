class Tab < ActiveRecord::Base
  set_table_name "tab"
  set_primary_key "tabs_name"
  establish_connection :mcf_db

  belongs_to :page, :primary_key => 'tabs_name'
  
end