class GeoInteger < ActiveRecord::Base
    establish_connection :mcf_db
    set_table_name "geo_integers"    
end
