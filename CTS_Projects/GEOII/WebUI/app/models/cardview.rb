class Cardview < ActiveRecord::Base
   
   set_table_name 'card_view'
   set_primary_key 'mcfcrc'
   establish_connection :mcf_db
end
