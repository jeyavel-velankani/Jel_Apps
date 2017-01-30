class Geoptcmenu < ActiveRecord::Base
set_table_name "MCFPhysicalLayout"
establish_connection :site_ptc_db if OCE_MODE == 1
end
