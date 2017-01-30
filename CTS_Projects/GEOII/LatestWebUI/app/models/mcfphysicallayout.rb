class Mcfphysicallayout < ActiveRecord::Base
  set_table_name "MCFPhysicalLayout"
  set_primary_key 'PhysLayoutNumber'
  establish_connection :site_ptc_db if OCE_MODE == 1
end
